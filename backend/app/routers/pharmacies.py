import math
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.pharmacy import PharmacyCompany, PharmacyBranch, PharmacyBranchPhoto
from app.schemas.pharmacy import (
    CompanyOut, CompanyCreate, CompanyUpdate,
    BranchOut, BranchCreate, BranchUpdate,
    PharmacyRegisterRequest,
)
from app.services import subscription_service as subs

router = APIRouter(tags=["pharmacies"])


# ─── Helpers ──────────────────────────────────────────────────────────────

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def _load_company(company_id: int, db: AsyncSession) -> Optional[PharmacyCompany]:
    result = await db.execute(
        select(PharmacyCompany)
        .options(selectinload(PharmacyCompany.branches).selectinload(PharmacyBranch.photos))
        .where(PharmacyCompany.id == company_id)
    )
    return result.scalar_one_or_none()


def _branch_to_out(branch: PharmacyBranch, distance_km: Optional[float] = None) -> BranchOut:
    out = BranchOut.model_validate(branch)
    out.company_name = branch.company.name if branch.company else None
    out.company_logo_url = branch.company.logo_url if branch.company else None
    out.company_whatsapp = branch.company.whatsapp if branch.company else None
    out.company_instagram = branch.company.instagram if branch.company else None
    out.company_website = branch.company.website if branch.company else None
    out.company_main_phone = branch.company.main_phone if branch.company else None
    if distance_km is not None:
        out.distance_km = round(distance_km, 2)
    return out


# ─── Registration ─────────────────────────────────────────────────────────

@router.post("/pharmacy/register", response_model=CompanyOut, status_code=201)
async def register_pharmacy(
    body: PharmacyRegisterRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Регистрация аптечной компании вместе с первым филиалом."""
    company = PharmacyCompany(**body.company.model_dump(), user_id=current_user.id)
    db.add(company)
    await db.flush()

    branch_data = body.first_branch.model_dump()
    photo_url = branch_data.pop("photo_url", None)
    branch = PharmacyBranch(**branch_data, company_id=company.id)
    db.add(branch)
    await db.flush()

    if photo_url:
        db.add(PharmacyBranchPhoto(branch_id=branch.id, url=photo_url, order=0))
        await db.flush()

    # Автоматический Pro-триал на 30 дней при регистрации аптечной компании
    await subs.start_trial(db, "pharmacy", company.id)

    return await _load_company(company.id, db)


# ─── Company ──────────────────────────────────────────────────────────────

@router.get("/pharmacy-companies/my", response_model=Optional[CompanyOut])
async def get_my_company(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyCompany)
        .options(selectinload(PharmacyCompany.branches).selectinload(PharmacyBranch.photos))
        .where(PharmacyCompany.user_id == current_user.id)
        .limit(1)
    )
    return result.scalars().first()


@router.get("/pharmacy-companies", response_model=List[CompanyOut])
async def list_companies(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyCompany)
        .options(selectinload(PharmacyCompany.branches).selectinload(PharmacyBranch.photos))
        .limit(limit).offset(offset)
    )
    return result.scalars().all()


@router.get("/pharmacy-companies/{company_id}", response_model=CompanyOut)
async def get_company(company_id: int, db: AsyncSession = Depends(get_db)):
    company = await _load_company(company_id, db)
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return company


@router.put("/pharmacy-companies/{company_id}", response_model=CompanyOut)
async def update_company(
    company_id: int,
    body: CompanyUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    company = await _load_company(company_id, db)
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    if company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    for key, value in body.model_dump(exclude_none=True).items():
        setattr(company, key, value)
    await db.flush()
    return await _load_company(company_id, db)


# ─── Branches ─────────────────────────────────────────────────────────────

@router.post("/pharmacy-companies/{company_id}/branches", response_model=BranchOut, status_code=201)
async def add_branch(
    company_id: int,
    body: BranchCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    company = await _load_company(company_id, db)
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    if company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    # Проверка лимита тарифа: Free = 9 активных филиалов
    plan = await subs.get_plan(db, "pharmacy", company_id)
    limit = subs.get_branch_limit(plan)
    if limit is not None:
        active_count = await subs.count_active_branches(db, company_id)
        if active_count >= limit:
            raise HTTPException(
                status_code=402,
                detail={
                    "code": "plan_limit_reached",
                    "limit_type": "branches",
                    "current_plan": plan,
                    "limit": limit,
                    "current": active_count,
                    "message": "Достигнут лимит филиалов на бесплатном тарифе. Оформите подписку Pro или Premium.",
                },
            )

    branch_data = body.model_dump()
    branch_data.pop("photo_url", None)
    branch = PharmacyBranch(**branch_data, company_id=company_id)
    db.add(branch)
    await db.flush()
    await db.refresh(branch)

    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch.id)
    )
    branch = result.scalar_one()
    return _branch_to_out(branch)


@router.put("/pharmacy-branches/{branch_id}", response_model=BranchOut)
async def update_branch(
    branch_id: int,
    body: BranchUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )
    branch = result.scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    if branch.company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    for key, value in body.model_dump(exclude_none=True).items():
        setattr(branch, key, value)
    await db.flush()
    return _branch_to_out(branch)


@router.delete("/pharmacy-branches/{branch_id}", status_code=204)
async def delete_branch(
    branch_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )
    branch = result.scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    if branch.company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")
    await db.delete(branch)
    await db.flush()


@router.get("/pharmacy-branches/nearby", response_model=List[BranchOut])
async def nearby_branches(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, gt=0, le=50),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(
            PharmacyBranch.is_active == True,
            PharmacyBranch.latitude.isnot(None),
            PharmacyBranch.longitude.isnot(None),
        )
    )
    branches = result.scalars().all()

    nearby = []
    for b in branches:
        dist = _haversine_km(lat, lng, b.latitude, b.longitude)
        if dist <= radius_km:
            nearby.append(_branch_to_out(b, distance_km=dist))

    nearby.sort(key=lambda x: x.distance_km or 0)
    return nearby


@router.get("/pharmacy-branches/{branch_id}", response_model=BranchOut)
async def get_branch(branch_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id, PharmacyBranch.is_active == True)
    )
    branch = result.scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    return _branch_to_out(branch)


@router.get("/pharmacy-branches", response_model=List[BranchOut])
async def list_branches(
    company_id: Optional[int] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.is_active == True)
    )
    if company_id:
        query = query.where(PharmacyBranch.company_id == company_id)
    query = query.limit(limit).offset(offset)
    result = await db.execute(query)
    return [_branch_to_out(b) for b in result.scalars().all()]


# ─── Branch photos ────────────────────────────────────────────────────────

@router.post("/pharmacy-branches/{branch_id}/photos", response_model=BranchOut, status_code=201)
async def add_branch_photo(
    branch_id: int,
    url: str,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )
    branch = result.scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    if branch.company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    order = len(branch.photos)
    db.add(PharmacyBranchPhoto(branch_id=branch_id, url=url, order=order))
    await db.flush()

    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.photos), selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )
    branch = result.scalar_one()
    return _branch_to_out(branch)


@router.delete("/pharmacy-branches/{branch_id}/photos/{photo_id}", status_code=204)
async def delete_branch_photo(
    branch_id: int,
    photo_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )
    branch = result.scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Branch not found")
    if branch.company.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    photo_result = await db.execute(
        select(PharmacyBranchPhoto).where(
            PharmacyBranchPhoto.id == photo_id,
            PharmacyBranchPhoto.branch_id == branch_id,
        )
    )
    photo = photo_result.scalar_one_or_none()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")

    await db.delete(photo)
