from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Boolean, Index, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Subscription(Base):
    __tablename__ = "subscriptions"
    __table_args__ = (
        Index("ix_subscriptions_owner", "owner_type", "owner_id"),
        Index("ix_subscriptions_status", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    owner_type: Mapped[str] = mapped_column(String(20))  # "clinic" | "pharmacy"
    owner_id: Mapped[int] = mapped_column(Integer)

    plan: Mapped[str] = mapped_column(String(20), default="free")  # "free" | "pro" | "premium"
    period: Mapped[Optional[str]] = mapped_column(String(10))      # "month" | "year" | None for free
    is_trial: Mapped[bool] = mapped_column(Boolean, default=False)

    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    status: Mapped[str] = mapped_column(String(20), default="active")  # "active" | "expired" | "cancelled"

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )


class TrialUsage(Base):
    """Запись о том, что владелец (клиника/аптека) уже использовал триал.
    Триал даётся ОДИН раз навсегда."""
    __tablename__ = "trial_usages"
    __table_args__ = (
        UniqueConstraint("owner_type", "owner_id", name="uq_trial_owner"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    owner_type: Mapped[str] = mapped_column(String(20))
    owner_id: Mapped[int] = mapped_column(Integer)
    used_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
