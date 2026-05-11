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

    SMS_API_KEY: str = ""
    SMS_SENDER: str = "MedFind"

    GROQ_API_KEY: str = ""

    FIREBASE_PROJECT_ID: str = ""          # Firebase project ID
    FIREBASE_SERVICE_ACCOUNT_PATH: str = ""  # path to serviceAccountKey.json

    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
