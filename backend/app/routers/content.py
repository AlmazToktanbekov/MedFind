from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import List

from app.core.database import get_db
from app.models.article import Article
from app.schemas.content import ArticleOut

router = APIRouter(prefix="/content", tags=["content"])


@router.get("/articles", response_model=List[ArticleOut])
async def get_articles(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Article)
        .where(Article.is_published == True, Article.category == "article")
        .order_by(Article.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return result.scalars().all()


@router.get("/first-aid", response_model=List[ArticleOut])
async def get_first_aid(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Article)
        .where(Article.is_published == True, Article.category == "first_aid")
        .order_by(Article.created_at.desc())
    )
    return result.scalars().all()


@router.get("/health-tips", response_model=List[ArticleOut])
async def get_health_tips(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Article)
        .where(Article.is_published == True, Article.category == "health_tip")
        .order_by(Article.created_at.desc())
    )
    return result.scalars().all()
