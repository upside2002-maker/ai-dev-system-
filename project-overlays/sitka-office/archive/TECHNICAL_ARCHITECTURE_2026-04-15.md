> **FROZEN snapshot, описывает legacy flow**

# Sitka Office — Technical Architecture

Дата: 2026-04-15 | Версия: 2.0 (полная ревизия по фактическому коду)

## 1. Обзор системы

**Sitka Office** — CRM для байерского бизнеса (покупка товаров в США, доставка в Россию через Казахстан).

Система ведёт сделку от первого контакта клиента до получения оплаты, автоматизируя: поиск товара, расчёт цены, отслеживание логистики, управление рисками, коммуникацию с клиентом.

### Ключевые цифры

| Метрика | Значение |
|---------|----------|
| Общий объём кода | ~12,500 строк |
| Haskell (core + tests) | ~2,560 строк |
| Python (services) | ~3,170 строк |
| TypeScript/TSX | ~4,000 строк |
| CSS | ~2,770 строк |
| Тесты Haskell | 33 (example + property-based) |
| Тесты Python | 21 |
| E2E тесты Playwright | 24 |

---

## 2. Архитектура

### Три слоя

```
┌─────────────────────────────────────────────────────────────────┐
│  sitka-web (React 19 + TypeScript + Vite)          :5173       │
│  Операторский дашборд. Тонкий слой — вся логика на бэкенде.    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP (fetch)
┌──────────────────────────▼──────────────────────────────────────┐
│  sitka-core (Haskell, Servant + Persistent + Warp)  :8080      │
│  Domain types, state machine, pricing, risk, API.              │
│  Single source of truth по бизнес-логике.                      │
├────────────────────────────────────────────────────────────────-┤
│  sitka-services (Python, FastAPI + Uvicorn)          :8081      │
│  Telegram bot, парсеры, notifications, exchange rate.          │
│  Вызывает core по HTTP. Не принимает бизнес-решений.           │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│  PostgreSQL 16           :5432     │  Redis 7       :6379      │
│  Единственный persistent store     │  Кеш/очереди (пока idle)  │
└────────────────────────────────────┴───────────────────────────-┘
```

### Принцип разделения

| Слой | Владеет | Не владеет |
|------|---------|-----------|
| **Core** | Domain types, state machine, pricing, risk flags, API контракты, DB schema | Парсеры, UI, browser automation, Telegram |
| **Services** | FastAPI, парсеры, Telegram bot, notifications, exchange rate | Бизнес-решения по деньгам и статусам |
| **Web** | Операторские сценарии, UX, API client | Расчёт цен, бизнес-логика статусов |

### Поток данных

```
Клиент (Telegram/Avito) → Менеджер → Web UI / Telegram Bot
    → sitka-core API (создание сделки, transition)
    → sitka-services (парсинг US stores, Avito references)
    → sitka-core (offer → quote → pricing engine)
    → Web UI (КП клиенту) → Client approve/reject
    → Logistics chain (US → KZ → RU) → Payment → Completed
```

---

## 3. Domain Model (Haskell)

### 3.1 Типы (`Domain/Types.hs`, 90 строк)

Фундамент type safety — 6 newtypes поверх `Scientific`:

```haskell
newtype USD          = USD { unUSD :: Scientific }
newtype RUB          = RUB { unRUB :: Scientific }
newtype Percent      = Percent { unPercent :: Scientific }
newtype ExchangeRate = ExchangeRate { unExchangeRate :: Scientific }
```

Каждый имеет `PersistField` instance (Scientific ↔ Double на границе с БД):

```haskell
instance PersistField USD where
  toPersistValue (USD x) = PersistDouble (toRealFloat x)
  fromPersistValue (PersistDouble d) = Right (USD (fromFloatDigits d))
  fromPersistValue x = Left $ "Expected Double for USD, got: " <> T.pack (show x)
```

**Открытый вопрос:** конструкторы экспортированы напрямую. Нужны smart constructors (`mkPercent`, `mkUSD`, `mkRUB`, `mkExchangeRate`) с валидацией диапазонов.

### 3.2 Клиент (`Domain/Client.hs`)

