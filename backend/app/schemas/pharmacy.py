from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


# ─── Photos ───────────────────────────────────────────────────────────────

class BranchPhotoOut(BaseModel):
    id: int
    url: str
    order: int

    class Config:
        from_attributes = True


# ─── Branch ───────────────────────────────────────────────────────────────

class BranchCreate(BaseModel):
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    working_hours: Optional[str] = None
    map_link: Optional[str] = None
    photo_url: Optional[str] = None


class BranchUpdate(BaseModel):
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    phone: Optional[str] = None
    working_hours: Optional[str] = None
    map_link: Optional[str] = None
    is_active: Optional[bool] = None


class BranchOut(BaseModel):
    id: int
    company_id: int
    address: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    phone: Optional[str]
    working_hours: Optional[str]
    map_link: Optional[str] = None
    is_active: bool
    rating: float
    reviews_count: int
    created_at: datetime
    photos: List[BranchPhotoOut] = []
    distance_km: Optional[float] = None  # заполняется в /nearby

    # Поля компании — подставляются в роутере
    company_name: Optional[str] = None
    company_logo_url: Optional[str] = None
    company_whatsapp: Optional[str] = None
    company_instagram: Optional[str] = None
    company_website: Optional[str] = None
    company_main_phone: Optional[str] = None

    class Config:
        from_attributes = True


# ─── Company ──────────────────────────────────────────────────────────────

class CompanyCreate(BaseModel):
    name: str
    logo_url: Optional[str] = None
    cover_photo_url: Optional[str] = None
    main_phone: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    whatsapp: Optional[str] = None
    instagram: Optional[str] = None


class CompanyUpdate(BaseModel):
    name: Optional[str] = None
    logo_url: Optional[str] = None
    cover_photo_url: Optional[str] = None
    main_phone: Optional[str] = None
    website: Optional[str] = None
    description: Optional[str] = None
    whatsapp: Optional[str] = None
    instagram: Optional[str] = None


class CompanyOut(BaseModel):
    id: int
    name: str
    logo_url: Optional[str]
    cover_photo_url: Optional[str] = None
    main_phone: Optional[str]
    website: Optional[str]
    description: Optional[str]
    whatsapp: Optional[str] = None
    instagram: Optional[str] = None
    created_at: datetime
    branches: List[BranchOut] = []

    class Config:
        from_attributes = True


# ─── Registration (company + first branch at once) ────────────────────────

class PharmacyRegisterRequest(BaseModel):
    company: CompanyCreate
    first_branch: BranchCreate
