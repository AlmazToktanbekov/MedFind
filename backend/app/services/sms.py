"""
SMS-сервис — отправка SMS через Nikita.kg API.

Документация провайдера: https://smspro.nikita.kg (раздел «API-ИНТЕГРАЦИЯ» в кабинете).
В DEV_MODE — реальную SMS не шлёт, только логирует в консоль.
"""

import logging
import secrets
import re

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

NIKITA_API_URL = "https://smspro.nikita.kg/api/message"


def _normalize_phone(phone: str) -> str:
    """Приводит номер к формату Nikita.kg: 996XXXXXXXXX (12 цифр, без '+')."""
    digits = re.sub(r"\D", "", phone)
    if digits.startswith("0") and len(digits) == 10:
        digits = "996" + digits[1:]
    elif not digits.startswith("996"):
        digits = "996" + digits
    return digits


def _build_xml(login: str, password: str, sender: str, phone: str, text: str) -> str:
    """Формирует XML-запрос для Nikita.kg API."""
    msg_id = secrets.token_hex(8)
    safe_text = (
        text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    )
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        "<message>"
        f"<login>{login}</login>"
        f"<pwd>{password}</pwd>"
        f"<id>{msg_id}</id>"
        f"<sender>{sender}</sender>"
        f"<text>{safe_text}</text>"
        "<phones>"
        f"<phone>{phone}</phone>"
        "</phones>"
        "</message>"
    )


async def send_sms(phone: str, text: str) -> bool:
    """
    Отправить SMS на указанный номер через Nikita.kg.

    В DEV_MODE — только логирует, реально SMS не отправляется.
    В прод-режиме — шлёт XML-запрос в Nikita API. Возвращает True если
    провайдер принял сообщение, False при ошибке.
    """
    if settings.DEV_MODE:
        logger.info("[SMS DEV] -> %s: %s", phone, text)
        return True

    if not settings.SMS_LOGIN or not settings.SMS_PASSWORD:
        logger.warning(
            "SMS не отправлено: SMS_LOGIN / SMS_PASSWORD не настроены в .env. phone=%s",
            phone,
        )
        return False

    normalized = _normalize_phone(phone)
    xml_body = _build_xml(
        login=settings.SMS_LOGIN,
        password=settings.SMS_PASSWORD,
        sender=settings.SMS_SENDER,
        phone=normalized,
        text=text,
    )

    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.post(
                NIKITA_API_URL,
                content=xml_body,
                headers={"Content-Type": "application/xml; charset=utf-8"},
            )
        if resp.status_code != 200:
            logger.error(
                "Nikita.kg вернул HTTP %s: %s", resp.status_code, resp.text[:300]
            )
            return False

        body = resp.text
        # Успех: <status>0</status> (или <result>... <status>0</status>)
        if "<status>0</status>" in body:
            logger.info("SMS отправлена на %s", normalized)
            return True

        logger.error("Nikita.kg отклонил отправку: %s", body[:500])
        return False
    except httpx.HTTPError as e:
        logger.exception("Ошибка HTTP при отправке SMS на %s: %s", normalized, e)
        return False
