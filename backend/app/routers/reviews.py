from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.review import Review
from app.models.doctor import Doctor
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewOut

router = APIRouter(prefix="/reviews", tags=["reviews"])


async def _recalc_doctor_rating(doctor_id: int, db: AsyncSession):
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.doctor_id == doctor_id
        )
    )
    avg_rating, count = result.one()
    doc_result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    doctor = doc_result.scalar_one_or_none()
    if doctor:
        doctor.rating = round(float(avg_rating or 0), 2)
        doctor.reviews_count = count or 0


def _to_out(review: Review, author: Optional[User]) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        author_id=review.author_id,
        author_name=author.full_name if author else None,
        rating=review.rating,
        text=review.text,
        created_at=review.created_at,
    )


@router.get("/doctor/{doctor_id}", response_model=List[ReviewOut])
async def get_doctor_reviews(
    doctor_id: int,
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Review, User)
        .outerjoin(User, Review.author_id == User.id)
        .where(Review.doctor_id == doctor_id)
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    rows = result.all()
    return [_to_out(review, user) for review, user in rows]


@router.post("/doctor/{doctor_id}", response_model=ReviewOut, status_code=201)
async def create_doctor_review(
    doctor_id: int,
    body: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    doc_result = await db.execute(select(Doctor).where(Doctor.id == doctor_id))
    if not doc_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Doctor not found")

    existing = await db.execute(
        select(Review).where(
            Review.doctor_id == doctor_id,
            Review.author_id == current_user.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="You already reviewed this doctor")

    review = Review(
        doctor_id=doctor_id,
        author_id=current_user.id,
        **body.model_dump(),
    )
    db.add(review)
    await db.flush()
    await _recalc_doctor_rating(doctor_id, db)
    await db.refresh(review)
    return _to_out(review, current_user)
