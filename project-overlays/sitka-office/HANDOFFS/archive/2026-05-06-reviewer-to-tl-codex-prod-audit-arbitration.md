# HANDOFF: reviewer → tl — codex-prod-audit-arbitration

- Status: closed
- Date: 2026-05-06 16:38
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Codex
- Model: Codex (ChatGPT)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-06-codex-prod-audit-arbitration.md

## Summary

Codex Reviewer прошёл аудит текущего state Sitka на HEAD `b58e5fb` (verified `git -C /Users/ilya/Projects/sitka-office log -1 --oneline`). 5 findings: 1×P1 (prod auth contract drift), 3×P2 (frontend localhost build, Avito cursor cold-start race, recordEvent на manual_expense), 1×P3 (`expenseCategoryId` отсутствует в `TransactionResp` wire shape). TL grep verify прошёл по 11 line-references — все factually correct. Findings описывают **drift между repo defaults и реальным live prod state**, не нарушения инвариантов. Прод сейчас live и работает, потому что server-only override patches компенсируют каждый из P1/P2 fronend-config gaps.

## Done

Codex Reviewer (run от user, runtime Codex):

- Прочитал HEAD `b58e5fb`, working tree only `.claude/*` + `sitka-services/.cache/` untracked.
- Нашёл 5 findings с конкретными file:line references.
- Подтвердил strengths: `-Wall -Werror -Wincomplete-patterns` в `sitka-core.cabal:8`, `.claude/architecture-invariants.md:21` слой/drift инварианты, CI (`.github/workflows/ci.yml:19`) покрывает 7 проверок, `scripts/check-imports.sh --self-test` 7/7 + clean на 48 Haskell файлах.

TL grep verify (Claude Tech Lead, runtime Claude Code, model Opus):

- P1.1 ✓ `docker-compose.prod.yml:22` — `CORE_AUTH: "required"` + `CORE_API_TOKEN: "${CORE_API_TOKEN:?Set CORE_API_TOKEN in .env}"` (fail-fast если не задан).
- P1.2 ✓ `sitka-core/src/Api/Server.hs:77` — `authMiddleware (Just token)` рейзит 401 если token присутствует И request не authorized.
- P1.3 ✓ `sitka-services/app/core_client/client.py:67` — `await self._http().request(method, ..., json=json)` без Authorization header.
- P1.4 ✓ `sitka-web/src/api/client.ts:102` — fetch headers только `Content-Type` для bodied requests, без Authorization.
- P1.5 ✓ `deploy/nginx-prod.conf:86` — `proxy_set_header Host/X-Real-IP/X-Forwarded-*` только, нет `proxy_set_header Authorization`.
- P2.1 ✓ `sitka-web/src/api/client.ts:78` — `import.meta.env.VITE_CORE_API_URL ?? 'http://localhost:8080'` (default localhost вшит в bundle).
- P2.2 ✓ `sitka-web/Dockerfile:9` — `RUN npm run build` без VITE_ env override / build-args.
- P2.3 ✓ `avito_poller.py:192-200` — cold start seed cursor to `now`, return 0; `_save_cursor:299-303` — `except CoreClientError as exc: logger.warning(...)` глотает error без retry / без preserving cursor.
- P2.4 ✓ `sitka-core/src/Api/Treasury.hs:503` — `createManualExpense` не вызывает `recordEvent`. `sitka-web/src/components/CashboxWidget.tsx:31` doc-comment подтверждает что widget refresh завязан на event-stream subscription.
- P3 ✓ `sitka-core/src/Api/Types.hs:1046` — `TransactionResp` без `trExpenseCategoryId`. `Db.Schema.hs` имеет `expenseCategoryId ExpenseCategoryId Maybe`. `Domain.Transaction` имеет `transactionExpenseCategoryId :: Maybe Int64`. `toDomainTransaction:697` маппит. `OperationalExpenseManager.tsx:130-145` — `<td className="mk-muted">—</td>` placeholder с явным comment про backend prereq.

