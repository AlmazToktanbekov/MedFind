import asyncio
import logging
from functools import lru_cache
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _get_firebase_app():
    import firebase_admin
    from firebase_admin import credentials

    if not settings.FIREBASE_SERVICE_ACCOUNT_PATH:
        return None

    try:
        cred = credentials.Certificate(settings.FIREBASE_SERVICE_ACCOUNT_PATH)
        return firebase_admin.initialize_app(cred)
    except Exception as exc:
        logger.warning("Firebase init failed: %s", exc)
        return None


def _send_sync(token: str, title: str, body: str, data: Optional[dict]) -> None:
    from firebase_admin import messaging

    app = _get_firebase_app()
    if app is None:
        logger.debug("Firebase not configured, skipping push: %s — %s", title, body)
        return

    msg = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        token=token,
    )
    messaging.send(msg)


async def send_push(
    token: Optional[str],
    title: str,
    body: str,
    *,
    notification_type: str,
    data: Optional[dict] = None,
    db: Optional[AsyncSession] = None,
    user_id: Optional[int] = None,
) -> None:
    """Сохраняет уведомление в БД (in-app лента) и отправляет push если есть FCM токен."""
    if db is not None and user_id is not None:
        from app.models.notification import Notification
        db.add(Notification(
            user_id=user_id,
            title=title,
            body=body,
            type=notification_type,
            data=data,
        ))
        await db.flush()

    if token:
        try:
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, _send_sync, token, title, body, data)
        except Exception as exc:
            logger.exception("FCM send failed: %s", exc)
