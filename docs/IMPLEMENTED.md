# MedFind — Реализованный функционал

> Последнее обновление: апрель 2026

---

## Обзор

MedFind — медицинское приложение Кыргызстана, соединяющее пациентов с врачами, клиниками и аптеками. Состоит из трёх частей:

- **Backend** — FastAPI + PostgreSQL (async SQLAlchemy)
- **Mobile** — Flutter (iOS / Android)
- **Admin Panel** — веб-интерфейс на Jinja2, встроен в backend

---

## Backend (FastAPI)

### Аутентификация (`/auth`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| POST | `/auth/register` | Регистрация (телефон + пароль) |
| POST | `/auth/login` | Вход |
| POST | `/auth/refresh` | Обновление access-токена |
| POST | `/auth/logout` | Выход (инвалидация refresh-токена) |
| GET | `/auth/me` | Данные текущего пользователя |

- Хеширование паролей через bcrypt
- JWT: access (15 мин) + refresh токены
- `DEV_MODE`: OTP-код возвращается в теле ответа без реальной отправки SMS

### Врачи (`/doctors`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/doctors` | Список активных врачей (фильтр: специализация, онлайн) |
| GET | `/doctors/{id}` | Детальный профиль (контакты, услуги, расписание) |
| GET | `/doctors/my` | Профиль текущего врача |
| GET | `/doctors/by-symptom/{symptom_id}` | Врачи по симптому |
| POST | `/doctors` | Создать профиль врача |
| PUT | `/doctors/{id}` | Обновить профиль |

### Клиники (`/clinics`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/clinics` | Список активных клиник (фильтр: категория) |
| GET | `/clinics/{id}` | Детали клиники |
| GET | `/clinics/my` | Профиль текущей клиники |
| POST | `/clinics` | Создать клинику |
| PUT | `/clinics/{id}` | Обновить клинику |

### Аптеки (`/pharmacies`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/pharmacies` | Список активных аптек |
| GET | `/pharmacies/{id}` | Детали аптеки |
| GET | `/pharmacies/my` | Профиль текущей аптеки |
| GET | `/pharmacies/nearby` | Ближайшие аптеки по координатам (формула Хаверсина) |
| POST | `/pharmacies` | Создать аптеку |
| PUT | `/pharmacies/{id}` | Обновить аптеку |

### Отзывы (`/reviews`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/reviews/doctor/{id}` | Отзывы о враче |
| POST | `/reviews/doctor/{id}` | Оставить отзыв (автоматически пересчитывает рейтинг) |

### Поиск (`/search`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/search?q=` | Единый поиск по врачам, клиникам, аптекам, специализациям |
| GET | `/search/specializations` | Список всех специализаций (27) |
| GET | `/search/categories` | Список категорий клиник (25) |

### Контент (`/content`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/content/articles` | Опубликованные статьи |
| GET | `/content/first-aid` | Статьи "Первая помощь" |
| GET | `/content/health-tips` | Советы по здоровью |

### AI-чат (`/ai`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| POST | `/ai/chat` | AI-ассистент по симптомам (Groq API, модель Llama 3.3) |

- Мультиязычный системный промпт (RU/KY/EN)
- Задаёт уточняющие вопросы о симптомах
- Рекомендует профильных специалистов

### Загрузка файлов (`/upload`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| POST | `/upload/photo` | Загрузка изображения → сохраняет в `uploads/`, возвращает URL |

