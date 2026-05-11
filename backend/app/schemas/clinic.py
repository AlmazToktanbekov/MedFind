from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ClinicPhotoOut(BaseModel):
    id: int
    url: str
    order: int

    class Config:
        from_attributes = True


class ClinicOut(BaseModel):
    id: int
    name_ru: str
    name_kg: Optional[str]
    name_en: Optional[str]
    description_ru: Optional[str]
    category_ru: Optional[str]
    address_ru: Optional[str]
    phone: Optional[str]
    whatsapp: Optional[str]
    telegram: Optional[str]
    instagram: Optional[str]
    email: Optional[str]
    website: Optional[str]
    logo_url: Optional[str]
    photo_url: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    map_url: Optional[str] = None
    rating: float
    reviews_count: int
    status: str
    working_hours_ru: Optional[str]
    created_at: datetime
    photos: List[ClinicPhotoOut] = []

    class Config:
        from_attributes = True


class ClinicCreate(BaseModel):
    name_ru: str
    name_kg: Optional[str] = None
    name_en: Optional[str] = None
    description_ru: Optional[str] = None
    category_ru: Optional[str] = None
    address_ru: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    telegram: Optional[str] = None
    instagram: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    map_url: Optional[str] = None
    working_hours_ru: Optional[str] = None


class ClinicUpdate(BaseModel):
    name_ru: Optional[str] = None
    description_ru: Optional[str] = None
    category_ru: Optional[str] = None
    address_ru: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    telegram: Optional[str] = None
    instagram: Optional[str] = None
    email: Optional[str] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    map_url: Optional[str] = None
    working_hours_ru: Optional[str] = None


# ─── Doctor management (используется в clinic router) ─────────────────────

class DoctorInClinicOut(BaseModel):
    id: int
    full_name_ru: str
    specialization_ru: str
    photo_url: Optional[str]
    status: str
    phone: Optional[str] = None

    class Config:
        from_attributes = True


class DoctorRequestsOut(BaseModel):
    pending: List[DoctorInClinicOut] = []
    active: List[DoctorInClinicOut] = []
    deactivated: List[DoctorInClinicOut] = []
    rejected: List[DoctorInClinicOut] = []
    removed: List[DoctorInClinicOut] = []
