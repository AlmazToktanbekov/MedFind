import math
import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete as sa_delete
from sqlalchemy.orm import selectinload
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.clinic import Clinic, ClinicPhoto
from app.models.doctor import Doctor, DoctorContact, DoctorService, DoctorSchedule, DoctorProfileUpdate
from app.models.user import User
from app.schemas.clinic import ClinicOut, ClinicCreate, ClinicUpdate, ClinicPhotoOut, DoctorInClinicOut, DoctorRequestsOut
from app.schemas.doctor import DoctorProfileUpdateOut
from app.services.fcm import send_push

router = APIRouter(prefix="/clinics", tags=["clinics"])


# ─── Helpers ──────────────────────────────────────────────────────────────

async def _load_clinic(clinic_id: int, db: AsyncSession) -> Optional[Clinic]:
    result = await db.execute(
        select(Clinic).options(selectinload(Clinic.photos)).where(Clinic.id == clinic_id)
    )
    return result.scalar_one_or_none()


async def _get_own_clinic(clinic_id: int, current_user, db: AsyncSession) -> Clinic:
    clinic = await _load_clinic(clinic_id, db)
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    if clinic.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")
    return clinic


async def _doctor_fcm_token(doctor: Doctor, db: AsyncSession) -> Optional[str]:
    if not doctor.user_id:
        return None
    result = await db.execute(select(User.fcm_token).where(User.id == doctor.user_id))
    return result.scalar_one_or_none()


async def _get_doctor_in_clinic(doctor_id: int, clinic_id: int, db: AsyncSession) -> Doctor:
    result = await db.execute(
        select(Doctor).where(Doctor.id == doctor_id, Doctor.clinic_id == clinic_id)
    )
    doctor = result.scalar_one_or_none()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found in this clinic")
    return doctor


# ─── Public endpoints ─────────────────────────────────────────────────────

@router.get("/my", response_model=Optional[ClinicOut])
async def get_my_clinic(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Clinic).options(selectinload(Clinic.photos)).where(Clinic.user_id == current_user.id)
    )
    return result.scalar_one_or_none()


@router.put("/my", response_model=ClinicOut)
async def update_my_clinic(
    body: ClinicUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Clinic).options(selectinload(Clinic.photos)).where(Clinic.user_id == current_user.id)
    )
    clinic = result.scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(clinic, key, value)
    await db.flush()
    await db.refresh(clinic)
    return clinic


@router.get("", response_model=List[ClinicOut])
async def list_clinics(
    category: Optional[str] = Query(None),
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(Clinic)
        .options(selectinload(Clinic.photos))
        .where(Clinic.status == "active")
    )
    if category:
        query = query.where(Clinic.category_ru.ilike(f"%{category}%"))
    query = query.order_by(Clinic.rating.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/nearby", response_model=List[ClinicOut])
async def nearby_clinics(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(10.0, gt=0, le=50.0),
    limit: int = Query(20, le=100),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Clinic)
        .options(selectinload(Clinic.photos))
        .where(
            Clinic.status == "active",
            Clinic.latitude.isnot(None),
            Clinic.longitude.isnot(None),
        )
    )
    clinics = result.scalars().all()

    def haversine(lat2: float, lon2: float) -> float:
        R = 6371.0
        p1, p2 = math.radians(lat), math.radians(lat2)
        dp = math.radians(lat2 - lat)
        dl = math.radians(lon2 - lng)
        a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
        return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    nearby = [c for c in clinics if haversine(c.latitude, c.longitude) <= radius_km]
    nearby.sort(key=lambda c: haversine(c.latitude, c.longitude))
    return nearby[:limit]


@router.get("/{clinic_id}", response_model=ClinicOut)
async def get_clinic(clinic_id: int, db: AsyncSession = Depends(get_db)):
    clinic = await _load_clinic(clinic_id, db)
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")
    return clinic


