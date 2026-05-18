from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    APP_NAME: str = "MedFind"

    DATABASE_URL: str = "postgresql+asyncpg://postgres:password@localhost:5432/medfind"
    SYNC_DATABASE_URL: str = "postgresql://postgres:password@localhost:5432/medfind"

    SECRET_KEY: str = "dev-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    OTP_EXPIRE_MINUTES: int = 5
    DEV_MODE: bool = True  # returns OTP in response

    S3_BUCKET_NAME: str = "medfind-media"
    S3_REGION: str = "us-east-1"
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""

    # Nikita.kg SMS gateway
    SMS_LOGIN: str = ""            # логин личного кабинета Nikita.kg
    SMS_PASSWORD: str = ""         # пароль API/SMPP (НЕ от кабинета — отдельный)
    SMS_SENDER: str = "SMSPRO.KG"  # одобренное имя отправителя
    SMS_API_KEY: str = ""          # резерв (для других провайдеров)

    GROQ_API_KEY: str = ""
    OPENROUTER_API_KEY: str = ""
    MISTRAL_API_KEY: str = ""

    FIREBASE_PROJECT_ID: str = ""          # Firebase project ID
    FIREBASE_SERVICE_ACCOUNT_PATH: str = ""  # path to serviceAccountKey.json

    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    # ─── Scheduler (APScheduler, ежедневно в 09:00) ──────────────────────
    SCHEDULER_ENABLED: bool = True
    SCHEDULER_HOUR: int = 9
    SCHEDULER_MINUTE: int = 0
    SCHEDULER_TIMEZONE: str = "Asia/Bishkek"

    # Жалобы: порог первого уведомления, второго, блокировки + длина блока в днях
    COMPLAINT_NOTIFY_1: int = 10
    COMPLAINT_NOTIFY_2: int = 100
    COMPLAINT_BLOCK_AT: int = 300
    COMPLAINT_BLOCK_DAYS: int = 14

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
