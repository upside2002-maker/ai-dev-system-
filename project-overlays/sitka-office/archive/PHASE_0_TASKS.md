> **ЗАКРЫТА 2026-04-26, см. CURRENT_STATE.md**

# Phase 0 — Tasks для рабочего агента

Phase 0 заложит foundation: новые domain types для маркетинга, расширение Deal, переход с auto-migration на версионированные миграции, базовый UI для ввода данных.

**Общий контекст для всех задач:** проектные правила в `/Users/ilya/Projects/sitka-office/CLAUDE.md`, дизайн в `ai-dev-system/project-overlays/sitka-office/ARCHITECTURE_V2.md`.

**Принцип:** одна задача = один слой = один агент за раз. Задачи идут последовательно, кроме помеченных как параллельные.

---

## Task 0.1 — Setup версионированных миграций

**Слой:** core (infrastructure)

**Файлы:**
- new: `sitka-core/migrations/` — папка для миграций
- new: `sitka-core/migrations/README.md` — workflow документация
- new: `Makefile` — добавить targets `migrate-up`, `migrate-down`, `migrate-status`, `migrate-new`
- modify: `sitka-core/app/Main.hs` — отключить `runMigration` на старте, заменить на проверку схемы (fail fast если схема не совпадает с ожидаемой)
- modify: `sitka-core/sitka-core.cabal` — если выбран встроенный механизм Persistent
- new: `sitka-core/migrations/0001_baseline.sql` (или эквивалент) — текущая схема как baseline
- modify: `docker-compose.yml` — миграции запускаются как init job или вручную, не автоматически
- modify: `docker-compose.prod.yml` — миграции запускаются явно через manual command, не на старте контейнера

**Задача:**
1. Выбрать инструмент миграций. Жёсткие требования:
   - Auto-migration отключена
   - Миграции версионированы (номер + название в имени файла)
   - Reversible (есть down-миграция или эквивалентный механизм отката)
   - Есть аудит "что и когда применилось" (отдельная таблица в БД)
   - Не зависит от рантайма приложения (миграции можно накатить когда core не запущен)
   - Работает в dev (docker-compose) и в prod (docker-compose.prod)
2. Setup выбранного инструмента
3. Сгенерировать baseline миграцию из текущей schema (всё что сейчас есть — Client, Deal, UsaOffer, AvitoRef, DealEvent, Task, Communication, Quote, Setting + индексы)
4. Применить baseline к dev БД, проверить что приложение работает
5. Документировать workflow в `migrations/README.md`: как создать новую миграцию, как накатить, как откатить, как проверить статус
6. Обновить `Makefile` с тремя targets

**Не трогать:**
- Domain types
- API endpoints
- Pricing engine
- State machine
- Tests
- Frontend

**Проверка:**
- `make migrate-status` показывает применённые миграции
- `make db-down && make db-up && make migrate-up` восстанавливает БД с нуля
- `cabal build` проходит
- `cabal test` проходит (все 33 существующих теста)
- Приложение `cabal run sitka-core` стартует без auto-migration
- В docker-compose.yml core не пытается мигрировать на старте

**Контекст:**
Сейчас `runMigration` в Main.hs делает auto-migration при каждом старте. Это опасно для production. Нужно перейти на ручной контролируемый накат. Выбор инструмента — на твоё усмотрение, документируй обоснование в `migrations/README.md`.

---

## Task 0.2 — Domain types + Deal расширение

**Слой:** core (domain)

**Зависит от:** Task 0.1 (нужен механизм миграций)

**Файлы:**
- new: `sitka-core/src/Domain/Marketing.hs` — Channel, ChannelAccount, Campaign, Listing
- new: `sitka-core/src/Domain/Marketing/Spend.hs` — SpendEntry, SpendType, SpendSource
- new: `sitka-core/src/Domain/Marketing/Attribution.hs` — SourceTouch, TouchType
- new: `sitka-core/src/Domain/Conversation.hs` — ConversationThread (метаданные), ThreadStatus, MessageDirection
- new: `sitka-core/src/Domain/Reason.hs` — DisqualifyReason, RejectReason, CancelReason
- modify: `sitka-core/src/Domain/Deal.hs` — расширить DealStatus + Deal record
- modify: `sitka-core/src/Domain/Deal/StateMachine.hs` — добавить переходы для Qualified/Disqualified
- modify: `sitka-core/src/Db/Schema.hs` — добавить новые таблицы
- new: `sitka-core/migrations/0002_marketing_foundation.sql` (или эквивалент) — миграция для новых таблиц + расширения Deal
- new: `sitka-core/test/MarketingSpec.hs`
- new: `sitka-core/test/ConversationSpec.hs`
- new: `sitka-core/test/ReasonSpec.hs`
- modify: `sitka-core/test/Spec.hs` — подключить новые spec модули
- modify: `sitka-core/sitka-core.cabal` — exposed-modules

