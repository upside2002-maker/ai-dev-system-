> **ЗАКРЫТА 2026-04-26, см. CURRENT_STATE.md**

# Phase 1 — Marketing Analytics MVP

**Цель:** менеджер открывает Marketing dashboard → видит spend / leads / deals / revenue / margin per channel за выбранный период. Дальше — drill-down до конкретного объявления.

**Длительность:** 2 недели. 4 задачи последовательно с параллелизацией 1.3/1.4 после 1.2.

**Контекст:** проектные правила в `/Users/ilya/Projects/sitka-office/CLAUDE.md`, дизайн в `ai-dev-system/project-overlays/sitka-office/ARCHITECTURE_V2.md` раздел 3.1, foundation заложен в Phase 0.

**Принцип:** engine pure (zero IO), API — тонкая обёртка с fetch+форматирование, UI — отображение без бизнес-логики.

---

## Task 1.1 — Engine.Marketing (pure aggregations)

**Слой:** core (engine)

**Зависит от:** Phase 0 закрыт (есть SpendEntry, SourceTouch, Deal с расширенным DealStatus, ConversationThread, reasons как ADT)

**Файлы:**
- new: `sitka-core/src/Engine/Marketing.hs` — pure агрегаторы
- new: `sitka-core/src/Engine/Marketing/Types.hs` — Period, Dimension, аналитические DTO
- new: `sitka-core/test/EngineMarketingSpec.hs`
- modify: `sitka-core/test/Spec.hs`
- modify: `sitka-core/sitka-core.cabal`

**Задача:**

### Часть A — Базовые типы (`Engine/Marketing/Types.hs`)

```haskell
data Period = Period { periodFrom :: UTCTime, periodTo :: UTCTime }

data Dimension
  = ByChannel              -- группировка по Channel
  | ByChannelAccount       -- группировка по ChannelAccount
  | ByCampaign             -- группировка по Campaign
  | ByListing              -- группировка по Listing
  deriving stock (Show, Eq)

-- Атомарные агрегации
data SpendByDimension = SpendByDimension
  { sbdKey       :: DimensionKey  -- что за измерение (channelId / campaignId / etc)
  , sbdLabel     :: Text           -- человекочитаемое имя
  , sbdAmount    :: RUB
  , sbdEntries   :: Int            -- сколько SpendEntry легло
  }

data DimensionKey
  = DKChannel Channel
  | DKChannelAccount ChannelAccountId
  | DKCampaign CampaignId
  | DKListing ListingId
  | DKUnattributed             -- сделки/расходы без атрибуции
  deriving stock (Show, Eq, Ord)

-- Воронка по измерению
data FunnelByDimension = FunnelByDimension
  { fbdKey         :: DimensionKey
  , fbdLabel       :: Text
  , fbdIncoming    :: Int    -- ConversationThread created в период
  , fbdQualified   :: Int    -- Deal.createdAt с sourceTouch в периоде (status >= Qualified)
  , fbdQuoted      :: Int    -- Deal достиг Quoted в периоде
  , fbdApproved    :: Int    -- Deal достиг Approved в периоде
  , fbdCompleted   :: Int    -- Deal.completedAt в периоде
  , fbdDisqualified :: Int   -- Deal в Disqualified
  , fbdRejected    :: Int    -- Deal в Rejected
  , fbdCancelled   :: Int    -- Deal в Cancelled
  }

-- Юнит-экономика по измерению
data UnitEconomicsByDimension = UnitEconomicsByDimension
  { uebKey            :: DimensionKey
  , uebLabel          :: Text
  , uebSpend          :: RUB
  , uebRevenue        :: RUB           -- сумма actualRevenue completed deals
  , uebCost           :: RUB           -- сумма actualCost completed deals
  , uebGrossMargin    :: RUB           -- revenue - cost
  , uebNetMargin      :: RUB           -- revenue - cost - spend
  , uebCPL            :: Maybe RUB     -- spend / incoming (Nothing если incoming = 0)
  , uebCPD            :: Maybe RUB     -- spend / qualified deals
  , uebCPC            :: Maybe RUB     -- spend / completed
  , uebROMI           :: Maybe Percent -- (revenue - spend) / spend × 100
  , uebROI            :: Maybe Percent -- (revenue - cost - spend) / spend × 100
  }

-- Loss reasons агрегат
data LossReasonsBreakdown = LossReasonsBreakdown
  { lrbDisqualifyReasons :: [(DisqualifyReason, Int)]
  , lrbRejectReasons     :: [(RejectReason, Int)]
  , lrbCancelReasons     :: [(CancelReason, Int)]
  }

-- Топ-листинги (для performance таблицы)
data ListingPerformance = ListingPerformance
  { lpListingId       :: ListingId
  , lpListingTitle    :: Text
  , lpChannelLabel    :: Text
  , lpCampaignLabel   :: Maybe Text
  , lpSpend           :: RUB
  , lpIncoming        :: Int
  , lpDeals           :: Int
  , lpCompleted       :: Int
  , lpRevenue         :: RUB
  , lpROMI            :: Maybe Percent
  }
```

