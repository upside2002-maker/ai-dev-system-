# Sitka Office — Domain Model V3 (финальная)

Дата финализации: 2026-04-19
Статус: одобрено пользователем, готово к декомпозиции в задачи

---

## TL;DR модели

**Lead** = потенциальная продажа (pre-sale процесс)
**Deal.awaiting_payment** = подтверждённое намерение купить (без Client)
**Deal.confirmed** = первая оплата получена, Client создан
**Client** = Person который совершил хотя бы одну оплату

```
Входящий сигнал → Person (создан или найден через identity resolution)
                → Lead (привязан к Person)
                → [разговор менеджера с клиентом в диалоге]
                → менеджер жмёт "Создать сделку"
                → Deal.AwaitingPayment (TTL 48ч default, override per deal)
                → оплата пришла
                → Deal.Confirmed + Client создан (если Person ещё не был Client)
                → Purchased → ... → Completed
```

---

## 7 ключевых решений модели

1. **Person** — сквозная сущность человека, создаётся при первом контакте
2. **ContactPoint** — каналы связи Person (1:N), с identity resolution по телефону/email/username
3. **Lead** (→ Person) — pre-sale, 4 статуса (Active / Paused / Converted / Closed), event-driven
4. **Deal** (→ Person) — 9 статусов: AwaitingPayment → Confirmed → Purchased → AtUsWarehouse → ShippedKz → InKazakhstan → ShippedRu → Delivered → Completed. Терминалы: Expired (до Confirmed), Cancelled (после Confirmed)
5. **Client** (1:1 с Person) — создаётся в момент `Deal.AwaitingPayment → Confirmed` (первая оплата)
6. **Treasury** — рублёвый ledger в MVP, starting balance 5 000 ₽ на 2026-04-19, архитектурный задел на multi-currency/multi-account
7. **Chat-first model** — CRM = слой фиксации и структуры, не слой операционного контроля. Менеджер работает в диалоге, одна ключевая кнопка "Создать сделку"

---

## 1. Person + ContactPoint (multi-channel identity)

### Person

```
Person:
  personId
  personDisplayName        -- как называть (из последнего контакта)
  personPrimaryContact     -- telegram/phone/whatsapp для быстрого доступа
  personCreatedAt
  personNotes              -- свободные заметки
```

Минимум в MVP. Расширяется по мере потребности.

### ContactPoint

```
ContactPoint:
  contactPointId
  contactPointPersonId     -- связь с Person
  contactPointChannel      -- Avito | Telegram | WhatsApp | Phone | Email
  contactPointExternalId   -- avito_user_id / tg_username / номер / email
  contactPointVerified     -- Bool (подтверждён ли)
  contactPointFirstSeen
  contactPointLastSeen
```

### Identity Resolution

**Автоматическое связывание (Strong match):**
- Верифицированный телефон совпал
- Верифицированный email совпал

**Предложить менеджеру (Medium match):**
- @username совпал (но не verified)
- Совпало имя + город

**Не автоматически (Weak match):**
- Только имя совпало
- Косвенные признаки

**Pure функция:**
```haskell
findMatchingPerson
  :: ContactPoint
  -> [ContactPoint]
  -> Maybe (PersonId, MatchConfidence)

data MatchConfidence = Strong | Medium | Weak | NoMatch
```

---

## 2. Lead (pre-sale)

### Статусы (упрощённые — event-driven)

```
Active       — диалог идёт
Paused       — нет активности N дней (автомат)
Converted    — создана сделка
Closed       — менеджер явно закрыл (Disqualified / Rejected / Lost)
```

### События (вместо старого set of 9 статусов)

```
LeadEvent:
  MessageSent              -- менеджер отправил
  MessageReceived          -- клиент написал
  OfferAttached msgId      -- менеджер пометил сообщение как оффер
  QuoteAttached msgId      -- менеджер пометил сообщение как КП
  PriceMentioned amount    -- система выделила цену из сообщения
  DealCreated dealId       -- главное действие (Lead.Converted)
  LeadClosed reason        -- менеджер закрыл (Disqualified/Rejected)
  LeadTimeoutMarked        -- автомат по timeout
  LeadReactivated          -- было закрыто, пришло сообщение
```

### Поля Lead

```
Lead:
  leadId
  leadPersonId             -- всегда заполнено
  leadOriginContactPointId -- откуда пришёл этот конкретный лид
  leadSourceTouchId        -- source/campaign/listing (атрибуция)
  leadStatus               -- производное от событий
  leadClosedReason         -- nullable (Disqualified/Rejected/Lost + детали)
  leadCreatedAt
  leadUpdatedAt
  leadClosedAt             -- nullable
  leadNotes
```

