"""Аналитика: приём событий от mobile + Premium-отчёты для клиник и аптек."""
from datetime import datetime, timezone, timedelta
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, get_current_user_optional
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany, PharmacyBranch
from app.services import analytics_service, subscription_service as subs

router = APIRouter(prefix="/analytics", tags=["analytics"])


# ─── Трекинг ──────────────────────────────────────────────────────────────

class EventIn(BaseModel):
    event_type: str
    target_type: Optional[str] = None
    target_id: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class TrackRequest(BaseModel):
    events: List[EventIn]


_ALLOWED_EVENTS = {
    "view_clinic", "view_doctor", "view_pharmacy_branch",
    "click_call", "click_whatsapp", "click_telegram", "click_route",
    "add_favorite", "search",
}


@router.post("/track")
async def track_events(
    body: TrackRequest,
    current_user=Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db),
):
    """Приём батча событий. Авторизация опциональна (гости тоже шлют события)."""
    user_id = current_user.id if current_user else None
    accepted = 0
    for ev in body.events:
        if ev.event_type not in _ALLOWED_EVENTS:
            continue
        await analytics_service.track_event(
            db,
            event_type=ev.event_type,
            target_type=ev.target_type,
            target_id=ev.target_id,
            user_id=user_id,
            metadata=ev.metadata,
        )
        accepted += 1
    return {"accepted": accepted}


# ─── Отчёты ───────────────────────────────────────────────────────────────

def _parse_period(
    from_str: Optional[str], to_str: Optional[str]
) -> tuple[datetime, datetime]:
    """Парсит ISO-даты ?from=YYYY-MM-DD&to=YYYY-MM-DD.
    По умолчанию — последние 30 дней. to_dt — эксклюзивная (следующий день)."""
    now = datetime.now(timezone.utc)
    if to_str:
        to_dt = datetime.fromisoformat(to_str).replace(tzinfo=timezone.utc)
        # Делаем эксклюзивным концом дня
        to_dt = to_dt.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
    else:
        to_dt = now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)
    if from_str:
        from_dt = datetime.fromisoformat(from_str).replace(tzinfo=timezone.utc)
        from_dt = from_dt.replace(hour=0, minute=0, second=0, microsecond=0)
    else:
        from_dt = to_dt - timedelta(days=30)
    if from_dt >= to_dt:
        raise HTTPException(status_code=400, detail="'from' must be before 'to'")
    return from_dt, to_dt


@router.get("/clinic/me")
async def get_my_clinic_analytics(
    from_: Optional[str] = Query(None, alias="from"),
    to: Optional[str] = Query(None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Отчёт для владельца клиники. Доступно только Premium (или в grace-период)."""
    r = await db.execute(
        select(Clinic).where(Clinic.user_id == current_user.id).limit(1)
    )
    clinic = r.scalar_one_or_none()
    if clinic is None:
        raise HTTPException(status_code=404, detail="Clinic not found for current user")

    allowed = await subs.has_analytics_access(db, "clinic", clinic.id)
    if not allowed:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "premium_required",
                "message": "Отчёты доступны только на тарифе Premium",
            },
        )

    from_dt, to_dt = _parse_period(from_, to)
    return await analytics_service.get_clinic_report(db, clinic.id, from_dt, to_dt)


@router.get("/pharmacy/branch/{branch_id}")
async def get_branch_analytics(
    branch_id: int,
    from_: Optional[str] = Query(None, alias="from"),
    to: Optional[str] = Query(None),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Отчёт для филиала аптеки. Доступно только Premium компании-владельцу."""
    r = await db.execute(
        select(PharmacyBranch, PharmacyCompany)
        .join(PharmacyCompany, PharmacyBranch.company_id == PharmacyCompany.id)
        .where(PharmacyBranch.id == branch_id)
    )
    row = r.one_or_none()
    if row is None:
        raise HTTPException(status_code=404, detail="Branch not found")
    branch, company = row
    if company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    allowed = await subs.has_analytics_access(db, "pharmacy", company.id)
    if not allowed:
        raise HTTPException(
            status_code=403,
            detail={
                "code": "premium_required",
                "message": "Отчёты доступны только на тарифе Premium",
            },
        )

    from_dt, to_dt = _parse_period(from_, to)
    return await analytics_service.get_branch_report(db, branch_id, from_dt, to_dt)
