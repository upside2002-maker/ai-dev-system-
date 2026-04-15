# AI Dev System

Системный репозиторий для агентной разработки сложных продуктов.

## Зачем

- Стандартизировать работу AI-агентов по слоям (core / services / frontend).
- Удерживать архитектурные границы и не давать им размываться.
- Накапливать corrections и хорошие паттерны между сессиями и проектами.
- Ускорять запуск следующих проектов без потери надёжности.

## Для каких проектов

Проекты с:
- typed core (Haskell/Rust/Scala) с жёсткими инвариантами;
- integration layer (Python/Node) для парсеров, мессенджеров, внешних API;
- operator frontend (React/Vue) для CRM/workflow;
- agent-driven development — часть кода пишет AI.

## Текущие проекты

- `sitka-office` — CRM для байерского бизнеса. Overlay: `project-overlays/sitka-office/`.

## Структура

```
CLAUDE_GLOBAL.md              ← общие правила для агентов
AGENT_OPERATING_MODEL.md      ← роли агентов, цикл работы, координация

playbooks/
  architecture/               ← границы и ownership между слоями
  haskell/                    ← работа с typed core
  python/                     ← integration layer
  frontend/                   ← operator UI

corrections/
  global-corrections.md       ← повторяемые анти-паттерны (кросс-проектные)

sources/
  HIGH_QUALITY_CODE_SOURCES.md    ← откуда брать хороший код
  curated-packs/
    HASKELL_TYPED_CORE_TOP20.md   ← 20 паттернов typed core
    PYTHON_SERVICES_TOP20.md      ← 20 паттернов services
    REACT_OPERATOR_UI_TOP20.md    ← 20 паттернов operator UI

templates/
  reference-snippets/         ← конкретные сниппеты для copy-paste

prompts/
  task-splitting.md           ← шаблоны формулировки задач по слоям

evals/
  review-checklist.md         ← чеклист ревью по слоям

task-recipes/
  new-feature-flow.md         ← 5-шаговый flow добавления фичи

project-overlays/
  sitka-office/
    PROJECT_MAP.md            ← карта файлов проекта
    CURRENT_STATE.md          ← текущее состояние
    KNOWN_ISSUES.md           ← известные проблемы
    KNOWN_RULES.md            ← выжимка правил
    NEXT_ACTIONS.md           ← приоритезированные задачи
    HANDOFF_NOTE.md           ← контекст для передачи
    INTEGRATION_CHECKLIST.md  ← что копировать в проект
```

## Как использовать

### Перед задачей

1. Агент читает `CLAUDE_GLOBAL.md`.
2. Читает overlay нужного проекта (`CURRENT_STATE.md`, `KNOWN_ISSUES.md`).
3. Берёт playbook для нужного слоя.
4. Формулирует задачу по шаблону из `prompts/task-splitting.md`.

### После задачи

1. Если ошибка повторяемая → `corrections/global-corrections.md`.
2. Если проект изменился → обновить overlay.
3. Если написан хороший сниппет → `templates/reference-snippets/`.

### Интеграция в проект

См. `project-overlays/<project>/INTEGRATION_CHECKLIST.md` — что копировать в `.claude/` проекта.

## Принцип

Обычный агент пишет код "по месту" и забывает.
Система агентной разработки делает другое:

- сохраняет знания между сессиями;
- делает ошибки дорогими один раз, а не каждый раз;
- разделяет надёжный core от быстрого integration-кода;
- переносит подход на следующие проекты.
