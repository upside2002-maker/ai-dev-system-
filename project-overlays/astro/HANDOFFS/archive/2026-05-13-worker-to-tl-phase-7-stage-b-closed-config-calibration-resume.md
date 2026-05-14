# HANDOFF: worker → tl — phase-7-stage-b-closed-config-calibration (Stage B resume)

- Status: closed
- Date: 2026-05-13
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker (Tier C, resume session)
- TASK: project-overlays/astro/TASKS/2026-05-13-phase-7-stage-b-closed-config-calibration.md
- Predecessor handoff: project-overlays/astro/HANDOFFS/archive/2026-05-13-worker-to-tl-phase-7-stage-b-closed-config-calibration.md (Stage A.2 STOP escalation, archived after TASK 7c overlay-only gate amendment)
- Product repo status: committed (backup push parity verified: backup/main = c936dd1)

## TL;DR

Phase 7 Stage B closed-config calibration completed under the amended gate (a)-(d) from TASK 7c. One product commit lands `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` extensions for cases 05 + 10, finalises `services/api-python/scripts/render_case.py` (kept from prior Worker session), generalises `_assert_three_phase_intervals` with `expected_window_count: int = 3` parameter, creates parameterised `test_multi_case_calibration.py`, and applies non-semantic doc/comment generalisation. Tests: **183 passed / 0 xfailed / 0 failed** (150 baseline + 33 new). 0 new tolerance overrides; threshold preserved. **Production-readiness verdict: «Ready for Marina show — pending user ack».**

## Amended gate (a)-(d) verification (Stage A.2 entry)

Resume Worker verified before starting Stage B by direct `transit_matrix_by_month` invocation on case 07 expected.json (`/Users/ilya/Projects/astro/services/api-python && .venv/bin/python -c "..."`):

- **(a) Labels — PASS.** 13 unique consecutive labels: `Июль 2025, Август 2025, Сентябрь 2025, Октябрь 2025, Ноябрь 2025, Декабрь 2025, Январь 2026, Февраль 2026, Март 2026, Апрель 2026, Май 2026, Июнь 2026, Июль 2026`. No duplicates, no skips. Matches `test_mariya_transit_matrix.py` regression test (TASK 7a).
- **(b) Cells — PASS.** Rows 1-11 match Marina exactly. Cell mismatches confined to documented TYPE-A boundary rows (calibration report § 4 items 4-5).
- **(c) Boundary mismatches classifiable — PASS.** Rows 12 (Июнь 2026: Mars 9 vs 8, Venus 11 vs 10) and 13 (Июль 2026: Saturn 8 vs 7, Venus 12 vs 11) are documented in § 4 items 4-5 with full transition data (Mars 2026-06-05, Venus 2026-06-11, Saturn 2026-07-08, Venus 2026-07-08).
- **(d) Verdict honest — PASS.** § 6 reflects honest reopening rationale; TYPE-A items visible.

All four conditions PASS at Stage B entry. Proceeded directly to B.1.

## Stage B per-section completion status

### B.1 — Case 05 Екатерина allowlist + card-facts: DONE

Extended `OUTER_CARD_ALLOWLIST["05-ekaterina-2025-2026"]` with 3 triples per Marina pp. 34-37 (`Соляр 2025-2026_2.pdf`):

- `(Uranus, Square, Moon)` — Marina pp. 34-35
- `(Uranus, Sextile, Jupiter)` — Marina pp. 35-36
- `(Neptune, Trine, Jupiter)` — Marina pp. 36-37

Populated `_OUTER_CARD_FACTS` for each — transit_natal_house, target_natal_house, transit_ruled_houses, target_ruled_houses, transit_walks_house (None for Нептун триг Юпитер where Marina leaves walks cell empty), psychology + event_level Marina-style paraphrase. Engine emits 3 display windows per card for case 05.

Rendered PDF `/tmp/05-ekaterina-stage-b.pdf` contains all 3 cards.

### B.2 — Case 10 Данила allowlist + card-facts: DONE

