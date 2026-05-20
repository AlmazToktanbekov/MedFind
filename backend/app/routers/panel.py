"""
Веб-панель администратора MedFind.
Маршруты: /panel/*
Аутентификация через сессию (cookie) с JWT-токеном.
"""
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, Form, Request, Response
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.core.database import get_db
from app.core.security import create_access_token, decode_token, verify_password
from app.models.user import User
from app.models.doctor import Doctor, DoctorContact, DoctorService, DoctorSchedule
from app.models.clinic import Clinic
from app.models.pharmacy import PharmacyCompany
from app.models.review import Review
from app.models.admin_log import AdminLog
from app.models.complaint import Complaint
from app.models.pharmacy import PharmacyBranch
from datetime import datetime, timedelta, timezone
from app.services.admin_log_service import log_action
from sqlalchemy.orm import selectinload
from jose import JWTError

# Jinja2 шаблоны
_TEMPLATES_DIR = Path(__file__).parent.parent / "templates"
templates = Jinja2Templates(directory=str(_TEMPLATES_DIR))

router = APIRouter(prefix="/panel", tags=["panel"])

# Константа куки для сессии
SESSION_COOKIE = "medfind_admin_token"


# ── Вспомогательные функции ──────────────────────────────────────────────────

async def _get_admin(request: Request, db: AsyncSession) -> Optional[User]:
    """Возвращает admin-пользователя из сессионной куки или None."""
    token = request.cookies.get(SESSION_COOKIE)
    if not token:
        return None
    try:
        payload = decode_token(token)
        user_id = int(payload.get("sub", 0))
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user and user.role == "admin":
            return user
    except (JWTError, Exception):
        pass
    return None


def _redirect_login():
    return RedirectResponse("/panel/login", status_code=302)


async def _pending_count(db: AsyncSession) -> int:
    d = (await db.execute(select(func.count()).where(Doctor.status == "pending"))).scalar() or 0
    c = (await db.execute(select(func.count()).where(Clinic.status == "pending"))).scalar() or 0
    return d + c


def _ctx(request: Request, active: str, extra: dict = None, pending_count: int = 0) -> dict:
    base = {"request": request, "active": active, "pending_count": pending_count}
    if extra:
        base.update(extra)
    return base


# ── Аутентификация ────────────────────────────────────────────────────────────

@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request):
    return templates.TemplateResponse("admin/login.html", {"request": request})


@router.post("/login")
async def login_submit(
    request: Request,
    phone: str = Form(...),
    password: str = Form(...),
    db: AsyncSession = Depends(get_db),
):
    # Ищем пользователя с ролью admin
    result = await db.execute(select(User).where(User.phone == phone, User.role == "admin"))
    user = result.scalar_one_or_none()

    # Простая проверка: в dev-режиме пароль "admin123", или через password_hash
    if not user:
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Пользователь не найден или нет прав администратора"},
            status_code=401,
        )

    if not user.password_hash or not verify_password(password, user.password_hash):
        return templates.TemplateResponse(
            "admin/login.html",
            {"request": request, "error": "Неверный пароль"},
            status_code=401,
        )

    token = create_access_token({"sub": str(user.id)})
    response = RedirectResponse("/panel/", status_code=302)
    response.set_cookie(SESSION_COOKIE, token, httponly=True, max_age=86400 * 7)
    return response


@router.get("/logout")
async def logout():
    response = RedirectResponse("/panel/login", status_code=302)
    response.delete_cookie(SESSION_COOKIE)
    return response


# ── Дашборд ───────────────────────────────────────────────────────────────────