```haskell
data ClientSource = Avito | WhatsApp | Telegram | Referral | Other Text

data Client = Client
  { clientName      :: Text
  , clientPhone     :: Maybe Text
  , clientEmail     :: Maybe Text
  , clientTelegram  :: Maybe Text
  , clientSource    :: ClientSource
  , clientNotes     :: Maybe Text
  , clientCreatedAt :: UTCTime
  }
```

### 3.3 Сделка (`Domain/Deal.hs`, 153 строки)

**13 статусов** — полная логистическая цепочка:

```haskell
data DealStatus
  = New            -- Заявка поступила
  | Sourcing       -- Менеджер ищет товар
  | Quoted         -- КП сформировано
  | Approved       -- Клиент одобрил
  | Purchased      -- Выкуплено в US store
  | AtUsWarehouse  -- На складе в США
  | ShippedKz      -- Отправлено в Казахстан
  | InKazakhstan   -- Прибыло в транзитный хаб KZ
  | ShippedRu      -- Отправлено в Россию
  | Delivered      -- Доставлено клиенту
  | Completed      -- Оплата получена (терминал)
  | Rejected       -- Клиент отказался (терминал)
  | Cancelled      -- Отменено (терминал)
```

22 поля записи Deal: clientId, status, managerId, desiredItem/Size/Color, maxPriceRub, plannedCost, quotedPrice, actualCost/Revenue, plannedMargin/actualMargin, riskFlags, trackingUs/Kz/Ru, timestamps (created, updated, completed, cancelled), cancelReason, notes.

**Сериализация:** Custom JSON/Persist/HttpApiData через exhaustive `statusToText`/`textToStatus` (lowercase wire format: `"new"`, `"sourcing"`, `"at_us_warehouse"`). Backwards compatibility: `"in_transit"` → `ShippedKz`.

### 3.4 State Machine (`Domain/Deal/StateMachine.hs`, 73 строки)

Pure функции, zero IO:

```haskell
data Transition
  = StartSourcing | CreateQuote | ClientApprove | ClientReject
  | ConfirmPurchase | ConfirmUsWarehouse | ConfirmShipKz
  | ConfirmArriveKz | ConfirmShipRu | ConfirmDelivery
  | ConfirmPayment | CancelDeal
```

**Граф переходов:**

```
New ──StartSourcing──→ Sourcing ──CreateQuote──→ Quoted
                                                   │
                                    StartSourcing ←─┤ (повторный поиск)
                                                   │
                                    ClientReject ──→ Rejected ■
                                    ClientApprove ─→ Approved
                                                       │
                            ConfirmPurchase ───────────→ Purchased
                            ConfirmUsWarehouse ────────→ AtUsWarehouse
                            ConfirmShipKz ─────────────→ ShippedKz
                            ConfirmArriveKz ───────────→ InKazakhstan
                            ConfirmShipRu ─────────────→ ShippedRu
                            ConfirmDelivery ───────────→ Delivered
                            ConfirmPayment ────────────→ Completed ■

Любой нетерминальный ──CancelDeal──→ Cancelled ■
```

**API:**

```haskell
transition :: DealStatus -> Transition -> Either TransitionError DealStatus
canTransition :: DealStatus -> Transition -> Bool
allowedTransitions :: DealStatus -> [(Transition, DealStatus)]
isTerminal :: DealStatus -> Bool
```

### 3.5 Оффер и Avito-референс

```haskell
-- Найденное предложение в US store
data USAOffer = USAOffer
  { store, url, itemName :: Text
  , priceUsd, shippingUsd :: USD
  , inStock :: Bool
  , foundAt :: UTCTime
  , notes :: Maybe Text
  }

-- Сравнительная цена на Avito
data AvitoReference = AvitoReference
  { url, itemName :: Text
  , priceRub :: RUB
  , seller :: Text
  , checkedAt :: UTCTime
  }
```

### 3.6 Quote и CostBreakdown

