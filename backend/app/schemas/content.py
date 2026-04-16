from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class ArticleOut(BaseModel):
    id: int
    title_ru: str
    title_kg: Optional[str]
    title_en: Optional[str]
    body_ru: Optional[str]
    body_kg: Optional[str]
    body_en: Optional[str]
    category: Optional[str]
    image_url: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
