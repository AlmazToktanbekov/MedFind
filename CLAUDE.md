# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

MedFind — медицинское приложение Кыргызстана. Соединяет пациентов с врачами, клиниками и аптеками.

---

## КОМАНДЫ

```bash
# Flutter (запускать из mobile/)
flutter run
flutter build apk
flutter test                                       # все тесты
flutter test test/widget_test.dart                # один тест
flutter gen-l10n                                   # генерация локализации из .arb

# Кодогенерация (freezed) — после изменений @freezed-моделей
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch    # режим watch при активной разработке

# FastAPI (запускать из backend/)
cp .env.example .env           # первый запуск: скопировать конфиг
uvicorn app.main:app --reload
alembic upgrade head           # применить миграции
alembic revision --autogenerate -m "описание"   # создать миграцию
python -m app.services.seed    # заполнить тестовыми данными
pytest                         # все тесты бэкенда
```

API документация: http://localhost:8000/docs
Веб-панель администратора: http://localhost:8000/panel

---

## АРХИТЕКТУРА FLUTTER

Flutter-приложение находится в `mobile/` (не `frontend/`).

### Слои фичи

Каждая фича в `mobile/lib/features/<name>/` делится на три слоя:
- `data/` — Repository: делает HTTP-запросы через `ApiClient().dio`, возвращает модели
- `providers/` — StateNotifierProvider: содержит бизнес-логику и состояние
- `presentation/screens/` — виджеты, читают провайдеры через `ref.watch`/`ref.read`

Папка `domain/` существует в некоторых фичах, но в текущей кодовой базе не используется.

**Фичи (12):** `ai`, `analytics`, `auth`, `clinics`, `doctors`, `health`, `home`, `notifications`, `pharmacies`, `profile`, `provider`, `search`.

### Riverpod

Используется **классический Riverpod** (`StateNotifierProvider`, `Provider`), **не** новый `@riverpod` / `riverpod_generator`. Новые провайдеры писать через `StateNotifierProvider`.

### Сеть (`mobile/lib/core/network/api_client.dart`)

`ApiClient` — **настоящий singleton** (приватный конструктор `_internal()` + factory), не создаётся заново. Использовать как `ApiClient().dio`.

- `baseUrl` = `AppConstants.baseUrl` (`http://localhost:8000`)
- JWT-интерцептор: читает `access_token` из `flutter_secure_storage`, добавляет `Authorization: Bearer`
- **Автообновление токена**: при 401 запускает очередь рефреша через `/auth/refresh`, повторяет исходный запрос с новым токеном; при неудаче вызывает `ApiClient.onUnauthorized`
- `PrettyDioLogger` включён по умолчанию

### Роутинг (`mobile/lib/core/router/app_router.dart`)

GoRouter, начальный маршрут `/splash`.

**Верхнеуровневые маршруты:**

| Путь | Экран |
|------|-------|
| `/splash` | SplashScreen |
| `/onboarding` | OnboardingScreen |
| `/login` | LoginScreen |
| `/register` | RegisterScreen (выбор роли) |
| `/register/form` | RegisterFormScreen |
| `/forgot-password` | ForgotPasswordScreen |
| `/reset-password` | ResetPasswordScreen (extra: `{phone, devCode?}`) |
| `/otp` | OtpScreen (extra: `{phone, devCode?}`) |
| `/main` | MainScreen (bottom nav: Home / Search / Health / Profile) |

**Вложенные маршруты под `/main`** (открываются поверх MainScreen):

