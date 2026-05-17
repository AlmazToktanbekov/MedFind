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
from app.models.article import Article
from app.models.wallet import Wallet, WalletTransaction
from app.models.subscription import Subscription
from app.models.admin_log import AdminLog
from app.models.complaint import Complaint
from app.models.review import Review
from app.models.pharmacy import PharmacyBranch
from app.services import wallet_service as wallets
from app.services import subscription_service as subs
from datetime import datetime, timedelta, timezone
from app.services.admin_log_service import log_action
from sqlalchemy.orm import selectinload
from jose import JWTError
from decimal import Decimal

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

    # Финансы и подписки для дашборда
    now = datetime.now(timezone.utc)
    cutoff_30 = now - timedelta(days=30)
    cutoff_7 = now + timedelta(days=7)

    revenue_30d = (await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount_usd), 0)).where(
            WalletTransaction.type == "purchase",
            WalletTransaction.status == "success",
            WalletTransaction.created_at >= cutoff_30,
        )
    )).scalar() or 0
    expiring_subs = (await db.execute(
        select(func.count()).where(
            Subscription.status == "active",
            Subscription.expires_at.isnot(None),
            Subscription.expires_at <= cutoff_7,
            Subscription.expires_at >= now,
        )
    )).scalar() or 0
    pending_topups = (await db.execute(
        select(func.count()).where(
            WalletTransaction.type == "topup",
            WalletTransaction.status == "pending",
        )
    )).scalar() or 0

    revenue_today = (await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount_usd), 0)).where(
            WalletTransaction.type == "purchase",
            WalletTransaction.status == "success",
            WalletTransaction.created_at >= now - timedelta(days=1),
        )
    )).scalar() or 0
    revenue_7d = (await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount_usd), 0)).where(
            WalletTransaction.type == "purchase",
            WalletTransaction.status == "success",
            WalletTransaction.created_at >= now - timedelta(days=7),
        )
    )).scalar() or 0

    finance = {
        "revenue_today_usd": float(revenue_today),
        "revenue_7d_usd": float(revenue_7d),
        "revenue_30d_usd": float(revenue_30d),
        "expiring_subs": expiring_subs,
        "pending_topups": pending_topups,
    }

    # ── Активность пользователей ──
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

    # ── График: выручка по дням за 30 дней ──
    rev_rows = (await db.execute(
        select(
            func.date(WalletTransaction.created_at).label("day"),
            func.coalesce(func.sum(WalletTransaction.amount_usd), 0),
        ).where(
            WalletTransaction.type == "purchase",
            WalletTransaction.status == "success",
            WalletTransaction.created_at >= cutoff_30,
        )
        .group_by(func.date(WalletTransaction.created_at))
        .order_by(func.date(WalletTransaction.created_at))
    )).all()
    rev_map = {str(day): float(amt) for day, amt in rev_rows}
    rev_chart_values = [rev_map.get(str((cutoff_30 + timedelta(days=i)).date()), 0.0)
                        for i in range(30)]

    # Последние 6 врачей
    recent_result = await db.execute(select(Doctor).order_by(Doctor.created_at.desc()).limit(6))
    recent_doctors = recent_result.scalars().all()

    # Заявки на модерации (первые 5)
    pend_d = (await db.execute(select(Doctor).where(Doctor.status == "pending").limit(5))).scalars().all()
    pend_c = (await db.execute(select(Clinic).where(Clinic.status == "pending").limit(3))).scalars().all()
    pending_items = []
    for d in pend_d:
        pending_items.append({"id": d.id, "entity_type": "doctor", "name": d.full_name_ru,
                               "type": "Врач", "detail": d.specialization_ru})
    for c in pend_c:
        pending_items.append({"id": c.id, "entity_type": "clinic", "name": c.name_ru,
                               "type": "Клиника", "detail": c.category_ru or ""})

    return templates.TemplateResponse(
        "admin/dashboard.html",
        _ctx(request, "dashboard", {
            "stats": stats,
            "status_breakdown": status_breakdown,
            "recent_doctors": recent_doctors,
            "pending_items": pending_items,
            "finance": finance,
            "activity": activity,
            "complaints_new_total": complaints_new_total,
            "complaints_24h": complaints_24h,
            "complaints_new_count": complaints_new_total,  # для бейджа в нав
            "reg_chart_labels": reg_chart_labels,
            "reg_chart_values": reg_chart_values,
            "rev_chart_values": rev_chart_values,
            "topup_pending_count": pending_topups,
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


# ── Модерация (pending) ───────────────────────────────────────────────────────

@router.get("/pending", response_class=HTMLResponse)
async def pending_list(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    doctors  = (await db.execute(select(Doctor).where(Doctor.status   == "pending").order_by(Doctor.created_at))).scalars().all()
    clinics  = (await db.execute(select(Clinic).where(Clinic.status   == "pending").order_by(Clinic.created_at))).scalars().all()
    return templates.TemplateResponse(
        "admin/pending.html",
        _ctx(request, "pending", {"doctors": doctors, "clinics": clinics}, pc),
    )


# ── Одобрить / Отклонить ──────────────────────────────────────────────────────

@router.post("/approve/{entity_type}/{entity_id}")
async def approve(
    request: Request,
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    entity = await _find_entity(entity_type, entity_id, db)
    if entity:
        old = entity.status
        entity.status = "active"
        await log_action(db, admin_id=admin.id, action=f"{entity_type}.approve",
                         target_type=entity_type, target_id=entity_id,
                         details=f"status {old} -> active", request=request)
        await db.commit()

    return RedirectResponse(request.headers.get("referer", "/panel/pending"), status_code=302)


@router.post("/reject/{entity_type}/{entity_id}")
async def reject(
    request: Request,
    entity_type: str,
    entity_id: int,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    entity = await _find_entity(entity_type, entity_id, db)
    if entity:
        old = entity.status
        entity.status = "rejected"
        await log_action(db, admin_id=admin.id, action=f"{entity_type}.reject",
                         target_type=entity_type, target_id=entity_id,
                         details=f"status {old} -> rejected", request=request)
        await db.commit()

    return RedirectResponse(request.headers.get("referer", "/panel/pending"), status_code=302)


async def _find_entity(entity_type: str, entity_id: int, db: AsyncSession):
    model = {"doctor": Doctor, "clinic": Clinic}.get(entity_type)
    if not model:
        return None
    return (await db.execute(select(model).where(model.id == entity_id))).scalar_one_or_none()


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


@router.post("/users/{user_id}/block")
async def panel_user_block(
    user_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    if user_id == admin.id:
        return RedirectResponse("/panel/users", status_code=302)
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if user:
        was_active = user.is_active
        user.is_active = not was_active
        if not user.is_active:
            user.refresh_token = None  # инвалидируем все сессии
        await log_action(
            db, admin.id,
            action="user.unblock" if was_active is False else "user.block",
            target_type="user",
            target_id=user.id,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", "/panel/users"),
        status_code=302,
    )


@router.post("/users/{user_id}/reset-password")
async def panel_user_reset_password(
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

    import secrets, string
    from app.core.security import hash_password
    temp_password = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(10))
    user.password_hash = hash_password(temp_password)
    user.must_change_password = True
    user.refresh_token = None
    await log_action(
        db, admin.id,
        action="user.password_reset",
        target_type="user",
        target_id=user.id,
        request=request,
    )

    # Возвращаемся с временным паролем во flash-cookie (показывается один раз)
    response = RedirectResponse(
        request.headers.get("referer", "/panel/users"),
        status_code=302,
    )
    response.set_cookie(
        "flash_temp_password",
        f"{user.phone}|{temp_password}",
        max_age=30,
        httponly=False,  # читается клиентом
    )
    return response


@router.post("/users/{user_id}/role")
async def panel_user_change_role(
    user_id: int,
    request: Request,
    role: str = Form(...),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    if role not in ("patient", "doctor", "clinic", "pharmacy", "admin"):
        return RedirectResponse("/panel/users", status_code=302)
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if user and user.id != admin.id:
        old = user.role
        user.role = role
        await log_action(
            db, admin.id,
            action="user.change_role",
            target_type="user",
            target_id=user.id,
            details=f"{old} → {role}",
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", "/panel/users"),
        status_code=302,
    )


@router.post("/users/{user_id}/delete")
async def panel_user_soft_delete(
    user_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    if user_id == admin.id:
        return RedirectResponse("/panel/users", status_code=302)
    user = (await db.execute(select(User).where(User.id == user_id))).scalar_one_or_none()
    if user:
        user.deleted_at = datetime.now(timezone.utc)
        user.is_active = False
        user.refresh_token = None
        await log_action(
            db, admin.id,
            action="user.delete",
            target_type="user",
            target_id=user.id,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", "/panel/users"),
        status_code=302,
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


# ── Статьи ────────────────────────────────────────────────────────────────────

@router.get("/articles", response_class=HTMLResponse)
async def articles_list(
    request: Request,
    cat: str = "all",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    q = select(Article).order_by(Article.created_at.desc())
    if cat != "all":
        q = q.where(Article.category == cat)
    articles = (await db.execute(q)).scalars().all()

    counts = {"all": 0, "article": 0, "first_aid": 0, "health_tip": 0}
    for c in ("all", "article", "first_aid", "health_tip"):
        sq = select(func.count(Article.id))
        if c != "all":
            sq = sq.where(Article.category == c)
        counts[c] = (await db.execute(sq)).scalar() or 0

    return templates.TemplateResponse(
        "admin/articles.html",
        _ctx(request, "articles", {"articles": articles, "counts": counts, "current_cat": cat}, pc),
    )


@router.post("/articles/{article_id}/toggle")
async def toggle_article(
    request: Request,
    article_id: int,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    result = await db.execute(select(Article).where(Article.id == article_id))
    article = result.scalar_one_or_none()
    if article:
        article.is_published = not article.is_published
        await log_action(db, admin_id=admin.id, action="article.toggle",
                         target_type="article", target_id=article.id,
                         details=f"is_published -> {article.is_published}", request=request)
        await db.commit()

    return RedirectResponse(request.headers.get("referer", "/panel/articles"), status_code=302)


# ── Wallet topup requests ────────────────────────────────────────────────────

async def _topup_pending_count(db: AsyncSession) -> int:
    r = await db.execute(
        select(func.count()).where(
            WalletTransaction.type == "topup",
            WalletTransaction.status == "pending",
        )
    )
    return r.scalar() or 0


@router.get("/wallet/topups", response_class=HTMLResponse)
async def panel_wallet_topups(
    request: Request,
    status: str = "pending",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    q = select(WalletTransaction, Wallet).join(
        Wallet, WalletTransaction.wallet_id == Wallet.id
    ).where(WalletTransaction.type == "topup")
    if status != "all":
        q = q.where(WalletTransaction.status == status)
    q = q.order_by(WalletTransaction.created_at.desc())
    rows = (await db.execute(q)).all()

    # Резолвим имя владельца (клиники/аптеки) для красоты
    items = []
    for tx, w in rows:
        owner_name = None
        if w.owner_type == "clinic":
            r = await db.execute(select(Clinic.name_ru).where(Clinic.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        elif w.owner_type == "pharmacy":
            r = await db.execute(select(PharmacyCompany.name).where(PharmacyCompany.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        items.append({
            "id": tx.id,
            "owner_type": w.owner_type,
            "owner_id": w.owner_id,
            "owner_name": owner_name,
            "amount_usd": float(tx.amount_usd),
            "payment_code": tx.payment_code,
            "status": tx.status,
            "comment": tx.comment,
            "created_at": tx.created_at,
        })

    pc = await _pending_count(db)
    topup_pc = await _topup_pending_count(db)
    return templates.TemplateResponse(
        "admin/wallet_topups.html",
        _ctx(request, "wallet_topups", {
            "items": items,
            "status": status,
            "pending_count": topup_pc,
            "topup_pending_count": topup_pc,
        }, pending_count=pc),
    )


@router.post("/wallet/topups/{tx_id}/confirm")
async def panel_confirm_topup(
    tx_id: int,
    request: Request,
    actual_amount_usd: float = Form(...),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    try:
        await wallets.confirm_topup(db, tx_id, Decimal(str(actual_amount_usd)), admin_user_id=admin.id)
        await log_action(db, admin_id=admin.id, action="wallet.topup_confirm",
                         target_type="wallet_tx", target_id=tx_id,
                         details=f"amount_usd={actual_amount_usd}", request=request)
        await db.commit()
    except wallets.WalletError:
        pass  # silently — для простоты, можно flash-сообщения добавить
    return RedirectResponse("/panel/wallet/topups", status_code=302)


@router.post("/wallet/topups/{tx_id}/cancel")
async def panel_cancel_topup(
    tx_id: int,
    request: Request,
    reason: str = Form(""),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    try:
        await wallets.cancel_topup(db, tx_id, reason or "Без причины", admin_user_id=admin.id)
        await log_action(db, admin_id=admin.id, action="wallet.topup_cancel",
                         target_type="wallet_tx", target_id=tx_id,
                         details=f"reason={reason or 'Без причины'}", request=request)
        await db.commit()
    except wallets.WalletError:
        pass
    return RedirectResponse("/panel/wallet/topups", status_code=302)


# ── Финансы ───────────────────────────────────────────────────────────────────

@router.get("/finance", response_class=HTMLResponse)
async def finance_overview(
    request: Request,
    type: str = "all",     # all | topup | purchase | refund
    status: str = "all",   # all | pending | completed | cancelled
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)

    # Базовый запрос — все транзакции кошелька (deposits/purchases/refunds)
    q = select(WalletTransaction, Wallet).join(
        Wallet, WalletTransaction.wallet_id == Wallet.id
    )
    if type != "all":
        q = q.where(WalletTransaction.type == type)
    if status != "all":
        q = q.where(WalletTransaction.status == status)
    q = q.order_by(WalletTransaction.created_at.desc()).limit(200)
    rows = (await db.execute(q)).all()

    items = []
    for tx, w in rows:
        owner_name = None
        if w.owner_type == "clinic":
            r = await db.execute(select(Clinic.name_ru).where(Clinic.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        elif w.owner_type == "pharmacy":
            r = await db.execute(select(PharmacyCompany.name).where(PharmacyCompany.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        items.append({
            "id": tx.id,
            "owner_type": w.owner_type,
            "owner_id": w.owner_id,
            "owner_name": owner_name or f"#{w.owner_id}",
            "type": tx.type,
            "status": tx.status,
            "amount_usd": float(tx.amount_usd),
            "payment_code": tx.payment_code,
            "comment": tx.comment,
            "created_at": tx.created_at,
        })

    # Сводка: выручка за 30 дней (completed purchases) + всего пополнено
    cutoff = datetime.now(timezone.utc) - timedelta(days=30)
    rev30 = (await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount_usd), 0)).where(
            WalletTransaction.type == "purchase",
            WalletTransaction.status == "success",
            WalletTransaction.created_at >= cutoff,
        )
    )).scalar() or 0
    topup_total = (await db.execute(
        select(func.coalesce(func.sum(WalletTransaction.amount_usd), 0)).where(
            WalletTransaction.type == "topup",
            WalletTransaction.status == "success",
        )
    )).scalar() or 0
    balance_total = (await db.execute(
        select(func.coalesce(func.sum(Wallet.balance_usd), 0))
    )).scalar() or 0
    pending_topups = (await db.execute(
        select(func.count()).where(
            WalletTransaction.type == "topup",
            WalletTransaction.status == "pending",
        )
    )).scalar() or 0

    summary = {
        "revenue_30d_usd": float(rev30),
        "topup_total_usd": float(topup_total),
        "balance_total_usd": float(balance_total),
        "pending_topups": pending_topups,
    }

    return templates.TemplateResponse(
        "admin/finance.html",
        _ctx(request, "finance", {
            "items": items,
            "summary": summary,
            "current_type": type,
            "current_status": status,
        }, pc),
    )


# ── Подписки ──────────────────────────────────────────────────────────────────

@router.get("/subscriptions", response_class=HTMLResponse)
async def subscriptions_list(
    request: Request,
    plan: str = "all",
    status: str = "all",
    owner_type: str = "all",
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    q = select(Subscription).order_by(Subscription.created_at.desc())
    if plan != "all":
        q = q.where(Subscription.plan == plan)
    if status != "all":
        q = q.where(Subscription.status == status)
    if owner_type != "all":
        q = q.where(Subscription.owner_type == owner_type)
    rows = (await db.execute(q)).scalars().all()

    items = []
    now = datetime.now(timezone.utc)
    for s in rows:
        owner_name = None
        if s.owner_type == "clinic":
            r = await db.execute(select(Clinic.name_ru).where(Clinic.id == s.owner_id))
            owner_name = r.scalar_one_or_none()
        elif s.owner_type == "pharmacy":
            r = await db.execute(select(PharmacyCompany.name).where(PharmacyCompany.id == s.owner_id))
            owner_name = r.scalar_one_or_none()
        days_left = None
        if s.expires_at:
            delta = s.expires_at - now
            days_left = max(0, delta.days)
        items.append({
            "id": s.id,
            "owner_type": s.owner_type,
            "owner_id": s.owner_id,
            "owner_name": owner_name or f"#{s.owner_id}",
            "plan": s.plan,
            "period": s.period or "—",
            "is_trial": s.is_trial,
            "status": s.status,
            "started_at": s.started_at,
            "expires_at": s.expires_at,
            "days_left": days_left,
        })

    # Сводка
    counts_by_plan = {"free": 0, "pro": 0, "premium": 0}
    for it in items:
        if it["status"] == "active":
            counts_by_plan[it["plan"]] = counts_by_plan.get(it["plan"], 0) + 1

    expiring_soon = sum(1 for it in items
                        if it["status"] == "active" and it["days_left"] is not None and it["days_left"] <= 7)

    return templates.TemplateResponse(
        "admin/subscriptions.html",
        _ctx(request, "subscriptions", {
            "items": items,
            "counts_by_plan": counts_by_plan,
            "expiring_soon": expiring_soon,
            "current_plan": plan,
            "current_status": status,
            "current_owner_type": owner_type,
        }, pc),
    )


@router.post("/subscriptions/set")
async def panel_set_subscription(
    request: Request,
    owner_type: str = Form(...),
    owner_id: int = Form(...),
    plan: str = Form(...),
    period: str = Form("month"),
    days: int = Form(30),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    if owner_type not in ("clinic", "pharmacy") or plan not in ("free", "pro", "premium"):
        return RedirectResponse("/panel/subscriptions", status_code=302)
    sub = await subs.set_plan_manual(db, owner_type, owner_id, plan, days, period)
    await log_action(
        db, admin_id=admin.id, action="subscription.set_plan",
        target_type="subscription", target_id=sub.id,
        details=f"{owner_type}#{owner_id} -> plan={plan} period={period} days={days}",
        request=request,
    )
    await db.commit()
    return RedirectResponse("/panel/subscriptions", status_code=302)


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


@router.post("/complaints/{complaint_id}/status")
async def panel_complaint_update_status(
    complaint_id: int,
    request: Request,
    status: str = Form(...),
    resolution_note: Optional[str] = Form(default=None),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    if status not in ("new", "in_review", "resolved", "rejected"):
        return RedirectResponse("/panel/complaints", status_code=302)

    r = await db.execute(select(Complaint).where(Complaint.id == complaint_id))
    c = r.scalar_one_or_none()
    if not c:
        return RedirectResponse("/panel/complaints", status_code=302)

    old_status = c.status
    c.status = status
    if resolution_note:
        c.resolution_note = resolution_note
    if status in ("resolved", "rejected"):
        c.resolved_at = datetime.now(timezone.utc)
        c.resolved_by_admin_id = admin.id

    await log_action(
        db, admin.id,
        action=f"complaint.{status}",
        target_type="complaint",
        target_id=c.id,
        details=f"{old_status} → {status}" + (f"; {resolution_note}" if resolution_note else ""),
        request=request,
    )

    return RedirectResponse(
        request.headers.get("referer", f"/panel/complaints?status={old_status}"),
        status_code=302,
    )


@router.post("/complaints/{complaint_id}/delete")
async def panel_complaint_delete(
    complaint_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    r = await db.execute(select(Complaint).where(Complaint.id == complaint_id))
    c = r.scalar_one_or_none()
    if c:
        await db.delete(c)
        await log_action(
            db, admin.id,
            action="complaint.delete",
            target_type="complaint",
            target_id=complaint_id,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", "/panel/complaints"),
        status_code=302,
    )


# ── Отзывы (модерация) ────────────────────────────────────────────────────

@router.get("/reviews", response_class=HTMLResponse)
async def panel_reviews_list(
    request: Request,
    target_type: str = "all",   # all | doctor | clinic | pharmacy_branch
    min_rating: str = "all",     # all | 1..5
    has_complaints: str = "no",  # no | yes
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    q = select(Review, User).outerjoin(User, Review.author_id == User.id)

    if target_type == "doctor":
        q = q.where(Review.doctor_id.isnot(None))
    elif target_type == "clinic":
        q = q.where(Review.clinic_id.isnot(None))
    elif target_type == "pharmacy_branch":
        q = q.where(Review.branch_id.isnot(None))

    if min_rating != "all":
        try:
            q = q.where(Review.rating <= float(min_rating))
        except ValueError:
            pass

    if has_complaints == "yes":
        complained_ids = select(Complaint.target_id).where(Complaint.target_type == "review")
        q = q.where(Review.id.in_(complained_ids))

    q = q.order_by(Review.created_at.desc()).limit(200)
    rows = (await db.execute(q)).all()

    # Кол-во жалоб на каждый отзыв одним запросом
    review_ids = [r.id for r, _ in rows]
    complaint_counts: dict[int, int] = {}
    if review_ids:
        cc_rows = (await db.execute(
            select(Complaint.target_id, func.count(Complaint.id))
            .where(Complaint.target_type == "review", Complaint.target_id.in_(review_ids))
            .group_by(Complaint.target_id)
        )).all()
        complaint_counts = {tid: cnt for tid, cnt in cc_rows}

    # Резолвим название цели
    items = []
    for review, author in rows:
        target_label = "—"
        if review.doctor_id:
            r = await db.execute(select(Doctor.full_name_ru).where(Doctor.id == review.doctor_id))
            target_label = f"👨‍⚕️ {r.scalar_one_or_none() or '—'}"
        elif review.clinic_id:
            r = await db.execute(select(Clinic.name_ru).where(Clinic.id == review.clinic_id))
            target_label = f"🏥 {r.scalar_one_or_none() or '—'}"
        elif review.branch_id:
            r = await db.execute(select(PharmacyBranch.address).where(PharmacyBranch.id == review.branch_id))
            target_label = f"💊 {r.scalar_one_or_none() or '—'}"
        items.append({
            "id": review.id,
            "target_label": target_label,
            "rating": review.rating,
            "text": review.text,
            "author_name": author.full_name if author else None,
            "author_phone": author.phone if author else None,
            "created_at": review.created_at,
            "complaints_count": complaint_counts.get(review.id, 0),
        })

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/reviews.html",
        _ctx(request, "reviews", {
            "items": items,
            "filter_target": target_type,
            "filter_rating": min_rating,
            "filter_complaints": has_complaints,
        }, pending_count=pc),
    )


@router.post("/reviews/{review_id}/delete")
async def panel_review_delete(
    review_id: int,
    request: Request,
    reason: str = Form(...),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    r = await db.execute(select(Review).where(Review.id == review_id))
    review = r.scalar_one_or_none()
    if not review:
        return RedirectResponse("/panel/reviews", status_code=302)

    target_type = "doctor" if review.doctor_id else ("clinic" if review.clinic_id else "branch")
    target_id = review.doctor_id or review.clinic_id or review.branch_id
    doctor_id, clinic_id, branch_id = review.doctor_id, review.clinic_id, review.branch_id

    await db.delete(review)
    await db.flush()

    # Пересчитываем рейтинг цели
    from app.routers.reviews import _recalc_doctor_rating, _recalc_clinic_rating, _recalc_branch_rating
    if doctor_id:
        await _recalc_doctor_rating(doctor_id, db)
    elif clinic_id:
        await _recalc_clinic_rating(clinic_id, db)
    elif branch_id:
        await _recalc_branch_rating(branch_id, db)

    await log_action(
        db, admin.id,
        action="review.delete",
        target_type="review",
        target_id=review_id,
        details=f"on {target_type}#{target_id}; reason: {reason}",
        request=request,
    )
    return RedirectResponse(
        request.headers.get("referer", "/panel/reviews"),
        status_code=302,
    )


# ── Карточка клиники + управление ─────────────────────────────────────────

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

    # История подписок
    subs_history = (await db.execute(
        select(Subscription)
        .where(Subscription.owner_type == "clinic", Subscription.owner_id == clinic_id)
        .order_by(Subscription.created_at.desc()).limit(20)
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
            "subs_history": subs_history, "complaints": complaints,
        }, pending_count=pc),
    )


@router.post("/clinics/{clinic_id}/freeze")
async def panel_clinic_freeze(
    clinic_id: int,
    request: Request,
    reason: str = Form(""),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    clinic = (await db.execute(select(Clinic).where(Clinic.id == clinic_id))).scalar_one_or_none()
    if clinic:
        was_frozen = clinic.is_frozen
        clinic.is_frozen = not was_frozen
        clinic.frozen_reason = reason if clinic.is_frozen else None
        await log_action(
            db, admin.id,
            action="clinic.unfreeze" if was_frozen else "clinic.freeze",
            target_type="clinic",
            target_id=clinic.id,
            details=reason or None,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", f"/panel/clinics/{clinic_id}"),
        status_code=302,
    )


@router.post("/clinics/{clinic_id}/block")
async def panel_clinic_block(
    clinic_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    clinic = (await db.execute(select(Clinic).where(Clinic.id == clinic_id))).scalar_one_or_none()
    if clinic:
        old_status = clinic.status
        clinic.status = "blocked" if clinic.status != "blocked" else "active"
        await log_action(
            db, admin.id,
            action="clinic.block" if clinic.status == "blocked" else "clinic.unblock",
            target_type="clinic",
            target_id=clinic.id,
            details=f"{old_status} → {clinic.status}",
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", f"/panel/clinics/{clinic_id}"),
        status_code=302,
    )


# ── Аптеки: карточка + заморозка + управление филиалами ──────────────────

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

    subs_history = (await db.execute(
        select(Subscription)
        .where(Subscription.owner_type == "pharmacy", Subscription.owner_id == company_id)
        .order_by(Subscription.created_at.desc()).limit(20)
    )).scalars().all()

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/pharmacy_detail.html",
        _ctx(request, "pharmacies", {
            "company": company, "subs_history": subs_history,
        }, pending_count=pc),
    )


@router.post("/pharmacies/{company_id}/freeze")
async def panel_pharmacy_freeze(
    company_id: int,
    request: Request,
    reason: str = Form(""),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    company = (await db.execute(select(PharmacyCompany).where(PharmacyCompany.id == company_id))).scalar_one_or_none()
    if company:
        was_frozen = company.is_frozen
        company.is_frozen = not was_frozen
        company.frozen_reason = reason if company.is_frozen else None
        await log_action(
            db, admin.id,
            action="pharmacy.unfreeze" if was_frozen else "pharmacy.freeze",
            target_type="pharmacy",
            target_id=company.id,
            details=reason or None,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", f"/panel/pharmacies/{company_id}"),
        status_code=302,
    )


@router.post("/pharmacy-branches/{branch_id}/toggle")
async def panel_branch_toggle(
    branch_id: int,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    branch = (await db.execute(select(PharmacyBranch).where(PharmacyBranch.id == branch_id))).scalar_one_or_none()
    if branch:
        branch.is_active = not branch.is_active
        await log_action(
            db, admin.id,
            action="branch.activate" if branch.is_active else "branch.deactivate",
            target_type="pharmacy_branch",
            target_id=branch.id,
            request=request,
        )
    return RedirectResponse(
        request.headers.get("referer", "/panel/pharmacies"),
        status_code=302,
    )


# ── Все транзакции + CSV + refund ─────────────────────────────────────────

@router.get("/transactions", response_class=HTMLResponse)
async def panel_transactions_list(
    request: Request,
    type: str = "all",      # all | topup | purchase | refund | credit
    status: str = "all",    # all | pending | success | cancelled
    owner_type: str = "all",  # all | clinic | pharmacy
    days: int = 30,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    q = select(WalletTransaction, Wallet).join(Wallet, WalletTransaction.wallet_id == Wallet.id)
    if type != "all":
        q = q.where(WalletTransaction.type == type)
    if status != "all":
        q = q.where(WalletTransaction.status == status)
    if owner_type != "all":
        q = q.where(Wallet.owner_type == owner_type)
    if days and days > 0:
        q = q.where(WalletTransaction.created_at >= datetime.now(timezone.utc) - timedelta(days=days))
    q = q.order_by(WalletTransaction.created_at.desc()).limit(500)
    rows = (await db.execute(q)).all()

    items = []
    for tx, w in rows:
        owner_name = None
        if w.owner_type == "clinic":
            r = await db.execute(select(Clinic.name_ru).where(Clinic.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        elif w.owner_type == "pharmacy":
            r = await db.execute(select(PharmacyCompany.name).where(PharmacyCompany.id == w.owner_id))
            owner_name = r.scalar_one_or_none()
        items.append({
            "id": tx.id,
            "owner_type": w.owner_type,
            "owner_id": w.owner_id,
            "owner_name": owner_name,
            "type": tx.type,
            "status": tx.status,
            "amount_usd": float(tx.amount_usd),
            "balance_after_usd": float(tx.balance_after_usd) if tx.balance_after_usd is not None else None,
            "payment_code": tx.payment_code,
            "comment": tx.comment,
            "related_subscription_id": tx.related_subscription_id,
            "created_at": tx.created_at,
            "completed_at": tx.completed_at,
        })

    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/transactions.html",
        _ctx(request, "transactions", {
            "items": items,
            "filter_type": type, "filter_status": status,
            "filter_owner": owner_type, "filter_days": days,
        }, pending_count=pc),
    )


@router.get("/transactions.csv")
async def panel_transactions_csv(
    request: Request,
    type: str = "all",
    status: str = "all",
    owner_type: str = "all",
    days: int = 30,
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    import csv, io
    q = select(WalletTransaction, Wallet).join(Wallet, WalletTransaction.wallet_id == Wallet.id)
    if type != "all":
        q = q.where(WalletTransaction.type == type)
    if status != "all":
        q = q.where(WalletTransaction.status == status)
    if owner_type != "all":
        q = q.where(Wallet.owner_type == owner_type)
    if days and days > 0:
        q = q.where(WalletTransaction.created_at >= datetime.now(timezone.utc) - timedelta(days=days))
    q = q.order_by(WalletTransaction.created_at.desc()).limit(50000)
    rows = (await db.execute(q)).all()

    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow([
        "id", "created_at", "completed_at",
        "owner_type", "owner_id",
        "type", "status",
        "amount_usd", "balance_after_usd",
        "payment_code", "related_subscription_id", "comment",
    ])
    for tx, wallet in rows:
        w.writerow([
            tx.id,
            tx.created_at.isoformat(),
            tx.completed_at.isoformat() if tx.completed_at else "",
            wallet.owner_type, wallet.owner_id,
            tx.type, tx.status,
            float(tx.amount_usd),
            float(tx.balance_after_usd) if tx.balance_after_usd is not None else "",
            tx.payment_code or "",
            tx.related_subscription_id or "",
            (tx.comment or "").replace("\n", " | "),
        ])

    from fastapi.responses import Response
    return Response(
        content=buf.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="transactions_{datetime.now().strftime("%Y%m%d_%H%M")}.csv"'},
    )


@router.post("/transactions/{tx_id}/refund")
async def panel_transaction_refund(
    tx_id: int,
    request: Request,
    reason: str = Form(...),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    try:
        refund_tx = await wallets.refund_purchase(db, tx_id, reason, admin_user_id=admin.id)
    except wallets.WalletError as e:
        return RedirectResponse(
            f"/panel/transactions?error={e.code}",
            status_code=302,
        )
    await log_action(
        db, admin.id,
        action="wallet.refund",
        target_type="wallet_tx",
        target_id=refund_tx.id,
        details=f"refund for tx #{tx_id}; reason: {reason}",
        request=request,
    )
    return RedirectResponse(
        request.headers.get("referer", "/panel/transactions"),
        status_code=302,
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

    # ── Конверсия trial → paid ──
    trial_count = (await db.execute(
        select(func.count(Subscription.id))
        .where(Subscription.is_trial.is_(True))
    )).scalar() or 0
    converted_count = (await db.execute(
        select(func.count(func.distinct(Subscription.owner_id)))
        .where(
            Subscription.is_trial.is_(False),
            Subscription.plan.in_(["pro", "premium"]),
        )
    )).scalar() or 0
    conversion = round(converted_count / trial_count * 100, 1) if trial_count > 0 else 0

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
            "trial_count": trial_count,
            "converted_count": converted_count,
            "conversion_pct": conversion,
            "totals": totals,
        }, pending_count=pc),
    )


# ── Push-рассылки ─────────────────────────────────────────────────────────

@router.get("/broadcasts", response_class=HTMLResponse)
async def panel_broadcasts_list(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    from app.models.broadcast import Broadcast as Bcast
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    items = (await db.execute(
        select(Bcast).order_by(Bcast.created_at.desc()).limit(100)
    )).scalars().all()
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/broadcasts.html",
        _ctx(request, "broadcasts", {"items": items}, pending_count=pc),
    )


@router.get("/broadcasts/new", response_class=HTMLResponse)
async def panel_broadcast_new(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    # Доступные города и планы для выпадашек
    cities_rows = (await db.execute(
        select(User.city, func.count(User.id))
        .where(User.city.isnot(None), User.deleted_at.is_(None))
        .group_by(User.city)
        .order_by(func.count(User.id).desc())
    )).all()
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/broadcast_new.html",
        _ctx(request, "broadcasts", {
            "available_cities": [{"city": c, "count": n} for c, n in cities_rows],
        }, pending_count=pc),
    )


@router.post("/broadcasts/preview")
async def panel_broadcast_preview(
    request: Request,
    roles: list[str] = Form(default=[]),
    plans: list[str] = Form(default=[]),
    cities: list[str] = Form(default=[]),
    registered_after: str = Form(default=""),
    active_since_days: str = Form(default=""),
    db: AsyncSession = Depends(get_db),
):
    from app.services import broadcast_service as bsvc
    admin = await _get_admin(request, db)
    if not admin:
        return {"error": "auth"}
    segment = {}
    if roles: segment["roles"] = roles
    if plans: segment["plans"] = plans
    if cities: segment["cities"] = cities
    if registered_after: segment["registered_after"] = registered_after
    if active_since_days:
        try:
            segment["active_since_days"] = int(active_since_days)
        except ValueError:
            pass
    cnt = await bsvc.preview_segment_count(db, segment)
    return {"count": cnt, "segment": segment}


@router.post("/broadcasts/create")
async def panel_broadcast_create(
    request: Request,
    title: str = Form(...),
    body: str = Form(...),
    image_url: str = Form(default=""),
    action: str = Form(default="draft"),  # "draft" | "send_now"
    roles: list[str] = Form(default=[]),
    plans: list[str] = Form(default=[]),
    cities: list[str] = Form(default=[]),
    registered_after: str = Form(default=""),
    active_since_days: str = Form(default=""),
    db: AsyncSession = Depends(get_db),
):
    from app.models.broadcast import Broadcast as Bcast
    from app.services import broadcast_service as bsvc

    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    segment = {}
    if roles: segment["roles"] = roles
    if plans: segment["plans"] = plans
    if cities: segment["cities"] = cities
    if registered_after: segment["registered_after"] = registered_after
    if active_since_days:
        try:
            segment["active_since_days"] = int(active_since_days)
        except ValueError:
            pass

    bcast = Bcast(
        title=title.strip(),
        body=body.strip(),
        image_url=image_url.strip() or None,
        segment=segment or None,
        status="draft",
        created_by_admin_id=admin.id,
    )
    db.add(bcast)
    await db.flush()

    await log_action(
        db, admin.id,
        action="broadcast.create",
        target_type="broadcast",
        target_id=bcast.id,
        details=f"title: {title}",
        request=request,
    )

    if action == "send_now":
        sent, failed = await bsvc.send_broadcast(db, bcast)
        await log_action(
            db, admin.id,
            action="broadcast.send",
            target_type="broadcast",
            target_id=bcast.id,
            details=f"sent={sent}, failed={failed}",
            request=request,
        )

    return RedirectResponse("/panel/broadcasts", status_code=302)


@router.get("/broadcasts/{bid}", response_class=HTMLResponse)
async def panel_broadcast_detail(
    bid: int, request: Request, db: AsyncSession = Depends(get_db),
):
    from app.models.broadcast import Broadcast as Bcast, BroadcastDelivery as Bd
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    bcast = (await db.execute(select(Bcast).where(Bcast.id == bid))).scalar_one_or_none()
    if not bcast:
        return RedirectResponse("/panel/broadcasts", status_code=302)
    deliveries = (await db.execute(
        select(Bd).where(Bd.broadcast_id == bid).order_by(Bd.created_at.desc()).limit(200)
    )).scalars().all()
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/broadcast_detail.html",
        _ctx(request, "broadcasts", {"bcast": bcast, "deliveries": deliveries}, pending_count=pc),
    )


@router.post("/broadcasts/{bid}/send")
async def panel_broadcast_send(
    bid: int, request: Request, db: AsyncSession = Depends(get_db),
):
    from app.models.broadcast import Broadcast as Bcast
    from app.services import broadcast_service as bsvc
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    bcast = (await db.execute(select(Bcast).where(Bcast.id == bid))).scalar_one_or_none()
    if not bcast or bcast.status not in ("draft", "scheduled", "failed"):
        return RedirectResponse(f"/panel/broadcasts/{bid}", status_code=302)
    sent, failed = await bsvc.send_broadcast(db, bcast)
    await log_action(
        db, admin.id,
        action="broadcast.send",
        target_type="broadcast",
        target_id=bcast.id,
        details=f"sent={sent}, failed={failed}",
        request=request,
    )
    return RedirectResponse(f"/panel/broadcasts/{bid}", status_code=302)


# ── Контент: создание/редактирование статей ──────────────────────────────

@router.get("/articles/new", response_class=HTMLResponse)
async def panel_article_new(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/article_edit.html",
        _ctx(request, "articles", {"article": None}, pending_count=pc),
    )


@router.get("/articles/{article_id}/edit", response_class=HTMLResponse)
async def panel_article_edit_form(
    article_id: int, request: Request, db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    article = (await db.execute(select(Article).where(Article.id == article_id))).scalar_one_or_none()
    if not article:
        return RedirectResponse("/panel/articles", status_code=302)
    pc = await _pending_count(db)
    return templates.TemplateResponse(
        "admin/article_edit.html",
        _ctx(request, "articles", {"article": article}, pending_count=pc),
    )


@router.post("/articles/save")
async def panel_article_save(
    request: Request,
    article_id: str = Form(default=""),
    title_ru: str = Form(...),
    title_kg: str = Form(default=""),
    title_en: str = Form(default=""),
    body_ru: str = Form(default=""),
    body_kg: str = Form(default=""),
    body_en: str = Form(default=""),
    category: str = Form(default="article"),
    image_url: str = Form(default=""),
    is_published: str = Form(default=""),
    db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    if article_id and article_id.isdigit():
        article = (await db.execute(select(Article).where(Article.id == int(article_id)))).scalar_one_or_none()
        if not article:
            return RedirectResponse("/panel/articles", status_code=302)
        action_kind = "update"
    else:
        article = Article()
        db.add(article)
        action_kind = "create"

    article.title_ru = title_ru.strip()
    article.title_kg = title_kg.strip() or None
    article.title_en = title_en.strip() or None
    article.body_ru = body_ru or None
    article.body_kg = body_kg or None
    article.body_en = body_en or None
    article.category = category.strip() or "article"
    article.image_url = image_url.strip() or None
    article.is_published = is_published == "on"

    await db.flush()
    await log_action(
        db, admin.id,
        action=f"article.{action_kind}",
        target_type="article",
        target_id=article.id,
        details=f"title: {title_ru}",
        request=request,
    )
    return RedirectResponse("/panel/articles", status_code=302)


@router.post("/articles/{article_id}/delete")
async def panel_article_delete(
    article_id: int, request: Request, db: AsyncSession = Depends(get_db),
):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()
    article = (await db.execute(select(Article).where(Article.id == article_id))).scalar_one_or_none()
    if article:
        await db.delete(article)
        await log_action(
            db, admin.id,
            action="article.delete",
            target_type="article",
            target_id=article_id,
            request=request,
        )
    return RedirectResponse("/panel/articles", status_code=302)
