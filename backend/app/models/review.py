from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Float, Integer, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[int] = mapped_column(primary_key=True)
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    doctor_id: Mapped[Optional[int]] = mapped_column(ForeignKey("doctors.id"))
    clinic_id: Mapped[Optional[int]] = mapped_column(ForeignKey("clinics.id"))
    rating: Mapped[float] = mapped_column(Float)
    text: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