| Путь | Экран |
|------|-------|
| `/main/doctors` | DoctorsScreen |
| `/main/doctors/by-symptom/:symptomId` | врачи по симптому |
| `/main/doctors/by-specialization` | врачи по специализации |
| `/main/doctors/:id` | DoctorDetailScreen |
| `/main/clinics`, `/main/clinics/:id` | ClinicsScreen / ClinicDetailScreen |
| `/main/pharmacies` | PharmaciesScreen |
| `/main/pharmacies/branch/:id` | PharmacyBranchScreen |
| `/main/pharmacies/company/:id` | PharmacyCompanyScreen |
| `/main/search`, `/main/favorites` | SearchScreen / FavoritesScreen |
| `/main/notifications` | NotificationsScreen |
| `/main/edit-profile` | EditProfileScreen |
| `/main/ai-chat` | AiChatScreen |
| `/main/specializations`, `/main/symptoms` | списки |
| `/main/health/first-aid/:id` | FirstAidDetailScreen |

**Кабинеты провайдеров:**

| Путь | Экран |
|------|-------|
| `/provider/setup` | DoctorSetupScreen (регистрация врача) |
| `/provider/doctor-edit` | DoctorEditScreen |
| `/provider/pending` | PendingReviewScreen (врач) |
| `/provider/clinic-intro`, `/provider/clinic-setup`, `/provider/clinic-created`, `/provider/pending-clinic` | регистрация клиники |
| `/clinic/:id/edit`, `/clinic/:id/photos`, `/clinic/:id/doctors`, `/clinic/:id/doctor-requests` | кабинет клиники |
| `/clinic/analytics` | ClinicAnalyticsScreen |
| `/provider/pharmacy-setup`, `/provider/pharmacy/manage`, `/provider/pending-pharmacy` | регистрация/кабинет аптеки |
| `/provider/pharmacy/edit`, `/provider/pharmacy/branch/add`, `/provider/pharmacy/branch/:id/edit`, `/pharmacy/branch/:id/photos` | управление филиалами |
| `/pharmacy/analytics` | PharmacyBranchAnalyticsScreen |

`MainScreen` использует `IndexedStack` с 4 табами: HomeScreen, SearchScreen, HealthScreen, ProfileScreen.

### Общие компоненты

- `shared/models/` — `doctor_model`, `clinic_model`, `pharmacy_model`, `symptom_model` (с `fromJson`)
- `shared/providers/` — `current_user_provider`, `favorites_provider`
- `shared/widgets/` — `GradientButton`, `DoctorCard`, `FilterChipWidget`, `RatingStars`, `CustomSearchBar`, `AppBottomNavBar` (`bottom_nav_bar.dart`), `ReviewCard`, `ReportDialog`
- `core/constants/app_constants.dart` — `baseUrl`, канонические списки `symptoms`, `specializations`, `clinicCategories`
- `core/services/notification_service.dart` — локальные/push-уведомления
- `core/analytics/` — клиент трекинга событий аналитики

### Локализация

3 языка (RU, KY, EN); код Kyrgyz — `ky` (не `kg`). Файлы `app_ru.arb`, `app_ky.arb`, `app_en.arb` в `mobile/lib/l10n/`, `flutter_localizations` подключён, `generate: true`. Сгенерированные `app_localizations*.dart` коммитятся. Новые строки добавлять во все три `.arb` и запускать `flutter gen-l10n`.

### Хранилище на устройстве

- **`FlutterSecureStorage`** — токены (`access_token`, `refresh_token`), данные профиля (`full_name`, `user_phone`)
- **`SharedPreferences`** — выбранная локаль (`app_locale`), локальный кэш

**Избранное синхронизируется с бэкендом** через роутер `/favorites` — не хранится только локально.

---

## АРХИТЕКТУРА BACKEND

Backend находится в `backend/`.

### Паттерны

- **Async SQLAlchemy** с `asyncpg`; сессия через `Depends(get_db)` в каждом роутере
- **Eager loading** через `selectinload` для связанных сущностей
- Pydantic-схемы в `app/schemas/` (отдельные файлы: `auth`, `clinic`, `doctor`, `pharmacy`, `review`, `complaint`, `search`); раздельно для чтения (`DoctorOut`, `DoctorListItem`) и записи (`DoctorCreate`, `DoctorUpdate`)
- Модели в `app/models/`
- Все роутеры подключены в `app/main.py` через `include_router`
- Настройки в `app/core/config.py` (pydantic-settings, читает из `.env`)

