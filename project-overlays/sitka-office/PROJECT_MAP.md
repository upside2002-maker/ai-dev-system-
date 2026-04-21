# Sitka Office — Project Map

Путь: `/Users/ilya/Projects/sitka-office`
Актуальность: snapshot `679b188` от `2026-04-21`

Это не полная распечатка дерева, а карта тех зон, в которые сейчас
реально приходится заходить агентам.

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
src/Domain/Conversation.hs        ← thread metadata + send status
src/Domain/Transaction.hs         ← treasury ledger
src/Domain/Marketing.hs           ← channels / campaigns / listings
src/Domain/Marketing/Attribution.hs
src/Domain/Marketing/Spend.hs
src/Domain/Reason.hs              ← typed reject/cancel/disqualify reasons
```

### Engines

```
src/Engine/IdentityResolution.hs  ← ContactPoint -> Person matching
src/Engine/LeadStatus.hs          ← derive Lead status from events
src/Engine/Pricing.hs             ← pricing engine
src/Engine/RiskFlags.hs           ← risk assessment
src/Engine/Marketing.hs           ← funnel / attribution helpers
src/Engine/Treasury.hs            ← ledger analytics
```

### API

```
src/Api/AppM.hs                   ← fetchOr404 / runDb / recordEvent
src/Api/Types.hs                  ← transport DTOs
src/Api/Server.hs                 ← route composition
src/Api/Health.hs
src/Api/Persons.hs                ← Person + ContactPoint CRUD / resolve
src/Api/Leads.hs                  ← Lead CRUD + offers + quotes + create-deal
src/Api/Deals.hs                  ← AwaitingPayment+ lifecycle + logistics
src/Api/Treasury.hs               ← transactions / balance / cashflow
src/Api/Marketing.hs              ← settings-side marketing CRUD
src/Api/MarketingAnalytics.hs     ← dashboards / metrics
src/Api/Conversations.hs          ← thread metadata
src/Api/Messages.hs               ← message ingest / outbox / history
src/Api/PricingSettings.hs
src/Api/ServiceState.hs
```

### Persistence / tests

```
src/Db/Schema.hs                  ← Persistent schema
src/Db/Indexes.hs                 ← index definitions
src/Db/Dm7MigrationLegacy.hs      ← one-shot legacy migration helper
migrations/                       ← dbmate migrations
test/                             ← Haskell tests (core + API + invariants)
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

app/tasks/deal_expiration.py      ← AwaitingPayment TTL sweeper
app/tasks/avito_poller.py         ← inbound message poller
app/tasks/avito_sender.py         ← outbound sender
app/tasks/exchange_rate.py        ← FX updater

tests/                            ← Python tests
```

## Web (`sitka-web/`) — React / TypeScript / Vite

### Core shells / hooks

```
src/App.tsx
src/AppLayout.tsx
src/api/types.ts                  ← TS mirror of backend DTOs
src/api/client.ts                 ← frontend client
src/hooks/useAppState.ts          ← deal-side shell state
src/hooks/useLeadInbox.ts         ← pre-sale lead journey
src/hooks/useMessageInbox.ts      ← message inbox state
src/hooks/useEventStream.ts       ← SSE
```

### Operator views

```
src/components/lead-inbox/        ← "Входящие"
  LeadInbox.tsx
  LeadInboxSidebar.tsx
  LeadDetailPanel.tsx
  LeadJourneySections.tsx
  CreateLeadModal.tsx

src/components/DealWorkspace.tsx  ← "Сделки" (post-Confirmed path)
src/components/workspace/         ← fulfillment / completed / stage pieces

src/components/message-inbox/     ← message inbox
  MessageInbox.tsx
  MessageInboxSidebar.tsx
  ThreadDetail.tsx
  ReplyForm.tsx

src/components/settings/          ← marketing settings managers
src/components/AnalyticsDashboard.tsx
src/components/MarketingAnalyticsSection.tsx
src/components/PricingSettingsPanel.tsx
```

### Tests / constants

```
src/constants/statuses.ts
src/constants/stores.ts
e2e/                              ← Playwright specs
```

## Infra

```
Makefile
docker-compose.yml
docker-compose.prod.yml
deploy/
scripts/
.github/workflows/ci.yml
.env.example
```

## Reading shortcuts

- если задача про pre-sale flow: `Domain.Person` + `Domain.Lead` +
  `Api.Leads` + `sitka-web/src/components/lead-inbox/`
- если задача про оплату / деньги: `Domain.Transaction` +
  `Api.Treasury` + `DealWorkspace`
- если задача про сообщения: `Domain.Conversation` + `Api.Messages` +
  `app/tasks/avito_*` + `src/components/message-inbox/`
