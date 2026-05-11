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

# Кодогенерация (freezed + riverpod_generator) — обязательно после изменений моделей/провайдеров
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

---

## АРХИТЕКТУРА FLUTTER

Flutter-приложение находится в `mobile/` (не `frontend/`).

### Слои фичи

Каждая фича в `mobile/lib/features/<name>/` делится на три слоя:
- `data/` — Repository: делает HTTP-запросы через `ApiClient().dio`, возвращает модели
- `providers/` — StateNotifierProvider: содержит бизнес-логику и состояние
- `presentation/screens/` — виджеты, читают провайдеры через `ref.watch`/`ref.read`

Папка `domain/` существует в каждой фиче, но в текущей кодовой базе не используется (пустая).

Фичи: `auth`, `clinics`, `doctors`, `health`, `home`, `pharmacies`, `profile`, `provider`, `search`.

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

| Путь | Экран |
|------|-------|
| `/splash` | SplashScreen |
| `/onboarding` | OnboardingScreen |
| `/login` | LoginScreen |
| `/otp` | OtpScreen (extra: `{phone, devCode?}`) |
| `/main` | MainScreen (bottom nav: Home / Search / Health / Profile) |
| `/main/doctors` | DoctorsScreen |
| `/main/doctors/:id` | DoctorDetailScreen |
| `/main/clinics` | ClinicsScreen |
| `/main/clinics/:id` | ClinicDetailScreen |
| `/main/pharmacies` | PharmaciesScreen |
| `/main/pharmacies/:id` | PharmacyDetailScreen |
| `/main/search` | SearchScreen |
| `/main/favorites` | FavoritesScreen |
| `/provider/setup` | DoctorSetupScreen |
| `/provider/pending` | PendingReviewScreen |

`MainScreen` использует `IndexedStack` с 4 табами: HomeScreen, SearchScree
n, HealthScreen, ProfileScreen. Вложенные маршруты (`/main/doctors`, etc.) открываются поверх MainScreen через GoRouter.

### Общие компоненты

- `shared/models/` — модели с `fromJson`
- `shared/providers/` — общие провайдеры
- `shared/widgets/` — переиспользуемые виджеты (`GradientButton`, `DoctorCard`, `FilterChipWidget`, `RatingStars`, `CustomSearchBar`, `AppBottomNavBar`)
- `core/constants/app_constants.dart` — канонические списки `symptoms`, `specializations`, `clinicCategories`

### Хранилище на устройстве

- **`FlutterSecureStorage`** — токены (`access_token`, `refresh_token`), данные профиля (`full_name`, `user_phone`)
- **`SharedPreferences`** — избранное (ключи вида `"doctor:123"`, `"clinic:456"`) и выбранная локаль (`app_locale`)

Избранное хранится **локально** и не синхронизируется с бэкендом.

---

## АРХИТЕКТУРА BACKEND

Backend находится в `backend/`.

### Паттерны

- **Async SQLAlchemy** с `asyncpg`; сессия через `Depends(get_db)` в каждом роутере
- **Eager loading** через `selectinload` для связанных сущностей
- Pydantic-схемы: отдельно для чтения (`DoctorOut`, `DoctorListItem`) и записи (`DoctorCreate`, `DoctorUpdate`)
- Все роутеры подключены в `app/main.py` через `include_router`
- Настройки в `app/core/config.py` (pydantic-settings, читает из `.env`)

### Роутеры (`app/routers/`)

`auth`, `doctors`, `clinics`, `pharmacies`, `reviews`, `search`, `content`, `admin`, `upload`, `panel`

**Веб-панель администратора** (`panel`) — доступна по `/panel/*`, рендерит Jinja2-шаблоны из `app/templates/admin/`, аутентификация через cookie с JWT-токеном (не Bearer).

**Загрузка файлов** (`upload`) — `POST /upload/photo` сохраняет изображения в локальную папку `uploads/` и возвращает URL вида `/uploads/<filename>`. S3 в конфиге настроен, но в текущей реализации не используется.

### DEV_MODE

В `.env` / `app/core/config.py`: `DEV_MODE=true` — OTP-код возвращается в теле ответа (поле `dev_code`) без реальной отправки SMS. Flutter отображает его на экране OTP.

### Статусы провайдеров

**Клиника** — регистрируется и сразу активна, без модерации админом.

**Аптечная компания** — регистрируется и сразу активна, без модерации админом.

**Врач** — 5 статусов:
- `pending` — подал заявку в клинику, ждёт подтверждения
- `active` — клиника подтвердила, виден пациентам
- `rejected` — клиника отклонила заявку
- `deactivated` — клиника временно деактивировала
- `removed` — клиника удалила врача из своего состава; врач НЕ виден пациентам, в его личном кабинете показывается красная плашка «Вас никто не видит — выберите новую клинику», кнопка ведёт на шаг выбора клиники

Только врачи со статусом `active` отдаются в публичных эндпоинтах.

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

---

## ПРАВИЛА

