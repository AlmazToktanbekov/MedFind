"""
SMS-сервис — единая точка отправки SMS.

Сейчас — заглушка: в DEV_MODE логирует код в консоль, в продакшене ничего не делает.
Чтобы подключить реального провайдера (SMS.kg, Nikita.kg и т.д.) — заменить тело
функции `send_sms` на HTTP-запрос к API провайдера. Остальной код приложения не трогать.
"""

import logging

from app.core.config import settings

logger = logging.getLogger(__name__)


async def send_sms(phone: str, text: str) -> bool:
    """
    Отправить SMS на указанный номер.

    Возвращает True если запрос на отправку принят провайдером, иначе False.
    В DEV_MODE — только логирует, реально SMS не отправляет.
    """
    if settings.DEV_MODE:
        logger.info("[SMS DEV] -> %s: %s", phone, text)
        return True

    if not settings.SMS_API_KEY:
        logger.warning(
            "SMS не отправлено: SMS_API_KEY не настроен. phone=%s", phone
        )
        return False

    # TODO: подключить реального провайдера (SMS.kg / Nikita.kg).
    # Пример для SMS.kg:
    #   import httpx
    #   async with httpx.AsyncClient(timeout=10) as client:
    #       resp = await client.post(
    #           "https://smspro.nikita.kg/api/message",
    #           json={
    #               "login": settings.SMS_API_KEY,
    #               "sender": settings.SMS_SENDER,
    #               "phone": phone,
    #               "text": text,
    #           },
    #       )
    #       return resp.status_code == 200
    logger.warning("SMS provider не настроен в коде. phone=%s", phone)
    return False
