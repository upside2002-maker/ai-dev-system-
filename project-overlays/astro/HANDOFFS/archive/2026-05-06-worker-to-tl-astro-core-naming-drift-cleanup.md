# HANDOFF: worker → tl — astro-core-naming-drift-cleanup

- Status: closed
- Date: 2026-05-06 19:51
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md

## Summary

Step 1 + Step 2 выполнены одним атомарным коммитом `astro:b7774cf` поверх `astro:4937c00`. Все acceptance criteria из TASK прошли: build green, 229/229 tests pass, post-rename greps чистые (3 × «0»), wire-format JSON-key `"consultation_skeleton"` сохранён (1 match in `Bridge/Solar.hs:434`), golden fixture `synthetic-solar-1.expected.json` byte-identical к baseline. Backup mirror sync'нут (`b7774cf` на `local` и на `/Users/ilya/Backups/astro.git`). Был один процесс-инцидент (см. § Conflicts): первый `git commit` без `git add -A` зафиксировал только staged renames без content-edits → broken state на HEAD; восстановлено через `git commit --amend -a --no-edit` ДО push на backup. Финальный HEAD — корректный.

## Done

### Step 1 — `Domain.ConsultationSkeleton` → `Domain.SolarReportSkeleton`

- `git mv core/astrology-hs/src/Domain/ConsultationSkeleton.hs → SolarReportSkeleton.hs` (rename detection 96%).
- В новом файле:
  - `module Domain.ConsultationSkeleton` → `module Domain.SolarReportSkeleton`.
  - Тип `ConsultationSkeleton(..)`, конструктор, 5 поля-selectors — все из ADT остались (csOpening, csPsychologicalSetting, csKeyPeriods, csExtendedThemes, csCautions). Только имя типа сменилось.
  - Функция `buildConsultationSkeleton` → `buildSolarReportSkeleton`.
  - JSON-инстансы `instance ToJSON SolarReportSkeleton`, `instance FromJSON SolarReportSkeleton`, `withObject "SolarReportSkeleton"`.
  - Module header rewritten: now «Solar report skeleton — Phase 0.7» с пометкой «Renamed 2026-05-06 to honour bright line #5» + ссылкой на recon §5.2 + указанием на git rename trail.
  - Внутренние комментарии: `«draft of the written consultation»` → `«skeleton of the written solar report»`, `«the consultation skeleton is self-contained»` → `«the report skeleton is self-contained»`.
- В `core/astrology-hs/src/Bridge/Solar.hs`:
  - Import block: `import Domain.SolarReportSkeleton ( SolarReportSkeleton, buildSolarReportSkeleton )`.
  - Поле `BridgeAnalysis`: `baSolarReportSkeleton :: !SolarReportSkeleton`.
  - **Wire-format key неизменно**: `, "consultation_skeleton" .= baSolarReportSkeleton a` — JSON-key `"consultation_skeleton"` сохранён, изменился только Haskell-accessor.
  - Локальная переменная `solarReportSkeleton = buildSolarReportSkeleton …` (вместо `consultationSkeleton = buildConsultationSkeleton`).
  - Ассемблирование `BridgeAnalysis`: `, baSolarReportSkeleton = solarReportSkeleton`.
- В `core/astrology-hs/astrology-core.cabal`:
  - `Domain.ConsultationSkeleton` → `Domain.SolarReportSkeleton` в `exposed-modules`.

### Step 2 — `Test.Golden` cleanup (T-B.8 finalization)

- `git rm core/astrology-hs/test/Test/Golden.hs` (3-line placeholder stub `True \`shouldBe\` True` удалён).
- `git mv core/astrology-hs/test/Test/Golden/SolarSpec.hs → core/astrology-hs/test/Test/GoldenSolar.hs` (rename detection 97%).
- В новом файле: `module Test.Golden.SolarSpec (spec) where` → `module Test.GoldenSolar (spec) where`. Тело spec не тронуто.
- `rmdir core/astrology-hs/test/Test/Golden/` — пустая директория удалена.
- В `core/astrology-hs/test/Spec.hs`:
  - Дропнут `import qualified Test.Golden`.
  - `import qualified Test.Golden.SolarSpec` → `import qualified Test.GoldenSolar`.
  - Дропнут `describe "Golden tests" Test.Golden.spec`.
  - `describe "Golden.Solar" Test.Golden.SolarSpec.spec` → `describe "Golden.Solar" Test.GoldenSolar.spec`.
- В `core/astrology-hs/astrology-core.cabal` `other-modules`:
  - Дропнут `Test.Golden`.
  - `Test.Golden.SolarSpec` → `Test.GoldenSolar`.

### Атомарный commit

