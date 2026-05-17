from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Text, JSON, Index, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Broadcast(Base):
    """Push-рассылка администратора с сегментацией."""

    __tablename__ = "broadcasts"
    __table_args__ = (
        Index("ix_broadcasts_status_scheduled", "status", "scheduled_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text)
    image_url: Mapped[Optional[str]] = mapped_column(String(512))

    # JSON-фильтр: {"roles":[...], "plans":[...], "cities":[...],
    #               "registered_after": iso, "registered_before": iso,
    #               "active_since_days": 30}
    segment: Mapped[Optional[dict]] = mapped_column(JSON)

    # "draft" | "scheduled" | "sending" | "sent" | "failed" | "cancelled"
    status: Mapped[str] = mapped_column(String(20), default="draft")
    scheduled_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    sent_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    sent_count: Mapped[int] = mapped_column(Integer, default=0)
    failed_count: Mapped[int] = mapped_column(Integer, default=0)

    created_by_admin_id: Mapped[Optional[int]] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )


class BroadcastDelivery(Base):
    """Лог доставки конкретному пользователю — для статистики и отладки."""

    __tablename__ = "broadcast_deliveries"
    __table_args__ = (
        Index("ix_bd_broadcast_status", "broadcast_id", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    broadcast_id: Mapped[int] = mapped_column(ForeignKey("broadcasts.id", ondelete="CASCADE"))
    user_id: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(20))  # "delivered" | "failed" | "no_fcm"
    error: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
