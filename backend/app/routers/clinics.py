from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.clinic import Clinic
from app.schemas.clinic import ClinicOut, ClinicCreate, ClinicUpdate

router = APIRouter(prefix="/clinics", tags=["clinics"])


@router.get("/my", response_model=Optional[ClinicOut])
async def get_my_clinic(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Получить профиль клиники текущего пользователя (null если не создан)."""
    result = await db.execute(
        select(Clinic).where(Clinic.user_id == current_user.id)
    )
    return result.scalar_one_or_none()


@router.get("", response_model=List[ClinicOut])
async def list_clinics(
    category: Optional[str] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    query = select(Clinic).where(Clinic.status == "active")
    if category:
        query = query.where(Clinic.category_ru.ilike(f"%{category}%"))
    query = query.order_by(Clinic.rating.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{clinic_id}", response_model=ClinicOut)
async def get_clinic(clinic_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Clinic).where(Clinic.id == clinic_id))
    clinic = result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    return clinic


@router.post("", response_model=ClinicOut, status_code=201)
async def create_clinic(
    body: ClinicCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = Clinic(**body.model_dump(), user_id=current_user.id, status="pending")
    db.add(clinic)
    await db.flush()
    await db.refresh(clinic)
    return clinic


@router.put("/{clinic_id}", response_model=ClinicOut)
async def update_clinic(
    clinic_id: int,
    body: ClinicUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Clinic).where(Clinic.id == clinic_id))
    clinic = result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")

    if clinic.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    for key, value in body.model_dump(exclude_none=True).items():
        setattr(clinic, key, value)

    await db.flush()
    await db.refresh(clinic)
    return clinic
