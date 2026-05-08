# TASK: tl-overlay-recon

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

Astro overlay (`project-overlays/astro/`) сейчас содержит только Worker-ориентированный reading order и не имеет TL start-файла по модели AI Dev System v0.1. До первого Phase 0 TASK нужно дать TL'у воспроизводимую точку входа и явно зафиксировать bootstrap-риск: продуктовый путь `/Users/ilya/Projects/astro` существует, но **не является git-репозиторием** (`.git` отсутствует, parent walk-up до `/` пуст). Это означает, что cross-repo state machine, evidence rule (git short hash для дат) и поле «Product repo status» в HANDOFF в текущем виде **не применимы** к Astro и требуют отдельного решения, прежде чем делегировать Worker'у любую техническую задачу по продукту.

## Scope

Входит:
- Создание `project-overlays/astro/starts/TECH_LEAD.md` по модели sitka — но с «Astro flavour»: ссылка на overlay-документы Architecture, явный учёт maturity=`pre-phase0`, явный учёт того что нет git-репо.
- Обновление `project-overlays/astro/README.md`: добавить TL reading order рядом с уже существующим Worker reading order; добавить «Bootstrap risk» секцию про git-state продукта.
- Зафиксировать в этих двух документах:
  - `target-architecture.md § 6` (Phase 0 PDF = «структурированные факты без графики и интерпретации») как **candidate drift** vs реальное состояние продукта (детальная переоценка — отдельным TASK'ом, не здесь).

Не входит:
- bump `.overlay-maturity` (остаётся `pre-phase0`).
- создание `CURRENT_STATE.md` / `KNOWN_ISSUES.md` / `NEXT_ACTIONS.md` / `PROJECT_MAP.md`.
- любая правка `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, RESEARCH/ — только цитирование существующего.
- любые изменения внутри `/Users/ilya/Projects/astro/` (продуктовые файлы).
- решение про `git init` / привязку remote — только зафиксировать как pending decision.

## Files

- new:    `project-overlays/astro/starts/TECH_LEAD.md`
- modify: `project-overlays/astro/README.md`
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — продуктовые файлы (включая `astro/.claude/`, `astro/CLAUDE.md`).
- `project-overlays/astro/.overlay-maturity` — оставить `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/**` — только цитировать.
- `project-overlays/astro/RESEARCH/**` — только ссылаться.
- `project-overlays/astro/starts/archive/**` — не трогать legacy.
- любые TASK / HANDOFF / OPERATING файлы вне самой этой задачи.

## Acceptance criteria

- [ ] Создан `project-overlays/astro/starts/TECH_LEAD.md` со структурой по модели `project-overlays/sitka-office/starts/TECH_LEAD.md`, но адаптированной под Astro:
  - reading order ссылается на actual файлы overlay (не на ещё-не-существующие `CURRENT_STATE.md` и пр.);
  - явно сказано, что overlay maturity = `pre-phase0` и какие артефакты появятся только после Phase 0.2 (T-F.4);
  - явно сказано, что `/Users/ilya/Projects/astro` не git-репо и git-evidence rule пока не применим;
  - перечислены 8 bright lines из `target-architecture.md § 11` как highest-priority контракты архитектуры.
- [ ] `project-overlays/astro/README.md` обновлён:
  - добавлена секция «Reading order для Project Tech Lead» рядом с уже имеющимся Worker reading order;
  - добавлена секция «Bootstrap risks» с фиксацией git-state продукта и candidate drift по `target-architecture.md § 6`.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` остаётся зелёным (overlay astro продолжает считаться `pre-phase0`-валидным).
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` отображает этот TASK как ACTIVE до момента submit, после submit — как review, после accept — пусто (файл уезжает в `TASKS/archive/`).
- [ ] Worker НЕ запускает `git` / не создаёт `.git` ни в каком пути. Все утверждения о состоянии продукта — через filesystem evidence (ls, find).

## Test commands

```
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
ls -la /Users/ilya/Projects/astro/.git || echo "OK: no git repo"
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff` (без manual touch файла), затем заполняет body. В шапке обязательно:
- `Agent runtime: Claude Code`
- `Model: Claude Opus`
- `Role mode: Worker`
- `TASK:` ссылка на `TASKS/2026-05-06-tl-overlay-recon.md`

В теле обязательно:
- список созданных / изменённых файлов (с количеством добавленных/удалённых строк через `wc -l`);
- цитата из шапки `TECH_LEAD.md` показывающая, что reading order верный;
- результат `make check` и `make status SLUG=astro` после правок;
- **`Product repo status:` `not a git repo at /Users/ilya/Projects/astro root / decision pending`** (это требование задачи, не общая формулировка);
- ссылка на места, где зафиксирован candidate drift (`target-architecture.md § 6`) и bootstrap risk.

После записи HANDOFF Worker вызывает:
```
make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-tl-overlay-recon.md
```

TL не делает manual edit `Status:` между submit и accept — submit-task сам поднимает `open → review`, accept-task поднимает `review → done` и переносит файл в archive.

Reviewer в этом TASK не запрашивается (Tier C docs-only). Если TL по результатам HANDOFF решит запросить ревью — это будет отдельный шаг с собственным `new-handoff` (Reviewer report в файл, не stdout).
