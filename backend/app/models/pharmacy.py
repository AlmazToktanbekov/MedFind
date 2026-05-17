from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Boolean, Float, Integer, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class PharmacyCompany(Base):
    __tablename__ = "pharmacy_companies"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    name: Mapped[str] = mapped_column(String(255))
    logo_url: Mapped[Optional[str]] = mapped_column(String(512))
    cover_photo_url: Mapped[Optional[str]] = mapped_column(String(512))
    main_phone: Mapped[Optional[str]] = mapped_column(String(30))
    website: Mapped[Optional[str]] = mapped_column(String(255))
    description: Mapped[Optional[str]] = mapped_column(Text)
    whatsapp: Mapped[Optional[str]] = mapped_column(String(30))
    instagram: Mapped[Optional[str]] = mapped_column(String(255))

    is_frozen: Mapped[bool] = mapped_column(Boolean, default=False)
    frozen_reason: Mapped[Optional[str]] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    branches: Mapped[list["PharmacyBranch"]] = relationship(
        back_populates="company", cascade="all, delete-orphan"
    )


class PharmacyBranch(Base):
    __tablename__ = "pharmacy_branches"

    id: Mapped[int] = mapped_column(primary_key=True)
    company_id: Mapped[int] = mapped_column(ForeignKey("pharmacy_companies.id"))

    address: Mapped[Optional[str]] = mapped_column(String(512))
    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)
    phone: Mapped[Optional[str]] = mapped_column(String(30))
    working_hours: Mapped[Optional[str]] = mapped_column(String(255))
    map_link: Mapped[Optional[str]] = mapped_column(String(512))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    rating: Mapped[float] = mapped_column(Float, default=0.0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    company: Mapped["PharmacyCompany"] = relationship(back_populates="branches")
    photos: Mapped[list["PharmacyBranchPhoto"]] = relationship(
        back_populates="branch", cascade="all, delete-orphan", order_by="PharmacyBranchPhoto.order"
    )


class PharmacyBranchPhoto(Base):
    __tablename__ = "pharmacy_branch_photos"

    id: Mapped[int] = mapped_column(primary_key=True)
    branch_id: Mapped[int] = mapped_column(ForeignKey("pharmacy_branches.id"))
    url: Mapped[str] = mapped_column(String(512))
    order: Mapped[int] = mapped_column(Integer, default=0)

    branch: Mapped["PharmacyBranch"] = relationship(back_populates="photos")
