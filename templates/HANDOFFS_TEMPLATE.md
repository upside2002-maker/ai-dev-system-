# HANDOFF Template

Канонический формат передачи между сессиями / моделями / ролями.

Файл хранится по пути `project-overlays/<slug>/HANDOFFS/<YYYY-MM-DD-from-to-short-slug>.md`. После закрытия — переносится в `HANDOFFS/archive/`.

## Поля шапки (обязательно)

- `Date:` — `YYYY-MM-DD HH:MM` (когда написан handoff)
- `From:` — кто передаёт (роль + опционально session/branch)
- `To:` — кому (роль + если уже известна сессия)
- `Agent runtime:` — `Claude Code` | `Codex` | `ChatGPT`
- `Model:` — `Claude Opus` | `ChatGPT 5.5` | `Codex` (точную версию если известна)
- `Role mode:` — `Tech Lead` | `Business Analyst` | `Reviewer` | `Worker` | `Admin`
- `TASK:` — ссылка на TASK-документ (если применимо)
- `Status:` — `open` | `acknowledged` | `closed`

## Секции тела

### Что сделано

Конкретно: коммиты, артефакты, файлы. Не процесс, не рассказ — список.

### Что осталось

Если работа не закрыта: явные открытые пункты.

### Артефакты

- ссылки на новые/изменённые файлы
- commit SHA если есть
- ссылки на PR / branch

### Конфликты / открытые вопросы

Если что-то требует решения TL / пользователя.

### Следующий шаг

Кто делает следующий ход и что именно.

## Lifecycle

- HANDOFF создаётся в момент передачи → `Status: open`
- Получатель прочитал → `Status: acknowledged`
- Следующий шаг закрыт → `Status: closed` → файл переносится в `HANDOFFS/archive/`
- В `OPERATING.md` отображаются только `open` и `acknowledged`
- HANDOFF — лёгкий audit trail. Не удаляем после закрытия.

**Discipline (важно):** перед `mv → HANDOFFS/archive/` TL обязан поднять `Status: closed`. Файл с `Status: open` или `Status: acknowledged` в `archive/` — это lifecycle drift; `make status` подсветит warning. Когда появится `accept-handoff` command (Phase 3 миграции `ROLE_MODEL`) — она автоматизирует bump+move атомарно.
