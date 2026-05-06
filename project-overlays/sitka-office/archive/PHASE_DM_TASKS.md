> **ЗАКРЫТА 2026-04-26, см. CURRENT_STATE.md**

# Phase DM — Domain Model Refactor Tasks

Декомпозиция финальной модели (`DOMAIN_V3.md`) в конкретные задачи для рабочего агента.

**Общий срок:** 6-8 недель параллельно с другими задачами.

**Принцип:** без giant rewrite. Каждая фаза самодостаточна, проходит CI, оставляет систему в рабочем состоянии.

---

## DM-1 — Foundation: Person + ContactPoint + Identity Resolution

**Срок:** 1 неделя
**Зависимости:** нет (старт)
**Tier:** A (touches core domain)

### Файлы

**Новые:**
- `sitka-core/src/Domain/Person.hs`
- `sitka-core/src/Domain/ContactPoint.hs`
- `sitka-core/src/Engine/IdentityResolution.hs`
- `sitka-core/test/PersonSpec.hs`
- `sitka-core/test/IdentityResolutionSpec.hs`
- `sitka-core/migrations/NNNN_person_contactpoint.sql`

**Изменения:**
- `sitka-core/src/Db/Schema.hs` — добавить Person, ContactPoint
- `sitka-core/sitka-core.cabal` — exposed-modules

### Задача

1. ADT для `Person`, `ContactPoint`, `Channel` (Avito/Telegram/WhatsApp/Phone/Email)
2. `IdentityResolution`:
   ```haskell
   data MatchConfidence = Strong | Medium | Weak | NoMatch
   findMatchingPerson :: ContactPoint -> [ContactPoint] -> Maybe (PersonId, MatchConfidence)
   ```
3. DB таблицы + FK + indexes
4. Миграция (dbmate)
5. Тесты:
   - Round-trip serialization
   - Strong match (phone совпал) → авто-связывание
   - Medium match (username без verified) → предложить
   - Weak match → игнор
   - NoMatch → новый Person
   - Property: `findMatching . create == Just (id, Strong)` для верифицированных контактов

### Не трогать

- Существующий Lead / Deal / Client код
- API endpoints (пока)

### Проверка

- `cabal build -Werror`
- `cabal test` — все старые + новые ≥20 проходят
- `make migrate-up` применяет
- Property tests для `findMatchingPerson`

---

## DM-2 — Lead entity с event-driven lifecycle

**Срок:** 1 неделя
**Зависимости:** DM-1
**Tier:** A

### Файлы

**Новые:**
- `sitka-core/src/Domain/Lead.hs`
- `sitka-core/src/Domain/Lead/Event.hs` — LeadEvent ADT
- `sitka-core/src/Engine/LeadStatus.hs` — derive status from events
- `sitka-core/migrations/NNNN_lead.sql`
- `sitka-core/test/LeadSpec.hs`
- `sitka-core/test/LeadStatusSpec.hs`

**Изменения:**
- `sitka-core/src/Db/Schema.hs`
- `sitka-core/src/Api/Leads.hs` (новый)
- `sitka-core/src/Api/Server.hs` (подключить leads API)

### Задача

1. `Lead` entity с 4 статусами (Active / Paused / Converted / Closed)
2. `LeadEvent` ADT (9 типов событий см. DOMAIN_V3 раздел 2)
3. Pure функция `currentStatus :: [LeadEvent] -> LeadStatus`
4. API endpoints:
   - `POST /api/leads` — создать (обычно через incoming signal)
   - `GET /api/leads` — list с фильтром по status
   - `GET /api/leads/:id` — detail включая events timeline
   - `POST /api/leads/:id/events` — добавить event (append-only)
   - `POST /api/leads/:id/close` — закрыть с reason (Disqualified/Rejected/Lost)
5. Auto-reactivation: при входящем сообщении на Closed/Lost Lead → событие `LeadReactivated` → status back to Active
6. Тесты:
   - Status derivation property: для любой последовательности events — статус консистентен
   - Event append-only (нельзя менять прошлые)
   - Reactivation logic

