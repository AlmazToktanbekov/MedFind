"""Обработка истёкших подписок.

Что делает:
1. Берёт все active-подписки с expires_at в прошлом
2. Помечает их как expired
3. Деактивирует «лишних» врачей/филиалы согласно лимиту Free:
   - Клиника: первые CLINIC_FREE_DOCTOR_LIMIT по дате остаются active, остальные → deactivated
   - Аптека: первые PHARMACY_FREE_BRANCH_LIMIT остаются, остальные → is_active=false
4. Шлёт push владельцу о деактивации
"""
import logging
from datetime import datetime, timezone

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.subscription import Subscription
from app.models.doctor import Doctor
from app.models.pharmacy import PharmacyBranch
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany
from app.models.user import User
from app.services.fcm import send_push

logger = logging.getLogger(__name__)


async def _resolve_owner_user(db: AsyncSession, owner_type: str, owner_id: int):
    """Возвращает (user_id, fcm_token, name)."""
    if owner_type == "clinic":
        r = await db.execute(
            select(Clinic.user_id, Clinic.name_ru).where(Clinic.id == owner_id)
        )
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


async def _deactivate_extra_doctors(db: AsyncSession, clinic_id: int) -> int:
    """Оставляет первые CLINIC_FREE_DOCTOR_LIMIT active по created_at, остальных → deactivated."""
    r = await db.execute(
        select(Doctor)
        .where(Doctor.clinic_id == clinic_id, Doctor.status == "active")
        .order_by(Doctor.created_at.asc())
    )
    actives = list(r.scalars().all())
    limit = settings.CLINIC_FREE_DOCTOR_LIMIT
    deactivated = 0
    for doctor in actives[limit:]:
        doctor.status = "deactivated"
        deactivated += 1
    return deactivated


async def _deactivate_extra_branches(db: AsyncSession, company_id: int) -> int:
    """Оставляет первые PHARMACY_FREE_BRANCH_LIMIT активных, остальные → is_active=False."""
    r = await db.execute(
        select(PharmacyBranch)
        .where(
            PharmacyBranch.company_id == company_id,
            PharmacyBranch.is_active == True,  # noqa: E712
        )
        .order_by(PharmacyBranch.created_at.asc())
    )
    actives = list(r.scalars().all())
    limit = settings.PHARMACY_FREE_BRANCH_LIMIT
    deactivated = 0
    for branch in actives[limit:]:
        branch.is_active = False
        deactivated += 1
    return deactivated


async def run(db: AsyncSession) -> dict:
    now = datetime.now(timezone.utc)
    expired = 0
    doctors_deactivated_total = 0
    branches_deactivated_total = 0

    # Все active с истёкшим сроком
    r = await db.execute(
        select(Subscription).where(
            Subscription.status == "active",
            Subscription.expires_at != None,  # noqa: E711
            Subscription.expires_at <= now,
        )
    )
    subs_list = list(r.scalars().all())

    for sub in subs_list:
        sub.status = "expired"
        expired += 1

        if sub.owner_type == "clinic":
            deact = await _deactivate_extra_doctors(db, sub.owner_id)
            doctors_deactivated_total += deact
        else:
            deact = await _deactivate_extra_branches(db, sub.owner_id)
            branches_deactivated_total += deact

        user_id, fcm, name = await _resolve_owner_user(db, sub.owner_type, sub.owner_id)
        if user_id is not None:
            if sub.owner_type == "clinic":
                title = "Подписка истекла"
                body = (
                    f"Подписка {sub.plan.upper()} закончилась. "
                    f"Деактивировано лишних врачей: {deact}. "
                    f"Пополните счёт и продлите тариф."
                ) if deact > 0 else (
                    f"Подписка {sub.plan.upper()} закончилась. Тариф понижен до Free."
                )
            else:
                title = "Подписка истекла"
                body = (
                    f"Подписка закончилась. Деактивировано лишних филиалов: {deact}. "
                    f"Пополните счёт и продлите тариф."
                ) if deact > 0 else (
                    "Подписка закончилась. Тариф понижен до Free."
                )

            await send_push(
                fcm, title, body,
                notification_type="subscription_expired",
                data={"route": "/subscription"},
                db=db,
                user_id=user_id,
            )

        logger.info("Expired subscription for %s #%s, deactivated extras: %d",
                    sub.owner_type, sub.owner_id, deact)

    return {
        "expired": expired,
        "doctors_deactivated": doctors_deactivated_total,
        "branches_deactivated": branches_deactivated_total,
    }
