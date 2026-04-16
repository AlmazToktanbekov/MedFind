from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ClinicOut(BaseModel):
    id: int
    name_ru: str
    name_kg: Optional[str]
    name_en: Optional[str]
    description_ru: Optional[str]
    category_ru: Optional[str]
    address_ru: Optional[str]
    phone: Optional[str]
    website: Optional[str]
    photo_url: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    rating: float
    reviews_count: int
    status: str
    working_hours_ru: Optional[str]
    created_at: datetime

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
    website: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    working_hours_ru: Optional[str] = None


class ClinicUpdate(BaseModel):
    name_ru: Optional[str] = None
    description_ru: Optional[str] = None
    category_ru: Optional[str] = None
    address_ru: Optional[str] = None
    phone: Optional[str] = None
    website: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    working_hours_ru: Optional[str] = None
    photo_url: Optional[str] = None
