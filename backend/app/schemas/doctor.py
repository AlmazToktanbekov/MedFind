from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# ─── Input schemas (create/update) ────────────────────────────────────────

class ContactInput(BaseModel):
    type: str   # phone | whatsapp | telegram | instagram
    value: str


class ServiceInput(BaseModel):
    name_ru: str
    price: Optional[float] = None


class ScheduleInput(BaseModel):
    day_of_week: int   # 0=Пн … 6=Вс
    start_time: str    # "09:00"
    end_time: str      # "18:00"
    is_available: bool = True


# ─── Output schemas ────────────────────────────────────────────────────────

class DoctorContactOut(BaseModel):
    id: int
    type: str
    value: str

    class Config:
        from_attributes = True


class DoctorServiceOut(BaseModel):
    id: int
    name_ru: str
    name_kg: Optional[str]
    name_en: Optional[str]
    price: Optional[float]

    class Config:
        from_attributes = True


class DoctorScheduleOut(BaseModel):
    id: int
    day_of_week: int
    start_time: str
    end_time: str
    is_available: bool

    class Config:
        from_attributes = True


class DoctorOut(BaseModel):
    id: int
    full_name_ru: str
    full_name_kg: Optional[str]
    full_name_en: Optional[str]
    specialization_ru: str
    specialization_kg: Optional[str]
    specialization_en: Optional[str]
    bio_ru: Optional[str]
    bio_kg: Optional[str]
    bio_en: Optional[str]
    phone: Optional[str]
    education: Optional[str]
    consultation_language: Optional[str]
    photo_url: Optional[str]
    cover_photo_url: Optional[str] = None
    experience_years: Optional[int]
    address_ru: Optional[str]
    clinic_id: Optional[int]
    clinic_name: Optional[str] = None
    has_online: bool
    has_offline: bool
    online_price: Optional[float]
    offline_price: Optional[float]
    online_duration_min: Optional[int]
    offline_duration_min: Optional[int]
    rating: float
    reviews_count: int
    status: str
    rejection_reason: Optional[str] = None
    has_pending_update: bool = False
    created_at: datetime
    contacts: List[DoctorContactOut] = []
    services: List[DoctorServiceOut] = []
    schedules: List[DoctorScheduleOut] = []

    class Config:
        from_attributes = True


class DoctorListItem(BaseModel):
    id: int
    full_name_ru: str
    specialization_ru: str
    photo_url: Optional[str]
    rating: float
    reviews_count: int
    has_online: bool
    has_offline: bool
    online_price: Optional[float]
    offline_price: Optional[float]
    status: str
    clinic_id: Optional[int] = None
    clinic_name: Optional[str] = None

    class Config:
        from_attributes = True


class DoctorCreate(BaseModel):
    full_name_ru: str
    full_name_kg: Optional[str] = None
    full_name_en: Optional[str] = None
    specialization_ru: str
    specialization_kg: Optional[str] = None
    specialization_en: Optional[str] = None
    bio_ru: Optional[str] = None
    bio_kg: Optional[str] = None
    bio_en: Optional[str] = None
    phone: Optional[str] = None
    education: Optional[str] = None
    consultation_language: Optional[str] = None
    experience_years: Optional[int] = None
    address_ru: Optional[str] = None
    clinic_id: Optional[int] = None
    has_online: bool = False
    has_offline: bool = True
    online_price: Optional[float] = None
    offline_price: Optional[float] = None
    online_duration_min: Optional[int] = 30
    offline_duration_min: Optional[int] = 30
    photo_url: Optional[str] = None
    cover_photo_url: Optional[str] = None
    contacts: Optional[List[ContactInput]] = None
    services: Optional[List[ServiceInput]] = None
    schedules: Optional[List[ScheduleInput]] = None


class DoctorUpdate(BaseModel):
    full_name_ru: Optional[str] = None
    full_name_kg: Optional[str] = None
    full_name_en: Optional[str] = None
    specialization_ru: Optional[str] = None
    specialization_kg: Optional[str] = None
    specialization_en: Optional[str] = None
    bio_ru: Optional[str] = None
    bio_kg: Optional[str] = None
    bio_en: Optional[str] = None
    phone: Optional[str] = None
    education: Optional[str] = None
    consultation_language: Optional[str] = None
    experience_years: Optional[int] = None
    address_ru: Optional[str] = None
    clinic_id: Optional[int] = None
    has_online: Optional[bool] = None
    has_offline: Optional[bool] = None
    online_price: Optional[float] = None
    offline_price: Optional[float] = None
    photo_url: Optional[str] = None
    cover_photo_url: Optional[str] = None
    contacts: Optional[List[ContactInput]] = None
    services: Optional[List[ServiceInput]] = None
    schedules: Optional[List[ScheduleInput]] = None


class ApplyClinicRequest(BaseModel):
    clinic_id: int


class DoctorUpdateRequestCreate(BaseModel):
    full_name_ru: Optional[str] = None
    specialization_ru: Optional[str] = None
    bio_ru: Optional[str] = None
    phone: Optional[str] = None
    education: Optional[str] = None
    consultation_language: Optional[str] = None
    photo_url: Optional[str] = None
    cover_photo_url: Optional[str] = None
    experience_years: Optional[int] = None
    has_online: Optional[bool] = None
    has_offline: Optional[bool] = None
    online_price: Optional[float] = None
    offline_price: Optional[float] = None
    online_duration_min: Optional[int] = None
    offline_duration_min: Optional[int] = None
    contacts: Optional[List[ContactInput]] = None
    services: Optional[List[ServiceInput]] = None
    schedules: Optional[List[ScheduleInput]] = None


class DoctorProfileUpdateOut(BaseModel):
    id: int
    doctor_id: int
    status: str
    created_at: datetime
    full_name_ru: Optional[str] = None
    specialization_ru: Optional[str] = None
    bio_ru: Optional[str] = None
    phone: Optional[str] = None
    education: Optional[str] = None
    photo_url: Optional[str] = None
    has_online: Optional[bool] = None
    has_offline: Optional[bool] = None
    online_price: Optional[float] = None
    offline_price: Optional[float] = None
    contacts_json: Optional[str] = None
    services_json: Optional[str] = None
    schedules_json: Optional[str] = None

    class Config:
        from_attributes = True
