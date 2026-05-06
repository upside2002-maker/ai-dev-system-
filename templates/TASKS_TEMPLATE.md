# TASK Template

Канонический формат задачи от Project Tech Lead → Worker.

Файл хранится по пути `project-overlays/<slug>/TASKS/<YYYY-MM-DD-short-slug>.md`. После закрытия — переносится в `TASKS/archive/`. ID задачи = basename файла (`<YYYY-MM-DD-short-slug>`).

Создаётся через `make new-task SLUG=<slug> TASK_SLUG=<short-slug> LAYER=<layer> TIER=<tier>` — scaffold helper генерит шапку и skeleton автоматически.

## Title

```
# TASK: <task-slug>
```

(`<task-slug>` — то же что в имени файла, без даты и `.md`.)

## Поля шапки (обязательно, в этом порядке)

- `Status:` — `open` | `in-progress` | `review` | `done` | `rejected` (lifecycle)
- `Ready:` — `yes` | `no` (можно ли Worker-у начинать сейчас)
  - `yes` — Worker может стартовать TASK как только `Status: open`
  - `no` — TASK существует, но Worker НЕ стартует без явного TL go-сигнала и bump'а в `yes`. Используется для DRAFT / blocked / awaiting-prereq состояний (например ждём CI green, billing reset, merge зависимого PR)
  - **Семантика разделена с `Status`** намеренно: `Status` = где в lifecycle, `Ready` = разрешено ли стартовать сейчас. Два независимых вопроса.
  - Legacy TASK без поля `Ready:` (в archive до 2026-05-04) считается `Ready: yes` — не мигрируем
- `Date:` — `YYYY-MM-DD` (когда TL поставил TASK)
- `Project:` — slug overlay (`sitka-office`, `astro`, и т.д.)
- `Layer:` — `docs` | `core` | `services` | `web` | `infra` | `mixed`
  - `web` = frontend / UI layer (React, TS components, CSS, e2e)
  - `infra` = Makefile, CI, docker, deploy, scripts
  - `mixed` — задача затрагивает несколько слоёв неразделимо (редкое; обычно делить на отдельные TASKs)
  - см. также `guides/LAYER_RESPONSIBILITIES.md`
- `Risk tier:` — `A` | `B` | `C` (из проектного `.claude/risk-tiers.md`; tier D не используется)
- `Owner:` — `Project Tech Lead` (на текущей итерации; в будущем — имя конкретного TL при multi-TL)
- `Worker model:` — `Claude Code` | `Codex` | `TBD` (фиксируется TL'ом до старта Worker; `TBD` если ещё не назначен)

## Секции тела

### Задача

Что делать, в 2–5 предложениях. Без bizdev-обоснований; они уже в product brief от BA или решении TL.

### Файлы

- `new:` — пути новых файлов
- `modify:` — пути изменяемых
- `delete:` — пути удаляемых (если есть)

### Не трогать

Явный список файлов или зон, которые не должны быть изменены. Worker не имеет права выходить за этот периметр без возврата в TL.

### Критерии приёмки

Чек-лист конкретных проверок: тесты, билд, линт, миграция, smoke-test.

### Контекст

Ссылки на CURRENT_STATE / архитектурные документы / предшествующий handoff / связанный TASK.

### Reviewer (опционально)

Если TL запросил ревью: какая модель (`Claude` / `Codex`), что проверять отдельно.

## Правила

- **Один TASK = один Worker = одна модель.**
- **Codex Worker** → отдельная ветка/worktree, write-set явно перечислен в "Файлы".
- Worker **не выходит** за пределы "Файлы" + "Не трогать". Если задача требует выйти — возвращает в TL, не делает молча.
- Замечания Reviewer → TL → решение → новый TASK или дополнение к текущему. Worker не реагирует на Reviewer напрямую.

## Lifecycle

1. TL создаёт `TASKS/<id>.md` со `Status: open`
2. Worker берёт → `Status: in-progress`
3. Worker закрывает → пишет HANDOFF → `Status: review`
4. TL принимает → `Status: done` → файл переносится в `TASKS/archive/`
5. TL отклоняет → `Status: rejected` → или фикс, или archive с причиной
