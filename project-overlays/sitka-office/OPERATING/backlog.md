# Sitka Operating — Backlog

Список открытых мелочей (mini-tasks, drive-by, drafts), не датированных и не блокирующих текущую работу. Обновляется TL/Admin при появлении новых пунктов или закрытии старых.

Соседние артефакты:
- `../OPERATING.md` — текущий dashboard (активные TASK / HANDOFF / Reviewer findings).
- `journal/` — журнал событий по датам.
- `../STATUS_RU.md` — пользовательский статус без английской терминологии (раздел «На очереди» цитирует ближайшие пункты этого backlog).

---

## Production / security

- 🟡 **P1 perimeter gap — фикс в репо готов, ждёт деплоя на сервер.** Принят 2026-05-10 через TASK `sitka-perimeter-close` (Mode: strict, Risk tier A, archive `TASKS/archive/2026-05-10-sitka-perimeter-close.md`). Worker iter1 + Reviewer iter1 (REQUEST CHANGES — web healthcheck бил `/` за `auth_basic`) + Worker iter2 (override healthcheck на `/health` + Compose ≥ 2.20 pre-check в DEPLOY.md) + Reviewer iter2 (ACCEPT). 4 файла в product repo: `docker-compose.prod.yml` (loopback bindings + web healthcheck override), `deploy/nginx-prod.conf` (Basic Auth на `/`, `/api/`, `/services/`), `deploy/htpasswd.example` (dummy), `DEPLOY.md` секция «6. Защита периметра». **До деплоя на сервер perimeter всё ещё открыт** — порты `8080`/`8081` слушают `0.0.0.0` на 94.72.112.106 как раньше. Деплой = отдельная сессия: TL ssh root@94.72.112.106 → `git pull` → `htpasswd -B -c /etc/sitka-htpasswd sitka-ops` → обновить server-only `docker-compose.override.yml` с volume mount → `docker compose up -d --force-recreate web core services` → smoke по чек-листу DEPLOY.md §6.c.