### Lead.Closed — три варианта причины

```
data LeadClosedReason
  = Disqualified DisqualifyReason  -- "не наш клиент"
  | Rejected RejectReason          -- "отказался от КП"
  | Lost                           -- пропал, не отвечает
  | ReactivatedToActive            -- псевдо-статус для истории (откат)
```

### Lost — мягкий (auto-reactivate)

- Автомат: если N дней нет сообщений → `LeadTimeoutMarked` → status `Closed/Lost`
- Если приходит новое сообщение → `LeadReactivated` → status `Active` (возврат к предыдущему активному)

---

## 3. Deal (post-conversion)

### Lifecycle

```
AwaitingPayment              -- создан из Lead, ждём оплату, TTL = 48ч default
  → Confirmed                -- первая оплата получена, Client создан
  → Expired                  -- TTL вышел, не оплатил (терминал)

Confirmed → Purchased → AtUsWarehouse → ShippedKz → InKazakhstan →
            ShippedRu → Delivered → Completed (терминал)

Любой от Confirmed до Delivered → Cancelled (терминал, с возвратом)
```

**Всего 11 статусов:** 1 pre-payment (AwaitingPayment) + 8 операционных + 2 терминала прерывания (Expired, Cancelled) + 1 финальный (Completed).

### Поля Deal

```
Deal:
  dealId
  dealLeadId               -- ссылка на исходный Lead
  dealPersonId             -- кто покупает
  dealClientId             -- nullable до Confirmed
  dealQuoteId              -- утверждённый quote
  dealSelectedOfferId      -- выбранный offer
  dealManagerId
  dealStatus
  dealCreatedAt
  dealConfirmedAt          -- nullable (когда пришла оплата)
  dealCompletedAt
  dealCancelledAt
  dealExpiredAt
  dealAwaitingPaymentTTL   -- NominalDiffTime, default 48h
  dealAwaitingPaymentDeadline
  dealPlannedCost, dealPlannedMargin
  dealActualCost, dealActualRevenue, dealActualMargin
  dealRiskFlags
  dealTrackingUs, dealTrackingKz, dealTrackingRu
  dealCancelReason         -- ADT при Cancelled
```

### Поведение TTL

**Default:** 48 часов (глобальный, хранится в `Setting` таблице, изменяется без деплоя).

**Per-deal override:** менеджер при создании сделки может указать другой TTL (через опциональное поле в форме).

**Auto-expire job:** cron-task раз в час проверяет `deadline < now AND status = AwaitingPayment` → `Expired`.

**Manual extend:** менеджер может продлить deadline в активном AwaitingPayment (событие `DealTTLExtended`).

---

## 4. Client

### Правило создания

**Момент:** переход `Deal.AwaitingPayment → Confirmed` (первая полученная оплата).

**Условие:** Person ещё не был Client (проверка: `SELECT Client WHERE personId = X`).

**Действие:**
1. Создать `Client(personId, firstPaidAt=now)`
2. Обновить `Client.lastDealAt = now`, `Client.totalSpent += amount`

### Поля Client

```
Client:
  clientId
  clientPersonId           -- 1:1 с Person
  clientFirstPaidAt
  clientTotalSpent         -- денормализация для быстрых запросов
  clientLastDealAt
  clientDealsCount         -- денормализация
```

---

## 5. Offer / Quote (post-factum attach к сообщениям)

### Офферы — не создаются через форму

Менеджер пишет клиенту напрямую в диалоге:
> "Sitka Hudson Bib Marsh XL — 32 000 ₽. Срок 4-6 недель. Через Black Ovis."

Потом в CRM кликает на это сообщение → **"Mark as offer"** → открывается форма с предзаполненными полями (parser попытался распарсить из текста) → менеджер корректирует → сохраняется `Offer` связанный с `messageId`.

Это **post-factum структурирование**, не замена ручного ввода отдельной формы.

### Поля Offer

```
Offer:
  offerId
  offerLeadId              -- к какому Lead
  offerMessageId           -- nullable, связь с сообщением из которого извлечён
  offerStore               -- US store
  offerUrl                 -- nullable
  offerItemName            -- модель
  offerSize
  offerColor
  offerPriceUsd
  offerShippingUsd
  offerInStock
  offerIsSelected          -- выбран ли клиентом
  offerFoundAt
```

### Quote — аналогично

