"""Тесты аналитики: трекинг событий + агрегации отчётов."""
from datetime import datetime, timezone, timedelta

import pytest

from app.services import analytics_service as analytics


async def test_track_event_view_clinic(db, make_clinic):
    clinic = await make_clinic()

    await analytics.track_event(
        db,
        event_type="view_clinic",
        target_type="clinic",
        target_id=clinic.id,
    )
    await db.flush()

    from sqlalchemy import select, func
    from app.models.analytics import AnalyticsEvent
    r = await db.execute(select(func.count(AnalyticsEvent.id)))
    assert r.scalar_one() == 1


async def test_track_view_doctor_denormalizes_clinic_id(db, make_clinic, make_doctor):
    """При view_doctor система должна записать clinic_id для быстрых отчётов."""
    clinic = await make_clinic()
    doctor = await make_doctor(clinic=clinic)

    await analytics.track_event(
        db,
        event_type="view_doctor",
        target_type="doctor",
        target_id=doctor.id,
    )
    await db.flush()

    from sqlalchemy import select
    from app.models.analytics import AnalyticsEvent
    r = await db.execute(select(AnalyticsEvent))
    event = r.scalar_one()
    assert event.clinic_id == clinic.id  # денормализовано


async def test_clinic_report_aggregates_metrics(db, make_clinic, make_doctor):
    """get_clinic_report считает все 8+ метрик за период."""
    clinic = await make_clinic()
    doctor = await make_doctor(clinic=clinic)

    # 3 просмотра клиники + 2 звонка + 1 WhatsApp
    for _ in range(3):
        await analytics.track_event(db, "view_clinic", "clinic", clinic.id)
    for _ in range(2):
        await analytics.track_event(db, "click_call", "doctor", doctor.id)
    await analytics.track_event(db, "click_whatsapp", "clinic", clinic.id)
    await db.flush()

    now = datetime.now(timezone.utc)
    report = await analytics.get_clinic_report(
        db, clinic.id,
        from_dt=now - timedelta(days=1),
        to_dt=now + timedelta(days=1),
    )

    s = report["summary"]
    assert s["view_clinic"] == 3
    assert s["click_call"] == 2
    assert s["click_whatsapp"] == 1
    assert s["view_doctor"] == 0


async def test_clinic_report_doctors_breakdown(db, make_clinic, make_doctor):
    """Топ врачей сортируется по просмотрам убыванию."""
    clinic = await make_clinic()
    doc_a = await make_doctor(clinic=clinic)
    doc_b = await make_doctor(clinic=clinic)

    # doc_a: 5 просмотров, doc_b: 2 просмотра
    for _ in range(5):
        await analytics.track_event(db, "view_doctor", "doctor", doc_a.id)
    for _ in range(2):
        await analytics.track_event(db, "view_doctor", "doctor", doc_b.id)
    await db.flush()

    now = datetime.now(timezone.utc)
    report = await analytics.get_clinic_report(
        db, clinic.id,
        from_dt=now - timedelta(days=1),
        to_dt=now + timedelta(days=1),
    )

    doctors = report["doctors"]
    assert len(doctors) == 2
    assert doctors[0]["id"] == doc_a.id
    assert doctors[0]["views"] == 5
    assert doctors[1]["id"] == doc_b.id
    assert doctors[1]["views"] == 2


async def test_branch_report_isolated_from_clinic(db, make_pharmacy, make_clinic):
    """Отчёт филиала не показывает события другой клиники."""
    from app.models.pharmacy import PharmacyBranch

    pharmacy = await make_pharmacy()
    branch = PharmacyBranch(
        company_id=pharmacy.id,
        address="Test st 1",
        is_active=True,
    )
    db.add(branch)
    await db.flush()

    clinic = await make_clinic()

    # 2 события на филиал, 3 на клинику
    await analytics.track_event(db, "view_pharmacy_branch", "pharmacy_branch", branch.id)
    await analytics.track_event(db, "click_call", "pharmacy_branch", branch.id)
    for _ in range(3):
        await analytics.track_event(db, "view_clinic", "clinic", clinic.id)
    await db.flush()

    now = datetime.now(timezone.utc)
    report = await analytics.get_branch_report(
        db, branch.id,
        from_dt=now - timedelta(days=1),
        to_dt=now + timedelta(days=1),
    )

    assert report["summary"]["view_pharmacy_branch"] == 1
    assert report["summary"]["click_call"] == 1
    # События клиники сюда не попали
    assert report["summary"]["view_clinic"] == 0


async def test_events_outside_period_are_excluded(db, make_clinic):
    """События до from_dt или после to_dt не учитываются."""
    clinic = await make_clinic()
    await analytics.track_event(db, "view_clinic", "clinic", clinic.id)
    await db.flush()

    # Период в прошлом
    now = datetime.now(timezone.utc)
    report = await analytics.get_clinic_report(
        db, clinic.id,
        from_dt=now - timedelta(days=10),
        to_dt=now - timedelta(days=5),
    )
    assert report["summary"]["view_clinic"] == 0
