from typing import Optional, List
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_admin
from app.models.doctor import Doctor
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyBranch
from app.models.review import Review
from app.models.user import User
from app.models.complaint import Complaint
from app.schemas.doctor import DoctorOut
from app.schemas.clinic import ClinicOut
from app.schemas.complaint import ComplaintAdminOut, ComplaintStatusUpdate

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/pending")
async def get_pending(
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    doctors_result = await db.execute(select(Doctor).where(Doctor.status == "pending"))
    clinics_result = await db.execute(select(Clinic).where(Clinic.status == "pending"))

    return {
        "doctors": [DoctorOut.model_validate(d) for d in doctors_result.scalars().all()],
        "clinics": [ClinicOut.model_validate(c) for c in clinics_result.scalars().all()],
    }


@router.put("/approve/{entity_type}/{entity_id}")
async def approve(
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    entity = await _get_entity(entity_type, entity_id, db)
    entity.status = "active"
    return {"message": f"{entity_type} {entity_id} approved"}


@router.delete("/reject/{entity_type}/{entity_id}")
async def reject(
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    entity = await _get_entity(entity_type, entity_id, db)
    entity.status = "rejected"
    return {"message": f"{entity_type} {entity_id} rejected"}



# ─── Scheduled jobs (manual trigger for testing / emergency) ──────────────

@router.get("/jobs")
async def list_jobs(_=Depends(get_current_admin)):
    """Список доступных фоновых задач."""
    from app.services.scheduler import JOBS
    return {"jobs": list(JOBS.keys())}


@router.post("/jobs/{name}/run")
async def run_job_now(name: str, _=Depends(get_current_admin)):
    """Запустить задачу вручную (использует собственную сессию БД)."""
    from app.services.scheduler import run_job, JOBS
    if name not in JOBS:
        raise HTTPException(status_code=404, detail=f"Unknown job: {name}")
    return await run_job(name)


# ─── Жалобы (модерация) ───────────────────────────────────────────────────

async def _resolve_target_title(target_type: str, target_id: int, db: AsyncSession) -> Optional[str]:
    if target_type == "doctor":
        r = await db.execute(select(Doctor.full_name_ru).where(Doctor.id == target_id))
        return r.scalar_one_or_none()
    if target_type == "clinic":
        r = await db.execute(select(Clinic.name_ru).where(Clinic.id == target_id))
        return r.scalar_one_or_none()
    if target_type == "pharmacy_branch":
        r = await db.execute(select(PharmacyBranch.address).where(PharmacyBranch.id == target_id))
        return r.scalar_one_or_none()
    if target_type == "review":
        r = await db.execute(select(Review.text).where(Review.id == target_id))
        text = r.scalar_one_or_none()
        return (text[:80] + "…") if text and len(text) > 80 else text
    return None


def _complaint_to_admin_out(
    c: Complaint, author: Optional[User], target_title: Optional[str]
) -> ComplaintAdminOut:
    return ComplaintAdminOut(
        id=c.id, author_id=c.author_id, target_type=c.target_type, target_id=c.target_id,
        reason=c.reason, comment=c.comment, status=c.status,
        resolution_note=c.resolution_note, resolved_at=c.resolved_at,
        created_at=c.created_at,
        author_name=author.full_name if author else None,
        author_phone=author.phone if author else None,
        target_title=target_title,
    )


@router.get("/complaints", response_model=List[ComplaintAdminOut])
async def list_complaints(
    status: Optional[str] = Query(default=None),
    target_type: Optional[str] = Query(default=None),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0),
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    q = select(Complaint, User).outerjoin(User, Complaint.author_id == User.id)
    if status:
        q = q.where(Complaint.status == status)
    if target_type:
        q = q.where(Complaint.target_type == target_type)
    q = q.order_by(Complaint.created_at.desc()).limit(limit).offset(offset)
    rows = (await db.execute(q)).all()
    out: List[ComplaintAdminOut] = []
    for c, author in rows:
        title = await _resolve_target_title(c.target_type, c.target_id, db)
        out.append(_complaint_to_admin_out(c, author, title))
    return out


@router.get("/complaints/stats")
async def complaints_stats(
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    from sqlalchemy import func
    rows = (await db.execute(
        select(Complaint.status, func.count(Complaint.id)).group_by(Complaint.status)
    )).all()
    return {status: count for status, count in rows}


@router.patch("/complaints/{complaint_id}", response_model=ComplaintAdminOut)
async def update_complaint_status(
    complaint_id: int,
    body: ComplaintStatusUpdate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(get_current_admin),
):
    res = await db.execute(
        select(Complaint, User)
        .outerjoin(User, Complaint.author_id == User.id)
        .where(Complaint.id == complaint_id)
    )
    row = res.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="not_found")
    c, author = row
    c.status = body.status
    c.resolution_note = body.resolution_note
    if body.status in ("resolved", "rejected"):
        c.resolved_at = datetime.utcnow()
        c.resolved_by_admin_id = admin.id
    await db.flush()
    title = await _resolve_target_title(c.target_type, c.target_id, db)
    return _complaint_to_admin_out(c, author, title)


@router.delete("/complaints/{complaint_id}", status_code=204)
async def delete_complaint(
    complaint_id: int,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_admin),
):
    res = await db.execute(select(Complaint).where(Complaint.id == complaint_id))
    c = res.scalar_one_or_none()
    if not c:
        raise HTTPException(status_code=404, detail="not_found")
    await db.delete(c)


async def _get_entity(entity_type: str, entity_id: int, db: AsyncSession):
    model_map = {"doctor": Doctor, "clinic": Clinic}
    model = model_map.get(entity_type)
    if not model:
        raise HTTPException(status_code=400, detail=f"Unknown entity type: {entity_type}")
    result = await db.execute(select(model).where(model.id == entity_id))
    entity = result.scalar_one_or_none()
    if not entity:
        raise HTTPException(status_code=404, detail="Not found")
    return entity
