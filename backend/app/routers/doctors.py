import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.orm import selectinload
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.doctor import Doctor, DoctorContact, DoctorService, DoctorSchedule, DoctorProfileUpdate
from app.models.symptom import SymptomSpecialization
from app.schemas.doctor import (
    DoctorOut, DoctorListItem, DoctorCreate, DoctorUpdate,
    ApplyClinicRequest, DoctorUpdateRequestCreate, DoctorProfileUpdateOut,
)
from app.models.clinic import Clinic
from app.models.user import User
from app.services.fcm import send_push

router = APIRouter(prefix="/doctors", tags=["doctors"])


async def _load_full(doctor_id: int, db: AsyncSession) -> Doctor:
    """Load doctor with all related entities."""
    result = await db.execute(
        select(Doctor)
        .options(
            selectinload(Doctor.contacts),
            selectinload(Doctor.services),
            selectinload(Doctor.schedules),
            selectinload(Doctor.clinic),
        )
        .where(Doctor.id == doctor_id)
    )
    return result.scalar_one_or_none()


async def _notify_clinic_new_application(clinic_id: int, doctor: Doctor, db: AsyncSession) -> None:
    """Уведомить клинику о новой заявке врача (push + in-app)."""
    clinic_r = await db.execute(select(Clinic).where(Clinic.id == clinic_id))
    clinic = clinic_r.scalar_one_or_none()
    if not clinic:
        return
    fcm_r = await db.execute(select(User.fcm_token).where(User.id == clinic.user_id))
    fcm = fcm_r.scalar_one_or_none()
    await send_push(
        fcm,
        "Новая заявка от врача",
        f"Врач {doctor.full_name_ru} ({doctor.specialization_ru}) подал заявку в вашу клинику",
        notification_type="clinic_new_doctor_request",
        data={"route": f"/clinic/{clinic_id}/doctor-requests"},
        db=db, user_id=clinic.user_id,
    )


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
            selectinload(Doctor.clinic),
        )
        .where(Doctor.user_id == current_user.id)
    )
    doctor = result.scalar_one_or_none()
    if doctor is None:
        return None

    pending_r = await db.execute(
        select(DoctorProfileUpdate.id).where(
            DoctorProfileUpdate.doctor_id == doctor.id,
            DoctorProfileUpdate.status == "pending",
        )
    )
    has_pending = pending_r.scalar_one_or_none() is not None

    out = DoctorOut.model_validate(doctor).model_dump()
    out["has_pending_update"] = has_pending
    return out


@router.get("", response_model=List[DoctorListItem])
async def list_doctors(
    status: str = Query("active"),
    specialization: Optional[str] = Query(None),
    has_online: Optional[bool] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(Doctor)
        .options(selectinload(Doctor.clinic))
        .where(Doctor.status == status)
    )
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
        .options(selectinload(Doctor.clinic))
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
    if doctor.clinic_id:
        await _notify_clinic_new_application(doctor.clinic_id, doctor, db)
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

    allowed = doctor.user_id == current_user.id or current_user.role == "admin"
    if not allowed and doctor.clinic_id:
        clinic_result = await db.execute(select(Clinic).where(Clinic.id == doctor.clinic_id))
        clinic = clinic_result.scalar_one_or_none()
        if clinic and clinic.user_id == current_user.id:
            allowed = True
    if not allowed:
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


@router.delete("/{doctor_id}", status_code=204)
async def delete_doctor(
    doctor_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    if doctor.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")
    await db.delete(doctor)
    await db.flush()


@router.post("/my/request-update", response_model=DoctorProfileUpdateOut, status_code=201)
async def request_profile_update(
    body: DoctorUpdateRequestCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Врач отправляет запрос на обновление профиля — клиника должна подтвердить."""
    result = await db.execute(select(Doctor).where(Doctor.user_id == current_user.id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")
    if not doctor.clinic_id:
        raise HTTPException(status_code=400, detail="Doctor not linked to a clinic")

    # Удаляем предыдущий pending-запрос (один за раз)
    old_r = await db.execute(
        select(DoctorProfileUpdate).where(
            DoctorProfileUpdate.doctor_id == doctor.id,
            DoctorProfileUpdate.status == "pending",
        )
    )
    for old in old_r.scalars().all():
        await db.delete(old)

    scalar_data = body.model_dump(exclude={"contacts", "services", "schedules"}, exclude_none=True)
    update = DoctorProfileUpdate(
        doctor_id=doctor.id,
        **scalar_data,
        contacts_json=json.dumps([c.model_dump() for c in body.contacts]) if body.contacts is not None else None,
        services_json=json.dumps([s.model_dump() for s in body.services]) if body.services is not None else None,
        schedules_json=json.dumps([s.model_dump() for s in body.schedules]) if body.schedules is not None else None,
    )
    db.add(update)
    await db.flush()
    await db.refresh(update)

    # Уведомляем клинику
    clinic_r = await db.execute(select(Clinic).where(Clinic.id == doctor.clinic_id))
    clinic = clinic_r.scalar_one_or_none()
    if clinic:
        user_r = await db.execute(select(User.fcm_token).where(User.id == clinic.user_id))
        fcm = user_r.scalar_one_or_none()
        await send_push(
            fcm,
            "Запрос на обновление профиля",
            f"Врач {doctor.full_name_ru} хочет обновить свой профиль",
            notification_type="clinic_update_request",
            data={"route": f"/clinic/{clinic.id}/doctor-requests?tab=updates"},
            db=db, user_id=clinic.user_id,
        )

    return update


@router.delete("/my/pending-update", status_code=204)
async def cancel_pending_update(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Врач отменяет свой pending-запрос на обновление."""
    result = await db.execute(select(Doctor).where(Doctor.user_id == current_user.id))
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    old_r = await db.execute(
        select(DoctorProfileUpdate).where(
            DoctorProfileUpdate.doctor_id == doctor.id,
            DoctorProfileUpdate.status == "pending",
        )
    )
    for upd in old_r.scalars().all():
        await db.delete(upd)


@router.post("/apply-clinic", response_model=DoctorOut)
async def apply_clinic(
    body: ApplyClinicRequest,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Врач выбирает клинику — статус становится pending, клиника получает заявку."""
    result = await db.execute(
        select(Doctor).where(Doctor.user_id == current_user.id)
    )
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor profile not found")

    clinic_result = await db.execute(select(Clinic).where(Clinic.id == body.clinic_id))
    clinic = clinic_result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    if clinic.status != "active":
        raise HTTPException(status_code=400, detail="Clinic is not active")

    doctor.clinic_id = body.clinic_id
    doctor.status = "pending"
    await db.flush()
    await _notify_clinic_new_application(body.clinic_id, doctor, db)
    return await _load_full(doctor.id, db)