### Admin API (`/admin`)

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/admin/pending` | Все провайдеры на модерации |
| PUT | `/admin/approve/{type}/{id}` | Одобрить провайдера |
| DELETE | `/admin/reject/{type}/{id}` | Отклонить провайдера |

---

### Модели базы данных

| Модель | Ключевые поля |
|--------|--------------|
| **User** | phone (unique), full_name, role (patient/doctor/clinic/pharmacy/admin), password_hash, refresh_token |
| **Doctor** | full_name (ru/kg/en), specialization, bio, photo_url, experience_years, has_online/offline, online/offline_price, rating, reviews_count, status |
| **DoctorContact** | phone, whatsapp, telegram, instagram, email |
| **DoctorService** | name (ru/kg/en), price, duration_min |
| **DoctorSchedule** | day_of_week, start_time, end_time, is_working |
| **Clinic** | name/description (ru/kg/en), category, address, latitude/longitude, phone, website, rating, status |
| **Pharmacy** | name/address (ru/kg/en), phone, latitude/longitude, is_open_24h, working_hours_ru, status |
| **Review** | author_id, doctor_id / clinic_id, rating (1–5), text |
| **Article** | title/body (ru/kg/en), category (article/first_aid/health_tip), image_url, is_published |
| **Favorite** | user_id, entity_type, entity_id |
| **Symptom** | name_ru/kg/en, icon |
| **SymptomSpecialization** | symptom_id → specialization |

Статусы провайдеров: `pending → active | rejected`

---

### Веб-панель администратора (`/panel`)

Jinja2-шаблоны, аутентификация через cookie + JWT.

- **Dashboard** — статистика (всего врачей/клиник/аптек, в ожидании)
- **Врачи** — список с фильтрацией по статусу, детальная страница
- **Клиники** — список с фильтрацией
- **Аптеки** — список с фильтрацией
- **Модерация** — очередь на одобрение/отклонение
- **Пользователи** — список всех пользователей
- **Статьи** — управление контентом, публикация/снятие с публикации

---

## Flutter Mobile App

### Экраны и флоу

#### Аутентификация
| Экран | Описание |
|-------|----------|
| SplashScreen | Заставка при запуске |
| OnboardingScreen | Карусель онбординга |
| LoginScreen | Вход (телефон + пароль) |
| RegisterScreen | Выбор роли (пациент/врач/клиника/аптека) |
| RegisterFormScreen | Форма регистрации по роли |
| OtpScreen | Верификация OTP (dev-mode показывает код) |

#### Главное приложение (Bottom Navigation — 4 таба)

**Home (Главная)**
- Шапка с приветствием, аватаром и кнопкой уведомлений
- Быстрые кнопки: Врачи / Клиники / Аптеки / Поиск
- Баннер AI-ассистента
- Поиск врача по симптому (8 симптом-чипов)
- Карусель специализаций (10 шт.)
- Горизонтальный список врачей (топ-6 по рейтингу)
- Горизонтальный список клиник (топ-6 по рейтингу)
- Список аптек (топ-3)

**Search (Поиск)**
- Поисковая строка
- История поисковых запросов (с кнопкой очистки)
- Единые результаты: врачи, клиники, аптеки
- Счётчики результатов по категориям
- Пустые состояния и обработка ошибок

**Health (Здоровье)**
- Статьи, Первая помощь, Советы по здоровью
- Фильтрация по категориям
- Только опубликованный контент

**Profile (Профиль)**
- Аватар с инициалами, имя и телефон
- Секция "Избранные врачи" с бейджем
- История поиска
- Выбор языка (RU / KY / EN)
- Кнопка выхода

#### Отдельные экраны

| Экран | Описание |
|-------|----------|
| DoctorsScreen | Список врачей, фильтры (Все/Онлайн/Клиника), пагинация, избранное |
| DoctorDetailScreen | Полный профиль: контакты, услуги, расписание, отзывы, рейтинг |
| ClinicsScreen | Список клиник с фильтром по категории |
| ClinicDetailScreen | Детали клиники, карта, контакты |
| PharmaciesScreen | Список аптек, индикатор 24ч |
| PharmacyDetailScreen | Детали аптеки, адрес и часы работы |
| FavoritesScreen | Сохранённые врачи пользователя |
| AiChatScreen | AI-ассистент по симптомам |
| SearchScreen | Поиск с историей |

#### Экраны настройки провайдера

| Экран | Описание |
|-------|----------|
| DoctorSetupScreen | Регистрация как врач (имя, специализация, контакты, услуги, расписание) |
| ClinicSetupScreen | Регистрация как клиника (название, категория, адрес, координаты, контакты) |
| PharmacySetupScreen | Регистрация как аптека (название, адрес, часы, флаг 24ч) |
| PendingReviewScreen | Статус "на модерации" после подачи заявки |

---

### AI-чат (экран)

- История сообщений с временными метками
- Кнопки быстрых подсказок
- Индикатор печати
- Обработка ошибок
- Кнопки "Новый чат" и загрузка истории
- Предыдущие беседы

---

### Роутинг (GoRouter)

```
/splash
/onboarding
/login
/register               ← выбор роли
/register/form?role=    ← форма регистрации
/otp
/main                   ← главный экран (bottom nav)
  /main/doctors
  /main/doctors/:id
  /main/clinics
  /main/clinics/:id
  /main/pharmacies
  /main/pharmacies/:id
  /main/search
  /main/favorites
  /main/ai-chat
  /main/health
  /main/profile
