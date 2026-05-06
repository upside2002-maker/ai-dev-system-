# Sitka Office — Architecture v2

Дата: 2026-04-16

Архитектурно-продуктовый документ для следующей итерации.
Не план рефакторинга — план **расширения foundation** под маркетинговую аналитику, омниканальные коммуникации и сохранение знаний.

---

## 1. Refined product framing

### Что меняется в бизнесе

С нуля запускается рекламная кампания. Бюджет 100 USD/день и выше.
Конверсии происходят в диалогах: Avito chat, WhatsApp, Telegram.
Без правильной структуры данных через 2 месяца восстановить картину "какое объявление → какая покупка" станет невозможно.

### Что это значит для софта

Софт сейчас — не "решение bottleneck бизнеса". Bottleneck в другой плоскости.

Софт = **операционная и аналитическая база**, которую нужно правильно заложить ДО того, как поток данных станет большим.

Принцип: **foundation сейчас, фичи постепенно**.

### Три ключевые foundation, которые нужно заложить с дня 1

1. **Каноническая модель маркетинговой экономики** — Channel → Account → Campaign → Listing → Spend
2. **Атрибуционная цепочка** — Listing → Conversation → Client → Deal → Outcome
3. **Conversation as first-class citizen** — диалог не теряется между Avito/WA/TG, привязан к источнику и сделке

Knowledge/Decisions hub — отдельный, более простой блок, не связанный с экономикой. Решается через расширение Telegram бота.

---

## 2. Current state assessment

### Что уже работает и используется

| Слой | Артефакт | Состояние |
|------|----------|-----------|
| Core | Domain types (USD, RUB, Percent, ExchangeRate) | Production-ready |
| Core | DealStatus + StateMachine (13 states, 12 transitions) | Production-ready |
| Core | Pricing engine (4 pure functions) | Production-ready |
| Core | Risk engine | Production-ready |
| Core | Event log (DealEvent + Actor + EventType) | Готов к расширению |
| Core | AppM monad + helpers | Готов к расширению |
| Core | API: Clients, Deals, Quotes | Готов к расширению |
| Services | Avito parser | Расширяется до chat sync |
| Services | Telegram bot (5 модулей, 11 команд) | Расширяется до knowledge capture |
| Services | Notification system | Готова |
| Web | InboxSidebar / DealWorkspace / ContextPanel | Эволюционирует |
| Web | AnalyticsDashboard (deal-level only) | Расширяется до marketing |

### Ключевые пробелы под новую итерацию

| Пробел | Critical | Где будет |
|--------|----------|-----------|
| Нет модели MarketingChannel/Account/Campaign/Listing | Yes | Core |
| Нет SpendEntry — расходы нигде не учитываются канонически | Yes | Core + Services (sync) |
| Нет SourceTouch — атрибуция листинг→сделка не сохраняется | Yes | Core |
| ConversationThread как отдельная сущность отсутствует | Yes | Core (метаданные) + Services (тело) |
| Нет provider abstraction для разных каналов (Avito/TG/WA) | Yes | Services |
| Нет Note/Decision модели для knowledge capture | Medium | Core (минимум) + Services (TG bot) |
| Marketing analytics endpoint и UI | Yes | Core + Web |
| Inbox с реальными диалогами Avito | Yes | Services + Web |

### Что НЕ нужно ломать

- Существующий Deal lifecycle (state machine остаётся как есть)
- Существующий Pricing engine
- Существующий Telegram bot (только расширяется)
- Существующий step-based Workspace UI

---

## 3. Proposed target architecture

### 3.1 Marketing Data Model (в Haskell Core)

#### Channel — внешний канал привлечения

```haskell
data Channel
  = AvitoChannel
  | TelegramChannel
  | WhatsAppChannel
  | DirectChannel       -- "пришёл сам"
  | ReferralChannel     -- по рекомендации
  | OtherChannel Text

-- PersistField, JSON, HttpApiData — exhaustive
```

#### ChannelAccount — конкретный аккаунт/кабинет в канале

Один Avito аккаунт = одна запись. Если в будущем добавится второй Avito аккаунт — это отдельная запись.

```haskell
ChannelAccount
  channel              Channel
  accountName          Text         -- человекочитаемое имя
  externalAccountId    Text Maybe   -- Avito user_id, TG @username, WA номер
  isActive             Bool
  createdAt            UTCTime
  notes                Text Maybe
```

#### Campaign — рекламная кампания

Опциональная группировка spend и listings. Может быть простая — "Apr 2026 Sitka Jetstream", может быть детальная с бюджетом и периодом.

