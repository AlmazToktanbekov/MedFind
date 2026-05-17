"""Тесты кошелька: создание заявок, подтверждение, покупка подписки."""
from decimal import Decimal

import pytest

from app.core.config import settings
from app.services import wallet_service as wallets
from app.services import subscription_service as subs


@pytest.fixture
def manual_confirm(monkeypatch):
    """Переключает стратегию подтверждения на 'manual' (для тестов админ-флоу)."""
    monkeypatch.setattr(settings, "WALLET_CONFIRM_STRATEGY", "manual")


async def test_get_or_create_wallet_creates_with_zero_balance(db, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    assert wallet.balance_usd == Decimal("0.00")
    assert wallet.owner_type == "clinic"
    assert wallet.owner_id == clinic.id


async def test_get_or_create_wallet_idempotent(db, make_clinic):
    """Второй вызов возвращает тот же кошелёк, не создаёт новый."""
    clinic = await make_clinic()
    w1 = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    w2 = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    assert w1.id == w2.id


async def test_request_topup_auto_confirms_and_credits_balance(db, make_clinic):
    """В auto-режиме (default) заявка сразу success, баланс растёт."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    assert tx.status == "success"
    assert tx.type == "topup"
    assert tx.balance_after_usd == Decimal("50.00")
    assert tx.payment_code is not None
    assert tx.payment_code.startswith(f"MEDF-{clinic.id}-")

    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("50.00")


async def test_request_topup_pending_in_manual_mode(db, manual_confirm, make_clinic):
    """В manual-режиме заявка создаётся как pending, баланс не меняется."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    assert tx.status == "pending"
    assert tx.balance_after_usd is None
    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("0.00")


async def test_request_topup_rejects_amount_below_minimum(db, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.request_topup(db, wallet, Decimal("5.00"))

    assert exc.value.code == "amount_too_small"


async def test_request_topup_rejects_amount_above_maximum(db, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.request_topup(db, wallet, Decimal("9999.00"))

    assert exc.value.code == "amount_too_large"


async def test_only_one_pending_request_allowed(db, manual_confirm, make_clinic):
    """Нельзя создать вторую заявку пока первая в статусе pending (manual режим)."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    await wallets.request_topup(db, wallet, Decimal("50.00"))

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.request_topup(db, wallet, Decimal("100.00"))

    assert exc.value.code == "pending_request_exists"
    assert exc.value.http_status == 409


async def test_confirm_topup_increases_balance(db, manual_confirm, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    confirmed = await wallets.confirm_topup(db, tx.id, Decimal("50.00"))

    assert confirmed.status == "success"
    assert confirmed.balance_after_usd == Decimal("50.00")
    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("50.00")


async def test_confirm_topup_accepts_partial_amount(db, manual_confirm, make_clinic):
    """Админ может подтвердить меньшую/большую сумму чем заявлено."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    confirmed = await wallets.confirm_topup(db, tx.id, Decimal("45.00"))

    assert confirmed.amount_usd == Decimal("45.00")
    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("45.00")


async def test_cannot_confirm_already_processed(db, manual_confirm, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))
    await wallets.confirm_topup(db, tx.id, Decimal("50.00"))

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.confirm_topup(db, tx.id, Decimal("50.00"))

    assert exc.value.code == "already_processed"


async def test_cancel_topup_does_not_change_balance(db, manual_confirm, make_clinic):
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    await wallets.cancel_topup(db, tx.id, "Тест отмены")

    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("0.00")
    await db.refresh(tx)
    assert tx.status == "cancelled"
    assert "Тест отмены" in tx.comment


async def test_purchase_subscription_pro_month(db, make_clinic):
    """После пополнения и покупки Pro: баланс -$20, подписка активна."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    # auto-режим: запрос на пополнение сразу зачисляет баланс
    await wallets.request_topup(db, wallet, Decimal("50.00"))

    purchase_tx, sub = await wallets.purchase_subscription(db, wallet, "pro", "month")

    assert purchase_tx.type == "purchase"
    assert purchase_tx.amount_usd == Decimal("20")
    assert purchase_tx.status == "success"
    assert purchase_tx.balance_after_usd == Decimal("30.00")
    assert purchase_tx.related_subscription_id == sub.id

    assert sub.plan == "pro"
    assert sub.is_trial is False

    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("30.00")


async def test_purchase_premium_year_costs_more(db, make_clinic):
    """Premium годовая = $400 (со скидкой 2 месяца от $40)."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    await wallets.request_topup(db, wallet, Decimal("500.00"))

    purchase_tx, sub = await wallets.purchase_subscription(db, wallet, "premium", "year")

    assert purchase_tx.amount_usd == Decimal("400")
    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("100.00")
    assert sub.plan == "premium"


async def test_purchase_fails_with_insufficient_funds(db, make_clinic):
    """Покупка при нехватке средств → HTTP 402."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    # Кошелёк с $5 — покупки Pro ($20) не хватит

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.purchase_subscription(db, wallet, "pro", "month")

    assert exc.value.code == "insufficient_funds"
    assert exc.value.http_status == 402

    await db.refresh(wallet)
    assert wallet.balance_usd == Decimal("0.00")  # не списалось


async def test_find_topup_by_code(db, manual_confirm, make_clinic):
    """Поиск заявки по коду (нужен для будущего Mbank webhook)."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    found = await wallets.find_topup_by_code(db, tx.payment_code)
    assert found is not None
    assert found.id == tx.id


async def test_find_topup_by_code_returns_none_for_unknown(db):
    found = await wallets.find_topup_by_code(db, "MEDF-99-XXXX")
    assert found is None


async def test_plan_prices(db):
    """Цены планов соответствуют CLAUDE.md."""
    assert wallets.plan_price_usd("pro", "month") == 20
    assert wallets.plan_price_usd("pro", "year") == 200
    assert wallets.plan_price_usd("premium", "month") == 40
    assert wallets.plan_price_usd("premium", "year") == 400


async def test_get_history_returns_all_tx_descending(db, make_clinic):
    """История содержит все транзакции, отсортированные по дате убыванию."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    await wallets.request_topup(db, wallet, Decimal("30.00"))
    await wallets.purchase_subscription(db, wallet, "pro", "month")

    history = await wallets.get_history(db, wallet.id, limit=10)

    assert len(history) == 2
    # Самая свежая — покупка — первая
    assert history[0].type == "purchase"
    assert history[1].type == "topup"