### Не трогать

- Deal код (пока)
- Client код
- Step-based workspace во фронте

### Проверка

- `cabal test`
- Property: для всех event sequences — status consistent
- Manual: POST /api/leads, добавить events, GET detail показывает timeline

---

## DM-3 — Deal lifecycle update (AwaitingPayment + TTL + Expired)

**Срок:** 1 неделя
**Зависимости:** DM-1, DM-2
**Tier:** A (money + state machine)

### Файлы

**Изменения:**
- `sitka-core/src/Domain/Deal.hs` — новый DealStatus enum
- `sitka-core/src/Domain/Deal/StateMachine.hs` — новые переходы
- `sitka-core/src/Db/Schema.hs` — новые поля
- `sitka-core/migrations/NNNN_deal_awaiting_payment.sql`
- `sitka-core/src/Api/Deals.hs` — новые endpoints
- `sitka-core/test/StateMachineSpec.hs` — обновить
- `sitka-core/test/DealSpec.hs`

**Новые:**
- `sitka-services/app/tasks/deal_expiration.py` — cron job

### Задача

1. Новый DealStatus enum (11 статусов по DOMAIN_V3 раздел 3)
2. Поля Deal:
   - `dealAwaitingPaymentTTL` (NominalDiffTime, default 48h)
   - `dealAwaitingPaymentDeadline` (UTCTime)
   - `dealConfirmedAt`, `dealExpiredAt`
3. StateMachine update:
   - `createDeal` из Lead → status AwaitingPayment
   - `confirmPayment` → AwaitingPayment → Confirmed
   - `expireDeal` → AwaitingPayment → Expired (auto)
   - Остальные переходы как были
4. Cron job в services: раз в час проверяет deadline, помечает Expired
5. API endpoints:
   - `POST /api/deals/:id/confirm-payment {transactionId}` → status Confirmed
   - `POST /api/deals/:id/extend-ttl {newDeadline}` → продлить
   - `POST /api/deals/:id/expire` (admin, обычно cron вызывает)
6. Event append в deal_event:
   - DealCreated, PaymentConfirmed, DealExpired, TTLExtended
7. Тесты:
   - StateMachine: AwaitingPayment → все валидные переходы
   - TTL logic: deadline computed correctly
   - Auto-expire: Python test с mocked time

### Не трогать

- Старые статусы (Qualified, Sourcing, Quoted) — они пока остаются в enum, убираются в DM-8

### Проверка

- `cabal test`
- `pytest` для cron job
- Manual: создать Deal с TTL 1 минута, ждать, проверить Expired

---

## DM-4 — Client entity + автосоздание при оплате

**Срок:** 3-4 дня
**Зависимости:** DM-3
**Tier:** A

### Файлы

**Изменения:**
- `sitka-core/src/Domain/Client.hs` — переосмыслить
- `sitka-core/migrations/NNNN_client_person.sql`
- `sitka-core/src/Api/Deals.hs` — update confirmPayment

### Задача

1. Client поля по DOMAIN_V3 раздел 4 (личный)
2. При `confirmPayment`:
   - Поиск `SELECT Client WHERE personId = X`
   - Если нет — создать Client(personId, firstPaidAt=now)
   - Обновить lastDealAt, totalSpent, dealsCount
3. API endpoint: `GET /api/clients/:id` — детали клиента + его deals
4. Миграция: **не трогаем существующие Client records** (старые остаются, но теперь связь через Person)
5. Тесты:
   - Создание Client при первой оплате
   - Обновление lastDealAt при второй оплате
   - Property: clientDealsCount = count(Deal where personId = clientPersonId AND status ≥ Confirmed)

### Проверка

- `cabal test`
- Manual: Deal AwaitingPayment → confirmPayment → Client создан

---

## DM-5 — Treasury ledger MVP

**Срок:** 1 неделя
**Зависимости:** DM-1 (Person нужен для некоторых связей)
**Tier:** A (деньги)

