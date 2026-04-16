# Sitka Office — Project Map

Путь: `/Users/ilya/Projects/sitka-office`

## Core (sitka-core/) — Haskell, Servant, Persistent, Warp :8080

```
src/Domain/Types.hs              ← USD, RUB, Percent, ExchangeRate + PersistField
src/Domain/Client.hs             ← Client record
src/Domain/Deal.hs               ← DealStatus (13), RiskFlag (6), Deal record (22 поля)
src/Domain/Deal/StateMachine.hs  ← Pure: 12 transitions, canTransition, allowedTransitions
src/Domain/Quote.hs              ← Quote, CostBreakdown
src/Domain/Offer.hs              ← UsaOffer
src/Domain/Event.hs              ← Domain events
src/Domain/Order.hs              ← Order tracking
src/Domain/Payment.hs            ← Payments
src/Domain/Shipment.hs           ← Shipments

src/Engine/Pricing.hs            ← Pure: calculateCost, calculateQuotePrice, calculateMargin
src/Engine/RiskFlags.hs          ← Risk assessment logic

src/Db/Schema.hs                 ← 8 Persistent tables
src/Db/Indexes.hs                ← DB indexes

src/Api/AppM.hs                  ← fetchOr404, runDb, recordEvent, validateOr400
src/Api/Types.hs                 ← Transport types (request/response records)
src/Api/Server.hs                ← Servant API composition + CORS
src/Api/Health.hs                ← Health check
src/Api/Clients.hs               ← Client CRUD
src/Api/Deals.hs                 ← Deal CRUD + transitions + offers + stats
src/Api/Quotes.hs                ← Quotes + pricing settings

app/Main.hs                      ← Entry point
test/Spec.hs                     ← Tests (12)
```

## Services (sitka-services/) — Python, FastAPI, Uvicorn :8081

```
app/main.py                      ← FastAPI app, CORS, lifespan
app/config.py                    ← Pydantic Settings
app/deps.py                      ← Dependency injection
app/logging_config.py            ← Structured logging

app/routes/parsing.py            ← Sourcing endpoints
app/routes/webhooks.py           ← Webhook handlers

app/core_client/client.py        ← HTTP client к core

app/parsers/avito.py             ← Playwright Avito parser
app/parsers/avito_mock.py        ← Mock fallback
app/parsers/avito_classify.py    ← Classification
app/parsers/inventory_v2.py      ← US store parser factory

app/bot/telegram_bot.py          ← Bot initialization
app/bot/formatters.py            ← Message formatting
app/bot/manager/__init__.py      ← Bot manager orchestration
app/bot/manager/handlers.py      ← Command handlers
app/bot/manager/callbacks.py     ← Callback query handlers
app/bot/manager/cards.py         ← Inline keyboard builders
app/bot/manager/create_flow.py   ← Deal creation conversation
app/bot/manager/auth.py          ← Bot authentication

app/notifications/notifier.py    ← Notification dispatch
app/notifications/event_watcher.py ← Event stream consumer

app/tasks/exchange_rate.py       ← CBR exchange rate updater
```

## Web (sitka-web/) — React 19, TypeScript, Vite :5173

```
src/App.tsx                       ← Root (17 строк, thin)
src/AppLayout.tsx                 ← Layout wrapper
src/api/types.ts                  ← TypeScript types (зеркало Haskell)
src/api/client.ts                 ← API client (core + services)
src/hooks/useAppState.ts          ← Global state (515 строк)
src/hooks/useEventStream.ts       ← SSE hook
src/contexts/WorkspaceContext.tsx  ← React context

src/components/InboxSidebar.tsx
src/components/DealWorkspace.tsx
src/components/ContextPanel.tsx
src/components/PricingSettingsPanel.tsx
src/components/AnalyticsDashboard.tsx
src/components/DealStatsWidget.tsx
src/components/ErrorBoundary.tsx

src/components/workspace/
  NewRequestStep.tsx
  SourcingStep.tsx
  ReviewOffersStep.tsx
  QuoteReadyStep.tsx
  FulfillmentStep.tsx
  CompletedStep.tsx
  StageIndicator.tsx
  ClientBanner.tsx
  helpers.ts

src/constants/stores.ts           ← 16 US stores
src/constants/statuses.ts         ← Status display config
src/constants/formatters.ts       ← Number/date formatters

e2e/                              ← Playwright E2E tests
```

## Infra

```
Makefile                          ← 23 targets
docker-compose.yml                ← dev (postgres + redis + apps)
docker-compose.prod.yml           ← production overrides
deploy/nginx-prod.conf            ← nginx reverse proxy
scripts/init-letsencrypt.sh       ← SSL setup
scripts/backup-pg.sh              ← DB backup
.github/workflows/ci.yml          ← CI pipeline
.env.example                      ← Environment template
```

## Self-learning (.claude/)

```
corrections.md                    ← 7 anti-pattern records
review-checklist.md               ← Pre-commit checks
reference-snippets/               ← 3 Haskell etalons
prompts/task-splitting.md         ← Task templates
```
