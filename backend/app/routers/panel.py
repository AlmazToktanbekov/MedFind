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
from app.services import wallet_service as wallets
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
    pharmacies = (await db.execute(select(PharmacyCompany).order_by(PharmacyCompany.created_at.desc()))).scalars().all()
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
        entity.status = "active"
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
        entity.status = "rejected"
        await db.commit()

    return RedirectResponse(request.headers.get("referer", "/panel/pending"), status_code=302)


async def _find_entity(entity_type: str, entity_id: int, db: AsyncSession):
    model = {"doctor": Doctor, "clinic": Clinic}.get(entity_type)
    if not model:
        return None
    return (await db.execute(select(model).where(model.id == entity_id))).scalar_one_or_none()


# ── Пользователи ──────────────────────────────────────────────────────────────

@router.get("/users", response_class=HTMLResponse)
async def users_list(request: Request, db: AsyncSession = Depends(get_db)):
    admin = await _get_admin(request, db)
    if not admin:
        return _redirect_login()

    pc = await _pending_count(db)
    users = (await db.execute(select(User).order_by(User.created_at.desc()))).scalars().all()
    return templates.TemplateResponse(
        "admin/users.html",
        _ctx(request, "users", {"users": users}, pc),
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
        await db.commit()
    except wallets.WalletError:
        pass
    return RedirectResponse("/panel/wallet/topups", status_code=302)