**Задача:**

### Часть A — Marketing types

Создать в `Domain/Marketing.hs`:
```haskell
data Channel
  = AvitoChannel | TelegramChannel | WhatsAppChannel
  | DirectChannel | ReferralChannel | OtherChannel Text

-- + ChannelAccount, Campaign, Listing records по ARCHITECTURE_V2.md раздел 3.1
```

В `Domain/Marketing/Spend.hs`:
```haskell
data SpendType = Promotion | Boost | Subscription | OneTime | Other Text
data SpendSource = ManualEntry | AvitoApiSync | CsvImport
-- + SpendEntry record
```

В `Domain/Marketing/Attribution.hs`:
```haskell
data TouchType = FirstContact | Reengagement | DirectInquiry
-- + SourceTouch record
```

Все ADT должны иметь:
- PersistField instance с canonical text mapping (lowercase snake_case)
- FromJSON / ToJSON
- Exhaustive `*ToText` / `textTo*` (без wildcard на конструкторах)
- HttpApiData instance для query params

### Часть B — Conversation metadata

В `Domain/Conversation.hs`:
```haskell
data ThreadStatus
  = ThreadNew | ThreadActive | ThreadAwaitingReply
  | ThreadAwaitingUs | ThreadClosed | ThreadArchived

data MessageDirection = Incoming | Outgoing
-- + ConversationThread record (метаданные, без body сообщений)
```

### Часть C — Reason ADTs

В `Domain/Reason.hs`:
```haskell
data DisqualifyReason
  = WrongProduct | WrongBudget | TimeNotRight | JustBrowsing | Spam | OtherReason Text

data RejectReason
  = PriceTooHigh | DeliveryTooLong | FoundCheaper | ChangedMind | NoResponse | OtherReject Text

data CancelReason
  = OutOfStock | PriceWentUp | LogisticIssue | ClientChanged | OtherCancel Text
```

Все три — с PersistField и JSON.

### Часть D — DealStatus расширение

В `Domain/Deal.hs` добавить два конструктора:
```haskell
data DealStatus
  = New
  | Qualified         -- НОВОЕ: между New и Sourcing
  | Sourcing
  | Quoted
  | Approved
  ...
  | Disqualified      -- НОВОЕ: терминал, "не наш клиент"
  | Cancelled
```

Обновить:
- `statusToText` и `textToStatus` (exhaustive, новые строки: `"qualified"`, `"disqualified"`)
- `isTerminal` — Disqualified terminal
- Property тесты на round-trip

### Часть E — State machine расширение

В `Domain/Deal/StateMachine.hs`:
- Добавить transitions: `QualifyDeal`, `DisqualifyDeal`
- Обновить `allowedTransitions`:
  - `New` → добавить `(QualifyDeal, Qualified)`, `(DisqualifyDeal, Disqualified)`
  - `Qualified` → `(StartSourcing, Sourcing), (DisqualifyDeal, Disqualified), (CancelDeal, Cancelled)`
  - Остальные пути не трогать
- Тесты на новые переходы

### Часть F — Deal record расширение

В `Domain/Deal.hs` добавить поля:
```haskell
, dealSourceTouchId    :: Maybe SourceTouchId
, dealDisqualifyReason :: Maybe DisqualifyReason
, dealRejectReason     :: Maybe RejectReason
, dealCancelReason     :: Maybe CancelReason
```

### Часть G — Schema + миграция

В `Db/Schema.hs` добавить таблицы:
- `MarketingChannelAccount` (channel хранится прямо в этой таблице)
- `MarketingCampaign`
- `MarketingListing`
- `MarketingSpendEntry`
- `MarketingSourceTouch`
- `ConversationThread`

Расширить таблицу `Deal` новыми полями (все nullable для backwards compat).

Создать миграцию `0002_marketing_foundation.sql` (или эквивалент через выбранный в Task 0.1 инструмент). Миграция должна:
- Создать новые таблицы с FK constraints
- Добавить индексы по часто запрашиваемым полям (channelAccountId+spendDate, listingId, dealId на SourceTouch)
- ALTER TABLE Deal для новых полей