/provider/setup              ← настройка профиля врача
/provider/pending
/provider/clinic-setup
/provider/pending-clinic
/provider/pharmacy-setup
/provider/pending-pharmacy
```

---

### Стейт-менеджмент (Riverpod)

| Провайдер | Отвечает за |
|-----------|-------------|
| `authProvider` | Аутентификация: вход/регистрация/выход |
| `profileProvider` | Данные профиля текущего пользователя |
| `doctorsProvider` | Список врачей + фильтрация |
| `clinicsProvider` | Список клиник + категория |
| `pharmaciesProvider` | Список аптек |
| `searchProvider` | Поиск + история запросов |
| `aiChatProvider` | Сообщения AI-чата |
| `aiHistoryProvider` | История бесед с AI |
| `favoritesProvider` | Локальное хранилище избранного |
| `localeProvider` | Выбор языка приложения |

Используется классический Riverpod (`StateNotifierProvider`).

---

### Общие компоненты (`shared/widgets/`)

| Компонент | Описание |
|-----------|----------|
| `DoctorCard` | Карточка врача с рейтингом и ценой |
| `ClinicCard` | Карточка клиники |
| `PharmacyCard` | Карточка аптеки |
| `FilterChipWidget` | Активный/неактивный фильтр-чип |
| `GradientButton` | Кнопка с градиентом |
| `CustomSearchBar` | Поисковое поле с иконкой |
| `AppBottomNavBar` | Нижняя навигация (4 таба) |
| `RatingStars` | Звёздный рейтинг |

---

### Хранилище на устройстве

| Хранилище | Данные |
|-----------|--------|
| `FlutterSecureStorage` | `access_token`, `refresh_token`, `full_name`, `user_phone` |
| `SharedPreferences` | Избранное (`"doctor:123"`, `"clinic:456"`), выбранная локаль (`app_locale`) |

Избранное хранится **локально** и не синхронизируется с сервером.

---

## Технический стек

| Слой | Технологии |
|------|------------|
| Backend | FastAPI, SQLAlchemy (async), asyncpg, PostgreSQL, Alembic, Pydantic v2, bcrypt, PyJWT, Jinja2, Groq API |
| Mobile | Flutter, Riverpod, GoRouter, Dio, flutter_secure_storage, shared_preferences, phosphor_flutter |
| AI | Groq API, модель Llama 3.3-70b |

---

## Локализация

- **3 языка**: Русский (RU), Кыргызский (KY), Английский (EN)
- Backend: мультиязычные поля для врачей, клиник, аптек, статей (`name_ru`, `name_kg`, `name_en`)
- Mobile: переключатель языка в профиле, locale-провайдер через Riverpod
- `.arb`-файлы ещё не созданы — строки пока хардкодятся
