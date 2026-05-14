# TASK: phase-7c-gate-amendment-typea-monthly-boundary

- Status: done
- Ready: yes
- Date: 2026-05-13
- Project: astro
- Layer: overlay (documentation-only)
- Risk tier: C (overlay-only, no product code, no tests, no fixtures)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: (none — TL inline; Tier C overlay-only)
- Mode: normal
- Critical approved by: (нет)

## Problem

TASK 7b Stage A.2 STOP gate (overlay commit `f7f3d8e`): spec required case 07 monthly table = 13/13 exact. Worker validated post-TASK-7a state:
- 13/13 labels correct (`Июль 2025` → `Июль 2026`, no duplicates, no skips).
- 11/13 cell rows match Marina; 2 residual mismatches at rows 12 (`Июнь 2026`) и 13 (`Июль 2026`).

Diagnosis (Worker + TL-verified independent reproduction):
- 2 mismatched rows = deterministic boundary anchor convention difference, **not Phase 7a regression** (identical cell values pre/post TASK 7a — fix targeted label arithmetic, not anchor day).
- Marina anchors monthly snapshot at **1-е соляр-месяца** (day-of-solar-return); our `transit_matrix_by_month` anchors at **mid-15** (`datetime(y, m, 15, UTC)` per Phase 6 / TASK 7a code).
- Cusp transitions fall in the 1st-to-15th gap: Mars 2026-06-05 (h8→9), Venus 2026-06-11 (h10→11), Saturn 2026-07-08 (h7→8), Venus 2026-07-08 (h11→12).

**Same family as case 05 Venus Jul 2025 boundary** (calibration report § 4 TYPE-A item 3). TASK 7b literal gate would block Stage B continuation despite the divergences being acceptable TYPE-A class.

TASK 7c amends TASK 7b gate language to allow TYPE-A boundary rows while preserving strict TYPE-B regression detection. **No product-code change.**

## Fixations (per user direction 2026-05-13)

### 1. Case 07 labels — PASS (TASK 7a fully achieved)

Post-TASK-7a, case 07 monthly table emits **13 unique consecutive labels** `[Июль 2025, Август 2025, Сентябрь 2025, Октябрь 2025, Ноябрь 2025, Декабрь 2025, Январь 2026, Февраль 2026, Март 2026, Апрель 2026, Май 2026, Июнь 2026, Июль 2026]`. No duplicates, no skips. Pinned by `services/api-python/tests/test_mariya_transit_matrix.py` regression test (full equality).

### 2. Case 07 monthly cells — 11/13 exact, 2 TYPE-A divergences

11/13 row cells match Marina exactly. 2 documented TYPE-A boundary divergences:
- **Row 12 «Июнь 2026»:** Mars/Venus cusp boundary between 1st and 15th of June 2026. Mars house 8→9 transition 2026-06-05; Venus house 10→11 transition 2026-06-11. Marina samples 01.06 (Mars h=8, Venus h=10); our mid-15 sample (Mars h=9, Venus h=11).
- **Row 13 «Июль 2026»:** Saturn/Venus cusp boundary between 1st and 15th of July 2026. Saturn house 7→8 transition 2026-07-08; Venus house 11→12 transition 2026-07-08. Marina samples 01.07 (Saturn h=7, Venus h=11); our mid-15 sample (Saturn h=8, Venus h=12).

### 3. Causa — anchor convention, не regression, не label arithmetic

Deterministic anchor convention difference:
- Marina convention: monthly snapshot anchored at **1-е соляр-месяца** (day-of-solar-return-day-of-month).
- Our convention: monthly snapshot anchored at **mid-15** of each calendar month (`datetime(y, m, 15, UTC)`, Phase 6 / TASK 7a `transit_matrix_by_month`).

When a planet crosses a house cusp between the 1st and 15th of a calendar month, the two conventions yield different house assignments.

**This is not a Phase 7a regression** — rows 12-13 emit identical cell values pre/post TASK 7a fix (TASK 7a fixed label arithmetic, anchor day was unchanged at mid-15 before and after). **Not a label arithmetic bug** (TASK 7a regression test verifies 13 unique consecutive labels). **Not engine logic bug** (engine emits correct cusp transition dates; row sampling is presentation-layer convention).

Same family as **case 05 Venus Jul 2025 cell boundary** (calibration report § 4 TYPE-A item 3 — Marina anchor 11.07.2025 / our mid-15 straddles h3/h4 cusp for Venus).

### 4. Stage B gate amendment

TASK 7b Stage A.2 gate is amended. Stage B is authorized **iff** all four conditions hold:

- **(a) No duplicate or missing month labels.** Each row has a unique consecutive label per `[sr-month, sr-month + 1, ..., sr-month + 12]`.
- **(b) No TYPE-B regressions in monthly tables.** Cell values for non-boundary rows match Marina exactly. Cell-value mismatches outside TYPE-A boundary rows trigger STOP.
- **(c) Any monthly cell mismatch must be classifiable as TYPE-A boundary divergence** (cusp crossing within the 1st-to-15th gap of the calendar month), explicitly listed in calibration report § 4 with: row label + planet + house transition + transition date.
- **(d) Calibration report verdict keeps the program state honest** — TYPE-A items enumerated, no rug-sweep, no implicit re-classification. Boundary rows remain visible to readers of the report.

If any of (a)-(d) fails → STOP, escalate, do not proceed to Stage B.

### 5. No product-code change in 7c

TASK 7c modifies overlay documentation only:
- `project-overlays/astro/TASKS/2026-05-13-phase-7-stage-b-closed-config-calibration.md` — Stage A.2 acceptance section updated to amended gate (a)-(d).
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 3.2 post-TASK-7a snapshot; § 4 TYPE-A items 4-5 (case 07 rows 12-13); § 6 reopening rationale.
- `project-overlays/astro/STATUS_RU.md` — narrative update.