Extended `OUTER_CARD_ALLOWLIST["10-danila-2025-2026"]` with 3 triples per Marina pp. 16-19:

- `(Uranus, Square, Moon)` — Marina pp. 16-17 (3 windows)
- `(Neptune, Square, Venus)` — Marina pp. 17-18 (3 windows)
- `(Neptune, Square, Jupiter)` — Marina pp. 18-19 (**4 windows** per «четвертое касание»)

Populated `_OUTER_CARD_FACTS` for each.

**Case 10 card 3 engine output verification:** `aggregate_display_windows` returns exactly 4 windows for `Neptune Square Jupiter` (engine raw hits: Direct@2461190.7, Direct@2461487.9, Retrograde@2461647.0, DirectReturn@2461779.4). Engine output matches Marina «четвертое касание» natively — no STOP trigger, no hardcoded count in production facts.

`_assert_three_phase_intervals` helper generalized: optional `expected_window_count: int = 3` parameter; case 10 card 3 test passes 4. Phase 4b Natальи tolerance_overrides unchanged.

Rendered PDF `/tmp/10-danila-stage-b.pdf` contains all 3 cards.

### B.3 — `render_case.py` finalization: DONE

`services/api-python/scripts/render_case.py` already existed (untracked) from prior Stage A.2 Worker session. Resume Worker reviewed: file works correctly for all 3 cases (05/07/10), produces provenance sidecar with correct `case_label` extra. Committed as-is — no adjustments required.

`render_natalya.py` left unchanged per Worker discretion in TASK spec § Files (no semantic need to refactor as thin wrapper).

### B.4 — Multi-case acceptance tests: DONE

New file `services/api-python/tests/test_multi_case_calibration.py` with 33 parameterised tests covering cases 05/07/10:

- **Monthly table label sequence** (3 tests, parameterized): full equality vs `EXPECTED_MONTHLY_LABELS` per case.
- **Case 07 monthly cells TYPE-A boundary** (1 test): asserts rows 1-11 match Marina exactly; rows 12-13 produce documented post-TASK-7a engine output. Cell-value-mismatches outside TYPE-A trigger failure per amended gate (b).
- **Outer cards count matches allowlist** (3 tests, parameterized): cases 05/10 = 3; case 07 = 0 (Marina editorial choice).
- **Outer card titles Marina-style** (2 tests, parameterized 05/10): planet + aspect locative + target stem present per card.
- **Outer card interval count** (6 tests, parameterized): case 05 all 3 cards = 3 windows; case 10 cards 1-2 = 3, card 3 = 4 windows.
- **Outer card golden_rule populated** (2 tests, parameterized 05/10): row 2 transit + radix placement non-empty; psychology + event level non-empty.
- **Calendar has entries** (3 tests, parameterized): each case calendar produces ≥ 20 entries.
- **Calendar exposes rulership_houses** (3 tests, parameterized): every entry has `target_house_set`.
- **Calendar target_house_set contains placement** (3 tests, parameterized): sampled `(transit, target, aspect)` per case has Marina-listed placement house in `target_house_set`.
- **Case 10 Нептун кв Юпитер 4-windows engine pin** (1 test): direct `aggregate_display_windows` engine contract.
- **Provenance carries case_label** (3 tests, parameterized): `render_case.py` sidecar `extra.case_label` matches `--case-id`.
- **Rendered PDF contains outer card titles** (3 tests, parameterized): regex-based extraction; case 05 = 3 titles; case 07 = 0 (forbidden any «тр X в Y c нат Z»); case 10 = 3 titles.

Tests use session-scoped render fixtures (one PDF per case per session) for speed.

### B.5 — Case 05 Venus monthly boundary: DONE (note-only)

TYPE-A item 3 in calibration report § 4 already documented (case 05 Venus Jul 2025). No structured override added. No new override mechanism introduced. Production code, fixtures, tests unchanged for this item per TASK 7b § B.5 + TASK 7c § Fixations 4 (same family as case 07 boundary rows; all anchor convention divergence; Path B convergence deferred to future programme).

