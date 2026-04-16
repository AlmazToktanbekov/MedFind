from typing import Optional
from sqlalchemy import String, Integer, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Symptom(Base):
    __tablename__ = "symptoms"

    id: Mapped[int] = mapped_column(primary_key=True)
    name_ru: Mapped[str] = mapped_column(String(255))
    name_kg: Mapped[Optional[str]] = mapped_column(String(255))
    name_en: Mapped[Optional[str]] = mapped_column(String(255))
    icon: Mapped[Optional[str]] = mapped_column(String(100))  # icon name


class SymptomSpecialization(Base):
    __tablename__ = "symptom_specializations"

    id: Mapped[int] = mapped_column(primary_key=True)
    symptom_id: Mapped[int] = mapped_column(ForeignKey("symptoms.id"))
    specialization_ru: Mapped[str] = mapped_column(String(255))
    specialization_kg: Mapped[Optional[str]] = mapped_column(String(255))
    specialization_en: Mapped[Optional[str]] = mapped_column(String(255))
