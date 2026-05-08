# TASK: audit-trail-after-b7774cf

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

После accept'а `astro-core-naming-drift-cleanup` (commit `astro:b7774cf`) остались два рекомендованных follow-up cleanup'а из § Remaining Reviewer/Worker HANDOFF — нужно закрыть audit trail прежде чем переходить к product-features или Phase 0.2:

1. **Correction 008 в `astro/.claude/corrections.md`.** Worker self-reported в § Conflicts of Worker HANDOFF: первый `git commit` без `git add -A` после серии `git mv` + Edit-tool правок дал broken intermediate commit (`552d919`), потому что content-edits через Edit-tool не были staged. Это process-discipline gap — заслуживает Correction-записи, чтобы будущие Worker'ы (и будущий Reviewer-pass) ловили его без повторного инцидента.
2. **T-B.8 status в `PHASE_0_TASKS.md`.** Сейчас аннотация говорит `Status @ astro:4937c00: partial — see architecture-drift-recon.md §3`. После b7774cf эта прескрипция фактически закрыта (T-B.8 finalized). Нужно отразить новый снимок.

Цель — закрыть audit trail одним маленьким docs-only пакетом без новых фич и без затрагивания остальных аннотаций / других файлов.

## Scope

Входит:

### Step 1 — добавить Correction 008 в `astro/.claude/corrections.md`

- Прочитать существующий файл; убедиться что последний Correction номер = 007 (либо текущий next-number, если что-то изменилось — Worker фиксирует в HANDOFF).
- Добавить в конец файла новую запись по существующему формату (`BAD / GOOD / WHY`):
  - **Заголовок:** `## Correction 008: git mv + Edit-tool requires \`git add -A\` before commit`
  - **BAD:** Worker в `astro-core-naming-drift-cleanup` сделал серию `git mv` + `git rm` (это staged автоматически), затем Edit-tool правки в файлах (cabal, Bridge/Solar.hs, Spec.hs, переименованные `.hs`-файлы), затем `git commit -m "..."` без предварительного `git add -A`. Получился broken intermediate commit `552d919` (rename'ы зафиксированы, но содержимое файлов не обновлено → cabal ссылается на удалённый модуль, build падает).
  - **GOOD:** перед commit'ом серии rename + edit:
    - либо `git add -A && git commit -m "..."` (стандартный путь);
    - либо `git commit -a -m "..."` (`-a` подхватывает modifications в tracked файлах, **но НЕ** новые файлы — для созданных через Edit/Write нужен `git add` сначала);
    - всегда верифицировать `git status --short` ДО `git commit` — если есть `??` или ` M` строки, что-то осталось unstaged.
  - **WHY:** `git mv` стейджит rename, но последующие Edit-tool правки в новом файле — это новая модификация поверх stage'нутого rename. Без `git add` они остаются unstaged. `git commit` без `-a/--add` не подхватит их → broken state на HEAD. Это process-trap, который компилятор не поймает (broken state в git, но код в working tree валиден). Catch — обязательная сверка `git status` перед commit.
  - **Контекст:** инцидент 2026-05-06 в TASK `astro-core-naming-drift-cleanup`, обнаружен через `git diff HEAD --stat` после первого commit (5 unstaged файлов), исправлен через `git commit --amend -a --no-edit` ДО `git push backup main` — broken `552d919` существовал ~30 секунд только локально, force-push не потребовался. См. HANDOFF `2026-05-06-worker-to-tl-astro-core-naming-drift-cleanup.md` § Conflicts.
- Никаких других правок в `corrections.md` — только добавление новой записи в конец, без изменения 1-7 существующих Correction'ов и без правки шапки.

### Step 2 — обновить аннотацию T-B.8 в `PHASE_0_TASKS.md`

- В `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` найти строку под `### T-B.8 — Property tests + golden test infrastructure` (предположительно):
  ```
  **Status @ astro:4937c00:** partial — see `architecture-drift-recon.md` §3
  ```
- Заменить **только** эту строку на:
  ```
  **Status @ astro:b7774cf:** closed-in-fact — finalized via commit `b7774cf` (closes real drift #2 in `architecture-drift-recon.md` §5.2: `Test.Golden` placeholder removed, `Test.Golden.SolarSpec` → `Test.GoldenSolar`). Was `partial` at `astro:4937c00`.
  ```
- **Не трогать** остальные 28 status-аннотаций (T-A.1, T-A.2, …, T-F.4 кроме T-B.8) — они продолжают ссылаться на baseline `4937c00` потому что не было соответствующих product-commits.

### Один product commit (только для Step 1)

- Step 1 правит `/Users/ilya/Projects/astro/.claude/corrections.md` — это product repo, требует commit:
  ```
  docs(corrections): add Correction 008 — git mv + Edit-tool require `git add -A` before commit

  Documents the process incident from b7774cf where the first commit
  captured only staged file-ops (renames + deletion) without the
  Edit-tool content modifications. Recovered via `git commit --amend -a`
  before backup push, but the discipline gap is worth a Correction.

  Refs: HANDOFF 2026-05-06-worker-to-tl-astro-core-naming-drift-cleanup.md §Conflicts.
  ```
- Push: `git push backup main` (новый commit вверх над `b7774cf`).
- Step 2 правит overlay (`project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md`) — overlay-only working-tree edit, **не** требует commit'а (consistent с предыдущими docs-only TASK'ами `phase0-status-annotations` и др., которые тоже не делали overlay-commits).