Все типы со `stock` deriving для Show/Eq, FromJSON/ToJSON через Generic для будущей API сериализации.

### Часть B — Pure aggregators (`Engine/Marketing.hs`)

```haskell
-- Главные функции
aggregateSpend
  :: Period
  -> Dimension
  -> [SpendEntry]
  -> [ChannelAccount]
  -> [Campaign]
  -> [Listing]
  -> [SpendByDimension]
-- Группирует SpendEntry по выбранному Dimension в периоде. 
-- Лейблы достаются из соответствующих lookup-таблиц.

aggregateFunnel
  :: Period
  -> Dimension
  -> [ConversationThread]
  -> [Deal]
  -> [SourceTouch]
  -> [ChannelAccount]
  -> [Campaign]
  -> [Listing]
  -> [FunnelByDimension]
-- Считает воронку по измерению. ConversationThread считается lead-ом.
-- Deal с sourceTouch.channelAccountId группируется соответственно.

aggregateUnitEconomics
  :: Period
  -> Dimension
  -> [SpendEntry]
  -> [Deal]
  -> [SourceTouch]
  -> [ChannelAccount]
  -> [Campaign]
  -> [Listing]
  -> [UnitEconomicsByDimension]
-- Объединяет spend + completed deals → CPL, CPD, CPC, ROMI, ROI.

aggregateLossReasons
  :: Period
  -> Maybe DimensionKey   -- если задан — фильтр по конкретному измерению
  -> [Deal]
  -> [SourceTouch]
  -> LossReasonsBreakdown
-- Для каждого reason-типа считает количество. Если DimensionKey задан — 
-- фильтрует только deals из этого измерения.

topListings
  :: Period
  -> Int                   -- top N
  -> [SpendEntry]
  -> [Deal]
  -> [SourceTouch]
  -> [Listing]
  -> [ChannelAccount]
  -> [Campaign]
  -> [ListingPerformance]
-- Сортировка по ROMI desc (с учётом completed deals и spend).

-- Хелперы
inPeriod :: Period -> UTCTime -> Bool
safeDivide :: RUB -> Int -> Maybe RUB  -- Nothing if denominator = 0
safeROI :: RUB -> RUB -> RUB -> Maybe Percent
```

### Часть C — Тесты (≥40 тестов)

Покрытие:
- **Happy path:** заданы spend + deals + threads → правильные числа
- **Edge cases:**
  - Пустой период (нет данных) → нули
  - Spend есть, deals нет → ROI = -100%, CPL/CPD = Nothing
  - Deals есть, spend нет → CPL/CPD = Nothing (a not zero — это разные смыслы!)
  - Все deals Disqualified → completed = 0, lossReasons заполнены
  - Один deal с двумя SourceTouch (теоретически невозможно, но защита) → берётся первый
- **Property tests (QuickCheck):**
  - `sum (sbdAmount <$> aggregateSpend p ByChannel spend ...) == sum (spendAmount <$> filterByPeriod p spend)` — total spend invariant
  - `fbdCompleted <= fbdApproved <= fbdQuoted <= fbdQualified <= fbdIncoming` — funnel monotonicity
  - `aggregateLossReasons` — sum of buckets ≤ total non-completed deals
- **Period boundary tests:** UTC midnight inclusion/exclusion корректно
- **Unattributed bucket:** deals без sourceTouchId попадают в `DKUnattributed`, не теряются

**Не трогать:**
- Domain types (Phase 0 заморожены)
- API endpoints (Task 1.2)
- Pricing engine (Engine.Pricing.hs)
- State machine
- Services
- Frontend

