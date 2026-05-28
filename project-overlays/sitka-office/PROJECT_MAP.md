# Sitka Office — Project Map

Путь: `/Users/ilya/Projects/sitka-office`
Актуальность: snapshot `b58e5fb` от `2026-05-03` (post DM-7 Phase C, production live).

Это не полная распечатка дерева, а карта зон, в которые сейчас реально приходится заходить агентам.

## Core (`sitka-core/`) — Haskell / Servant / Persistent / Warp

### Домен

```
src/Domain/Types.hs               ← money types, ids, shared newtypes
src/Domain/Person.hs              ← Person
src/Domain/ContactPoint.hs        ← channel identity
src/Domain/Lead.hs                ← pre-sale record
src/Domain/Lead/Event.hs          ← lead event log
src/Domain/Deal.hs                ← post-conversion deal model
src/Domain/Deal/StateMachine.hs   ← allowed deal transitions
src/Domain/Client.hs              ← paid subset of Person
src/Domain/Offer.hs               ← sourcing offers
src/Domain/Quote.hs               ← quotes / pricing output
src/Domain/Order.hs               ← purchase order materialised after Confirmed
src/Domain/Payment.hs             ← prepayment / final-payment events
src/Domain/Shipment.hs            ← logistics legs (US → KZ → RU)
src/Domain/Reservation.hs         ← cashbox reservation lifecycle (Phase A+B+C)
src/Domain/Transaction.hs         ← treasury ledger (incl. manual expenses)
src/Domain/ExpenseCategory.hs     ← expense category taxonomy (DM-7-C)
src/Domain/Event.hs               ← cross-entity event log (used by useEventStream)
src/Domain/Conversation.hs        ← thread metadata + send status
src/Domain/Marketing.hs           ← channels / campaigns / listings
src/Domain/Marketing/Attribution.hs
src/Domain/Marketing/Spend.hs
src/Domain/Reason.hs              ← typed reject/cancel/disqualify reasons
```

### Engines

```
src/Engine/IdentityResolution.hs  ← ContactPoint → Person matching
src/Engine/LeadStatus.hs          ← derive Lead status from events
src/Engine/Pricing.hs             ← pricing engine
src/Engine/RiskFlags.hs           ← risk assessment (incl. ReservationOverrun, PR #66;
                                    margin/price ratio через Rational, PR #68)
src/Engine/Marketing.hs           ← funnel / attribution helpers
src/Engine/Treasury.hs            ← ledger analytics + cashboxSnapshot
                                    (Phase A foundation; extended PR #76 csTotalSpent;
                                    csExpectedMargin = plan-based per PR #70)
```

### API

```
src/Api/AppM.hs                   ← fetchOr404 / runDb / recordEvent
src/Api/Types.hs                  ← transport DTOs (incl. CashboxSnapshot,
                                    TransactionResp, ExpenseCategoryResp,
                                    ConfirmPurchaseReq)
src/Api/Server.hs                 ← route composition
src/Api/Health.hs
src/Api/Persons.hs                ← Person + ContactPoint CRUD / resolve
src/Api/Leads.hs                  ← Lead CRUD + offers + quotes + create-deal
src/Api/Deals.hs                  ← AwaitingPayment+ lifecycle + ConfirmPurchase (PR #65)
                                    + reservation lifecycle hooks (PR #66)
src/Api/Treasury.hs               ← transactions / balance / cashbox snapshot
                                    + manual expenses CRUD (PR #72)
                                    + expense categories CRUD (PR #72)
                                    + free-balance guard (PR #72/#75)
                                    + guardFreeBalanceAfter* (refactored in Phase C
                                    из Api.Deals)
src/Api/Marketing.hs              ← settings-side marketing CRUD
src/Api/MarketingAnalytics.hs     ← dashboards / metrics
src/Api/Conversations.hs          ← thread metadata
src/Api/Messages.hs               ← message ingest / outbox / history
src/Api/PricingSettings.hs
src/Api/ServiceState.hs
```

### Persistence / tests

```
src/Db/Schema.hs                  ← Persistent schema (включая ExpenseCategory,
                                    Reservation, OperationalExpense entities)
src/Db/Indexes.hs                 ← index definitions
src/Db/Dm7MigrationLegacy.hs      ← one-shot legacy migration helper
migrations/                       ← dbmate migrations
test/                             ← Haskell tests (~539 на момент snapshot,
                                    incl. DM-7-C E1–E6 в ApiSpec.hs / TreasurySpec.hs)
```

## Services (`sitka-services/`) — FastAPI / bot / background tasks

```
app/main.py                       ← app startup + periodic tasks
app/config.py                     ← env / feature toggles
app/core_client/client.py         ← HTTP client to core

app/routes/parsing.py             ← sourcing/search endpoints
app/routes/webhooks.py            ← inbound hooks

app/bot/telegram_bot.py
app/bot/manager/__init__.py       ← manager commands wiring
app/bot/manager/create_flow.py    ← lead-first /new flow
app/bot/manager/handlers.py       ← read-side bot commands

app/channels/avito/client.py      ← Avito developer API client

app/parsers/inventory_v2.py       ← адаптер для vendored US-store parser

app/tasks/deal_expiration.py      ← AwaitingPayment TTL sweeper
app/tasks/avito_poller.py         ← inbound message poller
app/tasks/avito_sender.py         ← outbound sender
app/tasks/exchange_rate.py        ← FX updater

app/inventory/                    ← US-store inventory parser (forked 2026-05-27 из
                                    vendor/inventory_parser @ a7dc558 PR #67). Series:
                                    PR #90 (TASK A — переезд + чистка 30K dead),
                                    PR #91 (TASK B — substring drop),
                                    PR #93 (TASK C — per-adapter timeout cap).
                                    Подмодули: adapters/ (base + families/ + stores/),
                                    runtime/ (service + execution + postprocess + session),
                                    catalog/sitka_canon.py, query.py, types.py, registry.py,
                                    _governor.py + proxy_pool.py (бывший snapshot/),
                                    _sitka_catalog.py (10 символов из avito vendor; A2
                                    дотащит остальные 15).
vendor/avito_parser/              ← vendored Avito parser v2 (PR #55). Аудит запланирован
                                    как next-after-fork (после TASK A2).

tests/                            ← Python tests
```

