"""Роутер подписок: текущий план пользователя, тарифные планы."""
from datetime import datetime, timezone
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.config import settings
from app.core.security import get_current_user
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany
from app.services import subscription_service as subs

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


class SubscriptionOut(BaseModel):
    owner_type: str             # "clinic" | "pharmacy"
    owner_id: int
    plan: str                   # "free" | "pro" | "premium"
    period: Optional[str]
    is_trial: bool
    started_at: Optional[datetime]
    expires_at: Optional[datetime]
    days_left: Optional[int]
    doctor_limit: Optional[int]
    branch_limit: Optional[int]
    current_doctors: Optional[int] = None
    current_branches: Optional[int] = None


class PlanInfo(BaseModel):
    plan: str
    price_usd_month: int
    price_usd_year: int
    price_kgs_month: int
    price_kgs_year: int
    doctor_limit: Optional[int]
    branch_limit: Optional[int]
    has_reports: bool
    has_badge: bool


class PlansResponse(BaseModel):
    usd_to_kgs_rate: float
    plans: List[PlanInfo]


async def _resolve_owner(current_user, db: AsyncSession):
    """Определяет owner_type и owner_id для текущего юзера по его роли."""
    if current_user.role == "clinic":
        r = await db.execute(
            select(Clinic).where(Clinic.user_id == current_user.id).limit(1)
        )
        clinic = r.scalar_one_or_none()
        if clinic is None:
            return None
        return "clinic", clinic.id
    if current_user.role == "pharmacy":
        r = await db.execute(
            select(PharmacyCompany).where(PharmacyCompany.user_id == current_user.id).limit(1)
        )
        company = r.scalar_one_or_none()
        if company is None:
            return None
        return "pharmacy", company.id
    return None


@router.get("/me", response_model=Optional[SubscriptionOut])
async def get_my_subscription(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Текущая подписка владельца (по его клинике или аптечной компании).
    Возвращает null если у юзера нет клиники/аптеки."""
    owner = await _resolve_owner(current_user, db)
    if owner is None:
        return None
    owner_type, owner_id = owner

    sub = await subs.get_active_subscription(db, owner_type, owner_id)
    plan = sub.plan if sub else "free"

    current_doctors = await subs.count_active_doctors(db, owner_id) if owner_type == "clinic" else None
    current_branches = await subs.count_active_branches(db, owner_id) if owner_type == "pharmacy" else None

    return SubscriptionOut(
        owner_type=owner_type,
        owner_id=owner_id,
        plan=plan,
        period=sub.period if sub else None,
        is_trial=sub.is_trial if sub else False,
        started_at=sub.started_at if sub else None,
        expires_at=sub.expires_at if sub else None,
        days_left=subs.days_left(sub),
        doctor_limit=subs.get_doctor_limit(plan) if owner_type == "clinic" else None,
        branch_limit=subs.get_branch_limit(plan) if owner_type == "pharmacy" else None,
        current_doctors=current_doctors,
        current_branches=current_branches,
    )


@router.get("/plans", response_model=PlansResponse)
async def get_plans():
    """Возвращает доступные тарифы с ценами в USD и KGS (по курсу из конфига)."""
    rate = settings.USD_TO_KGS_RATE
    months_in_year = 12 - settings.PLAN_YEAR_DISCOUNT_MONTHS  # цена годовой = 10 месяцев

    def kgs(usd: int) -> int:
        return round(usd * rate)

    pro_year = settings.PLAN_PRO_PRICE_USD * months_in_year
    premium_year = settings.PLAN_PREMIUM_PRICE_USD * months_in_year

    return PlansResponse(
        usd_to_kgs_rate=rate,
        plans=[
            PlanInfo(
                plan="free",
                price_usd_month=0,
                price_usd_year=0,
                price_kgs_month=0,
                price_kgs_year=0,
                doctor_limit=settings.CLINIC_FREE_DOCTOR_LIMIT,
                branch_limit=settings.PHARMACY_FREE_BRANCH_LIMIT,
                has_reports=False,
                has_badge=False,
            ),
            PlanInfo(
                plan="pro",
                price_usd_month=settings.PLAN_PRO_PRICE_USD,
                price_usd_year=pro_year,
                price_kgs_month=kgs(settings.PLAN_PRO_PRICE_USD),
                price_kgs_year=kgs(pro_year),
                doctor_limit=None,
                branch_limit=None,
                has_reports=False,
                has_badge=False,
            ),
            PlanInfo(
                plan="premium",
                price_usd_month=settings.PLAN_PREMIUM_PRICE_USD,
                price_usd_year=premium_year,
                price_kgs_month=kgs(settings.PLAN_PREMIUM_PRICE_USD),
                price_kgs_year=kgs(premium_year),
                doctor_limit=None,
                branch_limit=None,
                has_reports=True,
                has_badge=True,
            ),
        ],
    )
