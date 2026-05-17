"""Сервис кошельков клиник/аптек: пополнение через ручную заявку с уникальным
кодом, атомарная покупка подписки из баланса.

Архитектура подтверждения через стратегии (см. confirm_strategies.py):
- "manual"     — админ подтверждает в админке (текущая стратегия)
- "mbank_auto" — webhook от Mbank API + матчинг по payment_code (на будущее)
"""
import secrets
import string
from datetime import datetime, timezone, timedelta
from decimal import Decimal
from typing import Optional, List, Literal, Tuple

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.wallet import Wallet, WalletTransaction
from app.models.subscription import Subscription
from app.services import subscription_service as subs

OwnerType = Literal["clinic", "pharmacy"]
Plan = Literal["pro", "premium"]
Period = Literal["month", "year"]


# ─── Помощники ────────────────────────────────────────────────────────────

def _generate_payment_code(owner_id: int) -> str:
    """Генерирует код вида MEDF-<owner_id>-<4 случайных alphanumeric>.

    Пример: MEDF-31-A7K4. Используется для матчинга платежа с заявкой:
    клиника указывает этот код в назначении банковского перевода.
    """
    alphabet = string.ascii_uppercase + string.digits
    suffix = "".join(secrets.choice(alphabet) for _ in range(4))
    return f"MEDF-{owner_id}-{suffix}"


def plan_price_usd(plan: Plan, period: Period) -> int:
    """Цена подписки в USD на нужный период.
    Year = (12 - PLAN_YEAR_DISCOUNT_MONTHS) * monthly_price.
    """
    monthly = (
        settings.PLAN_PRO_PRICE_USD if plan == "pro" else settings.PLAN_PREMIUM_PRICE_USD
    )
    if period == "year":
        return monthly * (12 - settings.PLAN_YEAR_DISCOUNT_MONTHS)
    return monthly


def plan_duration_days(period: Period) -> int:
    return 365 if period == "year" else 30


# ─── Кошелёк ──────────────────────────────────────────────────────────────

async def get_or_create_wallet(
    db: AsyncSession, owner_type: OwnerType, owner_id: int
) -> Wallet:
    r = await db.execute(
        select(Wallet).where(
            Wallet.owner_type == owner_type,
            Wallet.owner_id == owner_id,
        )
    )
    wallet = r.scalar_one_or_none()
    if wallet is None:
        wallet = Wallet(
            owner_type=owner_type, owner_id=owner_id, balance_usd=Decimal("0.00")
        )
        db.add(wallet)
        await db.flush()
    return wallet


