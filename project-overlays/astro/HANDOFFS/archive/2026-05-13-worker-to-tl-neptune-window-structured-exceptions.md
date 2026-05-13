# HANDOFF: worker → tl — neptune-window-structured-exceptions

- Status: closed
- Date: 2026-05-13 14:32
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker (TL-salvaged post-truncation)
- TASK: project-overlays/astro/TASKS/2026-05-13-neptune-window-structured-exceptions.md

## Summary

**Phase 4b Path 4 implementation completed.** Worker subagent (`a0d2e46652775fed8`) выполнил полную имплементацию: refactor `_assert_three_phase_intervals` с window-count + phase-set semantics + per-window tolerance overrides, 2 structured exceptions для Neptune boundaries (W3 end ±20d, W1 start ±200d) с явными reason-строками и memo cross-refs, unmark 2 Cat 4 Neptune xfails. Worker'ова message была truncated mid-pytest-wait (78s pytest run); commit + HANDOFF steps не дошли. TL inline-verified working tree changes + ran pytest (115 passed + 8 xfailed = exact Path 4 expected); committed Worker's work on его behalf с явной attribution.

## Done

- **Worker work (uncommitted при truncation):** полный refactor `services/api-python/tests/test_natalya_transits_acceptance.py`:
  - Module docstring обновлён с Path 4 contract + memo cross-reference.
  - Import `aggregate_display_windows` from `app.pdf.outer_cards` (no duplication).
  - `_assert_three_phase_intervals` refactored: `len(hits) == 3` → `len(aggregate_display_windows(hits)) == 3`; strict phase-order list → set-of-phases per window; explicit `expected_phase_sets` param (no actual-emission derivation — non-tautological); per-window-index 1-based `tolerance_overrides`.
  - REF_* constants изменены с 3-tuple `(phase, start, end)` на 2-tuple `(start, end)` — phase moved to caller.
  - 3 outer card tests (U-V, N-J, N-N) обновлены с `expected_phase_sets` параметром.
  - **User-spec vs engine reality reconciliation** (Worker discipline rule applied): user spec listed N-J W2 = {Retrograde} и N-N W2 = {Retrograde}, но memo § 3.5 показывает actual engine emission lp3 = DirectReturn для обоих. Worker использовал **engine truth** (W2 = {DirectReturn}) и явно задокументировал расхождение в inline test comments.
  - 2 Neptune tests получили `tolerance_overrides` с reason-строками:
    - N-J W3 end ±20d: «Marina extends past engine 1° orb threshold by 17d».
    - N-N W1 start ±200d: «Marina shows tail only of long first-orb-window».
  - `@pytest.mark.xfail` декораторы удалены с обоих Neptune tests.
  - Phase 5/6 xfails не тронуты (verified в diff).
- **TL salvage commit:** `d44d7c6` на `main` ветке. Commit message attribute Worker (a0d2e46652775fed8) + явная нота про truncation + TL inline verification.
- **Tests:** baseline `113 passed + 10 xfailed` (8c9588d) → after Worker work `115 passed + 8 xfailed` (d44d7c6). Exact Path 4 expected count. 0 failed.
- **Push backup:** `8c9588d..d44d7c6  main -> main` parity verified.

## Remaining

Ничего в Phase 4b scope.

## Artifacts

- branch:               main
- commit(s):            d44d7c6 (single commit, TL-salvaged post-Worker-truncation)
- PR:                   нет (direct main per Tier C)
- tests:                115 passed + 8 xfailed (was 113 + 10; +2 passed / −2 xfailed exactly)
- Product repo status:  committed

## Conflicts / risks

### Worker truncation handling (post-hoc salvage)

Worker subagent message was truncated mid-pytest-wait. Worker had completed all code changes (verified in `git diff` pre-commit), reconciliation reasoning documented in code comments. Worker did **not** commit, did **not** push backup, did **not** write HANDOFF. TL performed:

1. Independent `git diff` review — all 4 TL refinements applied correctly:
   - 1-based window index canon ✓ (`tolerance_overrides={3: ...}` и `{1: ...}`).
   - Explicit `expected_phase_sets` parameter — не выводится из actual ✓.
   - `outer_cards.aggregate_display_windows` import (no duplication) ✓.
   - Single-file scope discipline ✓ (`git status --short` — only `test_natalya_transits_acceptance.py` modified).
2. Independent pytest run — `115 passed + 8 xfailed in 224.17s`. Exact Path 4 expected.
3. Salvage commit с attribution на Worker subagent ID + явной нотой про truncation.
4. This HANDOFF — written by TL post-hoc для proper lifecycle closure. Содержание = de facto Worker deliverable + TL audit notes.

**Не пытался резюмировать Worker'ову сессию через SendMessage** — Phase 4b deliverable был уже complete в working tree, нужны были только mechanical steps (commit + HANDOFF). Salvage path выбран как минимально-invasive.

### User-spec vs engine reality reconciliation (engine = SoT)

TASK spec § Files listed user-spec phase sets как starting reference: N-J W2 = {Retrograde}, N-N W2 = {Retrograde}. Memo § 3.5 показывает engine actual emission: оба = {DirectReturn} (lp3 = DirectReturn). Per Phase 4b discipline rule, Worker использовал engine truth и явно задокументировал в test comments:

```python
# Engine emission per memo § 3.5: ... W2={DirectReturn} ... — engine
# is source of truth here (the user-listed reference in the TASK spec
# had W2={Retrograde}, which contradicts actual engine emission; per
# Phase 4b discipline rule we follow the engine).
```

Это **expected behaviour** (TL spec явно предусматривает reconciliation step). Flag for user: 2 typos в TASK 4b spec (W2 для N-J и N-N) — не блокер, Worker reconcile'нул engine-side.

### No bright-line violations

- Engine, schema, fixtures, PDF code, presentation helpers — 0 lines changed.
- Single file modified (test_natalya_transits_acceptance.py).
- Phase 5/6 xfails не тронуты.
- 2 Cat 4 Neptune xfails unmarked (как и обещано Path 4 acceptance).

## Next step

TL inline-verify уже выполнен (см. § Conflicts above). Closing pipeline:

1. `make accept-handoff FILE=project-overlays/astro/HANDOFFS/2026-05-13-worker-to-tl-neptune-window-structured-exceptions.md` — bump Status: closed + move to archive.
2. `make accept-task FILE=project-overlays/astro/TASKS/2026-05-13-neptune-window-structured-exceptions.md` — bump Status: done + move to archive (после submit-task → review).
3. Открыть TASK 5 (Phase 5 — Rulership-expanded target houses).
4. Update STATUS_RU (Phase 4b CLOSED, Phase 5 opens), overlay commit + push.
