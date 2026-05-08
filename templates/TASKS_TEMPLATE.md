# TASK Template

Канонический формат задачи от Project Tech Lead → Worker.

**Файл:** `project-overlays/<slug>/TASKS/<YYYY-MM-DD-short-slug>.md`. После acceptance — `make accept-task` переносит в `TASKS/archive/`. ID задачи = basename файла без `.md`.

**Создаётся:** `make new-task SLUG=<slug> TASK_SLUG=<short-slug> LAYER=<layer> TIER=<tier> MODE=<mode>` — scaffold-helper генерит шапку и пустые секции тела по этому шаблону.

## Title

```
# TASK: <task-slug>
```

`<task-slug>` совпадает с именем файла без даты-префикса и `.md`.

## Header (9 полей, в этом порядке)

- `Status:` — `open` | `in-progress` | `review` | `done` | `rejected` (lifecycle)
- `Ready:` — `yes` | `no`. `no` = DRAFT / blocked / awaits-prereq, Worker не стартует. Семантика отдельна от `Status`.
- `Date:` — `YYYY-MM-DD` (когда TL поставил задачу)
- `Project:` — overlay slug (`sitka-office`, `astro`, …)
- `Layer:` — `docs` | `core` | `services` | `web` | `infra` | `mixed` (см. `guides/LAYER_RESPONSIBILITIES.md`)
- `Risk tier:` — `A` | `B` | `C` (из проектного `.claude/risk-tiers.md`; tier D не используется)
- `Owner:` — `Project Tech Lead`
- `Worker model:` — `Claude Code` | `Codex` | `TBD` (фиксируется до старта Worker)
- `Mode:` — `light` | `normal` | `strict` | `preview` (объём процесса; ось ортогональна `Risk tier:`). Default по tier'у: C → `light`, B → `normal`, A → `strict`. Tier A без `Mode: strict` отказывается `accept-task` гейтом. Полные правила — `policies/MODES.md`.

## Body (5 обязательных секций)

### Problem

Что именно делаем и почему. 2–5 предложений, технически. Без bizdev-обоснований — они уже в product brief / TL decision.

### Files

```
- new:    <пути новых файлов>
- modify: <пути изменяемых>
- delete: <редко>
```

Список **исчерпывающий**: Worker не пишет ни в один файл вне этого списка. Если задача требует выйти за периметр — Worker возвращается в TL через HANDOFF, не делает молча.

### Do not touch

Явный список файлов или зон, в которые Worker НЕ должен заглядывать с правом записи (даже если они в `Files` других задач). Ширококонтекстные правила («не пиши в Tier A core без явного Files») живут в роли (`starts/WORKER.md`), здесь — TASK-specific исключения.

### Acceptance

Конкретные проверки: команды (`make check`, `cabal test -- -p Treasury`, `pytest path -k test_x`), числовые/файловые инварианты (`wc -l < N`, no diff outside Files). Стандартные test-команды по слою (`cabal test`, `pytest`, `npm test`) — в `starts/WORKER.md`; здесь — только нестандартное и/или специфичное для задачи.

### Context

Ссылки на CURRENT_STATE / архитектурный документ / предшествующий HANDOFF / связанный TASK. Если выбран **не-default Mode** для класса риска (`light` на B, `normal` на A — но A без strict не пройдёт gate, см. `policies/MODES.md`) — здесь обоснование одной строкой.

## Что НЕ дублируется в шаблоне

| Концепция | Где живёт |
|-----------|-----------|
| Lifecycle переходов (open → review → done) | `scripts/submit-task.sh`, `scripts/accept-task.sh` |
| Worker chain-of-custody, перед-стартовый reading order | `project-overlays/<slug>/starts/WORKER.md` + `.claude/agents/<slug>-worker.md` |
| Reviewer flow и формат отчёта | `project-overlays/<slug>/starts/REVIEWER.md` + `.claude/agents/<slug>-reviewer.md` |
| HANDOFF структура (Summary / Done / Artifacts / …) | `templates/HANDOFFS_TEMPLATE.md`, скелет в `scripts/new-handoff.sh` |
| Test-команды по умолчанию для слоя | `project-overlays/<slug>/starts/WORKER.md` (project-specific) |
| Mode → tier default + четыре режима | `policies/MODES.md` |
| Role isolation matrix (кто играет роли при риске X) | `ROLE_MODEL.md` § Role isolation by risk tier |
| Codex isolation rule (multi-model parallelism) | `project-overlays/<slug>/starts/WORKER.md` § Codex isolation |
| Anti-patterns (`Mode misuse`, `evidence rule`, …) | `corrections/global-corrections.md` |

Если что-то из этого «хочется» поднять в TASK — это сигнал, что задача либо нестандартная (тогда формулируется в `Context`), либо нужно править соответствующий source-of-truth, не шаблон.
