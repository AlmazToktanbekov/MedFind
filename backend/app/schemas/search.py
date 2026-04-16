from pydantic import BaseModel
from typing import Optional, List
from app.schemas.doctor import DoctorListItem
from app.schemas.clinic import ClinicOut
from app.schemas.pharmacy import PharmacyOut


class SearchResults(BaseModel):
    doctors: List[DoctorListItem] = []
    clinics: List[ClinicOut] = []
    pharmacies: List[PharmacyOut] = []
    specializations: List[str] = []
