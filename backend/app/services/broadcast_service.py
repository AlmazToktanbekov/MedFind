"""Сегментация и отправка push-рассылок.

В DEV-режиме «отправка» создаёт записи Notification (мобайл подхватит).
В проде сюда подключается FCM (см. TODO внутри _send_to_user).
"""
from datetime import datetime, timezone, timedelta
from typing import Optional
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.broadcast import Broadcast, BroadcastDelivery
from app.models.notification import Notification


async def resolve_segment(db: AsyncSession, segment: Optional[dict]) -> list[int]:
    """Возвращает список user_id, удовлетворяющих фильтру."""
    segment = segment or {}
    q = select(User.id).where(
        User.is_active.is_(True),
        User.deleted_at.is_(None),
    )

    roles = segment.get("roles")
    if roles:
        q = q.where(User.role.in_(roles))

    cities = segment.get("cities")
    if cities:
        q = q.where(User.city.in_(cities))

    reg_after = segment.get("registered_after")
    if reg_after:
        try:
            q = q.where(User.created_at >= datetime.fromisoformat(reg_after))
        except Exception:
            pass

    reg_before = segment.get("registered_before")
    if reg_before:
        try:
            q = q.where(User.created_at <= datetime.fromisoformat(reg_before))
        except Exception:
            pass

    active_since_days = segment.get("active_since_days")
    if active_since_days:
        try:
            cutoff = datetime.now(timezone.utc) - timedelta(days=int(active_since_days))
            q = q.where(User.last_active_at >= cutoff)
        except Exception:
            pass

    return list((await db.execute(q)).scalars().all())


async def preview_segment_count(db: AsyncSession, segment: Optional[dict]) -> int:
    return len(await resolve_segment(db, segment))


async def _send_to_user(db: AsyncSession, broadcast: Broadcast, user_id: int) -> BroadcastDelivery:
    """Заглушка реальной отправки. Создаём notification + delivery-лог."""
    db.add(Notification(
        user_id=user_id,
        title=broadcast.title,
        body=broadcast.body,
        type="broadcast",
        data={
            "broadcast_id": broadcast.id,
            "image_url": broadcast.image_url,
        },
    ))
    # TODO: интеграция с FCM здесь
    delivery = BroadcastDelivery(
        broadcast_id=broadcast.id,
        user_id=user_id,
        status="delivered",
    )
    db.add(delivery)
    return delivery


async def send_broadcast(db: AsyncSession, broadcast: Broadcast) -> tuple[int, int]:
    """Отправить рассылку (синхронно, без батчей). Возвращает (sent_count, failed_count)."""
    broadcast.status = "sending"
    await db.flush()

    user_ids = await resolve_segment(db, broadcast.segment)
    sent = 0
    failed = 0
    for uid in user_ids:
        try:
            await _send_to_user(db, broadcast, uid)
            sent += 1
        except Exception:
            db.add(BroadcastDelivery(broadcast_id=broadcast.id, user_id=uid, status="failed"))
            failed += 1

    broadcast.status = "sent"
    broadcast.sent_at = datetime.now(timezone.utc)
    broadcast.sent_count = sent
    broadcast.failed_count = failed
    await db.flush()
    return sent, failed
