"""Тесты cron-задач APScheduler (запуск напрямую через job.run(db))."""
from datetime import datetime, timezone, timedelta
from decimal import Decimal

import pytest

from app.core.config import settings
from app.services import subscription_service as subs
from app.services import wallet_service as wallets


@pytest.fixture
def manual_confirm(monkeypatch):
    """Manual-режим для тестов pending-flow."""
    monkeypatch.setattr(settings, "WALLET_CONFIRM_STRATEGY", "manual")
from app.services.jobs import (
    subscription_reminders,
    subscription_expiration,
    topup_cleanup,
    complaints_warning,
)


async def test_complaints_warning_no_data(db):
    """Без жалоб — warned=0."""
    result = await complaints_warning.run(db)
    assert result["warned"] == 0
    assert result["threshold"] > 0
    assert result["window_days"] > 0


async def test_topup_cleanup_cancels_old_pending(db, manual_confirm, make_clinic):
    """Заявки старше 7 дней автоматически отменяются."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    # Подменяем created_at на 10 дней назад
    from sqlalchemy import update
    from app.models.wallet import WalletTransaction
    await db.execute(
        update(WalletTransaction)
        .where(WalletTransaction.id == tx.id)
        .values(created_at=datetime.now(timezone.utc) - timedelta(days=10))
    )
    await db.flush()

    result = await topup_cleanup.run(db)
    assert result["cancelled"] == 1

    await db.refresh(tx)
    assert tx.status == "cancelled"


async def test_topup_cleanup_does_not_touch_fresh_requests(db, manual_confirm, make_clinic):
    """Свежие заявки (моложе 7 дней) не трогаются."""
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    result = await topup_cleanup.run(db)
    assert result["cancelled"] == 0

    await db.refresh(tx)
    assert tx.status == "pending"


async def test_subscription_expiration_marks_expired(db, make_clinic):
    """Подписки с истёкшим expires_at становятся expired."""
    clinic = await make_clinic()
    # Pro на -1 день → уже истекла
    sub = await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=-1)
    await db.commit()

    result = await subscription_expiration.run(db)
    assert result["expired"] == 1

    await db.refresh(sub)
    assert sub.status == "expired"


async def test_subscription_expiration_deactivates_extra_doctors(db, make_clinic, make_doctor):
    """При истечении подписки клиники с 6 активными врачами:
    первые 4 остаются active, остальные → deactivated."""
    clinic = await make_clinic()
    doctors = []
    for _ in range(6):
        doctors.append(await make_doctor(clinic=clinic, status="active"))

    # Подписка Pro истекла
    await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=-1)
    await db.commit()

    result = await subscription_expiration.run(db)
    assert result["doctors_deactivated"] == 2  # 6 - 4 = 2

    # Первые 4 (по created_at) остались active, остальные deactivated
    for i, doc in enumerate(doctors):
        await db.refresh(doc)
        if i < 4:
            assert doc.status == "active", f"Doctor {i} should be active"
        else:
            assert doc.status == "deactivated", f"Doctor {i} should be deactivated"


async def test_subscription_expiration_skips_active_subscriptions(db, make_clinic, make_doctor):
    """Не трогает подписки с expires_at в будущем."""
    clinic = await make_clinic()
    for _ in range(6):
        await make_doctor(clinic=clinic, status="active")
    await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=30)
    await db.commit()

    result = await subscription_expiration.run(db)
    assert result["expired"] == 0
    assert result["doctors_deactivated"] == 0


async def test_subscription_reminders_does_not_throw(db, make_clinic):
    """Smoke test: задача напоминаний выполняется без ошибок."""
    clinic = await make_clinic()
    # Подписка ровно через 7 дней
    await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=7)
    await db.commit()

    result = await subscription_reminders.run(db)
    assert "sent" in result
    assert "skipped" in result
    assert "total" in result
    assert result["total"] >= 1
