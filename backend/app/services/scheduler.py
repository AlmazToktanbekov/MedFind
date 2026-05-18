"""APScheduler — ежедневные фоновые задачи MedFind.

Запускается из lifespan FastAPI приложения (см. app/main.py).
Все задачи стартуют ежедневно в SCHEDULER_HOUR:SCHEDULER_MINUTE по таймзоне SCHEDULER_TIMEZONE.

Список задач:
  • complaints_warning — предупреждение при N жалобах (заглушка)
"""
import logging
from typing import Callable, Awaitable, Optional, Dict

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.services.jobs import complaints_warning

logger = logging.getLogger(__name__)

# Реестр всех задач: имя → корутина job(db: AsyncSession) → dict со статистикой
JOBS: Dict[str, Callable[..., Awaitable[dict]]] = {
    "complaints_warning": complaints_warning.run,
}

_scheduler: Optional[AsyncIOScheduler] = None


async def run_job(name: str) -> dict:
    """Запускает задачу по имени. Создаёт собственную сессию БД, коммитит изменения.

    Используется и cron-триггером, и админом для ручного запуска.
    """
    job_func = JOBS.get(name)
    if job_func is None:
        raise ValueError(f"Unknown job: {name}")

    logger.info("Running job: %s", name)
    async with AsyncSessionLocal() as session:
        try:
            stats = await job_func(session)
            await session.commit()
            logger.info("Job %s done: %s", name, stats)
            return {"job": name, "ok": True, "stats": stats}
        except Exception as exc:
            await session.rollback()
            logger.exception("Job %s failed: %s", name, exc)
            return {"job": name, "ok": False, "error": str(exc)}


def start_scheduler() -> None:
    """Инициализирует и запускает APScheduler. Вызывается при старте FastAPI."""
    global _scheduler
    if not settings.SCHEDULER_ENABLED:
        logger.info("Scheduler disabled (SCHEDULER_ENABLED=false)")
        return
    if _scheduler is not None:
        logger.warning("Scheduler already started")
        return

    _scheduler = AsyncIOScheduler(timezone=settings.SCHEDULER_TIMEZONE)

    trigger = CronTrigger(
        hour=settings.SCHEDULER_HOUR,
        minute=settings.SCHEDULER_MINUTE,
        timezone=settings.SCHEDULER_TIMEZONE,
    )

    for name in JOBS.keys():
        _scheduler.add_job(
            run_job,
            trigger=trigger,
            args=[name],
            id=f"daily_{name}",
            name=f"Daily {name}",
            replace_existing=True,
        )

    _scheduler.start()
    logger.info(
        "Scheduler started: %d jobs daily at %02d:%02d %s",
        len(JOBS),
        settings.SCHEDULER_HOUR,
        settings.SCHEDULER_MINUTE,
        settings.SCHEDULER_TIMEZONE,
    )


def shutdown_scheduler() -> None:
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
        logger.info("Scheduler shut down")