**No code, no tests, no fixtures, no Haskell, no schema.** After TASK 7c closes, TASK 7b Worker resumes per amended gate on Stage B (B.1, B.2, B.4, B.5, B.6).

## Files

- new:
  - `project-overlays/astro/TASKS/2026-05-13-phase-7c-gate-amendment-typea-monthly-boundary.md` (this file).

- modify:
  - `project-overlays/astro/TASKS/2026-05-13-phase-7-stage-b-closed-config-calibration.md` — Stage A.2 acceptance section.
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 3.2, § 4, § 6.
  - `project-overlays/astro/STATUS_RU.md` — narrative.

- delete: —

## Do not touch

- Haskell core, schema, fixtures, rulesets.
- All product code (`services/api-python/app/pdf/*`, `services/api-python/tests/*`, `services/api-python/scripts/*`).
- TASK 7b Stage B sections (B.1, B.2, B.3, B.4, B.5, B.6) — gate amendment touches Stage A.2 acceptance only; Stage B scope unchanged.
- TASK 7a regression test `test_mariya_transit_matrix.py`.
- Worker's untracked `services/api-python/scripts/render_case.py` — remains untracked through TASK 7c (it returns under TASK 7b § B.3 ownership when Worker resumes).

## Acceptance

- [ ] TASK 7b spec Stage A.2 acceptance section updated to amended gate (a)-(d).
- [ ] Calibration report § 3.2 case 07 monthly table snapshot reflects post-TASK-7a state (13/13 labels, 11/13 cells, 2 boundary rows).
- [ ] Calibration report § 4 TYPE-A list contains items 4-5 with row label + planet + house transition + transition date for case 07 rows 12-13; cross-reference to item 3 (case 05 Venus Jul 2025) explicit.
- [ ] Calibration report § 6 «Required follow-up before reopening Phase 7» updated — TYPE-B label-arithmetic resolved by TASK 7a; remaining work = Stage B closed-config per amended gate.
- [ ] STATUS_RU narrative updated.
- [ ] One overlay commit; push backup; parity verified.
- [ ] User explicit ack on TASK 7c closure → unblocks TASK 7b Worker resume.
- [ ] Pytest baseline preserved (150/0/0) — no test changes in 7c.
- [ ] Product `git status --short` unchanged (still only `render_case.py` + `.claude/scheduled_tasks.lock` untracked).

## Context

**Mode normal + Tier C overlay-only.** No Worker subagent (TL inline; documentation-only scope). No Reviewer subagent (no code change). Risk tier C is conservative — could arguably be tier D (pure documentation), but kept at C for procedural consistency with other Phase 7 TASKs.

**Baseline:**
- Product main @ `8a4865e` (TASK 7a).
- Overlay @ `f7f3d8e` (TASK 7b STOP escalation).
- Pytest 150/0/0 preserved; cabal build clean.

**Production-readiness gate:** TASK 7c closure does **not** close the recovery program. Sequence:
1. TASK 7c closes (this TASK) → TASK 7b gate amended.
2. TASK 7b Worker resumes Stage B (B.1, B.2, B.4, B.5, B.6) per amended gate.
3. TASK 7b emits final calibration report verdict.
4. User explicit ack on final report.
5. Recovery program closes; PDF can be shown to Marina.

**Why Path B (anchor convention convergence) was not chosen:** changing anchor day from mid-15 to 1-е соляр-месяца is a generic-logic semantic policy change requiring full Phase 1-7 re-validation across Натальи (150 baseline) + cases 05/07/10. Strategically may be the right move, but scope-wise too wide for final recovery push. Deferred to future programme if Marina prefers 1-е anchor in practice.

**Why Path C (STOP program globally) was not chosen:** abandons the multi-case generalization goal of the recovery program. Outer cards 05/10 would defer indefinitely.

**Why Path A (in-memo amendment) was not chosen:** procedurally less clean than Path D (separate TASK file with explicit ack trail). Path D preserves audit visibility — a year from now it is clear that the gate softening was a deliberate, ack'd decision with documented rationale.

**Ready: yes** — user provided full spec content (5 fixations) inline; TL captures verbatim in this TASK file.

## Closure (2026-05-13)

- **Inline application landed:** overlay commit `6b768ae` (one commit, 4 files: TASK 7c new + TASK 7b spec + calibration report + STATUS_RU).
- **All Acceptance items checked:**
  - TASK 7b spec Stage A.2 acceptance section updated to amended gate (a)-(d). ✓
  - Calibration report § 3.2 case 07 monthly table snapshot reflects post-TASK-7a state. ✓
  - Calibration report § 4 TYPE-A items 4-5 added with row + planet + transition + date; cross-ref to item 3 explicit. ✓
  - Calibration report § 6 follow-up updated (TASK 7a [DONE], TASK 7c [DONE], TASK 7b Stage B [NEXT]). ✓
  - STATUS_RU narrative updated. ✓
  - One overlay commit; push backup; parity ✓.
  - Pytest baseline preserved (150/0/0).
  - Product `git status --short` unchanged (only `.claude/scheduled_tasks.lock` + Worker'овский `services/api-python/scripts/render_case.py` untracked).
- **User ack on closure: received 2026-05-13.**
- **Status: done.** Archive to `project-overlays/astro/TASKS/archive/`.

After closure → resume TASK 7b Worker on Stage B (B.1, B.2, B.4, B.5, B.6 + doc/comment generalization + test helper generalization) per amended gate (a)-(d).