- HEAD: `astro:b7774cf` (`b7774cf8ed9c475c5b237b222add1463dc18747f`).
- Parent: `astro:4937c00`.
- 6 files changed, +31/−39 (net −8 lines).
- Commit message multi-line, ссылается на `architecture-drift-recon.md §5.2` + `PHASE_0_TASKS.md T-B.8`. Зафиксировано преднамеренное сохранение wire-key для bright-line #8 non-trigger.
- `git push backup main` отработал: `4937c00..b7774cf  main -> main`.

### Acceptance criteria walk

| Criterion | Status |
|-----------|--------|
| `cabal build` зелёный | ✅ |
| `cabal test` зелёный (229/229; baseline 230, −1 placeholder) | ✅ |
| `git grep 'ConsultationSkeleton' core/astrology-hs/` = 0 | ✅ (0 matches) |
| `git grep -E 'Test\.Golden([^A-Za-z0-9_]\|$)' core/astrology-hs/` = 0 | ✅ (0 matches) |
| `git grep '"consultation_skeleton"' Bridge/Solar.hs` = 1 | ✅ (line 434) |
| `git diff 4937c00 HEAD -- test/golden/synthetic-solar-1.expected.json` empty | ✅ (empty) |
| `git status` clean | ✅ (`## main`) |
| `git log --oneline 4937c00..HEAD` = 1 commit | ✅ (`b7774cf`) |
| `git ls-remote backup main` == local HEAD | ✅ (`b7774cf`) |
| `make check` зелёный | ✅ (`overlay astro pre-phase0 OK`) |
| Worker не трогал ничего вне `core/astrology-hs/` | ✅ (см. § Artifacts evidence ниже) |
| Worker не запускал `pytest`, `npm`, `tsc` | ✅ |

## Remaining

Pending у TL:
1. Запустить **Reviewer pass** (по требованию пользователя в этом TASK обязателен).
2. После accept Reviewer'ом — accept этот HANDOFF + accept TASK.

Pending в продуктовом коде (не входит в этот TASK, но полезно зафиксировать для следующего):
- Frontend (`apps/web-react/src/types.ts`) и Python (`services/api-python/app/models.py`) **не трогались** в рамках этого TASK — они и должны остаться неизменными, потому что wire-format `"consultation_skeleton"` сохранён. Если в Phase 0.2+ будет решение перенести wire-format на `"solar_report_skeleton"` — это другой TASK с bright-line #8 cascade (Tier A), отдельным TL go.

## Artifacts

- branch:               `main` (продуктовый repo `/Users/ilya/Projects/astro`)
- commit(s):            `astro:b7774cf` (`b7774cf8ed9c475c5b237b222add1463dc18747f`), parent `astro:4937c00`
- PR:                   n/a (local-only git, no public hosting)
- tests:                **229/229 green** (was 230/230 at `4937c00`; −1 placeholder `Test.Golden.spec` удалён как ожидалось по TASK § Acceptance criterion #2)
- Product repo status:  **committed (commit:b7774cf)** + backup pushed (`/Users/ilya/Backups/astro.git` HEAD `b7774cf`)

Filesystem evidence (re-checked at HANDOFF time, не из памяти):

```
$ git -C /Users/ilya/Projects/astro status --short --branch
## main

$ git -C /Users/ilya/Projects/astro rev-parse HEAD
b7774cf8ed9c475c5b237b222add1463dc18747f

$ git -C /Users/ilya/Projects/astro log --oneline 4937c00..HEAD
b7774cf refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup

$ git -C /Users/ilya/Projects/astro show --stat HEAD | head -10
commit b7774cf8ed9c475c5b237b222add1463dc18747f
[…]
 core/astrology-hs/astrology-core.cabal             |  5 ++--
 core/astrology-hs/src/Bridge/Solar.hs              | 14 ++++-----
 core/astrology-hs/src/Domain/{ConsultationSkeleton.hs => SolarReportSkeleton.hs} | 34 ++++++++++++----------
 core/astrology-hs/test/Spec.hs                     |  6 ++--
 core/astrology-hs/test/Test/Golden.hs              |  9 ------
 core/astrology-hs/test/Test/{Golden/SolarSpec.hs => GoldenSolar.hs} |  2 +-

$ git -C /Users/ilya/Projects/astro diff 4937c00 HEAD -- core/astrology-hs/test/golden/synthetic-solar-1.expected.json
$                                                   # (empty: wire-format byte-identical)

$ git --git-dir=/Users/ilya/Backups/astro.git rev-parse main
b7774cf8ed9c475c5b237b222add1463dc18747f

$ make -C /Users/ilya/Projects/ai-dev-system check 2>&1 | grep "overlay 'astro'"
OK: overlay 'astro' is at maturity=pre-phase0 (README only; CURRENT_STATE/etc. expected after Phase 0 — bump to 'active' then).
```

**Worker НЕ трогал** Python (`services/`), Frontend (`apps/`), contracts (`packages/`), infra (`infra/`, `docker-compose.yml`, `run-local.sh`), `.claude/`, `data/`, документацию (`docs/`). `git show --stat HEAD` показывает только пути под `core/astrology-hs/`.

## Conflicts / risks

### 1. Process: первый `git commit` без `git add -A` дал broken state (исправлено ДО push)

**Что произошло:** После `git mv` + `git rm` файловые операции были staged. Content-edits через Edit-tool (cabal/Bridge/Solar.hs/Spec.hs/SolarReportSkeleton.hs/GoldenSolar.hs) остались **не staged**. Первый `git commit` (без `-a` и без `git add -A`) зафиксировал только renames + deletion → broken state: cabal `exposed-modules` ссылается на `Domain.ConsultationSkeleton`, файла на этом пути нет, `Domain.SolarReportSkeleton.hs` существует но содержит ещё старое имя `module Domain.ConsultationSkeleton`. Build на этом промежуточном HEAD упал бы, тесты не прошли бы.

**Как обнаружено:** `git diff HEAD --stat` после первого commit показал 5 файлов с unstaged content-edits (`cabal`, `Bridge/Solar.hs`, `SolarReportSkeleton.hs`, `Spec.hs`, `GoldenSolar.hs`). Это сигнализировало о неполном commit'е.

**Как исправлено:** `git add -A && git commit --amend --no-edit` — staged всё пропущенное и amend'нул commit. Final HEAD `b7774cf` содержит атомарный полный коммит. Push на backup произошёл уже из правильного состояния (4937c00..b7774cf one-shot, без промежуточного broken commit'а в backup).

