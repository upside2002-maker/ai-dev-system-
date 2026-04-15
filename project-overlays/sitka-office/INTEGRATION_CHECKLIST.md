# Integration Checklist: ai-dev-system → sitka-office

Что скопировать/подключить в sitka-office когда будет готовность.

## Шаг 1: Файлы для .claude/ (копировать as-is)

```
ai-dev-system/evals/review-checklist.md
  → sitka-office/.claude/review-checklist.md

ai-dev-system/templates/reference-snippets/haskell-handler-patterns.md
  → sitka-office/.claude/reference-snippets/haskell-handler-patterns.md

ai-dev-system/prompts/task-splitting.md
  → sitka-office/.claude/prompts/task-splitting.md
```

## Шаг 2: Corrections (merge, не перезаписывать)

В `sitka-office/.claude/corrections.md` уже 3 записи (#1-#3).

Добавить из `ai-dev-system/corrections/global-corrections.md`:
- Correction #4: Не тащить domain decisions в integration layer
- Correction #5: Не строить UI вокруг внутренней архитектуры
- Correction #6: Не путать pre-deal и active deal

## Шаг 3: CLAUDE.md (добавить секцию)

Добавить в конец sitka-office/CLAUDE.md:

```markdown
## Agent Reading Order

Before ANY task:
1. This file (CLAUDE.md)
2. `.claude/corrections.md`
3. `.claude/review-checklist.md` (before commit)

For Haskell tasks:
4. `.claude/reference-snippets/haskell-handler-patterns.md`

For task decomposition:
5. `.claude/prompts/task-splitting.md`
```

## Шаг 4: Что НЕ копировать

- `CLAUDE_GLOBAL.md` — дублирует существующий CLAUDE.md
- `AGENT_OPERATING_MODEL.md` — остаётся в ai-dev-system, не в проекте
- Playbooks — справочные, не операционные. Агент читает при необходимости из ai-dev-system
- TOP20 packs — слишком объёмные для обязательного чтения. Reference only
- `HIGH_QUALITY_CODE_SOURCES.md` — справочник, не инструкция

## Шаг 5: Верификация

После интеграции проверить:
- [ ] Агент при старте сессии читает CLAUDE.md + corrections.md
- [ ] Агент перед commit проходит review-checklist
- [ ] При ошибке corrections.md обновляется
- [ ] Задачи формулируются по шаблону из task-splitting.md