### Роутеры (`app/routers/`) — 15 шт.

| Роутер | Назначение |
|--------|-----------|
| `auth` | регистрация, логин, refresh, OTP, восстановление пароля, `/auth/me`, `/auth/fcm-token` |
| `doctors` | каталог врачей, профиль, заявки в клинику, заявки на изменение профиля |
| `clinics` | каталог клиник, кабинет клиники, управление врачами и заявками |
| `pharmacies` | компании и филиалы аптек, `nearby` (Haversine), галереи фото |
| `reviews` | отзывы на врачей / клиники / филиалы аптек |
| `search` | глобальный поиск, списки специализаций и категорий |
| `symptoms` | каталог симптомов, маппинг симптом → специализации |
| `favorites` | избранное (синхронизация с бэкендом) |
| `ai` | AI-ассистент (Mistral): чат + серверная история диалогов |
| `notifications` | список уведомлений, счётчик непрочитанных, отметка прочитанным |
| `complaints` | жалобы на врачей / клиники / филиалы |
| `analytics` | трекинг событий + отчёты для клиник и аптек |
| `admin` | служебные эндпоинты (jobs, статистика жалоб, тест-push) |
| `upload` | загрузка фото в локальную папку `uploads/` |
| `panel` | веб-панель администратора (Jinja2 + cookie JWT) |

### Ключевые эндпоинты

**auth:** `POST /auth/register|login|refresh|logout`, `GET|PATCH /auth/me`, `POST /auth/otp/send|verify`, `POST /auth/password/forgot|reset`, `POST /auth/fcm-token`

**doctors:** `GET /doctors`, `/doctors/{id}`, `/doctors/my`, `/doctors/by-symptom/{id}`; `POST /doctors`, `/doctors/apply-clinic`, `/doctors/my/request-update`; `PUT|DELETE /doctors/{id}`; `DELETE /doctors/my/pending-update`

**clinics:** `GET|PUT /clinics/my`, `GET /clinics`, `/clinics/{id}`, `/clinics/{id}/doctors`, `/clinics/{id}/doctor-requests`, `/clinics/{id}/doctor-update-requests`; `POST /clinics/{id}/approve-doctor|reject-doctor|deactivate-doctor|activate-doctor|approve-update|reject-update`; `DELETE /clinics/{id}/remove-doctor/{doctorId}`

**pharmacies:** `POST /pharmacy/register`, `GET /pharmacy-companies[/my|/{id}]`, `GET /pharmacy-branches[/nearby|/{id}]`, CRUD филиалов и фото

**ai:** `POST /ai/chat`, `GET|POST|DELETE /ai/history[/{id}]`

**analytics:** `POST /analytics/track`, `GET /analytics/clinic/me`, `GET /analytics/pharmacy/branch/{id}`

**notifications:** `GET /notifications`, `/notifications/unread-count`, `PATCH /notifications/{id}/read`, `/notifications/read-all`, `DELETE`

**complaints:** `POST /complaints`, `GET /complaints/mine`

### Веб-панель администратора (`panel`)

Доступна по `/panel/*`, рендерит Jinja2-шаблоны из `app/templates/admin/`, аутентификация через cookie с JWT-токеном (не Bearer). Разделы: дашборд, врачи, клиники, аптеки, пользователи (+ история), отзывы и жалобы, аналитика платформы, логи админов. Управления статьями нет — раздел «Первая помощь» встроен в мобильное приложение (`first_aid_data.dart`), через панель не управляется.

### Модели (`app/models/`)

`user`, `doctor`, `clinic`, `pharmacy`, `review`, `symptom`, `favorite`, `complaint`, `notification`, `analytics`, `ai_conversation`, `search_log`, `admin_log`.

### Сервисы (`app/services/`)

