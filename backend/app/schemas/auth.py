from pydantic import BaseModel, field_validator
from typing import Optional


class RegisterRequest(BaseModel):
    phone: str
    password: str
    full_name: str
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"patient", "doctor", "clinic", "pharmacy"}
        if v not in allowed:
            raise ValueError(f"Роль должна быть одной из: {allowed}")
        return v


class LoginRequest(BaseModel):
    phone: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: int
    role: str
    full_name: Optional[str] = None
    phone: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: int
    phone: str
    full_name: Optional[str]
    role: str
    avatar_url: Optional[str]

    class Config:
        from_attributes = True
