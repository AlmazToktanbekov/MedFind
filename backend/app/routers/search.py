from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.models.pharmacy import Pharmacy
from app.schemas.search import SearchResults

router = APIRouter(prefix="/search", tags=["search"])

SPECIALIZATIONS = [
    "Терапевт", "Кардиолог", "Акушер-гинеколог", "Гастроэнтеролог",
    "Оториноларинголог", "Эндокринолог", "Уролог", "Диетолог",
    "Дерматолог", "Андролог", "Ортопед", "Пульмонолог", "Травматолог",
    "Невролог", "Маммолог", "Онколог", "Рентгенолог", "Нутрициолог",
    "Психотерапевт", "Педиатр", "Венеролог", "Радиолог", "Косметолог",
    "Офтальмолог", "Медсестра", "Семейный врач", "Анестезиолог-реаниматолог",
    "Кардиохирург", "Нефролог", "Хирург", "Неонатолог", "Проктолог",
    "Стоматолог", "Хэлс-коуч", "Врач функциональной диагностики",
]


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
        select(Clinic).where(
            Clinic.status == "active",
            (Clinic.name_ru.ilike(pattern) | Clinic.category_ru.ilike(pattern)),
        ).limit(10)
    )

    pharmacies_result = await db.execute(
        select(Pharmacy).where(
            Pharmacy.status == "active",
            Pharmacy.name_ru.ilike(pattern),
        ).limit(5)
    )

    matched_specs = [s for s in SPECIALIZATIONS if q.lower() in s.lower()]

    return SearchResults(
        doctors=doctors_result.scalars().all(),
        clinics=clinics_result.scalars().all(),
        pharmacies=pharmacies_result.scalars().all(),
        specializations=matched_specs,
    )


@router.get("/specializations")
async def get_specializations():
    return {"specializations": SPECIALIZATIONS}


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