```haskell
data CostBreakdown = CostBreakdown
  { cbItemPriceUsd   :: USD            -- цена товара
  , cbExchangeRate   :: ExchangeRate   -- курс ЦБ
  , cbExchangeBuffer :: Percent        -- буфер на колебания курса
  , cbShippingUs     :: USD            -- доставка внутри US
  , cbShippingIntl   :: USD            -- US → KZ
  , cbCustoms        :: RUB            -- таможня
  , cbShippingRu     :: RUB            -- KZ → клиент
  , cbTotalCostRub   :: RUB            -- итого себестоимость
  }

data Quote = Quote
  { qDealId, qOfferId :: Key Deal / Key UsaOffer
  , qCostBreakdown    :: CostBreakdown
  , qMarginPercent    :: Percent
  , qPriceRub         :: RUB           -- цена для клиента
  , qAvitoPriceRub    :: Maybe RUB     -- цена на Avito
  , qClientSaves      :: Maybe RUB     -- экономия клиента
  , qValidUntil       :: UTCTime
  }
```

### 3.7 Logistics Types

```haskell
-- Order tracking (US store purchase)
data OrderStatus = Placed | Confirmed | Shipped

-- Shipment tracking (multi-stage)
data ShipmentStage = USWarehouse | IntlTransit | Customs | RUTransit | ShipDelivered

-- Payment lifecycle
data PaymentStatus = Pending | Received | Refunded
data PaymentMethod = Card | BankTransfer | Cash | OtherMethod Text
```

### 3.8 Events — Immutable Audit Log

```haskell
data Actor = ManagerActor EntityId | SystemActor | ParserActor | AIActor

data EventType
  = DealCreated | SourcingStarted | OfferAdded | QuoteSent
  | DealApproved | DealRejected
  | PurchaseConfirmed | ShipmentStarted | DeliveryConfirmed | PaymentReceived
  | DealCompleted | DealCancelled
  | RiskFlagAdded | RiskFlagRemoved | NoteAdded
```

Каждое событие: `dealId`, `eventType`, `actor`, `payload` (JSON), `createdAt`. Append-only.

---

## 4. Engines (Pure Business Logic)

### 4.1 Pricing Engine (`Engine/Pricing.hs`, 67 строк)

4 чистые функции, zero IO, вся арифметика в newtypes:

```haskell
-- Себестоимость в рублях
calculateCost :: PricingParams -> USD -> RUB
-- Цена для клиента (cost + margin)
calculateQuotePrice :: RUB -> Percent -> RUB
-- Маржа (revenue - cost)
calculateMargin :: RUB -> RUB -> RUB
-- Экономия клиента vs Avito
calculateClientSavings :: RUB -> RUB -> RUB
```

**PricingParams:** exchangeRate, exchangeBuffer (%), shippingUs, shippingIntl (USD), customs, shippingRu (RUB).

**Формула стоимости:**
```
totalCostRub = (itemPriceUsd + shippingUs + shippingIntl)
             × exchangeRate × (1 + exchangeBuffer/100)
             + customs + shippingRu
```

### 4.2 Risk Engine (`Engine/RiskFlags.hs`)

Pure функция `assessRisks :: RiskContext -> [RiskFlag]`:

| Flag | Условие |
|------|---------|
| `NegativeMargin` | Маржа < 0 |
| `LowMargin` | Маржа < 10% от quotedPrice |
| `MissingAvitoRef` | Статус Sourcing/Quoted, нет Avito reference |
| `OverdueDelivery` | В транзите > 14 дней |
| `PaymentOverdue` | Delivered > 7 дней, нет оплаты |

`RiskContext`: status, plannedMargin, plannedCost, quotedPrice, hasAvitoRef, lastUpdateAt, currentTime.

---

## 5. API Layer

### 5.1 Application Monad (`Api/AppM.hs`, 79 строк)

```haskell
type AppM = ReaderT ConnectionPool Handler
```

Устраняет передачу `pool` через все хэндлеры. Стандартные хелперы:

```haskell
fetchOr404    :: Key val -> AppM val           -- get + 404
runDb         :: SqlPersistT IO a -> AppM a    -- pool → runSqlPool
recordEvent   :: Key Deal -> EventType -> Actor -> Maybe Value -> AppM ()
validateOr400 :: Bool -> Text -> AppM ()       -- guard + 400
```

### 5.2 Servant API Composition (`Api/Server.hs`)

```haskell
type API = HealthAPI :<|> ClientsAPI :<|> DealsAPI :<|> QuotesAPI
```