- `sms.py` — единая точка отправки SMS (`send_sms`)
- `fcm.py` — push-уведомления через Firebase Admin SDK (`send_push`)
- `scheduler.py` + `jobs/` — APScheduler: `complaints_warning.py`, `unblock_expired.py`
- `analytics_service.py` — агрегация метрик для отчётов
- `admin_log_service.py` — запись действий админов
- `seed.py` — тестовые данные

### AI-ассистент

Чат на **Mistral AI** (`MISTRAL_API_KEY` в `.env`). История диалогов хранится на сервере (таблица `ai_conversations`), эндпоинты `/ai/*`. Mobile: фича `ai`, экран `/main/ai-chat`.

### DEV_MODE

В `.env` / `app/core/config.py`: `DEV_MODE=true` — OTP-код возвращается в теле ответа (поле `dev_code`) без реальной отправки SMS. Flutter отображает его на экране OTP.

### SMS-сервис

Единая точка отправки SMS — `app/services/sms.py`, функция `send_sms(phone, text)`. В DEV_MODE — заглушка, логирует код в консоль. Для подключения провайдера (SMS.kg / Nikita.kg) — заменить тело функции на HTTP-запрос; остальной код приложения не трогать. Используется в `/auth/otp/send` и `/auth/password/forgot`.

### Восстановление пароля

- `POST /auth/password/forgot` — принимает `{phone}`, отправляет OTP через `send_sms`. Из соображений приватности всегда возвращает одинаковое сообщение (`dev_code` — только если юзер существует и `DEV_MODE=true`).
- `POST /auth/password/reset` — принимает `{phone, code, new_password}` (мин. 6 символов), валидирует OTP, обновляет `password_hash`, ротирует `refresh_token`, возвращает `TokenResponse` (автологин).

### Статусы провайдеров

**Клиника** — регистрируется и сразу активна, без модерации админом.

**Аптечная компания** — регистрируется и сразу активна, без модерации админом.

**Врач** — 5 статусов:
- `pending` — подал заявку в клинику, ждёт подтверждения
- `active` — клиника подтвердила, виден пациентам
- `rejected` — клиника отклонила заявку
- `deactivated` — клиника временно деактивировала
- `removed` — клиника удалила врача; врач НЕ виден пациентам, в кабинете показывается красная плашка с кнопкой выбора новой клиники

Только врачи со статусом `active` отдаются в публичных эндпоинтах.

### Модерация изменений профиля врача

Активный врач не редактирует профиль напрямую: `POST /doctors/my/request-update` создаёт заявку на изменение, клиника одобряет (`/clinics/{id}/approve-update/{updateId}`) или отклоняет (`/reject-update`). Отменить свою заявку — `DELETE /doctors/my/pending-update`.

---

## ДИЗАЙН-СИСТЕМА

### Цвета (`mobile/lib/core/theme/app_colors.dart`)

```
primaryBlue:     #1565C0   — кнопки, активные элементы
primaryDark:     #0D47A1   — тёмный конец градиента
accentBlue:      #2979FF   — иконки, теги
backgroundApp:   #F0F4FF   — фон экранов
backgroundCard:  #FFFFFF   — белые карточки
textPrimary:     #0D1B3E
textSecondary:   #6B7A99
success:         #00C897
warning:         #FF8C42
error:           #E53935

heroGradient: LinearGradient(#0D47A1 → #1565C0 → #42A5F5)
btnGradient:  LinearGradient(#1565C0 → #2979FF)
cardShadow:   BoxShadow(color: #1A1565C0, blurRadius: 20, offset: Offset(0, 8))
```

### Типографика

Шрифт **Inter** (google_fonts).

| Стиль | Размер | Вес |
|-------|--------|-----|
| headingLarge | 28px | w700 |
| headingMedium | 22px | w600 |
| bodyLarge | 16px | w400 |
| bodySmall | 13px | w400 |
| labelBold | 14px | w600 |

### UI-компоненты