```
Quote:
  quoteId
  quoteLeadId
  quoteMessageId           -- nullable
  quoteOfferId             -- на основе какого оффера
  quoteCostBreakdown       -- себестоимость
  quoteMarginPercent
  quotePriceRub            -- цена для клиента
  quoteAvitoPriceRub       -- для сравнения
  quoteClientSaves
  quoteValidUntil
  quoteCreatedAt
  quoteAcceptedAt          -- nullable (когда клиент согласился)
```

---

## 6. Treasury (касса)

### Starting balance

**5 000 ₽ на 2026-04-19.** Это точка отсчёта ledger'а.

### Transaction

```haskell
data Currency = RUB | USD | USDT        -- MVP: только RUB, остальное задел

data TransactionType
  = ClientPrepayment       -- предоплата от клиента
  | ClientFinalPayment     -- финальная оплата
  | ClientRefund           -- возврат клиенту
  | PurchaseUS             -- закупка в US
  | ShippingExpense
  | CustomsExpense
  | MarketingSpend
  | BankFee
  | Conversion             -- для multi-currency
  | OperationalExpense
  | OwnerWithdraw
  | OwnerDeposit

data TransactionSource
  = ManualEntry
  | LeadLinked LeadId              -- атрибуция pre-sale расходов
  | DealLinked DealId
  | SpendEntryLinked SpendEntryId
  | BankImport Text

Transaction:
  transactionId
  transactionAmount               -- RUB (MVP)
  transactionCurrency             -- всегда RUB в MVP
  transactionType
  transactionDate
  transactionSource
  transactionAccountId            -- NULL в MVP, задел
  transactionCounterpartyId       -- NULL в MVP, задел
  transactionExternalRef
  transactionNotes
  transactionCreatedAt
```

### Account (shadow в MVP)

```
Account:
  accountId
  accountName
  accountType              -- BankAccount | CryptoWallet | CashAccount | CardAccount
  accountCurrency          -- RUB / USD / USDT
  accountIsActive
```

В MVP может быть 1 запись "Main RUB" или таблица пустая.

### Pure functions (Engine.Treasury)

```haskell
currentBalance             :: [Transaction] -> RUB
balanceOnDate              :: Day -> [Transaction] -> RUB
incomingByPeriod           :: Period -> [Transaction] -> RUB
outgoingByCategory         :: Period -> [Transaction] -> Map TransactionType RUB
cashflow                   :: Period -> [Transaction] -> CashflowReport
spendPerLead               :: LeadId -> [Transaction] -> RUB
revenuePerDeal             :: DealId -> [Transaction] -> RUB
marketingCostPerConvertedLead :: Period -> [Lead] -> [Transaction] -> Map ChannelAccountId RUB
```

### Переход к V2 и V3 (без ломки)

**V2 (multi-account, через 6+ месяцев):** заполнить `account` реальными счетами, привязать все transactions, multi-currency.

**V3 (double-entry, через год+):** каждая Transaction в 2 `JournalEntry`, invariant `SUM = 0`, Transaction становится "логической группой".

---

## 7. Chat-first model (Architecture Invariant I7)

**Принцип:**

> CRM — это слой фиксации и структуры, не слой операционного контроля. Менеджер работает в диалоге (Avito / Telegram / WhatsApp), CRM автоматически сохраняет историю, извлекает контекст и создаёт доменные сущности. Единственное обязательное ручное действие в pre-sale — "Создать сделку" в момент конверсии. Статусы Lead — внутренняя метка, не UI-элемент управления.

### UI Layout (chat-first)

```
┌──────────────┬────────────────────────┬─────────────────────┐
│ Inbox        │ Диалог (сообщения)     │ Context Panel       │
│              │                        │                     │
│ ● Active(12) │ [Клиент]: Есть Hudson? │ Source: Avito       │
│ ⏸ Paused(5)  │ [Менеджер]: Да, 32K... │ Канал: @avito_main  │
│ ✓ Converted  │ [Клиент]: Беру         │ Person: Иван        │
│ ✗ Closed     │ ...                    │                     │
│              │                        │ Attached facts:     │
│ [список      │                        │ • Offer: Hudson Bib │
│  диалогов]   │                        │ • Цена: 32 000 ₽    │
│              │                        │ • Согласие ✓        │
│              │ [поле ввода]           │                     │
│              │                        │ ┌──────────────┐   │
│              │                        │ │Создать сделку│   │
│              │                        │ └──────────────┘   │
└──────────────┴────────────────────────┴─────────────────────┘
```

### Пre-sale UI — удаляется