**Middleware stack:** Bearer token auth (опционально, пропускает `/health`) → CORS → Servant routing.

### 5.3 Endpoints

#### Clients (`Api/Clients.hs`)

| Method | Path | Action |
|--------|------|--------|
| POST | `/api/clients` | Создать клиента |
| GET | `/api/clients` | Список (с поиском) |
| GET | `/api/clients/:id` | Получить клиента |
| PATCH | `/api/clients/:id` | Обновить клиента |

#### Deals (`Api/Deals.hs`)

| Method | Path | Action |
|--------|------|--------|
| POST | `/api/deals` | Создать сделку |
| GET | `/api/deals` | Список (фильтр по status, clientId, search, pagination) |
| GET | `/api/deals/:id` | Детали сделки |
| PATCH | `/api/deals/:id` | Обновить сделку |
| POST | `/api/deals/:id/offers` | Добавить оффер |
| POST | `/api/deals/:id/avito-refs` | Добавить Avito reference |
| POST | `/api/deals/:id/transition` | Перевести статус |
| POST | `/api/deals/bulk-transition` | Массовый переход |
| GET | `/api/deals/stats` | Статистика |
| GET | `/api/deals/analytics` | Аналитика |
| GET | `/api/deals/export` | Экспорт (CSV/JSON) |
| GET | `/api/events` | Лента событий (с фильтром по timestamp) |

#### Quotes (`Api/Quotes.hs`)

| Method | Path | Action |
|--------|------|--------|
| POST | `/api/deals/:id/quotes` | Создать КП (pricing engine) |
| GET | `/api/settings/pricing` | Текущие настройки pricing |
| PUT | `/api/settings/pricing` | Обновить настройки pricing |

### 5.4 Transport Types (`Api/Types.hs`)

Request/Response DTO с Aeson instances. Ключевые:

- `CreateDealReq` / `DealResp` / `UpdateDealReq`
- `DealDetailResp` — агрегат: сделка + офферы + Avito refs + события + risk flags
- `CreateClientReq` / `ClientResp` / `UpdateClientReq`
- `AddOfferReq` / `OfferResp`
- `AddAvitoRefReq` / `AvitoRefResp`
- `TransitionReq` / `BulkTransitionReq`
- `DealStatsResp` / `DealAnalyticsResp`

---

## 6. Database (`Db/Schema.hs`)

### 6.1 Таблицы (10 Persistent models)

| Таблица | Назначение | Ключевые поля |
|---------|-----------|---------------|
| **Client** | Клиенты | name, phone, email, telegram, source, notes |
| **Deal** | Сделки | clientId (FK), status, managerId, desiredItem/Size/Color, maxPriceRub, planned/quoted/actual cost/revenue/margin, riskFlags, tracking (US/KZ/RU), timestamps |
| **UsaOffer** | Офферы из US | dealId (FK), store, url, itemName, priceUsd, shippingUsd, inStock | 
| **AvitoRef** | Avito references | dealId (FK), url, itemName, priceRub, seller |
| **DealEvent** | Audit log | dealId (FK), eventType, actor, payload (JSON) |
| **Task** | Задачи по сделке | dealId (FK), description, dueDate, isDone |
| **Communication** | Лог переписки | dealId (FK), clientId (FK), channel, direction, content |
| **Quote** | КП snapshot | dealId (FK), offerId (FK), полный CostBreakdown, margin, price, Avito comparison |
| **Setting** | Настройки | key (unique), valueNum, valueText |

### 6.2 Constraints

- `UsaOffer`: unique (dealId, store, itemName) — один оффер на товар/магазин
- `Setting`: unique key
- Foreign keys: Deal → Client, UsaOffer/AvitoRef/DealEvent/Task/Communication/Quote → Deal

### 6.3 Миграции

Сейчас: auto-migration (Persistent `runMigration`). Production режим: `check` (только валидация, не мигрирует).

**Открытый вопрос:** нужен переход на versioned SQL migrations перед production.

---

## 7. Services Layer (Python)

### 7.1 FastAPI App (`app/main.py`, 128 строк)

