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
- **Product repo status (обязательно):** `committed` / `intentionally uncommitted (Tier C docs)` / `not applicable` / `dirty (см. Conflicts)` — состояние working tree в продуктовом repo на момент HANDOFF. Без этого поля cross-repo state machine непрозрачна: AI Dev System может говорить "done", а git product repo — "не сохранено".

**Evidence rule (даты PR/commit, обязательно):** любая ссылка на PR # или merge-дату в HANDOFF / design doc / overlay сопровождается git short hash из `git log --grep='#NN' --pretty=format:'%h %ad' --date=short` или `gh pr view NN --json mergedAt`. Формат: `PR #74 (2026-05-01, b58e5fb)`. Никогда не пишем даты "из памяти" / "из контекста сессии". Это закрывает Correction 010.

### Конфликты / открытые вопросы

Если что-то требует решения TL / пользователя.

### Следующий шаг

Кто делает следующий ход и что именно.

## User-facing зоны

Если HANDOFF содержит готовый текст, который TL передаст пользователю напрямую (или с минимальной обработкой), такая часть оборачивается в маркеры:

```
<!-- user-facing -->
Касса теперь под паролем. Перепроверил три вещи: без пароля не пускает,
с паролем пускает, внутренние входы снаружи больше не открываются.
<!-- /user-facing -->
```

Внутри этой зоны действуют запреты из `policies/OPERATOR_LANGUAGE.md` (полный список запрещённых слов) и `CLAUDE_GLOBAL.md` → «Главный закон общения с пользователем». Скрипт `scripts/self-check-handoff.sh` проверяет содержимое таких зон на наличие запрещённых слов и выдаёт предупреждение перед `submit-task`.

Если в HANDOFF нет user-facing зон (типичный случай — техническая передача от Worker к TL) — маркеры не нужны, проверка пропускается.

## Lifecycle

- HANDOFF создаётся в момент передачи → `Status: open`
- Получатель прочитал → `Status: acknowledged`
- Следующий шаг закрыт → `Status: closed` → файл переносится в `HANDOFFS/archive/`
- В `OPERATING.md` отображаются только `open` и `acknowledged`
- HANDOFF — лёгкий audit trail. Не удаляем после закрытия.

**Discipline (важно):** перед `mv → HANDOFFS/archive/` TL обязан поднять `Status: closed`. Файл с `Status: open` или `Status: acknowledged` в `archive/` — это lifecycle drift; `make status` подсветит warning. Когда появится `accept-handoff` command (Phase 3 миграции `ROLE_MODEL`) — она автоматизирует bump+move атомарно.
