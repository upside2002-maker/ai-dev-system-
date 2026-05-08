# HANDOFF: reviewer → tl — astro-core-naming-drift-cleanup

- Status: closed
- Date: 2026-05-06 19:53
- Project: astro
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Reviewer / Red Team
- TASK: project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md

## Summary

**Verdict: ACCEPT — no blockers.** Независимая верификация Worker-результата (`astro:b7774cf`) против всех TASK acceptance criteria + 6 Reviewer-критериев из требования пользователя ((a)-(f)). Все 16 проверок зелёные. Поведение runSolar byte-identical baseline (golden fixture diff = 0 lines). Wire-format JSON-key `consultation_skeleton` сохранён, что защищает 4 Python consumer-точки (verified). 1 атомарный commit, backup parity. Worker self-reported один process-инцидент (incomplete-commit + amend ДО push) — Reviewer подтверждает: amend произошёл локально до `git push backup`, broken intermediate commit `552d919` существовал ~30 секунд только в local, на backup ушёл только финальный `b7774cf`. Это **не блокер** для accept; кандидат на запись в `astro/.claude/corrections.md` отдельным docs-only follow-up.

## Done

### Reviewer независимо повторил все проверки, не доверяя Worker-сводке.

#### Commit hygiene (R1–R5)

| Check | Result |
|---|---|
| R1 HEAD identity | `b7774cf8ed9c475c5b237b222add1463dc18747f` |
| R2 1 commit in `4937c00..HEAD` | `count: 1`, message `refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup` |
| R3 working tree clean | `## main` |
| R4 paths in HEAD only under `core/astrology-hs/` | 6 files: `astrology-core.cabal`, `src/Bridge/Solar.hs`, `src/Domain/SolarReportSkeleton.hs`, `test/Spec.hs`, `test/Test/Golden.hs` (deleted), `test/Test/GoldenSolar.hs` (renamed) |
| R5 backup parity | local `b7774cf` == `/Users/ilya/Backups/astro.git` `b7774cf` |

#### Name-purge (R6–R8)

| Check | Result | Acceptance |
|---|---|---|
| R6 `ConsultationSkeleton` (PascalCase) | grep exit 1 (0 matches) | ✅ |
| R7 `Test\.Golden([^A-Za-z0-9_]\|$)` | grep exit 1 (0 matches) | ✅ |
| R8 `consultationSkeleton` (camelCase) | grep exit 1 (0 matches) | ✅ |

#### Wire-format integrity (R9–R10)

| Check | Result | Acceptance |
|---|---|---|
| R9 `"consultation_skeleton"` wire key | found 1× in `core/astrology-hs/src/Bridge/Solar.hs:434` (с правильно переименованным accessor `baSolarReportSkeleton a`) + 1× в frozen golden fixture `test/golden/synthetic-solar-1.expected.json:1` (см. R10 — fixture неизменно) | ✅ |
| R10 golden fixture vs 4937c00 | `git diff` = **0 lines** — byte-identical | ✅ |

#### Cross-layer consistency (R11)

Wire-key `consultation_skeleton` ещё активно используется во внешних потребителях, что **подтверждает** критичность сохранения wire-format Worker'ом:
- `apps/web-react/src/types.ts:415: consultation_skeleton: ConsultationSkeleton;` (Frontend TS-type интерфейс)
- `packages/contracts/solar-computed-facts.schema.json:709, 737` (JSON-Schema required + $defs reference)
- `packages/test-fixtures/golden-cases/{01,02,03,04,05,07,08}-*.expected.json:3` (7 реальных клиентских golden cases)
- **R16 (Python consumer trace):** `services/api-python/app/draft.py:170`, `services/api-python/app/main.py:{451,457,458,492}` — 5 Python-точек активно читают `analysis.consultation_skeleton` из output Haskell-core. Изменение wire-key сломало бы их.

Все эти файлы Worker НЕ модифицировал — verified via R4 (HEAD diff stat). Wire contract intact; frontend/schema/fixtures/Python continue working без изменений.

#### Build + test (R12, fresh independent run)