### Часть H — Тесты

Минимум по 5 тестов на каждый новый тип:
- Round-trip serialization (`textToX . xToText == Just`)
- PersistField round-trip
- JSON round-trip
- Property test (QuickCheck) на полную совместимость

Тесты на расширенный StateMachine: новые happy-path сценарии (New → Qualified → Sourcing → ... → Completed) + новые отказ-пути (New → Disqualified, Qualified → Disqualified).

**Не трогать:**
- Pricing engine (Engine/Pricing.hs)
- Risk engine (Engine/RiskFlags.hs)
- API endpoints (Api/*) — это Task 0.3
- Notification system
- Telegram bot
- Frontend
- Существующие тесты pricing/risk

**Проверка:**
- `cabal build` строго с `-Werror -Wincomplete-patterns`
- `cabal test` — все существующие тесты + новые (минимум 30 новых) проходят
- `make migrate-up` накатывает миграцию 0002 без ошибок
- В psql видны новые таблицы с правильными типами и FK
- Round-trip property: для каждого ADT сериализация в БД и обратно даёт исходное значение
- StateMachine не разрешает запрещённых переходов (`New → Quoted` запрещён, `Qualified → New` запрещён)

**Контекст:**
ARCHITECTURE_V2.md раздел 3 — полный дизайн model. CLAUDE.md в репозитории — правила type safety. .claude/corrections.md — известные anti-patterns (особенно про PersistField для newtypes и exhaustive serialization). reference-snippets/haskell-state-machine.md — паттерн расширения SM.

---

## Task 0.3 — API endpoints для marketing entities

**Слой:** core (api)

**Зависит от:** Task 0.2

**Файлы:**
- new: `sitka-core/src/Api/Marketing.hs` — endpoints CRUD
- new: `sitka-core/src/Api/Conversations.hs` — пока только метаданные тредов (полный inbox в Phase 2)
- modify: `sitka-core/src/Api/Server.hs` — подключить новые роутеры
- modify: `sitka-core/src/Api/Types.hs` — DTO для request/response
- modify: `sitka-core/src/Api/Deals.hs` — обновить CreateDealReq (опциональный sourceTouch + listing), TransitionReq (опциональные reasons)
- new: `sitka-core/test/ApiMarketingSpec.hs`

**Задача:**

### Endpoints для Marketing

| Метод | Путь | Действие |
|-------|------|----------|
| POST | `/api/marketing/channel-accounts` | Создать |
| GET | `/api/marketing/channel-accounts` | Список |
| PATCH | `/api/marketing/channel-accounts/:id` | Обновить |
| POST | `/api/marketing/campaigns` | Создать |
| GET | `/api/marketing/campaigns` | Список (filter by channelAccount) |
| PATCH | `/api/marketing/campaigns/:id` | Обновить |
| POST | `/api/marketing/listings` | Создать |
| GET | `/api/marketing/listings` | Список (filter by channelAccount, campaign) |
| PATCH | `/api/marketing/listings/:id` | Обновить (archive) |
| POST | `/api/marketing/spend` | Создать SpendEntry |
| GET | `/api/marketing/spend` | Список (filter by period, channel, listing) |
| GET | `/api/marketing/source-selector` | Helper: вернуть всю иерархию channel→account→campaign→listing для UI selector |

### Endpoints для Conversations (минимум)

| Метод | Путь | Действие |
|-------|------|----------|
| POST | `/api/conversations` | Создать тред (используется services при ingestion) |
| GET | `/api/conversations` | Список (filter by status, channel) |
| GET | `/api/conversations/:id` | Получить тред |
| POST | `/api/conversations/:id/link-deal` | Привязать к Deal |
| POST | `/api/conversations/:id/link-client` | Привязать к Client |

Полный Inbox UI с messages — в Phase 2. Сейчас только базовый CRUD.

### Расширения существующих endpoints

В `Api/Deals.hs`:
- `CreateDealReq` — добавить опциональные поля `channelAccountId`, `listingId`, `campaignId`. Если переданы — автоматически создать SourceTouch и привязать к Deal.
- `TransitionReq` — добавить опциональные `disqualifyReason`, `rejectReason`, `cancelReason`. Валидация: для transition в Disqualified — reason обязателен. Для transition в Rejected — reason обязателен. Для CancelDeal — reason обязателен.

### Helpers

Использовать существующий `AppM` monad и хелперы из `Api/AppM.hs` (`fetchOr404`, `runDb`, `recordEvent`, `validateOr400`).

Все мутации логировать через `recordEvent` с подходящим EventType (возможно нужны новые: `SpendRecorded`, `SourceTouchCreated`, `ListingCreated`).

**Не трогать:**
- Domain types (зафиксированы в Task 0.2)
- Pricing engine
- State machine
- Notification system
- Telegram bot
- Frontend

**Проверка:**
- `cabal build` с `-Werror`
- `cabal test` всё проходит
- Тесты в `ApiMarketingSpec.hs` покрывают happy path для каждого endpoint
- Тесты на валидацию: создание Deal с несуществующим channelAccountId → 400, transition в Disqualified без reason → 400
- Manual smoke test через curl: создать ChannelAccount → Campaign → Listing → SpendEntry → ChannelAccount, потом вызвать `/source-selector` и убедиться что возвращается дерево

**Контекст:**
ARCHITECTURE_V2.md раздел 3.1 (model), раздел 5 (как UI будет использовать selector). Используй паттерн handlers из reference-snippets/haskell-handler-patterns.md. Все API типы в Api/Types.hs отделены от domain типов (corrections.md правило).

---

## Task 0.4 — Settings UI для marketing entities

**Слой:** web

**Зависит от:** Task 0.3 (нужны endpoints)

**Файлы:**
- new: `sitka-web/src/components/settings/MarketingSettings.tsx` — главный экран
- new: `sitka-web/src/components/settings/ChannelAccountManager.tsx`
- new: `sitka-web/src/components/settings/CampaignManager.tsx`
- new: `sitka-web/src/components/settings/ListingManager.tsx`
- new: `sitka-web/src/components/settings/SpendEntryForm.tsx`
- new: `sitka-web/src/components/settings/SpendList.tsx`
- modify: `sitka-web/src/api/types.ts` — добавить TypeScript types зеркалящие Haskell
- modify: `sitka-web/src/api/client.ts` — добавить методы для новых endpoints
- modify: `sitka-web/src/AppLayout.tsx` или routing — добавить раздел Settings → Marketing
- new: `sitka-web/src/constants/channels.ts` — константы каналов и SLA

**Задача:**

### UI структура

```
Settings → Marketing
├── Channels & Accounts (список + создание)
├── Campaigns (список + создание + фильтр по аккаунту)
├── Listings (список + создание + фильтр по аккаунту/кампании)
└── Spend Entries (список + форма ручного ввода + фильтр по периоду/каналу)
```

Layout: tabbed interface, каждая tab — отдельный компонент.

### Spend entry form (приоритет)

Форма должна быть максимально быстрой для регулярного ввода:
- Selector канала+аккаунта (default: последний использованный)
- Опциональные campaign/listing (при выборе аккаунта — фильтр того что есть)
- Сумма в рублях (number input с валидацией ≥0)
- Дата (default: сегодня)
- Тип расхода (dropdown с SpendType)
- Notes (textarea, опционально)
- Submit

После submit — форма сбрасывается, показывается toast "Расход сохранён", в списке появляется новая запись вверху.

### Spend list

Таблица с фильтрами:
- Период (preset: сегодня / неделя / месяц / custom)
- Канал
- Источник (ManualEntry / AvitoApiSync)

Колонки: дата, канал, аккаунт, кампания, объявление, сумма, тип, notes, источник записи.

Внизу: total за выбранный период.

### Channel/Campaign/Listing managers

Простые CRUD списки с inline-формами. Без излишеств. Цель — позволить менеджеру создать иерархию за минуты.

**Не трогать:**
- Существующий InboxSidebar
- Существующий DealWorkspace
- Существующий AnalyticsDashboard
- ContextPanel
- Pricing settings panel
- Hooks useAppState, useEventStream

**Проверка:**
- `tsc --noEmit` без ошибок
- `npm run build` проходит
- Manual smoke test:
  1. Создать ChannelAccount "Avito Main"
  2. Создать Campaign "April 2026 Test"
  3. Создать Listing "Sitka Jetstream"
  4. Ввести 3 SpendEntry за разные дни
  5. Список показывает корректно
- E2E test (опционально, если есть время): один happy-path test через Playwright

**Контекст:**
ARCHITECTURE_V2.md раздел 5.4 (UX принципы). Текущий UI устроен через React компоненты + custom hooks. TypeScript types зеркалят Haskell — посмотри как это сделано в существующем `api/types.ts` для Client/Deal. Не используй state management библиотеки — местный state в компонентах + загрузка через api client.

---

## Task 0.5 — Source selector в Deal creation

**Слой:** web

**Зависит от:** Task 0.4 (нужны UI для создания entities) + Task 0.3 (нужен `/source-selector` endpoint)

**Может идти параллельно с Task 0.4 после Task 0.3.**

**Файлы:**
- modify: `sitka-web/src/components/workspace/NewRequestStep.tsx` — добавить selector источника
- modify: `sitka-web/src/api/client.ts` — добавить метод `getSourceSelector()`
- new: `sitka-web/src/components/SourceSelector.tsx` — переиспользуемый компонент
- modify: `sitka-web/src/api/types.ts` — добавить SourceSelectorData type

**Задача:**

При создании новой сделки (NewRequestStep) добавить блок "Источник" с тремя каскадными dropdown-ами:
1. Channel + Account (один dropdown с группировкой)
2. Campaign (опционально, фильтруется по выбранному account)
3. Listing (опционально, фильтруется по account+campaign)

Все три — опциональные. Если ничего не выбрано — Deal создаётся без SourceTouch (например, для исторических сделок).

При submit формы — передать выбранные ID в `CreateDealReq`. Бэкенд автоматически создаёт SourceTouch и привязывает.

Также: показывать предупреждение "Источник не указан" жёлтым алертом, если selector пустой. Не блокировать submit, но обратить внимание.

**Не трогать:**
- Существующий flow Sourcing/Quote/Fulfillment steps
- StageIndicator
- Helpers
- Existing API methods

**Проверка:**
- `tsc --noEmit`
- Manual: создать Deal с указанием source → в БД создаётся SourceTouch с правильными FK
- Manual: создать Deal без source → SourceTouch не создаётся, Deal валидный
- Создать Deal → проверить что в DealDetailResp видна attribution

**Контекст:**
ARCHITECTURE_V2.md раздел 3.2 — модель атрибуции. SourceSelector компонент потом будет переиспользован в Phase 2 для линковки conversations к deals.

---

## Порядок выполнения и параллелизация

```
Task 0.1 (миграции)
    ↓
Task 0.2 (domain + schema)
    ↓
Task 0.3 (API)
    ↓
    ├── Task 0.4 (Settings UI)        ─┐
    └── Task 0.5 (Deal source selector)─┴── могут идти параллельно
```

**Критический путь:** 0.1 → 0.2 → 0.3 → (0.4 или 0.5)

**Реалистичная оценка:** 2-3 недели общим объёмом, в зависимости от выбора инструмента миграций (если новый — +2-3 дня).

---

## Acceptance criteria для Phase 0 целиком

После всех 5 задач должно быть выполнено:

- [ ] Auto-migration отключена, миграции через выбранный инструмент
- [ ] Все новые ADT (Channel, SpendType, ThreadStatus, *Reason) с PersistField и exhaustive serialization
- [ ] DealStatus расширен Qualified + Disqualified
- [ ] StateMachine разрешает только корректные новые переходы
- [ ] Все новые таблицы созданы с FK и индексами
- [ ] API endpoints для CRUD marketing entities работают
- [ ] API возвращает source-selector tree для UI
- [ ] CreateDeal принимает source attribution (опционально)
- [ ] Transition в Disqualified/Rejected/Cancelled требует reason
- [ ] UI Settings → Marketing позволяет управлять channels/campaigns/listings
- [ ] UI позволяет вводить spend entries вручную
- [ ] UI Deal creation имеет source selector
- [ ] Все тесты проходят (старые 33+ + новые ≥40)
- [ ] CI зелёный
- [ ] Документация миграций в `migrations/README.md`

---

## После Phase 0

Когда Phase 0 закрыт:
1. Обновить `project-overlays/sitka-office/CURRENT_STATE.md` — что нового в репо
2. Обновить `project-overlays/sitka-office/KNOWN_ISSUES.md` — какие открытые остались (если что)
3. Обновить `project-overlays/sitka-office/NEXT_ACTIONS.md` — поставить Phase 1 как next
4. Если выявлены новые anti-patterns — записать в `.claude/corrections.md`
5. Готовиться к Phase 1 (Marketing Analytics MVP) — план уже в ARCHITECTURE_V2.md раздел 6