**Проверка:**
- `cabal build` строго `-Werror`
- `cabal test` — все 202 + новые ≥40 проходят
- Property tests генерируют 100+ кейсов на каждый property
- Engine модули НЕ импортируют ничего из `Db.*` или `Api.*` — только из `Domain.*` и стандартных библиотек

**Контекст:**
ARCHITECTURE_V2.md раздел 3.1-3.2 — модель данных. Все агрегаторы pure: на вход списки, на выход агрегаты. IO остаётся в API layer (Task 1.2). Это позволит тестировать без БД.

---

## Task 1.2 — API endpoints для marketing analytics

**Слой:** core (api)

**Зависит от:** Task 1.1

**Файлы:**
- modify: `sitka-core/src/Api/Marketing.hs` — добавить analytics endpoints
- modify: `sitka-core/src/Api/Types.hs` — DTO для analytics responses
- new: `sitka-core/test/ApiMarketingAnalyticsSpec.hs`

**Задача:**

### Endpoints (5 новых)

| Метод | Путь | Возвращает |
|-------|------|------------|
| GET | `/api/marketing/dashboard?from=&to=&channel=` | Сводка для главного экрана: 4 KPI + funnel + top-listings + loss-reasons (одним ответом) |
| GET | `/api/marketing/funnel?from=&to=&groupBy=channel\|account\|campaign\|listing&filter=...` | `[FunnelByDimension]` |
| GET | `/api/marketing/economics?from=&to=&groupBy=...&filter=...` | `[UnitEconomicsByDimension]` |
| GET | `/api/marketing/listings?from=&to=&top=20` | `[ListingPerformance]` |
| GET | `/api/marketing/losses?from=&to=&filter=...` | `LossReasonsBreakdown` |

### Параметры

- `from`, `to` — обязательные, ISO 8601 даты или Unix timestamp
- `groupBy` — опциональный, default `channel`
- `filter` — опциональный, формат `channelAccountId:5` / `campaignId:10` / `listingId:100` для фильтра внутри одного измерения
- `channel` — для dashboard endpoint, опциональный quick filter

### Реализация

Все endpoints следуют паттерну:
1. Парсят период (Validation 400 если from > to или период > 1 года)
2. Fetch данных через `runDb`:
   - SpendEntry where date в периоде
   - Deal where createdAt OR completedAt в периоде
   - ConversationThread where createdAt в периоде
   - SourceTouch где привязан к этим Deal
   - Lookup tables (ChannelAccount, Campaign, Listing) — все, не фильтр
3. Передают в `Engine.Marketing` функции
4. Возвращают результат как JSON

### Кеширование

Не делаем сейчас. Если dashboard будет тормозить (>2s) — добавим Redis кеш на 5 минут. Pre-flight проверка: за месяц данных меньше ~500 deals и ~5K spend entries. Это легко агрегируется без кеша.

### Dashboard endpoint shape

```haskell
data MarketingDashboardResp = MarketingDashboardResp
  { mdrPeriod         :: Period
  , mdrTotalSpend     :: RUB
  , mdrTotalLeads     :: Int
  , mdrTotalDeals     :: Int      -- созданных в периоде
  , mdrTotalCompleted :: Int
  , mdrTotalRevenue   :: RUB
  , mdrTotalMargin    :: RUB      -- gross
  , mdrTotalNetMargin :: RUB      -- gross - spend
  , mdrAvgCPL         :: Maybe RUB
  , mdrAvgCPD         :: Maybe RUB
  , mdrAvgROMI        :: Maybe Percent
  , mdrFunnelByChannel :: [FunnelByDimension]
  , mdrTopListings    :: [ListingPerformance]
  , mdrLossReasons    :: LossReasonsBreakdown
  }
```

Один запрос — вся главная страница. UI не делает 5 параллельных fetch.

### Audit

Аналитические endpoints — read-only. Не пишут в audit log. Это OK.

### Тесты (≥15)

- Каждый endpoint happy path
- Validation: from > to → 400, период > 1 года → 400
- Period parsing: Unix timestamp + ISO 8601
- Filter parameter: invalid channelAccountId → 400 или пустой результат (выбери)
- Empty period (нет данных) → возвращает структуру с нулями, не 404