**Безопасность:** amend произошёл **до** push в backup remote. На backup ушёл сразу финальный `b7774cf`, без промежуточного `552d919` (broken-state commit, который существовал ~30 секунд только локально). Force-push в backup НЕ потребовался.

**Риск для будущих Worker'ов:** при использовании `git mv`/`git rm` параллельно с Edit-tool — обязательно `git add -A` перед commit. Альтернатива — `git commit -a` (с `-a` флагом). Worker считает это process-correction, кандидат на запись в `astro/.claude/corrections.md` (не делается в этом TASK — отдельный TL go нужен для записи).

### 2. Один historical reference в комментарии (контекст: Worker мнение)

Module header в `SolarReportSkeleton.hs` после rename содержит фразу `«The prior name lived under the @Domain.Consultation*@ namespace»` — это намеренный historical pointer для будущего читателя кода, чтобы тот понял почему файл переименован. Сам токен `ConsultationSkeleton` (PascalCase) **отсутствует** в комментарии (заменено на `Domain.Consultation*` с wildcard). Pure-PascalCase grep `'ConsultationSkeleton'` даёт 0 matches — соответствует TASK § Acceptance.

Worker мнение: это semantic-level historical reference, ценный для понимания эволюции namespace; не блокирует acceptance. Если Reviewer считает что и эта ссылка должна быть удалена — отдельный mini-edit ≤ 5 строк, тривиальный.

### Других conflicts/risks нет

- Wire-format JSON contract: byte-identical (golden fixture diff empty).
- Python/Frontend: не трогались, контракт стабилен.
- bright-line #8 не триггернут (no schema change).
- Behavior change: ноль (Eq cabal test, Eq runSolar output bytes).

## Next step

**Reviewer pass обязателен** (по требованию пользователя в этом TASK). TL запускает:

```
make new-handoff SLUG=astro \
  TASK=project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md \
  FROM=reviewer TO=tl
```

Reviewer проверяет согласно Worker-сводке выше + требованиям пользователя:
- (a) нет behavior change (golden fixture identical) — verify;
- (b) нет имени `ConsultationSkeleton` или `Test.Golden\b` в core — verify;
- (c) wire-format `"consultation_skeleton"` сохранён — verify;
- (d) commit message соответствует TASK template — verify;
- (e) commit диапазон `4937c00..HEAD` ровно один commit — verify;
- (f) backup parity — verify.

Reviewer пишет findings **в файл HANDOFF**, не в stdout. После Reviewer HANDOFF — TL accepts оба HANDOFF + TASK (если нет блокеров) или открывает мини-TASK на исправления (если блокер найден).

После accept (если без блокеров): mяч у TL — выбор следующего хода (recon § 5.2 закрыт; PHASE_0_TASKS.md T-B.8 финализирован; можно фиксировать в overlay через docs-only follow-up TASK или переходить к product-фичам).
