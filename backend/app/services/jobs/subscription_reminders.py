"""Напоминания о скором окончании подписки.

За SUBSCRIPTION_REMINDER_DAYS дней до expires_at отправляет push владельцу клиники/аптеки.
"""
import logging
from datetime import datetime, timezone, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.subscription import Subscription
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany
from app.models.user import User
from app.services.fcm import send_push

logger = logging.getLogger(__name__)


async def _resolve_owner_user(db: AsyncSession, owner_type: str, owner_id: int):
    """Возвращает (user_id, fcm_token, display_name) владельца клиники/аптеки."""
    if owner_type == "clinic":
        r = await db.execute(
            select(Clinic.user_id, Clinic.name_ru).where(Clinic.id == owner_id)
        )
        row = r.one_or_none()
    else:
        r = await db.execute(
            select(PharmacyCompany.user_id, PharmacyCompany.name).where(PharmacyCompany.id == owner_id)
        )
        row = r.one_or_none()
    if not row or not row[0]:
        return None, None, None
    user_id, name = row[0], row[1]
    fcm_r = await db.execute(select(User.fcm_token).where(User.id == user_id))
    fcm = fcm_r.scalar_one_or_none()
    return user_id, fcm, name


async def run(db: AsyncSession) -> dict:
    """Главная функция задачи. Возвращает статистику по отправленным напоминаниям."""
    now = datetime.now(timezone.utc)
    sent = 0
    skipped = 0

    # Берём все активные подписки с expires_at в будущем
    r = await db.execute(
        select(Subscription).where(
            Subscription.status == "active",
            Subscription.expires_at != None,  # noqa: E711
            Subscription.expires_at > now,
        )
    )
    subs_list = list(r.scalars().all())

    for sub in subs_list:
        # Сколько целых дней осталось
        delta = sub.expires_at - now
        days_left = delta.days
        if days_left not in settings.SUBSCRIPTION_REMINDER_DAYS:
            skipped += 1
            continue

        user_id, fcm, name = await _resolve_owner_user(db, sub.owner_type, sub.owner_id)
        if user_id is None:
            skipped += 1
            continue

        plan_label = sub.plan.upper()
        title = f"Подписка {plan_label} скоро закончится"
        body = f"Через {days_left} {'день' if days_left == 1 else 'дн.'} истекает подписка. Пополните счёт и продлите."

        await send_push(
            fcm, title, body,
            notification_type="subscription_expiring",
            data={"route": "/subscription", "days_left": str(days_left)},
            db=db,
            user_id=user_id,
        )
        sent += 1
        logger.info("Sent reminder to %s #%s (%s): %d days", sub.owner_type, sub.owner_id, name, days_left)

    return {"sent": sent, "skipped": skipped, "total": len(subs_list)}
