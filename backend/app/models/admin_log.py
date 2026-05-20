from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Text, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class AdminLog(Base):
    """Аудит-журнал действий администраторов в /panel/* и /admin/*.

    Используется для безопасности и отчётности. Записи никогда не удаляются.
    """
    __tablename__ = "admin_logs"
    __table_args__ = (
        Index("ix_admin_logs_admin_created", "admin_user_id", "created_at"),
        Index("ix_admin_logs_target", "target_type", "target_id"),
        Index("ix_admin_logs_action_created", "action", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    admin_user_id: Mapped[int] = mapped_column(Integer)

    action: Mapped[str] = mapped_column(String(60))
    # примеры: "doctor.approve", "clinic.reject", "user.block",
    # "user.password_reset", "review.delete"

    target_type: Mapped[Optional[str]] = mapped_column(String(30))
    # "doctor" | "clinic" | "pharmacy" | "user" | "review"
    target_id: Mapped[Optional[int]] = mapped_column(Integer)

    details: Mapped[Optional[str]] = mapped_column(Text)
    # JSON или человеко-читаемое описание (причина, старое/новое значение)

    ip_address: Mapped[Optional[str]] = mapped_column(String(64))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