```haskell
Campaign
  channelAccountId     ChannelAccountId
  name                 Text
  periodStart          Day
  periodEnd            Day Maybe       -- nullable если ongoing
  plannedBudget        RUB Maybe
  goal                 Text Maybe      -- "тест нового сегмента", "распродажа"
  notes                Text Maybe
  createdAt            UTCTime
```

#### Listing — конкретное объявление/реклама

Для Avito — конкретное объявление с item_id. Для Telegram/WA — может быть post или ссылка.

```haskell
Listing
  channelAccountId     ChannelAccountId
  campaignId           CampaignId Maybe
  externalListingId    Text             -- Avito item_id
  title                Text
  url                  Text Maybe
  publishedAt          UTCTime Maybe
  archivedAt           UTCTime Maybe
  meta                 Value Maybe      -- JSON для provider-specific полей
  createdAt            UTCTime
```

#### SpendEntry — атомарная единица расходов

Одна запись = один расход в один день.
Может быть с разной гранулярностью: на Listing, на Campaign, на Account.
Если на Listing → автоматически приписывается к Campaign и Account.

```haskell
SpendEntry
  channelAccountId     ChannelAccountId
  campaignId           CampaignId Maybe
  listingId            ListingId Maybe
  amount               RUB
  spendDate            Day                       -- день, не timestamp
  spendType            SpendType                 -- Promotion | Boost | Subscription | OneTime | Other
  source               SpendSource               -- ManualEntry | AvitoApiSync | CsvImport
  externalRef          Text Maybe                -- номер счёта / транзакции
  notes                Text Maybe
  createdAt            UTCTime

data SpendType
  = Promotion          -- продвижение объявления
  | Boost              -- разовый буст
  | Subscription       -- подписка на тариф
  | OneTime            -- разовая оплата
  | Other Text

data SpendSource
  = ManualEntry        -- менеджер ввёл
  | AvitoApiSync       -- sync из Avito API
  | CsvImport          -- импортировали выгрузку
```

**Почему именно так:**
- День, не timestamp — Avito выдаёт ежедневный spend
- Многоуровневая привязка (account/campaign/listing) — Avito не всегда даёт листинг-уровень
- `source` поле — критично знать, откуда данные, для контроля точности

### 3.2 Attribution Model

#### SourceTouch — момент касания источника с воронкой

```haskell
SourceTouch
  channelAccountId     ChannelAccountId
  listingId            ListingId Maybe          -- если знаем конкретно объявление
  campaignId           CampaignId Maybe         -- если знаем кампанию
  conversationId       ConversationThreadId Maybe
  clientId             ClientId Maybe
  dealId               DealId Maybe
  touchType            TouchType                -- FirstContact | Reengagement | DirectInquiry
  touchedAt            UTCTime                  -- когда произошло касание
  createdAt            UTCTime

data TouchType
  = FirstContact       -- первый контакт от этого клиента
  | Reengagement       -- вернулся после паузы
  | DirectInquiry      -- зашёл напрямую в существующую сделку
```

**Single-touch attribution** (на старте):
- Первый SourceTouch для пары (clientId, время) = источник сделки
- Это поле в Deal: `sourceTouchId :: Maybe SourceTouchId`

**Возможность роста до multi-touch:**
- Все SourceTouches сохраняются
- В будущем можно посчитать веса (linear, time-decay, position-based) поверх существующей таблицы
- Не меняя schema

#### Атрибуционная цепочка целиком

```
[Channel + Account + Campaign + Listing] → SpendEntry (сколько потратили)
                ↓
        SourceTouch (кто-то пришёл)
                ↓
        ConversationThread (диалог)
                ↓
        Client (квалифицировался)
                ↓
        Deal (стал сделкой)
                ↓
        Quote → Approved → Completed (получили деньги)
```

Каждый этап имеет timestamp и foreign key назад. Можно построить любой funnel срез одним SQL.

### 3.3 Conversations Architecture

#### Принцип: метаданные в Core, тело в Services

**В Core (Haskell):**

```haskell
ConversationThread
  channelAccountId     ChannelAccountId
  externalThreadId     Text                -- chat id в системе провайдера
  externalParticipantId Text Maybe         -- кто на той стороне (provider user id)
  clientId             ClientId Maybe      -- nullable до квалификации
  dealId               DealId Maybe        -- nullable до создания сделки
  listingId            ListingId Maybe     -- если пришёл из листинга
  sourceTouchId        SourceTouchId Maybe
  status               ThreadStatus
  lastMessageAt        UTCTime
  lastMessageDirection MessageDirection    -- Incoming | Outgoing
  unreadCount          Int                 -- денормализовано для inbox UI
  slaDeadline          UTCTime Maybe
  assignedManagerId    Text Maybe
  createdAt            UTCTime
  closedAt             UTCTime Maybe

data ThreadStatus
  = ThreadNew           -- ещё не открыли
  | ThreadActive        -- в работе
  | ThreadAwaitingReply -- ждём клиента
  | ThreadAwaitingUs    -- клиент ждёт нас (KPI alert)
  | ThreadClosed        -- закрыли (с deal или без)
  | ThreadArchived      -- скрыто

data MessageDirection = Incoming | Outgoing
```

