# MedFind — История изменений

## v2.2 — Полная админ-панель и фича жалоб (17.05.2026)

Эта версия закрывает все требования из ТЗ v2.1, раздел **13.5. Администратор** (11 разделов веб-панели) и раздел **21.1. Краткосрочные задачи** (доработка панели, таблица complaints, расширение тестов).

### Реализовано в 9 последовательных фазах

#### Фаза A · Фундамент — миграции и middleware
- Миграция `c4d5e6f7a8b9` — таблица `complaints` (модель Complaint: target_type, target_id, reason, comment, status, resolution_note, resolved_by_admin_id, resolved_at)
- Миграция `d5e6f7a8b9c0` — расширение `users` (`last_active_at`, `must_change_password`, `deleted_at`, `city`), флаги `is_frozen` / `frozen_reason` на `clinics` и `pharmacy_companies`, таблицы `search_logs`, `broadcasts`, `broadcast_deliveries`
- Middleware в [security.py](../backend/app/core/security.py): автообновление `last_active_at` (throttle 5 мин), блок 403 для `is_active=false`, 401 для `deleted_at`
- Логирование поисковых запросов через `SearchLog` в [routers/search.py](../backend/app/routers/search.py)

#### Фаза B · Дашборд `/panel/`
- DAU / WAU / MAU (по `User.last_active_at`)
- Регистрации сегодня с разбивкой по ролям (patient / doctor / clinic / pharmacy)
- Карточка «🚩 Жалобы» — новые + за 24 часа, со ссылкой на `/panel/complaints`
- Выручка за 3 периода: сегодня / 7 дней / 30 дней
- График регистраций по дням за 30 дней (Chart.js line)
- График выручки по дням за 30 дней (Chart.js bar)

#### Фаза C · Пользователи `/panel/users`
- Фильтры: роль, статус (active / blocked / deleted / all), поиск по имени / телефону / email
- **Блокировка / разблокировка** — toggle `is_active`, инвалидация `refresh_token`
- **Сброс пароля** — генерация временного, флаг `must_change_password`, временный пароль показывается админу одноразово через flash-cookie
- **Смена роли** inline (нельзя поменять свою)
- **Soft-delete** — `deleted_at`, аккаунт выходит из всех сессий
- Страница **истории действий админов** над юзером `/users/{id}/history`
- Все действия пишутся в `admin_logs`

#### Фаза D · Отзывы `/panel/reviews`
- Новый раздел: фильтры по target_type / минимальному рейтингу / наличию жалоб
- Карточки помечаются жёлтым, если на них есть жалобы
- Удаление с обязательным указанием причины → автоматический пересчёт рейтинга цели
- Из карточки отзыва в мобайле через меню `⋮` доступна жалоба (target_type=review)

#### Фаза E · Клиники и аптеки
- **Карточка клиники** `/panel/clinics/{id}` — информация, активные врачи, история подписок, жалобы
- **Заморозка / разморозка клиники** с указанием причины (флаг `is_frozen`)
- **Блокировка клиники** (status → blocked)
- **Карточка аптечной компании** `/panel/pharmacies/{id}` — данные, филиалы, история подписок
- **Активация / деактивация каждого филиала** отдельной кнопкой
- Список аптек переписан под актуальную модель `PharmacyCompany` (был сломан со старыми полями)

#### Фаза F · Финансы — все транзакции, CSV, refund
- Новый раздел `/panel/transactions` — все WalletTransaction с фильтрами (тип / статус / владелец / период 7/30/90/365/все)
- **CSV-экспорт** `/panel/transactions.csv` — выгрузка до 50000 строк
- **Возврат (refund)** через сервис [`wallet_service.refund_purchase()`](../backend/app/services/wallet_service.py) — атомарная операция с `SELECT FOR UPDATE`, проверка дубля по `related_subscription_id` (HTTP 409 `already_refunded`)
- Каждое действие пишет лог в `admin_logs`

#### Фаза G · Аналитика платформы `/panel/analytics`
- Новый раздел, селектор периода (7 / 30 / 90 / 180 дней)
- Суммарные счётчики по ролям (active, не deleted)
- **График DAU** за период (Chart.js line)
- **Регистрации по дням** с разбивкой по ролям (Chart.js stacked bar)
- **Топ-20 поисковых запросов** из `search_logs`
- **Топ-15 городов** по `User.city`
- **Конверсия trial → paid** (счётчик trial-подписок vs. купивших Pro/Premium + процент)

#### Фаза H · Push-рассылки `/panel/broadcasts`
- Список рассылок + кнопка «+ Новая»
- Конструктор `/panel/broadcasts/new`:
  - Заголовок + тело + URL картинки
  - Сегментация: роли (multi), планы (multi для clinic/pharmacy), города, дата регистрации после, активны за N дней
  - **AJAX-предпросмотр** количества получателей до отправки
  - Два режима: «Сохранить черновик» / «Отправить сейчас»
