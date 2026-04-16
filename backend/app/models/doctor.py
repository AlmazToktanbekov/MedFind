from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Boolean, Float, Integer, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Doctor(Base):
    __tablename__ = "doctors"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), unique=True)

    # Multilingual fields
    full_name_ru: Mapped[str] = mapped_column(String(255))
    full_name_kg: Mapped[Optional[str]] = mapped_column(String(255))
    full_name_en: Mapped[Optional[str]] = mapped_column(String(255))

    specialization_ru: Mapped[str] = mapped_column(String(255))
    specialization_kg: Mapped[Optional[str]] = mapped_column(String(255))
    specialization_en: Mapped[Optional[str]] = mapped_column(String(255))

    bio_ru: Mapped[Optional[str]] = mapped_column(Text)
    bio_kg: Mapped[Optional[str]] = mapped_column(Text)
    bio_en: Mapped[Optional[str]] = mapped_column(Text)

    photo_url: Mapped[Optional[str]] = mapped_column(String(512))
    experience_years: Mapped[Optional[int]] = mapped_column(Integer)
    address_ru: Mapped[Optional[str]] = mapped_column(String(512))
    clinic_id: Mapped[Optional[int]] = mapped_column(ForeignKey("clinics.id"))

    # Availability
    has_online: Mapped[bool] = mapped_column(Boolean, default=False)
    has_offline: Mapped[bool] = mapped_column(Boolean, default=True)
    online_price: Mapped[Optional[float]] = mapped_column(Float)
    offline_price: Mapped[Optional[float]] = mapped_column(Float)
    online_duration_min: Mapped[Optional[int]] = mapped_column(Integer, default=30)
    offline_duration_min: Mapped[Optional[int]] = mapped_column(Integer, default=30)

    # Stats
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)

    # Moderation
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending|active|rejected

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    contacts: Mapped[list["DoctorContact"]] = relationship(back_populates="doctor", cascade="all, delete-orphan")
    services: Mapped[list["DoctorService"]] = relationship(back_populates="doctor", cascade="all, delete-orphan")
    schedules: Mapped[list["DoctorSchedule"]] = relationship(back_populates="doctor", cascade="all, delete-orphan")


class DoctorContact(Base):
    __tablename__ = "doctor_contacts"

    id: Mapped[int] = mapped_column(primary_key=True)
    doctor_id: Mapped[int] = mapped_column(ForeignKey("doctors.id"))
    type: Mapped[str] = mapped_column(String(30))  # phone | whatsapp | telegram | instagram | email
    value: Mapped[str] = mapped_column(String(255))

    doctor: Mapped["Doctor"] = relationship(back_populates="contacts")


class DoctorService(Base):
    __tablename__ = "doctor_services"

    id: Mapped[int] = mapped_column(primary_key=True)
    doctor_id: Mapped[int] = mapped_column(ForeignKey("doctors.id"))
    name_ru: Mapped[str] = mapped_column(String(255))
    name_kg: Mapped[Optional[str]] = mapped_column(String(255))
    name_en: Mapped[Optional[str]] = mapped_column(String(255))
    price: Mapped[Optional[float]] = mapped_column(Float)

    doctor: Mapped["Doctor"] = relationship(back_populates="services")


class DoctorSchedule(Base):
    __tablename__ = "doctor_schedules"

    id: Mapped[int] = mapped_column(primary_key=True)
    doctor_id: Mapped[int] = mapped_column(ForeignKey("doctors.id"))
    day_of_week: Mapped[int] = mapped_column(Integer)  # 0=Mon, 6=Sun
    start_time: Mapped[str] = mapped_column(String(5))  # "09:00"
    end_time: Mapped[str] = mapped_column(String(5))    # "18:00"
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)

    doctor: Mapped["Doctor"] = relationship(back_populates="schedules")
