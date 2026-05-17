from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Text, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class Complaint(Base):
    """Жалоба пользователя на врача / клинику / филиал аптеки / отзыв."""

    __tablename__ = "complaints"
    __table_args__ = (
        Index("ix_complaints_target", "target_type", "target_id"),
        Index("ix_complaints_status_created", "status", "created_at"),
        Index("ix_complaints_target_created", "target_type", "target_id", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    author_id: Mapped[int] = mapped_column(ForeignKey("users.id"))

    # "doctor" | "clinic" | "pharmacy_branch" | "review"
    target_type: Mapped[str] = mapped_column(String(30))
    target_id: Mapped[int] = mapped_column(Integer)

    # фиксированные коды причин (для аналитики)
    # "wrong_info" | "rude_behavior" | "fraud" | "spam" | "fake" | "other"
    reason: Mapped[str] = mapped_column(String(40))

    comment: Mapped[Optional[str]] = mapped_column(Text)

    # "new" | "in_review" | "resolved" | "rejected"
    status: Mapped[str] = mapped_column(String(20), default="new")

    resolution_note: Mapped[Optional[str]] = mapped_column(Text)
    resolved_by_admin_id: Mapped[Optional[int]] = mapped_column(Integer)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