```
Lifespan:
  startup  → start Telegram bot, event watcher, exchange rate refresh
  shutdown → stop bot, watcher

Middleware:
  CORS (configurable origins)
  Bearer token auth (optional, skip /health)

Routers:
  /api/parsing/*   — sourcing endpoints
  /api/webhooks/*  — webhook handlers

Manual:
  /health              — checks core reachability + parser
  POST /api/admin/refresh-rate — принудительное обновление курса ЦБ
```

### 7.2 Telegram Bot (`app/bot/`, ~1,100 строк)

5 модулей: init, handlers, callbacks, cards, create_flow, auth.

**Команды менеджера:**

| Команда | Действие |
|---------|----------|
| `/new` | Создать клиента + сделку (conversation flow) |
| `/deal <name\|ID>` | Добавить сделку существующему клиенту |
| `/d <ID>` | Карточка сделки (inline keyboard) |
| `/d <ID> трек <номер>` | Обновить трекинг |
| `/d <ID> заметка <текст>` | Добавить заметку |
| `/active` | Список активных сделок |
| `/recent` | Последние 10 сделок |
| `/find <query>` | Поиск по сделкам/клиентам |
| `/client <ID>` | Карточка клиента |
| `/cancel` | Отмена текущего ввода |
| `/mgr` | Справка |

**Callbacks:** inline кнопки для transition, редактирования, навигации по сделке.

**Auth:** белый список Telegram ID менеджеров (через `SITKA_MANAGER_TG_IDS`).

### 7.3 Notifications (`app/notifications/`)

**Event watcher** — consumer ленты событий из core.

**Notifier** — push-уведомления клиенту в Telegram при смене статуса:

| Статус | Сообщение |
|--------|-----------|
| `quoted` | "КП готово!" + цена |
| `purchased` | "Товар выкуплен!" |
| `shipped_kz` | "Товар в пути!" (из US) |
| `shipped_ru` | "Товар в пути в Россию!" + трекинг |
| `delivered` | "Товар доставлен!" |
| `cancelled` | "Заказ отменён" + причина |

Внутренние статусы (Sourcing, Approved, AtUsWarehouse, InKazakhstan) — не триггерят уведомления.

### 7.4 Парсеры

- **Avito parser** (`app/parsers/avito.py`) — Playwright browser automation для получения цен конкурентов
- **Avito mock** (`app/parsers/avito_mock.py`) — fallback для dev
- **Avito classify** (`app/parsers/avito_classify.py`) — классификация найденных товаров
- **US store parser** (`app/parsers/inventory_v2.py`) — фабрика парсеров для 16 US stores

### 7.5 Exchange Rate (`app/tasks/exchange_rate.py`)

Автоматическое обновление курса USD/RUB из ЦБ РФ.

### 7.6 Core Client (`app/core_client/client.py`)

HTTP-клиент к sitka-core. Все бизнес-операции (создание сделок, transitions, quotes) делегируются core.

---

## 8. Web Frontend (React)

### 8.1 Стек

- React 19, TypeScript (strict mode), Vite
- Без state management библиотеки — custom `useAppState` hook (~515 строк)
- SSE для real-time обновлений (`useEventStream`)
- Playwright для E2E тестов

### 8.2 Структура компонентов

```
App.tsx (17 строк, thin)
└── AppLayout.tsx
    ├── InboxSidebar.tsx        — список сделок, фильтры, поиск
    ├── DealWorkspace.tsx       — основная рабочая зона
    │   ├── StageIndicator.tsx  — визуальный прогресс сделки
    │   ├── ClientBanner.tsx    — инфо о клиенте
    │   ├── NewRequestStep.tsx  — заявка
    │   ├── SourcingStep.tsx    — поиск товара
    │   ├── ReviewOffersStep.tsx— сравнение офферов
    │   ├── QuoteReadyStep.tsx  — КП сформировано
    │   ├── FulfillmentStep.tsx — логистика (US→KZ→RU)
    │   └── CompletedStep.tsx   — завершение
    ├── ContextPanel.tsx        — боковая панель (события, заметки)
    ├── PricingSettingsPanel.tsx — настройки pricing engine
    ├── AnalyticsDashboard.tsx  — аналитика по сделкам
    └── DealStatsWidget.tsx     — виджет статистики
```