- **Карточки**: белый фон + `cardShadow`, `borderRadius` 16–20px, `padding: 16px`
- **Кнопка Primary**: `btnGradient`, `borderRadius: 14px`, высота `54px`, Inter 16px Bold White
- **Кнопка Outlined**: `border: 1.5px solid #1565C0`, `borderRadius: 14px`
- **Bottom Nav**: белый, `borderRadius: 24px` (верхние углы), высота `72px`; активная вкладка — синяя иконка + синяя точка снизу
- **Поле поиска**: фон `#EEF2FF`, `borderRadius: 14px`, высота `52px`, без border
- **Фильтр-чип активный**: фон `primaryBlue`, текст белый, `borderRadius: 20px`
- **Фильтр-чип неактивный**: фон `#EEF2FF`, текст `primaryBlue`

### Анимации

- Переходы страниц: FadeTransition + SlideTransition (снизу), 300ms, `Curves.easeInOut`
- Hero-анимация фото: `Hero(tag: 'doctor_${doctor.id}', ...)`
- Список карточек: staggered, задержка 50ms на карточку, fade + slide
- Кнопки: ScaleTransition при нажатии (scale: 0.95)

### Иконки

Пакет `phosphor_flutter`, стиль **Outline**.

### Графики

Аналитика и отчёты — через `fl_chart`.

---

## ПРАВИЛА

- **Дизайн**: строго следуй дизайн-системе — никаких отклонений от палитры, радиусов, теней
- **Архитектура**: логика только в repository/provider, не в виджетах
- **Deeplinks**: WhatsApp → `https://wa.me/<номер>`, Telegram → `https://t.me/<username>`, звонок → `tel:<номер>` через `url_launcher`
- **Локализация**: 3 языка (RU, KY, EN); код Kyrgyz — `ky`. Новые строки — во все три `.arb`, затем `flutter gen-l10n`
- **Кодогенерация**: при добавлении `@freezed` аннотаций запускать `build_runner`
- **Канонические списки**: симптомы, специализации, категории клиник — в `app_constants.dart` (mobile) и в БД (`symptom` table) — не дублировать в других местах

---

## СОГЛАСОВАННАЯ БИЗНЕС-ЛОГИКА

Этот раздел фиксирует все принятые проектные решения. При реализации строго следовать этим договорённостям.

---

### АПТЕКИ

#### Структура данных
Аптека = одна компания + список филиалов (две отдельные таблицы).

**pharmacy_companies** — главный профиль компании:
- `id`, `user_id`, `name`, `logo`, `main_phone`, `website`, `description`, `created_at`

**pharmacy_branches** — каждый филиал компании:
- `id`, `company_id`, `address`, `latitude`, `longitude`
- `phone`, `working_hours`, `is_active`, `created_at`
- фото — **галерея** (несколько фото на филиал, отдельная таблица `pharmacy_branch_photos`)

#### Регистрация аптеки
- Аптека регистрируется **сама через приложение** (роль `pharmacy`)
- После регистрации **сразу активна**, модерация админом не нужна
- Пошаговая форма:
  1. Данные компании (название, логотип, главный номер, сайт)
  2. Первый филиал (адрес, телефон, фото, график)
- Из личного кабинета можно добавлять новые филиалы

#### Личный кабинет аптеки (для владельца)
- Просмотр и редактирование профиля компании
- Список своих филиалов с возможностью добавить / редактировать / деактивировать

#### Публичный профиль аптечной компании (для пациента)
- Логотип, название, главный номер, сайт, описание
- Раздел «Филиалы» — список всех активных филиалов

#### Карточка филиала (для пациента)
- Название сети (компании)
- Адрес, телефон, график работы
- Галерея фото
- Расстояние до пользователя (если геолокация разрешена)
- Кнопка **«Позвонить»** → `tel:<номер>` через `url_launcher`
- Кнопка **«Маршрут»** → открывает 2GIS (приоритет) или Google Maps

#### Геолокация
- Разрешение запрашивается **при первом входе в раздел аптек** ИЛИ при нажатии «Ближайшие аптеки»
- Если пользователь уже дал разрешение — повторно не спрашивать
- Логика ближайших: `GET /pharmacy-branches/nearby?lat=...&lon=...` → сортировка по расстоянию (формула Haversine на бэкенде)