- **Frontend bearer auth flow** — сейчас prod использует `CORE_AUTH=disabled` + `SITKA_API_TOKEN=""` потому что frontend никогда не реализован для bearer header. Если когда-нибудь захочется external exposure (DNS+SSL+Let's Encrypt phase 5) — нужен frontend auth flow ~50-100 LOC + token storage. На internal IP-only сейчас не критично.

## Frontend / build / deploy

- **Frontend localhost build default** (Codex audit 2026-05-06, ПРИНЯТЬ): `sitka-web/src/api/client.ts:78-80` имеет `import.meta.env.VITE_CORE_API_URL ?? 'http://localhost:8080'` — без VITE_ env override на build время в bundle вшит `localhost`. На проде fix'ed server-only `sitka-web/.env` (2026-05-02). Mini-PR TL inline Tier C ~3-5 LOC: заменить default на `''` (relative URLs) + `'/services'`. Same-origin works на любом хосте без override.

- **Mirror server inline patches в `docker-compose.prod.yml`** — на сервере `/opt/sitka-office/docker-compose.override.yml` имеет: `web ports !override 8088:80`, `LANG/LC_ALL=C.UTF-8` в core+services (чтобы dev-format Russian logs не крашили `commitBuffer: invalid argument`), `CORE_DB_CONN` в services env (knowledge_search нужен прямой DB access), `CORE_CORS_ORIGINS` с prod URL. Без mirror в repo — каждый next deploy будет повторять inline patches вручную. Tier C ~30 LOC.

- **web container wget healthcheck** — busybox wget работает, но docker reports unhealthy после ранних failed checks (cosmetic; функция OK). Mini-PR ~5 LOC чтобы поменять healthcheck на `wget --spider` или TCP probe.

## UX / mobile

- **Mobile responsive** (отложено 2026-05-02 per user) — frontend desktop-first, 23 `@media` rules покрывают workspace-shell/funnel но Касса tab + Variant B widget + ExpenseCategoryManager без mobile-стилей. Tier C ~100-300 LOC + audit всех 6 tabs на 375px viewport.

- Messages layout bug — header перекрывает top-nav. Ждёт скрин для точной диагностики. Tier C, ~20 LOC. Кандидаты root-cause до скрина: top-nav `position: sticky/fixed` с `z-index` выше Lead detail header; либо `padding-top` body не учитывает высоту top-nav. Файлы: вероятно `sitka-web/src/components/message-inbox/MessageInbox.tsx` + общий CSS top-nav.

## Backend / data integrity

- **Avito cursor cold-start save race** (Codex audit 2026-05-06, ПРИНЯТЬ): `avito_poller.py:192-200` cold start seed cursor to `now`, return; `_save_cursor:299-303` глотает `CoreClientError` → next tick опять `cursor=None` → seed `now2 > now1` → пропуск окна `[now1, now2]` (≤60s = 1 poll cycle). Mini-TASK Tier A backend ~10-15 LOC: либо retry на save failure без advancing cursor, либо preserve last cursor in-memory. Не блокер немедленно.

- `recordEvent` на `manual_expense` insert (Tier A backend, ~10-15 LOC) — чтобы CashboxWidget refreshed после manual expense (currently не event-driven). **Codex audit 2026-05-06 confirmed** через grep: `Treasury.hs:503` `createManualExpense` без `recordEvent`, `CashboxWidget.tsx:31` doc-comment подтверждает event-stream subscription. Сложность: `manual_expense` без `dealId` — нужно либо ALLOW NULL FK на event, либо использовать sentinel deal или новый event scope. Требует grounding read `Domain.Lead.Event` / `recordEvent` shape прежде чем оформить TASK.

## Hygiene / code quality

- `_dealId` unused в `client.ts:304` — pre-existing master lint error (hygiene). Не связано с DM-7-C; отдельный mini-TASK или drive-by в любом будущем PR трогающем `client.ts`.

- `useEventStream` singleton refactor — если subscribers вырастут до 4+ (Phase D widgets); после T3+T4 = 2 subscribers (CashboxWidget mounted в AnalyticsDashboard + CashboxScreen). Tier C, ~30 LOC, отложить до 4+.

- CSS classes `.ws-financial-block` / `.ws-kv-line--muted` определения (косметика, fallback работает). CSS-PR Tier C ~10 LOC.

- doc-комменты в `Api/Deals.hs:~1244,~1247` ссылки на guards после refactor (`Treasury.guard*` префиксы — Haddock не валидируется CI, semantically стоит почистить).

- `Makefile` target `db-test-reset` для локальной DB ownership (`sitka_test owned by ilya vs sitka` ломает `setupPool`).

- `scripts/file-tier.sh sitka-core/src/Api/Treasury.hs` возвращает `C`, хотя `.claude/risk-tiers.md` явно перечисляет файл в Tier A. Баг matcher-а в скрипте. Кандидат на отдельный TASK для maintainer (Tier C, ~10 строк bash). Замечено Worker'ом 2026-04-28.

## Phase D backlog (за горизонтом)

- **Frontend Widget TASK (последняя связка Phase C, Tier C ~80 LOC).** Расширить `sitka-web/src/components/CashboxWidget.tsx` с разбивкой outgoing по `expense_category.kind` (4 группы: salary/ops/logistics/misc) через клиентский join `transactions × categories` — теперь возможно после backend prereq добавит `trExpenseCategoryId` в wire shape. Создаётся как новый TASK после merge backend prereq (`TASKS/2026-04-29-dm7-c-backend-widget-prereq.md`).

- **Phase D content** (widget breakdown по `kind` после backend prereq merged, графики/аналитика по cashbox в Касса tab, transactions ledger viewer с фильтрами) — без явного operator UX триггера не приоритет.
