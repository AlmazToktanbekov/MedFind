from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, distinct
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyBranch, PharmacyCompany
from app.schemas.search import SearchResults
from app.schemas.pharmacy import CompanyOut

router = APIRouter(prefix="/search", tags=["search"])


async def _get_specializations(db: AsyncSession) -> list[str]:
    result = await db.execute(
        select(distinct(Doctor.specialization_ru))
        .where(Doctor.specialization_ru.isnot(None))
        .order_by(Doctor.specialization_ru)
    )
    return [row[0] for row in result.all() if row[0]]


@router.get("", response_model=SearchResults)
async def search(q: str = Query(..., min_length=1), db: AsyncSession = Depends(get_db)):
    pattern = f"%{q}%"

    doctors_result = await db.execute(
        select(Doctor).where(
            Doctor.status == "active",
            (Doctor.full_name_ru.ilike(pattern) | Doctor.specialization_ru.ilike(pattern)),
        ).limit(10)
    )

    clinics_result = await db.execute(
        select(Clinic)
        .options(selectinload(Clinic.photos))
        .where(
            Clinic.status == "active",
            (Clinic.name_ru.ilike(pattern) | Clinic.category_ru.ilike(pattern)),
        ).limit(10)
    )

    # Ищем аптеки по названию компании — возвращаем компании (одна карточка на сеть)
    companies_result = await db.execute(
        select(PharmacyCompany)
        .options(selectinload(PharmacyCompany.branches).selectinload(PharmacyBranch.photos))
        .where(PharmacyCompany.name.ilike(pattern))
        .limit(5)
    )
    branches: list[CompanyOut] = list(companies_result.scalars().all())

    all_specs = await _get_specializations(db)
    matched_specs = [s for s in all_specs if q.lower() in s.lower()]

    return SearchResults(
        doctors=doctors_result.scalars().all(),
        clinics=clinics_result.scalars().all(),
        pharmacies=branches,
        specializations=matched_specs,
    )


@router.get("/specializations")
async def get_specializations(db: AsyncSession = Depends(get_db)):
    return {"specializations": await _get_specializations(db)}


@router.get("/categories")
async def get_categories():
    return {
        "categories": [
            "Кардиология", "Акушерство и гинекология", "Гастроэнтерология",
            "Оториноларингология", "Рентгенологические исследования",
            "Эндокринология", "Урология и андрология", "Терапия",
            "Косметология", "Офтальмология", "Диетология", "Медицинский туризм",
            "УЗИ", "Пульмонология", "Мануальная терапия",
            "Дерматовенерология", "Хирургия", "Стоматология",
            "КТ", "Проктология", "Эндоскопия", "Нефрология",
            "Неонатология", "Неврология", "Педиатрия",
        ]
    }
