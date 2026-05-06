# Sitka Office — Current State

Дата: 2026-05-02 EOD
Snapshot commit: `b58e5fb` (post PR #78 layout + #79 PGDG + #80 services-wget). **Production live:** http://94.72.112.106:8088, internal IP-only (no DNS/SSL), CORE_AUTH=disabled, Avito poller + Telegram bot + Apify parser running, knowledge seeded (284 моделей), Avito backfill (1102+ messages с 2026-02-01).
Repo: `/Users/ilya/Projects/sitka-office`

## TL;DR

`sitka-office` больше не находится в Phase 0 / раннем Phase 1 / mid DM-6.2.5.
Текущая форма проекта — **DM-7 cashbox refactor, Phase A + B + C закрыты целиком, production live**:

- DM-6.2.5 закрыта целиком (буквы a–r)
- DM-7 спроектирован как четыре фазы (по коммиту `dm-7-a`: "Phase A of 4")
- Phase A merged (#63: `cashbox foundation — reservations, categories, snapshot`)
- **Phase B закрыта тремя PR:**
  - #64 / B-1: `ConfirmPrepayment strict + reservation insert + legacy backfill`
  - #65 / B-2: `ConfirmPurchase endpoint + DROP COLUMN actuals` (backend) + `ConfirmedStep` (frontend) + fix purchase guard на free-balance
  - #66 / B-3: `shipping-expense + reservation lifecycle hooks` — outflow accounting, ConfirmDelivery/CancelDeal idempotent hooks, новый ReservationOverrun risk-flag, FulfillmentStep UI
- **Phase C Core закрыта (#72, 2026-04-29):** 4 endpoint-а в `Api.Treasury` (categories CRUD + manual expense POST, RUB-only), tri-state Aeson PATCH (новый паттерн в репе для unset-of-nullable), free-balance guard расширен на `createManualExpense` (теперь покрывает все 5 outgoing handler'ов), generic `POST /transactions` rejects `OperationalExpense + SourceManual` с redirect, `guardFreeBalanceAfter*` перенесены `Api.Deals → Api.Treasury` (4 Phase B call sites обновлены). 538/538 tests green. Reviewer round (Codex red-team) выявил 2 P1 finding'а — оба закрыты в том же PR через follow-up commit.
- **Phase C Frontend закрыта** (5 PR в порядке merge):
  - #73 (2026-04-29): docs sync DM-7-C Core closure в `docs/DM-7-cashbox.md`
  - #74 (2026-05-01): frontend UI tab «Прочие расходы» + manual expense form + category CRUD (1646 LOC, 150 vitest + 41 Playwright)
  - #75 (2026-05-01): unified `<DealFinancialBlock>` в Confirmed step + cashbox live refresh через `useEventStream` + shipping-expense status gating (`status ∈ {InKazakhstan, ShippedRu, Delivered}`)
  - #76 (2026-05-01): backend prereq для Variant B widget — `csTotalSpent :: RUB` в `CashboxSnapshot` wire shape
  - #77 (2026-05-01): «Касса» top-tab + Variant B widget cells (Всего / Свободно / В резерве / Потрачено / Прибыль закрытых) + slug auto-gen с RU→Latin transliteration
  - #78 (2026-05-02): cashbox screen layout fix (single-col grid + drop duplicate header)
- **Production deploy (2026-05-02):** первый prod на VPS `94.72.112.106:8088`, internal IP-only (no DNS/SSL), `CORE_AUTH=disabled`. Deploy fixes: #79 (libpq-dev в core builder через PGDG repo) + #80 (wget в services container для compose healthcheck). Avito poller / Telegram bot / Apify parser running, knowledge seeded (2553 sections / 284 моделей), Avito backfill 1102+ сообщений с 2026-02-01.
- **Phase D** — scope в `/Users/ilya/Projects/sitka-office/docs/DM-7-cashbox.md`, в overlay не зафиксировано. Active mini-TASK на backend prereq: `2026-04-29-dm7-c-backend-widget-prereq` (`trExpenseCategoryId :: Maybe Int64` в `Api.TransactionResp` для будущей категория-разбивки в widget) — Status: open / DRAFT / не срочно (запускать только когда оператор захочет breakdown).
- **Live-smoke fixes на текущем master (PR #68–#70):**
  - #68: `RiskFlags margin/price ratio через Rational, не Scientific` — фикс long-standing serialization bug, существовал с DM-3 (тесты на круглых числах, реальная сделка `23000/78000` рейзит)
  - #69: parser UX — sticky calculator sidebar (340px) + sourcing timeout 45s→90s (cold-cache eurooptic-adapter ~18s)
  - #70: `csExpectedMargin = plan-based` — выравнивание реализации с Phase A docs (Phase B-2 этого не сделала; conservative running-diff заменён на `quotedPrice − plannedCost − reservation.planned`)
- **Vendor inventory parser подключён (#67)** — US-store parser ~2.1 MB vendored из `upside2002-maker/sitka @ a7dc558`, через адаптер `sitka-services/app/parsers/inventory_v2.py`; public API совместим
- Lead-first flow остаётся единственным живым write-path; legacy Client-first вырезан
- Person / ContactPoint / Lead / Treasury / Conversations / Cashbox (reservations, categories, snapshot) — в ядре
- UI: `Входящие` + `Сделки` + Message Inbox + AwaitingPayment + KB Catalog + FulfillmentStep (Lead-Inbox упразднён в DM-6.2.5-h+)
- Подсистемы существовавшие до 089191d: knowledge base (ingest+FTS, /kb Telegram, KB Catalog UI), vendor Avito parser v2 + `/api/avito/search`

Это важно: старые документы про `NewRequest -> Sourcing -> QuoteReady`
нужно читать только как историю.

## Архитектура

Система по-прежнему трёхслойная:

- `sitka-core` — Haskell (Servant + Persistent + Warp), `:8080`
- `sitka-services` — Python (FastAPI + Telegram + crons + Avito tasks), `:8081`
- `sitka-web` — React 19 + TypeScript + Vite, `:5173`
- PostgreSQL 16 + Redis 7 через docker-compose
- CI: 7 обязательных проверок
- миграции: `dbmate`, без auto-migration

## Текущий бизнес-flow

Источник правды по состоянию домена теперь такой:

```
incoming signal
  -> person resolve
  -> lead create
  -> offers + quote attach to lead
  -> create-deal-from-lead
  -> Deal.AwaitingPayment
  -> ConfirmPrepayment
  -> Deal.Confirmed + Client materialised + Treasury row
  -> Purchased -> logistics chain -> Completed
```

Ключевая граница:

- pre-sale живёт на `Person + Lead`
- post-payment execution живёт на `Deal`
- `Client` создаётся только при первой оплате

## Core (Haskell)

### Доменные сущности

В активной модели уже есть:

- `Person`, `ContactPoint`, `Lead`, `Lead.Event`
- `Deal`, `Quote`, `Offer`, `Reason`
- `Conversation`
- `Marketing` + attribution
- `Transaction` (treasury ledger)

### API surface

В кодовой базе уже есть отдельные модули:

- `Api.Persons`
- `Api.Leads`
- `Api.Deals`
- `Api.Treasury`
- `Api.Marketing`
- `Api.MarketingAnalytics`
- `Api.Conversations`
- `Api.Messages`
- `Api.PricingSettings`
- `Api.ServiceState`

### Важная оговорка

Legacy-конструкторы `DealStatus` и старые `Transition` ещё
компилируются как мёртвая поверхность, но текущий runtime-path их не
создаёт. Они остались ради совместимости внутренних helper-ов и
аналитических mapping-ов.

## Services (Python)

Слой services уже тоже ушёл далеко от описания "Phase 0":

- Telegram bot переведён на lead-first создание
- есть `deal_expiration.py` для TTL / auto-expire
- есть Avito poller / sender tasks
- есть канальный Avito client
- старый create-deal-from-sourcing путь уже вырезан
- vendor inventory parser (US-stores) — vendored из `upside2002-maker/sitka` в `sitka-services/vendor/inventory_parser/`, через адаптер `app/parsers/inventory_v2.py` (PR #67)

Важно: часть Avito-функций остаётся credentials-gated и по умолчанию
может no-op'иться, пока не заданы реальные ключи/настройки.

## Web (React)

Фронт уже не является только legacy workspace.

Актуальная форма UI (top-nav после Phase C Frontend, PR #77):

- `Сделки` — post-Confirmed deal workspace, включает AwaitingPayment / ConfirmedStep (с unified `<DealFinancialBlock>` PR #75) / FulfillmentStep
- `Касса` (PR #77, 2-я в nav) — `<CashboxWidget />` Variant B cells сверху (Всего / Свободно / В резерве / Потрачено / Прибыль закрытых) + `<OperationalExpenseManager />` снизу
- `Сообщения` — Message Inbox (треды)
- `Парсер` — ParserScreen, sticky calculator sidebar 340px (PR #69)
- `База знаний` — KB Catalog
- `Маркетинг` — marketing settings, analytics dashboard, новый таб `Прочие расходы` (PR #74) с manual expense form + category CRUD
- (Lead Inbox / `Входящие` упразднён в DM-6.2.5-h+)

То есть операторский интерфейс уже реально разделён по фазам процесса,
а не крутится вокруг одной legacy карточки сделки.

## Quality / safety

- в Haskell-ядре — сотни тестов
- в Python — десятки test files
- во фронте — `12` E2E spec files + unit tests
- CI жёстко прогоняет formatter / import rules / migration drift /
  Haskell / Python / frontend

Отдельный источник правды по инвариантам:

- `/Users/ilya/Projects/sitka-office/CLAUDE.md`
- `/Users/ilya/Projects/sitka-office/.claude/architecture-invariants.md`

## Git snapshot

На момент синхронизации overlay:

- HEAD: `b58e5fb` (`fix(deploy): install wget in services container for compose healthcheck`)
- рабочее дерево содержит untracked `.claude/worktrees/` (в `.gitignore`) и `sitka-services/.cache/` (локальный кеш)
- За интервал `39873d2..b58e5fb` — 10 PR-ов: docs sync Phase B-3 (#71), Phase C Core (#72/#73), Phase C Frontend (#74/#75/#76/#77/#78), production deploy fixes (#79/#80). Замечание из прошлых refresh про natural lag overlay в активном проекте остаётся в силе.

## Что читать дальше

1. `README.md` в этом overlay
2. `KNOWN_ISSUES.md`
3. `NEXT_ACTIONS.md`
4. `PROJECT_MAP.md`
5. Для глубины: `DOMAIN_V3.md`, `PHASE_DM_TASKS.md`, `ARCHITECTURE_V2.md`
