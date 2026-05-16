"""Pytest fixtures для MedFind backend tests.

Стратегия:
- Используется отдельная PostgreSQL база `medfind_test` (создаётся вручную, см. README ниже).
- Перед сессией тестов: создаются все таблицы через SQLAlchemy metadata.create_all.
- После сессии: drop_all.
- На каждый тест — отдельная сессия с откатом транзакции в конце (изоляция).

Запуск:
    cd backend
    source .venv/bin/activate
    pytest tests/ -v
"""
import os
import pytest
import pytest_asyncio

# Тестовая БД должна быть отдельной — НЕ боевой
TEST_DATABASE_URL = "postgresql+asyncpg://medfind_user:medfind2024@localhost:5432/medfind_test"
os.environ["DATABASE_URL"] = TEST_DATABASE_URL

from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.pool import NullPool

from app.core.database import Base
import app.models  # noqa: F401 — регистрация всех моделей в metadata


@pytest_asyncio.fixture
async def test_engine():
    """Создаём engine на тест с NullPool (без шеринга connections между тестами).
    Перед тестом — пересоздаём схему, после — drop_all."""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        echo=False,
        future=True,
        poolclass=NullPool,
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture
async def db(test_engine) -> AsyncSession:
    """Сессия БД для одного теста."""
    SessionLocal = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with SessionLocal() as session:
        yield session
        await session.rollback()


# ─── Factories ────────────────────────────────────────────────────────────

@pytest_asyncio.fixture
async def make_user(db):
    """Фабрика пользователей."""
    from app.models.user import User
    from app.core.security import hash_password

    counter = {"n": 0}

    async def _factory(role: str = "patient", phone: str = None, password: str = "test1234"):
        counter["n"] += 1
        if phone is None:
            phone = f"+99670000000{counter['n']:02d}"
        user = User(
            phone=phone,
            role=role,
            full_name=f"Test {role} {counter['n']}",
            password_hash=hash_password(password),
        )
        db.add(user)
        await db.flush()
        return user

    return _factory


@pytest_asyncio.fixture
async def make_clinic(db, make_user):
    """Фабрика клиник."""
    from app.models.clinic import Clinic

    counter = {"n": 0}

    async def _factory(user=None, name: str = None):
        counter["n"] += 1
        if user is None:
            user = await make_user(role="clinic")
        clinic = Clinic(
            user_id=user.id,
            name_ru=name or f"Test Clinic {counter['n']}",
            status="active",
        )
        db.add(clinic)
        await db.flush()
        return clinic

    return _factory


@pytest_asyncio.fixture
async def make_doctor(db, make_user, make_clinic):
    """Фабрика врачей со статусом 'active' по умолчанию."""
    from app.models.doctor import Doctor

    counter = {"n": 0}

    async def _factory(clinic=None, status: str = "active"):
        counter["n"] += 1
        if clinic is None:
            clinic = await make_clinic()
        user = await make_user(role="doctor")
        doctor = Doctor(
            user_id=user.id,
            clinic_id=clinic.id,
            full_name_ru=f"Doc {counter['n']}",
            specialization_ru="Терапевт",
            status=status,
        )
        db.add(doctor)
        await db.flush()
        return doctor

    return _factory


@pytest_asyncio.fixture
async def make_pharmacy(db, make_user):
    """Фабрика аптечных компаний."""
    from app.models.pharmacy import PharmacyCompany

    counter = {"n": 0}

    async def _factory(user=None, name: str = None):
        counter["n"] += 1
        if user is None:
            user = await make_user(role="pharmacy")
        pharmacy = PharmacyCompany(
            user_id=user.id,
            name=name or f"Test Pharmacy {counter['n']}",
        )
        db.add(pharmacy)
        await db.flush()
        return pharmacy

    return _factory