### 8.3 API Client (`src/api/client.ts`)

Типизированный клиент к core + services. TypeScript types (`src/api/types.ts`) зеркалят Haskell domain types.

### 8.4 Constants

- `stores.ts` — 16 US stores (Sitka, Kuiu, etc.)
- `statuses.ts` — display config для статусов (labels, colors, icons)
- `formatters.ts` — форматирование чисел/дат

---

## 9. Infrastructure

### 9.1 Docker Compose

**Development** (`docker-compose.yml`):

| Service | Image | Port | Notes |
|---------|-------|------|-------|
| postgres | postgres:16-alpine | 5432 | DB: sitka, healthcheck: pg_isready |
| redis | redis:7-alpine | 6379 | healthcheck: redis-cli ping |
| core | ./sitka-core | 8080 | migrate: auto, log: dev |
| services | ./sitka-services | 8081 | depends: core, redis |
| web | ./sitka-web | 80 | depends: core, services |

Profiles: `app` для core/services/web (БД и Redis стартуют всегда).

**Production** (`docker-compose.prod.yml`):

- Пароли из `.env`
- Core: migrate=check, log=json
- Web: nginx-prod.conf, SSL через Let's Encrypt
- Sidecar: certbot (обновление SSL каждые 12ч)
- Sidecar: backup (pg_dump ежедневно)

### 9.2 CI/CD (`.github/workflows/ci.yml`)

**Триггеры:** push to master, PR to master (concurrent runs cancelled per ref).

| Job | Stack | Tests |
|-----|-------|-------|
| Haskell | GHC 9.6 + Cabal 3.10 + libpq-dev | 33 tests (HSpec + QuickCheck) |
| Python | Python 3.12 + pytest | 21 tests |
| Frontend | Node 22 + Playwright (Chromium) | tsc --noEmit + 24 E2E tests |

Кеширование: cabal store, pip, npm ci.

### 9.3 Makefile (23 targets)

```
Infrastructure:   db-up, db-down, db-psql
Haskell:          core-build, core-run, core-test, core-repl
Python:           services-setup, services-run, services-dev, services-test
Frontend:         web-setup, web-dev, web-build, web-test
Docker:           docker-build, docker-up, docker-down
Deploy:           deploy-prod
```

### 9.4 Auth

Bearer token через env (`CORE_API_TOKEN` / `SITKA_API_TOKEN`). Опционально — если env не задан, auth отключена. `/health` пропускается всегда.

---

## 10. Compiler & Language Configuration

### Haskell (sitka-core.cabal)

```yaml
Language: GHC2021

Default Extensions:
  - DataKinds
  - DeriveGeneric
  - DeriveAnyClass
  - DerivingStrategies
  - OverloadedStrings
  - RecordWildCards
  - StrictData
  - TypeOperators

GHC Flags: -Wall -Werror -Wincomplete-patterns -Wunused-imports

Key Dependencies:
  servant + servant-server 0.20
  persistent + persistent-postgresql 2.13-2.14
  aeson 2.1, scientific 0.3
  warp 3.3, wai-cors 0.2
  hspec 2.11, QuickCheck 2.14
```

### Python

```yaml
Python: 3.12
Framework: FastAPI + Uvicorn
Browser: Playwright (Chromium)
Config: Pydantic Settings (SITKA_ prefix)
Testing: pytest
```

### TypeScript

```yaml
React: 19
Bundler: Vite
Mode: strict
E2E: Playwright
```

---

## 11. Type Safety Guarantees

### Что уже работает

| Гарантия | Как реализовано |
|----------|----------------|
| Деньги не путаются | `USD`, `RUB` newtypes с PersistField |
| Статусы exhaustive | `-Wincomplete-patterns` + `statusToText` без wildcard на конструкторах |
| fetchOr404 | Единый хелпер, нет дублирования null-check |
| Pure business logic | StateMachine, Pricing, RiskFlags — zero IO |
| DB boundary clean | PersistField instances для всех newtypes и ADTs |
| API types typed | Transport DTO с Aeson, отделены от domain |
| Immutable audit | DealEvent append-only, typed Actor/EventType |

### Что ещё открыто

