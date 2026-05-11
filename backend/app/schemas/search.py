from pydantic import BaseModel
from typing import List
from app.schemas.doctor import DoctorListItem
from app.schemas.clinic import ClinicOut
from app.schemas.pharmacy import CompanyOut


class SearchResults(BaseModel):
    doctors: List[DoctorListItem] = []
    clinics: List[ClinicOut] = []
    pharmacies: List[CompanyOut] = []
    specializations: List[str] = []
