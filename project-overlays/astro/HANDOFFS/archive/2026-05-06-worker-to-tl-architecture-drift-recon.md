# HANDOFF: worker → tl — architecture-drift-recon

- Status: closed
- Date: 2026-05-06 19:05
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-06-architecture-drift-recon.md

## Summary

Создан `project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md` (483 строки) — evidence-based рекон состояния `astro:4937c00` против 5 overlay-документов. Все 7 секций согласно § Scope TASK на месте. Worker не запускал ни одной write-операции в `/Users/ilya/Projects/astro` — только read-only (`git ls-tree`, `git show`, `cat`, `wc`, `grep`). Не вызывал `cabal`, `pytest`, `npm`, `tsc`. Главный сводный вывод: 21 prescribed TASK закрыт, 6 partial, 2 deferred-в-Phase-0.2, 1 deferred-TL-decision, 2 obsolete-by-evolution; 9 conscious deviations + 2 real drift; рекомендован один docs-only TASK как следующий безопасный шаг.

## Done

- Создан `project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md` (483 строки) с 7 секциями в порядке Scope:
  1. **Baseline и метод** — `4937c00`, 161 файл, 5 overlay-источников, evidence-метод (`git ls-tree`/`git show`/`cat`/`grep`).
  2. **Inventory по слоям** — Core (Adapters / Bridge / Domain × 20 модулей / Tests × 23 файла), Services (app/* + ephemeris/* + pdf/* × 6 модулей + tests × 6), Frontend (pages × 6 + components × 18 + lib × 2), Contracts (5 schemas + 3 rulesets + 9 golden-cases pairs), Infra/Docs.
  3. **PHASE_0_TASKS walk** — таблицы по блокам A–F с колонкой статуса (`closed-in-fact` / `partial` / `not-started` / `obsolete-by-evolution`) и evidence на каждый пункт.
  4. **target-architecture.md divergences** — секция-за-секцией: § 1-2 aligned, § 3.2 divergent (deferred), § 5.1 divergent (extension/missing), § 5.2 divergent (Draft extension), § 6 divergent major (3 «чего НЕТ» фактически реализованы), § 7.2 divergent mixed, § 8.3 aligned, § 11 mostly aligned + 1 boundary blur (#5).
  5. **Conscious vs real drift** — 9 conscious в одной таблице, 2 real drift в другой, явное обоснование непустоты обеих корзин.
  6. **Next product TASK** — одно предложение: docs-only `phase0-status-annotations` со ссылкой на этот recon, с обоснованием 4 критериев.
  7. **Evidence appendix** — 10 reproducible команд (`git rev-parse`, `git ls-tree`, `git show … | head/grep`, `wc -l`) с фрагментами реального вывода.

- Каждая claim в § 2-§ 5 подтверждена либо path'ом + evidence-командой, либо короткой цитатой ≤ 15 слов из overlay-документа.
- Раздел Cleanup verification (§ 7.8 evidence appendix) подтверждает T-A.2 deletions: `services/orchestrator-python/`, `Adapters/Ephemeris/Swiss.hs`, `Domain/Report.hs`, `core-input.schema.json` отсутствуют в blob `4937c00`.

## Remaining

Pending у TL (после accept этого HANDOFF + accept TASK):

1. **Прочитать § 5 рекона** и подтвердить классификацию 9 conscious / 2 real drift; при разногласии — указать какие пункты сместить и в какую корзину.
2. **Прочитать § 6 рекона** и решить:
   - принять рекомендованный `phase0-status-annotations` TASK как новый docs-only Tier C;
   - или сформулировать другой вариант first product TASK;
   - или явно отложить (например, до отдельной BA-сессии по приоритетам).
3. **Решение про bright line #5 boundary blur** в `Domain/ConsultationSkeleton.hs` — отдельным go: либо переименование (product code change) → отдельный TASK; либо запись Correction 011 (потребует write в `astro/.claude/corrections.md`); либо явная фиксация как known-issue до Phase 1 evaluation gate.
4. Решение про `Test.Golden` → `Test.GoldenSolar` rename — может объединиться с (3) либо отдельно как trivial T-B.8 finalization.

## Artifacts

- branch:               n/a (AI Dev System repo: working-tree edit; product repo не тронут)
- commit(s):            ещё не закоммичено в `ai-dev-system` (TL accept'нет → отдельный коммит уже после lifecycle complete)
- PR:                   n/a (внутренний docs-only TASK, без PR-flow)
- tests:                Worker не запускал тесты (recon-only, по § Scope TASK). `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки (overlay astro = `pre-phase0`-валидный). `wc -l` рекона = 483.
- Product repo status:  **clean / commit:4937c00** — Worker делал только read-only operations (`git ls-tree`, `git show`, `cat`, `wc`, `grep`); состояние working tree продуктового repo идентично `4937c00`.

Filesystem evidence (re-checked at HANDOFF time, не из памяти):

```
$ git -C /Users/ilya/Projects/astro status --short --branch
## main

$ git -C /Users/ilya/Projects/astro rev-parse HEAD
4937c0065054f627e92f59b1e7bf8b29c3c4d7f2

$ wc -l project-overlays/astro/ARCHITECTURE/architecture-drift-recon.md
     483

$ make -C /Users/ilya/Projects/ai-dev-system check 2>&1 | grep "overlay 'astro'"
OK: overlay 'astro' is at maturity=pre-phase0 (README only; CURRENT_STATE/etc. expected after Phase 0 — bump to 'active' then).

$ make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro | grep -A 2 'ACTIVE TASKS'
ACTIVE TASKS:
  [open    ] TASK: architecture-drift-recon
             layer=docs  tier=C  ready=yes
```

**Worker не выполнял** `cabal`, `pytest`, `npm`, `tsc`, ни одной write-операции в `/Users/ilya/Projects/astro` или `/Users/ilya/Backups`. Только read-only из git blob `4937c00` через `git show` / `git ls-tree`.

## Conflicts / risks

- **Boundary blur #5 (`ConsultationSkeleton.hs`)** — рекон классифицировал как `real drift` (§ 5.2). Альтернативная интерпретация: «naming choice без operational-data violation, лучше зафиксировать как conscious deviation в `corrections.md`». Worker мнение: real drift, потому что нарушает invariant в формулировке (а не только в духе) — но решение TL.
- **`Test.Golden` без переименования** — трактован как real drift (§ 5.2). Альтернатива: trivial T-B.8 finalization, не drift. Worker мнение: drift минимального масштаба, можно объединить с любой другой трогающей `core/astrology-hs/test/` правкой.
- **Конкретные тексты citations** в § 4 ограничены ≤ 15 слов как требует TASK § Acceptance — это намеренно усложняет читаемость, но соответствует копирайту/discipline. Если TL хочет более развёрнутые цитаты — сделать в отдельном следующем шаге со специальной пометкой и объяснением.
- **Перечень Phase 0.5–0.10b нумерации** — взят из header'ов исходных файлов (`«Phase 0.5»` в `TransitCalendar.hs`, `«Phase 0.7»` в `ConsultationSkeleton.hs`, `«Phase 0.8»` в `002_draft_overrides.sql`). Это **внутренняя нумерация продуктовых сессий**, не overlay-фиксированная. Если TL хочет переименовать «Phase 0.5–0.10b» в overlay-нейтральные термины — сделать в `phase0-status-annotations` TASK.

## Next step

TL принимает HANDOFF через `make accept-handoff FILE=project-overlays/astro/HANDOFFS/2026-05-06-worker-to-tl-architecture-drift-recon.md`, затем TASK через `make accept-task FILE=project-overlays/astro/TASKS/2026-05-06-architecture-drift-recon.md`. После accept — оба файла переезжают в `archive/`.

После accept мяч у TL:
1. Прочитать `architecture-drift-recon.md`.
2. Принять или скорректировать § 5 классификацию.
3. Принять или скорректировать § 6 рекомендованный next TASK (`phase0-status-annotations`).

Reviewer не запрашивался Worker'ом (Tier C docs-only). Если TL по результатам HANDOFF решит запросить ревью — отдельный шаг с собственным `make new-handoff FROM=reviewer TO=tl`. Reviewer пишет findings **в файл HANDOFF**, не в stdout (требование TASK § Handoff requirements).