**В Services (Python + Postgres):**

Отдельная таблица `conversation_messages`:
```sql
conversation_messages (
  id BIGSERIAL,
  thread_external_id TEXT,         -- ссылка на ConversationThread.externalThreadId
  channel_account_id INT,           -- денормализовано для индексации
  external_message_id TEXT,
  direction TEXT,                   -- 'in' | 'out'
  body TEXT,
  attachments JSONB,
  raw_payload JSONB,                -- полный payload от провайдера
  sent_at TIMESTAMPTZ,
  received_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  PRIMARY KEY (id),
  INDEX (thread_external_id, sent_at)
)
```

**Почему такое разделение:**
- Core отвечает на бизнес-вопросы: какие треды активны, какой клиент к какому треду привязан, какая атрибуция
- Services отвечает на технический вопрос: вот тело сообщения, вот вложение
- Если меняется тело сообщения — это не бизнес-событие
- Если меняется привязка треда к Deal — это бизнес-событие, оно в Core с полным аудитом

#### Provider abstraction в Services

```python
# sitka-services/app/conversations/
class ConversationProvider(Protocol):
    async def list_threads(self, since: datetime) -> list[ThreadDTO]: ...
    async def get_thread(self, external_id: str) -> ThreadDTO: ...
    async def list_messages(self, thread_id: str, since: datetime) -> list[MessageDTO]: ...
    async def send_message(self, thread_id: str, body: str) -> MessageDTO: ...
    async def mark_read(self, thread_id: str, message_id: str) -> None: ...

# Реализации:
class AvitoProvider(ConversationProvider): ...
class TelegramProvider(ConversationProvider): ...   # уже частично есть в bot
class WhatsAppProvider(ConversationProvider): ...   # позже
```

Всё provider-specific (auth, retries, rate limits, payload normalization) — внутри adapter.
Core видит унифицированный интерфейс.

### 3.4 Knowledge / Decisions Hub

**Принцип:** Note/Decision — это **операционные данные, не бизнес-инварианты**. Место — Services, не Core.

**Аналогия с conversations:**
- ConversationThread (метаданные, привязка к Deal) → Core ✓
- ConversationMessage (тело сообщения) → Services ✓
- Точно так же: Note (тело, теги, автор) → Services. В Core максимум — audit-маркер `NoteAdded` в EventType (он уже есть).

**Почему НЕ в Core:**
- У Note нет бизнес-инвариантов (не считаются деньги, не валидируются переходы статусов, не аффектит рентабельность)
- Type safety на уровне Haskell не нужна — это плоский текст с автором и тегами
- Свобода добавлять новые поля (теги, attachments, summary) без миграций Core
- Поиск (FTS) и индексация — настраиваются в Services без касания Core
- Если завтра прикрутим ИИ-суммаризацию — это в Services, не в Core

#### В Services — данные и логика

Таблица `notes` в Postgres (та же БД, что и `conversation_messages`):

```sql
notes (
  id BIGSERIAL PRIMARY KEY,
  body TEXT NOT NULL,
  author_tg_id BIGINT,
  author_name TEXT,
  source TEXT NOT NULL,                  -- 'manual' | 'telegram_command' | 'telegram_reaction'
  tags JSONB,                             -- ['idea', 'pricing', 'sitka']
  attached_entity_type TEXT,              -- 'deal' | 'client' | 'listing' | 'campaign' | NULL
  attached_entity_id BIGINT,              -- FK в core (логическая, не физическая)
  parent_note_id BIGINT REFERENCES notes(id),  -- для тредов
  external_message_id TEXT,               -- TG message id для линка обратно
  external_chat_id BIGINT,                -- TG chat id
  created_at TIMESTAMPTZ DEFAULT now(),
  INDEX (attached_entity_type, attached_entity_id),
  INDEX (created_at DESC),
  INDEX USING gin (tags)
)
```

Таблица `decisions` (похожая, но со своим lifecycle):

```sql
decisions (
  id BIGSERIAL PRIMARY KEY,
  topic TEXT NOT NULL,
  context TEXT,
  outcome TEXT,
  status TEXT NOT NULL,                   -- 'proposed' | 'accepted' | 'implemented' | 'revised' | 'rejected'
  decided_by JSONB,                       -- ["Илья", "Артём"]
  related_entity_type TEXT,
  related_entity_id BIGINT,
  related_note_ids JSONB,                 -- список связанных note id
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  INDEX (status, created_at DESC)
)
```

