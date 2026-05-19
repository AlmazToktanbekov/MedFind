import json
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import httpx

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete as sa_delete

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.ai_conversation import AiConversation

router = APIRouter(prefix="/ai", tags=["ai"])

_MISTRAL_URL = "https://api.mistral.ai/v1/chat/completions"
_MISTRAL_MODEL = "mistral-small-latest"

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
    role: str
    text: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

class ChatResponse(BaseModel):
    reply: str

class ConversationOut(BaseModel):
    id: int
    title: str
    messages: List[ChatMessage]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class SaveConversationRequest(BaseModel):
    title: str
    messages: List[ChatMessage]

# ─── Chat endpoint ─────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse)
async def ai_chat(body: ChatRequest):
    if not settings.MISTRAL_API_KEY:
        raise HTTPException(status_code=503, detail="AI сервис не настроен")

    if not body.messages:
        raise HTTPException(status_code=422, detail="messages не может быть пустым")

    messages = [{"role": "system", "content": _SYSTEM_PROMPT}]
    for msg in body.messages:
        role = "assistant" if msg.role in ("model", "assistant") else "user"
        messages.append({"role": role, "content": msg.text})

    payload = {
        "model": _MISTRAL_MODEL,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 1024,
    }

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                _MISTRAL_URL,
                headers={"Authorization": f"Bearer {settings.MISTRAL_API_KEY}"},
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

# ─── History endpoints ──────────────────────────────────────────────────────────

@router.get("/history", response_model=List[ConversationOut])
async def get_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AiConversation)
        .where(AiConversation.user_id == current_user.id)
        .order_by(AiConversation.updated_at.desc())
        .limit(20)
    )
    conversations = result.scalars().all()
    return [_to_out(c) for c in conversations]


@router.post("/history", response_model=ConversationOut, status_code=201)
async def save_conversation(
    body: SaveConversationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not body.messages:
        raise HTTPException(status_code=422, detail="messages не может быть пустым")

    now = datetime.now(timezone.utc)
    conv = AiConversation(
        user_id=current_user.id,
        title=body.title[:100],
        messages_json=json.dumps([m.dict() for m in body.messages], ensure_ascii=False),
        created_at=now,
        updated_at=now,
    )
    db.add(conv)
    await db.flush()

    # Keep only last 20 conversations per user
    old_ids_result = await db.execute(
        select(AiConversation.id)
        .where(AiConversation.user_id == current_user.id)
        .order_by(AiConversation.updated_at.desc())
        .offset(20)
    )
    old_ids = [row[0] for row in old_ids_result.fetchall()]
    if old_ids:
        await db.execute(
            sa_delete(AiConversation).where(AiConversation.id.in_(old_ids))
        )

    await db.commit()
    await db.refresh(conv)
    return _to_out(conv)


@router.delete("/history/{conversation_id}", status_code=204)
async def delete_conversation(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AiConversation).where(
            AiConversation.id == conversation_id,
            AiConversation.user_id == current_user.id,
        )
    )
    conv = result.scalar_one_or_none()
    if not conv:
        raise HTTPException(status_code=404, detail="Диалог не найден")
    await db.delete(conv)
    await db.commit()


@router.delete("/history", status_code=204)
async def clear_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await db.execute(
        sa_delete(AiConversation).where(AiConversation.user_id == current_user.id)
    )
    await db.commit()


def _to_out(conv: AiConversation) -> ConversationOut:
    messages = [ChatMessage(**m) for m in json.loads(conv.messages_json)]
    return ConversationOut(
        id=conv.id,
        title=conv.title,
        messages=messages,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
    )
