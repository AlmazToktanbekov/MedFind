from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


class ReviewCreate(BaseModel):
    rating: float = Field(ge=1, le=5)
    text: Optional[str] = None


class ReviewUpdate(BaseModel):
    rating: Optional[float] = Field(default=None, ge=1, le=5)
    text: Optional[str] = None


class ReviewOut(BaseModel):
    id: int
    author_id: int
    author_name: Optional[str] = None
    author_avatar_url: Optional[str] = None
    rating: float
    text: Optional[str]
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
