from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.core.config import settings
from app.routers import auth, doctors, clinics, pharmacies, search, reviews, content, admin
from app.routers import upload, panel, ai

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="MedFind — медицинское приложение Кыргызстана",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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


_uploads_dir = Path("uploads")
_uploads_dir.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(_uploads_dir)), name="uploads")


@app.get("/", tags=["health"])
async def root():
    return {"status": "ok", "app": settings.APP_NAME, "version": "1.0.0"}


@app.get("/health", tags=["health"])
async def health():
    return {"status": "healthy"}
