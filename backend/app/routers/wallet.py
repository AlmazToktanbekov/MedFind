"""Кошелёк: баланс владельца клиники/аптеки, заявки на пополнение, покупка
подписок из баланса. Реквизиты MedFind берутся из конфига.

Webhook от банка (`/wallet/webhook/mbank`) — заглушка под стратегию
WALLET_CONFIRM_STRATEGY=mbank_auto. Пока возвращает 501.
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional, List, Literal
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.config import settings
from app.core.security import get_current_user
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany
from app.models.wallet import Wallet, WalletTransaction
from app.services import wallet_service as wallets

router = APIRouter(prefix="/wallet", tags=["wallet"])


# ─── Схемы ────────────────────────────────────────────────────────────────

class WalletOut(BaseModel):
    owner_type: str
    owner_id: int
    balance_usd: float
    balance_kgs: float
    updated_at: datetime

    @staticmethod
    def from_db(w: Wallet) -> "WalletOut":
        usd = float(w.balance_usd)
        return WalletOut(
            owner_type=w.owner_type,
            owner_id=w.owner_id,
            balance_usd=usd,
            balance_kgs=round(usd * settings.USD_TO_KGS_RATE, 2),
            updated_at=w.updated_at,
        )


class TransactionOut(BaseModel):
    id: int
    type: str
    status: str
    amount_usd: float
    balance_after_usd: Optional[float]
    payment_code: Optional[str]
    comment: Optional[str]
    related_subscription_id: Optional[int]
    created_at: datetime
    completed_at: Optional[datetime]

    @staticmethod
    def from_db(t: WalletTransaction) -> "TransactionOut":
        return TransactionOut(
            id=t.id,
            type=t.type,
            status=t.status,
            amount_usd=float(t.amount_usd),
            balance_after_usd=float(t.balance_after_usd) if t.balance_after_usd is not None else None,
            payment_code=t.payment_code,
            comment=t.comment,
            related_subscription_id=t.related_subscription_id,
            created_at=t.created_at,
            completed_at=t.completed_at,
        )


class TopupRequestIn(BaseModel):
    amount_usd: int = Field(..., gt=0)
    comment: Optional[str] = None


class PurchaseIn(BaseModel):
    plan: Literal["pro", "premium"]
    period: Literal["month", "year"] = "month"


class PaymentInfoOut(BaseModel):
    company_name: str
    inn: str
    bank_name: str
    bank_account: str
    bank_bik: str
    support_phone: str
    min_amount_usd: int
    max_amount_usd: int
    usd_to_kgs_rate: float


# ─── Helpers ──────────────────────────────────────────────────────────────

async def _resolve_owner(current_user, db: AsyncSession):
    """По роли текущего юзера находит его клинику или аптечную компанию."""
    if current_user.role == "clinic":
        r = await db.execute(select(Clinic).where(Clinic.user_id == current_user.id).limit(1))
        clinic = r.scalar_one_or_none()
        if clinic is None:
            raise HTTPException(status_code=404, detail="Clinic not found for current user")
        return "clinic", clinic.id
    if current_user.role == "pharmacy":
        r = await db.execute(
            select(PharmacyCompany).where(PharmacyCompany.user_id == current_user.id).limit(1)
        )
        company = r.scalar_one_or_none()
        if company is None:
            raise HTTPException(status_code=404, detail="Pharmacy company not found for current user")
        return "pharmacy", company.id
    raise HTTPException(status_code=403, detail="Wallet available only for clinic/pharmacy roles")


def _wallet_error_to_http(e: wallets.WalletError) -> HTTPException:
    return HTTPException(
        status_code=e.http_status,
        detail={"code": e.code, "message": e.message},
    )


# ─── Публичные endpoints ─────────────────────────────────────────────────

@router.get("/me", response_model=WalletOut)
async def get_my_wallet(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Баланс владельца. Создаёт кошелёк лениво если ещё нет."""
    owner_type, owner_id = await _resolve_owner(current_user, db)
    wallet = await wallets.get_or_create_wallet(db, owner_type, owner_id)
    return WalletOut.from_db(wallet)


@router.get("/me/transactions", response_model=List[TransactionOut])
async def my_transactions(
    limit: int = 50,
    offset: int = 0,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    owner_type, owner_id = await _resolve_owner(current_user, db)
    wallet = await wallets.get_or_create_wallet(db, owner_type, owner_id)
    items = await wallets.get_history(db, wallet.id, limit=limit, offset=offset)
    return [TransactionOut.from_db(t) for t in items]


@router.get("/me/payment-info", response_model=PaymentInfoOut)
async def payment_info():
    """Реквизиты MedFind для перевода + лимиты пополнения."""
    return PaymentInfoOut(
        company_name=settings.COMPANY_NAME,
        inn=settings.COMPANY_INN,
        bank_name=settings.BANK_NAME,
        bank_account=settings.BANK_ACCOUNT,
        bank_bik=settings.BANK_BIK,
        support_phone=settings.SUPPORT_PHONE,
        min_amount_usd=settings.WALLET_MIN_TOPUP_USD,
        max_amount_usd=settings.WALLET_MAX_TOPUP_USD,
        usd_to_kgs_rate=settings.USD_TO_KGS_RATE,
    )


@router.post("/me/topup-request", response_model=TransactionOut, status_code=201)
async def create_topup_request(
    body: TopupRequestIn,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Клиника создаёт заявку на пополнение. Возвращает payment_code, который
    нужно указать в назначении банковского перевода."""
    owner_type, owner_id = await _resolve_owner(current_user, db)
    wallet = await wallets.get_or_create_wallet(db, owner_type, owner_id)
    try:
        tx = await wallets.request_topup(
            db, wallet, Decimal(body.amount_usd), comment=body.comment
        )
    except wallets.WalletError as e:
        raise _wallet_error_to_http(e)
    return TransactionOut.from_db(tx)


@router.post("/me/purchase", response_model=TransactionOut, status_code=201)
async def purchase_subscription(
    body: PurchaseIn,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Купить подписку (списание с баланса). Атомарно: проверка → списание →
    активация подписки. При нехватке средств — HTTP 402."""
    owner_type, owner_id = await _resolve_owner(current_user, db)
    wallet = await wallets.get_or_create_wallet(db, owner_type, owner_id)
    try:
        tx, _sub = await wallets.purchase_subscription(db, wallet, body.plan, body.period)
    except wallets.WalletError as e:
        raise _wallet_error_to_http(e)
    return TransactionOut.from_db(tx)


# ─── Webhook от банка (стратегия mbank_auto) ─────────────────────────────

@router.post("/webhook/mbank")
async def mbank_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Заглушка под Mbank Business API.

    Когда WALLET_CONFIRM_STRATEGY=mbank_auto и есть валидные API-credentials:
      1. Проверяем HMAC подпись (MBANK_WEBHOOK_SECRET)
      2. Парсим из body: payment_code из «назначение платежа», сумму
      3. find_topup_by_code(payment_code) → confirm_topup(...)

    Сейчас (manual mode): возвращает 501.
    """
    if settings.WALLET_CONFIRM_STRATEGY != "mbank_auto":
        raise HTTPException(
            status_code=501,
            detail={
                "code": "auto_confirm_disabled",
                "message": "Автоподтверждение через Mbank API не подключено. "
                           "Установите WALLET_CONFIRM_STRATEGY=mbank_auto и заполните MBANK_WEBHOOK_SECRET.",
            },
        )
    # TODO: реализовать когда будет доступ к Mbank Business API
    raise HTTPException(status_code=501, detail="Not implemented")
