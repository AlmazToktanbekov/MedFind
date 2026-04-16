from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Boolean, Float, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Pharmacy(Base):
    __tablename__ = "pharmacies"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer)

    name_ru: Mapped[str] = mapped_column(String(255))
    name_kg: Mapped[Optional[str]] = mapped_column(String(255))
    name_en: Mapped[Optional[str]] = mapped_column(String(255))

    address_ru: Mapped[Optional[str]] = mapped_column(String(512))
    address_kg: Mapped[Optional[str]] = mapped_column(String(512))
    address_en: Mapped[Optional[str]] = mapped_column(String(512))

    phone: Mapped[Optional[str]] = mapped_column(String(30))
    photo_url: Mapped[Optional[str]] = mapped_column(String(512))

    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)

    is_open_24h: Mapped[bool] = mapped_column(Boolean, default=False)
    working_hours_ru: Mapped[Optional[str]] = mapped_column(String(255))

    status: Mapped[str] = mapped_column(String(20), default="pending")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