- Карточка рассылки `/panel/broadcasts/{id}` — содержимое, JSON-сегмент, статистика, лог доставок, кнопка повторной отправки для failed/draft
- Сервис [`broadcast_service.py`](../backend/app/services/broadcast_service.py): `resolve_segment()` + `send_broadcast()` (создаёт `Notification` + `BroadcastDelivery`). FCM-интеграция — TODO

#### Фаза I · Контент — редактор статей
- Кнопка «+ Новая статья» в `/panel/articles`
- Редактор `/panel/articles/{id}/edit` — табы RU / KY / EN, Markdown в textarea с шпаргалкой, обложка, категория, чекбокс публикации
- **Удаление статьи** с подтверждением

### Фича жалоб (отдельный коммит, прошёл ранее в рамках того же мерж-цикла)

- **Backend**:
  - Модель `Complaint` + миграция `c4d5e6f7a8b9`
  - Пациентский роутер `POST /complaints`, `GET /complaints/mine` ([routers/complaints.py](../backend/app/routers/complaints.py))
  - Антидубликат: одна активная жалоба на цель от одного юзера → HTTP 409 `already_reported`
  - Админ API `/admin/complaints` (GET / GET stats / PATCH / DELETE)
  - Активирован cron `complaints_warning` (ежедневно 09:00): при ≥ `COMPLAINTS_WARNING_THRESHOLD=100` жалоб за `COMPLAINTS_WINDOW_DAYS=10` дней — push владельцу + всем админам, дедуп через `notifications`
- **Mobile**:
  - Универсальная модалка [report_dialog.dart](../mobile/lib/shared/widgets/report_dialog.dart) с 6 причинами + комментарием
  - Иконка флажка 🚩 в AppBar карточек врача, клиники, филиала аптеки
  - В карточках отзывов меню `⋮` → «Пожаловаться» (только не для своих отзывов)

### Тесты
- Было: 41 pytest-тест
- **Стало: 57** (+ 16 новых)
- Новые модули:
  - [`test_complaints.py`](../backend/tests/test_complaints.py) — 6 тестов: создание, закрытие, cron-предупреждения (под порогом / выше порога / дедуп / отзывы пропускаются)
  - [`test_refund_and_broadcast.py`](../backend/tests/test_refund_and_broadcast.py) — 9 тестов: refund (success / дубль / wrong_type), сегментация рассылок (роль / пусто / без blocked,deleted / по городу), отправка broadcast, SearchLog

### База данных — новые/изменённые таблицы

| Таблица | Изменение |
|---|---|
| `users` | +`last_active_at`, +`must_change_password`, +`deleted_at`, +`city`, индексы на `last_active_at`, `city` |
| `clinics` | +`is_frozen`, +`frozen_reason` |
| `pharmacy_companies` | +`is_frozen`, +`frozen_reason` |
| `complaints` | новая — жалобы пациентов |
| `search_logs` | новая — лог поисковых запросов |
| `broadcasts` | новая — push-рассылки |
| `broadcast_deliveries` | новая — лог доставок |

### Сводка по разделам админ-панели (соответствие ТЗ v2.1 §13.5)

| # | Раздел ТЗ | Статус |
|---|---|---|
| 1 | Дашборд (регистрации, DAU, выручка, жалобы, истекающие подписки) | ✅ |
| 2 | Пользователи (фильтр по роли, блокировка, сброс пароля, история) | ✅ |
| 3 | Клиники (фильтр по тарифу, ручное управление подпиской, заморозка) | ✅ |
| 4 | Аптеки (то же + список филиалов) | ✅ |
| 5 | Врачи (статусы, фильтры, принудительное изменение) | ✅ |
| 6 | Отзывы и жалобы (модерация, удаление с причиной) | ✅ |
| 7 | Контент (статьи + редактор) | ✅ (справочники симптомов/специализаций пока в коде) |
| 8 | Финансы (платежи, выручка, заявки с кодами MEDF-X-Y) | ✅ + refund + CSV |
| 9 | Аналитика платформы (DAU/WAU/MAU, топ запросов, география) | ✅ |
| 10 | Push-рассылки (сегментация: роль / город / план) | ✅ |
| 11 | Логи действий админов (admin_logs, не удаляется) | ✅ |

### Что осталось вне scope (для будущих версий)
- Реальная FCM-отправка push (рассылки сейчас идут в таблицу `notifications`, мобайл подхватывает)
- Запланированная отправка рассылок через APScheduler (поле `scheduled_at` есть, обработчик не подключён)
- Перенос справочников симптомов / специализаций / категорий клиник из `mobile/lib/core/constants/app_constants.dart` в БД (требует синхронных правок Flutter-кода и `/content` API)
- Markdown-превью прямо в редакторе (сейчас редактируем сырой Markdown; рендеринг идёт на стороне мобайла)
- Конверсии «free → upgrade» и «регистрация → создание клиники» в аналитике (есть только trial → paid)
- PDF-экспорт Premium-отчётов клиники/аптеки
