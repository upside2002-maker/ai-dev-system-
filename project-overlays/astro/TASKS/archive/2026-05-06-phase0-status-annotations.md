# TASK: phase0-status-annotations

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`PHASE_0_TASKS.md` зафиксирована 2026-04-24 как prescriptive план Phase 0; за период 2026-04-24 → 2026-05-06 продуктовый код прошёл серию фаз (0.5–0.10b), и часть TASK уже выполнена / частично выполнена / устарела. Это задокументировано в `architecture-drift-recon.md` (TASK `architecture-drift-recon`, accepted 2026-05-06). Сейчас `PHASE_0_TASKS.md` сам по себе — устаревшая карта: Worker, читая её, не знает, что T-A.1 уже сделан, а T-B.6 переоформлен в `TransitCalendar.hs`.

Цель — превратить `PHASE_0_TASKS.md` в актуальную рабочую карту через минимальную аннотацию: под каждой `### T-X.Y` добавить одну строку статуса со ссылкой на recon § 3, где детали. Не переписывать Scope / Acceptance / Checks / зависимости — это работа другого TASK уровня.

## Scope

Входит:
- Точечная правка одного файла: `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md`.
- Под каждой из **29** task-heading'ов уровня `### T-X.Y — <title>` (T-A.1 … T-F.4) — вставить **одну** строку нового содержания **сразу после** heading-строки и **перед** первой строкой `**Слой:**` (или `**Phase:**`/`**Файлы:**`, что идёт первым), отделённую пустой строкой сверху и снизу:

  ```
  **Status @ astro:4937c00:** <label> — see `architecture-drift-recon.md` §3
  ```

  где `<label>` — ровно одно из 4 значений:
  - `closed-in-fact`
  - `partial`
  - `not-started (Phase 0.2)`
  - `obsolete-by-evolution`

- Распределение label'ов по task'ам — точное, по `architecture-drift-recon.md` § 3:

  | Task | Label |
  |------|-------|
  | T-A.1 | `closed-in-fact` |
  | T-A.2 | `closed-in-fact` |
  | T-A.3 | `closed-in-fact` |
  | T-A.4 | `partial` |
  | T-A.5 | `closed-in-fact` |
  | T-A.6 | `closed-in-fact` |
  | T-B.1 | `partial` |
  | T-B.2 | `closed-in-fact` |
  | T-B.3 | `not-started (Phase 0.2)` |
  | T-B.4 | `not-started (Phase 0.2)` |
  | T-B.5 | `closed-in-fact` |
  | T-B.6 | `obsolete-by-evolution` |
  | T-B.7 | `closed-in-fact` |
  | T-B.8 | `partial` |
  | T-C.1 | `closed-in-fact` |
  | T-C.2 | `closed-in-fact` |
  | T-C.3 | `closed-in-fact` |
  | T-D.1 | `closed-in-fact` |
  | T-D.2 | `partial` |
  | T-D.3 | `closed-in-fact` |
  | T-D.4 | `obsolete-by-evolution` |
  | T-E.1 | `closed-in-fact` |
  | T-E.2 | `closed-in-fact` |
  | T-E.3 | `closed-in-fact` |
  | T-E.4 | `partial` |
  | T-F.1 | `closed-in-fact` |
  | T-F.2 | `closed-in-fact` |
  | T-F.3 | `closed-in-fact` |
  | T-F.4 | `not-started (Phase 0.2)` |

  Worker сверяется с этой таблицей; при разногласии — фиксирует claim в HANDOFF § Conflicts (не меняет label по своему усмотрению).

