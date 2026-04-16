# MedFind Backend

FastAPI backend для медицинского приложения MedFind (Кыргызстан).

## Быстрый старт

```bash
cd backend

# 1. Создать виртуальное окружение
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Установить зависимости
pip install -r requirements.txt

# 3. Настроить .env
cp .env.example .env
# Отредактируй DATABASE_URL в .env

# 4. Применить миграции
alembic upgrade head

# 5. Заполнить тестовыми данными
python -m app.services.seed

# 6. Запустить сервер
uvicorn app.main:app --reload
```

Документация API: http://localhost:8000/docs

## Структура

```
app/
├── main.py              # FastAPI app + CORS
├── core/
│   ├── config.py        # Настройки из .env
│   ├── database.py      # PostgreSQL async engine
│   └── security.py      # JWT + OTP
├── models/              # SQLAlchemy модели
├── schemas/             # Pydantic схемы
├── routers/             # Роутеры по модулям
│   ├── auth.py          # POST /auth/otp/send, /otp/verify, /login, /register
│   ├── doctors.py       # GET/POST/PUT /doctors
│   ├── clinics.py       # GET/POST/PUT /clinics
│   ├── pharmacies.py    # GET /pharmacies, /pharmacies/nearby
│   ├── search.py        # GET /search?q=
│   ├── reviews.py       # GET/POST /reviews/doctor/{id}
│   ├── content.py       # GET /content/articles|first-aid|health-tips
│   └── admin.py         # GET /admin/pending, PUT/DELETE /admin/approve|reject
└── services/
    └── seed.py          # Тестовые данные
```

## API Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| POST | /auth/otp/send | Отправить OTP на телефон |
| POST | /auth/otp/verify | Проверить OTP |
| POST | /auth/register | Регистрация |
| POST | /auth/login | Вход по OTP |
| GET | /auth/me | Текущий пользователь |
| GET | /doctors | Список врачей |
| GET | /doctors/{id} | Профиль врача |
| GET | /doctors/by-symptom/{id} | Врачи по симптому |
| POST | /doctors | Создать профиль врача |
| PUT | /doctors/{id} | Обновить профиль |
| GET | /clinics | Список клиник |
| GET | /clinics/{id} | Карточка клиники |
| GET | /pharmacies | Список аптек |
| GET | /pharmacies/nearby | Ближайшие аптеки (lat, lng) |
| GET | /search?q= | Полнотекстовый поиск |
| GET | /search/specializations | Все специализации |
| GET | /reviews/doctor/{id} | Отзывы о враче |
| POST | /reviews/doctor/{id} | Оставить отзыв |
| GET | /content/articles | Статьи |
| GET | /content/first-aid | Первая помощь |
| GET | /content/health-tips | Советы по здоровью |
| GET | /admin/pending | Ожидающие модерации |
| PUT | /admin/approve/{type}/{id} | Одобрить |
| DELETE | /admin/reject/{type}/{id} | Отклонить |

## DEV режим

В `.env` установи `DEV_MODE=true` — OTP код будет возвращаться в ответе API (поле `dev_code`), без реальной отправки SMS.

## Статусы провайдеров

- `pending` — на модерации
- `active` — одобрен, виден пользователям
- `rejected` — отклонён
