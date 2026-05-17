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

    # Подписки и тарифы
    CLINIC_FREE_DOCTOR_LIMIT: int = 4
    PHARMACY_FREE_BRANCH_LIMIT: int = 9
    TRIAL_DAYS: int = 30
    PLAN_PRO_PRICE_USD: int = 20
    PLAN_PREMIUM_PRICE_USD: int = 40
    PLAN_YEAR_DISCOUNT_MONTHS: int = 2   # 2 месяца в подарок при годовой оплате
    USD_TO_KGS_RATE: float = 89.0        # курс для отображения в кабинете
    PREMIUM_REPORTS_RETENTION_DAYS: int = 30  # доступ к отчётам после отмены Premium

    # ─── Кошелёк / личный счёт ───────────────────────────────────────────
    # Реквизиты MedFind для переводов клиник/аптек (хардкод сейчас, в админку — потом)
    COMPANY_NAME: str = "ОсОО MedFind"
    COMPANY_INN: str = "—"
    BANK_NAME: str = "Mbank"
    BANK_ACCOUNT: str = "—"
    BANK_BIK: str = "—"
    SUPPORT_PHONE: str = "+996700000000"

    # Лимиты пополнения (USD)
    WALLET_MIN_TOPUP_USD: int = 10
    WALLET_MAX_TOPUP_USD: int = 1000
    # Срок жизни pending-заявки в днях (потом автоотмена — Этап 4 cron)
    WALLET_TOPUP_REQUEST_TTL_DAYS: int = 7

    # Стратегия подтверждения пополнений:
    # "auto"       — мгновенное автоподтверждение в момент создания заявки
    #                (для MVP / демо; в проде заменяется реальным платёжным шлюзом)
    # "manual"     — админ подтверждает в админке
    # "mbank_auto" — webhook от Mbank Business API + матчинг по payment_code
    WALLET_CONFIRM_STRATEGY: str = "auto"
    MBANK_WEBHOOK_SECRET: str = ""

    # ─── Scheduler (APScheduler, ежедневно в 09:00) ──────────────────────
    SCHEDULER_ENABLED: bool = True
    SCHEDULER_HOUR: int = 9    # час запуска ежедневных задач
    SCHEDULER_MINUTE: int = 0
    SCHEDULER_TIMEZONE: str = "Asia/Bishkek"

    # Напоминания о подписке (за сколько дней до окончания слать push)
    SUBSCRIPTION_REMINDER_DAYS: List[int] = [7, 3, 1]
    # Срок жизни pending-заявки на пополнение (потом автоотмена)
    TOPUP_PENDING_TTL_DAYS: int = 7
    # Порог жалоб для авто-предупреждения клиники
    COMPLAINTS_WARNING_THRESHOLD: int = 100
    COMPLAINTS_WINDOW_DAYS: int = 10

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