## Web (`sitka-web/`) — React / TypeScript / Vite

### Core shells / hooks

```
src/App.tsx
src/AppLayout.tsx                 ← top-nav: Сделки / Касса / Сообщения /
                                    Парсер / База знаний / Маркетинг
src/api/types.ts                  ← TS mirror of backend DTOs
src/api/client.ts                 ← frontend client
src/hooks/useAppState.ts          ← deal-side shell state
                                    (workspace.view union включает 'cashbox')
src/hooks/useMessageInbox.ts      ← message inbox state
src/hooks/useEventStream.ts       ← SSE; subscribers: useAppState +
                                    CashboxWidget (PR #75 live refresh)
```

### Operator views

```
src/components/AppLayout.tsx                   ← (см. выше)
src/components/AnalyticsDashboard.tsx         ← Сделки tab; mounts CashboxWidget
src/components/CashboxScreen.tsx              ← Касса top-tab (PR #77, IA refactor):
                                                CashboxWidget сверху +
                                                OperationalExpenseManager снизу
src/components/CashboxWidget.tsx              ← Variant B cells: Всего / Свободно /
                                                В резерве / Потрачено / Прибыль
                                                закрытых сделок (PR #77)
src/components/DealWorkspace.tsx              ← "Сделки" workspace
src/components/ContextPanel.tsx
src/components/DealStatsWidget.tsx
src/components/ErrorBoundary.tsx
src/components/InboxSidebar.tsx
src/components/MarketingAnalyticsSection.tsx
src/components/PricingSettingsPanel.tsx
src/components/SourceSelector.tsx

src/components/workspace/                     ← stage pieces
  AwaitingPaymentStep.tsx                     ← TTL / contacts / confirm
  ConfirmedStep.tsx                           ← post-prepayment; mounts
                                                <DealFinancialBlock /> (PR #75)
  DealFinancialBlock.tsx                      ← unified deal financial breakdown
                                                (PR #75; reusable across steps)
  FulfillmentStep.tsx                         ← shipping-expense form +
                                                reservation lifecycle UI (PR #66)
  CompletedStep.tsx
  ClientBanner.tsx
  ClientCard.tsx
  StageIndicator.tsx
  helpers.ts

src/components/message-inbox/                 ← Сообщения tab
  MessageInbox.tsx
  MessageInboxSidebar.tsx
  ThreadDetail.tsx
  ReplyForm.tsx
  CreateDealModal.tsx                         ← auto-Lead → Create-Deal in chat
                                                (PR #50, DM-6.2.5-g)

src/components/settings/                      ← Маркетинг tab
  MarketingSettings.tsx                       ← главный экран settings
  ExpenseCategoryManager.tsx                  ← категории расходов (PR #74)
                                                с RU→Latin slug auto-gen (PR #77)
  OperationalExpenseForm.tsx                  ← форма ввода ручного расхода (PR #74)
  OperationalExpenseManager.tsx               ← список + фильтры расходов (PR #74)

src/components/knowledge/                     ← База знаний tab (KB Catalog)
src/components/parser/                        ← Парсер screen
                                                (sticky calculator sidebar PR #69)
```

### Tests / constants

```
src/constants/statuses.ts
src/constants/stores.ts
e2e/                              ← Playwright specs (~41 на момент snapshot)
```

### Retired

```
src/components/lead-inbox/        ← УПРАЗДНЕНО в DM-6.2.5-h+ (PR #51).
                                    Lead Inbox tab вырезан; lead-flow живёт
                                    в Message Inbox через CreateDealModal.
```

## Infra

```
Makefile
docker-compose.yml
docker-compose.prod.yml            ← production deploy (PR #79 PGDG repo для libpq16+;
                                     PR #80 wget в services container)
deploy/
scripts/
.github/workflows/ci.yml
.env.example
docs/DM-7-cashbox.md               ← живой дизайн-док cashbox (Phase A/B/C/D)
```

## Reading shortcuts

- **pre-sale flow:** `Domain.Person` + `Domain.Lead` + `Api.Leads` +
  `sitka-web/src/components/message-inbox/` (lead-flow живёт в Message Inbox после DM-6.2.5-h+)
- **деньги / cashbox:** `Domain.Transaction` + `Domain.Reservation` +
  `Domain.ExpenseCategory` + `Engine.Treasury` (cashboxSnapshot) + `Api.Treasury` +
  `sitka-web/src/components/CashboxScreen.tsx` + `workspace/DealFinancialBlock.tsx`
- **Deal lifecycle:** `Domain.Deal` + `Domain.Deal.StateMachine` + `Api.Deals` +
  `workspace/{AwaitingPaymentStep, ConfirmedStep, FulfillmentStep, CompletedStep}.tsx`
- **сообщения:** `Domain.Conversation` + `Api.Messages` + `app/tasks/avito_*` +
  `src/components/message-inbox/`
- **парсер:** `app/parsers/inventory_v2.py` (backwards-compat alias) → `app/inventory/`
  (US-stores, форкнут из vendor 2026-05-27) / `vendor/avito_parser/` (Avito) +
  `src/components/parser/`
- **knowledge base (БЗ):** см. `Api.Messages` + KB-related endpoints +
  `src/components/knowledge/`
