# HANDOFF: worker → tl — multi-case-calibration

- Status: open
- Date: 2026-05-13 17:31
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-13-multi-case-calibration.md

## Summary

Phase 7 Stage A multi-case calibration completed on cases 05-ekaterina,
07-mariya, 10-danila. Validation produced **«Blockers identified — program NOT
production-ready»** verdict due to one TYPE-B regression discovered in case 07
monthly transit table (label-arithmetic bug in `transit_themes.py:transit_matrix_by_month`
that duplicates Aug/Oct labels and skips Sep/Feb when sr-day-of-month is 01
with late-UT time). Stage B NOT authorized. Two TYPE-A closed-config gaps
(case 05 + case 10 outer-cards allowlist empty) documented but not addressed
— Stage B can land them once the TYPE-B bug is fixed and a fresh Stage A
re-validation passes.

## Done

- **Stage A inventory validation**: confirmed all 3 default Marina-PDF
  mappings via return_jd comparison (Δ < 60s). Validation table in
  calibration report § 1.
- **Stage A per-case render**: 3 PDFs produced via Worker-side throwaway
  ad-hoc script (`/tmp/stage_a_render_case.py` — not committed to product
  repo, used only because canonical `render_natalya.py` hardcodes
  `case_label="08-natalya-..."` and would otherwise produce diagnostically
  invalid PDFs for cases 05/07/10).
- **Stage A per-section diff**: monthly table cell-by-cell, per-house
  enumeration, outer-cards inventory, calendar structure — all 3 cases vs
  Marina reference deck. Findings tabulated in report § 3.
- **Divergence classification (report § 4)**:
  - TYPE-A: 3 items (case 05 outer-cards, case 10 outer-cards, case 05
    Venus Jul 2025 ±1-house boundary).
  - **TYPE-B: 1 item** — case 07 monthly table label-arithmetic bug
    (`transit_themes.py:transit_matrix_by_month` lines 546-578).
  - TYPE-C: 2 items documented (case 10 card 3 has 4 windows not 3; case
    07 no-outer-cards matches Marina editorial choice).
- **Override count + Phase 4b gate**: 2 / 10 across all cases (within
  threshold). Report § 5.
- **Production-readiness verdict** (report § 6): «Blockers identified —
  program NOT production-ready». Stage B not authorized.
- **Calibration report**:
  `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`
  (423 lines, §§ 1-6 + appendix).
- **Build + tests**: `cabal build` clean (`Up to date`); `pytest --tb=no
  -q` 149 passed, 0 xfailed, 0 failed (Натальи baseline preserved, no
  regression from Stage A read-only diagnostic).

## Remaining

Stage B work blocked pending TYPE-B fix. After fix lands:

1. Re-validate case 07 monthly table against Marina (should be 13/13 cells
   matching with consecutive month labels).
2. Stage B closed-config work:
   - Extend `app/pdf/outer_cards.py:OUTER_CARD_ALLOWLIST` for
     `05-ekaterina-2025-2026` (3 triples: Уран кв Луне, Уран секст
     Юпитеру, Нептун триг Юпитеру) + populate `_OUTER_CARD_FACTS` from
     Marina pp. 34-37.
   - Extend allowlist for `10-danila-2025-2026` (3 triples: Уран кв Луне,
     Нептун кв Венере, Нептун кв Юпитеру) + card-facts from Marina pp.
     16-19. Note: case-10 card 3 has 4 windows, not 3 — Phase 4 helper
     `_assert_three_phase_intervals` needs parametrised window count.
   - Create `services/api-python/scripts/render_case.py` to formalise
     per-case canonical render (replaces Stage A throwaway).
   - Per-case acceptance test files (single parameterised file
     `test_multi_case_calibration.py` recommended).
   - Optionally apply structured tolerance override for case 05 Venus Jul
     2025 cell (TYPE-A item 3).
3. User explicit ack on calibration report.
4. Recovery program closes after ack.

## Artifacts

- branch:               astro main @ a1891cc (Phase 6 closed, unchanged
                        by Stage A); ai-dev-system master @ 081cbe2
                        (calibration report added).
- commit(s):            ai-dev-system 081cbe2 (calibration report). No
                        product-repo commits — Stage A is read-only.
- PR:                   none.
- tests:                149 passed / 0 xfailed / 0 failed (Натальи
                        baseline preserved; no Stage A test additions
                        since Stage A is read-only validation).
- Product repo status:  not applicable (Stage A read-only validation; no
                        product code changes). Astro repo `git status
                        --short` shows only the pre-existing untracked
                        `.claude/scheduled_tasks.lock` which TASK § Acceptance
                        explicitly permits ignoring.
- Calibration report:   project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md
- Per-case PDFs:        /tmp/05-ekaterina-phase7.pdf
                        /tmp/07-mariya-phase7.pdf
                        /tmp/10-danila-phase7.pdf
                        (+ matching .provenance.json sidecars)
- Push status:          ai-dev-system → backup OK
                        (dea5f63..081cbe2  master → master)

## Conflicts / risks

- **TYPE-B regression in Phase 1-6 generic logic**. The label-arithmetic
  bug in `transit_themes.py:transit_matrix_by_month` was hidden during
  Natalya calibration because Natalya's solar return is early-morning UT
  on the 7th of August — `sr + N*30.4375` for N=0..12 lands cleanly in
  consecutive calendar months. Case 07 (Мария, sr=01.07.2025 19:11 UT)
  is the first case in the calibration set where this bug manifests:
  iteration index 2 lands on 31.08.2025 (still August by calendar
  rounding), so the label "Август 2025" repeats and the September
  mid-month snapshot is never computed. Result: 6 of 13 rows in case 07
  monthly table have wrong cells vs Marina, and 2 month labels duplicate.
  Fix scope is ~10 lines (replace iteration with calendar-month-advance
  arithmetic) but **touches generic Phase 5 logic** which is
  out-of-scope for Phase 7 closed-config calibration per TASK
  § «Запрещены modifications в Stage B». Therefore: TYPE-B → STOP.
- **Why this was not caught earlier**: Natalya-only Phase 1-6 testing
  (149 passing) didn't exercise the iteration over a late-day-of-month
  starting point. The Phase 7 calibration is exactly the mechanism that
  surfaces this kind of regression — the program design is working as
  intended; it's revealing a real bug.

## Next step

TL action sequence:

1. Review calibration report.
2. Decide whether to open a **separate Tier-C TASK
   `transit-monthly-table-label-arithmetic`** (recommended) to fix the
   bug in isolation, with a regression test specifically for case 07.
3. After that TASK lands and Натальи baseline (149 passed) stays green,
   **reopen Phase 7 Stage A re-validation** on case 07.
4. If clean, proceed to original Stage B plan (allowlist extensions for
   cases 05 and 10, per-case tests, `render_case.py`).
5. Only after Stage B closes AND user provides explicit ack on the
   updated calibration report — the Transit Section Recovery program
   officially completes and PDFs become showable to Marina.

PDF status today: still internal QA artefact. **Do not show Marina.**
