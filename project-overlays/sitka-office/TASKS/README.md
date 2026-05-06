# Sitka TASKS

Папка для активных TASK-документов от Project Tech Lead воркерам.

## Формат

Канонический шаблон: [`../../../templates/TASKS_TEMPLATE.md`](../../../templates/TASKS_TEMPLATE.md).

## Имя файла

`YYYY-MM-DD-<short-slug>.md`, например:
`2026-04-26-dm7-b3-purchase-cashbox-allocation.md`

Дата = когда TL поставил TASK, не когда Worker закрыл.

## Lifecycle

1. TL создаёт `TASKS/<id>.md` со `Status: open` + `Ready: yes` (default через `make new-task`)
2. Worker берёт → `Status: in-progress`
3. Worker закрывает → пишет HANDOFF → `Status: review`
4. TL принимает → `Status: done` → файл переносится в `TASKS/archive/`
5. TL отклоняет → `Status: rejected` → ручной mv в `archive/` (см. ниже)

**Поле `Ready`** разделено с `Status`. `Status` = где в lifecycle, `Ready` = разрешено ли Worker'у стартовать сейчас. Если TASK создан как DRAFT / awaits-prereq (например ждём CI green / billing reset / merge зависимого PR) — TL ставит `Ready: no`. Worker и `/sitka-worker` отказывают на `Ready: no`. После того как блокер снят — TL вручную поднимает в `Ready: yes`. `make status` показывает такие TASK с `[BLOCKED]` префиксом и `ready=no` суффиксом, но они **остаются** в Active queue (не отдельная категория) — TL сразу видит что в работе и что заблокировано.

## Создание TASK

Используй scaffold helper — генерирует skeleton с валидированными полями шапки:

```
make new-task SLUG=sitka-office TASK_SLUG=dm7-d-widget-copy LAYER=web TIER=C
```

Создаёт `TASKS/YYYY-MM-DD-<TASK_SLUG>.md` с:
- шапкой: `Status: open`, `Date`, `Project`, `Layer`, `Risk tier`, `Owner: Project Tech Lead`, `Worker model: TBD`
- секциями-плейсхолдерами: Problem / Scope / Files / Do not touch / Acceptance criteria / Test commands / Handoff requirements

Helper отказывается на: missing args, `TASK_SLUG` не матчит `^[a-z0-9]+(-[a-z0-9]+)*$` (lowercase + digits + single hyphens), `LAYER` не из `{docs, core, services, web, infra, mixed}`, `TIER` не из `{A, B, C}`, overlay `project-overlays/<SLUG>/` не существует, target file уже существует.

Дальше TL руками заполняет Problem / Scope / Files / Do not touch / Acceptance / Test commands / Handoff requirements + добавляет ссылку в `OPERATING.md` → "Активные TASKS".

## Принятие TASK

После TL acceptance используй helper — атомарно поднимает `Status: done` и переносит файл:

```
make accept-task FILE=project-overlays/sitka-office/TASKS/<file>.md
```

Helper отказывается на: missing FILE, файл не найден, путь вне `TASKS/` или внутри `archive/`, basename = `README.md`, target в archive/ уже существует, нет `- Status:` в файле. Не трогает `OPERATING.md` — TL сам убирает строку оттуда если TASK был перечислен.

## Отклонение TASK

Если TL отклоняет TASK — атомарный helper bump'ает `Status: rejected`, вставляет `- Rejected reason:` после Status и переносит в `archive/`:

```
make reject-task FILE=project-overlays/sitka-office/TASKS/<file>.md REASON="scope changed, superseded by TASK Y"
```

REASON обязателен (non-empty, single-line). REASON со спецсимволами (слэши, кавычки, скобки) безопасен — передаётся в perl через env var, не через shell expansion. Helper отказывается дополнительно на: пустой REASON, файл уже имеет `- Rejected reason:` (двойная штамповка запрещена). Не трогает `OPERATING.md`.

## Правила

- В `archive/` все TASKs обязаны иметь terminal status (`done` или `rejected`).
- Один TASK = один Worker = одна модель.
- Codex Worker → отдельная ветка / worktree (фиксируется в TASK поле `Worker branch`).
- Worker не выходит за пределы "Файлы" / "Не трогать" из TASK.
- Замечания Reviewer → не правки этого TASK, а новый TASK / дополнение через TL.
