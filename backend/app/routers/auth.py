import random
import secrets
from datetime import datetime, timezone, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
    get_current_user,
)
from app.models.user import User, OTPCode
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshRequest,
    UserOut,
    OTPSendRequest,
    OTPSendResponse,
    OTPVerifyRequest,
    FCMTokenRequest,
    ForgotPasswordRequest,
    ForgotPasswordResponse,
    ResetPasswordRequest,
)
from app.services.sms import send_sms


def _make_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def _token_response(user: User, access_token: str, refresh_token: str) -> TokenResponse:
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_id=user.id,
        role=user.role,
        full_name=user.full_name,
        phone=user.phone,
    )


router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """Регистрация нового пользователя по номеру телефона и паролю."""
    result = await db.execute(select(User).where(User.phone == body.phone))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=400,
            detail="Этот номер телефона уже зарегистрирован",
        )

    refresh = _make_refresh_token()
    user = User(
        phone=body.phone,
        full_name=body.full_name,
        role=body.role,
        password_hash=hash_password(body.password),
        refresh_token=refresh,
    )
    db.add(user)
    await db.flush()

    token = create_access_token({"sub": str(user.id)})
    return _token_response(user, token, refresh)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Вход по номеру телефона и паролю."""
    result = await db.execute(
        select(User).where(User.phone == body.phone, User.is_active == True)
    )
    user = result.scalar_one_or_none()

    if not user or not user.password_hash:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный номер телефона или пароль",
        )
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный номер телефона или пароль",
        )

    refresh = _make_refresh_token()
    user.refresh_token = refresh
    token = create_access_token({"sub": str(user.id)})
    return _token_response(user, token, refresh)


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(body: RefreshRequest, db: AsyncSession = Depends(get_db)):
    """Обновление access токена по refresh токену."""
    result = await db.execute(
        select(User).where(
            User.refresh_token == body.refresh_token,
            User.is_active == True,
        )
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Недействительный refresh токен",
        )

    new_refresh = _make_refresh_token()
    user.refresh_token = new_refresh
    new_token = create_access_token({"sub": str(user.id)})
    return _token_response(user, new_token, new_refresh)


@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Выход — инвалидирует refresh токен."""
    current_user.refresh_token = None
    return {"message": "Выход выполнен успешно"}


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    """Получить данные текущего пользователя."""
    return current_user


class UpdateMeRequest(BaseModel):
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None


@router.patch("/me", response_model=UserOut)
async def update_me(
    body: UpdateMeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Обновить имя и/или аватар текущего пользователя."""
    if body.full_name is not None:
        current_user.full_name = body.full_name.strip() or None
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url or None
    await db.flush()
    return current_user


# ── OTP ───────────────────────────────────────────────────────────────────────

@router.post("/otp/send", response_model=OTPSendResponse)
async def otp_send(body: OTPSendRequest, db: AsyncSession = Depends(get_db)):
    """Отправить OTP-код на номер телефона."""
    code = str(random.randint(100000, 999999))
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)

    otp = OTPCode(phone=body.phone, code=code, expires_at=expires)
    db.add(otp)
    await db.flush()

    await send_sms(body.phone, f"Ваш код подтверждения MedFind: {code}")

    return OTPSendResponse(
        message="Код отправлен",
        dev_code=code if settings.DEV_MODE else None,
    )


@router.post("/otp/verify", response_model=TokenResponse)
async def otp_verify(body: OTPVerifyRequest, db: AsyncSession = Depends(get_db)):
    """Проверить OTP и войти / зарегистрировать пользователя."""
    now = datetime.now(timezone.utc)

    otp_result = await db.execute(
        select(OTPCode).where(
            OTPCode.phone == body.phone,
            OTPCode.code == body.code,
            OTPCode.is_used == False,
            OTPCode.expires_at > now,
        ).order_by(OTPCode.created_at.desc()).limit(1)
    )
    otp = otp_result.scalar_one_or_none()
    if not otp:
        raise HTTPException(status_code=400, detail="Неверный или истёкший код")

    otp.is_used = True

    user_result = await db.execute(select(User).where(User.phone == body.phone))
    user = user_result.scalar_one_or_none()

    refresh = _make_refresh_token()
    if user:
        user.refresh_token = refresh
    else:
        user = User(
            phone=body.phone,
            full_name=body.full_name,
            role=body.role,
            refresh_token=refresh,
        )
        db.add(user)
        await db.flush()

    token = create_access_token({"sub": str(user.id)})
    return _token_response(user, token, refresh)


# ── Восстановление пароля ─────────────────────────────────────────────────────

@router.post("/password/forgot", response_model=ForgotPasswordResponse)
async def password_forgot(
    body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)
):
    """Запросить код для сброса пароля. Код приходит SMS-кой на телефон.

    Из соображений приватности всегда возвращаем одинаковое сообщение,
    независимо от того, существует пользователь или нет (чтобы нельзя было
    через API проверить, зарегистрирован ли номер).
    """
    user_result = await db.execute(select(User).where(User.phone == body.phone))
    user = user_result.scalar_one_or_none()

    dev_code: Optional[str] = None
    if user:
        code = str(random.randint(100000, 999999))
        expires = datetime.now(timezone.utc) + timedelta(
            minutes=settings.OTP_EXPIRE_MINUTES
        )
        otp = OTPCode(phone=body.phone, code=code, expires_at=expires)
        db.add(otp)
        await db.flush()

        await send_sms(
            body.phone,
            f"Код для сброса пароля MedFind: {code}",
        )
        if settings.DEV_MODE:
            dev_code = code

    return ForgotPasswordResponse(
        message="Если номер зарегистрирован, мы отправили код",
        dev_code=dev_code,
    )


@router.post("/password/reset", response_model=TokenResponse)
async def password_reset(
    body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)
):
    """Сбросить пароль по OTP-коду и автоматически войти."""
    now = datetime.now(timezone.utc)

    otp_result = await db.execute(
        select(OTPCode)
        .where(
            OTPCode.phone == body.phone,
            OTPCode.code == body.code,
            OTPCode.is_used == False,
            OTPCode.expires_at > now,
        )
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    otp = otp_result.scalar_one_or_none()
    if not otp:
        raise HTTPException(status_code=400, detail="Неверный или истёкший код")

    user_result = await db.execute(
        select(User).where(User.phone == body.phone, User.is_active == True)
    )
    user = user_result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="Неверный или истёкший код")

    otp.is_used = True
    user.password_hash = hash_password(body.new_password)
    refresh = _make_refresh_token()
    user.refresh_token = refresh
    await db.flush()

    token = create_access_token({"sub": str(user.id)})
    return _token_response(user, token, refresh)


# ── FCM token ─────────────────────────────────────────────────────────────────

@router.post("/fcm-token")
async def save_fcm_token(
    body: FCMTokenRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Сохранить FCM-токен устройства для push-уведомлений."""
    current_user.fcm_token = body.fcm_token
    return {"message": "FCM token saved"}
