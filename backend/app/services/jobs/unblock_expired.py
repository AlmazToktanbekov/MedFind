"""Ежедневная авторазблокировка аккаунтов с истёкшим complaint_blocked_until."""
import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User

logger = logging.getLogger(__name__)


async def run(db: AsyncSession) -> dict:
    now = datetime.now(timezone.utc)
    rows = (await db.execute(
        select(User).where(
            User.is_active == False,
            User.complaint_blocked_until.isnot(None),
            User.complaint_blocked_until <= now,
        )
    )).scalars().all()

    unblocked = 0
    for user in rows:
        user.is_active = True
        user.complaint_blocked_until = None
        unblocked += 1

    if unblocked:
        await db.flush()

    logger.info("unblock_expired: unblocked=%d users", unblocked)
    return {"unblocked": unblocked}