Было: step-based workspace (NewRequest → Sourcing → ReviewOffers → QuoteReady).

Будет: **Inbox primary**, весь pre-sale в контексте диалога + Context Panel справа.

### Deal UI — остаётся

Workspace для Deal (после AwaitingPayment → Confirmed) — остаётся как есть. Это операционная карточка с tracking, статусами доставки, финальной оплатой.

### Автоматически фиксируется в диалоге

**Простое (Phase 2):**
- Source, ChannelAccount
- Timestamps
- Кто писал последним
- Весь текст сообщений

**Среднее (Phase 2-3 с regex):**
- Упоминания цен ("32000 ₽", "32K")
- Совпадения с моделями Sitka
- Размеры / контакты (phone/email/@username)

**Сложное (отложено в Phase 3+):**
- NLP "клиент согласился" / "отказался"
- Автоматический Offer без attach
- Суммаризация

---

## 8. "Создать сделку" — техническое поведение

Когда менеджер жмёт кнопку:

1. Проверка: у Lead есть attached Offer и Quote? 
   - Нет → чек-лист "не хватает данных":
     - ☐ Модель (из Offer)
     - ☐ Цена (из Quote)
     - ☐ Контакт для связи (ContactPoint verified)
   - Менеджер доделывает inline → кнопка активируется
2. Создание `Deal`:
   - `dealPersonId` = Lead.personId
   - `dealLeadId` = Lead.id
   - `dealSelectedOfferId` = последний attached offer
   - `dealQuoteId` = последний attached quote
   - `dealStatus` = AwaitingPayment
   - `dealAwaitingPaymentTTL` = default (48h) или custom
   - `dealAwaitingPaymentDeadline` = now + TTL
3. Lead переходит в `Converted`, пишется событие `DealCreated`
4. Уведомление: "Сделка #123 создана, deadline 21 апр 14:00"

---

## 9. Что удаляется из старой модели

- ❌ `DealStatus.New`, `Qualified`, `Sourcing`, `Quoted`, `Approved` — уходят на Lead (или исчезают)
- ❌ `DealStatus.Disqualified`, `Rejected` — уходят на `Lead.Closed` с reason
- ❌ Step-based pre-sale workspace в web
- ❌ Явное создание Offer/Quote через отдельные формы
- ❌ Создание Client при первом контакте
- ❌ `DisqualifyReason` / `RejectReason` на Deal → теперь на Lead

---

## 10. Open Questions (решены)

- Q1: Client при первой оплате → ✅ принято
- Q2: Lead.personId (single direction) → ✅ принято
- Q3: Treasury single ledger с Currency field → ✅ принято
- Q4: Deal.AwaitingPayment с TTL + per-deal override → ✅ принято
- Q5: Старые test data игнорируем → ✅ принято
- Q6: Simple ledger, double-entry позже → ✅ принято
- Starting balance Treasury: 5 000 ₽ на 2026-04-19 → ✅ принято
- TTL: 48ч default + per-deal override → ✅ принято
- Chat-first model вместо step-based → ✅ принято
- Event-driven Lead status → ✅ принято

---

## 11. Acceptance criteria финальной модели

После всех фаз:

- [ ] Входящий сигнал создаёт `Person` (или находит существующий) + `Lead`
- [ ] Multi-channel identity resolution работает (Strong → авто, Medium → предложение, Weak → новый Person)
- [ ] Lead.status — 4 статуса (Active / Paused / Converted / Closed), без ручного переключения
- [ ] Offer / Quote привязаны к message_id (post-factum attach)
- [ ] Кнопка "Создать сделку" — единственное обязательное ручное действие в pre-sale
- [ ] Deal.AwaitingPayment с TTL 48ч, auto-expire job работает
- [ ] Client создаётся только при `AwaitingPayment → Confirmed` (первая оплата)
- [ ] Treasury ledger показывает текущий баланс (start = 5 000 ₽)
- [ ] Transaction связывается с Lead / Deal / SpendEntry
- [ ] Chat-first Inbox — primary workspace, step-based pre-sale удалён
- [ ] Старый Deal lifecycle упрощён (11 статусов вместо 13)
- [ ] Миграция legacy данных: активные Deal в pre-sale стадиях → Lead

---

## 12. Что следующее

Детальная декомпозиция → `PHASE_DM_TASKS.md` (создаётся параллельно).

8 фаз: Foundation → Lead refactor → Deal lifecycle → Client → Treasury → Chat-first UI → Migration → Cleanup.

Общий срок: 6-8 недель параллельно с обычной работой.
