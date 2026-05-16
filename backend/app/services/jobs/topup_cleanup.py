"""Авто-отмена pending-заявок на пополнение, висящих дольше TOPUP_PENDING_TTL_DAYS дней."""
import logging
from datetime import datetime, timezone, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.wallet import WalletTransaction
from app.services import wallet_service as wallets

logger = logging.getLogger(__name__)


async def run(db: AsyncSession) -> dict:
    cutoff = datetime.now(timezone.utc) - timedelta(days=settings.TOPUP_PENDING_TTL_DAYS)
    r = await db.execute(
        select(WalletTransaction).where(
            WalletTransaction.type == "topup",
            WalletTransaction.status == "pending",
            WalletTransaction.created_at <= cutoff,
        )
    )
    expired = list(r.scalars().all())
    for tx in expired:
        try:
            await wallets.cancel_topup(
                db,
                tx.id,
                f"Автоматически отменено: не подтверждено за {settings.TOPUP_PENDING_TTL_DAYS} дней",
                admin_user_id=None,
            )
        except wallets.WalletError as e:
            logger.warning("Could not cancel topup %s: %s", tx.id, e.message)
    return {"cancelled": len(expired)}