### B.6 — Calibration report final update: DONE

Updated `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`:

- **Header**: title renamed «Phase 7 (Stage A + Stage B)»; baseline updated to `main @ 8a4865e` + Stage B commit; tests counts `183 passed / 0 xfailed / 0 failed`.
- **§ 3.1 case 05**: outer cards section updated — TYPE-A item [RESOLVED via Stage B] note.
- **§ 3.3 case 10**: outer cards section updated — TYPE-A item [RESOLVED via Stage B] note; 4-window engine output verified.
- **§ 4 TYPE-A items 1, 2**: marked `[RESOLVED via Stage B]` with full detail (allowlist + facts populated, paths to Marina pages, engine 4-window pinning for case 10 card 3).
- **§ 5**: total override count breakdown — Stage B added 0 new overrides; gate WITHIN threshold (2 total ≤ 10; 2 ≤ 5 per case).
- **§ 6 Verdict update (post-Stage-B)**: «**Ready for Marina show — pending user ack**». Verdict rationale enumerates all closure conditions (no TYPE-B; all TYPE-A closed-config gaps resolved; overrides within threshold; TYPE-C documented; tests green; canonical render path).
- **§ 6 Required follow-up**: items 1-3 marked DONE; item 4 [NEXT — user] = explicit ack.
- **Appendix**: Stage B production-ready artefact paths added (`/tmp/05-ekaterina-stage-b.pdf` + sidecar; `/tmp/07-mariya-stage-b.pdf` + sidecar; `/tmp/10-danila-stage-b.pdf` + sidecar; `services/api-python/scripts/render_case.py`; `services/api-python/tests/test_multi_case_calibration.py`).

### Doc/comment generalization: DONE

- **`outer_cards.py`** module docstring: «three deep-dive cards … case 08 (Наталья)» → generalized to per-case allowlist with case 10 4-window note. Tweaked aggregate_display_windows + build_outer_card + ordinals comment to clarify «typically 3, case 10 Нептун-Юпитер = 4». Defensive fallback comment updated to reference case 05 / 08 / 10 coverage.
- **`solar.html.j2`**: top-level Jinja block comment generalized («3 realisation intervals» → «3+ realisation intervals per Marina card editorial choice»). User-facing intro paragraph reworded «интервалы трёх касаний» → «интервалы касаний (обычно три, иногда больше — по эталону Марины)». No semantic code change in either file; both already iterate `card.intervals`.

### Test helper generalization: DONE

`tests/test_natalya_transits_acceptance.py`:

- `_assert_three_phase_intervals` accepts `expected_window_count: int = 3` parameter. Default preserves Phase 4b behavior for Натальи 3 existing tests (no test changes downstream).
- Asserts `len(reference) == expected_window_count` to catch caller mismatch.
- Module-level docstring «Window count» bullet updated: default 3, accepts override for case 10 Нептун-Юпитер = 4.
- **Phase 4b structured Neptune overrides on Натальи UNCHANGED** (N-J W3 end ±20d, N-N W1 start ±200d).

## Override count + Phase 4b gate clause status

| Case | Existing overrides | Stage B additions | Total |
|---|---|---|---|
| 08-natalya | 2 (Phase 4b: N-J W3 end ±20d, N-N W1 start ±200d) | 0 | 2 |
| 05-ekaterina | 0 | 0 | 0 |
| 07-mariya | 0 | 0 | 0 |
| 10-danila | 0 | 0 | 0 |
| **Total** | **2** | **0** | **2** |

- ≤ 10 total: **YES** (2 ≤ 10).
- ≤ 5 per case: **YES** (max 2 on Натальи).
- **Gate status: WITHIN threshold.**

## Production-readiness verdict

**«Ready for Marina show — pending user ack»**

Rationale (full enumeration in calibration report § 6 «Verdict update (post-Stage-B)»):

