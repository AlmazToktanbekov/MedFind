from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Article(Base):
    __tablename__ = "articles"

    id: Mapped[int] = mapped_column(primary_key=True)
    title_ru: Mapped[str] = mapped_column(String(512))
    title_kg: Mapped[Optional[str]] = mapped_column(String(512))
    title_en: Mapped[Optional[str]] = mapped_column(String(512))

    body_ru: Mapped[Optional[str]] = mapped_column(Text)
    body_kg: Mapped[Optional[str]] = mapped_column(Text)
    body_en: Mapped[Optional[str]] = mapped_column(Text)

    category: Mapped[Optional[str]] = mapped_column(String(50))  # article | first_aid | health_tip
    image_url: Mapped[Optional[str]] = mapped_column(String(512))
    is_published: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