#### Отзывы для аптек
- Отзывы оставляются на **каждый филиал отдельно** (не на компанию)
- В таблице `reviews`: `target_type = "pharmacy_branch"`, `target_id = branch_id`

---

### КЛИНИКИ

#### Структура
- Одна клиника = одна карточка, один аккаунт (роль `clinic`)
- Регистрируется сама через приложение, **сразу активна**

#### Пошаговая регистрация клиники (3 шага)
- Шаг 1: название (required), телефон (required), описание, сайт, направления/категории multi-select (required), логотип
- Шаг 2: адрес (required), координаты lat/lon, график работы, WhatsApp, Telegram, Instagram, email
- Шаг 3: фото клиники

Категории хранятся как строка, разделённая «, » (`category_ru`). Координаты — `latitude`, `longitude` (float). Логотип — `logo_url`.

#### Публичный профиль клиники
- Все данные + список подтверждённых врачей, сгруппированных по специализации
- Кнопка маршрута → 2GIS (приоритет) или Google Maps
- Раздел отзывов

#### Личный кабинет клиники (разделы)
1. О клинике (просмотр + редактирование)
2. Контакты
3. Фото
4. Врачи (список активных врачей по специализациям)
5. Управление врачами (заявки: ожидают / активны / отклонены / деактивированы)
6. Отзывы

#### Управление врачами
Клиника может:
- **Подтвердить** врача (статус → `active`)
- **Отклонить** врача (статус → `rejected`)
- **Деактивировать** активного врача (статус → `deactivated`)
- **Активировать** деактивированного врача (статус → `active`)
- **Удалить** врача из клиники (статус → `removed`)
- **Одобрить / отклонить** заявку врача на изменение профиля

Перед подтверждением клиника видит: ФИО, фото, телефон, специализацию, образование, стаж, услуги, контакты, график. Причина отказа — **не обязательна**.

---

### ВРАЧИ

#### Структура
- Врач привязан к **одной клинике** (не нескольким)
- Не виден пациентам, пока клиника не подтвердит

#### Обязательные поля регистрации
- ФИО, номер телефона, специализация, образование, стаж
- Формат консультации: очный / онлайн / оба + цены
- Услуги (название + цена)
- Контакты: рабочий телефон, WhatsApp, Telegram, Instagram
- График приёма
- Фото
- Выбор клиники

#### Адрес врача
- **Не вводится вручную** — автоматически берётся из выбранной клиники

#### Онлайн-консультация
- Только через **WhatsApp** или **Telegram** (не видеозвонок внутри приложения)
- Ссылки через `url_launcher`: `https://wa.me/<номер>` / `https://t.me/<username>`

#### Пошаговая регистрация врача (7 шагов + экран ожидания)
1. Основная информация (фото, ФИО, телефон)
2. Специализация + формат консультации + цены
3. Образование и стаж
4. Услуги (название + цена)
5. Контакты (WhatsApp, Telegram, Instagram)
6. График приёма — адрес берётся автоматически из клиники
7. Выбор клиники → отправка заявки
→ Экран ожидания подтверждения (PendingReviewScreen)

#### Статусы врача
`pending`, `active`, `rejected`, `deactivated`, `removed` (см. раздел «Статусы провайдеров»).

**При статусе `removed`:** в кабинете врача красная плашка:
> «⚠️ Вас не видят пациенты — вы не привязаны к клинике. Выберите новую клинику.»
Кнопка ведёт на шаг выбора клиники.

#### Изменение профиля
Активный врач отправляет заявку на изменение, клиника одобряет/отклоняет (см. «Модерация изменений профиля врача»).

#### Push-уведомления врачу
- Клиника подтвердила → «Клиника [название] подтвердила ваш профиль»
- Клиника отклонила → «Клиника [название] отклонила вашу заявку»
- Клиника деактивировала → «Ваш профиль деактивирован клиникой [название]»