## Remaining

TL classification (см. Conflicts/risks ниже). Если TL принимает finding — либо новый mini-TASK, либо backlog entry в OPERATING.md, либо принятый risk явно зафиксирован.

## Artifacts

- branch: master (ничего не trog'нуто этим Reviewer round'ом — только аудит).
- commit(s): N/A (audit, не code change).
- PR: N/A.
- tests: not run as part of review (Codex смотрел static state).
- Product repo status: **not applicable** — Reviewer не trogал product repo, только читал. AI Dev System overlay получит TASK + HANDOFF + (опционально) update OPERATING backlog.

## Conflicts / risks

Findings описывают **factual drift между repo defaults и реальным live prod state**. TL вердикт по каждому фиксируется в anchor TASK `2026-05-06-codex-prod-audit-arbitration.md` (см. Acceptance criteria там). Кратко:

| # | Severity | Verdict | Триггер / следующий шаг |
|---|----------|---------|-------------------------|
| P1 prod auth contract drift | P1 (Codex) → TL re-evaluated 2026-05-06 после user override → **P1 подтверждён, переформулирован как perimeter gap** | **ПРИНЯТЬ + URGENT** | App-level auth (логин/роли) — отдельная фича, не сейчас. Срочно: **perimeter open** — `8080`/`8081` экспонированы на `0.0.0.0` (verified `curl http://94.72.112.106:8080/api/treasury/cashbox` без bearer → live JSON). Действия: (a) TL inline сейчас — bind ports на `127.0.0.1`; (b) perimeter защита на `8088` (Basic Auth / IP allowlist / VPN — user choice); (c) mirror в `docker-compose.prod.yml`; (d) document app-auth gap в DEPLOY/OPERATING. Полный bearer flow Tier B ~50-100 LOC — после стадии тестирования. |
| P2 frontend localhost build | P2 | **ПРИНЯТЬ** | TL inline patch Tier C ~3-5 LOC: в `client.ts:78` default fallback заменить с `'http://localhost:8080'` на `''` (пустая строка → relative URLs → same-origin works on any host без override). Same для services. Кандидат для следующего quick win. |
| P2 Avito cursor cold-start save race | P2 | **ПРИНЯТЬ** | Mini-TASK Tier A backend ~10-15 LOC: либо retry до save success без advancing cursor, либо preserve last cursor in-memory если save failed. Не блокер немедленно (cold start one-time, окно ≤ 60s = 1 poll cycle). |
| P2 recordEvent на manual_expense | P2 | **ПРИНЯТЬ** (duplicate, уже в backlog) | Mini-TASK Tier A backend ~10-15 LOC. Уже в OPERATING `Open backlog`. Confirmation от Codex. |
| P3 expenseCategoryId DTO gap | P3 | **ОТЛОЖИТЬ** | Уже DRAFT TASK `2026-04-29-dm7-c-backend-widget-prereq.md` (`Status: open`, `Ready: no`). Триггер: оператор хочет breakdown по `expense_category.kind`. До бизнес-триггера не запускаем. |

**Critique для Codex:** good evidence-grounded review (line-refs верны). Severity calibration слегка overshoot на P1 — для текущего internal-only IP-only deploy без bearer auth contract drift = degraded к P2 (фактически прод работает через server-only override; не блокер прямо сейчас). Это не отнимает у finding'а validity — drift между repo и реальностью реален и должен быть закрыт либо изменением default'а, либо реализацией bearer.

## Next step

TL заполняет anchor TASK `codex-prod-audit-arbitration` body (Problem / Scope / Acceptance / Test commands / Handoff requirements) с конкретными verdicts + spawn'ит sub-TASKs где нужно. После закрытия arbitration → `make accept-task` + ручной cleanup OPERATING.

Этот HANDOFF auto-acknowledged TL'ом в момент создания (TL = recipient, Reviewer report полностью прочитан + verified). Closure через `make accept-handoff` после того как TL завершит arbitration TASK.
