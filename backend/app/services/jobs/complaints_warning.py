"""Авто-предупреждение и авто-блокировка при превышении порога жалоб.

Логика:
  1. Каждые COMPLAINTS_WINDOW_DAYS дней считаем жалобы по каждой цели.
  2. Если >= COMPLAINTS_WARNING_THRESHOLD — шлём предупреждение (1 раз в окно).
  3. После COMPLAINTS_AUTO_BLOCK_AFTER предупреждений подряд — автоматически
     блокируем аккаунт владельца (user.is_active = False) и уведомляем его.
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
    """Возвращает (target_type, target_id) по которым УЖЕ было предупреждение
    в текущем окне — чтобы не слать повторно."""
    res = await db.execute(
        select(Notification.data).where(
            and_(
                Notification.type.in_(["complaints_warning", "complaints_auto_blocked"]),
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


async def _total_warning_count(db: AsyncSession, target_type: str, target_id: int) -> int:
    """Возвращает общее количество предупреждений по цели за всё время."""
    res = await db.execute(
        select(Notification.data).where(Notification.type == "complaints_warning")
    )
    count = 0
    for (data,) in res.all():
        if (
            isinstance(data, dict)
            and data.get("target_type") == target_type
            and data.get("target_id") == target_id
        ):
            count += 1
    return count


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
    auto_block_after = settings.COMPLAINTS_AUTO_BLOCK_AFTER
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
    blocked = 0

    for target_type, target_id, count in rows:
        if target_type == "review":
            continue
        if (target_type, target_id) in already:
            continue

        owner_id = await _owner_user_id(db, target_type, target_id)
        route_tpl = _ROUTE_MAP.get(target_type)
        route = route_tpl.format(target_id) if route_tpl else None
        data = {"target_type": target_type, "target_id": target_id, "route": route}

        # Считаем сколько предупреждений уже было по этой цели
        prev_warnings = await _total_warning_count(db, target_type, target_id)
        # Это будет (prev_warnings + 1)-е предупреждение
        new_warning_num = prev_warnings + 1
        should_block = new_warning_num >= auto_block_after

        if should_block and owner_id:
            # Блокируем аккаунт
            user_res = await db.execute(select(User).where(User.id == owner_id))
            user = user_res.scalar_one_or_none()
            if user and user.is_active:
                user.is_active = False
                blocked += 1
                db.add(Notification(
                    user_id=owner_id,
                    title="Аккаунт заблокирован",
                    body=(
                        f"Ваш аккаунт заблокирован автоматически: на ваш профиль "
                        f"поступило {count} жалоб за {window_days} дней. "
                        f"Это {new_warning_num}-е предупреждение. "
                        "Свяжитесь с поддержкой для разблокировки."
                    ),
                    type="complaints_auto_blocked",
                    data={**data, "warning_num": new_warning_num},
                ))
                for aid in admin_ids:
                    db.add(Notification(
                        user_id=aid,
                        title=f"🔴 Авто-блокировка: {target_type} #{target_id}",
                        body=(
                            f"Аккаунт заблокирован автоматически после "
                            f"{new_warning_num} предупреждений ({count} жалоб за {window_days} дней)."
                        ),
                        type="complaints_auto_blocked",
                        data={**data, "warning_num": new_warning_num},
                    ))
                logger.warning(
                    "AUTO-BLOCKED %s #%d after %d warnings (%d complaints in %dd)",
                    target_type, target_id, new_warning_num, count, window_days,
                )
        else:
            # Обычное предупреждение
            if owner_id:
                db.add(Notification(
                    user_id=owner_id,
                    title="Поступило много жалоб",
                    body=(
                        f"На ваш профиль поступило {count} жалоб за {window_days} дней. "
                        f"Это предупреждение {new_warning_num} из {auto_block_after}. "
                        "При следующем превышении аккаунт может быть заблокирован."
                    ),
                    type="complaints_warning",
                    data={**data, "warning_num": new_warning_num},
                ))
            for aid in admin_ids:
                db.add(Notification(
                    user_id=aid,
                    title=f"⚠️ {count} жалоб на {target_type} #{target_id}",
                    body=(
                        f"Превышен порог жалоб ({threshold}) за {window_days} дней. "
                        f"Предупреждение {new_warning_num}/{auto_block_after}."
                    ),
                    type="complaints_warning",
                    data={**data, "warning_num": new_warning_num},
                ))

        warned += 1

    if warned:
        await db.flush()

    logger.info(
        "complaints_warning: warned=%d, blocked=%d (threshold=%d, window=%dd, auto_block_after=%d)",
        warned, blocked, threshold, window_days, auto_block_after,
    )
    return {
        "warned": warned,
        "blocked": blocked,
        "threshold": threshold,
        "window_days": window_days,
        "auto_block_after": auto_block_after,
    }