@router.post("", response_model=ClinicOut, status_code=201)
async def create_clinic(
    body: ClinicCreate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = Clinic(**body.model_dump(), user_id=current_user.id, status="active")
    db.add(clinic)
    await db.flush()
    return await _load_clinic(clinic.id, db)


@router.put("/{clinic_id}", response_model=ClinicOut)
async def update_clinic(
    clinic_id: int,
    body: ClinicUpdate,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    for key, value in body.model_dump(exclude_none=True).items():
        setattr(clinic, key, value)
    await db.flush()
    return await _load_clinic(clinic_id, db)


@router.delete("/{clinic_id}", status_code=204)
async def delete_clinic(
    clinic_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    await db.delete(clinic)
    await db.flush()


# ─── Photo management ─────────────────────────────────────────────────────

@router.post("/{clinic_id}/photos", response_model=ClinicPhotoOut, status_code=201)
async def add_clinic_photo(
    clinic_id: int,
    body: dict,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_own_clinic(clinic_id, current_user, db)
    url = body.get("url")
    if not url:
        raise HTTPException(status_code=422, detail="url is required")
    result = await db.execute(
        select(ClinicPhoto).where(ClinicPhoto.clinic_id == clinic_id).order_by(ClinicPhoto.order.desc()).limit(1)
    )
    last = result.scalar_one_or_none()
    order = (last.order + 1) if last else 0
    photo = ClinicPhoto(clinic_id=clinic_id, url=url, order=order)
    db.add(photo)
    await db.flush()
    await db.refresh(photo)
    return photo


@router.delete("/{clinic_id}/photos/{photo_id}", status_code=204)
async def delete_clinic_photo(
    clinic_id: int,
    photo_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_own_clinic(clinic_id, current_user, db)
    result = await db.execute(
        select(ClinicPhoto).where(ClinicPhoto.id == photo_id, ClinicPhoto.clinic_id == clinic_id)
    )
    photo = result.scalar_one_or_none()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    await db.delete(photo)
    await db.flush()


# ─── Public: doctors of a clinic ──────────────────────────────────────────

@router.get("/{clinic_id}/doctors", response_model=List[DoctorInClinicOut])
async def clinic_doctors(clinic_id: int, db: AsyncSession = Depends(get_db)):
    """Публичный список активных врачей клиники (для страницы клиники)."""
    result = await db.execute(
        select(Doctor).where(
            Doctor.clinic_id == clinic_id,
            Doctor.status == "active",
        ).order_by(Doctor.specialization_ru)
    )
    return result.scalars().all()


# ─── Clinic: doctor management ────────────────────────────────────────────

@router.get("/{clinic_id}/doctor-requests", response_model=DoctorRequestsOut)
async def doctor_requests(
    clinic_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Все врачи клиники, сгруппированные по статусу (для личного кабинета)."""
    await _get_own_clinic(clinic_id, current_user, db)

    result = await db.execute(
        select(Doctor).where(Doctor.clinic_id == clinic_id)
    )
    doctors = result.scalars().all()

    out = DoctorRequestsOut()
    for d in doctors:
        item = DoctorInClinicOut.model_validate(d)
        if d.status == "pending":
            out.pending.append(item)
        elif d.status == "active":
            out.active.append(item)
        elif d.status == "deactivated":
            out.deactivated.append(item)
        elif d.status == "rejected":
            out.rejected.append(item)
        elif d.status == "removed":
            out.removed.append(item)
    return out


@router.post("/{clinic_id}/approve-doctor/{doctor_id}")
async def approve_doctor(
    clinic_id: int,
    doctor_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    doctor = await _get_doctor_in_clinic(doctor_id, clinic_id, db)
    if doctor.status != "pending":
        raise HTTPException(status_code=400, detail="Doctor is not in pending status")
    doctor.status = "active"
    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Заявка одобрена", f"Клиника {clinic.name_ru} подтвердила ваш профиль",
        notification_type="doctor_approved",
        data={"route": "/provider/doctor-edit"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Doctor approved"}


class ReasonBody(BaseModel):
    reason: Optional[str] = None


@router.post("/{clinic_id}/reject-doctor/{doctor_id}")
async def reject_doctor(
    clinic_id: int,
    doctor_id: int,
    body: ReasonBody = ReasonBody(),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    doctor = await _get_doctor_in_clinic(doctor_id, clinic_id, db)
    if doctor.status != "pending":
        raise HTTPException(status_code=400, detail="Doctor is not in pending status")
    doctor.status = "rejected"
    doctor.rejection_reason = body.reason
    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Заявка отклонена", f"Клиника {clinic.name_ru} отклонила вашу заявку",
        notification_type="doctor_rejected",
        data={"route": "/provider/setup"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Doctor rejected"}


@router.post("/{clinic_id}/deactivate-doctor/{doctor_id}")
async def deactivate_doctor(
    clinic_id: int,
    doctor_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    doctor = await _get_doctor_in_clinic(doctor_id, clinic_id, db)
    if doctor.status != "active":
        raise HTTPException(status_code=400, detail="Doctor is not active")
    doctor.status = "deactivated"
    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Профиль деактивирован", f"Ваш профиль деактивирован клиникой {clinic.name_ru}",
        notification_type="doctor_deactivated",
        data={"route": "/provider/doctor-edit"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Doctor deactivated"}


@router.post("/{clinic_id}/activate-doctor/{doctor_id}")
async def activate_doctor(
    clinic_id: int,
    doctor_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    doctor = await _get_doctor_in_clinic(doctor_id, clinic_id, db)
    if doctor.status != "deactivated":
        raise HTTPException(status_code=400, detail="Doctor is not deactivated")
    doctor.status = "active"
    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Профиль снова активен", f"Клиника {clinic.name_ru} снова активировала ваш профиль",
        notification_type="doctor_activated",
        data={"route": "/provider/doctor-edit"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Doctor activated"}


@router.get("/{clinic_id}/doctor-update-requests", response_model=List[DoctorProfileUpdateOut])
async def get_doctor_update_requests(
    clinic_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Список pending-запросов на обновление профиля от врачей этой клиники."""
    await _get_own_clinic(clinic_id, current_user, db)
    result = await db.execute(
        select(DoctorProfileUpdate)
        .join(Doctor, DoctorProfileUpdate.doctor_id == Doctor.id)
        .where(Doctor.clinic_id == clinic_id, DoctorProfileUpdate.status == "pending")
        .order_by(DoctorProfileUpdate.created_at.desc())
    )
    return result.scalars().all()


@router.post("/{clinic_id}/approve-update/{update_id}")
async def approve_doctor_update(
    clinic_id: int,
    update_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Клиника подтверждает запрос на обновление профиля врача."""
    await _get_own_clinic(clinic_id, current_user, db)

    upd_r = await db.execute(select(DoctorProfileUpdate).where(DoctorProfileUpdate.id == update_id))
    upd = upd_r.scalar_one_or_none()
    if not upd or upd.status != "pending":
        raise HTTPException(status_code=404, detail="Update request not found")

    doctor = await _get_doctor_in_clinic(upd.doctor_id, clinic_id, db)

    scalar_fields = [
        "full_name_ru", "specialization_ru", "bio_ru", "phone", "education",
        "consultation_language", "photo_url", "cover_photo_url", "experience_years",
        "has_online", "has_offline", "online_price", "offline_price",
        "online_duration_min", "offline_duration_min",
    ]
    for field in scalar_fields:
        val = getattr(upd, field)
        if val is not None:
            setattr(doctor, field, val)

    if upd.contacts_json:
        await db.execute(sa_delete(DoctorContact).where(DoctorContact.doctor_id == doctor.id))
        for c in json.loads(upd.contacts_json):
            db.add(DoctorContact(doctor_id=doctor.id, type=c["type"], value=c["value"]))

    if upd.services_json:
        await db.execute(sa_delete(DoctorService).where(DoctorService.doctor_id == doctor.id))
        for s in json.loads(upd.services_json):
            db.add(DoctorService(doctor_id=doctor.id, name_ru=s["name_ru"], price=s.get("price")))

    if upd.schedules_json:
        await db.execute(sa_delete(DoctorSchedule).where(DoctorSchedule.doctor_id == doctor.id))
        for sch in json.loads(upd.schedules_json):
            db.add(DoctorSchedule(doctor_id=doctor.id, **sch))

    upd.status = "approved"
    upd.reviewed_at = datetime.now(timezone.utc)

    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Профиль обновлён", "Клиника подтвердила изменения вашего профиля",
        notification_type="profile_updated",
        data={"route": "/provider/doctor-edit"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Update approved"}


@router.post("/{clinic_id}/reject-update/{update_id}")
async def reject_doctor_update(
    clinic_id: int,
    update_id: int,
    body: ReasonBody = ReasonBody(),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Клиника отклоняет запрос на обновление профиля врача."""
    await _get_own_clinic(clinic_id, current_user, db)

    upd_r = await db.execute(select(DoctorProfileUpdate).where(DoctorProfileUpdate.id == update_id))
    upd = upd_r.scalar_one_or_none()
    if not upd or upd.status != "pending":
        raise HTTPException(status_code=404, detail="Update request not found")

    doctor = await _get_doctor_in_clinic(upd.doctor_id, clinic_id, db)

    upd.status = "rejected"
    upd.rejection_reason = body.reason
    upd.reviewed_at = datetime.now(timezone.utc)

    fcm = await _doctor_fcm_token(doctor, db)
    await send_push(
        fcm, "Обновление профиля отклонено", "Клиника отклонила изменения вашего профиля",
        notification_type="profile_update_rejected",
        data={"route": "/provider/doctor-edit"},
        db=db, user_id=doctor.user_id,
    )
    return {"message": "Update rejected"}


@router.delete("/{clinic_id}/remove-doctor/{doctor_id}")
async def remove_doctor(
    clinic_id: int,
    doctor_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Удалить врача из клиники — врач получает статус 'removed' и становится невидим."""
    clinic = await _get_own_clinic(clinic_id, current_user, db)
    doctor = await _get_doctor_in_clinic(doctor_id, clinic_id, db)
    fcm = await _doctor_fcm_token(doctor, db)
    doctor_user_id = doctor.user_id
    doctor.status = "removed"
    doctor.clinic_id = None
    await send_push(
        fcm, "Вас удалили из клиники", f"Клиника {clinic.name_ru} удалила вас. Выберите новую клинику.",
        notification_type="doctor_removed",
        data={"route": "/provider/setup"},
        db=db, user_id=doctor_user_id,
    )
    return {"message": "Doctor removed from clinic"}
