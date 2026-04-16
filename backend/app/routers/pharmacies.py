import math
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.pharmacy import Pharmacy
from app.schemas.pharmacy import PharmacyOut, PharmacyCreate, PharmacyUpdate

router = APIRouter(prefix="/pharmacies", tags=["pharmacies"])


@router.get("/my", response_model=Optional[PharmacyOut])
async def get_my_pharmacy(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Получить профиль аптеки текущего пользователя (null если не создан)."""
    result = await db.execute(
        select(Pharmacy).where(Pharmacy.user_id == current_user.id)
    )
    return result.scalar_one_or_none()


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@router.get("", response_model=List[PharmacyOut])
async def list_pharmacies(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pharmacy).where(Pharmacy.status == "active").limit(limit).offset(offset)
    )
    return result.scalars().all()


@router.get("/nearby", response_model=List[PharmacyOut])
async def nearby_pharmacies(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_km: float = Query(5.0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pharmacy).where(
            Pharmacy.status == "active",
            Pharmacy.latitude.isnot(None),
            Pharmacy.longitude.isnot(None),
        )
    )
    pharmacies = result.scalars().all()

    nearby = []
    for p in pharmacies:
        dist = _haversine_km(lat, lng, p.latitude, p.longitude)
        if dist <= radius_km:
            item = PharmacyOut.model_validate(p)
            item.distance_km = round(dist, 2)
            nearby.append(item)

    nearby.sort(key=lambda x: x.distance_km or 0)
    return nearby


@router.get("/{pharmacy_id}", response_model=PharmacyOut)
async def get_pharmacy(pharmacy_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Pharmacy).where(Pharmacy.id == pharmacy_id))
    pharmacy = result.scalar_one_or_none()
    if not pharmacy:
        raise HTTPException(status_code=404, detail="Pharmacy not found")
    return pharmacy


@router.post("", response_model=PharmacyOut, status_code=201)
async def create_pharmacy(
    body: PharmacyCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    pharmacy = Pharmacy(**body.model_dump(), user_id=current_user.id, status="pending")
    db.add(pharmacy)
    await db.flush()
    await db.refresh(pharmacy)
    return pharmacy


@router.put("/{pharmacy_id}", response_model=PharmacyOut)
async def update_pharmacy(
    pharmacy_id: int,
    body: PharmacyUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Pharmacy).where(Pharmacy.id == pharmacy_id))
    pharmacy = result.scalar_one_or_none()
    if not pharmacy:
        raise HTTPException(status_code=404, detail="Pharmacy not found")

    if pharmacy.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    for key, value in body.model_dump(exclude_none=True).items():
        setattr(pharmacy, key, value)

    await db.flush()
    await db.refresh(pharmacy)
    return pharmacy
