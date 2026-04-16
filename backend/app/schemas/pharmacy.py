from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class PharmacyOut(BaseModel):
    id: int
    name_ru: str
    name_kg: Optional[str]
    name_en: Optional[str]
    address_ru: Optional[str]
    phone: Optional[str]
    photo_url: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    is_open_24h: bool
    working_hours_ru: Optional[str]
    status: str
    created_at: datetime
    distance_km: Optional[float] = None  # populated in /nearby

    class Config:
        from_attributes = True


class PharmacyCreate(BaseModel):
    name_ru: str
    name_kg: Optional[str] = None
    name_en: Optional[str] = None
    address_ru: Optional[str] = None
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_open_24h: bool = False
    working_hours_ru: Optional[str] = None


class PharmacyUpdate(BaseModel):
    name_ru: Optional[str] = None
    name_kg: Optional[str] = None
    name_en: Optional[str] = None
    address_ru: Optional[str] = None
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_open_24h: Optional[bool] = None
    working_hours_ru: Optional[str] = None
