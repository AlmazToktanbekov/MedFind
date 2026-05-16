"""Бизнес-логика подписок: тарифы, лимиты, триал.

Триал даётся ОДИН раз навсегда на (owner_type, owner_id) — фиксируется в TrialUsage.
Активная подписка определяется по статусу = "active" и expires_at в будущем (или null для free).
"""
from datetime import datetime, timezone, timedelta
from typing import Optional, Literal

from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.subscription import Subscription, TrialUsage
from app.models.doctor import Doctor
from app.models.pharmacy import PharmacyBranch

OwnerType = Literal["clinic", "pharmacy"]
Plan = Literal["free", "pro", "premium"]


def get_doctor_limit(plan: Plan) -> Optional[int]:
    """Возвращает лимит врачей для плана. None = безлимит."""
    if plan == "free":
        return settings.CLINIC_FREE_DOCTOR_LIMIT
    return None


def get_branch_limit(plan: Plan) -> Optional[int]:
    """Возвращает лимит филиалов для плана. None = безлимит."""
    if plan == "free":
        return settings.PHARMACY_FREE_BRANCH_LIMIT
    return None


async def get_active_subscription(
    db: AsyncSession, owner_type: OwnerType, owner_id: int
) -> Optional[Subscription]:
    """Возвращает текущую активную подписку (если не истёк expires_at)."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(Subscription).where(
            Subscription.owner_type == owner_type,
            Subscription.owner_id == owner_id,
            Subscription.status == "active",
        ).order_by(Subscription.created_at.desc())
    )
    sub = result.scalars().first()
    if sub is None:
        return None
    # Если есть expires_at и он в прошлом — помечаем как expired
    if sub.expires_at is not None and sub.expires_at <= now:
        sub.status = "expired"
        return None
    return sub


async def get_plan(db: AsyncSession, owner_type: OwnerType, owner_id: int) -> Plan:
    """Возвращает текущий план: 'free' если нет активной подписки."""
    sub = await get_active_subscription(db, owner_type, owner_id)
    if sub is None:
        return "free"
    return sub.plan  # type: ignore


async def _trial_was_used(db: AsyncSession, owner_type: OwnerType, owner_id: int) -> bool:
    r = await db.execute(
        select(TrialUsage).where(
            TrialUsage.owner_type == owner_type,
            TrialUsage.owner_id == owner_id,
        )
    )
    return r.scalar_one_or_none() is not None


async def start_trial(
    db: AsyncSession, owner_type: OwnerType, owner_id: int
) -> Optional[Subscription]:
    """Создаёт триальную Pro-подписку на TRIAL_DAYS дней.
    Если триал уже использовался — возвращает None и ничего не создаёт.
    """
    if await _trial_was_used(db, owner_type, owner_id):
        return None

    now = datetime.now(timezone.utc)
    sub = Subscription(
        owner_type=owner_type,
        owner_id=owner_id,
        plan="pro",
        period="month",
        is_trial=True,
        started_at=now,
        expires_at=now + timedelta(days=settings.TRIAL_DAYS),
        status="active",
    )
    db.add(sub)
    db.add(TrialUsage(owner_type=owner_type, owner_id=owner_id, used_at=now))
    await db.flush()
    return sub


async def count_active_doctors(db: AsyncSession, clinic_id: int) -> int:
    """Считает врачей со статусом 'active' в клинике."""
    r = await db.execute(
        select(func.count(Doctor.id)).where(
            Doctor.clinic_id == clinic_id,
            Doctor.status == "active",
        )
    )
    return r.scalar_one()


async def count_active_branches(db: AsyncSession, company_id: int) -> int:
    """Считает активные филиалы аптечной компании."""
    r = await db.execute(
        select(func.count(PharmacyBranch.id)).where(
            PharmacyBranch.company_id == company_id,
            PharmacyBranch.is_active == True,  # noqa: E712
        )
    )
    return r.scalar_one()


def days_left(sub: Optional[Subscription]) -> Optional[int]:
    """Сколько дней осталось до конца подписки. None для free / безлимита."""
    if sub is None or sub.expires_at is None:
        return None
    delta = sub.expires_at - datetime.now(timezone.utc)
    return max(0, delta.days)


async def has_analytics_access(
    db: AsyncSession, owner_type: OwnerType, owner_id: int
) -> bool:
    """Доступ к Premium-отчётам: активный Premium ИЛИ Premium закончился не более
    PREMIUM_REPORTS_RETENTION_DAYS назад (grace-период из CLAUDE.md = 30 дней)."""
    # Активная Premium?
    active = await get_active_subscription(db, owner_type, owner_id)
    if active is not None and active.plan == "premium":
        return True

    # Был Premium недавно (grace)?
    from datetime import timedelta
    cutoff = datetime.now(timezone.utc) - timedelta(days=settings.PREMIUM_REPORTS_RETENTION_DAYS)
    r = await db.execute(
        select(Subscription).where(
            Subscription.owner_type == owner_type,
            Subscription.owner_id == owner_id,
            Subscription.plan == "premium",
            Subscription.expires_at != None,  # noqa: E711
            Subscription.expires_at >= cutoff,
        ).limit(1)
    )
    return r.scalar_one_or_none() is not None


async def set_plan_manual(
    db: AsyncSession,
    owner_type: OwnerType,
    owner_id: int,
    plan: Plan,
    days: int,
    period: str = "month",
) -> Subscription:
    """Ручное включение подписки админом (без оплаты). Закрывает старую active, создаёт новую."""
    now = datetime.now(timezone.utc)
    # Закрыть предыдущую активную
    r = await db.execute(
        select(Subscription).where(
            Subscription.owner_type == owner_type,
            Subscription.owner_id == owner_id,
            Subscription.status == "active",
        )
    )
    for old in r.scalars().all():
        old.status = "cancelled"

    sub = Subscription(
        owner_type=owner_type,
        owner_id=owner_id,
        plan=plan,
        period=period,
        is_trial=False,
        started_at=now,
        expires_at=now + timedelta(days=days) if plan != "free" else None,
        status="active",
    )
    db.add(sub)
    await db.flush()
    return sub
