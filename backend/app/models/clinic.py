from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Boolean, Float, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Clinic(Base):
    __tablename__ = "clinics"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer)  # FK to users

    name_ru: Mapped[str] = mapped_column(String(255))
    name_kg: Mapped[Optional[str]] = mapped_column(String(255))
    name_en: Mapped[Optional[str]] = mapped_column(String(255))

    description_ru: Mapped[Optional[str]] = mapped_column(Text)
    description_kg: Mapped[Optional[str]] = mapped_column(Text)
    description_en: Mapped[Optional[str]] = mapped_column(Text)

    category_ru: Mapped[Optional[str]] = mapped_column(String(255))
    category_kg: Mapped[Optional[str]] = mapped_column(String(255))
    category_en: Mapped[Optional[str]] = mapped_column(String(255))

    address_ru: Mapped[Optional[str]] = mapped_column(String(512))
    address_kg: Mapped[Optional[str]] = mapped_column(String(512))
    address_en: Mapped[Optional[str]] = mapped_column(String(512))

    phone: Mapped[Optional[str]] = mapped_column(String(30))
    website: Mapped[Optional[str]] = mapped_column(String(255))
    photo_url: Mapped[Optional[str]] = mapped_column(String(512))

    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)

    rating: Mapped[float] = mapped_column(Float, default=0.0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)

    status: Mapped[str] = mapped_column(String(20), default="pending")

    working_hours_ru: Mapped[Optional[str]] = mapped_column(String(255))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
