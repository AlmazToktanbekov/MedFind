from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel
from typing import Optional

from app.core.database import get_db
from app.models.symptom import Symptom, SymptomSpecialization

router = APIRouter(prefix="/symptoms", tags=["symptoms"])


class SymptomOut(BaseModel):
    id: int
    name_ru: str
    name_kg: Optional[str] = None
    name_en: Optional[str] = None
    icon: Optional[str] = None

    class Config:
        from_attributes = True


class SymptomSpecializationOut(BaseModel):
    id: int
    symptom_id: int
    specialization_ru: str
    specialization_kg: Optional[str] = None
    specialization_en: Optional[str] = None

    class Config:
        from_attributes = True


@router.get("", response_model=List[SymptomOut])
async def list_symptoms(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Symptom).order_by(Symptom.name_ru))
    return result.scalars().all()


@router.get("/{symptom_id}", response_model=SymptomOut)
async def get_symptom(symptom_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Symptom).where(Symptom.id == symptom_id))
    symptom = result.scalar_one_or_none()
    if not symptom:
        raise HTTPException(status_code=404, detail="Symptom not found")
    return symptom


@router.get("/{symptom_id}/specializations", response_model=List[SymptomSpecializationOut])
async def symptom_specializations(symptom_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(SymptomSpecialization).where(SymptomSpecialization.symptom_id == symptom_id)
    )
    return result.scalars().all()
