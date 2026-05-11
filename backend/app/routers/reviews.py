from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import Optional, List

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.review import Review
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyBranch
from app.models.notification import Notification
from app.models.user import User
from app.schemas.review import ReviewCreate, ReviewUpdate, ReviewOut

router = APIRouter(prefix="/reviews", tags=["reviews"])


async def _recalc_doctor_rating(doctor_id: int, db: AsyncSession):
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.doctor_id == doctor_id
        )
    )
    avg_rating, count = result.one()
    doctor = (await db.execute(select(Doctor).where(Doctor.id == doctor_id))).scalar_one_or_none()
    if doctor:
        doctor.rating = round(float(avg_rating or 0), 2)
        doctor.reviews_count = count or 0


async def _recalc_clinic_rating(clinic_id: int, db: AsyncSession):
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.clinic_id == clinic_id
        )
    )
    avg_rating, count = result.one()
    clinic = (await db.execute(select(Clinic).where(Clinic.id == clinic_id))).scalar_one_or_none()
    if clinic:
        clinic.rating = round(float(avg_rating or 0), 2)
        clinic.reviews_count = count or 0


async def _recalc_branch_rating(branch_id: int, db: AsyncSession):
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.branch_id == branch_id
        )
    )
    avg_rating, count = result.one()
    branch = (await db.execute(select(PharmacyBranch).where(PharmacyBranch.id == branch_id))).scalar_one_or_none()
    if branch:
        branch.rating = round(float(avg_rating or 0), 2)
        branch.reviews_count = count or 0


def _to_out(review: Review, author: Optional[User]) -> ReviewOut:
    return ReviewOut(
        id=review.id,
        author_id=review.author_id,
        author_name=author.full_name if author else None,
        author_avatar_url=author.avatar_url if author else None,
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
    doctor = doc_result.scalar_one_or_none()
    if not doctor:
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

    if doctor.user_id:
        stars = "★" * int(body.rating) + "☆" * (5 - int(body.rating))
        db.add(Notification(
            user_id=doctor.user_id,
            title="Новый отзыв",
            body=f"{current_user.full_name or 'Пациент'} оставил отзыв {stars}",
            type="new_review",
            data={"route": f"/main/doctors/{doctor_id}", "target_type": "doctor", "target_id": doctor_id},
        ))

    await db.refresh(review)
    return _to_out(review, current_user)


# ── Clinic reviews ────────────────────────────────────────────────────────────

@router.get("/clinic/{clinic_id}", response_model=List[ReviewOut])
async def get_clinic_reviews(
    clinic_id: int,
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Review, User)
        .outerjoin(User, Review.author_id == User.id)
        .where(Review.clinic_id == clinic_id)
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return [_to_out(review, user) for review, user in result.all()]


@router.post("/clinic/{clinic_id}", response_model=ReviewOut, status_code=201)
async def create_clinic_review(
    clinic_id: int,
    body: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    clinic = (await db.execute(select(Clinic).where(Clinic.id == clinic_id))).scalar_one_or_none()
    if not clinic:
        raise HTTPException(status_code=404, detail="Clinic not found")

    if (await db.execute(
        select(Review).where(Review.clinic_id == clinic_id, Review.author_id == current_user.id)
    )).scalar_one_or_none():
        raise HTTPException(status_code=400, detail="You already reviewed this clinic")

    review = Review(clinic_id=clinic_id, author_id=current_user.id, **body.model_dump())
    db.add(review)
    await db.flush()
    await _recalc_clinic_rating(clinic_id, db)

    if clinic.user_id:
        stars = "★" * int(body.rating) + "☆" * (5 - int(body.rating))
        db.add(Notification(
            user_id=clinic.user_id,
            title="Новый отзыв",
            body=f"{current_user.full_name or 'Пациент'} оставил отзыв {stars}",
            type="new_review",
            data={"route": f"/main/clinics/{clinic_id}", "target_type": "clinic", "target_id": clinic_id},
        ))

    await db.refresh(review)
    return _to_out(review, current_user)


# ── Pharmacy branch reviews ───────────────────────────────────────────────────

@router.get("/pharmacy-branch/{branch_id}", response_model=List[ReviewOut])
async def get_branch_reviews(
    branch_id: int,
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Review, User)
        .outerjoin(User, Review.author_id == User.id)
        .where(Review.branch_id == branch_id)
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return [_to_out(review, user) for review, user in result.all()]


@router.patch("/{review_id}", response_model=ReviewOut)
async def update_review(
    review_id: int,
    body: ReviewUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Review, User)
        .outerjoin(User, Review.author_id == User.id)
        .where(Review.id == review_id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Review not found")
    review, author = row
    if review.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Only the author can edit this review")

    if body.rating is not None:
        review.rating = body.rating
    if body.text is not None:
        review.text = body.text
    review.updated_at = datetime.now(timezone.utc)

    await db.flush()

    if review.doctor_id:
        await _recalc_doctor_rating(review.doctor_id, db)
    elif review.clinic_id:
        await _recalc_clinic_rating(review.clinic_id, db)
    elif review.branch_id:
        await _recalc_branch_rating(review.branch_id, db)

    await db.refresh(review)
    return _to_out(review, author)


@router.delete("/{review_id}", status_code=204)
async def delete_review(
    review_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Review not found")
    if review.author_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not allowed")

    doctor_id = review.doctor_id
    clinic_id = review.clinic_id
    branch_id = review.branch_id

    await db.delete(review)
    await db.flush()

    if doctor_id:
        await _recalc_doctor_rating(doctor_id, db)
    elif clinic_id:
        await _recalc_clinic_rating(clinic_id, db)
    elif branch_id:
        await _recalc_branch_rating(branch_id, db)


@router.post("/pharmacy-branch/{branch_id}", response_model=ReviewOut, status_code=201)
async def create_branch_review(
    branch_id: int,
    body: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy.orm import selectinload
    branch = (await db.execute(
        select(PharmacyBranch)
        .options(selectinload(PharmacyBranch.company))
        .where(PharmacyBranch.id == branch_id)
    )).scalar_one_or_none()
    if not branch:
        raise HTTPException(status_code=404, detail="Pharmacy branch not found")

    if (await db.execute(
        select(Review).where(Review.branch_id == branch_id, Review.author_id == current_user.id)
    )).scalar_one_or_none():
        raise HTTPException(status_code=400, detail="You already reviewed this branch")

    review = Review(branch_id=branch_id, author_id=current_user.id, **body.model_dump())
    db.add(review)
    await db.flush()
    await _recalc_branch_rating(branch_id, db)

    if branch.company and branch.company.user_id:
        stars = "★" * int(body.rating) + "☆" * (5 - int(body.rating))
        db.add(Notification(
            user_id=branch.company.user_id,
            title="Новый отзыв на филиал",
            body=f"{current_user.full_name or 'Пациент'} оставил отзыв {stars} на {branch.address or 'ваш филиал'}",
            type="new_review",
            data={"route": f"/main/pharmacies/branch/{branch_id}", "target_type": "pharmacy_branch", "target_id": branch_id},
        ))

    await db.refresh(review)
    return _to_out(review, current_user)