### Файлы

**Новые:**
- `sitka-core/src/Domain/Transaction.hs`
- `sitka-core/src/Domain/Account.hs` — shadow в MVP
- `sitka-core/src/Engine/Treasury.hs`
- `sitka-core/src/Api/Treasury.hs`
- `sitka-core/migrations/NNNN_treasury.sql`
- `sitka-core/test/TreasurySpec.hs`

### Задача

1. Transaction entity по DOMAIN_V3 раздел 6
2. **Starting balance 5 000 ₽ на 2026-04-19** — создать через migration или seed
3. Pure функции в Engine.Treasury (8 функций см. DOMAIN_V3)
4. API endpoints:
   - `POST /api/treasury/transactions` — создать транзакцию
   - `GET /api/treasury/transactions` — list с фильтром
   - `GET /api/treasury/balance` — текущий баланс
   - `GET /api/treasury/cashflow?from=&to=` — отчёт движений
5. Автоматическая привязка:
   - При `confirmPayment` → Transaction(ClientPrepayment, dealId)
   - При SpendEntry создании → Transaction(MarketingSpend, spendEntryId)
6. Тесты:
   - Starting balance = 5 000 ₽
   - currentBalance после N транзакций
   - Property: balance monotonic for same-sign transactions

### Проверка

- `cabal test`
- Manual: создать Deal → confirmPayment → balance += prepayment
- Manual: create SpendEntry → balance -= amount

---

## DM-6 — Chat-first UI (Inbox primary workspace)

**Срок:** 2-3 недели
**Зависимости:** DM-2 (Lead + events), **Phase 2 (Avito Conversations Inbox)** — блокер
**Tier:** B (UI-heavy)

### Файлы

**Новые:**
- `sitka-web/src/components/inbox/InboxView.tsx` — primary workspace
- `sitka-web/src/components/inbox/ConversationPanel.tsx` — диалог (центр)
- `sitka-web/src/components/inbox/ContextPanel.tsx` — автоматический контекст (справа)
- `sitka-web/src/components/inbox/AttachActions.tsx` — "Mark as offer" / "Mark as quote" на сообщениях
- `sitka-web/src/components/inbox/CreateDealButton.tsx` — главная кнопка
- `sitka-web/src/hooks/useInbox.ts`

**Удаление:**
- `sitka-web/src/components/workspace/NewRequestStep.tsx`
- `sitka-web/src/components/workspace/SourcingStep.tsx`
- `sitka-web/src/components/workspace/ReviewOffersStep.tsx`
- `sitka-web/src/components/workspace/QuoteReadyStep.tsx`
- (удалить после DM-8, не сейчас)

### Задача

1. Inbox с фильтрами (Active / Paused / Converted / Closed)
2. ConversationPanel — рендер messages + ввод
3. ContextPanel:
   - Source, Channel, Person info
   - Attached offers / quotes
   - Выделенные цены, размеры (из regex-парсинга сообщений)
   - Кнопка "Создать сделку"
4. Attach actions: клик на сообщение → menu "Mark as offer" / "Mark as quote" → форма prefilled
5. Create Deal flow:
   - Проверка required fields
   - Если не хватает — inline checklist
   - Jest создание Deal.AwaitingPayment

### Зависит от Phase 2

Без Avito Conversations Inbox (Phase 2) — UI будет показывать только метаданные Lead, но не диалог. Минимально работает, но пользы меньше.

### Проверка

- `tsc --noEmit`
- Manual: входящее сообщение → Inbox → Context Panel автоматически заполнен → attach offer → create deal

---

## DM-7 — Migration of legacy data

**Срок:** 3-4 дня
**Зависимости:** DM-1 через DM-5
**Tier:** A (data)

### Задача

Миграционный скрипт (Haskell executable или SQL + Haskell post-processing):

1. **Существующие Deal** в статусах:
   - `New / Qualified / Sourcing / Quoted` → создать Lead + Person, удалить Deal
   - `Approved+` → оставить как Deal, мигрировать в новый статус (Approved → Confirmed, остальные 1:1)