**Не трогать:**
- Engine (Task 1.1 заморожен)
- Существующие Marketing endpoints (CRUD из Phase 0)
- Conversations, Deals API
- Frontend

**Проверка:**
- `cabal build -Werror`
- `cabal test` — 240+ тестов проходят
- Manual smoke: создать ChannelAccount → SpendEntry → Deal с sourceTouch → completedAt now → curl `/api/marketing/dashboard?from=2026-04-01&to=2026-04-30` → видны числа

**Контекст:**
Engine pure, API только проксирует. Используй `AppM` хелперы из `Api/AppM.hs`. DTO в `Api/Types.hs` — отделены от domain types (corrections.md правило).

---

## Task 1.3 — Web Marketing Dashboard

**Слой:** web

**Зависит от:** Task 1.2

**Может идти параллельно с Task 1.4 после 1.2.**

**Файлы:**
- new: `sitka-web/src/components/marketing/MarketingDashboard.tsx` — главный экран
- new: `sitka-web/src/components/marketing/PeriodSelector.tsx`
- new: `sitka-web/src/components/marketing/KpiCards.tsx`
- new: `sitka-web/src/components/marketing/FunnelChart.tsx`
- new: `sitka-web/src/components/marketing/TopListingsTable.tsx`
- new: `sitka-web/src/components/marketing/LossReasonsChart.tsx`
- modify: `sitka-web/src/api/types.ts` — TypeScript types зеркалят Haskell DTO
- modify: `sitka-web/src/api/client.ts` — методы для analytics endpoints
- modify: `sitka-web/src/AppLayout.tsx` или routing — раздел Marketing
- modify: `sitka-web/package.json` — добавить chart библиотеку

**Задача:**

### Выбор chart библиотеки

**Рекомендую Recharts** (`recharts` npm).

Аргументация:
- Декларативный React API — компоненты как у любых других React-элементов
- Lightweight (~90KB gzipped vs Chart.js ~150KB)
- TypeScript types из коробки
- Покрывает все нужные типы: bar, pie, line, KPI cards (через Custom)
- Активно поддерживается

