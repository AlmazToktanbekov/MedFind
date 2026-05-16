"""Сервис аналитики: запись событий и агрегация отчётов."""
import json
from datetime import datetime, timezone, date as date_cls, timedelta
from typing import Optional, List, Dict, Any

from sqlalchemy import select, func, and_, case
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.analytics import AnalyticsEvent
from app.models.doctor import Doctor
from app.models.pharmacy import PharmacyBranch
from app.models.review import Review


# ─── Запись событий ──────────────────────────────────────────────────────

async def _resolve_clinic_id(db: AsyncSession, target_type: Optional[str], target_id: Optional[int]) -> Optional[int]:
    """Денормализация: вычисляем clinic_id, чтобы потом не делать JOIN."""
    if target_id is None:
        return None
    if target_type == "clinic":
        return target_id
    if target_type == "doctor":
        r = await db.execute(select(Doctor.clinic_id).where(Doctor.id == target_id))
        return r.scalar_one_or_none()
    return None


async def _resolve_branch_id(target_type: Optional[str], target_id: Optional[int]) -> Optional[int]:
    if target_type == "pharmacy_branch":
        return target_id
    return None


async def track_event(
    db: AsyncSession,
    event_type: str,
    target_type: Optional[str] = None,
    target_id: Optional[int] = None,
    user_id: Optional[int] = None,
    metadata: Optional[Dict[str, Any]] = None,
) -> None:
    """Записывает одно событие. Денормализует clinic_id/branch_id."""
    clinic_id = await _resolve_clinic_id(db, target_type, target_id)
    branch_id = await _resolve_branch_id(target_type, target_id)
    db.add(AnalyticsEvent(
        event_type=event_type,
        target_type=target_type,
        target_id=target_id,
        clinic_id=clinic_id,
        pharmacy_branch_id=branch_id,
        user_id=user_id,
        metadata_json=json.dumps(metadata) if metadata else None,
    ))


# ─── Агрегации ────────────────────────────────────────────────────────────

EVENT_TYPES_FOR_SUMMARY = [
    "view_clinic", "view_doctor", "view_pharmacy_branch",
    "click_call", "click_whatsapp", "click_telegram",
    "click_route", "add_favorite",
]


async def _count_by_event_type(
    db: AsyncSession,
    *,
    clinic_id: Optional[int] = None,
    branch_id: Optional[int] = None,
    from_dt: datetime,
    to_dt: datetime,
) -> Dict[str, int]:
    q = select(AnalyticsEvent.event_type, func.count(AnalyticsEvent.id)).where(
        AnalyticsEvent.created_at >= from_dt,
        AnalyticsEvent.created_at < to_dt,
    )
    if clinic_id is not None:
        q = q.where(AnalyticsEvent.clinic_id == clinic_id)
    if branch_id is not None:
        q = q.where(AnalyticsEvent.pharmacy_branch_id == branch_id)
    q = q.group_by(AnalyticsEvent.event_type)
    r = await db.execute(q)
    counts = {row[0]: row[1] for row in r.all()}
    return {et: counts.get(et, 0) for et in EVENT_TYPES_FOR_SUMMARY}


async def _clinic_review_stats(db: AsyncSession, clinic_id: int) -> Dict[str, Any]:
    """Средний рейтинг и общее число отзывов клиники (включая её врачей)."""
    # Отзывы на клинику + на врачей этой клиники
    doctor_ids_q = select(Doctor.id).where(Doctor.clinic_id == clinic_id)
    r = await db.execute(doctor_ids_q)
    doctor_ids = [row[0] for row in r.all()]

    cond = Review.clinic_id == clinic_id
    if doctor_ids:
        cond = (Review.clinic_id == clinic_id) | (Review.doctor_id.in_(doctor_ids))

    r = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(cond)
    )
    avg, cnt = r.one()
    return {
        "avg_rating": round(float(avg), 2) if avg is not None else 0.0,
        "reviews_count": int(cnt or 0),
    }


async def _branch_review_stats(db: AsyncSession, branch_id: int) -> Dict[str, Any]:
    r = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id))
        .where(Review.branch_id == branch_id)
    )
    avg, cnt = r.one()
    return {
        "avg_rating": round(float(avg), 2) if avg is not None else 0.0,
        "reviews_count": int(cnt or 0),
    }


