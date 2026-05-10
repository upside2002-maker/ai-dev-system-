# TASK: codex-prod-audit-arbitration

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: sitka-office
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: N/A (TL self-arbitration; не делегируется Worker'у)

## Problem

Codex Reviewer (runtime Codex, run от пользователя 2026-05-06) прислал аудит state репо на HEAD `b58e5fb`: 5 findings (1×P1 + 3×P2 + 1×P3) с конкретными file:line references. TL grep verify прошёл — все 11 references factually correct (см. HANDOFF `2026-05-06-reviewer-to-tl-codex-prod-audit-arbitration.md`). Эта TASK — формальная arbitration (ROLE_MODEL §«Арбитраж конфликтов / TL × Reviewer»): по каждому finding фиксируется ПРИНЯТЬ / ОТКЛОНИТЬ / ОТЛОЖИТЬ + действие.

## Scope

**Входит:**
- 5 verdicts × finding с обоснованием.
- Для ПРИНЯТЬ — конкретный action (новый mini-TASK либо backlog item в OPERATING).
- Для ОТЛОЖИТЬ — триггер возврата.
- Update OPERATING `Open backlog` если появились новые items.

**Не входит:**
- Реализация какого-либо из mini-TASKs (отдельные tickets с собственными acceptance).
- Изменение продакт-логики, code, тестов в product repo.

## Files

- new: `project-overlays/sitka-office/HANDOFFS/2026-05-06-reviewer-to-tl-codex-prod-audit-arbitration.md` (created by `make new-handoff`, заполнен TL'ом).
- modify: `project-overlays/sitka-office/OPERATING.md` (backlog section — добавить новые items если нужно).
- delete: —

## Do not touch

- product repo `/Users/ilya/Projects/sitka-office/` — этот TASK исключительно meta-arbitration в overlay.
- любые existing TASK'и (`dm7-c-backend-widget-prereq` остаётся как есть, только confirm как ОТЛОЖИТЬ-триггер).

## Acceptance criteria

- [x] Все 5 findings classified (см. таблицу ниже).
- [ ] Для каждого ПРИНЯТЬ — backlog entry в `OPERATING.md` либо ссылка на existing item с пометкой "Codex confirmed".
- [ ] Для ОТЛОЖИТЬ — триггер возврата явно записан.
- [ ] HANDOFF `reviewer-to-tl-codex-prod-audit-arbitration.md` Status: acknowledged → закрыт через `make accept-handoff` после accept этого TASK.
- [ ] `make check` + `make status SLUG=sitka-office` зелёные.

## Verdicts (5 findings)

| # | Severity | Verdict | Action |
|---|----------|---------|--------|
| **P1 prod auth contract drift** | TL re-evaluated 2026-05-06 после user override → **подтверждён P1, но переформулирован как perimeter security gap, не app-auth gap** | **ПРИНЯТЬ + URGENT** | Codex был прав по факту, но severity calibration: app-level auth (логин / роли / refresh) — отдельная фича, **не сейчас**. Что есть сейчас и срочно: **perimeter open** — `8080` (core) и `8081` (services) экспонированы на `0.0.0.0` через `docker-proxy` на сервере 94.72.112.106. Verified 2026-05-06: `curl http://94.72.112.106:8080/api/treasury/cashbox` без bearer возвращает live JSON (`CORE_AUTH=disabled`). Любой со знанием IP может bypass'нуть web nginx прокси, читать/писать API. **Действия:** (a) **TL inline сейчас**: bind `8080`/`8081` ports на `127.0.0.1` через docker compose override на сервере (только loopback; web container hits через docker network) — ~5 LOC, reversible, non-destructive для UI flow; (b) **Perimeter защита на `8088`** — choice user'а: Basic Auth nginx / IP allowlist / VPN/Tailscale. Spawn'ится sub-TASK после choice; (c) **Mirror в master**: `docker-compose.prod.yml` фиксирует `127.0.0.1:8080`/`127.0.0.1:8081` binding + нгинх Basic Auth example как опция; (d) **Document gap**: DEPLOY.md + OPERATING явно зафиксируют что app-level auth НЕ готова, `CORE_AUTH=disabled` допустим **только внутри закрытого perimeter**, не как public default. Полный bearer flow (services CoreClient + web + nginx Authorization injection) — отдельный TASK Tier B ~50-100 LOC, **не сейчас, после стадии тестирования**. |
| **P2 frontend localhost build** | P2 | **ПРИНЯТЬ** | TL inline patch Tier C ~3-5 LOC (потенциально следующий quick win): в `sitka-web/src/api/client.ts:78-80` default fallback заменить с `'http://localhost:8080'` / `'http://localhost:8081'` на `''` / `'/services'` (пустая строка → relative URLs → same-origin works на любом хосте без VITE_ override). Это закрывает источник bug'а, который мы fix'или server-only `.env` 2026-05-02. Запускать только когда TL даст go (квалифицируется как inline patch — ≤30 LOC, ≤2 файла, не Tier A, без миграций). |
| **P2 Avito cursor cold-start save race** | P2 | **ПРИНЯТЬ** | Backlog item в OPERATING (новый): "Avito cursor cold-start save race — `avito_poller.py:192-200` cold start seed cursor to `now`, return 0; `_save_cursor:299-303` глотает CoreClientError → next tick опять cursor=None → seed `now2 > now1` → пропуск окна `[now1, now2]` (≤60s). Mini-TASK Tier A backend ~10-15 LOC: либо retry на save failure без advancing cursor, либо preserve last cursor in-memory. Не блокер немедленно (one-time на cold start, узкое окно)." |
| **P2 recordEvent на manual_expense** | P2 | **ПРИНЯТЬ** (duplicate, уже в backlog) | Уже в OPERATING `Open backlog`: "`recordEvent` на `manual_expense` insert (Tier A backend, ~10-15 LOC) — чтобы CashboxWidget refreshed после manual expense (currently не event-driven)." Codex confirmation добавлен как evidence. |
| **P3 expenseCategoryId DTO gap** | P3 | **ОТЛОЖИТЬ** | Уже existing DRAFT TASK `TASKS/2026-04-29-dm7-c-backend-widget-prereq.md` (`Status: open`, `Ready: no`). Триггер возврата: **оператор реально захочет breakdown по `expense_category.kind` в widget**. До бизнес-триггера не запускаем — backend поле live unused, UI placeholder `—` явно documented в `OperationalExpenseManager.tsx:130-145` как "deliberate placeholder, не fake join". |

## Test commands

```sh
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=sitka-office
```

## Handoff requirements

Self-arbitration TASK, не делегируется Worker'у. TL заполняет verdicts inline, обновляет OPERATING backlog, потом `make accept-task` для закрытия.

После accept HANDOFF `2026-05-06-reviewer-to-tl-codex-prod-audit-arbitration.md` тоже Status: acknowledged → closed через `make accept-handoff`.
