# TASK: astro-core-naming-drift-cleanup

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: core
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`architecture-drift-recon.md` § 5.2 идентифицировал два пункта real drift (дисциплинарного, не bizdev-evolution):

1. **Bright line #5 boundary blur.** `core/astrology-hs/src/Domain/ConsultationSkeleton.hs` экспортирует тип `ConsultationSkeleton` и функцию `buildConsultationSkeleton`. Бmodule header сам говорит: `"Aggregation layer that takes already-computed analysis blocks ... and produces a STRUCTURED draft of the written consultation"` — это про *report skeleton*, а не Consultation-as-workflow. Naming в core **прямо** нарушает invariant #5 («Core не знает про Consultation как workflow»). Глубинный invariant (нет operational data в Core) НЕ нарушен — типы оперируют только pre-computed analysis blocks, Person/Consultation как entity не импортируются.
2. **T-B.8 leftover.** Прескрипция `PHASE_0_TASKS.md § T-B.8` требовала переименование `Test.Golden` → `Test.GoldenSolar`. По факту: `Test/Golden.hs` существует как 3-строчный **placeholder stub** (`True shouldBe True`), а реальный golden test живёт в `Test.Golden.SolarSpec`. Чистый T-B.8: убрать placeholder, переместить spec в одно `Test.GoldenSolar`.

Цель — закрыть оба пункта real drift одним маленьким product-code patch'ем без изменения поведения. Это первый product-code TASK после git bootstrap (`astro:4937c00`); он валидирует AI Dev System workflow для не-docs Tier B изменений.

## Scope

Входит — **только** Haskell-side rename. Wire-format JSON-keys и поведение runSolar остаются неизменными.

### Step 1 — ConsultationSkeleton → SolarReportSkeleton (Haskell-only)

- Renamed module file:
  - `core/astrology-hs/src/Domain/ConsultationSkeleton.hs` → `core/astrology-hs/src/Domain/SolarReportSkeleton.hs`
- В переименованном файле:
  - `module Domain.ConsultationSkeleton` → `module Domain.SolarReportSkeleton`
  - Тип `ConsultationSkeleton` → `SolarReportSkeleton` (и его конструктор + selectors).
  - Функция `buildConsultationSkeleton` → `buildSolarReportSkeleton`.
  - `withObject "ConsultationSkeleton"` (parseJSON) → `withObject "SolarReportSkeleton"`.
  - В module header: пункт `"... STRUCTURED draft of the written consultation that Архипова's PDFs follow"` переписать на `"... STRUCTURED skeleton of the written solar report that Архипова's PDFs follow"`. Аналогично остальные mentions «consultation» в комментариях этого файла → «solar report» / «report skeleton».
  - **НЕ** трогать другие типы и функции внутри файла, кроме перечисленных.
- В `core/astrology-hs/src/Bridge/Solar.hs`:
  - `import Domain.ConsultationSkeleton` → `import Domain.SolarReportSkeleton`.
  - `( ConsultationSkeleton, buildConsultationSkeleton )` → `( SolarReportSkeleton, buildSolarReportSkeleton )`.
  - Поле `baConsultationSkeleton :: !ConsultationSkeleton` → `baSolarReportSkeleton :: !SolarReportSkeleton`.
  - Использование `buildConsultationSkeleton` в `runSolar` pipeline → `buildSolarReportSkeleton`.
  - Локальная переменная `consultationSkeleton` → `solarReportSkeleton`, и в `, baConsultationSkeleton = consultationSkeleton` → `, baSolarReportSkeleton = solarReportSkeleton`.
  - **НЕ ТРОГАТЬ** wire-format JSON-key `"consultation_skeleton"` в строке `"consultation_skeleton" .= baSolarReportSkeleton a` — JSON-encoding key остаётся как есть; меняется только ссылка на Haskell-accessor (`baConsultationSkeleton` → `baSolarReportSkeleton`). Это сохраняет контракт с Python+Frontend и не триггерит bright-line #8 cascade.
- В `core/astrology-hs/astrology-core.cabal`:
  - `Domain.ConsultationSkeleton` → `Domain.SolarReportSkeleton` в `exposed-modules:`.

### Step 2 — Test.Golden cleanup (T-B.8 finalization)

- Удалить placeholder файл:
  - `core/astrology-hs/test/Test/Golden.hs` — DELETE (это 3-строчный stub `describe "golden placeholders"; True shouldBe True`, никакой ценности).
