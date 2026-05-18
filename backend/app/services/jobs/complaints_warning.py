"""Авто-обработка жалоб на врачей / клиники / филиалы аптек.

Логика (считаем ВСЕ жалобы за всё время по каждой цели):
  • >= 10  (COMPLAINT_NOTIFY_1)  — первое уведомление владельцу
  • >= 100 (COMPLAINT_NOTIFY_2)  — повторное уведомление
  • >= 300 (COMPLAINT_BLOCK_AT)  — блокировка аккаунта на COMPLAINT_BLOCK_DAYS дней

Дедуп: в текущем окне (1 день) не шлём дубли одного типа на ту же цель.
Блокировка: устанавливает user.complaint_blocked_until = now + N дней
             и user.is_active = False.
Разблокировка: ежедневный job unblock_expired (в scheduler.py).
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

_ROUTE_MAP = {
    "doctor": "/main/doctors/{}",
    "clinic": "/main/clinics/{}",
    "pharmacy_branch": "/main/pharmacies/branch/{}",
}


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


async def _sent_today(db: AsyncSession, notif_type: str, target_type: str, target_id: int) -> bool:
    """Проверяем: отправляли ли уже сегодня такое уведомление на эту цель."""
    since = datetime.now(timezone.utc) - timedelta(hours=24)
    rows = await db.execute(
        select(Notification.data).where(
            and_(Notification.type == notif_type, Notification.created_at >= since)
        )
    )
    for (data,) in rows.all():
        if (
            isinstance(data, dict)
            and data.get("target_type") == target_type
            and data.get("target_id") == target_id
        ):
            return True
    return False


def _notif(user_id: int, title: str, body: str, notif_type: str, data: dict) -> Notification:
    return Notification(user_id=user_id, title=title, body=body, type=notif_type, data=data)


async def run(db: AsyncSession) -> dict:
    n1 = settings.COMPLAINT_NOTIFY_1
    n2 = settings.COMPLAINT_NOTIFY_2
    n_block = settings.COMPLAINT_BLOCK_AT
    block_days = settings.COMPLAINT_BLOCK_DAYS

    # Все жалобы суммарно по каждой цели
    rows = (await db.execute(
        select(Complaint.target_type, Complaint.target_id, func.count(Complaint.id))
        .where(Complaint.target_type != "review")
        .group_by(Complaint.target_type, Complaint.target_id)
        .having(func.count(Complaint.id) >= n1)
    )).all()

    admin_ids = [u for (u,) in (await db.execute(
        select(User.id).where(User.role == "admin")
    )).all()]

    notified = 0
    blocked = 0

    for target_type, target_id, count in rows:
        owner_id = await _owner_user_id(db, target_type, target_id)
        route = _ROUTE_MAP.get(target_type, "").format(target_id)
        data = {"target_type": target_type, "target_id": target_id, "route": route}

        if count >= n_block:
            # ── Блокировка на 14 дней ──────────────────────────────────
            if await _sent_today(db, "complaint_blocked", target_type, target_id):
                continue
            if owner_id:
                user_res = await db.execute(select(User).where(User.id == owner_id))
                user = user_res.scalar_one_or_none()
                if user and user.is_active:
                    block_until = datetime.now(timezone.utc) + timedelta(days=block_days)
                    user.is_active = False
                    user.complaint_blocked_until = block_until
                    blocked += 1
                    db.add(_notif(
                        owner_id,
                        "Аккаунт заблокирован",
                        (f"Ваш аккаунт заблокирован на {block_days} дней: "
                         f"на ваш профиль поступило {count} жалоб. "
                         "Свяжитесь с поддержкой."),
                        "complaint_blocked",
                        {**data, "count": count, "block_days": block_days},
                    ))
                    for aid in admin_ids:
                        db.add(_notif(
                            aid,
                            f"🔴 Авто-блокировка: {target_type} #{target_id}",
                            f"{count} жалоб — аккаунт заблокирован на {block_days} дней.",
                            "complaint_blocked",
                            {**data, "count": count},
                        ))
                    logger.warning(
                        "AUTO-BLOCKED %s #%d (%d complaints, %d days)",
                        target_type, target_id, count, block_days,
                    )
            notified += 1

        elif count >= n2:
            # ── Второе уведомление ────────────────────────────────────
            if await _sent_today(db, "complaint_warning_2", target_type, target_id):
                continue
            if owner_id:
                db.add(_notif(
                    owner_id,
                    "⚠️ Критически много жалоб",
                    (f"На ваш профиль поступило уже {count} жалоб. "
                     f"При {n_block} жалобах аккаунт будет заблокирован на {block_days} дней."),
                    "complaint_warning_2",
                    {**data, "count": count},
                ))
            for aid in admin_ids:
                db.add(_notif(
                    aid,
                    f"⚠️ {count} жалоб на {target_type} #{target_id}",
                    f"Второе предупреждение (порог блокировки: {n_block}).",
                    "complaint_warning_2",
                    {**data, "count": count},
                ))
            notified += 1

        else:
            # ── Первое уведомление (>= 10) ────────────────────────────
            if await _sent_today(db, "complaint_warning_1", target_type, target_id):
                continue
            if owner_id:
                db.add(_notif(
                    owner_id,
                    "На вас поступили жалобы",
                    (f"На ваш профиль поступило {count} жалоб. "
                     f"При {n2} жалобах придёт серьёзное предупреждение, "
                     f"при {n_block} — блокировка на {block_days} дней."),
                    "complaint_warning_1",
                    {**data, "count": count},
                ))
            for aid in admin_ids:
                db.add(_notif(
                    aid,
                    f"ℹ️ {count} жалоб на {target_type} #{target_id}",
                    f"Первое предупреждение (порог: {n1}).",
                    "complaint_warning_1",
                    {**data, "count": count},
                ))
            notified += 1

    if notified or blocked:
        await db.flush()

    logger.info(
        "complaints job: notified=%d, blocked=%d (n1=%d, n2=%d, block_at=%d)",
        notified, blocked, n1, n2, n_block,
    )
    return {"notified": notified, "blocked": blocked, "n1": n1, "n2": n2, "block_at": n_block}
