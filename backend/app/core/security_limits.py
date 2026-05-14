"""Константы и хелперы для защитных лимитов авторизации/SMS."""
from datetime import datetime, timezone, timedelta
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import OTPCode, User


# ── SMS / OTP ──────────────────────────────────────────────────────────────
SMS_COOLDOWN_SECONDS = 60          # минимальный интервал между SMS на один номер
SMS_MAX_PER_DAY = 5                # максимум SMS в сутки на один номер
OTP_MAX_VERIFY_ATTEMPTS = 5        # сколько раз можно ввести код перед инвалидацией

# ── Login brute-force ─────────────────────────────────────────────────────
LOGIN_MAX_FAILED_ATTEMPTS = 5      # после стольки неудач — блокировка
LOGIN_LOCKOUT_MINUTES = 15         # на сколько блокируем

# ── IP rate limits (для slowapi) ──────────────────────────────────────────
IP_LIMIT_AUTH = "20/minute"        # login/register/refresh
IP_LIMIT_SMS = "10/minute"         # отправка SMS (otp_send / forgot)


async def assert_sms_allowed(db: AsyncSession, phone: str) -> None:
    """Проверить, что для номера можно отправить SMS.

    Бросает HTTPException, если:
    - последняя SMS отправлена меньше SMS_COOLDOWN_SECONDS назад
    - за сутки уже отправлено >= SMS_MAX_PER_DAY кодов
    """
    from fastapi import HTTPException, status

    now = datetime.now(timezone.utc)

    # cooldown
    last = await db.execute(
        select(OTPCode.created_at)
        .where(OTPCode.phone == phone)
        .order_by(OTPCode.created_at.desc())
        .limit(1)
    )
    last_at = last.scalar_one_or_none()
    if last_at is not None:
        delta = (now - last_at).total_seconds()
        if delta < SMS_COOLDOWN_SECONDS:
            wait = int(SMS_COOLDOWN_SECONDS - delta)
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail=f"Подождите {wait} сек перед повторной отправкой кода",
                headers={"Retry-After": str(wait)},
            )

    # дневной лимит
    day_ago = now - timedelta(hours=24)
    cnt_q = await db.execute(
        select(func.count(OTPCode.id)).where(
            OTPCode.phone == phone,
            OTPCode.created_at > day_ago,
        )
    )
    cnt = cnt_q.scalar_one()
    if cnt >= SMS_MAX_PER_DAY:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Превышен дневной лимит отправки кодов. Попробуйте через 24 часа.",
        )


async def invalidate_active_otps(db: AsyncSession, phone: str) -> None:
    """Пометить все активные (не использованные, не истёкшие) коды для номера как использованные.

    Вызывается перед выпуском нового кода — чтобы у юзера всегда был только один валидный.
    """
    now = datetime.now(timezone.utc)
    await db.execute(
        update(OTPCode)
        .where(
            OTPCode.phone == phone,
            OTPCode.is_used == False,  # noqa: E712
            OTPCode.expires_at > now,
        )
        .values(is_used=True)
    )


async def check_user_lockout(user: User) -> None:
    """Бросить 423 LOCKED, если у юзера активная блокировка."""
    from fastapi import HTTPException, status

    if user.locked_until is None:
        return
    now = datetime.now(timezone.utc)
    if user.locked_until > now:
        wait = int((user.locked_until - now).total_seconds())
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail=f"Слишком много неудачных попыток. Попробуйте через {wait // 60 + 1} мин.",
            headers={"Retry-After": str(wait)},
        )


async def register_login_failure(db: AsyncSession, user: User) -> None:
    """Инкрементировать счётчик неудачных логинов; при достижении лимита — заблокировать."""
    user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
    if user.failed_login_attempts >= LOGIN_MAX_FAILED_ATTEMPTS:
        user.locked_until = datetime.now(timezone.utc) + timedelta(minutes=LOGIN_LOCKOUT_MINUTES)
        user.failed_login_attempts = 0
    await db.flush()


async def reset_login_failures(db: AsyncSession, user: User) -> None:
    """Сбросить счётчик при успешном входе."""
    if user.failed_login_attempts or user.locked_until:
        user.failed_login_attempts = 0
        user.locked_until = None
        await db.flush()
