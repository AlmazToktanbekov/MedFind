from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.schemas.doctor import DoctorOut
from app.schemas.clinic import ClinicOut

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/pending")
async def get_pending(
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    doctors_result = await db.execute(select(Doctor).where(Doctor.status == "pending"))
    clinics_result = await db.execute(select(Clinic).where(Clinic.status == "pending"))

    return {
        "doctors": [DoctorOut.model_validate(d) for d in doctors_result.scalars().all()],
        "clinics": [ClinicOut.model_validate(c) for c in clinics_result.scalars().all()],
    }


@router.put("/approve/{entity_type}/{entity_id}")
async def approve(
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    entity = await _get_entity(entity_type, entity_id, db)
    entity.status = "active"
    return {"message": f"{entity_type} {entity_id} approved"}


@router.delete("/reject/{entity_type}/{entity_id}")
async def reject(
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    entity = await _get_entity(entity_type, entity_id, db)
    entity.status = "rejected"
    return {"message": f"{entity_type} {entity_id} rejected"}


async def _get_entity(entity_type: str, entity_id: int, db: AsyncSession):
    model_map = {"doctor": Doctor, "clinic": Clinic}
    model = model_map.get(entity_type)
    if not model:
        raise HTTPException(status_code=400, detail=f"Unknown entity type: {entity_type}")
    result = await db.execute(select(model).where(model.id == entity_id))
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Not found")
    return entity
