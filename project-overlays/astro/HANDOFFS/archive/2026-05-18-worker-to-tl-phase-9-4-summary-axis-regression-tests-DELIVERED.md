# HANDOFF: Worker → TL — Phase 9.4 Summary Axis Regression Tests — **DELIVERED (β scope)**

- Status: closed (TL inline-verify + user explicit closure ack 2026-05-18; TASK 9.4 archived).
- Дата: 2026-05-18.
- TASK: `project-overlays/astro/TASKS/2026-05-17-phase-9-4-summary-axis-regression-tests.md` (Status: in-progress → review pending TL closure ack).
- Tier: C (tests-only; Reviewer NOT required per user direction).
- Worker mode: normal.
- Outcome: **All β-scope acceptance items met.** 4 pytest tests added для cases 02/03/08/10 pinning `analysis.house_axis.primary_axis` к Marina-curated value per memo § 1.1. Memo erratum + programme lesson note landed per user verbatim formulation 2026-05-18.
- Baseline: product main @ `aca694b`; overlay master @ `8d9487b` (start). Pytest **368 → 372 passed + 2 skipped + 0 failed**; cabal Up to date; `git status --short` clean before commits.

---

## § 0. Worker scope discipline preserved

- ✓ NO product code modified — `git diff aca694b -- services/api-python/app/` empty.
- ✓ NO Haskell engine / schema / fixtures / `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` touched.
- ✓ NO template / Jinja filter / allowlist data modified.
- ✓ NO cases 05/09/Ольга 11 pinned (β scope explicit).
- ✓ NO Marina-reference PDFs re-extracted (cases 01/04/07 skipped per user direction).
- ✓ Test-only addition: 1 new file `services/api-python/tests/test_summary_themes.py`.

---

## § 1. Stage 1 — Engine primary-axis field path (confirmed)

Field path matches prior Worker trace (HANDOFF STOP § 2.1):

```python
facts["analysis"]["house_axis"]["primary_axis"]
# → {"low": int 1..6, "high": int 7..12, "strength": int} or None

facts["analysis"]["house_axis"]["secondary_axis"]
# → same shape or None
```

- **Computation:** Haskell core `core/astrology-hs/src/Domain/HouseAxisAnalysis.hs::analyzeAxes` (line 159-205). Method: project 12 solar cusps onto natal Placidus chart → count `axisOf(natalHouse)` → sort `(Down strength, asc low-pole)` → take top if `strength ≥ minAxisStrength = 3`.
- **Bridge:** `core/astrology-hs/src/Bridge/Solar.hs::baHouseAxis` (line 411 + JSON key `house_axis` line 425).
- **Template consumption:** `services/api-python/app/pdf/templates/solar.html.j2:271-298`; `synthesis_themes.py:792`.

Field path is fully deterministic Haskell output. Test target field unchanged from prior Worker trace.

---

## § 2. Stage 2 — 4 regression tests landed

### 2.1 Test file

New file `services/api-python/tests/test_summary_themes.py` (preferred location per TASK spec).

Pattern:
- Parametrized over 4 case_ids.
- Loads `packages/test-fixtures/golden-cases/<case_id>.expected.json` (canonical engine output — `test_golden_cases.py` validates it reproduces live CLI byte-for-byte).
- Asserts `facts["analysis"]["house_axis"]["primary_axis"] == <Marina-expected>` AND `secondary_axis == <Marina-expected>`.

### 2.2 Pinned values per memo § 1.1

| Case | Pinned primary | Pinned secondary | Marina memo § 1.1 | Match |
|---|---|---|---|---|
| 02-maksim-2025-2026 | `{low:2, high:8, strength:4}` | None | ось 2-8 (финансы) — 1st place | ✓ |
| 03-artem-2025-2026 | `{low:6, high:12, strength:6}` | `{low:5, high:11, strength:4}` | 6-12 1st + 5-11 2nd | ✓ |
| 08-natalya-2025-2026 | `{low:6, high:12, strength:4}` | None | ось 6-12 (работа) — 1st place | ✓ |
| 10-danila-2025-2026 | `{low:2, high:8, strength:4}` | None | ось 2-8 (финансы) — 1st place | ✓ |

### 2.3 Cases explicitly NOT pinned (β scope; documented in test file docstring + memo erratum)

- **05-ekaterina** — tie-break divergence: engine 1-7 (numeric low-pole asc) vs Marina 6-12 (editorial significance). Both axes в engine top-density set; disagreement on tie-break direction only.
- **09-anastasiya** — super-solar fallback: engine `primary_axis = None`; Marina labels 1-7 by chart-anchor editorial logic.
- **11-olga** — engine matches Marina (5-11) but no fixture; DB-only.
- **01/04/07** — Marina-primary not extracted в memo § 1.1.