Альтернативы (если не нравится):
- Chart.js + react-chartjs-2 — старее, более сложный API
- Visx — мощнее но низкоуровневый, overkill для дашборда

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ Marketing                                    [Period: Last 30d ▾] │
├──────────────────────────────────────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │ Spend   │ │ Leads   │ │ Deals   │ │ Revenue │ │ Margin  │    │
│ │ ₽X      │ │ N       │ │ N       │ │ ₽X      │ │ ₽X      │    │
│ │         │ │ CPL ₽X  │ │ CPD ₽X  │ │         │ │ ROMI X% │    │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
├──────────────────────────────────────────────────────────────────┤
│ Funnel by channel                                                │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │  Avito   [████████████████████████████████]  50%          │   │
│ │  TG      [████████]  15%                                  │   │
│ │  WA      [████]  8%                                       │   │
│ │  Other   [██]  3%                                         │   │
│ │                                                            │   │
│ │  Stages: Incoming | Qualified | Quoted | Approved | Done  │   │
│ └──────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│ Top performing listings                                          │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ Listing             | Spend  | Leads | Deals | Done | ROMI│   │
│ │ Hudson Bib Marsh L  | 5 200₽ |   23  |   8   |  3   | 145%│   │
│ │ Mountain Jacket XL  | 3 100₽ |   15  |   5   |  2   | 89% │   │
│ │ ...                                                        │   │
│ └──────────────────────────────────────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│ Loss reasons                                                     │
│ ┌────────────────────────┐  ┌────────────────────────┐         │
│ │  Disqualify reasons    │  │  Reject + Cancel       │         │
│ │  [pie chart]           │  │  [pie chart]           │         │
│ └────────────────────────┘  └────────────────────────┘         │
└──────────────────────────────────────────────────────────────────┘
```

### KPI Cards

5 карточек в ряд (responsive: на мобильном — 2 в ряд):
- **Spend** — общий spend за период, иконка ↑↓ vs прошлый период (опционально, если будет время)
- **Leads** — incoming conversations + ниже мелким шрифтом "CPL: ₽X"
- **Deals** — qualified deals + "CPD: ₽X"
- **Revenue** — gross revenue
- **Margin** — net margin (revenue - cost - spend) + "ROMI: X%"

Цветовая индикация:
- ROMI > 50% → зелёный
- ROMI 0-50% → жёлтый
- ROMI < 0% → красный

### Funnel Chart

Stacked horizontal bar per channel. По оси X — % от incoming. Каждая полоса разбита на сегменты (Qualified / Quoted / Approved / Completed / Lost).

При наведении — tooltip с абсолютными числами.

### Top Listings Table

Sortable. По умолчанию sort by ROMI desc. Колонки: Listing | Channel/Campaign | Spend | Leads | Deals | Completed | Revenue | ROMI.

При клике на listing → переход на drill-down (Task 1.4).

### Loss Reasons

Два pie chart рядом:
1. Disqualify reasons (распределение по WrongProduct / WrongBudget / etc)
2. Reject + Cancel reasons (объединённые, с указанием категории)

Tagged JSON из API → красиво отрендерить human-readable labels (через mapping в `constants/reasons.ts`).

### Period Selector

Dropdown с пресетами:
- Today
- Yesterday
- This week
- Last 7 days
- This month
- Last 30 days
- This quarter
- Last quarter
- Custom (с date pickers)

При смене → re-fetch данных, lock UI с loading spinner.

### Loading & Empty states

- Loading: skeleton placeholders для каждого блока
- Empty period (нет данных): "За выбранный период данных нет. Попробуйте расширить период или проверить настройки атрибуции в Settings → Marketing."
- Error: "Не удалось загрузить аналитику. Подробнее в консоли."

### Routing

В `AppLayout.tsx` или роутере: добавить пункт "Marketing" в главную навигацию рядом с существующими. URL: `/marketing` или `/dashboard/marketing`.

**Не трогать:**
- Settings → Marketing (это Task 0.4 — управление сущностями, не аналитика)
- Существующий Workspace
- InboxSidebar
- ContextPanel
- DealStatsWidget (его потом заменим, но не сейчас)

**Проверка:**
- `tsc --noEmit` без ошибок
- `npm run build` проходит
- Manual smoke:
  1. Создать ChannelAccount + 2 SpendEntry + 3 Deal с разными статусами через UI Settings
  2. Открыть Marketing dashboard
  3. Проверить что 5 KPI карточек показывают непустые значения
  4. Проверить funnel chart рендерится
  5. Проверить sortable таблицу top listings
  6. Сменить период — данные перезагружаются
- Recharts type imports корректные

**Контекст:**
ARCHITECTURE_V2.md раздел 5.4 — UX концепция. Дашборд должен быть "не перегружен, информативен, ориентирован на next best action". Цвета и иконки — не яркие, спокойные. Главное — числа и тренды видны с первого взгляда.

---

## Task 1.4 — Drill-down navigation

**Слой:** web

**Зависит от:** Task 1.2

**Может идти параллельно с Task 1.3.**

**Файлы:**
- new: `sitka-web/src/components/marketing/ChannelDrillDown.tsx`
- new: `sitka-web/src/components/marketing/CampaignDrillDown.tsx`
- new: `sitka-web/src/components/marketing/ListingDrillDown.tsx`
- modify: routing — добавить URL для drill-down уровней
- modify: `sitka-web/src/api/client.ts` — методы с фильтрами

**Задача:**

### Уровни drill-down

```
Marketing Dashboard (агрегаты по каналам)
    ↓ клик на Avito
Channel Drill-down: Avito
  - все аккаунты этого канала
  - funnel + economics для каждого
  - top campaigns
    ↓ клик на campaign
Campaign Drill-down
  - все listings этой кампании
  - performance каждого
  - loss reasons фильтр по этой campaign
    ↓ клик на listing
Listing Drill-down
  - детальные метрики этого listing
  - список conversations из него
  - список deals из него (с привязкой к sourceTouch)
  - timeline активности