2. **Существующие Client** → привязать к Person (создать Person на основе данных Client, linked через phone/email)
3. **Existing UsaOffer / Quote** → перевесить на Lead (если активный) или оставить исторически на Deal
4. **SourceTouch** → мигрировать с Deal на Lead (для активных)
5. **Тестовые Disqualified / Rejected deals** → удалить (согласовано с пользователем)

### Проверка

- Invariant: total revenue (SUM actualRevenue for Completed) не меняется до и после миграции
- Invariant: count of Person ≥ count of Client
- Invariant: каждый Lead имеет personId
- Dry-run на копии БД перед production

---

## DM-8 — Cleanup старой схемы

**Срок:** 2-3 дня
**Зависимости:** DM-7
**Tier:** B (cleanup)

### Задача

1. Удалить из `DealStatus` статусы: `New`, `Qualified`, `Sourcing`, `Quoted`, `Approved`, `Disqualified`, `Rejected`
2. Удалить pre-sale поля из Deal:
   - `dealDesiredItem`, `dealDesiredSize`, `dealDesiredColor`, `dealMaxPriceRub`
   - `dealDisqualifyReason`, `dealRejectReason` (они теперь на Lead)
3. Удалить `step-based workspace` components (из DM-6 списка)
4. Обновить `allowedTransitions` StateMachine
5. Обновить `statusToText` / `textToStatus` — exhaustive
6. Обновить все тесты на новый lifecycle

### Проверка

- `cabal build -Werror`
- `cabal test` — все зелёные
- Web: тесты не используют удалённые components
- Manual: на чистой БД создать Lead → Deal → Completed по полному flow

---

## Параллелизация

```
DM-1 (Person+ContactPoint)
    ↓
    ├── DM-2 (Lead)
    │       ↓
    │       DM-3 (Deal AwaitingPayment)
    │           ↓
    │           DM-4 (Client automation)
    │
    └── DM-5 (Treasury) — может параллельно с DM-2

После DM-2 + DM-3 + DM-4 + DM-5:
    DM-6 (Chat-first UI) — ждёт ещё Phase 2 Avito Inbox

После всех DM-1..DM-6:
    DM-7 (Migration) → DM-8 (Cleanup)
```

**Критический путь:** DM-1 → DM-2 → DM-3 → DM-4 → DM-7 → DM-8 = ~5 недель
**Параллельно:** DM-5 (Treasury), DM-6 (UI, ждёт Phase 2)

**Общий срок:** 6-8 недель.

---

## Acceptance criteria Phase DM целиком

- [ ] Все тесты старые + новые зелёные
- [ ] `cabal build -Werror` проходит
- [ ] Migration dry-run на production-like данных успешен
- [ ] Invariant: total revenue не изменился после миграции
- [ ] Все 7 решений из DOMAIN_V3 раздел TL;DR работают
- [ ] Chat-first UI доступен (зависит от Phase 2)
- [ ] Treasury balance отражает реальные движения начиная с 5 000 ₽
- [ ] Lead.status event-driven, менеджер не кликает статусы
- [ ] Deal создаётся только через "Создать сделку" из Lead
- [ ] Client создаётся только при первой оплате

---

## Ordering с учётом других phase

**Уже идёт:**
- Phase 1 (Marketing Analytics) — Task 1.1-1.3 сделаны, Task 1.4 в работе
- Sprint защит архитектуры — D1-D14 закрыты, D15 (Critical-path invariants) — открыт

**Порядок:**
1. Закрыть Phase 1 Task 1.4 + D15
2. Начать DM-1 параллельно с Phase 2 (Avito Conversations Inbox)
3. DM-2..DM-5 параллельно с Phase 2
4. DM-6 когда Phase 2 готова
5. DM-7, DM-8 финалом

Phase 3 (Telegram/WhatsApp adapters) и Phase 4 (Knowledge Hub) — после Phase DM.
