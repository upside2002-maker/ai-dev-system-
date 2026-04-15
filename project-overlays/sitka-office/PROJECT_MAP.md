# Sitka Office — Project Map

## Репозиторий

Путь: `/Users/ilya/Projects/sitka-office`

## Корневые файлы

- `CLAUDE.md` — правила разработки, Haskell standards, anti-patterns.
- `.claude/corrections.md` — накопленные corrections (3 записи на 2026-04-14).
- `sitka-core/.hlint.yaml` — автоматические HLint-проверки для core.
- `MARKETING_RESEARCH_REPORT.md` — бизнес-контекст, unit economics, Avito-стратегия.
- `Makefile` — основные команды запуска всех слоёв.
- `docker-compose.yml` — PostgreSQL 16 + Redis 7.

## Слои

### `sitka-core` (Haskell, Servant, Persistent, Warp)

Build: Stack. GHC2021. Порт 8080.

Доменные модули:
- `src/Domain/Types.hs` — USD, RUB, Percent, ExchangeRate, EntityId newtypes.
- `src/Domain/Client.hs` — клиент.
- `src/Domain/Deal.hs` — сделка, DealStatus (10 конструкторов), RiskFlag (6 конструкторов).
- `src/Domain/Deal/StateMachine.hs` — чистый state machine, Transition ADT.
- `src/Domain/Quote.hs` — КП и CostBreakdown.
- `src/Domain/Offer.hs` — офферы с US-магазинов.
- `src/Domain/Order.hs` — заказы.
- `src/Domain/Payment.hs` — платежи.
- `src/Domain/Shipment.hs` — доставка.
- `src/Domain/Event.hs` — domain events.

Engine:
- `src/Engine/Pricing.hs` — чистый pricing: calculateCost, calculateQuotePrice, calculateMargin, calculateClientSavings.

Database:
- `src/Db/Schema.hs` — Persistent TH, 9 таблиц: Client, Deal, UsaOffer, AvitoRef, DealEvent, Task, Communication, Quote, Setting.

API:
- `src/Api/Types.hs` — отдельные transport types (request/response records).
- `src/Api/Health.hs` — health check.
- `src/Api/Clients.hs` — CRUD клиентов.
- `src/Api/Deals.hs` — CRUD сделок + offers + avito-refs + transitions.
- `src/Api/Quotes.hs` — генерация и список КП.
- `src/Api/Server.hs` — Servant API composition + CORS.

Entry:
- `app/Main.hs` — Warp сервер, CORE_DB_CONN env, pool size 5, auto-migration.

Тесты:
- `test/Spec.hs` — минимальный, требует расширения.

### `sitka-services` (Python, FastAPI, Uvicorn)

Порт 8081. Python 3.12 + venv.

- `app/main.py` — FastAPI app, CORS, `/health`, lifespan manager.
- `app/config.py` — Pydantic Settings, `SITKA_` env prefix.
- `app/routes/parsing.py` — pre-deal sourcing, create-deal из результатов.
- `app/core_client/client.py` — HTTP client к sitka-core.
- `app/parsers/avito.py` — Playwright browser automation для Avito.
- `app/parsers/avito_mock.py` — mock-парсер для разработки.
- `app/parsers/avito_classify.py` — классификация результатов.
- `app/parsers/inventory_v2.py` — фабрика и управление парсерами.

### `sitka-web` (React 19, TypeScript, Vite)

Порт 5173 (dev).

- `src/App.tsx` — root, state management, data loading, transitions, sourcing.
- `src/api/types.ts` — TypeScript types зеркалящие Haskell API.
- `src/api/client.ts` — API client к core и services.
- `src/components/InboxSidebar.tsx` — список клиентов/сделок.
- `src/components/DealWorkspace.tsx` — основной workspace сделки.
- `src/components/ContextPanel.tsx` — правая панель деталей.
- `src/components/PricingSettingsPanel.tsx` — настройки pricing (курс, маржа, таможня).

### `third_party/parser-v2-lite`

Внешний parser package. Подключается в sitka-services. Не core-логика.

## Команды

```
make db-up          # PostgreSQL + Redis
make db-down        # Остановить
make db-psql        # psql shell

make core-build     # stack build
make core-run       # запуск на :8080
make core-test      # stack test
make core-repl      # stack ghci

make services-setup # venv + pip install
make services-run   # uvicorn :8081
make services-dev   # uvicorn с auto-reload

make web-setup      # npm install
make web-dev        # vite dev :5173

make up             # db + инструкции
```

## Порядок чтения для нового агента

1. `CLAUDE.md` — правила и запреты.
2. `.claude/corrections.md` — ошибки предшественников.
3. Overlay `CURRENT_STATE.md` — где проект сейчас.
4. Overlay `KNOWN_ISSUES.md` — что сломано и ждёт фикса.
5. Конкретный слой по задаче.
