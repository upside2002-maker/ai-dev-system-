# Sitka Office — Current State

Дата: 2026-04-15

## Архитектура

Три слоя, все работают:

- `sitka-core` — Haskell (Servant + Persistent + Warp), порт 8080
- `sitka-services` — Python (FastAPI + Uvicorn + Telegram bot), порт 8081
- `sitka-web` — React 19 + TypeScript + Vite, порт 5173
- PostgreSQL 16 + Redis 7 через docker-compose
- CI: GitHub Actions (build + test + lint)
- Auth: bearer token (CORE_API_TOKEN / SITKA_API_TOKEN)

## Core (2,193 строк Haskell)

- 6 newtypes с PersistField instances: USD, RUB, Percent, ExchangeRate, Money, EntityId
- DealStatus ADT: 13 конструкторов (New → Completed/Rejected/Cancelled)
- RiskFlag ADT: 6 конструкторов
- Pure state machine: 12 типов переходов, canTransition/transition/allowedTransitions
- Pure pricing engine: calculateCost, calculateQuotePrice, calculateMargin, calculateClientSavings
- Risk engine: Engine/RiskFlags.hs
- 8 DB таблиц через Persistent TH
- 15 API endpoints (Servant type-level composition)
- Extracted helpers: fetchOr404, runDb, recordEvent, validateOr400 (в Api/AppM.hs)
- GHC flags: -Wall -Werror -Wincomplete-patterns -Wunused-imports
- Тесты: 12 (state machine + pricing)

## Services (3,156 строк Python)

- Sourcing pipeline: 16 US-магазинов + Avito (Playwright)
- Avito parser (stealth mode) + mock fallback
- Core client (HTTP к Haskell, timeout + retry)
- **Telegram bot** (5 модулей, 1100+ строк): deal creation flow, manager commands, inline keyboards, callbacks
- **Notifications**: event watcher + notifier
- **Exchange rate**: auto-update от CBR API
- Webhook routes
- Auth middleware
- Pydantic Settings

## Web (6,766 строк TypeScript/CSS)

- Workspace layout: InboxSidebar → DealWorkspace → ContextPanel
- Step-based workflow: NewRequest → Sourcing → ReviewOffers → QuoteReady → Fulfillment → Completed
- PricingSettingsPanel
- AnalyticsDashboard + DealStatsWidget
- useAppState hook (extracted state management, 515 строк)
- WorkspaceContext (React context)
- useEventStream hook (SSE)
- E2E тесты: 3 Playwright specs
- API client с typed endpoints

## Infra

- Docker Compose: dev + prod profiles
- Production: docker-compose.prod.yml с migrations, JSON logging, SSL/certbot, daily backups
- nginx: deploy/nginx-prod.conf
- Scripts: init-letsencrypt.sh, backup-pg.sh
- CI: .github/workflows/ci.yml
- Makefile: 23 targets

## Self-learning

- CLAUDE.md: 12 правил + what exists + what not to do (обновлён 2026-04-15)
- .claude/corrections.md: 7 записей
- .claude/review-checklist.md: 29 строк
- .claude/reference-snippets/: 3 Haskell эталона
- .claude/prompts/task-splitting.md: шаблоны задач
- sitka-core/.hlint.yaml: errors + warnings + suggestions

## Git

7 коммитов на master. Working directory чистый.