#### Публичный профиль врача
- Фото, ФИО, специализация, образование, стаж, опыт, язык консультации
- Формат консультации + цены, услуги
- Контакты (кнопки WhatsApp, Telegram, звонок)
- График приёма, рейтинг + отзывы
- Блок **«✅ Подтверждён клиникой: [Название]»** — кнопка ведёт в профиль клиники

---

### РОЛИ ПОЛЬЗОВАТЕЛЕЙ

| Роль | Значение в БД | Описание |
|------|--------------|---------|
| Пациент | `patient` | Основной пользователь |
| Врач | `doctor` | Регистрируется через приложение |
| Клиника | `clinic` | Управляет своими врачами |
| Аптека | `pharmacy` | Управляет компанией и филиалами |
| Администратор | `admin` | Управляет платформой |

---

### КАРТЫ И НАВИГАЦИЯ

Приоритет при нажатии «Маршрут»:
1. **2GIS** — `dgis://2gis.ru/routeSearch/to/<lat>,<lon>`
2. **Google Maps** — `https://maps.google.com/?q=<lat>,<lon>` (если 2GIS не установлен)

Реализация: `url_launcher` с проверкой `canLaunchUrl` для 2GIS, fallback на Google Maps.

---

### АНАЛИТИКА И ОТЧЁТЫ

Раздел **«Отчёты»** доступен клиникам и аптекам. Отображается только внутри приложения (без PDF/email на старте).

**Период:** кастомный диапазон дат. По умолчанию — последние 30 дней.

#### Метрики отчёта клиники
Просмотры профиля клиники и каждого врача; звонки; переходы в WhatsApp / Telegram; нажатия «Маршрут»; добавления в избранное; средний рейтинг и число отзывов; топ популярных врачей; график активности по дням.

#### Метрики отчёта аптеки
Только по каждому филиалу отдельно (селектор филиала наверху): просмотры филиала, звонки, WhatsApp, маршрут, избранное, рейтинг.

#### Техническая реализация
- Таблица `analytics_events` (event_type, target_type, target_id, clinic_id, user_id?, metadata, created_at)
- Mobile отправляет события через `POST /analytics/track` (fire-and-forget)
- События: `view_clinic`, `view_doctor`, `view_pharmacy_branch`, `click_call`, `click_whatsapp`, `click_telegram`, `click_route`, `add_favorite`, `search`
- Backend: `GET /analytics/clinic/me`, `GET /analytics/pharmacy/branch/{id}`
- Этический фильтр: НЕЛЬЗЯ показывать имена/телефоны пациентов — только агрегированные цифры
- Графики в Flutter через `fl_chart`

---

### АДМИН-ПАНЕЛЬ

Доступна по `/panel`, аутентификация cookie + JWT. На старте — **1 super-admin** (основатель). Уровень вмешательства — минимум: модерация и блокировка, **без редактирования** профилей клиник и врачей. Администратор не является разрешительным звеном: клиники и аптеки активны сразу после регистрации, врачей подтверждают клиники, админ подключается реактивно (по жалобам). Мобильное приложение работает независимо от панели. Финансовых разделов нет — приложение бесплатное.

#### Разделы
1. **Дашборд** — регистрации (всего / сегодня / неделя / месяц), разбивка по ролям, DAU/WAU/MAU, размер каталога, счётчики ожидающих подтверждения врачей и новых жалоб.
2. **Пользователи** — список с фильтрами по роли и статусу, поиск, карточка + история действий; блокировка/разблокировка, сброс пароля.
3. **Врачи** — список по статусам и специализациям, карточка профиля; принудительная смена статуса и заморозка — только при жалобах, без редактирования профиля.
4. **Клиники** — список, карточка с составом врачей и отзывами; заморозка/разморозка с указанием причины.
5. **Аптеки** — аптечные компании и их филиалы; заморозка/разморозка компании.
6. **Отзывы и жалобы** — жалобы (приоритетная вкладка, агрегаты по объектам с порогами 10/100/300), отзывы (удаление недопустимых с указанием причины).
7. **Аналитика платформы** — регистрации по дням/ролям, DAU/WAU/MAU, топ поисковых запросов (из `search_logs`), запросы без результатов, агрегаты событий (`analytics_events`).
8. **Журнал действий админов** — аудит всех действий, не удаляется.
9. **Служебные функции** — статус и ручной запуск регламентных задач (`complaints_warning`, `unblock_expired`), тестовая отправка push.