async def get_history(
    db: AsyncSession, wallet_id: int, limit: int = 50, offset: int = 0
) -> List[WalletTransaction]:
    r = await db.execute(
        select(WalletTransaction)
        .where(WalletTransaction.wallet_id == wallet_id)
        .order_by(WalletTransaction.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(r.scalars().all())


# ─── Заявка на пополнение ────────────────────────────────────────────────

class WalletError(Exception):
    """Базовая ошибка кошелька — превращается в HTTP в роутере."""
    def __init__(self, code: str, message: str, http_status: int = 400):
        self.code = code
        self.message = message
        self.http_status = http_status
        super().__init__(message)


async def request_topup(
    db: AsyncSession,
    wallet: Wallet,
    amount_usd: Decimal,
    comment: Optional[str] = None,
) -> WalletTransaction:
    """Создаёт заявку на пополнение с уникальным payment_code.

    Проверки:
      - сумма в диапазоне [WALLET_MIN_TOPUP_USD, WALLET_MAX_TOPUP_USD]
      - нет активной pending-заявки на этот кошелёк (одновременно только одна)
    """
    if amount_usd < settings.WALLET_MIN_TOPUP_USD:
        raise WalletError(
            "amount_too_small",
            f"Минимальная сумма пополнения — ${settings.WALLET_MIN_TOPUP_USD}",
        )
    if amount_usd > settings.WALLET_MAX_TOPUP_USD:
        raise WalletError(
            "amount_too_large",
            f"Максимальная сумма одной заявки — ${settings.WALLET_MAX_TOPUP_USD}",
        )

    # Проверка одной pending-заявки актуальна только для ручного/банковского подтверждения.
    # В auto-режиме заявки сразу success, ограничение не нужно.
    if settings.WALLET_CONFIRM_STRATEGY != "auto":
        r = await db.execute(
            select(WalletTransaction).where(
                WalletTransaction.wallet_id == wallet.id,
                WalletTransaction.type == "topup",
                WalletTransaction.status == "pending",
            )
        )
        if r.scalar_one_or_none() is not None:
            raise WalletError(
                "pending_request_exists",
                "У вас уже есть заявка на пополнение, ожидающая подтверждения",
                http_status=409,
            )

    # При стратегии "auto" — мгновенное автоподтверждение (MVP/демо-режим).
    # При "manual" / "mbank_auto" — pending, ждёт админа или webhook.
    if settings.WALLET_CONFIRM_STRATEGY == "auto":
        new_balance = wallet.balance_usd + amount_usd
        wallet.balance_usd = new_balance
        tx = WalletTransaction(
            wallet_id=wallet.id,
            type="topup",
            amount_usd=amount_usd,
            balance_after_usd=new_balance,
            status="success",
            payment_code=_generate_payment_code(wallet.owner_id),
            comment=comment,
            completed_at=datetime.now(timezone.utc),
        )
    else:
        tx = WalletTransaction(
            wallet_id=wallet.id,
            type="topup",
            amount_usd=amount_usd,
            status="pending",
            payment_code=_generate_payment_code(wallet.owner_id),
            comment=comment,
        )
    db.add(tx)
    await db.flush()
    return tx


async def confirm_topup(
    db: AsyncSession,
    tx_id: int,
    actual_amount_usd: Decimal,
    admin_user_id: Optional[int] = None,
) -> WalletTransaction:
    """Подтверждение пополнения (вызывается админом или webhook'ом).

    Атомарно:
      1. Помечаем транзакцию как success с фактической суммой
      2. Зачисляем actual_amount_usd на баланс кошелька
      3. Сохраняем balance_after_usd
    """
    r = await db.execute(
        select(WalletTransaction).where(WalletTransaction.id == tx_id)
    )
    tx = r.scalar_one_or_none()
    if tx is None:
        raise WalletError("not_found", "Заявка не найдена", http_status=404)
    if tx.type != "topup":
        raise WalletError("wrong_type", "Это не заявка на пополнение")
    if tx.status != "pending":
        raise WalletError(
            "already_processed",
            f"Заявка уже в статусе {tx.status}",
            http_status=409,
        )
    if actual_amount_usd <= 0:
        raise WalletError("amount_invalid", "Сумма должна быть положительной")

    # Lock-free пока: одна заявка → одно подтверждение. Race condition защищён
    # проверкой status='pending' выше + flush. При высокой нагрузке добавим
    # SELECT FOR UPDATE.
    wallet_r = await db.execute(
        select(Wallet).where(Wallet.id == tx.wallet_id).with_for_update()
    )
    wallet = wallet_r.scalar_one()

    new_balance = wallet.balance_usd + actual_amount_usd
    wallet.balance_usd = new_balance

    tx.amount_usd = actual_amount_usd
    tx.balance_after_usd = new_balance
    tx.status = "success"
    tx.admin_user_id = admin_user_id
    tx.completed_at = datetime.now(timezone.utc)

    await db.flush()
    return tx


async def cancel_topup(
    db: AsyncSession,
    tx_id: int,
    reason: str,
    admin_user_id: Optional[int] = None,
) -> WalletTransaction:
    r = await db.execute(
        select(WalletTransaction).where(WalletTransaction.id == tx_id)
    )
    tx = r.scalar_one_or_none()
    if tx is None:
        raise WalletError("not_found", "Заявка не найдена", http_status=404)
    if tx.status != "pending":
        raise WalletError(
            "already_processed",
            f"Заявка уже в статусе {tx.status}",
            http_status=409,
        )

    tx.status = "cancelled"
    tx.comment = (tx.comment or "") + f"\n[Отклонено]: {reason}"
    tx.admin_user_id = admin_user_id
    tx.completed_at = datetime.now(timezone.utc)
    await db.flush()
    return tx


# ─── Покупка подписки из баланса ─────────────────────────────────────────

async def purchase_subscription(
    db: AsyncSession,
    wallet: Wallet,
    plan: Plan,
    period: Period,
) -> Tuple[WalletTransaction, Subscription]:
    """Атомарная покупка: списание с баланса + активация подписки.

    Если баланс меньше цены — WalletError(insufficient_funds).
    Подписка активируется на 30/365 дней (period=month/year).
    """
    price = Decimal(plan_price_usd(plan, period))

    # Lock баланса на время транзакции
    wallet_r = await db.execute(
        select(Wallet).where(Wallet.id == wallet.id).with_for_update()
    )
    locked = wallet_r.scalar_one()

    if locked.balance_usd < price:
        raise WalletError(
            "insufficient_funds",
            f"Недостаточно средств. Нужно ${price}, баланс ${locked.balance_usd}",
            http_status=402,
        )

    new_balance = locked.balance_usd - price
    locked.balance_usd = new_balance

    # Активируем подписку (закрывает старые active автоматически)
    sub = await subs.set_plan_manual(
        db,
        owner_type=locked.owner_type,  # type: ignore
        owner_id=locked.owner_id,
        plan=plan,
        days=plan_duration_days(period),
        period=period,
    )

    tx = WalletTransaction(
        wallet_id=locked.id,
        type="purchase",
        amount_usd=price,
        balance_after_usd=new_balance,
        status="success",
        related_subscription_id=sub.id,
        comment=f"Подписка {plan.upper()} на {'год' if period == 'year' else 'месяц'}",
        completed_at=datetime.now(timezone.utc),
    )
    db.add(tx)
    await db.flush()
    return tx, sub


# ─── Поиск заявки по коду (для будущего Mbank-webhook) ───────────────────

async def find_topup_by_code(
    db: AsyncSession, payment_code: str
) -> Optional[WalletTransaction]:
    r = await db.execute(
        select(WalletTransaction).where(
            WalletTransaction.payment_code == payment_code,
            WalletTransaction.type == "topup",
            WalletTransaction.status == "pending",
        )
    )
    return r.scalar_one_or_none()


# ─── Refund (возврат админом) ────────────────────────────────────────────

async def refund_purchase(
    db: AsyncSession,
    tx_id: int,
    reason: str,
    admin_user_id: int,
) -> WalletTransaction:
    """Создаёт refund: возвращает amount_usd оригинальной purchase на баланс кошелька.

    Идемпотентность: на каждую purchase можно сделать не более одного refund (проверяем по
    related_subscription_id и наличию refund-транзакции, ссылающейся на ту же подписку).
    """
    r = await db.execute(select(WalletTransaction).where(WalletTransaction.id == tx_id))
    tx = r.scalar_one_or_none()
    if tx is None:
        raise WalletError("not_found", "Транзакция не найдена", http_status=404)
    if tx.type != "purchase":
        raise WalletError("wrong_type", "Возврат можно сделать только для покупки")
    if tx.status != "success":
        raise WalletError("not_succeeded", "Транзакция не успешна")

    # Проверка дубля: если уже есть refund на эту же подписку — отказ
    if tx.related_subscription_id is not None:
        dup = await db.execute(
            select(WalletTransaction).where(
                WalletTransaction.type == "refund",
                WalletTransaction.related_subscription_id == tx.related_subscription_id,
            )
        )
        if dup.scalar_one_or_none():
            raise WalletError("already_refunded", "Возврат по этой подписке уже сделан", http_status=409)

    wallet_r = await db.execute(
        select(Wallet).where(Wallet.id == tx.wallet_id).with_for_update()
    )
    wallet = wallet_r.scalar_one()

    new_balance = wallet.balance_usd + tx.amount_usd
    wallet.balance_usd = new_balance

    refund_tx = WalletTransaction(
        wallet_id=wallet.id,
        type="refund",
        amount_usd=tx.amount_usd,
        balance_after_usd=new_balance,
        status="success",
        related_subscription_id=tx.related_subscription_id,
        comment=f"Refund для tx #{tx.id}: {reason}",
        admin_user_id=admin_user_id,
        completed_at=datetime.now(timezone.utc),
    )
    db.add(refund_tx)
    await db.flush()
    return refund_tx
