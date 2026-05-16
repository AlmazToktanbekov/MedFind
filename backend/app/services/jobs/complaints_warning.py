"""Авто-предупреждение клиник/аптек при превышении порога жалоб.

⚠️ TODO: требует наличия таблицы `complaints` (фича жалоб пока не реализована).
Когда фича появится — реализовать логику:
  1. SELECT target_type, target_id, COUNT(*)
     FROM complaints
     WHERE created_at >= NOW() - INTERVAL 'COMPLAINTS_WINDOW_DAYS days'
     GROUP BY target_type, target_id
     HAVING COUNT(*) >= COMPLAINTS_WARNING_THRESHOLD
  2. Для каждой такой клиники/аптеки отправить push владельцу + админу
"""
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.config import settings

logger = logging.getLogger(__name__)


async def run(db: AsyncSession) -> dict:
    # Заглушка: фича жалоб ещё не реализована
    logger.info(
        "complaints_warning: skipped (complaints feature not implemented; "
        "threshold=%d in %d days)",
        settings.COMPLAINTS_WARNING_THRESHOLD,
        settings.COMPLAINTS_WINDOW_DAYS,
    )
    return {"warned": 0, "status": "not_implemented"}