API в `sitka-services/app/knowledge/`:

```python
# FastAPI endpoints (НЕ Servant — это в services!)
GET  /api/notes?entity=deal:123&tag=pricing&author=...&from=...
POST /api/notes
GET  /api/decisions?status=proposed
POST /api/decisions
PATCH /api/decisions/:id
```

#### В Core — только маркер событий

```haskell
-- В Domain.Event (это уже есть!)
data EventType = ... | NoteAdded
```

Когда Telegram bot создаёт note привязанную к Deal, он:
1. POST в services API → notes таблица обновлена
2. POST в core `/api/deals/:id/events` с `eventType = NoteAdded`, `payload = {"noteId": 123, "source": "telegram"}` — для audit trail сделки

Это даёт consistency: в DealEvent логе видно "к этой сделке добавили заметку", детали в Services.

#### В Services — Telegram capture

Расширение существующего Telegram bot:

| Команда | Действие |
|---------|----------|
| `/note <текст>` | Создать standalone note |
| `/note @deal:123 <текст>` | Note прикреплённая к сделке |
| `/save` (как реплай на сообщение) | Сохранить процитированное сообщение как note |
| `/decide <topic>` | Начать создание Decision (conversation flow) |
| `/decisions` | Список открытых decisions |
| `/notes [filter]` | Поиск по notes |

Для общего чата команды отрабатывают только если автор в whitelist (managers).

Альтернативно (умнее): бот в общем чате реагирует на сообщения с эмодзи 📌 — автоматически сохраняет процитированное сообщение.

#### В Web — простой UI

- Раздел "Knowledge" с tabs: Notes | Decisions
- Фильтры: по тегу, по entity, по автору, по периоду
- Поиск по body
- Каждая сущность (Deal/Client/Campaign/Listing) имеет свой Notes tab в ContextPanel

**Никакого "Growth Lab" со встроенными A/B тестами и статистикой.** Это knowledge base + decision log. Простой и полезный.

---

## 4. Lead vs DealStatus extension — DECISION

**Решение: расширить DealStatus + использовать ConversationThread как pre-deal lead.**

Аргументация:

### Почему не отдельный Lead entity

1. **Дублирование state machine.** У Lead будут свои переходы (Created → Qualified → Disqualified → Converted to Deal), у Deal свои. Поддерживать две параллельные SM = удвоение тестов и багов.
2. **Дублирование UI.** Workspace для Lead vs Workspace для Deal — переключение контекста для менеджера.
3. **Артефактные поля.** Lead имеет 80% полей Deal (client, source, notes, manager). Дублирование схемы.
4. **Историческая консистентность.** При переходе Lead → Deal что делать с историей? Копировать события? Линковать? Это дополнительная сложность ради эстетики.

### Почему ConversationThread = операционный pre-deal объект

В реальности **лид — это диалог, который не стал сделкой**. Не отдельная сущность.

- Пришёл диалог из Avito → ConversationThread создан
- Пока не привязан к Deal → это лид в воронке
- Менеджер квалифицирует через действия: "создать сделку" / "не наш клиент"
- Если "не наш клиент" → ConversationThread.status = Closed, dealId = NULL, в воронке считается как "lost lead"
- Если "наш" → создаётся Deal, ConversationThread.dealId привязывается

### Расширение DealStatus

```haskell
data DealStatus
  = New              -- было: заявка поступила
  | Qualified        -- НОВОЕ: подтверждённый интерес, готовится sourcing
  | Sourcing         -- было
  | Quoted           -- было
  ...
  | Disqualified     -- НОВОЕ: квалифицировали как "не наш" после разговора
                     --        (терминал, отдельно от Rejected/Cancelled)
```

**Disqualified** — это терминал для случая "не наш клиент с самого начала", в отличие от Rejected (отказался от КП) и Cancelled (отменили в процессе). Разделение нужно для аналитики.

### Reasons (структурированные причины)

Расширить с Text на ADT:

```haskell
data DisqualifyReason
  = WrongProduct          -- спрашивал не то что мы возим
  | WrongBudget           -- не тянет по цене
  | TimeNotRight          -- слишком долго ждать
  | JustBrowsing          -- просто интересовался
  | Spam                  -- мусор
  | OtherReason Text

data RejectReason
  = PriceTooHigh
  | DeliveryTooLong
  | FoundCheaper
  | ChangedMind
  | NoResponse           -- замолчал после КП
  | OtherReject Text

data CancelReason
  = OutOfStock           -- товар пропал
  | PriceWentUp          -- цена скакнула
  | LogisticIssue        -- проблема с доставкой
  | ClientChanged        -- клиент передумал в процессе
  | OtherCancel Text
```