async def _doctors_breakdown(
    db: AsyncSession, clinic_id: int, from_dt: datetime, to_dt: datetime
) -> List[Dict[str, Any]]:
    """Топ врачей клиники с метриками. Сортировка по просмотрам DESC."""
    # Все активные врачи клиники
    r = await db.execute(
        select(Doctor.id, Doctor.full_name_ru, Doctor.photo_url, Doctor.specialization_ru)
        .where(Doctor.clinic_id == clinic_id, Doctor.status == "active")
    )
    doctors = [
        {"id": row[0], "full_name": row[1], "photo_url": row[2], "specialization": row[3]}
        for row in r.all()
    ]
    if not doctors:
        return []

    doctor_ids = [d["id"] for d in doctors]

    # Считаем события по каждому врачу
    r = await db.execute(
        select(
            AnalyticsEvent.target_id,
            AnalyticsEvent.event_type,
            func.count(AnalyticsEvent.id),
        ).where(
            AnalyticsEvent.target_type == "doctor",
            AnalyticsEvent.target_id.in_(doctor_ids),
            AnalyticsEvent.created_at >= from_dt,
            AnalyticsEvent.created_at < to_dt,
        ).group_by(AnalyticsEvent.target_id, AnalyticsEvent.event_type)
    )
    counts_map: Dict[int, Dict[str, int]] = {}
    for tid, etype, c in r.all():
        counts_map.setdefault(tid, {})[etype] = c

    for d in doctors:
        c = counts_map.get(d["id"], {})
        d["views"] = c.get("view_doctor", 0)
        d["calls"] = c.get("click_call", 0)
        d["whatsapp"] = c.get("click_whatsapp", 0)
        d["telegram"] = c.get("click_telegram", 0)

    doctors.sort(key=lambda x: x["views"], reverse=True)
    return doctors


async def _daily_timeline(
    db: AsyncSession,
    *,
    clinic_id: Optional[int] = None,
    branch_id: Optional[int] = None,
    from_dt: datetime,
    to_dt: datetime,
) -> List[Dict[str, Any]]:
    """Группировка по дням: views (все view_*), calls, whatsapp."""
    day = func.date_trunc("day", AnalyticsEvent.created_at).label("day")
    q = select(
        day,
        func.sum(case((AnalyticsEvent.event_type.in_(["view_clinic", "view_doctor", "view_pharmacy_branch"]), 1), else_=0)).label("views"),
        func.sum(case((AnalyticsEvent.event_type == "click_call", 1), else_=0)).label("calls"),
        func.sum(case((AnalyticsEvent.event_type == "click_whatsapp", 1), else_=0)).label("whatsapp"),
    ).where(
        AnalyticsEvent.created_at >= from_dt,
        AnalyticsEvent.created_at < to_dt,
    )
    if clinic_id is not None:
        q = q.where(AnalyticsEvent.clinic_id == clinic_id)
    if branch_id is not None:
        q = q.where(AnalyticsEvent.pharmacy_branch_id == branch_id)
    q = q.group_by(day).order_by(day)
    r = await db.execute(q)
    return [
        {
            "date": row.day.date().isoformat(),
            "views": int(row.views or 0),
            "calls": int(row.calls or 0),
            "whatsapp": int(row.whatsapp or 0),
        }
        for row in r.all()
    ]


async def get_clinic_report(
    db: AsyncSession, clinic_id: int, from_dt: datetime, to_dt: datetime
) -> Dict[str, Any]:
    summary = await _count_by_event_type(db, clinic_id=clinic_id, from_dt=from_dt, to_dt=to_dt)
    reviews = await _clinic_review_stats(db, clinic_id)
    summary.update(reviews)
    doctors = await _doctors_breakdown(db, clinic_id, from_dt, to_dt)
    timeline = await _daily_timeline(db, clinic_id=clinic_id, from_dt=from_dt, to_dt=to_dt)
    return {
        "period": {"from": from_dt.isoformat(), "to": to_dt.isoformat()},
        "summary": summary,
        "doctors": doctors,
        "daily_timeline": timeline,
    }


async def get_branch_report(
    db: AsyncSession, branch_id: int, from_dt: datetime, to_dt: datetime
) -> Dict[str, Any]:
    summary = await _count_by_event_type(db, branch_id=branch_id, from_dt=from_dt, to_dt=to_dt)
    reviews = await _branch_review_stats(db, branch_id)
    summary.update(reviews)
    timeline = await _daily_timeline(db, branch_id=branch_id, from_dt=from_dt, to_dt=to_dt)
    return {
        "period": {"from": from_dt.isoformat(), "to": to_dt.isoformat()},
        "summary": summary,
        "doctors": [],
        "daily_timeline": timeline,
    }
