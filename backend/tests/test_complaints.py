"""Тесты модели Complaint и сервиса предупреждений."""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.models.complaint import Complaint
from app.models.notification import Notification
from app.services.jobs import complaints_warning


pytestmark = pytest.mark.asyncio


async def test_complaint_create(db, make_user, make_doctor):
    """Жалоба создаётся с корректными полями и статусом new."""
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
    assert saved.target_id == doctor.id
    assert saved.reason == "rude_behavior"
    assert saved.resolved_at is None


async def test_complaint_resolved_fields(db, make_user, make_clinic):
    """При закрытии жалобы фиксируются resolved_at и resolved_by."""
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
    assert saved.resolution_note == "ok"


async def test_complaints_warning_no_threshold(db, make_user, make_clinic):
    """Меньше порога — никаких уведомлений."""
    user = await make_user(role="patient")
    clinic = await make_clinic()
    # Всего 3 жалобы, порог 100 — никого не предупреждаем
    for _ in range(3):
        db.add(Complaint(
            author_id=user.id, target_type="clinic", target_id=clinic.id,
            reason="other", status="new",
            created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["warned"] == 0


async def test_complaints_warning_above_threshold_sends_notifications(
    db, make_user, make_clinic, monkeypatch
):
    """При жалобах >= порога — push владельцу клиники и админам."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINTS_WARNING_THRESHOLD", 3)
    monkeypatch.setattr(cfg.settings, "COMPLAINTS_WINDOW_DAYS", 10)

    owner = await make_user(role="clinic")
    admin = await make_user(role="admin")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(3):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="fraud", status="new",
            created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["warned"] == 1
    assert result["threshold"] == 3

    # Owner получил push
    owner_notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaints_warning",
        )
    )).scalars().all()
    assert len(owner_notifs) == 1
    assert "жалоб" in owner_notifs[0].body.lower()

    # Админ получил push
    admin_notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == admin.id,
            Notification.type == "complaints_warning",
        )
    )).scalars().all()
    assert len(admin_notifs) == 1


async def test_complaints_warning_dedup(db, make_user, make_clinic, monkeypatch):
    """Повторный запуск в том же окне не дублирует уведомления."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINTS_WARNING_THRESHOLD", 2)
    monkeypatch.setattr(cfg.settings, "COMPLAINTS_WINDOW_DAYS", 10)

    owner = await make_user(role="clinic")
    patient = await make_user(role="patient")
    clinic = await make_clinic(user=owner)

    for _ in range(2):
        db.add(Complaint(
            author_id=patient.id, target_type="clinic", target_id=clinic.id,
            reason="other", status="new",
            created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    r1 = await complaints_warning.run(db)
    r2 = await complaints_warning.run(db)
    assert r1["warned"] == 1
    assert r2["warned"] == 0  # уже предупреждали — дедуп

    owner_notifs = (await db.execute(
        select(Notification).where(
            Notification.user_id == owner.id,
            Notification.type == "complaints_warning",
        )
    )).scalars().all()
    assert len(owner_notifs) == 1


async def test_complaints_warning_skips_reviews(db, make_user, make_clinic, monkeypatch):
    """Жалобы на отзывы не вызывают предупреждение владельцу — только админу."""
    from app.core import config as cfg
    monkeypatch.setattr(cfg.settings, "COMPLAINTS_WARNING_THRESHOLD", 2)

    admin = await make_user(role="admin")
    patient = await make_user(role="patient")

    for _ in range(2):
        db.add(Complaint(
            author_id=patient.id, target_type="review", target_id=999,
            reason="spam", status="new",
            created_at=datetime.now(timezone.utc),
        ))
    await db.flush()

    result = await complaints_warning.run(db)
    assert result["warned"] == 0  # отзывы пропускаем
