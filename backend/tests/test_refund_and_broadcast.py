"""Тесты для админ-функций: refund и push-рассылки с сегментацией."""
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from sqlalchemy import select

from app.core.config import settings
from app.models.broadcast import Broadcast, BroadcastDelivery
from app.models.notification import Notification
from app.models.search_log import SearchLog
from app.models.wallet import WalletTransaction
from app.services import broadcast_service as bsvc
from app.services import wallet_service as wallets


pytestmark = pytest.mark.asyncio


# ─── Refund ───────────────────────────────────────────────────────────────

async def test_refund_returns_amount_to_wallet(db, make_user, make_clinic):
    """Возврат покупки увеличивает баланс на сумму оригинальной транзакции."""
    admin = await make_user(role="admin")
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)

    # Пополняем + покупаем (получаем purchase tx с балансом)
    await wallets.request_topup(db, wallet, Decimal("100.00"))
    purchase_tx, _ = await wallets.purchase_subscription(db, wallet, "pro", "month")
    assert purchase_tx.status == "success"
    balance_before = wallet.balance_usd

    refund_tx = await wallets.refund_purchase(
        db, purchase_tx.id, reason="клиент попросил", admin_user_id=admin.id,
    )

    assert refund_tx.type == "refund"
    assert refund_tx.status == "success"
    assert refund_tx.amount_usd == purchase_tx.amount_usd
    assert refund_tx.admin_user_id == admin.id
    assert wallet.balance_usd == balance_before + purchase_tx.amount_usd


async def test_refund_prevents_double(db, make_user, make_clinic):
    """Повторный возврат той же покупки → already_refunded."""
    admin = await make_user(role="admin")
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    await wallets.request_topup(db, wallet, Decimal("100.00"))
    purchase_tx, _ = await wallets.purchase_subscription(db, wallet, "pro", "month")

    await wallets.refund_purchase(db, purchase_tx.id, "первый", admin.id)
    with pytest.raises(wallets.WalletError) as exc:
        await wallets.refund_purchase(db, purchase_tx.id, "второй", admin.id)
    assert exc.value.code == "already_refunded"


async def test_refund_rejects_non_purchase(db, make_user, make_clinic):
    """На пополнение refund сделать нельзя."""
    admin = await make_user(role="admin")
    clinic = await make_clinic()
    wallet = await wallets.get_or_create_wallet(db, "clinic", clinic.id)
    topup_tx = await wallets.request_topup(db, wallet, Decimal("50.00"))

    with pytest.raises(wallets.WalletError) as exc:
        await wallets.refund_purchase(db, topup_tx.id, "оп", admin.id)
    assert exc.value.code == "wrong_type"


# ─── Broadcast segmentation ───────────────────────────────────────────────

async def test_broadcast_segment_by_role(db, make_user):
    """Сегмент {roles:['patient']} возвращает только пациентов."""
    p1 = await make_user(role="patient")
    p2 = await make_user(role="patient")
    await make_user(role="doctor")
    await make_user(role="clinic")

    ids = await bsvc.resolve_segment(db, {"roles": ["patient"]})
    assert set(ids) == {p1.id, p2.id}


async def test_broadcast_segment_empty_returns_all_active(db, make_user):
    """Пустой сегмент = все активные пользователи."""
    u1 = await make_user(role="patient")
    u2 = await make_user(role="doctor")
    ids = await bsvc.resolve_segment(db, None)
    assert set(ids) >= {u1.id, u2.id}


async def test_broadcast_segment_excludes_blocked_and_deleted(db, make_user):
    """Заблокированные и удалённые пользователи не попадают в сегмент."""
    active = await make_user(role="patient")
    blocked = await make_user(role="patient")
    blocked.is_active = False
    deleted = await make_user(role="patient")
    deleted.deleted_at = datetime.now(timezone.utc)
    await db.flush()

    ids = await bsvc.resolve_segment(db, {"roles": ["patient"]})
    assert active.id in ids
    assert blocked.id not in ids
    assert deleted.id not in ids


async def test_broadcast_segment_by_city(db, make_user):
    bishkek = await make_user(role="patient")
    bishkek.city = "Бишкек"
    osh = await make_user(role="patient")
    osh.city = "Ош"
    await db.flush()

    ids = await bsvc.resolve_segment(db, {"cities": ["Бишкек"]})
    assert bishkek.id in ids
    assert osh.id not in ids


async def test_broadcast_send_creates_notifications_and_deliveries(db, make_user):
    """Отправка рассылки пишет Notification получателям и BroadcastDelivery с success."""
    admin = await make_user(role="admin")
    p1 = await make_user(role="patient")
    p2 = await make_user(role="patient")

    bcast = Broadcast(
        title="Тестовая рассылка",
        body="Здравствуйте!",
        segment={"roles": ["patient"]},
        status="draft",
        created_by_admin_id=admin.id,
    )
    db.add(bcast)
    await db.flush()

    sent, failed = await bsvc.send_broadcast(db, bcast)
    assert sent == 2
    assert failed == 0
    assert bcast.status == "sent"
    assert bcast.sent_at is not None

    # Notifications созданы
    for uid in (p1.id, p2.id):
        notifs = (await db.execute(
            select(Notification).where(
                Notification.user_id == uid, Notification.type == "broadcast",
            )
        )).scalars().all()
        assert len(notifs) == 1
        assert notifs[0].title == "Тестовая рассылка"

    # Deliveries есть
    deliveries = (await db.execute(
        select(BroadcastDelivery).where(BroadcastDelivery.broadcast_id == bcast.id)
    )).scalars().all()
    assert len(deliveries) == 2
    assert all(d.status == "delivered" for d in deliveries)


# ─── Search log ────────────────────────────────────────────────────────────

async def test_search_log_record(db, make_user):
    """SearchLog запись сохраняется с user_id или без, query усекается до 255."""
    user = await make_user(role="patient")

    db.add(SearchLog(user_id=user.id, query="терапевт", results_count=5))
    db.add(SearchLog(user_id=None, query="кардиолог", results_count=0))
    await db.flush()

    rows = (await db.execute(select(SearchLog).order_by(SearchLog.id))).scalars().all()
    assert len(rows) == 2
    assert rows[0].query == "терапевт"
    assert rows[0].user_id == user.id
    assert rows[1].user_id is None