### 2.4 Test results

```
$ pytest tests/test_summary_themes.py -v
tests/test_summary_themes.py::test_engine_primary_axis_matches_marina[02-maksim-2025-2026] PASSED
tests/test_summary_themes.py::test_engine_primary_axis_matches_marina[03-artem-2025-2026] PASSED
tests/test_summary_themes.py::test_engine_primary_axis_matches_marina[08-natalya-2025-2026] PASSED
tests/test_summary_themes.py::test_engine_primary_axis_matches_marina[10-danila-2025-2026] PASSED
============================== 4 passed in 0.13s ===============================
```

Full pytest suite: **372 passed + 2 skipped + 0 failed** (368 baseline + 4 new).

---

## § 3. Stage 3 — Memo § 5.4 erratum landed

File: `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md`.

New subsection appended после existing Phase 9.1 Erratum (line ~990): **«## Erratum (Phase 9.4 empirical validation, 2026-05-18)»**.

Content per user verbatim formulation 2026-05-18:

> Phase 9.4 empirical validation revises Phase 9.0 § 5.4. The previous "deterministic 8/8" verdict was overstated. Strict fixture validation shows Marina match for 4/6 analyzable fixture cases: 02, 03, 08, 10. Case 05 diverges on equal-strength tie-break: engine selects numeric low-pole axis 1-7, Marina selects editorially significant 6-12. Case 09 diverges on super-solar fallback: engine returns no primary axis, Marina uses chart-anchor/editorial 1-7. Olga 11 matches Marina but is DB-only/no fixture and is not pinned in this tests-only task. Revised verdict: partial deterministic with editorial residual.

Plus programme lesson note (per user direction):

> All Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation. This is confirmed by Phase 9.1 directions and Phase 9.4 summary findings.

Plus § «What this changes»:
- Memo § 5.4 «deterministic 8/8» — superseded.
- § 5.2 / § 5.3 — NOT changed by this erratum but require Stage 0 strict empirical validation before any implementation TASK ships.
- Phase 9.4 closure: 4 tests pin 02/03/08/10; cases 05/09/Ольга 11 documented as known divergences here.

Plus cross-references: TASK 9.4 archived closure path; Phase 9.1 Erratum (precedent); Phase 4a memo Erratum (original recurring precedent).

Phase 9.0 memo body unchanged — only new subsection appended at end (per spec «only add new Erratum subsection at end»).

---

## § 4. Stage 4 — STATUS_RU update

File: `project-overlays/astro/STATUS_RU.md`.

Updated «## Сейчас» opening paragraph: «Phase 9.4 — Summary Axis Regression Tests — DELIVERED 2026-05-18 (β scope, tests-only)» replacing prior «STOP + escalation» status. Captured:

- 4 регрессионных теста landed; test file path; pinned cases summary.
- Cases 05/09/Ольга 11 not pinned (memo erratum reference).
- Memo § 5.4 verdict revision (deterministic 8/8 → partial deterministic 4/6).
- Programme lesson landed.
- Pytest 368 → 372 + 2 skipped + 0 failed.
- Cabal Up to date.
- NO product code touched.
- Next per user direction: Phase 9.2 + 9.3 re-spec as validation-first TASKs.
- Prior Worker STOP HANDOFF reference preserved (historical record).

---

## § 5. Stage 5 — Manual smoke verification

Optional per TASK spec («Optional — tests-only nature means this is bonus, не required acceptance»).

**Not executed** — tests sufficient. New tests directly validate the canonical engine output that PDFs render from. PDF smoke would be redundant: same `expected.json` fixture used by `test_golden_cases.py` (which validates live CLI roundtrip) and by `solar.html.j2:271-298` (which renders `house_axis.primary_axis`).

If TL wants smoke later: `python services/api-python/scripts/render_case.py --case-id 10-danila-2025-2026 --output /tmp/smoke.pdf` and visually verify «Итоги консультации» section shows «ось 2-8».

---

## § 6. Acceptance status

| Item | Status | Note |
|---|---|---|
| Exactly 4 tests added для cases 02/03/08/10 | ✓ MET | parametrized into 4 test cases |
| Cases 05/09/Ольга 11 NOT pinned | ✓ MET | divergence documented in memo erratum + test docstring |
| Tests pass at HEAD `aca694b` | ✓ MET | 4/4 passed |
| No product code modified | ✓ MET | `git diff aca694b -- services/api-python/app/` empty |
| Memo § 5.4 erratum landed | ✓ MET | per user verbatim formulation 2026-05-18 |
| Programme lesson note added | ✓ MET | within memo erratum subsection |
| Cabal clean | ✓ MET | Up to date |
| Pytest 372 passed + 2 skipped + 0 failed | ✓ MET | 368 baseline + 4 new |
| `git status --short` clean | ✓ MET (pre-commit) | only intended changes |
| One product commit (test file only) | ✓ MET | Single commit pending |
| Overlay commit (memo + STATUS_RU + HANDOFF) | ✓ MET | Single commit pending |
| Push backup, parity verified | ✓ pending after commits | — |
| Tests-only scope | ✓ MET | Zero product code touched |
| STOP discipline honored | ✓ MET | β scope explicit; no temptation to pin 05/09 |

