from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class AnalyticsEvent(Base):
    """Событие действия пациента — для отчётов Premium-клиник и аптек.

    clinic_id и pharmacy_branch_id денормализованы: при view_doctor/click_call/etc
    мы определяем clinic_id врача в момент записи, чтобы потом не делать JOIN.
    """
    __tablename__ = "analytics_events"
    __table_args__ = (
        Index("ix_analytics_clinic_created", "clinic_id", "created_at"),
        Index("ix_analytics_branch_created", "pharmacy_branch_id", "created_at"),
        Index("ix_analytics_event_created", "event_type", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    event_type: Mapped[str] = mapped_column(String(40))
    # "view_clinic" | "view_doctor" | "view_pharmacy_branch"
    # | "click_call" | "click_whatsapp" | "click_telegram" | "click_route"
    # | "add_favorite" | "search"

    target_type: Mapped[Optional[str]] = mapped_column(String(20))
    # "doctor" | "clinic" | "pharmacy_branch" | None (для search)
    target_id: Mapped[Optional[int]] = mapped_column(Integer)

    clinic_id: Mapped[Optional[int]] = mapped_column(Integer)
    pharmacy_branch_id: Mapped[Optional[int]] = mapped_column(Integer)

    user_id: Mapped[Optional[int]] = mapped_column(Integer)
    metadata_json: Mapped[Optional[str]] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