Каждая reason ADT — с PersistField, exhaustive serialization. Аналитика "почему теряем" станет точной.

### Воронка тогда выглядит так

```
ConversationThread.created     → "входящих диалогов"
ConversationThread.dealId NN   → "квалифицировано в сделку" (= Deal.New + Deal.Qualified)
                                 ИЛИ → ConversationThread.closed без dealId → "disqualified лиды"
Deal.Sourcing                  → "пошли искать"
Deal.Quoted                    → "отправили КП"
Deal.Approved                  → "клиент одобрил"
Deal.Completed                 → "получили деньги"

losses:
Deal.Disqualified              → потеряли при квалификации (с reason)
Deal.Rejected                  → потеряли после КП (с reason)
Deal.Cancelled                 → потеряли в процессе (с reason)
```

Один SQL запрос даёт полную воронку с reasons.

---

## 5. UX Proposal

### Принцип: эволюция, не переделка

Текущая структура Web сохраняется. Добавляем 2 новых раздела + улучшаем существующие.

### 5.1 Глобальная навигация

```
[Inbox]  [Deals]  [Marketing]  [Knowledge]  [Settings]
   ↑        ↑          ↑            ↑
  новое    было      новое       новое
```

### 5.2 Inbox (новый раздел)

Заменяет/дополняет текущий InboxSidebar.

**Layout:**
```
┌────────────┬─────────────────────┬──────────────┐
│ Filters    │ Conversation list   │ Thread view  │
│ + counters │ (sorted by SLA/new) │ + actions    │
├────────────┤                     │              │
│ All        │ ● Unread (12)       │ Messages     │
│ Mine       │ ⏳ Awaiting us (5)  │ ...          │
│ Unread     │ ✓ Active            │              │
│ Awaiting   │ Closed              │ Quick action │
│ By channel │                     │ panel:       │
│  Avito     │                     │ - Create lead│
│  Telegram  │                     │ - Link client│
│  WhatsApp  │                     │ - Create deal│
│ By listing │                     │ - Send temp. │
└────────────┴─────────────────────┴──────────────┘
```

**Quick actions on thread:**
- Create deal from this thread
- Link to existing client
- Mark as Disqualified (with reason picker)
- Send template message
- Snooze / set reminder
- Add note
- Transfer to other manager

**SLA indicator:** красный значок у threads, где мы не отвечали >2 часов. Это критичный KPI.

### 5.3 Deals (улучшение существующего)

Текущий step-based Workspace оставляем. Добавляем:

**В ContextPanel:**
- Новый блок "Source Attribution" — какой listing/campaign привёл, когда первое касание
- Новый блок "Linked Conversations" — все треды этого клиента/сделки
- Новый блок "Notes" — knowledge layer

**В DealWorkspace:**
- "Next best action" виджет вверху — система рекомендует следующий шаг по статусу + времени с последнего обновления

### 5.4 Marketing (новый раздел)

**Layout:**
```
┌────────────────────────────────────────────────┐
│ Period selector  [last 30d ▾]  Channel [All ▾]│
├──────────┬──────────┬──────────┬───────────────┤
│ Spend    │ Leads    │ Deals    │ Revenue       │
│ ₽X       │ N        │ N        │ ₽X            │
│          │ CPL ₽X   │ CPD ₽X   │ Margin ₽X    │
├──────────┴──────────┴──────────┴───────────────┤
│ Funnel by channel                              │
│ [Avito ████████████ 80%] [TG ██ 15%] [WA █ 5%]│
│                                                │
│ Conv → Lead → Deal → Quote → Approved → Done  │
│ [stacked bars per stage]                       │
├────────────────────────────────────────────────┤
│ Performance by listing                         │
│ [table: listing | spend | leads | deals | ROI] │
│ Sortable, filterable                          │
├────────────────────────────────────────────────┤
│ Loss reasons breakdown                         │
│ [pie chart: disqualify reasons | reject reasons│
│  | cancel reasons]                             │
└────────────────────────────────────────────────┘
```

**KPI cards вверху:** spend, leads, deals, revenue, margin, ROI/ROMI, average CPL, average CPD.

**Не перегружать:** только эти три блока на старте. Drill-down в детали через клик.

### 5.5 Knowledge (новый раздел)

