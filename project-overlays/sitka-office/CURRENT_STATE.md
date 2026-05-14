# Sitka Office — Current State

Дата: 2026-05-14
Snapshot commit: `7b069a7` (`ci(deploy): автоматический деплой через GitHub Actions + scope detection + auto-rollback (#87)`). Perimeter fix задеплоен 2026-05-11. После него в master: PR #82 (portable `~/Projects/...` пути в `.claude/`), PR #83 (рабочий калькулятор парсера, master `936ccdb`), PR #84 (буфер курса в калькуляторе парсера, master `f048c9b`), PR #85 (расширение CODEOWNERS до 2-tier protection model, master `19ddeef`), PR #86 (wget в Dockerfile core + точечные deploy-команды в DEPLOY.md, master `42be920`; долгосрочный фикс инцидента 2026-05-13), PR #87 (automated deploy через GitHub Actions с scope detection + auto-rollback, master `7b069a7`; включён, протестирован на пустом diff 2026-05-14 01:26Z).
Repo: `~/Projects/sitka-office`

## Phase status

DM-6.2.5 закрыта целиком. DM-7 спроектирован как четыре фазы (по
коммиту `dm-7-a` "Phase A of 4"). На сегодня **Phase A, B и C
закрыты целиком**, production живёт с 2026-05-02 на VPS
`94.72.112.106:8088` (internal IP-only, без DNS/SSL,
`CORE_AUTH=disabled`, Avito poller / Telegram bot / Apify parser
running, knowledge seeded на 284 моделей, Avito backfill 1102+
сообщений с 2026-02-01). **Phase D** scope — в
`/Users/ilya/Projects/sitka-office/docs/DM-7-cashbox.md`, в overlay
не оформлен; active backlog — один DRAFT mini-TASK
`2026-04-29-dm7-c-backend-widget-prereq` (класс A backend, не
срочно, см. `OPERATING.md`). Хронология — `OPERATING/journal/` + `git log master`.

## Архитектура

Трёхслойная: `sitka-core` (Haskell Servant + Persistent + Warp,
:8080), `sitka-services` (Python FastAPI + Telegram + crons + Avito
tasks, :8081), `sitka-web` (React 19 + TypeScript + Vite, :5173).
PostgreSQL 16 + Redis 7 через docker-compose. CI: 7 обязательных
проверок (formatter / import rules / migration drift / Haskell /
Python / frontend / pre-commit). Миграции через `dbmate`, без
auto-migration.

## Бизнес-flow

```
incoming signal
  → person resolve
  → lead create
  → offers + quote attach to lead
  → create-deal-from-lead
  → Deal.AwaitingPayment
  → ConfirmPrepayment
  → Deal.Confirmed + Client materialised + Treasury row
  → Purchased → logistics chain → Completed
```

Границы: pre-sale живёт на `Person + Lead`; post-payment execution
живёт на `Deal`; `Client` создаётся только при первой оплате. Cashbox
(append-only `transaction` ledger + `deal_reservation` + manual
`expense_category`) — единый учёт денег, не parallel-bookkeeping.

## Quality / invariants

- **Тесты:** sitka-core 16 test files (~537 cases по grep на `it/prop`), sitka-services 18 pytest files, sitka-web 18 vitest + 9 Playwright e2e. Точные counts фиксируются в commit messages при merge — см. `OPERATING/journal/`.
- **Authoritative invariants:**
  `/Users/ilya/Projects/sitka-office/CLAUDE.md` +
  `/Users/ilya/Projects/sitka-office/.claude/architecture-invariants.md`
  (highest priority — wins over any prompt).

## Git snapshot

- HEAD: `7b069a7` (`ci(deploy): автоматический деплой через GitHub Actions + scope detection + auto-rollback (#87)`).
- Untracked в проде repo: `.claude/worktrees/` (gitignored),
  `sitka-services/.cache/` (локальный кеш).
- Интервал `39873d2..7b069a7` = **17 commits** (PR #71-#87; per-PR detail — `OPERATING/journal/2026-04.md` + `2026-05.md`).
- Snapshot drift: overlay допускает natural lag за активным проектом
  до следующего refresh.

## Что читать дальше

1. `OPERATING.md` — dashboard: активные TASKS / HANDOFFS / Reviewer findings.
2. `STATUS_RU.md` — пользовательский статус без английской терминологии.
3. `OPERATING/journal/<YYYY-MM>.md` — журнал событий по датам.
4. `OPERATING/backlog.md` — открытые мелочи.
5. `KNOWN_ISSUES.md` / `NEXT_ACTIONS.md` / `PROJECT_MAP.md` — overlay глубже.
6. `/Users/ilya/Projects/sitka-office/docs/DM-7-cashbox.md` — design doc DM-7.