- Перенести real spec:
  - `core/astrology-hs/test/Test/Golden/SolarSpec.hs` → `core/astrology-hs/test/Test/GoldenSolar.hs`.
  - Внутри файла: `module Test.Golden.SolarSpec` → `module Test.GoldenSolar`. Содержимое spec'а (сами тесты) — **не трогать**.
- Удалить пустую директорию `core/astrology-hs/test/Test/Golden/` после `mv`.
- В `core/astrology-hs/test/Spec.hs`:
  - Удалить строку `import qualified Test.Golden`.
  - `import qualified Test.Golden.SolarSpec` → `import qualified Test.GoldenSolar`.
  - Удалить строку `describe "Golden tests"  Test.Golden.spec` (placeholder больше не существует).
  - `describe "Golden.Solar"  Test.Golden.SolarSpec.spec` → `describe "Golden.Solar"  Test.GoldenSolar.spec`.
- В `core/astrology-hs/astrology-core.cabal`:
  - Удалить `Test.Golden` из `other-modules:`.
  - `Test.Golden.SolarSpec` → `Test.GoldenSolar` в `other-modules:`.

### Один атомарный commit

Worker делает **один git commit** в продуктовом repo с обеими переименованиями (Step 1 + Step 2). Commit message:

```
refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup

- Domain.ConsultationSkeleton → Domain.SolarReportSkeleton (closes real drift #1
  from architecture-drift-recon.md §5.2: bright line #5 naming-level violation).
- Test.Golden placeholder removed; Test.Golden.SolarSpec → Test.GoldenSolar
  (closes real drift #2: T-B.8 leftover rename).
- No behavior change; wire-format JSON key `consultation_skeleton` preserved
  to keep Python/Frontend contract stable (bright line #8 not triggered).
- Tests: cabal test all green, same count as 4937c00 baseline.

Refs: architecture-drift-recon.md §5.2, PHASE_0_TASKS.md T-B.8.
```

После успешного коммита — `git push backup main` (push на bare backup remote).