**Layout:**
```
┌──────────────┬──────────────────────────────┐
│ Tabs:        │ Note / Decision content      │
│ • Notes      │                              │
│ • Decisions  │                              │
│ • Pinned     │                              │
├──────────────┤                              │
│ Filters:     │                              │
│ - Tag        │                              │
│ - Entity     │                              │
│ - Author     │                              │
│ - Period     │                              │
│ Search ___   │                              │
├──────────────┤                              │
│ List of      │                              │
│ notes by     │                              │
│ filter       │                              │
└──────────────┴──────────────────────────────┘
```

**Note view:** body + tags + attached entity (с deep link) + author + timestamp + thread (если parentNote есть).

**Decision view:** topic / context / outcome / status / participants + history of revisions.

### 5.6 Что упростить или убрать

- **PricingSettingsPanel** — оставить, но переместить в Settings раздел, не в основной workflow
- **DealStatsWidget** — заменить на marketing dashboard для верхнеуровневого view
- **AnalyticsDashboard** в текущем виде — переосмыслить как deal-level analytics tab внутри Marketing раздела

---

## 6. Phased Implementation Roadmap

### Phase 0 — Foundation Schema (1 неделя)

**Цель:** заложить таблицы, начать собирать spend сразу.

**Core (Haskell):**
- Новые domain types: Channel, ChannelAccount, Campaign, Listing, SpendEntry, SpendType, SpendSource
- Новые domain types: SourceTouch, TouchType
- Новые domain types: ConversationThread (только сама запись, без messages), ThreadStatus, MessageDirection
- Новые типы reasons: DisqualifyReason, RejectReason, CancelReason (с PersistField)
- Расширение DealStatus: добавить Qualified, Disqualified
- Расширение Deal: sourceTouchId, disqualifyReason, rejectReason, cancelReason
- DB migration script (versioned, не auto-migrate в этот раз)
- Тесты на новые типы

**Web:**
- Простая форма "Add Spend Entry" в Settings
- Простая форма "Manage Channels/Accounts/Campaigns/Listings"
- Selector источника при создании Deal: channel + account + listing

**Acceptance criteria:**
- Менеджер может вручную ввести spend за прошлый день
- При создании Deal привязывается к Channel/Listing
- При закрытии Deal как Disqualified обязателен reason
- Все новые таблицы покрыты ≥3 тестами

### Phase 1 — Marketing Analytics MVP (2 недели)

**Цель:** видеть ROI каналов даже без интеграций.

**Core (Haskell):**
- Engine.Marketing — pure функции:
  - `aggregateSpend :: Period -> [SpendEntry] -> SpendByChannel`
  - `funnelByChannel :: Period -> [Deal] -> [SourceTouch] -> FunnelByChannel`
  - `calculateCPL :: ChannelAccountId -> Period -> RUB`
  - `calculateCPD :: ChannelAccountId -> Period -> RUB`
  - `calculateROI :: ChannelAccountId -> Period -> Percent`
- Api.Marketing — endpoints:
  - `GET /api/marketing/dashboard?from=&to=&channel=`
  - `GET /api/marketing/funnel?from=&to=&groupBy=channel|listing|campaign`
  - `GET /api/marketing/listings?from=&to=` — performance per listing
  - `GET /api/marketing/losses?from=&to=` — breakdown by reason

**Web:**
- Новый раздел Marketing с layout из 5.4
- KPI cards, funnel chart, listing table, loss reasons pie

**Acceptance criteria:**
- Один SQL запрос даёт ROI per channel за любой период
- Менеджер открывает Marketing → видит spend / leads / deals / revenue / margin за месяц
- Drill-down: клик по channel → разбивка по listings
- Тесты на funnel logic покрывают edge cases (нет spend, нет deals, lost reasons)

### Phase 2 — Conversations Architecture + Avito Inbox (3 недели)

**Цель:** диалоги Avito появляются в CRM, привязываются к источнику.

**Core (Haskell):**
- ConversationThread persistence layer
- Api.Conversations — endpoints:
  - `GET /api/conversations?status=&channel=&assignedTo=`
  - `GET /api/conversations/:id`
  - `POST /api/conversations/:id/link-client`
  - `POST /api/conversations/:id/link-deal`
  - `POST /api/conversations/:id/create-deal`
  - `POST /api/conversations/:id/close?reason=`
  - `POST /api/conversations` (создание из services при ingestion)
- Расширение Deal API: `dealConversations` поле в DealDetailResp

**Services (Python):**
- `sitka-services/app/conversations/` модуль
- `ConversationProvider` protocol
- `AvitoProvider` implementation
  - List threads via Avito API
  - Sync messages
  - Send messages
  - Mark read
- Background job: periodic sync (каждые N минут)
- Webhook handler if Avito поддерживает push
- Локальная Postgres таблица `conversation_messages` для тел сообщений
- Push в Core новых ConversationThread при первом обнаружении

