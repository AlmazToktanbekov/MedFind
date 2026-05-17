from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Index
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class SearchLog(Base):
    """Лог поисковых запросов пациентов — для аналитики «топ запросов»."""

    __tablename__ = "search_logs"
    __table_args__ = (
        Index("ix_search_logs_query", "query"),
        Index("ix_search_logs_created", "created_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(Integer)
    query: Mapped[str] = mapped_column(String(255))
    results_count: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
