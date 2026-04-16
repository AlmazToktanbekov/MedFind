from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.orm import selectinload
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.doctor import Doctor, DoctorContact, DoctorService, DoctorSchedule
from app.models.symptom import SymptomSpecialization
from app.schemas.doctor import DoctorOut, DoctorListItem, DoctorCreate, DoctorUpdate

router = APIRouter(prefix="/doctors", tags=["doctors"])


async def _load_full(doctor_id: int, db: AsyncSession) -> Doctor:
    """Load doctor with all related entities."""
    result = await db.execute(
        select(Doctor)
        .options(
            selectinload(Doctor.contacts),
            selectinload(Doctor.services),
            selectinload(Doctor.schedules),
        )
        .where(Doctor.id == doctor_id)
    )
    return result.scalar_one_or_none()


@router.get("/my", response_model=Optional[DoctorOut])
async def get_my_doctor(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Получить профиль врача текущего пользователя (null если не создан)."""
    result = await db.execute(
        select(Doctor)
        .options(
            selectinload(Doctor.contacts),
            selectinload(Doctor.services),
            selectinload(Doctor.schedules),
        )
        .where(Doctor.user_id == current_user.id)
    )
    return result.scalar_one_or_none()


@router.get("", response_model=List[DoctorListItem])
async def list_doctors(
    status: Optional[str] = Query(None),
    specialization: Optional[str] = Query(None),
    has_online: Optional[bool] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    query = select(Doctor).where(Doctor.status == "active")
    if specialization:
        query = query.where(Doctor.specialization_ru.ilike(f"%{specialization}%"))
    if has_online is not None:
        query = query.where(Doctor.has_online == has_online)
    query = query.order_by(Doctor.rating.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/by-symptom/{symptom_id}", response_model=List[DoctorListItem])
async def doctors_by_symptom(symptom_id: int, db: AsyncSession = Depends(get_db)):
    spec_result = await db.execute(
        select(SymptomSpecialization).where(SymptomSpecialization.symptom_id == symptom_id)
    )
    specs = spec_result.scalars().all()
    if not specs:
        return []

    spec_names = [s.specialization_ru for s in specs]
    result = await db.execute(
        select(Doctor)
        .where(Doctor.status == "active", Doctor.specialization_ru.in_(spec_names))
        .order_by(Doctor.rating.desc())
    )
    return result.scalars().all()


@router.get("/{doctor_id}", response_model=DoctorOut)
async def get_doctor(doctor_id: int, db: AsyncSession = Depends(get_db)):
    doctor = await _load_full(doctor_id, db)
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor


@router.post("", response_model=DoctorOut, status_code=201)
async def create_doctor(
    body: DoctorCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Extract relationship lists before creating
    contacts_data = body.contacts or []
    services_data = body.services or []
    schedules_data = body.schedules or []

    doctor_fields = body.model_dump(
        exclude={"contacts", "services", "schedules"}, exclude_none=True
    )
    doctor = Doctor(**doctor_fields, user_id=current_user.id, status="pending")
    db.add(doctor)
    await db.flush()  # get doctor.id

    for c in contacts_data:
        db.add(DoctorContact(doctor_id=doctor.id, type=c.type, value=c.value))
    for s in services_data:
        db.add(DoctorService(doctor_id=doctor.id, name_ru=s.name_ru, price=s.price))
    for sch in schedules_data:
        db.add(DoctorSchedule(doctor_id=doctor.id, **sch.model_dump()))

    await db.flush()
    return await _load_full(doctor.id, db)


@router.put("/{doctor_id}", response_model=DoctorOut)
async def update_doctor(
    doctor_id: int,
    body: DoctorUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")

    if doctor.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    # Update scalar fields
    scalar_data = body.model_dump(
        exclude={"contacts", "services", "schedules"}, exclude_none=True
    )
    for key, value in scalar_data.items():
        setattr(doctor, key, value)

    # Replace contacts if provided
    if body.contacts is not None:
        await db.execute(
            sa_delete(DoctorContact).where(DoctorContact.doctor_id == doctor_id)
        )
        for c in body.contacts:
            db.add(DoctorContact(doctor_id=doctor_id, type=c.type, value=c.value))

    # Replace services if provided
    if body.services is not None:
        await db.execute(
            sa_delete(DoctorService).where(DoctorService.doctor_id == doctor_id)
        )
        for s in body.services:
            db.add(DoctorService(doctor_id=doctor_id, name_ru=s.name_ru, price=s.price))

    # Replace schedules if provided
    if body.schedules is not None:
        await db.execute(
            sa_delete(DoctorSchedule).where(DoctorSchedule.doctor_id == doctor_id)
        )
        for sch in body.schedules:
            db.add(DoctorSchedule(doctor_id=doctor_id, **sch.model_dump()))

    await db.flush()
    return await _load_full(doctor_id, db)
