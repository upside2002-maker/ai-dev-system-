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

- 2026-05-10: arbitration `codex-prod-audit-arbitration` принята и закрыта; HANDOFF и TASK перемещены в archive. Backlog по 4 принятым findings уже зафиксирован в `OPERATING/backlog.md` (коммит `b44ac5d`, 2026-05-09); P3 `expenseCategoryId` остаётся отложенным — триггер «оператор хочет breakdown» в существующем DRAFT `dm7-c-backend-widget-prereq.md`.
- 2026-05-09: memory/context cleanup — журнал событий перенесён в `OPERATING/journal/`, открытые мелочи — в `OPERATING/backlog.md`, dashboard сокращён до этого файла.
- 2026-05-02: Production live на 94.72.112.106:8088 (master `b58e5fb`); DM-7-C полностью закрыта. Подробности — `OPERATING/journal/2026-05.md` (раздел «Сводка EOD 2026-05-02»).
