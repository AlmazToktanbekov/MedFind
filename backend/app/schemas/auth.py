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


class OTPSendRequest(BaseModel):
    phone: str
    full_name: Optional[str] = None
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"patient", "doctor", "clinic", "pharmacy"}
        if v not in allowed:
            raise ValueError(f"Роль должна быть одной из: {allowed}")
        return v


class OTPSendResponse(BaseModel):
    message: str
    dev_code: Optional[str] = None  # only in DEV_MODE


class OTPVerifyRequest(BaseModel):
    phone: str
    code: str
    full_name: Optional[str] = None
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"patient", "doctor", "clinic", "pharmacy"}
        if v not in allowed:
            raise ValueError(f"Роль должна быть одной из: {allowed}")
        return v


class FCMTokenRequest(BaseModel):
    fcm_token: str


class ForgotPasswordRequest(BaseModel):
    phone: str


class ForgotPasswordResponse(BaseModel):
    message: str
    dev_code: Optional[str] = None  # only in DEV_MODE and only if user exists


class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        if len(v) < 6:
            raise ValueError("Пароль должен быть не короче 6 символов")
        return v