```
$ cabal build
[…library + executable rebuilt without errors…]

$ cabal test --test-show-details=direct
229 examples, 0 failures
Test suite astrology-core-tests: PASS
```

229 / 0 — точно как Worker заявил; baseline был 230 (−1 placeholder `Test.Golden.spec` удалён по TASK acceptance criterion #2).

#### Commit message audit (R13–R14)

Commit message:
```
refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup

- Domain.ConsultationSkeleton → Domain.SolarReportSkeleton (closes real drift #1
  from architecture-drift-recon.md §5.2: bright line #5 naming-level violation).
- Test.Golden placeholder removed; Test.Golden.SolarSpec → Test.GoldenSolar
  (closes real drift #2: T-B.8 leftover rename).
- No behavior change; wire-format JSON key `consultation_skeleton` preserved
  to keep Python/Frontend contract stable (bright line #8 not triggered).
- Tests: cabal test 229/229 green (was 230/230 at 4937c00; -1 placeholder test
  Test.Golden.spec which was a trivial True `shouldBe` True stub).

Refs: architecture-drift-recon.md §5.2, PHASE_0_TASKS.md T-B.8.
```

Required citations (TASK template):
- ✅ `architecture-drift-recon.md §5.2` — present (2 mentions)
- ✅ `PHASE_0_TASKS.md T-B.8` — present
- ✅ `bright line #5` — present (real drift #1 attribution)
- ✅ `wire-format JSON key consultation_skeleton preserved` — present
- ✅ Test count delta evidence — present (229/229 vs 230/230)

#### User criteria mapping ((a)–(f) из go-сообщения)

| User criterion | Reviewer verdict |
|---|---|
| (a) нет behavior change (golden fixture identical) | ✅ R10: 0-line diff |
| (b) нет имени `ConsultationSkeleton` или `Test.Golden\b` в core | ✅ R6, R7: 0 matches obeих |
| (c) wire-format `"consultation_skeleton"` сохранён | ✅ R9: 1 match in Bridge/Solar.hs:434, accessor renamed but key preserved |
| (d) commit message соответствует TASK template | ✅ R13/R14 |
| (e) ровно 1 commit `4937c00..HEAD` | ✅ R2 |
| (f) backup parity | ✅ R5 |

## Remaining

После accept TL'ом этого Reviewer HANDOFF + Worker HANDOFF + TASK:

1. (recommended, не блокер) Open mini-TASK на запись в `astro/.claude/corrections.md` нового Correction по поводу process-инцидента из Worker § Conflicts ("git mv + Edit-tool без `git add -A` → incomplete commit"). Это product-code change (запись в `.claude/corrections.md` внутри `/Users/ilya/Projects/astro`), Tier C docs-only.

2. (optional) Open mini-TASK на phase0-tasks-annotations refresh — обновить `Status @ astro:4937c00:` для T-B.8 (`partial` → `closed-in-fact (T-B.8 finalized in b7774cf)`) в `PHASE_0_TASKS.md`. Docs-only, overlay-only, Tier C.

3. (optional, future) Если в Phase 0.2+ возникнет необходимость переименовать wire-format JSON key с `"consultation_skeleton"` на что-то более согласованное с Haskell-side `SolarReportSkeleton` — это Tier A через bright-line #8 cascade (schema + fixtures + Python + TS + roundtrip-tests одним коммитом).

## Artifacts

- branch:               `main` (продуктовый repo `/Users/ilya/Projects/astro`)
- commit(s):            `astro:b7774cf` (= Worker's commit, independently verified by Reviewer)
- PR:                   n/a
- tests:                **229/229 green** (independently re-run by Reviewer)
- Product repo status:  **committed (commit:b7774cf)** + backup pushed (verified parity at R5)

Filesystem evidence (Reviewer fresh re-check):

```
$ cd /Users/ilya/Projects/astro
$ git log --oneline 4937c00..HEAD
b7774cf refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup

$ cd core/astrology-hs && cabal test --test-show-details=direct 2>&1 | grep examples
229 examples, 0 failures

$ cd /Users/ilya/Projects/astro
$ git grep -n 'ConsultationSkeleton' core/astrology-hs/ ; echo "exit: $?"
exit: 1                                  # 0 matches

$ git grep -n -E 'Test\.Golden([^A-Za-z0-9_]|$)' core/astrology-hs/ ; echo "exit: $?"
exit: 1                                  # 0 matches

$ git grep -n 'consultationSkeleton' core/astrology-hs/ ; echo "exit: $?"
exit: 1                                  # 0 matches

$ git grep -n '"consultation_skeleton"' core/astrology-hs/src/Bridge/Solar.hs
core/astrology-hs/src/Bridge/Solar.hs:434:    , "consultation_skeleton"     .= baSolarReportSkeleton a

$ git diff 4937c00 HEAD -- core/astrology-hs/test/golden/synthetic-solar-1.expected.json | wc -l
       0
```

## Conflicts / risks

### Worker process-incident (NOT a blocker)

Worker self-reported в § Conflicts: первый `git commit` (без `-a` и без `git add -A`) зафиксировал только staged file-ops (renames + deletion), оставив 5 файлов с unstaged content-edits → broken intermediate commit `552d919`. Восстановление через `git commit --amend -a --no-edit` ДО `git push backup main`.

**Reviewer верификация инцидента:**
- Final commit `b7774cf` корректен (16 проверок выше — все ✅).
- На backup ушёл сразу `4937c00..b7774cf`, broken `552d919` отсутствует в backup history.
- Force-push на backup НЕ был использован (verified: `git push backup main` без `--force`).
- Local-only git, no public hosting → broken intermediate commit не «утёк» никуда.

**Reviewer мнение:** инцидент имеет ценный learnable, но не нарушил TASK acceptance. Worker корректно идентифицировал проблему через `git diff HEAD --stat`, исправил amend'ом ДО push, отчитался в HANDOFF. Кандидат на Correction в `astro/.claude/corrections.md` (см. Remaining #1) — но не блокер этого accept'а.

### Historical-pointer comment in `Domain/SolarReportSkeleton.hs`

Module header содержит фразу `«The prior name lived under the @Domain.Consultation*@ namespace»` (с wildcard). Worker зафиксировал в § Conflicts что это намеренный history pointer без буквального токена `ConsultationSkeleton` — pure-PascalCase grep (R6) даёт 0 matches.

**Reviewer мнение:** semantically valuable для будущего читателя, не нарушает invariant. **Не блокер.** Если TL хочет — отдельный 1-строчный edit, тривиальный (но не рекомендуется удалять — теряется semantic context для readers).

### Других conflicts/risks Reviewer не нашёл

Перечень потенциальных проблем, которые Reviewer проверил и НЕ обнаружил:
- ❌ Wire-format change → 0-line golden diff (R10) подтверждает byte-identical
- ❌ Out-of-scope file changes → R4 показывает 6 файлов, все под `core/astrology-hs/`
- ❌ Cabal references к старому имени → R12 build green = exposed-modules + other-modules synced
- ❌ Spec.hs broken → R12 cabal test all 229 examples found and run
- ❌ Behavior regression → R10 golden fixture byte-equal + 229/229 pass
- ❌ Force-push / history rewrite → R5 parity check + Worker self-report confirms no force-push
- ❌ Multi-commit / non-atomic → R2 count = 1
- ❌ Bright-line #8 trigger → wire-key preserved, no schema/fixture/Python/TS modifications

## Next step

**Reviewer verdict: ACCEPT — no blockers.** TL может accept оба HANDOFF + TASK обычным lifecycle:

```
make accept-handoff FILE=project-overlays/astro/HANDOFFS/2026-05-06-reviewer-to-tl-astro-core-naming-drift-cleanup.md
make accept-handoff FILE=project-overlays/astro/HANDOFFS/2026-05-06-worker-to-tl-astro-core-naming-drift-cleanup.md
make accept-task FILE=project-overlays/astro/TASKS/2026-05-06-astro-core-naming-drift-cleanup.md
```

После accept — TL'ные next-step opcji описаны в Worker HANDOFF § Remaining + здесь § Remaining (обе списки совместимы).