- **Дизайн**: строго следуй дизайн-системе — никаких отклонений от палитры, радиусов, теней
- **Архитектура**: логика только в repository/provider, не в виджетах
- **Deeplinks**: WhatsApp → `https://wa.me/<номер>`, Telegram → `https://t.me/<username>`, звонок → `tel:<номер>` через `url_launcher`
- **Локализация**: 3 языка (RU, KY, EN); код Kyrgyz — `ky` (не `kg`). `.arb`-файлы ещё не созданы — строки пока хардкодятся; при добавлении локализации через `flutter_localizations` создавать `app_ru.arb`, `app_ky.arb`, `app_en.arb`
- **Кодогенерация**: при добавлении `@freezed` / `@riverpod` аннотаций запускать `build_runner`
- **Канонические списки**: симптомы, специализации, категории клиник хранятся в `app_constants.dart` — не дублировать в других местах

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
- Разрешение на геолокацию запрашивается **при первом входе в раздел аптек** ИЛИ при нажатии кнопки «Ближайшие аптеки»
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
- Шаг 2: адрес (required), координаты lat/lon (для кнопки «Маршрут»), график работы, WhatsApp, Telegram, Instagram, email
- Шаг 3: фото клиники

Категории хранятся как строка, разделённая «, » (`category_ru`). Координаты — `latitude`, `longitude` (float). Логотип — `logo_url`.

Клиника **сразу активна** после регистрации, без модерации.

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

Перед подтверждением клиника видит: ФИО, фото, телефон, специализацию, образование, стаж, услуги, контакты, график.

Причина отказа — **не обязательна**.

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
2. Специализация + формат консультации (очный / онлайн / оба) + цены
3. Образование и стаж
4. Услуги (название + цена)
5. Контакты (WhatsApp, Telegram, Instagram) — телефон вводится на шаге 1
6. График приёма — адрес берётся автоматически из выбранной клиники
7. Выбор клиники → отправка заявки
→ Экран ожидания подтверждения (PendingReviewScreen)

#### Статусы врача
- `pending` — ожидает подтверждения клиники
- `active` — подтверждён, виден пациентам
- `rejected` — клиника отклонила
- `deactivated` — клиника деактивировала
- `removed` — клиника удалила врача

**При статусе `removed`:** в личном кабинете врача красная плашка:
> «⚠️ Вас не видят пациенты — вы не привязаны к клинике. Выберите новую клинику.»
Кнопка ведёт на шаг 7 регистрации (выбор клиники).

#### Push-уведомления врачу
- Клиника подтвердила → «Клиника [название] подтвердила ваш профиль»
- Клиника отклонила → «Клиника [название] отклонила вашу заявку»
- Клиника деактивировала → «Ваш профиль деактивирован клиникой [название]»

#### Публичный профиль врача
- Фото, ФИО, специализация, образование, стаж, опыт, язык консультации
- Формат консультации + цены
- Услуги
- Контакты (кнопки WhatsApp, Telegram, звонок)
- График приёма
- Рейтинг + отзывы
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

### НОВЫЕ МАРШРУТЫ РОУТЕРА (добавить в app_router.dart)

| Путь | Экран |
|------|-------|
| `/main/pharmacies` | PharmaciesScreen (список филиалов, поиск, ближайшие) |
| `/main/pharmacies/company/:id` | PharmacyCompanyScreen (профиль компании) |
| `/main/pharmacies/branch/:id` | PharmacyBranchScreen (профиль филиала + галерея + отзывы) |
| `/provider/pharmacy-setup` | PharmacySetupScreen (регистрация аптечной компании) |
| `/provider/pharmacy/branches` | PharmacyBranchesScreen (управление филиалами) |
| `/provider/pharmacy/branch/add` | AddBranchScreen (добавить филиал) |
| `/clinic/doctors` | ClinicDoctorsScreen (список врачей клиники) |
| `/clinic/doctor-requests` | DoctorRequestsScreen (управление заявками) |

---

### ТЕКУЩИЙ СТАТУС РАЗРАБОТКИ

**Что согласовано и зафиксировано** (апрель 2026):
- ✅ Архитектура аптек: компания + филиалы
- ✅ Галерея фото для каждого филиала
- ✅ Отзывы на каждый филиал отдельно
- ✅ Геолокация: запрос при входе или при нажатии «Ближайшие»
- ✅ Клиника регистрируется сама, сразу активна
- ✅ Врач — только одна клиника
- ✅ Статус `removed` для врача + красная плашка
- ✅ Онлайн-консультация только через WhatsApp/Telegram
- ✅ 9 шагов регистрации врача
- ✅ Карты: 2GIS (приоритет) → Google Maps (fallback)

**Что ещё не обсуждалось** (обсудить перед реализацией):
- Регистрация пациента (телефон + пароль, без OTP на первом этапе)
- ИИ-помощник (только медицинские вопросы, история диалогов)
- Раздел «Первая помощь» (контент от администратора)
- Напоминания о лекарствах
- Push-уведомления (FCM)
