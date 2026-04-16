import secrets
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
    get_current_user,
)
from app.models.user import User
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshRequest,
    UserOut,
)


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