Не входит:

- любая модификация в `core/astrology-hs/`, `services/`, `apps/`, `packages/`, `infra/`, `data/`, `docs/`, `CLAUDE.md`, `run-local.sh`, `docker-compose.yml`;
- любая модификация `astro/.claude/architecture-invariants.md` (только `corrections.md`);
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` etc.;
- любая правка `architecture-drift-recon.md`, `target-architecture.md`, `migration-plan.md`, `current-mvp-review.md`;
- любая правка других task-аннотаций в `PHASE_0_TASKS.md` кроме T-B.8;
- запуск `cabal`, `pytest`, `npm`, `tsc` (docs-only TASK);
- `git push --force`, `git rebase`, history-rewrite;
- создание новых git remotes (только existing `backup`).

## Files

- new:    —
- modify:
  - `/Users/ilya/Projects/astro/.claude/corrections.md` (add Correction 008 at end)
  - `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` (T-B.8 status line only)
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` кроме `.claude/corrections.md` — никаких правок в core/services/apps/packages/data/docs/etc.
- `astro/.claude/architecture-invariants.md` — не трогать (только corrections.md в `.claude/`).
- `astro/CLAUDE.md` — не трогать.
- `/Users/ilya/Backups/**` — не трогать.
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` — только T-B.8 status line; остальные 28 аннотаций + всё содержимое не-T-B.8 секций не трогать.
- `project-overlays/astro/ARCHITECTURE/{target-architecture,migration-plan,current-mvp-review,git-bootstrap-plan,git-bootstrap-execution,architecture-drift-recon}.md` — не трогать.
- `project-overlays/astro/{starts,RESEARCH,archive}/`, `TASKS/archive/`, `HANDOFFS/archive/`, `README.md` — не трогать.

## Acceptance criteria

- [ ] `astro/.claude/corrections.md` содержит новую секцию `## Correction 008:` с темой про `git add -A` / `git mv` / staging discipline. Подтверждается: `grep -c '^## Correction 008:' /Users/ilya/Projects/astro/.claude/corrections.md` → `1`.
- [ ] Существующие Correction 001-007 в `corrections.md` неизменны (Worker фиксирует в HANDOFF одним из: `git diff` показывает только +N/-0 в самом конце файла; либо явная фраза «Correction 001-007 untouched, verified via grep").
- [ ] T-B.8 аннотация в `PHASE_0_TASKS.md` заменена на новую строку с `Status @ astro:b7774cf:` + `closed-in-fact` + ссылкой на commit `b7774cf` + recon §5.2. Подтверждается: `grep -A 1 '^### T-B\.8 ' project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` показывает blank line + новую строку (без слова `partial`).
- [ ] Остальные 28 аннотаций неизменны: `grep -c 'Status @ astro:4937c00:' project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` → `28` (было 29, после правки T-B.8 — 28).
- [ ] `grep -c 'Status @ astro:b7774cf:' project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` → `1`.
- [ ] Один product commit поверх `b7774cf`: `git -C /Users/ilya/Projects/astro log --oneline b7774cf..HEAD` → 1 строка.
- [ ] Commit диапазон по файлам: `git -C /Users/ilya/Projects/astro show --stat HEAD` → один файл `.claude/corrections.md`.
- [ ] `git status` чист в продуктовом repo после commit.
- [ ] Backup sync: `git ls-remote backup main` == local HEAD.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правок.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает TASK как `RECENTLY ARCHIVED` после accept.
- [ ] Worker не запускал `cabal`, `pytest`, `npm`, `tsc`.

## Test commands

```bash
# Read-only sanity:
cat /Users/ilya/Projects/astro/.claude/corrections.md | tail -50
grep -nE '^## Correction [0-9]+' /Users/ilya/Projects/astro/.claude/corrections.md
grep -nE '### T-B\.8' /Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md

# After Step 1:
grep -c '^## Correction 008:' /Users/ilya/Projects/astro/.claude/corrections.md   # → 1
grep -c '^## Correction ' /Users/ilya/Projects/astro/.claude/corrections.md       # → 9 (was 8: 1-6, 6-pre, 7; new 008)

# After Step 2:
grep -A 1 '^### T-B\.8 ' /Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
grep -c 'Status @ astro:4937c00:' /Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md   # → 28
grep -c 'Status @ astro:b7774cf:' /Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md   # → 1

# Commit + push:
cd /Users/ilya/Projects/astro
git status --short --branch                         # MUST verify before commit (Correction 008 itself!)
git add .claude/corrections.md
git commit -m "<multi-line message per § Scope>"
git log --oneline b7774cf..HEAD                     # → 1 line
git push backup main
git ls-remote backup main                           # == local HEAD

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

**Self-application of Correction 008:** Worker этого TASK обязан **сам** проверить `git status --short` ДО `git commit` — это и есть сразу применение нового правила. Если `git status` не чист (например забыл `git add`), `git commit` НЕ запускать; сначала исправить staging.

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-audit-trail-after-b7774cf.md FROM=worker TO=tl`. Шапка строго по `templates/HANDOFFS_TEMPLATE.md`.

В теле обязательно:
- список изменённых файлов: 2 (`.claude/corrections.md`, `PHASE_0_TASKS.md`);
- diff-stat: `+N/-0` для corrections.md, `+1/-1` или `+1/-1` для T-B.8 line в PHASE_0_TASKS.md;
- per-grep счётчики из § Test commands (Correction 008 = 1, total Correction = 9, Status @ 4937c00 = 28, Status @ b7774cf = 1);
- результат `make check` и `make status SLUG=astro`;
- **`Product repo status:` `committed (commit:<short>)`** с новым коротким SHA поверх `b7774cf`;
- backup sync confirmation: `git ls-remote backup main` показывает HEAD == local HEAD;
- evidence-rule подтверждение: «Worker применил Correction 008 на самом себе — проверил `git status --short` перед commit; всё было корректно staged через `git add .claude/corrections.md`»;
- если возникли out-of-scope изменения (например IDE-генерированные файлы) — указать в § Conflicts.

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-audit-trail-after-b7774cf.md`. **TL не делает manual edit `Status:`**.

Reviewer: optional. Tier C docs-only — пользователь не запрашивал mandatory pass для этого TASK; TL может accept без Reviewer'а или запустить отдельным шагом если есть сомнения.

## Контекст

- TASK `astro-core-naming-drift-cleanup` accepted 2026-05-06, commit `astro:b7774cf` (parent `4937c00`).
- Worker HANDOFF этого TASK: `project-overlays/astro/HANDOFFS/archive/2026-05-06-worker-to-tl-astro-core-naming-drift-cleanup.md` § Conflicts описывает incident подробно.
- Reviewer HANDOFF: `project-overlays/astro/HANDOFFS/archive/2026-05-06-reviewer-to-tl-astro-core-naming-drift-cleanup.md` § Remaining #1 рекомендует именно эту Correction.
- `architecture-drift-recon.md` § 5.2 идентифицировал T-B.8 leftover как real drift #2; commit `b7774cf` его финализировал.