@router.get("/", response_class=HTMLResponse)
async def dashboard(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)

    # Статистика
    d_total = (await db.execute(select(func.count(Doctor.id)))).scalar() or 0
    c_total = (await db.execute(select(func.count(Clinic.id)))).scalar() or 0
    p_total = (await db.execute(select(func.count(PharmacyCompany.id)))).scalar() or 0

    stats = {
        "doctors_total": d_total,
        "clinics_total": c_total,
        "pharmacies_total": p_total,
        "pending_total": pc,
    }

    # Breakdown по статусам для графика
    total_all = d_total + c_total + p_total or 1
    d_active = (await db.execute(select(func.count(Doctor.id)).where(Doctor.status == "active"))).scalar() or 0
    c_active = (await db.execute(select(func.count(Clinic.id)).where(Clinic.status == "active"))).scalar() or 0
    status_breakdown = [
        {"label": "Активные врачи",   "count": d_active,         "pct": round(d_active / total_all * 100)},
        {"label": "Активные клиники", "count": c_active,         "pct": round(c_active / total_all * 100)},
        {"label": "На модерации",     "count": pc,               "pct": round(pc / total_all * 100)},
    ]

    # ── Активность пользователей ──
    now = datetime.now(timezone.utc)
    cutoff_30 = now - timedelta(days=30)
    dau = (await db.execute(
        select(func.count(User.id)).where(User.last_active_at >= now - timedelta(days=1))
    )).scalar() or 0
    wau = (await db.execute(
        select(func.count(User.id)).where(User.last_active_at >= now - timedelta(days=7))
    )).scalar() or 0
    mau = (await db.execute(
        select(func.count(User.id)).where(User.last_active_at >= now - timedelta(days=30))
    )).scalar() or 0

    # ── Регистрации сегодня по ролям ──
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    today_rows = (await db.execute(
        select(User.role, func.count(User.id))
        .where(User.created_at >= today_start)
        .group_by(User.role)
    )).all()
    today_regs = {role: count for role, count in today_rows}

    activity = {
        "dau": dau,
        "wau": wau,
        "mau": mau,
        "today_patients": today_regs.get("patient", 0),
        "today_doctors": today_regs.get("doctor", 0),
        "today_clinics": today_regs.get("clinic", 0),
        "today_pharmacies": today_regs.get("pharmacy", 0),
        "today_total": sum(today_regs.values()),
    }

    # ── Жалобы за 24ч ──
    complaints_new_total = (await db.execute(
        select(func.count(Complaint.id)).where(Complaint.status == "new")
    )).scalar() or 0
    complaints_24h = (await db.execute(
        select(func.count(Complaint.id)).where(Complaint.created_at >= now - timedelta(days=1))
    )).scalar() or 0

    # ── График: регистрации по дням за 30 дней ──
    reg_rows = (await db.execute(
        select(
            func.date(User.created_at).label("day"),
            func.count(User.id),
        ).where(User.created_at >= cutoff_30)
        .group_by(func.date(User.created_at))
        .order_by(func.date(User.created_at))
    )).all()
    reg_chart_labels = []
    reg_chart_values = []
    reg_map = {str(day): count for day, count in reg_rows}
    for i in range(30):
        d = (cutoff_30 + timedelta(days=i)).date()
        reg_chart_labels.append(d.strftime("%d.%m"))
        reg_chart_values.append(reg_map.get(str(d), 0))

    # Последние 6 врачей
    recent_result = await db.execute(select(Doctor).order_by(Doctor.created_at.desc()).limit(6))
    recent_doctors = recent_result.scalars().all()

    return templates.TemplateResponse(
        "admin/dashboard.html",
        _ctx(request, "dashboard", {
            "stats": stats,
            "status_breakdown": status_breakdown,
            "recent_doctors": recent_doctors,
            "activity": activity,
            "complaints_new_total": complaints_new_total,
            "complaints_24h": complaints_24h,
            "complaints_new_count": complaints_new_total,
            "reg_chart_labels": reg_chart_labels,
            "reg_chart_values": reg_chart_values,
        }, pending_count=pc),
    )


# ── Врачи ─────────────────────────────────────────────────────────────────────

@router.get("/doctors", response_class=HTMLResponse)
async def doctors_list(
    request: Request,
    status: str = "all",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)

    q = select(Doctor).order_by(Doctor.created_at.desc())
    if status != "all":
        q = q.where(Doctor.status == status)
    doctors = (await db.execute(q)).scalars().all()

    # Подсчёт для вкладок
    counts = {}
    for s in ("all", "active", "pending", "rejected"):
        sq = select(func.count(Doctor.id))
        if s != "all":
            sq = sq.where(Doctor.status == s)
        counts[s] = (await db.execute(sq)).scalar() or 0

    return templates.TemplateResponse(
        "admin/doctors.html",
        _ctx(request, "doctors", {"doctors": doctors, "counts": counts, "current_status": status}, pc),
    )


