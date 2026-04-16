# AI Dev System

Системный репозиторий для агентной разработки. Правила, corrections, playbooks, reference snippets.

## Структура

```
CLAUDE_GLOBAL.md                  ← правила для агентов (читать первым)
AGENT_OPERATING_MODEL.md          ← роли агентов, координация

playbooks/
  haskell/                        ← typed core
  python/                         ← integration layer
  frontend/                       ← operator UI

corrections/
  global-corrections.md           ← кросс-проектные anti-patterns

templates/reference-snippets/     ← эталонные code samples
prompts/task-splitting.md         ← шаблоны задач по слоям
evals/review-checklist.md         ← чеклист ревью

project-overlays/sitka-office/    ← состояние текущего проекта
  CURRENT_STATE.md
  KNOWN_ISSUES.md
  NEXT_ACTIONS.md
  PROJECT_MAP.md
```

## Как использовать

**Перед задачей:** CLAUDE_GLOBAL → overlay (CURRENT_STATE, KNOWN_ISSUES) → playbook для слоя.

**После задачи:** corrections (если ошибка повторяемая) → overlay (если проект изменился).

## Текущие проекты

- `sitka-office` — CRM для байерского бизнеса (Haskell + Python + React)
