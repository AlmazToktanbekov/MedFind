from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, Field


TargetType = Literal["doctor", "clinic", "pharmacy_branch", "review"]
Reason = Literal["wrong_info", "rude_behavior", "fraud", "spam", "fake", "other"]
Status = Literal["new", "in_review", "resolved", "rejected"]


class ComplaintCreate(BaseModel):
    target_type: TargetType
    target_id: int
    reason: Reason
    comment: Optional[str] = Field(default=None, max_length=2000)


class ComplaintOut(BaseModel):
    id: int
    author_id: int
    target_type: str
    target_id: int
    reason: str
    comment: Optional[str]
    status: str
    resolution_note: Optional[str]
    resolved_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class ComplaintAdminOut(ComplaintOut):
    author_name: Optional[str] = None
    author_phone: Optional[str] = None
    target_title: Optional[str] = None  # имя врача / клиники / адрес филиала


class ComplaintStatusUpdate(BaseModel):
    status: Status
    resolution_note: Optional[str] = Field(default=None, max_length=2000)