- No TYPE-B regressions. TYPE-B item 1 (case 07 label arithmetic) resolved by TASK 7a.
- All TYPE-A closed-config gaps resolved (items 1, 2 = cases 05/10 outer cards).
- TYPE-A boundary items 3-5 = anchor convention; documented notes per TASK 7c § Fixations 4 + TASK 7b § B.5; explicitly out of Stage B closed-config scope.
- TYPE-C item 1 (case 10 card 3 = 4 windows) handled via engine output + helper generalization.
- TYPE-C item 2 (case 07 zero outer cards) correctly matches Marina via empty allowlist entry.
- Override count within threshold (2 total).
- Tests green (183/0/0).
- Canonical render path (`render_case.py`) with correct provenance for each case.

After explicit user ack on the updated calibration report: recovery program closes; PDFs cases 05/07/08/10 production-ready (clientable to Marina).

## Calibration report path

`/Users/ilya/Projects/ai-dev-system/project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (modified Stage B; overlay commit lands together with this HANDOFF).

## Stage B PDF artefacts (per case, with sidecars)

- `/tmp/05-ekaterina-stage-b.pdf` + `/tmp/05-ekaterina-stage-b.pdf.provenance.json`
- `/tmp/07-mariya-stage-b.pdf` + `/tmp/07-mariya-stage-b.pdf.provenance.json`
- `/tmp/10-danila-stage-b.pdf` + `/tmp/10-danila-stage-b.pdf.provenance.json`

All rendered via `services/api-python/scripts/render_case.py --case-id <id> --output <path>`. Each sidecar has mode `fixture-render`, SHA `8a4865e94eb2` at render time (the Stage B commit landed AFTER renders — TL can re-render at the Stage B HEAD if desired; the new render would land SHA `c936dd15169c`).

## Files touched (single commit `c936dd1`)

- **modified:**
  - `services/api-python/app/pdf/outer_cards.py` — `OUTER_CARD_ALLOWLIST` extended (cases 05/10); `_OUTER_CARD_FACTS` extended; doc/comment generalization.
  - `services/api-python/app/pdf/templates/solar.html.j2` — Jinja comment + user-facing intro generalization.
  - `services/api-python/tests/test_natalya_transits_acceptance.py` — `_assert_three_phase_intervals` accepts `expected_window_count` parameter.
- **new:**
  - `services/api-python/scripts/render_case.py` (created Stage A.2, committed Stage B).
  - `services/api-python/tests/test_multi_case_calibration.py` (33 parameterized tests).

Engine / Haskell core / schema / fixtures / `transit_themes.py` / `rulership_houses.py` / `synthesis_themes.py` / `builder.py` / `provenance.py` / Phase 4b structured overrides: **0 lines changed**.

## Pytest result

```
$ cd services/api-python && .venv/bin/pytest --tb=no -q
........................................................................ [ 39%]
........................................................................ [ 78%]
.......................................                                  [100%]
183 passed in 27.32s
```

**150 baseline (post-TASK-7a) + 33 new multi-case tests = 183 passed, 0 xfailed, 0 failed.**

`cabal build` (core/astrology-hs): **Up to date**.

## Backup parity

```
$ git rev-parse main
c936dd15169ca5cc4a9425617f2d01c0677e6cfe
$ git rev-parse backup/main
c936dd15169ca5cc4a9425617f2d01c0677e6cfe
```

**Parity verified.**

## Commit summary

`c936dd1 feat(pdf): multi-case outer cards + acceptance tests (Phase 7 / TASK 7b Stage B)` — single commit covering all Stage B deliverables in a clean closed-config boundary.

## Process

- Worker accepted TASK in `in-progress` (resumed; TASK 7c did not flip status). Did NOT re-run `accept-task.sh`.
- Worker bumped TASK 7b Status from `in-progress` to `review` after Stage B complete and HANDOFF written.
- TL inline-verifies per Tier C; no Reviewer subagent.
- Next step: TL runs `accept-handoff.sh worker tl <TASK-path>` after reading this HANDOFF + calibration report + PDFs; closes TASK 7b. After user explicit ack on calibration report: recovery program closes.

## Open items / nothing-to-do flags

None — all Stage B acceptance items closed.