**Web:**
- Новый раздел Inbox с layout из 5.2
- Thread view с messages (тянет из services, не из core)
- Quick actions: create deal, link client, disqualify, send template

**Acceptance criteria:**
- Новый диалог в Avito появляется в CRM Inbox в течение 5 минут
- Менеджер может создать Deal из треда одним кликом
- При создании Deal автоматически создаётся SourceTouch с listing → conversation → deal цепочкой
- SLA индикатор работает — красным помечает >2h без ответа

### Phase 3 — Telegram + WhatsApp adapters (2-3 недели)

**Цель:** омниканальный inbox.

**Services:**
- Расширение существующего Telegram bot для роли ConversationProvider
- TelegramProvider implementation
- WhatsAppProvider implementation (зависит от выбора: WA Business API, Wati, или Twilio)
- Унификация payload normalization

**Core:**
- Никаких изменений в model — она уже channel-agnostic
- Возможно: Channel.WhatsAppChannel constructor

**Web:**
- Inbox автоматически отображает все channels через единый интерфейс
- Filter by channel в Inbox

**Acceptance criteria:**
- Сообщение из Telegram private chat появляется в Inbox
- Можно отвечать из CRM в Telegram
- Аналогично для WhatsApp

### Phase 4 — Knowledge / Decisions Hub (1-2 недели)

**Цель:** контекст из чатов не теряется.

**Core:**
- Никаких новых entity. `NoteAdded` уже есть в `EventType` — используется для audit trail на сделках.
- Опционально: новый event type `DecisionMade` если хотим маркер на уровне сделки.

**Services (вся основная работа здесь):**
- Новые таблицы в Postgres: `notes`, `decisions` (см. раздел 3.4 schema)
- FastAPI endpoints в `sitka-services/app/knowledge/`:
  - `GET /api/notes?entity=&tag=&author=&from=`
  - `POST /api/notes`
  - `GET /api/decisions?status=`
  - `POST /api/decisions`
  - `PATCH /api/decisions/:id` (status updates)
- Расширение Telegram bot:
  - `/note <text>` команда
  - `/note @deal:NN <text>` с привязкой
  - `/save` (reply mode) — сохраняет процитированное сообщение
  - `/decide` (conversation flow для Decision)
  - `/notes` и `/decisions` для просмотра
- Реакция на 📌 emoji в общем чате (опционально)
- При создании Note с привязкой к Deal — bot также POST в core `/api/deals/:id/events` с `eventType=NoteAdded` для audit

**Web:**
- Новый раздел Knowledge с layout из 5.5 (fetch с **services** API, не core)
- Notes tab в ContextPanel сделки (тоже fetch с services)
- Поиск по notes (Postgres FTS в services БД)

**Acceptance criteria:**
- Менеджер пишет `/note это про сезон Sitka FY26` в общем TG чате → запись появляется в CRM Knowledge
- Можно найти заметку через 2 месяца поиском
- Decisions имеют чёткий статус и историю
- На странице Deal видны привязанные notes и audit log содержит `NoteAdded` события

### Phase 5 — Avito Spend Auto-Sync (1 неделя)

**Цель:** не вводить spend вручную.

**Services:**
- AvitoSpendSync background job
- Раз в день: pull spend report из Avito API
- Создание SpendEntry с source = AvitoApiSync
- Reconciliation если был ManualEntry за тот же день/listing — alert менеджеру

**Acceptance criteria:**
- Spend Avito автоматически появляется к 9:00 следующего дня
- Менеджер видит difference manual vs API если есть

### Параллелизация

Можно делать параллельно:

| Параллельно с | Допустимо |
|---------------|-----------|
| Phase 0 ↔ ничего | — |
| Phase 1 ↔ Phase 2 (после Phase 0) | Yes — разные модули |
| Phase 3 ↔ Phase 4 (после Phase 2) | Yes — разные слои |
| Phase 5 ↔ Phase 4 | Yes |

**Критическая последовательность:** Phase 0 → Phase 1 (нельзя строить аналитику без foundation), Phase 0 → Phase 2 (нельзя сохранять SourceTouch без таблиц).

### Total timeline

~10 недель на полный foundation. Но первые 3 недели (Phase 0 + Phase 1) уже дают полезную аналитику.

---

## 7. Boundaries (что где живёт) — итог

### Haskell Core (sitka-core)

- Все типы Channel, Campaign, Listing, SpendEntry, SourceTouch, ConversationThread (метаданные)
- Расширения DealStatus + reasons
- Pure aggregations: funnel, ROI, CPL, CPD
- API endpoints для marketing analytics, conversations metadata
- Бизнес-инварианты (например: spend не может быть отрицательным, SourceTouch требует хотя бы один из listing/campaign/account)
- `NoteAdded` event type для audit trail сделок (само тело Note — в Services)

