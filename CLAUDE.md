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

`MainScreen` использует `IndexedStack` с 4 табами: HomeScreen, SearchScreen, HealthScreen, ProfileScreen. Вложенные маршруты (`/main/doctors`, etc.) открываются поверх MainScreen через GoRouter.

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

`Doctor` / `Clinic` / `Pharmacy` имеют статус: `pending` → `active` | `rejected`.
Только `active` отдаются в публичных эндпоинтах. Модерация через `PUT /admin/approve/{type}/{id}`.

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
