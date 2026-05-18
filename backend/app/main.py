from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from contextlib import asynccontextmanager

from app.core.config import settings
from app.core.rate_limit import limiter
from app.routers import auth, doctors, clinics, pharmacies, search, reviews, content, admin
from app.routers import upload, panel, ai, symptoms, favorites, notifications, complaints, analytics
from app.services import scheduler as _scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: запуск APScheduler (ежедневные cron-задачи)
    _scheduler.start_scheduler()
    yield
    # Shutdown
    _scheduler.shutdown_scheduler()


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="MedFind — медицинское приложение Кыргызстана",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# ── Rate limiting (slowapi) ──────────────────────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)


# ── Security headers ─────────────────────────────────────────────────────────
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response: Response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
        if not settings.DEV_MODE:
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
        return response


app.add_middleware(SecurityHeadersMiddleware)


# ── CORS ─────────────────────────────────────────────────────────────────────
# В DEV режиме разрешаем все origins для удобства; в проде — только белый список из .env.
_cors_origins = settings.BACKEND_CORS_ORIGINS
if settings.DEV_MODE and _cors_origins == ["*"]:
    _cors_kwargs = {"allow_origins": ["*"], "allow_credentials": False}
else:
    # allow_credentials=True несовместимо с allow_origins=["*"] — поэтому при
    # whitelist'е доменов включаем credentials.
    _cors_kwargs = {"allow_origins": _cors_origins, "allow_credentials": True}

app.add_middleware(
    CORSMiddleware,
    allow_methods=["*"],
    allow_headers=["*"],
    **_cors_kwargs,
)


app.include_router(auth.router)
app.include_router(upload.router)
app.include_router(doctors.router)
app.include_router(clinics.router)
app.include_router(pharmacies.router)
app.include_router(search.router)
app.include_router(reviews.router)
app.include_router(content.router)
app.include_router(admin.router)
app.include_router(panel.router)
app.include_router(ai.router)
app.include_router(symptoms.router)
app.include_router(favorites.router)
app.include_router(notifications.router)
app.include_router(complaints.router)
app.include_router(analytics.router)


_uploads_dir = Path("uploads")
_uploads_dir.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(_uploads_dir)), name="uploads")


@app.get("/", tags=["health"])
async def root():
    return {"status": "ok", "app": settings.APP_NAME, "version": "1.0.0"}


@app.get("/health", tags=["health"])
async def health():
    return {"status": "healthy"}
