# TASK: ai-dev-system-progress-log-v01-smoke

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: sitka-office
- Layer: docs
- Risk tier: C
- Owner: AI Dev System Admin
- Worker model: Claude Code (sitka-worker subagent)

## Problem

Этот TASK — **retry прогон агентной механики** после system-fix PR
`feat(ai-dev-system): system-fix — submit-task + reviewer persistence + evidence + product-repo status`
(commit `d4dc7b2`). Цель — доказать что новый flow работает **без
ручных edit'ов** между `Worker submit` и `TL accept`.

Содержание (чтобы было что делать): добавить запись в
`learning/progress.md` про Phase B smoke baseline (tag
`ai-dev-system-v0.1-smoke`, commit `449a29a`) и про system-fix PR
(commit `d4dc7b2`). Запись — короткая, ~5-10 строк, фактическая. Это
не главное; главное — что Worker пройдёт по новой механике.

Хотя TASK живёт в `project-overlays/sitka-office/TASKS/` (потому что
эта overlay-инфраструктура уже работает), **изменения только в
`/Users/ilya/Projects/ai-dev-system/`** — это AI-Dev-System-internal
docs TASK, не sitka product change.

## Scope

В скоупе:

- Добавить новую запись в `/Users/ilya/Projects/ai-dev-system/learning/progress.md`
  под существующую структуру файла (читать его перед edit'ом, не угадывать).
- Запись содержит: дату 2026-05-06, факт "Phase B smoke baseline
  зафиксирован как tag `ai-dev-system-v0.1-smoke` (commit `449a29a`)",
  факт "system-fix PR закрыл Corrections 008/009/010 (commit
  `d4dc7b2`)", и что следующий retry — этот TASK сам.
- **Все ссылки на commit/tag сопровождаются git short hash, проверенным
  через `git -C /Users/ilya/Projects/ai-dev-system log` или
  `git -C /Users/ilya/Projects/ai-dev-system tag -l`.** Без памяти.
  (Evidence rule per Correction 010.)

Вне скоупа:

- Любые изменения в `/Users/ilya/Projects/sitka-office/` (это
  AI-Dev-System-internal TASK).
- Любые архитектурные изменения, новые скрипты, изменения других
  ai-dev-system файлов кроме `learning/progress.md`.
- Ревизия структуры `learning/progress.md` (просто добавить запись
  в существующий формат).

## Files

- new:    (none)
- modify: `/Users/ilya/Projects/ai-dev-system/learning/progress.md`
- delete: (none)

## Do not touch

- `/Users/ilya/Projects/sitka-office/**`
- `/Users/ilya/Projects/ai-dev-system/scripts/**`
- `/Users/ilya/Projects/ai-dev-system/templates/**`
- `/Users/ilya/Projects/ai-dev-system/Makefile`
- `/Users/ilya/Projects/ai-dev-system/BASELINE.md`
- `/Users/ilya/Projects/ai-dev-system/corrections/global-corrections.md`
- Любой файл вне `Files` секции выше

## Acceptance criteria

Стандартные content checks:

- [x] `learning/progress.md` имеет новую запись с датой `2026-05-06`
- [x] В записи упомянут tag `ai-dev-system-v0.1-smoke` с commit hash `449a29a`
- [x] В записи упомянут system-fix commit `d4dc7b2`
- [x] Все ссылки на commit/tag/PR сопровождаются git short hash (no
      "from-memory" даты)
- [x] Никаких изменений вне `learning/progress.md`
- [x] Markdown синтаксис валидный

**Mechanism checks (главное для retry — это и есть smoke):**

- [x] Worker вызвал `make submit-task FILE=...` в конце работы;
      TASK при получении TL имеет `Status: review` без manual edit'а.
- [x] HANDOFF файл `HANDOFFS/2026-05-06-worker-to-tl-ai-dev-system-progress-log-v01-smoke.md`
      существует с заполненным body (не placeholder'ами).
- [x] Секция `## Artifacts` HANDOFF'а содержит явное `Product repo status:`
      поле (`not applicable`, потому что TASK ничего не трогает в sitka product repo).
- [x] Все ссылки на commit/tag в HANDOFF сопровождаются git short hash.
- [x] **TL не делает ни одного manual edit'а** в TASK / HANDOFF / target file
      между Worker submit и `make accept-task`. Если делает — retry **failed**,
      нужна вторая итерация system-fix.

## Test commands

```bash
# В repo /Users/ilya/Projects/ai-dev-system:
git -C /Users/ilya/Projects/ai-dev-system diff learning/progress.md   # проверить scope diff
git -C /Users/ilya/Projects/ai-dev-system status --short              # должен показать только M learning/progress.md
git -C /Users/ilya/Projects/ai-dev-system tag -l ai-dev-system-v0.1-smoke   # подтвердить tag exists для evidence rule
git -C /Users/ilya/Projects/ai-dev-system log --oneline 449a29a d4dc7b2     # подтвердить commits exist
```

Никаких cabal test / pytest / npm — это docs-only retry TASK.

## Handoff requirements

Worker в HANDOFF фиксирует:

- **Done**: какая запись добавлена в `learning/progress.md` (краткая
  цитата или diff-stat); evidence: путь, line numbers если применимо.
- **Artifacts**: branch (для retry допустимо working tree без branch'а
  — Tier C docs); commit SHA если коммитил; **обязательно**
  `Product repo status: not applicable` (TASK не трогает sitka).
- **Conflicts/risks**: None expected. Если Worker заметил scope creep
  или нарушение Do-not-touch — flag явно; TL читает.
- **Next step**: `make accept-handoff` + `make accept-task`. Submit-step
  Worker уже сделал перед HANDOFF'ом per новой инструкции.

**Worker завершает работу вызовом:**

```bash
make -C /Users/ilya/Projects/ai-dev-system submit-task \
  FILE=project-overlays/sitka-office/TASKS/2026-05-06-ai-dev-system-progress-log-v01-smoke.md
```

Без этого шага TL не сможет принять TASK — gate откажет.

## Outcome (post-acceptance)

Retry **PASSED**. Worker subagent (cold-start, no session memory)
прошёл chain корректно: edit → HANDOFF written → submit-task →
review status. TL accept (`make accept-handoff` + `make accept-task`)
прошёл с **0** manual edit'ов. system-fix v0.1 валиден.