| Проблема | Severity | Решение |
|----------|----------|---------|
| Конструкторы exported | Medium | Smart constructors: mkPercent(0-100), mkUSD(≥0), mkRUB(≥0), mkExchangeRate(>0) |
| riskFlags как Text | Medium | JSONB array или junction table |
| eventType/actor как Text в DB | Low | ADT с PersistField (как DealStatus) |
| Setting.valueNum :: Double | Low | Newtype или Scientific |
| Мало тестов SM edge cases | Medium | QuickCheck property tests для граничных случаев |
| Redis не подключен | Low | Подключить когда будет нагрузка |

---

## 12. Self-Learning System

### В sitka-office/.claude/

| Файл | Содержимое |
|------|-----------|
| `corrections.md` | 7 anti-patterns (BAD → GOOD → WHY) |
| `review-checklist.md` | Pre-commit checks для агентов |
| `reference-snippets/haskell-handler-patterns.md` | Эталон AppM handler |
| `reference-snippets/haskell-state-machine.md` | Эталон SM pattern |
| `reference-snippets/haskell-pricing-engine.md` | Эталон pricing |
| `prompts/task-splitting.md` | Шаблоны задач по слоям |

### Corrections (выборка)

1. **PersistField для newtypes** — не `toRealFloat (unUSD price)`, а instance
2. **Exhaustive statusToText** — нет wildcard на конструкторах, `-Wincomplete-patterns`
3. **fetchOr404 helper** — не повторять null-check в каждом handler
4. **Domain logic в core** — Python не принимает бизнес-решений
5. **Operator language** — UI показывает "этап", "действие", не enum-ы
6. **Pre-deal vs Active deal** — sourcing отделён от создания сделки
7. **TypeScript `as const` + `.includes()`** — cast to `readonly string[]`

### В ai-dev-system/

Отдельный репозиторий для кросс-проектной инфраструктуры разработки:

```
CLAUDE_GLOBAL.md               — правила для агентов
AGENT_OPERATING_MODEL.md       — роли, цикл, координация
corrections/                   — кросс-проектные anti-patterns
playbooks/{haskell,python,frontend}/
templates/reference-snippets/
project-overlays/sitka-office/ — состояние проекта (синхронизировано)
```

---

## 13. Testing Strategy

### Haskell (33 теста)

**State Machine** (10 example + 6 property):
- Happy path: New → ... → Completed (11 transitions)
- Terminal states block all transitions
- CancelDeal from any non-terminal
- Serialization round-trip
- Backwards compatibility (`"in_transit"` → ShippedKz)

**Pricing Engine** (13 example + 7 property):
- Cost breakdown с конкретными числами (USD 200 → RUB 23,980)
- Quote price с маржой (25% → RUB 29,975)
- Exchange rate sensitivity
- Edge cases (zero shipping, high buffer)

**Risk Assessment** (11 tests):
- Negative margin detection
- Low margin threshold (10%)
- Missing Avito reference
- Overdue delivery/payment
- Multiple simultaneous flags

### Python (21 тест)
- Parser tests, bot handler tests, notification tests

### E2E (24 теста)
- Playwright + Chromium
- Full user flows через web UI

---

## 14. Roadmap

### Приоритет 0: Техдолг

- [ ] Smart constructors для newtypes (mkPercent, mkUSD, mkRUB, mkExchangeRate)
- [ ] ADT для eventType/actor (вместо Text в DB)
- [ ] Больше QuickCheck тестов для SM edge cases и pricing boundaries

### Приоритет 1: Production

- [ ] Первый деплой на VPS (docker-compose.prod.yml готов)
- [ ] Versioned SQL migrations (вместо auto-migration)
- [ ] Staging environment

### Приоритет 2: Бизнес-ценность

- [ ] Telegram bot доработки по UX
- [ ] Outbound actions (отправка КП из workspace)
- [ ] Мобильная адаптация

### Приоритет 3: Масштабирование

- [ ] Redis (кеш/очереди)
- [ ] riskFlags нормализация (JSONB / junction table)
- [ ] Event sourcing wiring

### Не делать

- Не переписывать архитектуру
- Не добавлять Kubernetes
- Не добавлять email/SMS — только Telegram
- Не тащить business logic в Python
