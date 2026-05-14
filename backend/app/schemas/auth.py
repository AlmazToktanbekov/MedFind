from pydantic import BaseModel, Field, field_validator
from typing import Optional


_ALLOWED_ROLES = {"patient", "doctor", "clinic", "pharmacy"}


class RegisterRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    password: str = Field(min_length=6, max_length=128)
    full_name: str = Field(min_length=1, max_length=120)
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in _ALLOWED_ROLES:
            raise ValueError(f"Роль должна быть одной из: {_ALLOWED_ROLES}")
        return v


class LoginRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    password: str = Field(min_length=1, max_length=128)


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: int
    role: str
    full_name: Optional[str] = None
    phone: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=20, max_length=256)


class UserOut(BaseModel):
    id: int
    phone: str
    full_name: Optional[str]
    role: str
    avatar_url: Optional[str]

    class Config:
        from_attributes = True


class OTPSendRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    full_name: Optional[str] = Field(default=None, max_length=120)
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in _ALLOWED_ROLES:
            raise ValueError(f"Роль должна быть одной из: {_ALLOWED_ROLES}")
        return v


class OTPSendResponse(BaseModel):
    message: str
    dev_code: Optional[str] = None  # only in DEV_MODE


class OTPVerifyRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    code: str = Field(min_length=4, max_length=10)
    full_name: Optional[str] = Field(default=None, max_length=120)
    role: str = "patient"

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        if v not in _ALLOWED_ROLES:
            raise ValueError(f"Роль должна быть одной из: {_ALLOWED_ROLES}")
        return v


class FCMTokenRequest(BaseModel):
    fcm_token: str = Field(min_length=10, max_length=512)


class ForgotPasswordRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)


class ForgotPasswordResponse(BaseModel):
    message: str
    dev_code: Optional[str] = None  # only in DEV_MODE and only if user exists


class ResetPasswordRequest(BaseModel):
    phone: str = Field(min_length=10, max_length=20)
    code: str = Field(min_length=4, max_length=10)
    new_password: str = Field(min_length=6, max_length=128)