Не входит:
- любая правка `**Слой:**`, `**Файлы:**`, `**Задача:**`, `**Не трогать:**`, `**Проверка:**`, `**Зависит от:**` секций под task-heading'ами;
- любая правка вступительной части `PHASE_0_TASKS.md` (заголовок, «Phase 0 разбит на две стадии», «Phase 0.1 DoD», «Phase 0.2 DoD», «Демо-сценарии», «Инварианты задач», «Phase Distribution», «Замечание по задачам с пометкой [0.1+0.2]», «Оценка объёма Phase 0», «Правила работы worker-агента»);
- любая правка `target-architecture.md`, `migration-plan.md`, `current-mvp-review.md`, `architecture-drift-recon.md` (только цитировать через ссылку);
- любая модификация product code в `/Users/ilya/Projects/astro`;
- любая git-операция в `/Users/ilya/Projects/astro` кроме read-only;
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` / `KNOWN_ISSUES.md` / `NEXT_ACTIONS.md` / `PROJECT_MAP.md`;
- запись в `astro/.claude/{corrections,architecture-invariants}.md`;
- запуск `cabal build` / `pytest` / `npm install` / `tsc`.

## Files

- new:    —
- modify: `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md`
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких write операций; разрешены только read-only.
- `/Users/ilya/Backups/**` — не трогать.
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/{target-architecture,migration-plan,current-mvp-review,git-bootstrap-plan,git-bootstrap-execution,architecture-drift-recon}.md` — не трогать; только ссылаться по имени из аннотаций.
- `project-overlays/astro/{starts,RESEARCH,archive}/`, `TASKS/archive/`, `HANDOFFS/archive/` — не трогать.

## Acceptance criteria

- [ ] Файл `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` модифицирован: ровно **29 строк-аннотаций** добавлены, по одной под каждой `### T-X.Y` heading. Подтверждается:
      `grep -c '^\*\*Status @ astro:4937c00:\*\*' project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` → `29`.
- [ ] Все 4 label'а представлены в нужном количестве (по таблице из § Scope):
      - `closed-in-fact` — 21 раз;
      - `partial` — 6 раз;
      - `not-started (Phase 0.2)` — 3 раза;
      - `obsolete-by-evolution` — 2 раза.
      Подтверждается `grep -E '^\*\*Status @ astro:4937c00:\*\* (closed-in-fact|partial|not-started|obsolete-by-evolution)'` + per-label счёт.
- [ ] Каждая строка-аннотация заканчивается ровно: `` — see `architecture-drift-recon.md` §3 ``.
- [ ] Ни одна секция вне task-heading'ов и ни одна строка `**Слой:** | **Файлы:** | **Задача:** | **Не трогать:** | **Проверка:** | **Зависит от:**` не модифицирована. Подтверждается `git diff --stat` (один файл) + `git diff` визуальной проверкой только-добавления.
- [ ] `wc -l` файла увеличилось ровно на **58** (29 пустых строк + 29 строк-аннотаций) либо на **29** если форматирование без второй пустой — Worker фиксирует фактическое число в HANDOFF.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает TASK как `Active TASKS` (до submit) либо `RECENTLY ARCHIVED` (после accept).
- [ ] Worker не выполнил ни одной write-операции в `/Users/ilya/Projects/astro` или в любых заблокированных в § «Do not touch» путях. В HANDOFF — явная фраза подтверждения.
- [ ] Worker не запускал `cabal`, `pytest`, `npm`, `tsc`.

## Test commands

```
# Read-only: чтение source-документов:
cat project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
cat project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md  # для сверки § 3

# Sanity grep после правки:
grep -c '^\*\*Status @ astro:4937c00:\*\*' project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
grep -cE '^\*\*Status @ astro:4937c00:\*\* closed-in-fact ' \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
grep -cE '^\*\*Status @ astro:4937c00:\*\* partial ' \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
grep -cE '^\*\*Status @ astro:4937c00:\*\* not-started \(Phase 0\.2\) ' \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
grep -cE '^\*\*Status @ astro:4937c00:\*\* obsolete-by-evolution ' \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-phase0-status-annotations.md FROM=worker TO=tl` (без manual touch файла), потом заполняет body. Шапка строго по `templates/HANDOFFS_TEMPLATE.md`.

В теле обязательно:
- список изменённых файлов (один — `PHASE_0_TASKS.md`, с `wc -l` до и после, и `git diff --stat` в overlay-репо как text);
- per-label счётчики из § Test commands grep'ов (4 числа, должны соответствовать 21/6/3/2);
- результат `make check` и `make status SLUG=astro`;
- `Product repo status:` — `clean / commit:4937c00` ожидаемо (Worker делает только read-only operations в продуктовом repo);
- evidence-rule подтверждение: «Worker выполнял в `/Users/ilya/Projects/astro` только read-only команды; ни одной write-операции в продуктовый repo не было»;
- если Worker заметил расхождение между recon § 3 и таблицей в § Scope этого TASK — указать в § Conflicts (не менять label автоматически).

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-phase0-status-annotations.md`. **TL не делает manual edit `Status:`**.

Reviewer: optional. Если TL по результатам HANDOFF решит запросить ревью — отдельный шаг с собственным `make new-handoff FROM=reviewer TO=tl`. Reviewer пишет findings **в файл HANDOFF**, не в stdout.