Управления статьями в панели нет: «Первая помощь» — встроенный в приложение фиксированный справочник неотложных ситуаций.

#### Авто-уведомления от админки (cron, ежедневно 09:00)

Job `complaints_warning` агрегирует ВСЕ жалобы по каждой цели (врач / клиника / филиал аптеки) и при достижении порогов шлёт push (FCM) + in-app владельцу и админам:
- ≥ 10 жалоб (`COMPLAINT_NOTIFY_1`) — «На вас поступили жалобы»
- ≥ 100 жалоб (`COMPLAINT_NOTIFY_2`) — «Критически много жалоб»
- ≥ 300 жалоб (`COMPLAINT_BLOCK_AT`) — автоблокировка на `COMPLAINT_BLOCK_DAYS` (по умолч. 14) дней

Job `unblock_expired` снимает блокировку по истечении срока. Дедупликация: повторное уведомление одного типа на ту же цель не шлётся в течение 24 часов.

#### Техническая реализация
- Таблицы: `analytics_events`, `complaints`, `admin_logs`, `notifications`
- Cron через **APScheduler** (`app/services/scheduler.py`, jobs в `app/services/jobs/`)
- Служебные эндпоинты: `GET /admin/jobs`, `POST /admin/jobs/{name}/run`, `GET /admin/complaints[/stats]`, `POST /admin/test-push`

---

### КОНФИГ (`app/core/config.py`)

```python
DEV_MODE = true              # OTP возвращается в ответе
MISTRAL_API_KEY = ""         # ключ AI-ассистента
COMPLAINT_NOTIFY_1 = 10      # первое уведомление о жалобах
COMPLAINT_NOTIFY_2 = 100     # повторное серьёзное
COMPLAINT_BLOCK_AT = 300     # автоблокировка
COMPLAINT_BLOCK_DAYS = 14    # на сколько блокируем
FIREBASE_SERVICE_ACCOUNT_PATH = "serviceAccountKey.json"
```

---

### ТЕКУЩИЙ СТАТУС РАЗРАБОТКИ

**Бизнес-модель:** приложение полностью бесплатное для всех ролей; монетизация и подписки убраны. Аналитика и отчёты доступны клиникам и аптекам без ограничений.

**Реализовано в коде:**
- ✅ Аутентификация (JWT + refresh, OTP, восстановление пароля), роли
- ✅ Каталоги врачей / клиник / аптек, поиск, симптомы → специализации
- ✅ Регистрация и кабинеты врачей, клиник, аптек; управление врачами
- ✅ Модерация изменений профиля врача
- ✅ Отзывы (врачи / клиники / филиалы аптек)
- ✅ Избранное с синхронизацией на бэкенде (`/favorites`)
- ✅ AI-ассистент (Mistral) с серверной историей диалогов
- ✅ Аналитика событий и отчёты для клиник и аптек (`fl_chart`)
- ✅ Жалобы + APScheduler (`complaints_warning`, `unblock_expired`) с порогами 10/100/300
- ✅ Push-уведомления (FCM) + in-app уведомления
- ✅ Веб-панель администратора (Jinja2, cookie JWT)
- ✅ Локализация RU / KY / EN (`.arb` + `flutter_localizations`)
- ✅ pytest: `backend/tests/test_complaints.py`

**Запланировано:**
- ⏳ Перенос загрузки фото с локальной папки `uploads/` на S3
- ⏳ Полноценные миграции Alembic (сейчас `versions/` пуста)