@router.get("/doctors/{doctor_id}", response_class=HTMLResponse)
async def doctor_detail(request: Request, doctor_id: int, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    result = await db.execute(
        select(Doctor)
        .options(
            selectinload(Doctor.contacts),
            selectinload(Doctor.services),
            selectinload(Doctor.schedules),
        )
        .where(Doctor.id == doctor_id)
    )
    doctor = result.scalar_one_or_none()
    if not doctor:
        return RedirectResponse("/panel/doctors", status_code=302)

    return templates.TemplateResponse(
        "admin/doctor_detail.html",
        _ctx(request, "doctors", {"doctor": doctor}, pc),
    )


# ── Клиники ───────────────────────────────────────────────────────────────────

@router.get("/clinics", response_class=HTMLResponse)
async def clinics_list(
    request: Request,
    status: str = "all",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    q = select(Clinic).order_by(Clinic.created_at.desc())
    if status != "all":
        q = q.where(Clinic.status == status)
    clinics = (await db.execute(q)).scalars().all()

    counts = {}
    for s in ("all", "active", "pending", "rejected"):
        sq = select(func.count(Clinic.id))
        if s != "all":
            sq = sq.where(Clinic.status == s)
        counts[s] = (await db.execute(sq)).scalar() or 0

    return templates.TemplateResponse(
        "admin/clinics.html",
        _ctx(request, "clinics", {"clinics": clinics, "counts": counts, "current_status": status}, pc),
    )


# ── Аптеки ────────────────────────────────────────────────────────────────────

@router.get("/pharmacies", response_class=HTMLResponse)
async def pharmacies_list(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    pharmacies = (await db.execute(
        select(PharmacyCompany)
        .options(selectinload(PharmacyCompany.branches))
        .order_by(PharmacyCompany.created_at.desc())
    )).scalars().all()
    return templates.TemplateResponse(
        "admin/pharmacies.html",
        _ctx(request, "pharmacies", {"pharmacies": pharmacies}, pc),
    )


# ── Пользователи ──────────────────────────────────────────────────────────────

@router.get("/users", response_class=HTMLResponse)
async def users_list(
    request: Request,
    role: str = "all",
    status: str = "all",  # all | active | blocked | deleted
    q: str = "",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    query = select(User)
    if role != "all":
        query = query.where(User.role == role)
    if status == "active":
        query = query.where(User.is_active.is_(True), User.deleted_at.is_(None))
    elif status == "blocked":
        query = query.where(User.is_active.is_(False), User.deleted_at.is_(None))
    elif status == "deleted":
        query = query.where(User.deleted_at.isnot(None))
    else:  # all: исключаем soft-deleted из общего по умолчанию
        query = query.where(User.deleted_at.is_(None))
    if q:
        pattern = f"%{q}%"
        query = query.where(
            (User.full_name.ilike(pattern)) | (User.phone.ilike(pattern)) | (User.email.ilike(pattern))
        )
    query = query.order_by(User.created_at.desc()).limit(500)
    users = (await db.execute(query)).scalars().all()

    return templates.TemplateResponse(
        "admin/users.html",
        _ctx(request, "users", {
            "users": users,
            "filter_role": role,
            "filter_status": status,
            "filter_q": q,
            "roles": ["patient", "doctor", "clinic", "pharmacy", "admin"],
        }, pc),
    )




@router.get("/users/{user_id}/history", response_class=HTMLResponse)
async def panel_user_history(
    user_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if not user:
        return RedirectResponse("/panel/users", status_code=302)
    pc = await _pending_count(db)
    logs = (await db.execute(
        select(AdminLog, User)
        .outerjoin(User, AdminLog.admin_user_id == User.id)
        .where(AdminLog.target_type == "user", AdminLog.target_id == user_id)
        .order_by(AdminLog.created_at.desc())
        .limit(100)
    )).all()
    items = [{
        "action": l.action,
        "details": l.details,
        "admin_name": (u.full_name if u else None) or f"#{l.admin_user_id}",
        "created_at": l.created_at,
    } for l, u in logs]
    return templates.TemplateResponse(
        "admin/user_history.html",
        _ctx(request, "users", {"user": user, "items": items}, pending_count=pc),
    )


# ── Логи действий админов ────────────────────────────────────────────────────

@router.get("/admin-logs", response_class=HTMLResponse)
async def admin_logs_list(
    request: Request,
    action: str = "all",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    q = select(AdminLog, User).join(User, AdminLog.admin_user_id == User.id, isouter=True)
    if action != "all":
        q = q.where(AdminLog.action == action)
    q = q.order_by(AdminLog.created_at.desc()).limit(300)
    rows = (await db.execute(q)).all()
    items = [{
        "id": l.id,
        "admin_name": (u.full_name if u else None) or (u.phone if u else f"#{l.admin_user_id}"),
        "action": l.action,
        "target_type": l.target_type,
        "target_id": l.target_id,
        "details": l.details,
        "ip_address": l.ip_address,
        "created_at": l.created_at,
    } for l, u in rows]

    # Уникальные action для фильтра
    actions_r = await db.execute(select(AdminLog.action).distinct())
    distinct_actions = sorted({a for (a,) in actions_r.all() if a})

    return templates.TemplateResponse(
        "admin/admin_logs.html",
        _ctx(request, "admin_logs", {
            "items": items,
            "actions": distinct_actions,
            "current_action": action,
        }, pc),
    )


# ── Жалобы ─────────────────────────────────────────────────────────────────

_REASON_LABELS = {
    "wrong_info": "Недостоверная информация",
    "rude_behavior": "Грубое поведение",
    "fraud": "Мошенничество",
    "spam": "Спам / реклама",
    "fake": "Поддельный профиль",
    "other": "Другое",
}


async def _complaints_stats(db: AsyncSession) -> dict:
    rows = (await db.execute(
        select(Complaint.status, func.count(Complaint.id)).group_by(Complaint.status)
    )).all()
    return {status: count for status, count in rows}


async def _complaint_target_title(db: AsyncSession, target_type: str, target_id: int):
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
        if text and len(text) > 80:
            return text[:80] + "…"
        return text
    return None


@router.get("/complaints", response_class=HTMLResponse)
async def panel_complaints(
    request: Request,
    status: str = "new",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    q = select(Complaint, User).join(User, Complaint.author_id == User.id, isouter=True)
    if status != "all":
        q = q.where(Complaint.status == status)
    q = q.order_by(Complaint.created_at.desc()).limit(200)
    rows = (await db.execute(q)).all()

    items = []
    for c, author in rows:
        items.append({
            "id": c.id,
            "target_type": c.target_type,
            "target_id": c.target_id,
            "target_title": await _complaint_target_title(db, c.target_type, c.target_id),
            "reason": c.reason,
            "comment": c.comment,
            "status": c.status,
            "resolution_note": c.resolution_note,
            "author_name": author.full_name if author else None,
            "author_phone": author.phone if author else None,
            "created_at": c.created_at,
        })

    stats = await _complaints_stats(db)
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/complaints.html",
        _ctx(request, "complaints", {
            "items": items,
            "status": status,
            "stats": stats,
            "reason_labels": _REASON_LABELS,
            "complaints_new_count": stats.get("new", 0),
        }, pending_count=pc),
    )


# ── Карточка клиники (только просмотр) ────────────────────────────────────

@router.get("/clinics/{clinic_id}", response_class=HTMLResponse)
async def panel_clinic_detail(
    clinic_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    clinic = (await db.execute(
        select(Clinic).options(selectinload(Clinic.photos)).where(Clinic.id == clinic_id)
    )).scalar_one_or_none()
    if not clinic:
        return RedirectResponse("/panel/clinics", status_code=302)

    # Активные врачи клиники
    doctors = (await db.execute(
        select(Doctor).where(Doctor.clinic_id == clinic_id)
        .order_by(Doctor.status, Doctor.full_name_ru)
    )).scalars().all()

    # Жалобы на клинику
    complaints = (await db.execute(
        select(Complaint)
        .where(Complaint.target_type == "clinic", Complaint.target_id == clinic_id)
        .order_by(Complaint.created_at.desc()).limit(20)
    )).scalars().all()

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/clinic_detail.html",
        _ctx(request, "clinics", {
            "clinic": clinic, "doctors": doctors,
            "complaints": complaints,
        }, pending_count=pc),
    )


# ── Аптеки: карточка (только просмотр) ───────────────────────────────────

@router.get("/pharmacies/{company_id}", response_class=HTMLResponse)
async def panel_pharmacy_detail(
    company_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    company = (await db.execute(
        select(PharmacyCompany).options(selectinload(PharmacyCompany.branches))
        .where(PharmacyCompany.id == company_id)
    )).scalar_one_or_none()
    if not company:
        return RedirectResponse("/panel/pharmacies", status_code=302)

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/pharmacy_detail.html",
        _ctx(request, "pharmacies", {
            "company": company,
        }, pending_count=pc),
    )


# ── Аналитика платформы ───────────────────────────────────────────────────

@router.get("/analytics", response_class=HTMLResponse)
async def panel_analytics(
    request: Request,
    days: int = 90,
    db: AsyncSession = Depends(get_db),
):
    from app.models.search_log import SearchLog
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=days)

    # ── DAU/WAU/MAU за период (тренд) ──
    # Считаем количество уникальных user_id, активных в каждый день
    activity_rows = (await db.execute(
        select(
            func.date(User.last_active_at).label("day"),
            func.count(func.distinct(User.id)),
        ).where(User.last_active_at >= cutoff)
        .group_by(func.date(User.last_active_at))
        .order_by(func.date(User.last_active_at))
    )).all()
    activity_map = {str(d): cnt for d, cnt in activity_rows}

    # ── Регистрации по дням с разбивкой по ролям ──
    reg_rows = (await db.execute(
        select(
            func.date(User.created_at).label("day"),
            User.role,
            func.count(User.id),
        ).where(User.created_at >= cutoff)
        .group_by(func.date(User.created_at), User.role)
        .order_by(func.date(User.created_at))
    )).all()

    chart_labels = []
    dau_values = []
    reg_data = {"patient": [], "doctor": [], "clinic": [], "pharmacy": []}
    for i in range(days):
        d = (cutoff + timedelta(days=i)).date()
        ds = str(d)
        chart_labels.append(d.strftime("%d.%m"))
        dau_values.append(activity_map.get(ds, 0))
        for role in reg_data:
            count = sum(c for day, r, c in reg_rows if str(day) == ds and r == role)
            reg_data[role].append(count)

    # ── Топ-20 поисковых запросов ──
    top_searches = (await db.execute(
        select(SearchLog.query, func.count(SearchLog.id).label("cnt"))
        .where(SearchLog.created_at >= cutoff)
        .group_by(SearchLog.query)
        .order_by(func.count(SearchLog.id).desc())
        .limit(20)
    )).all()

    # ── Топ городов ──
    top_cities = (await db.execute(
        select(User.city, func.count(User.id))
        .where(User.city.isnot(None), User.deleted_at.is_(None))
        .group_by(User.city)
        .order_by(func.count(User.id).desc())
        .limit(15)
    )).all()

    # ── Суммарные счётчики ──
    totals_users = (await db.execute(
        select(User.role, func.count(User.id)).where(User.deleted_at.is_(None)).group_by(User.role)
    )).all()
    totals = {r: c for r, c in totals_users}

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/analytics.html",
        _ctx(request, "analytics", {
            "days": days,
            "chart_labels": chart_labels,
            "dau_values": dau_values,
            "reg_data": reg_data,
            "top_searches": [{"query": q, "count": c} for q, c in top_searches],
            "top_cities": [{"city": c, "count": cnt} for c, cnt in top_cities],
            "totals": totals,
        }, pending_count=pc),
    )


# ── Отзывы ────────────────────────────────────────────────────────────────────

async def _review_target_title(db: AsyncSession, review) -> tuple[str, str]:
    if review.doctor_id:
        d = (await db.execute(select(Doctor).where(Doctor.id == review.doctor_id))).scalar_one_or_none()
        return ("Врач", d.full_name_ru if d else f"#{review.doctor_id}")
    if review.clinic_id:
        c = (await db.execute(select(Clinic).where(Clinic.id == review.clinic_id))).scalar_one_or_none()
        return ("Клиника", c.name_ru if c else f"#{review.clinic_id}")
    if review.branch_id:
        b = (await db.execute(select(PharmacyBranch).where(PharmacyBranch.id == review.branch_id))).scalar_one_or_none()
        return ("Филиал аптеки", (b.address or f"#{review.branch_id}") if b else f"#{review.branch_id}")
    return ("—", "—")


@router.get("/reviews", response_class=HTMLResponse)
async def panel_reviews(request: Request, rating: str = "all", db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    q = select(Review, User).join(User, Review.author_id == User.id, isouter=True)
    if rating in ("1", "2", "3", "4", "5"):
        q = q.where(Review.rating == int(rating))
    q = q.order_by(Review.created_at.desc()).limit(200)
    rows = (await db.execute(q)).all()

    items = []
    for r, author in rows:
        ttype, ttitle = await _review_target_title(db, r)
        items.append({
            "id": r.id,
            "target_type": ttype,
            "target_title": ttitle,
            "rating": int(r.rating or 0),
            "text": r.text,
            "author_name": author.full_name if author else None,
            "author_phone": author.phone if author else None,
            "created_at": r.created_at,
        })

    total = (await db.execute(select(func.count(Review.id)))).scalar() or 0
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/reviews.html",
        _ctx(request, "reviews", {"items": items, "rating": rating, "total": total}, pending_count=pc),
    )


@router.post("/reviews/{review_id}/delete")
async def panel_review_delete(
    review_id: int,
    request: Request,
    reason: str = Form(default=""),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    review = (await db.execute(select(Review).where(Review.id == review_id))).scalar_one_or_none()
    if review:
        from app.routers.reviews import (
            _recalc_doctor_rating, _recalc_clinic_rating, _recalc_branch_rating,
        )
        doctor_id, clinic_id, branch_id = review.doctor_id, review.clinic_id, review.branch_id
        await db.delete(review)
        await db.flush()
        if doctor_id:
            await _recalc_doctor_rating(doctor_id, db)
        elif clinic_id:
            await _recalc_clinic_rating(clinic_id, db)
        elif branch_id:
            await _recalc_branch_rating(branch_id, db)
        await log_action(
            db, admin_id=admin.id, action="review.delete",
            target_type="review", target_id=review_id,
            details=f"причина: {reason}" if reason.strip() else "без указания причины",
            request=request,
        )
        await db.commit()

    return RedirectResponse("/panel/reviews", status_code=302)


# ── Служебные функции ────────────────────────────────────────────────────────

_LAST_JOB_RESULT: dict = {}


@router.get("/system", response_class=HTMLResponse)
async def panel_system(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    from app.services.scheduler import JOBS
    from app.core.config import settings
    jobs = [{"name": name, "last": _LAST_JOB_RESULT.get(name)} for name in JOBS.keys()]
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/system.html",
        _ctx(request, "system", {
            "jobs": jobs,
            "test_push": _LAST_JOB_RESULT.get("test_push"),
            "scheduler_time": f"{settings.SCHEDULER_HOUR:02d}:{settings.SCHEDULER_MINUTE:02d}",
            "scheduler_tz": settings.SCHEDULER_TIMEZONE,
        }, pending_count=pc),
    )


@router.post("/system/run/{name}")
async def panel_system_run(name: str, request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    from app.services.scheduler import run_job, JOBS
    if name in JOBS:
        result = await run_job(name)
        _LAST_JOB_RESULT[name] = {
            "at": datetime.now(timezone.utc),
            "ok": result.get("ok"),
            "info": result.get("stats") or result.get("error"),
        }
        await log_action(db, admin_id=admin.id, action="system.run_job",
                         target_type="job", details=name, request=request)
        await db.commit()
    return RedirectResponse("/panel/system", status_code=302)


@router.post("/system/test-push")
async def panel_system_test_push(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    from app.services.fcm import send_push
    await send_push(
        admin.fcm_token,
        "Тестовое уведомление",
        "Проверка работы push-уведомлений MedFind.",
        notification_type="system_test",
        db=db, user_id=admin.id,
    )
    _LAST_JOB_RESULT["test_push"] = {
        "at": datetime.now(timezone.utc),
        "ok": True,
        "info": "push отправлен" if admin.fcm_token else "in-app сохранено (FCM-токен не задан)",
    }
    await log_action(db, admin_id=admin.id, action="system.test_push",
                     target_type="user", target_id=admin.id, request=request)
    await db.commit()
    return RedirectResponse("/panel/system", status_code=302)


