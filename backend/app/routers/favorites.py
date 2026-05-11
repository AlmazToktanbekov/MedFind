from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List
from pydantic import BaseModel
from datetime import datetime

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.favorite import Favorite

router = APIRouter(prefix="/favorites", tags=["favorites"])

VALID_TYPES = {"doctor", "clinic", "pharmacy"}


class FavoriteOut(BaseModel):
    id: int
    entity_type: str
    entity_id: int
    created_at: datetime

    class Config:
        from_attributes = True


@router.get("", response_model=List[FavoriteOut])
async def get_favorites(
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Favorite)
        .where(Favorite.user_id == current_user.id)
        .order_by(Favorite.created_at.desc())
    )
    return result.scalars().all()


@router.post("/{entity_type}/{entity_id}", response_model=FavoriteOut, status_code=201)
async def add_favorite(
    entity_type: str,
    entity_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if entity_type not in VALID_TYPES:
        raise HTTPException(status_code=422, detail=f"entity_type must be one of {VALID_TYPES}")

    existing = await db.execute(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.entity_type == entity_type,
            Favorite.entity_id == entity_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Already in favorites")

    fav = Favorite(user_id=current_user.id, entity_type=entity_type, entity_id=entity_id)
    db.add(fav)
    await db.flush()
    await db.refresh(fav)
    return fav


@router.delete("/{entity_type}/{entity_id}", status_code=204)
async def remove_favorite(
    entity_type: str,
    entity_id: int,
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Favorite).where(
            Favorite.user_id == current_user.id,
            Favorite.entity_type == entity_type,
            Favorite.entity_id == entity_id,
        )
    )
    fav = result.scalar_one_or_none()
    if not fav:
        raise HTTPException(status_code=404, detail="Not in favorites")
    await db.delete(fav)
    await db.flush()
