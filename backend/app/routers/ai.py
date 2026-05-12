from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
import httpx

from app.core.config import settings

router = APIRouter(prefix="/ai", tags=["ai"])

_OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
_OPENROUTER_MODEL = "meta-llama/llama-3.3-70b-instruct:free"

# ─── Системный промпт ──────────────────────────────────────────────────────────

_SYSTEM_PROMPT = """Ты — ИИ-ассистент приложения MedFind (Кыргызстан).
Твоя задача — помочь пользователю разобраться с симптомами и подсказать,
к какому врачу-специалисту обратиться.

Правила:
- Отвечай на том языке, на котором пишет пользователь (русский, кыргызский или английский).
- НЕ ставь диагнозы. В конце каждого ответа напоминай: «Это информационная помощь, не медицинский диагноз. Обратитесь к врачу.»
- Уточняй детали симптомов: где болит, как давно, интенсивность по шкале 1–10, сопутствующие симптомы.
- После уточнения предлагай 2–3 возможные причины (простыми словами) и называй специалистов из списка ниже.
- Отвечай кратко и дружелюбно. Не пиши длинных абзацев.

Доступные специалисты в MedFind:
Терапевт, Кардиолог, Невролог, Гастроэнтеролог, Дерматолог, Хирург, Ортопед,
Офтальмолог, ЛОР, Эндокринолог, Гинеколог, Уролог, Педиатр, Психиатр, Онколог,
Аллерголог, Ревматолог, Пульмонолог, Нефролог, Стоматолог.

Формат ответа когда называешь специалистов:
«К кому обратиться:
• Специалист 1
• Специалист 2»"""

# ─── Схемы ────────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str   # "user" или "assistant"
    text: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

class ChatResponse(BaseModel):
    reply: str

# ─── Endpoint ─────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def ai_chat(body: ChatRequest):
    if not settings.OPENROUTER_API_KEY:
        raise HTTPException(status_code=503, detail="AI сервис не настроен")

    if not body.messages:
        raise HTTPException(status_code=422, detail="messages не может быть пустым")

    messages = [{"role": "system", "content": _SYSTEM_PROMPT}]
    for msg in body.messages:
        role = "assistant" if msg.role in ("model", "assistant") else "user"
        messages.append({"role": role, "content": msg.text})

    payload = {
        "model": _OPENROUTER_MODEL,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 1024,
    }

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                _OPENROUTER_URL,
                headers={"Authorization": f"Bearer {settings.OPENROUTER_API_KEY}"},
                json=payload,
            )

        if response.status_code != 200:
            raise HTTPException(status_code=502, detail=f"Ошибка AI: {response.text}")

        data = response.json()
        reply = data["choices"][0]["message"]["content"]
        return ChatResponse(reply=reply)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Ошибка AI: {str(e)}")
