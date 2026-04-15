# Sitka Office — Current State Snapshot

Дата снимка: 2026-04-14

## Архитектура

Три слоя, все работают:

- `sitka-core` — Haskell (Servant + Persistent + Warp), порт 8080.
- `sitka-services` — Python (FastAPI + Uvicorn), порт 8081.
- `sitka-web` — React 19 + TypeScript + Vite, порт 5173.
- `third_party/parser-v2-lite` — подключается в services.
- PostgreSQL 16 + Redis 7 через docker-compose.

## Что реально работает

### Core (зрелость: высокая для domain model, средняя для type safety на границах)

Реализовано:
- Полный набор доменных типов: USD, RUB, Percent, ExchangeRate newtypes.
- DealStatus ADT с 10 конструкторами + RiskFlag с 6.
- Чистый state machine в отдельном модуле (canTransition, transition, allowedTransitions).
- Чистый pricing engine (4 функции, полностью pure).
- Отдельные transport types в Api/Types.hs.
- CRUD для клиентов, сделок, КП.
- Transitions через API.
- Servant type-level API composition.
- Auto-migration при старте.

НЕ реализовано / неполно:
- PersistField instances для USD/RUB/DealStatus/RiskFlag — **DB хранит raw Double и Text**.
- fetchOr404 helper — **паттерн дублируется**.
- Smart constructors — описаны в CLAUDE.md, реализация не проверена.
- Event sourcing — таблица DealEvent есть, handlers не пишут events.
- Task management — таблица Task есть, API нет.
- Communication tracking — таблица Communication есть, API нет.
- Тесты минимальные (только Spec.hs).

### Services (зрелость: средняя)

Реализовано:
- FastAPI app с CORS и lifespan.
- Health endpoint проверяет core + parser.
- Pre-deal sourcing через parsing route.
- Avito parser (Playwright) + mock fallback.
- Core client для HTTP-вызовов к core.
- Pydantic Settings для конфигурации.
- Создание сделки из результатов sourcing.
- Normalization и dedupe в pipeline.

НЕ реализовано:
- Redis не используется (сконфигурирован, но не подключён).
- Avito messaging API.
- Telegram integration.
- Очереди/background tasks.

### Web (зрелость: средняя)

Реализовано:
- Workspace layout: InboxSidebar → DealWorkspace → ContextPanel.
- Список клиентов и сделок.
- Pre-deal sourcing из UI.
- Создание сделки из результатов поиска.
- Transitions из UI.
- Quote creation.
- Banner feedback.
- PricingSettingsPanel для настроек.

НЕ реализовано / слабо:
- Нет явного "next action" — UI показывает возможности, а не указывает что делать.
- Pre-deal и active deal визуально не разделены достаточно.
- Нет мобильной адаптации.
- Нет outbound actions (отправка КП, follow-up).

## Self-learning контур

Уже работает:
- `CLAUDE.md` — 12 правил + anti-patterns с примерами кода.
- `.claude/corrections.md` — 3 записи (DB boundary, ADT as Text, fetch-or-404).
- `sitka-core/.hlint.yaml` — errors (IORef, MVar, unsafePerformIO), warnings, suggestions.

## Git

- Один коммит на master: "Initial commit: SITKA Office CRM".
- Working directory может быть в процессе изменений другим агентом.

## Бизнес-контекст

Байерский бизнес Sitka/Kuiu gear через Avito. Made-to-order из США.
Выручка через прямые переводы (СБП), не через Avito Delivery.
Подробности в `MARKETING_RESEARCH_REPORT.md`.