Не входит:
- любая правка wire-format JSON keys (включая `"consultation_skeleton"` в Bridge/Solar.hs:434, и любые keys в `*.schema.json`);
- любая правка `packages/contracts/*.schema.json`, `packages/test-fixtures/*`;
- любая правка Python (`services/`), Frontend (`apps/`), infra (`run-local.sh`, `infra/docker/*`);
- любая правка `astro/.claude/{corrections,architecture-invariants}.md` или `CLAUDE.md`;
- любая правка `data/*` (PII БД);
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` etc.;
- любая правка overlay-документов (`target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, `architecture-drift-recon.md`, и т.д.);
- любые другие переименования / refactor'ы за пределами 2 указанных пунктов;
- запуск `pytest`, `npm`, `tsc` (TASK ограничен Haskell core'ом);
- `git push --force`, `git rebase`, любая history-rewrite операция;
- создание новых git remotes (только existing `backup`).

## Files

- new:
  - `core/astrology-hs/src/Domain/SolarReportSkeleton.hs` (renamed from ConsultationSkeleton.hs, content updated for new names + comment refresh)
  - `core/astrology-hs/test/Test/GoldenSolar.hs` (renamed from test/Test/Golden/SolarSpec.hs, module declaration updated)
- modify:
  - `core/astrology-hs/src/Bridge/Solar.hs` (6 reference updates; **do NOT touch wire-format JSON key**)
  - `core/astrology-hs/test/Spec.hs` (3 changes: drop import, rename import, drop describe, rename describe arg)
  - `core/astrology-hs/astrology-core.cabal` (3 changes: rename in exposed-modules, drop Test.Golden, rename Test.Golden.SolarSpec)
- delete:
  - `core/astrology-hs/src/Domain/ConsultationSkeleton.hs` (replaced by `SolarReportSkeleton.hs`)
  - `core/astrology-hs/test/Test/Golden.hs` (placeholder stub)
  - `core/astrology-hs/test/Test/Golden/SolarSpec.hs` (replaced by `Test/GoldenSolar.hs`)
  - `core/astrology-hs/test/Test/Golden/` (empty dir, cleanup)

**Total: 2 new + 3 modified + 3 deleted (+ 1 dir) = 8 file-ops, 1 commit.**

## Do not touch

- `/Users/ilya/Projects/astro/data/**` — PII БД и эфемериды.
- `/Users/ilya/Projects/astro/packages/contracts/**`, `packages/test-fixtures/**`, `packages/rulesets/**` — контракты и fixtures (изменение здесь = bright-line #8 cascade, вне scope).
- `/Users/ilya/Projects/astro/services/**` — Python services (wire-format не меняется → нет смысла трогать).
- `/Users/ilya/Projects/astro/apps/**` — React frontend (то же).
- `/Users/ilya/Projects/astro/infra/**`, `docker-compose.yml`, `run-local.sh` — infra.
- `/Users/ilya/Projects/astro/.claude/**`, `CLAUDE.md` — продуктовые рабочие правила.
- `/Users/ilya/Projects/astro/docs/**` — документация продукта.
- `/Users/ilya/Backups/**` — backup mirror.
- `core/astrology-hs/src/Domain/*` кроме `ConsultationSkeleton.hs` — другие domain-модули.
- `core/astrology-hs/src/Bridge/Solar.hs` — кроме 6 точечных rename'ов (НЕ ТРОГАТЬ wire-format JSON keys, типы, runSolar logic).
- `core/astrology-hs/src/Adapters/**`, `core/astrology-hs/app/Main.hs` — не трогать.
- `core/astrology-hs/test/Test/Bridge/**`, `core/astrology-hs/test/Test/Domain/**` — другие тесты не трогать.
- `core/astrology-hs/test/golden/` — fixture файлы (`.json`) не трогать; их формат не меняется.
- `core/astrology-hs/cabal.project` — не трогать.
- `project-overlays/astro/**` — overlay не трогать (включая обновление PHASE_0_TASKS.md аннотации T-B.8 — это отдельный шаг по результатам этого TASK).

## Acceptance criteria

- [ ] `cabal build` зелёный в `core/astrology-hs/`.
- [ ] `cabal test` зелёный, **то же число тестов** что и до правки (или меньше на 1 — placeholder `Test.Golden.spec` с тривиальным `True shouldBe True` мог считаться 1 проходящим тестом; этот тест исчезает, остальные остаются). Worker фиксирует точные числа в HANDOFF.
- [ ] `git -C /Users/ilya/Projects/astro grep -n 'ConsultationSkeleton' core/astrology-hs/` → **0 matches** после rename.
- [ ] `git -C /Users/ilya/Projects/astro grep -n -E 'Test\.Golden([^A-Za-z0-9_]|$)' core/astrology-hs/` (точно `Test.Golden` как identifier с не-word-char или EOL после; не матчит `Test.GoldenSolar`) → **0 matches** после rename.
- [ ] `git -C /Users/ilya/Projects/astro grep -n '"consultation_skeleton"' core/astrology-hs/src/Bridge/Solar.hs` → **1 match** (wire-format key неизменно сохранён).
- [ ] Содержимое golden fixture-файла `core/astrology-hs/test/golden/synthetic-solar-1.expected.json` **идентично** до и после: `git diff 4937c00 HEAD -- core/astrology-hs/test/golden/synthetic-solar-1.expected.json` пустой.
- [ ] `git status` после правки → clean (всё закоммичено в один commit).
- [ ] `git log --oneline 4937c00..HEAD` показывает **ровно 1** new commit.
- [ ] Backup mirror sync'нут: `git push backup main` отработал; `git ls-remote backup main` совпадает с локальным HEAD.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный после правки (overlay astro = `pre-phase0`-валидный).
- [ ] Worker не выполнил ни одной правки за пределами `core/astrology-hs/` (verifies via `git show --stat HEAD` показывает только пути под `core/astrology-hs/`).
- [ ] Worker не запускал `pytest`, `npm`, `tsc`, `git push --force`, не создавал новых remotes.

## Test commands

```bash
# 1. Build (must pass with renamed names resolved):
cd /Users/ilya/Projects/astro/core/astrology-hs
cabal build

# 2. Test (full suite green; record pass count for HANDOFF):
cabal test --test-show-details=direct

# 3. Post-rename greps (in product repo root):
cd /Users/ilya/Projects/astro
git grep -n 'ConsultationSkeleton' core/astrology-hs/    # must be empty
git grep -n -E 'Test\.Golden([^A-Za-z0-9_]|$)' core/astrology-hs/   # must be empty
git grep -n '"consultation_skeleton"' core/astrology-hs/src/Bridge/Solar.hs  # must show line 434 unchanged

# 4. Wire-format unchanged check:
git diff 4937c00 HEAD -- core/astrology-hs/test/golden/synthetic-solar-1.expected.json
# (should be empty diff)

# 5. Commit hygiene:
git status
git log --oneline 4937c00..HEAD                            # exactly 1 commit
git show --stat HEAD | head -20                            # only core/astrology-hs/* paths

# 6. Backup sync:
git push backup main
git ls-remote backup main                                  # equals local HEAD

# 7. Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Rollback plan

Атомарность: всё через **один commit** (Step 1 + Step 2 вместе). Если что-то упадёт:

- **Build / test fail в working tree (до commit):** `git -C /Users/ilya/Projects/astro restore .` восстанавливает working tree до `4937c00`. Worker возвращается в TL с описанием препятствия.
- **После commit, но обнаружили проблему до push backup:** `git -C /Users/ilya/Projects/astro reset --hard 4937c00` отбрасывает new commit. Worker возвращается в TL.
- **После push backup, обнаружили проблему:** local rollback (`git reset --hard 4937c00`) + `git push backup main --force-with-lease` (но force-push в backup допустим только с TL go и ровно один раз, см. `Do not touch`). Альтернатива: новый revert-commit `git revert HEAD` + push. Чище — revert-commit, потому что не требует force-push privilege escalation.
- **Catastrophic state mismatch:** baseline `4937c00` сохранён в `/Users/ilya/Backups/astro.git` (bare backup) + `/Users/ilya/Backups/astro-pre-git-2026-05-06-183746.db` (pre-init DB snapshot). `git clone /Users/ilya/Backups/astro.git /Users/ilya/Projects/astro-restored` восстановит чистую копию.

В TASK § Acceptance явно зафиксирован критерий «golden fixture identical» — это early-warning, что wire-format не сместился. Если этот тест красный, **commit не делать**, fix первый.

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md FROM=worker TO=tl` (без manual touch файла), потом заполняет body. Шапка строго по `templates/HANDOFFS_TEMPLATE.md`.

В теле обязательно:
- список изменённых файлов: 2 new + 3 modified + 3 deleted, с `git show --stat HEAD`;
- результаты `cabal build` (one-line: `OK: build green`) и `cabal test` (с pass count: `Cases: N  Tried: N  Errors: 0  Failures: 0`);
- post-rename greps (3 числа, каждое = 0 / 1 / 0 как в § Acceptance);
- wire-format guard: `git diff 4937c00 HEAD -- core/astrology-hs/test/golden/synthetic-solar-1.expected.json` пустой (one-line evidence);
- результат `make check` и `make status SLUG=astro`;
- **`Product repo status:` `committed (commit:<short-sha>)`** — это первый product-code TASK после git bootstrap, поле заполняется обычным образом (не `intentionally uncommitted` — это уже не Tier C docs);
- backup sync confirmation: `git ls-remote backup main` показывает HEAD = local HEAD (евидентность что backup mirror совпал);
- если возникли непредвиденные изменения в файлах вне scope (например IDE сгенерировал `.cabal-sandbox/`, `.stack-work/`, `dist-newstyle/`) — указать в § Conflicts; они должны быть .gitignored, не закоммичены.

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md`. **TL не делает manual edit `Status:`**.

Reviewer: optional. По результатам HANDOFF TL может запросить ревью отдельной сессии — Reviewer проверяет: (a) нет behavior change (golden fixture identical); (b) нет имени `ConsultationSkeleton` или `Test.Golden\b` в core; (c) wire-format `"consultation_skeleton"` сохранён; (d) commit message соответствует требованиям. Reviewer пишет findings **в файл HANDOFF**, не в stdout.

## Контекст

- `architecture-drift-recon.md` § 5.2 (real drift корзина) — оба пункта этого TASK там описаны.
- `PHASE_0_TASKS.md § T-B.8` — leftover rename `Test.Golden → Test.GoldenSolar`.
- `target-architecture.md § 11` (bright lines), особенно #5 (Core не знает про Consultation как workflow) и #8 (Schema change gate — НЕ триггерится этим TASK потому что wire-format сохранён).
- `astro/.claude/corrections.md` Correction 002 (no catch-all in sum-type match) — не релевантно этому TASK, но Worker должен прочитать перед стартом.
- Baseline commit: `astro:4937c00`.

**Ready: yes** (TL flipped 2026-05-06 после go от пользователя). Worker может стартовать. Status остаётся `open` до Worker bump'а через `make submit-task`.