All acceptance items met.

---

## § 7. Files changed

### Product side (1 commit, test file only)

- **NEW:** `services/api-python/tests/test_summary_themes.py` (109 lines: docstring + 4 parametrized tests + Marina-curated table).

### Overlay side (1 commit)

- **MODIFIED:** `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` — appended «Erratum (Phase 9.4 empirical validation, 2026-05-18)» subsection (verdict revision + programme lesson + what-changes + cross-references).
- **MODIFIED:** `project-overlays/astro/STATUS_RU.md` — opening paragraph updated.
- **NEW:** `project-overlays/astro/HANDOFFS/2026-05-18-worker-to-tl-phase-9-4-summary-axis-regression-tests-DELIVERED.md` — this file.
- **MODIFIED:** `project-overlays/astro/TASKS/2026-05-17-phase-9-4-summary-axis-regression-tests.md` — Status: open → in-progress (TL will bump → review → done on closure).

### Files NOT touched

- All Haskell core code (`core/astrology-hs/`).
- All Python product code (`services/api-python/app/`).
- All schemas (`packages/contracts/`).
- All fixtures (`packages/test-fixtures/`).
- All templates, allowlist, structured overrides.
- All TS frontend code.

---

## § 8. Programme implication

Phase 9.x meta-pattern (third recurrence after Phase 4a + Phase 9.1):

- **Phase 9.0 memo § 5.4 verdict:** «deterministic 8/8».
- **Phase 9.4 empirical validation:** 4 of 6 analyzable cases match Marina at strict primary-equality test (02/03/08/10); cases 05 (tie-break) + 09 (super-solar) diverge.
- **Verdict downgrade:** «deterministic 8/8» → «partial deterministic 4/6 with editorial residual».

Same family pattern как:
- **Phase 4a:** verbal description omitted N±2/N±1 boundary semantics → Phase 8B Path 1 retract.
- **Phase 9.1:** memo § 5.1 «hybrid (deterministic-leaning)» → empirical validation showed no formulation reproduces Marina selection across calibrated + Ольга simultaneously → verdict downgrade to «editorial / curation-required».

**Programme lesson now formalized in memo:** all Phase 9 memo verdicts now require Stage 0 strict empirical validation before implementation.

**Operational implication for next phases:**

- Phase 9.2 (outer cards) — memo § 5.2 verdict «hybrid» (target ≠ angle + per-client significator). Per programme lesson: cannot ship implementation TASK without Stage 0 strict validation that filter reproduces Marina selections for all calibrated + Ольга. Re-spec as validation-first.
- Phase 9.3 (intervals) — memo § 5.3 verdict «hybrid (strong editorial residual)». Per programme lesson: same.

Phase 9.4 itself: closed honestly с partial deterministic deliverable (4 pinned cases) + erratum acknowledging that two cases require editorial layer (or engine modification beyond tests-only scope) для full Marina alignment.

---

## § 9. Backup parity (pending after commits)

To be verified after:
1. Product commit creates 1 commit in `astro` repo.
2. Overlay commit creates 1 commit in `ai-dev-system` repo.
3. `git push backup main` for product.
4. `git push backup master` for overlay (если backup remote configured for overlay).

---

## § 10. STOP triggers — none triggered

- ✗ Engine primary-axis output differs from Marina expected for 4 pinned cases — DID NOT TRIGGER (all 4 match: 02 → 2-8, 03 → 6-12+5-11, 08 → 6-12, 10 → 2-8).
- ✗ Engine field name not found — DID NOT TRIGGER (field path confirmed match с prior Worker trace).
- ✗ Worker tempted to pin 05/09/Ольга — DID NOT TRIGGER (β scope explicit; tempted only to verify, not pin).
- ✗ Worker tempted to «improve» engine — DID NOT TRIGGER (tests-only discipline; engine tie-break + super-solar None are deliberate engine behavior, not bug).

---

## § 11. Submission

- **HANDOFF**: this file.
- **STATUS_RU**: updated.
- **Memo erratum**: landed in `marina-significance-selection-analysis-2026-05-17.md`.
- **TASK file**: Status bumped open → in-progress. TL bumps → review → done on closure.
- **Product commit**: 1 (test file only).
- **Overlay commit**: 1 (memo erratum + STATUS_RU + HANDOFF + TASK status).

End of HANDOFF.
