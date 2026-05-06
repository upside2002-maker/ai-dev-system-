# Sitka HANDOFFS

Папка для handoff-документов между сессиями / моделями / ролями по проекту sitka-office.

## Формат

Канонический шаблон: [`../../../templates/HANDOFFS_TEMPLATE.md`](../../../templates/HANDOFFS_TEMPLATE.md).

## Имя файла

`YYYY-MM-DD-<from>-to-<to>-<short-slug>.md`, например:
`2026-04-26-codex-worker-to-claude-tl-confirmpurchase.md`

## Lifecycle

- HANDOFF создаётся в момент передачи → `Status: open`
- Получатель прочитал → `Status: acknowledged`
- Следующий шаг закрыт → `Status: closed` → файл переносится в `HANDOFFS/archive/`

## Создание HANDOFF

Используй scaffold helper — генерирует skeleton с link на TASK:

```
make new-handoff SLUG=sitka-office TASK=project-overlays/sitka-office/TASKS/<file>.md FROM=worker TO=tl
```

Defaults: `FROM=worker`, `TO=tl`. `FROM/TO ∈ {tl, worker, reviewer, ba, admin}`. TASK может быть в `TASKS/` (active) или `TASKS/archive/` (post-mortem на закрытую задачу). `Agent runtime` дефолтит в `Claude Code`, `Model` в `TBD` — поправь руками если Codex/ChatGPT.

Имя файла: `YYYY-MM-DD-<from>-to-<to>-<task-slug>.md`, где `<task-slug>` извлекается из basename TASK (`YYYY-MM-DD-<slug>.md`).

Helper отказывается на: missing SLUG/TASK, overlay не существует, TASK не найден, TASK вне `TASKS/[archive/]` этого проекта (cross-slug, nested, README.md), bad FROM/TO, target HANDOFF уже существует.

## Принятие HANDOFF

Перед ручным `mv` в `archive/` используй helper — он атомарно поднимает `Status: closed` и переносит файл:

```
make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/<file>.md
```

Helper отказывается на: missing FILE, файл не найден, путь вне `HANDOFFS/` или внутри `archive/`, target уже существует, нет `- Status:` в файле. Не трогает `OPERATING.md` — TL сам убирает строку оттуда если HANDOFF был перечислен.

Если ручной `mv` всё-таки используется — убедись что `Status: closed` стоит до переноса (иначе `make status` подсветит warning).

## Правила

- В `archive/` все handoff-ы обязаны иметь `Status: closed` (`make status` предупредит про drift).
- В `OPERATING.md` отображаются только `open` и `acknowledged`.
- HANDOFF — лёгкий audit trail, не удаляем после закрытия.
- Каждый handoff имеет `Agent runtime` / `Model` / `Role mode` в шапке (см. шаблон).
