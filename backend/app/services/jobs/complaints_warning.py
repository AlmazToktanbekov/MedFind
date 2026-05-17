"""Авто-предупреждение клиник/аптек/врачей при превышении порога жалоб.

Считаем жалобы по каждой цели за окно (COMPLAINTS_WINDOW_DAYS дней).
Если >= COMPLAINTS_WARNING_THRESHOLD — шлём push владельцу (клиника / аптечная
компания / врач) и админам.

Чтобы не спамить, выставляем флаг через таблицу notifications — если за окно
уже было notification с type="complaints_warning" и тем же target — пропускаем.
"""
import logging
from datetime import datetime, timezone, timedelta

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.complaint import Complaint
from app.models.notification import Notification
from app.models.clinic import Clinic
from app.models.doctor import Doctor
from app.models.pharmacy import PharmacyBranch, PharmacyCompany
from app.models.user import User

logger = logging.getLogger(__name__)


async def _recent_warnings(db: AsyncSession, since) -> set[tuple[str, int]]:
    """Возвращает множество (target_type, target_id), по которым уже было
    предупреждение в окне — чтобы не слать повторно."""
    res = await db.execute(
        select(Notification.data).where(
            and_(
                Notification.type == "complaints_warning",
                Notification.created_at >= since,
            )
        )
    )
    out: set[tuple[str, int]] = set()
    for (data,) in res.all():
        if isinstance(data, dict) and data.get("target_type") and data.get("target_id"):
            try:
                out.add((data["target_type"], int(data["target_id"])))
            except (TypeError, ValueError):
                pass
    return out


async def _owner_user_id(db: AsyncSession, target_type: str, target_id: int):
    if target_type == "doctor":
        r = await db.execute(select(Doctor.user_id).where(Doctor.id == target_id))
        return r.scalar_one_or_none()
    if target_type == "clinic":
        r = await db.execute(select(Clinic.user_id).where(Clinic.id == target_id))
        return r.scalar_one_or_none()
    if target_type == "pharmacy_branch":
        r = await db.execute(
            select(PharmacyCompany.user_id)
            .join(PharmacyBranch, PharmacyBranch.company_id == PharmacyCompany.id)
            .where(PharmacyBranch.id == target_id)
        )
        return r.scalar_one_or_none()
    return None


_ROUTE_MAP = {
    "doctor": "/main/doctors/{}",
    "clinic": "/main/clinics/{}",
    "pharmacy_branch": "/main/pharmacies/branch/{}",
}


async def run(db: AsyncSession) -> dict:
    threshold = settings.COMPLAINTS_WARNING_THRESHOLD
    window_days = settings.COMPLAINTS_WINDOW_DAYS
    since = datetime.now(timezone.utc) - timedelta(days=window_days)

    rows = (await db.execute(
        select(
            Complaint.target_type, Complaint.target_id, func.count(Complaint.id)
        ).where(Complaint.created_at >= since)
        .group_by(Complaint.target_type, Complaint.target_id)
        .having(func.count(Complaint.id) >= threshold)
    )).all()

    admin_ids = [u for (u,) in (await db.execute(
        select(User.id).where(User.role == "admin")
    )).all()]

    already = await _recent_warnings(db, since)
    warned = 0
    for target_type, target_id, count in rows:
        if target_type == "review":
            continue  # на отзывы шлём только админу (см. ниже)
        if (target_type, target_id) in already:
            continue

        owner_id = await _owner_user_id(db, target_type, target_id)
        route_tpl = _ROUTE_MAP.get(target_type)
        route = route_tpl.format(target_id) if route_tpl else None
        data = {"target_type": target_type, "target_id": target_id, "route": route}

        if owner_id:
            db.add(Notification(
                user_id=owner_id,
                title="Поступило много жалоб",
                body=(f"На ваш профиль поступило {count} жалоб за {window_days} дней. "
                      "Профиль может быть заблокирован. Свяжитесь с поддержкой."),
                type="complaints_warning",
                data=data,
            ))
        for aid in admin_ids:
            db.add(Notification(
                user_id=aid,
                title=f"⚠️ {count} жалоб на {target_type} #{target_id}",
                body=f"Превышен порог жалоб ({threshold}) за {window_days} дней.",
                type="complaints_warning",
                data=data,
            ))
        warned += 1

    if warned:
        await db.flush()

    logger.info(
        "complaints_warning: warned=%d (threshold=%d, window=%dd)",
        warned, threshold, window_days,
    )
    return {"warned": warned, "threshold": threshold, "window_days": window_days}
