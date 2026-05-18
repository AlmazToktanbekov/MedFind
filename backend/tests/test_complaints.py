"""Тесты модели Complaint и сервиса авто-обработки жалоб."""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.models.complaint import Complaint
from app.models.notification import Notification
from app.models.user import User

pytestmark = pytest.mark.asyncio


async def test_complaint_create(db, make_user, make_doctor):
    user = await make_user(role="patient")
    doctor = await make_doctor()

    c = Complaint(
        author_id=user.id,
        target_type="doctor",
        target_id=doctor.id,
        reason="rude_behavior",
        comment="был груб",
    )
    db.add(c)
    await db.flush()

    saved = (await db.execute(select(Complaint).where(Complaint.id == c.id))).scalar_one()
    assert saved.status == "new"
    assert saved.target_type == "doctor"
    assert saved.reason == "rude_behavior"
    assert saved.resolved_at is None


async def test_complaint_resolved_fields(db, make_user, make_clinic):
    user = await make_user(role="patient")
    admin = await make_user(role="admin")
    clinic = await make_clinic()

    c = Complaint(
        author_id=user.id, target_type="clinic", target_id=clinic.id,
        reason="spam", status="new",
    )
    db.add(c)
    await db.flush()

    c.status = "resolved"
    c.resolution_note = "ok"
    c.resolved_by_admin_id = admin.id
    c.resolved_at = datetime.now(timezone.utc)
    await db.flush()

    saved = (await db.execute(select(Complaint).where(Complaint.id == c.id))).scalar_one()
    assert saved.status == "resolved"
    assert saved.resolved_by_admin_id == admin.id


async def test_no_notification_below_threshold(db, make_user, make_clinic, monkeypatch):
    """Меньше 10 жалоб — никаких уведомлений."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_1", 10)

    from app.services.jobs import complaints_warning
    owner = await make_user(role="clinic")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(3):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="other", status="new", created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["notified"] == 0
    assert result["blocked"] == 0


async def test_first_notification_at_n1(db, make_user, make_clinic, monkeypatch):
    """При >= 10 жалоб — первое уведомление (complaint_warning_1)."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_1", 5)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_2", 50)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_BLOCK_AT", 300)

    from app.services.jobs import complaints_warning
    owner = await make_user(role="clinic")
    admin = await make_user(role="admin")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(5):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="other", status="new", created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["notified"] == 1
    assert result["blocked"] == 0

    notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaint_warning_1",
        )
    )).scalars().all()
    assert len(notifs) == 1
    assert "жалоб" in notifs[0].body.lower()


async def test_second_notification_at_n2(db, make_user, make_clinic, monkeypatch):
    """При >= 100 жалоб — второе уведомление (complaint_warning_2)."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_1", 5)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_2", 10)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_BLOCK_AT", 300)

    from app.services.jobs import complaints_warning
    owner = await make_user(role="clinic")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(10):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="fraud", status="new", created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["notified"] == 1
    assert result["blocked"] == 0

    notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaint_warning_2",
        )
    )).scalars().all()
    assert len(notifs) == 1


async def test_auto_block_at_n_block(db, make_user, make_clinic, monkeypatch):
    """При >= 300 жалоб — аккаунт блокируется на 14 дней."""
    from app.core import config as cfg
    from sqlalchemy import select as sa_select

    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_1", 5)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_2", 10)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_BLOCK_AT", 15)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_BLOCK_DAYS", 14)

    from app.services.jobs import complaints_warning
    owner = await make_user(role="clinic")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(15):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="fraud", status="new", created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["blocked"] == 1

    owner_user = (await db.execute(sa_select(User).where(User.id == owner.id))).scalar_one()
    assert owner_user.is_active is False
    assert owner_user.complaint_blocked_until is not None

    block_notifs = (await db.execute(
        sa_select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaint_blocked",
        )
    )).scalars().all()
    assert len(block_notifs) == 1
    assert "заблокирован" in block_notifs[0].body.lower()


async def test_dedup_no_double_notify(db, make_user, make_clinic, monkeypatch):
    """Повторный запуск в тот же день не дублирует уведомления."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_1", 3)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_NOTIFY_2", 50)
    monkeypatch.setattr(cfg.settings, "COMPLAINT_BLOCK_AT", 300)

    from app.services.jobs import complaints_warning
    owner = await make_user(role="clinic")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(3):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="other", status="new", created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    r1 = await complaints_warning.run(db)
    r2 = await complaints_warning.run(db)
    assert r1["notified"] == 1
    assert r2["notified"] == 0  # дедуп

    owner_notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaint_warning_1",
        )
    )).scalars().all()
    assert len(owner_notifs) == 1


async def test_unblock_expired_job(db, make_user):
    """Ежедневный job разблокирует аккаунты с истёкшим complaint_blocked_until."""
    from app.services.jobs import unblock_expired
    from sqlalchemy import select as sa_select

    user = await make_user(role="clinic")
    user.is_active = False
    user.complaint_blocked_until = datetime.now(timezone.utc) - timedelta(hours=1)
    await db.flush()

    result = await unblock_expired.run(db)
    assert result["unblocked"] == 1

    refreshed = (await db.execute(sa_select(User).where(User.id == user.id))).scalar_one()
    assert refreshed.is_active is True
    assert refreshed.complaint_blocked_until is None


async def test_unblock_not_expired_stays_blocked(db, make_user):
    """Аккаунт с будущим complaint_blocked_until не разблокируется."""
    from app.services.jobs import unblock_expired
    from sqlalchemy import select as sa_select

    user = await make_user(role="clinic")
    user.is_active = False
    user.complaint_blocked_until = datetime.now(timezone.utc) + timedelta(days=10)
    await db.flush()

    result = await unblock_expired.run(db)
    assert result["unblocked"] == 0

    refreshed = (await db.execute(sa_select(User).where(User.id == user.id))).scalar_one()
    assert refreshed.is_active is False
