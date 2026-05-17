"""Жалобы пациентов на врачей, клиники, филиалы аптек и отзывы.

Пациент создаёт жалобу через POST /complaints. Админ модерирует через
/admin/complaints/* (см. app/routers/admin.py)."""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.complaint import Complaint
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyBranch
from app.models.review import Review
from app.models.user import User
from app.models.notification import Notification
from app.schemas.complaint import ComplaintCreate, ComplaintOut

router = APIRouter(prefix="/complaints", tags=["complaints"])


# ── Анти-спам: дубликаты в пределах окна ────────────────────────────────────
_DUPLICATE_WINDOW_MINUTES = 60


async def _target_exists(target_type: str, target_id: int, db: AsyncSession) -> bool:
    if target_type == "doctor":
        row = await db.execute(select(Doctor.id).where(Doctor.id == target_id))
    elif target_type == "clinic":
        row = await db.execute(select(Clinic.id).where(Clinic.id == target_id))
    elif target_type == "pharmacy_branch":
        row = await db.execute(select(PharmacyBranch.id).where(PharmacyBranch.id == target_id))
    elif target_type == "review":
        row = await db.execute(select(Review.id).where(Review.id == target_id))
    else:
        return False
    return row.scalar_one_or_none() is not None


@router.post("", response_model=ComplaintOut, status_code=201)
async def create_complaint(
    body: ComplaintCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 1. Цель существует
    if not await _target_exists(body.target_type, body.target_id, db):
        raise HTTPException(status_code=404, detail="target_not_found")

    # 2. Антидубликат: одна жалоба от пользователя на цель раз в час
    existing = await db.execute(
        select(Complaint).where(
            Complaint.author_id == current_user.id,
            Complaint.target_type == body.target_type,
            Complaint.target_id == body.target_id,
            Complaint.status.in_(["new", "in_review"]),
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="already_reported")

    complaint = Complaint(
        author_id=current_user.id,
        target_type=body.target_type,
        target_id=body.target_id,
        reason=body.reason,
        comment=body.comment,
        status="new",
        created_at=datetime.now(timezone.utc),
    )
    db.add(complaint)
    await db.flush()
    await db.refresh(complaint)
    return complaint


@router.get("/mine", response_model=list[ComplaintOut])
async def list_my_complaints(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    res = await db.execute(
        select(Complaint)
        .where(Complaint.author_id == current_user.id)
        .order_by(Complaint.created_at.desc())
        .limit(100)
    )
    return list(res.scalars().all())