```

### Каждый drill-down

- Использует те же endpoints из Task 1.2 с параметром `filter=channelAccountId:N` или `campaignId:N` или `listingId:N`
- Breadcrumb навигация: `Marketing → Avito Main → Apr 2026 Campaign → Hudson Bib Marsh`
- Кнопка "Назад" возвращает на уровень выше
- Period selector сохраняется при переходах

### Listing Drill-down — особое

Самый детальный уровень. Помимо метрик показывает:
- Список conversations (link на Inbox в Phase 2, пока — текстовый список)
- Список deals (link на Deal Workspace)
- Timeline: когда listing был создан, когда последняя сделка, когда последний spend

### URL routing

- `/marketing` — главная
- `/marketing/channels/:channelAccountId` — drill-down аккаунта
- `/marketing/campaigns/:campaignId` — drill-down кампании
- `/marketing/listings/:listingId` — drill-down листинга

URL должен быть shareable — открыл ссылку, попал точно в тот же view.

**Не трогать:**
- Marketing Dashboard главную (Task 1.3 параллельно)
- API (всё что нужно — уже в 1.2)

**Проверка:**
- `tsc --noEmit`
- Manual: на главном дашборде кликнуть на канал → попасть в channel drill-down → кликнуть на кампанию → попасть в campaign drill-down → кликнуть на listing → попасть в listing drill-down. Каждый уровень показывает свои данные.
- URL копируется и открывается напрямую → попадает в тот же view
- Breadcrumb навигация работает в обе стороны

**Контекст:**
Цель drill-down — позволить менеджеру за 3 клика дойти от "общая картина" до "вот этот конкретный listing работает плохо". Не перегружать каждый уровень — на каждом показывать только то что нельзя свернуть в верхний уровень.

---

## Порядок выполнения

```
Task 1.1 (Engine — pure aggregations)
    ↓
Task 1.2 (API endpoints)
    ↓
    ├── Task 1.3 (Marketing Dashboard)        ─┐
    └── Task 1.4 (Drill-down navigation)      ─┴── параллельно
```

**Критический путь:** 1.1 → 1.2 → (1.3 или 1.4)

**Реалистичная оценка:** 2 недели общим объёмом.
- 1.1: 3-4 дня
- 1.2: 2-3 дня
- 1.3: 4-5 дней (с настройкой Recharts)
- 1.4: 2-3 дня

---

## Acceptance criteria для Phase 1 целиком

- [ ] Engine.Marketing — pure функции, ≥40 тестов, property-based для invariants
- [ ] 5 новых endpoints с валидацией параметров
- [ ] Marketing Dashboard с 5 KPI cards, funnel chart, top listings, loss reasons
- [ ] Drill-down 3 уровня: channel → campaign → listing
- [ ] Period selector с пресетами
- [ ] URL routing для всех drill-down уровней
- [ ] Empty/loading/error states обработаны
- [ ] Все тесты проходят (Phase 0 + новые)
- [ ] Manual smoke test полностью проходит (создание данных → отображение → drill-down)
- [ ] CI зелёный
- [ ] Recharts добавлен в dependencies

---

## После Phase 1

Когда закроется:
1. Обновить `CURRENT_STATE.md` — что новое в репо
2. Обновить `KNOWN_ISSUES.md` если нашли новые
3. Обновить `NEXT_ACTIONS.md` — Phase 2 как next priority
4. Demo для пользователя — открыть dashboard на реальных данных (если уже накопились)

Phase 2 — Avito Inbox + Conversations Architecture. План в `ARCHITECTURE_V2.md` раздел 6.

---

## Технические заметки

### Performance

На текущем масштабе (≤500 deals, ≤5K spend entries в месяц) запросы должны выполняться <500ms без кеша. Если медленнее:
- Добавить индексы (запиши issue для проверки)
- Подключить Redis кеш на dashboard endpoint (5 минут TTL)
- Materialized view для часто запрашиваемых агрегатов (если данных станет много)

### Future-proofing

Engine.Marketing не привязан к источникам данных. Когда появится `marketing_event` таблица (Issue #10) — функции получат дополнительные параметры, но shape агрегатов не изменится.

Когда появится multi-touch attribution — функции получат опциональный `AttributionStrategy` параметр (FirstTouch | LastTouch | Linear | TimeDecay). Сейчас всё считается как FirstTouch (по `dealSourceTouchId`).

### Что НЕ делаем в Phase 1

- A/B testing analytics — нет данных, не нужно
- Cohort analysis — преждевременно
- Forecasting / ML — нет
- Sankey diagrams для funnel — простой stacked bar достаточно
- Export в Excel/PDF — будем добавлять когда попросят
- Email/Slack отчёты — не сейчас
- Real-time updates — рефреш по запросу пользователя достаточно