### Python Services (sitka-services)

- Avito API client (chat, listings, spend)
- Telegram bot (расширение существующего)
- WhatsApp integration (когда дойдём)
- ConversationProvider abstraction + 3 implementations
- conversation_messages таблица (тело сообщений + raw payload)
- **notes и decisions таблицы** — knowledge layer полностью здесь
- **Knowledge API** (FastAPI endpoints для notes/decisions)
- Background sync jobs
- Webhook handlers
- Spend sync from Avito → POST в Core

### Web (sitka-web)

- Inbox раздел (новый)
- Marketing dashboard (новый)
- Knowledge раздел (новый)
- Расширение Workspace ContextPanel: source attribution, linked conversations, notes
- "Next best action" widget на Workspace
- Settings: spend management, channel/campaign/listing CRUD

---

## 8. Risks & Open Questions

### Riski

1. **WhatsApp integration** — официальный WA Business API требует верификации компании, может занять недели. Альтернативы: Wati, Twilio (платно). Решение откладывается до Phase 3.

2. **Avito API rate limits** — нужно заложить exponential backoff и кэширование. Если sync упрётся в лимиты, придётся уменьшать частоту.

3. **conversation_messages таблица в Postgres** — за год может вырасти до GB. Нужна стратегия архивации (не критично сразу, заложить через 6 месяцев).

4. **Telegram common chat capture** — этичность. Все участники чата должны знать, что бот сохраняет реакции 📌. Whitelist обязателен.

5. **Source attribution точность** — если клиент пришёл из Avito, потом перешёл в Telegram, потом купил — какой это touch? Решено: первый = атрибуция. Это можно пересмотреть в Phase 6+.

### Решённые вопросы (зафиксировано перед Phase 0)

1. **Тариф Avito:** максимальный — все API доступны (chat, listings, spend report, webhooks, listings metadata).
2. **Whitelist менеджеров для Knowledge bot:** на старте используем заглушки. Реальные Telegram IDs подставляются после Phase 4 без изменений в коде.
3. **Частота Avito sync:** каждые 15 минут (polling). Если Avito поддерживает webhooks для chat events на максимальном тарифе — переключаемся на push, polling остаётся как fallback.
4. **SLA по каналам:**
   - Avito: 30 минут (жёстко, красный алерт + уведомление менеджеру)
   - Telegram: 4 часа (мягко, только подсветка в Inbox, без алертов)
   - WhatsApp: 4 часа (мягко, только подсветка)
   - Direct/Referral: 24 часа (минимальный приоритет)
5. **Инструмент миграций:** на усмотрение рабочего агента в Phase 0. Жёсткие требования: auto-migration выключен, миграции версионированы и реверсируемы, есть аудит "что и когда применилось".

---

## 9. Acceptance criteria — итог

### По окончании Phase 0
- [ ] DB миграция с новыми таблицами без потери данных
- [ ] Spend можно вводить через UI
- [ ] Deal привязывается к Channel/Listing при создании
- [ ] Causes для Disqualified/Rejected/Cancelled обязательны и структурированы
- [ ] Тесты покрывают новые types (≥80% line coverage на Domain.Marketing.*)

### По окончании Phase 1
- [ ] Marketing dashboard показывает spend / leads / deals / revenue / margin
- [ ] Funnel breakdown по channel доступен
- [ ] ROI считается per channel/listing
- [ ] Loss reasons breakdown работает
- [ ] Performance: dashboard загружается <1s

### По окончании Phase 2
- [ ] Avito диалоги синкаются автоматически
- [ ] Inbox показывает unified list
- [ ] Создание Deal из треда — один клик
- [ ] SLA alerts работают
- [ ] SourceTouch автоматически создаётся при первом сообщении

### По окончании Phase 3
- [ ] Telegram private chats в Inbox
- [ ] WhatsApp в Inbox (если интеграция готова)
- [ ] Channel filter работает

### По окончании Phase 4
- [ ] `/note` в TG bot создаёт запись в Knowledge
- [ ] Поиск по notes работает
- [ ] Decisions имеют lifecycle

### По окончании Phase 5
- [ ] Avito spend синкается ежедневно
- [ ] Reconciliation alerts работают

---

## 10. Что НЕ делаем в этой итерации

- Multi-touch attribution (single-touch достаточно)
- A/B testing infrastructure
- Cohort analysis (отложено до Phase 6+)
- ML / прогнозирование
- Mobile app
- Customer-facing portal
- Email integration
- Payment processing internal (Stripe etc)
- Полная переделка Workspace (только эволюция)

Эти задачи могут стать релевантны через 6+ месяцев. Сейчас — преждевременно.
