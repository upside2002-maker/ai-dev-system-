# Sitka Operating

Живой dashboard оперативного состояния sitka-office. Обновляется TL или Admin **по событию** (новый TASK, новый HANDOFF, изменение Reviewer findings).

Соседние артефакты:

- `OPERATING/journal/<YYYY-MM>.md` — журнал событий по датам.
- `OPERATING/backlog.md` — открытые мелочи (mini-tasks, drive-by, drafts).
- `STATUS_RU.md` — пользовательский статус без английской терминологии.
- `CURRENT_STATE.md` — snapshot фазы и архитектуры.

## Активные TASKS

- [`TASKS/2026-04-29-dm7-c-backend-widget-prereq.md`](TASKS/2026-04-29-dm7-c-backend-widget-prereq.md) — `Status: open` → DRAFT → Worker → расширить `Api.TransactionResp` полем `trExpenseCategoryId :: Maybe Int64`. **НЕ срочно** — запускать только когда оператор захочет breakdown в виджете. Класс A без `Mode:` — перед запуском нужно дописать `Mode: strict` (или явно понизить класс с обоснованием), иначе `accept-task` откажет; см. STATUS_RU.md.

См. [`TASKS/README.md`](TASKS/README.md) для правил.

## Открытые HANDOFFS

(нет)

См. [`HANDOFFS/README.md`](HANDOFFS/README.md) для правил.

## Reviewer findings ожидающие TL

(нет)

## Активные Worker сессии

(нет)

## Заметки

- 2026-05-13 (вечер): калькулятор парсера теперь учитывает буфер курса. PR #84 → master `f048c9b`. TASK `2026-05-13-parser-quote-calculator-exchange-buffer` (Tier B, Mode normal, Worker model Claude Code) — Worker iter1 (седьмое поле «Буфер курса, %» с дефолтом из `psExchangeBuffer`, эффективный курс через `usdRate × (1 + buffer/100)`, 21 unit-теста, два числовых эталона #1/#2 сошлись до копейки) → Reviewer iter1 ACCEPT (независимый пересчёт обоих эталонов в JS, scope strict 2 файла, 182/182 vitest + build чистый). Visual layout 7-польной сетки (3+3+1 на 638px sidebar) подтверждён через `npm run dev` в worktree. Два non-blocking findings Reviewer (F1 mock-helper dup, F2 placeholder format) — REJECT/DEFER, в backlog не плодим. Два residual'а из PR #83 (защита `usdRate<0`, cleanup `.parser-calculator-submit` + `offerSavedCount`) остаются в backlog как было. Backend (`Api.PricingSettings`, `Engine.Pricing`) не тронут.
- 2026-05-13: калькулятор парсера превращён из заглушки в рабочий инструмент, кнопка копирования итога добавлена, тесты зелёные. PR #83 → master `936ccdb`. TASK `2026-05-12-parser-quote-calculator` (Tier B, Mode normal, Worker model Claude Code) — Worker iter1 (6 inputs / 7 breakdown lines, 17 unit-тестов) → Reviewer iter1 ACCEPT (numeric correctness + scope clean + 178/178 vitest зелёный + `npm run build` clean). Четыре worker conflict'а (6 vs 7 полей; customs свёрнут в RU shipping default; exchange buffer не выведен отдельным input'ом; inline-style override `.parser-calculator-submit`) — приняты на TL-уровне. Три follow-up в backlog (см. ниже).
- 2026-05-11: deploy `sitka-perimeter-close` на сервер выполнен. `git pull` до `470f48f` (PR #81 в master), `/etc/sitka-htpasswd` создан (bcrypt-12, user `sitka-ops`), server-only `docker-compose.override.yml` обновлён (loopback bindings для core/services через `ports: !override`, volume mount htpasswd, локальный `deploy/nginx-server.conf` — HTTP-only адаптация `nginx-prod.conf` без SSL, поскольку домен/Let's Encrypt пока не настроены). `docker compose up -d --force-recreate web core services` прошёл, все 4 контейнера healthy. Внешний smoke с локального хоста: 8080/8081 → Connection refused; 8088/ без auth → 401; 8088/api/treasury/cashbox с auth → 200; 8088/services/* без auth → 401; 8088/health без auth → 200. Старый override-файл сохранён рядом как `.bak-may11` для отката.
- 2026-05-10 (вечер): TASK `sitka-perimeter-close` принята (Mode: strict, Risk tier A) — закрыт P1 perimeter gap **в репо**. Worker iter1 + Reviewer iter1 (REQUEST CHANGES — web healthcheck бил `/` за `auth_basic`) + Worker iter2 (override healthcheck на `/health` + Compose ≥ 2.20 pre-check в DEPLOY.md) + Reviewer iter2 (ACCEPT). 4 файла в product repo working tree; deploy сделан 2026-05-11 (см. выше).
- 2026-05-10: arbitration `codex-prod-audit-arbitration` принята и закрыта; HANDOFF и TASK перемещены в archive. Backlog по 4 принятым findings уже зафиксирован в `OPERATING/backlog.md` (коммит `b44ac5d`, 2026-05-09); P3 `expenseCategoryId` остаётся отложенным — триггер «оператор хочет breakdown» в существующем DRAFT `dm7-c-backend-widget-prereq.md`.
- 2026-05-09: memory/context cleanup — журнал событий перенесён в `OPERATING/journal/`, открытые мелочи — в `OPERATING/backlog.md`, dashboard сокращён до этого файла.
- 2026-05-02: Production live на 94.72.112.106:8088 (master `b58e5fb`); DM-7-C полностью закрыта. Подробности — `OPERATING/journal/2026-05.md` (раздел «Сводка EOD 2026-05-02»).
