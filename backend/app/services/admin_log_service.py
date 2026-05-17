"""Сервис логирования действий администраторов.

Использование:
    from app.services.admin_log_service import log_action
    await log_action(db, admin_id=admin.id, action="doctor.approve",
                     target_type="doctor", target_id=doctor.id,
                     details="status pending -> active", request=request)

Запись фиксируется в общей транзакции (commit делает вызывающий код).
"""
from typing import Optional
from fastapi import Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin_log import AdminLog


def _client_ip(request: Optional[Request]) -> Optional[str]:
    if request is None:
        return None
    # X-Forwarded-For имеет приоритет (если есть прокси)
    xff = request.headers.get("x-forwarded-for")
    if xff:
        return xff.split(",")[0].strip()
    return request.client.host if request.client else None


async def log_action(
    db: AsyncSession,
    *,
    admin_id: int,
    action: str,
    target_type: Optional[str] = None,
    target_id: Optional[int] = None,
    details: Optional[str] = None,
    request: Optional[Request] = None,
) -> AdminLog:
    entry = AdminLog(
        admin_user_id=admin_id,
        action=action,
        target_type=target_type,
        target_id=target_id,
        details=details,
        ip_address=_client_ip(request),
    )
    db.add(entry)
    await db.flush()
    return entry
