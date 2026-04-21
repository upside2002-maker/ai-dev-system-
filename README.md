# AI Dev System

Системный репозиторий для агентной разработки: правила, corrections,
playbooks, overlay-документация по проектам и лёгкие проверки
консистентности.

Важно: это пока docs-first control center, а не полностью
автоматизированная self-improving platform. Источник правды по каждому
проекту остаётся в самом проекте; overlay здесь должен отражать его
текущее состояние.

## Структура

```
CLAUDE_GLOBAL.md                  ← глобальные правила для агентов
AGENT_OPERATING_MODEL.md          ← роли и модель координации
AGENT_ONBOARDING.md               ← единый reading order

playbooks/
  haskell/                        ← typed core / invariants
  python/                         ← integration layer / services
  frontend/                       ← operator UI

corrections/
  global-corrections.md           ← кросс-проектные anti-patterns

templates/reference-snippets/     ← эталонные code samples
prompts/task-splitting.md         ← шаблоны задач по слоям
evals/review-checklist.md         ← чеклист ревью

project-overlays/
  sitka-office/                   ← overlay активного CRM-проекта
    README.md                     ← точка входа в overlay
    CURRENT_STATE.md              ← актуальный snapshot
    KNOWN_ISSUES.md               ← текущие ограничения / долги
    NEXT_ACTIONS.md               ← ближайшие практические шаги
    PROJECT_MAP.md                ← карта кода и модулей

scripts/
  check-system-structure.sh       ← проверка root docs + entrypoints
  check-overlay-consistency.sh    ← проверка, что overlay не отстал от repo

Makefile
  check                           ← запустить минимальные self-checks
```

## Как использовать

Перед задачей:

1. `CLAUDE_GLOBAL.md`
2. `corrections/global-corrections.md`
3. `AGENT_OPERATING_MODEL.md`
4. `project-overlays/<slug>/README.md`
5. Уже потом углубляться в `CURRENT_STATE`, `KNOWN_ISSUES`, playbook и код

После задачи:

1. Обновить corrections, если встретился новый повторяемый анти-паттерн
2. Обновить overlay, если проект реально сменил фазу или архитектурную форму
3. Прогнать `scripts/check-overlay-consistency.sh <slug>`, если менялся overlay
4. Или просто `make check` для минимальной системной проверки

## Текущие проекты

- `sitka-office` — CRM для байерского бизнеса; активная фаза разработки,
  post-Phase-DM, lead-first flow + message inbox
- `astro` — исследовательский overlay для нового проекта
