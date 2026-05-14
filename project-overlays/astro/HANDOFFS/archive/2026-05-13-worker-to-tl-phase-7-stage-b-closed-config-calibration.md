# HANDOFF: worker → tl — phase-7-stage-b-closed-config-calibration

- Status: closed
- Date: 2026-05-13
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker (Tier C)
- TASK: project-overlays/astro/TASKS/2026-05-13-phase-7-stage-b-closed-config-calibration.md

## STOP escalation — summary

Stage A.2 re-validation revealed case 07 monthly table = **11/13 rows match Marina** (not 13/13 as TASK 7b spec expected). Per TASK STOP trigger «If case 07 < 13/13 → STOP, escalation memo, do not start Stage B», Worker halts before any Stage B production-code changes. The 2 residual mismatches are TYPE-A (Marina-vs-our anchor convention), pre-existing pre/post TASK 7a fix, not regressions. TL decides next step (Path A/B/C/D below).

## Lifecycle

Status flow this session:
- Loaded TASK at Status=open, bumped to Status=in-progress.
- Stage A.2 verification revealed gate violation (see § Findings below).
- Worker halts at Stage A.2 with Stage B blocked; emits this escalation memo.

TASK file Status remains `in-progress` pending TL decision. Worker did NOT bump to `review` — STOP discipline means TL evaluates the escalation first, then decides on next steps.

## Baseline (pre-work)

- Branch: `main`, HEAD = `8a4865e` (TASK 7a label-arithmetic fix landed).
- Pytest baseline verified: **150 passed, 0 xfailed, 0 failed** (63.85s).
- `cabal build` (core/astrology-hs): **Up to date**.
- `git status --short` clean (only pre-existing `.claude/scheduled_tasks.lock` untracked).

## What Worker did before STOP

1. **Stage B.3 — Created `services/api-python/scripts/render_case.py`**
   - Canonical parameterised render with `--case-id` argument.
   - Reuses `app.pdf.builder.write_solar_pdf` + `app.pdf.provenance.collect_provenance`.
   - `case_label` pinned in sidecar `extra` (so `outer_cards_for_case` keys correctly).
   - Worker decision: kept this file because TASK spec explicitly authorized creating it before Stage A.2 («TASK 7b creates `render_case.py` first, OR throwaway script если render_case.py creation deferred»). It is genuinely useful for Stage A.2 (case 07 re-validation) and is independent of the Stage B outer-card work.
   - `render_natalya.py` left unchanged (per Worker discretion in spec § Files; no need to refactor it into a wrapper).
   - Smoke-tested: produces PDF + provenance sidecar for case 07 cleanly.

2. **Stage A.2 — Re-validated case 07 monthly table against Marina**
   - Rendered case 07 PDF via `render_case.py --case-id 07-mariya-2025-2026 --output /tmp/07-mariya-stage-a2.pdf` → PDF + sidecar emitted, mode `fixture-render`, SHA `8a4865e94eb2` (main).
   - Inspected 13 row labels via PyPDF text extract: `[Июль 2025, Август 2025, Сентябрь 2025, Октябрь 2025, Ноябрь 2025, Декабрь 2025, Январь 2026, Февраль 2026, Март 2026, Апрель 2026, Май 2026, Июнь 2026, Июль 2026]` — exactly the 13 consecutive labels TASK 7a regression test pins. **Label sequence: PASS (13/13).**
   - Compared cell values against Marina ref (`/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_4.pdf` p. 6-7) via direct `transit_matrix_by_month` invocation on case-07 expected.json + PyPDF text extract of Marina's PDF.

3. **Stage A.2 — Re-validated cases 05, 10 (no regression check)**
   - Case 05 (Екатерина): monthly cells match calibration report § 3.1 exactly. Single boundary diff (Venus Jul 2025: ours 4, Marina 3) — pre-existing per § 4 TYPE-A item 3.
   - Case 10 (Данила): monthly cells match calibration report § 3.3 exactly. 52/52 cells match. No regression.

## Stage A.2 case 07 findings (the STOP trigger)

Marina case 07 monthly table (extracted from `Соляр 2025-2026_4.pdf` pp. 6-7):

| Marina row | Marina (M/S/J/V) | Our label | Our (M/S/J/V) | Match |
|---|---|---|---|---|
| 01.07.2025 | 12 / 7 / 10 / 9 | Июль 2025 | 12 / 7 / 10 / 9 | YES |
| 01.08.2025 | 1 / 7 / 10 / 10 | Август 2025 | 1 / 7 / 10 / 10 | YES |
| 01.09.2025 | 2 / 7 / 10 / 11 | Сентябрь 2025 | 2 / 7 / 10 / 11 | YES |
| 01.10.2025 | 3 / 7 / 10 / 1 | Октябрь 2025 | 3 / 7 / 10 / 1 | YES |
| 01.11.2025 | 3 / 7 / 10 / 2 | Ноябрь 2025 | 3 / 7 / 10 / 2 | YES |
| 01.12.2025 | 4 / 7 / 10 / 3 | Декабрь 2025 | 4 / 7 / 10 / 3 | YES |
| 01.01.2026 | 4 / 7 / 10 / 4 | Январь 2026 | 4 / 7 / 10 / 4 | YES |
| 01.02.2026 | 5 / 7 / 10 / 6 | Февраль 2026 | 5 / 7 / 10 / 6 | YES |
| 01.03.2026 | 6 / 7 / 10 / 7 | Март 2026 | 6 / 7 / 10 / 7 | YES |
| 01.04.2026 | 7 / 7 / 10 / 9 | Апрель 2026 | 7 / 7 / 10 / 9 | YES |
| 01.05.2026 | 8 / 7 / 10 / 10 | Май 2026 | 8 / 7 / 10 / 10 | YES |
| 01.06.2026 | 8 / 7 / 10 / 10 | Июнь 2026 | **9** / 7 / 10 / **11** | **NO** (Mars 9 vs 8; Venus 11 vs 10) |
| 01.07.2026 | 9 / 7 / 11 / 11 | Июль 2026 | 9 / **8** / 11 / **12** | **NO** (Saturn 8 vs 7; Venus 12 vs 11) |

**Result: 11/13 rows match. 2 rows mismatch.**

### Diagnosis of the 2 residual mismatches — pre-existing boundary anchor diffs, NOT TASK 7a regressions

The 2 mismatching rows are **identical** to the same rows in the pre-fix Stage A calibration report § 3.2:
- Pre-fix row 12 ("Июнь 2026" pre-fix): 9 / 7 / 10 / 11 → SAME as post-fix.
- Pre-fix row 13 ("Июль 2026" pre-fix): 9 / 8 / 11 / 12 → SAME as post-fix.

TASK 7a's commit `8a4865e` fix targeted **label arithmetic only**: it replaced `sr + i * 30.4375` fractional iteration with `(year, month + i)` calendar-month advance. The mid-month-15 sampling anchor itself is unchanged. The pre-fix label-drift rows (3, 5, 6, 7, 8) had wrong sample dates AND wrong labels; TASK 7a fixed both for those rows. Rows 12, 13 were never label-drift rows — they always had the correct mid-month-15 sample; the diff comes from a different cause.

Root cause of the 2 residual mismatches: **Marina anchors at day-of-month = solar-return-day (01); our convention anchors at calendar mid-month (15)**. For fast / medium movers near a house-cusp boundary in the relevant 15-day gap, the two anchors yield different house assignments.

Concrete cusp crossings (engine output, case-07 expected.json):
- **Mars June 2026**: house 8 → 9 transition on **2026-06-05**. Marina samples 01.06.2026 (Mars still h=8); ours samples mid-15.06.2026 (Mars now h=9).
- **Venus June 2026**: house 10 → 11 transition on **2026-06-11**. Marina samples 01.06.2026 (h=10); ours samples 15.06.2026 (h=11).
- **Saturn July 2026**: house 7 → 8 transition on **2026-07-08**. Marina samples 01.07.2026 (h=7); ours samples 15.07.2026 (h=8).
- **Venus July 2026**: house 11 → 12 transition on **2026-07-08**. Marina samples 01.07.2026 (h=11); ours samples 15.07.2026 (h=12).

These are **same-family as case 05 Venus Jul 2025** (TYPE-A note in calibration report § 4 item 3): boundary days where Marina's 01-anchor and our 15-anchor straddle a cusp transition. Not a regression. Not a logic bug. Not TYPE-B.

### Classification proposal (for TL decision)

The 2 residual mismatches are **TYPE-A** per the same taxonomy used for case 05 Venus Jul 2025:
- Pre-existing (same numbers pre/post TASK 7a fix).
- Not a regression.
- Caused by Marina-vs-our anchor-day convention difference for fast movers near cusp boundaries.
- Not fixable by closed-config (no override mechanism for monthly cells; B.5 explicitly forbids new override mechanisms).
- **Solution path:** document as TYPE-A note in calibration report § 4 (same as case 05 Venus Jul 2025), continue Stage B.

## STOP rationale

Per TASK spec § Stages > Stage A.2:
> If case 07 < 13/13 после fix → STOP, escalation memo, отдельный TASK.

Worker reads this literally: 11/13 < 13/13 → STOP. The 2 residual mismatches are TYPE-A (not TYPE-B / not regressions), but the gate condition is strict and Worker has no authorization to reclassify on the fly.

## What Worker did NOT do (Stage B blocked by STOP)

- B.1 — `OUTER_CARD_ALLOWLIST["05-ekaterina-2025-2026"]` extension: **not started**.
- B.2 — `OUTER_CARD_ALLOWLIST["10-danila-2025-2026"]` extension: **not started**.
- B.4 — `test_multi_case_calibration.py`: **not created**.
- B.5 — Case 05 Venus monthly boundary note: **not added** to calibration report (deferred to Stage B.6 update batch).
- B.6 — Calibration report update: **not started** (Stage A.2 results documented in this HANDOFF instead).
- Test-helper generalization (`_assert_three_phase_intervals` parametrize `expected_window_count`): **not started**.
- Doc/comment generalization in `outer_cards.py` / `solar.html.j2` («three intervals» → «3+ intervals»): **not started**.

## Files touched by Worker

- new: `services/api-python/scripts/render_case.py` (Stage B.3; kept because spec authorized it as a Stage A.2 prerequisite — see § What Worker did item 1).

That is the **only** product file Worker touched this session. The calibration report (overlay) was NOT updated — Stage A.2 results live in this HANDOFF for TL review before any overlay edit.

## Override count + Phase 4b gate clause status

Unchanged from Stage A baseline:
- 08-natalya-2025-2026: 2 overrides (Phase 4b Neptune tolerance: N-J W3 end ±20d, N-N W1 start ±200d).
- 05/07/10: 0 overrides.
- **Total: 2.** Gate: 2 ≤ 5 per case, 2 ≤ 10 total — within threshold.

## Production-readiness verdict (current state)

**Blockers identified — program NOT production-ready.**

Same verdict as Stage A original (calibration report § 6 unchanged in spirit, though the specific blocker family has shifted). Stage A.2 reveals: TASK 7a fix achieved its label-arithmetic objective, but case 07 monthly table still has 2 pre-existing TYPE-A boundary diffs (rows 12, 13) that the spec author did not anticipate. Recovery program remains open.

PDFs for cases 05/07/10 are diagnostic artifacts only — **not for client (Marina) showing**.

## Decision needed from TL

Worker proposes one of these paths (TL chooses):

### Path A — Reclassify rows 12, 13 as TYPE-A; authorize Stage B continuation

1. TL ack: rows 12, 13 case 07 are same-family TYPE-A as case 05 Venus Jul 2025. Pre-existing, not regressions, not fixable by closed-config.
2. Calibration report § 4 gains TYPE-A items 4-5 (case 07 Jun 2026 Mars/Venus boundary; case 07 Jul 2026 Saturn/Venus boundary).
3. TASK 7b spec gate softened: «case 07 ≥ 11/13 with 2 documented TYPE-A boundary-diff rows» replaces the literal «13/13».
4. Worker resumes Stage B from where it STOPped (B.1 → B.2 → B.4 → doc/comment generalization → test helper generalization → B.5 note → B.6 report update).

This path treats the 11/13 result as the legitimate post-TASK-7a outcome and proceeds to ship outer cards for case 05/10. Pragmatic; matches how case 05 Venus Jul 2025 was handled. Same production-readiness path forward as originally planned.

### Path B — Open a separate Tier-C TASK to converge anchor convention

1. Open TASK `transit-monthly-table-anchor-day-convergence` (or similar):
   - Goal: change our convention from mid-15 to day-of-solar-return (or some other anchor that converges to Marina on cases 05/07).
   - Scope: small change to `transit_matrix_by_month` (mid_dt derivation).
   - Risk: this is the same Phase 5 / generic-logic code the calibration discipline says we should NOT touch in Stage B; this would be a separate TASK with its own regression / golden-case scope.
   - Cost: a full re-validation against case 08 Натальи to ensure no regression on the existing 150-baseline.
   - Benefit: case 07 reaches 13/13, case 05 Venus Jul 2025 likely reaches 52/52 too (same root cause), case 10 stays 52/52 (no boundary diff there).
2. After TASK lands, re-run Stage A.2 and confirm 13/13 / 52/52 / 52/52.
3. Then proceed to Stage B per original plan.

This path is more invasive but produces a cleaner final result. It also costs a calendar-day or two for the additional TASK + verification.

### Path C — STOP transit recovery program at «Blockers identified»

1. TL declares the program complete-with-blocker: TASK 7a achieved what it set out to do (label arithmetic); 2 residual TYPE-A boundary diffs are acknowledged but accepted as inherent to the anchor convention.
2. Outer cards for case 05/10 — **deferred to a future programme**.
3. PDF Натальи: production-ready (Phase 1-6 + 4b + 7a complete).
4. PDFs case 05/07/10: NOT shown to Marina yet (outer cards missing for 05/10 means «client-incomplete» per § 7 Запрет 7).

This is the most conservative option but means Marina sees only Наталья — not the multi-case sweep originally envisioned.

### Path D — Reread spec, agree with Worker's literal STOP, open follow-up TASK 7c

If TL agrees that «13/13» was an inadvertent over-specification in TASK 7b and the real intent was «label arithmetic correct + boundary diffs reclassified TYPE-A», open a minimal TASK 7c that:
- Updates the spec language to allow TYPE-A boundary diffs in case 07 rows 12, 13.
- Authorizes Worker to continue Stage B closed-config calibration.
- Stage A.2 results are already verified by this HANDOFF — no re-render needed in TASK 7c.

This is functionally equivalent to Path A but routes through a new TASK rather than an in-memo amendment.

**Worker recommendation:** Path A or Path D. Both achieve the same production state. Path D is more procedurally clean (separate TASK to update the gate); Path A is faster.

## Artifacts produced

- `/tmp/07-mariya-stage-a2.pdf` + `.provenance.json` — case 07 post-fix PDF (Stage A.2 evidence). Mode `fixture-render`, SHA `8a4865e94eb2`, branch `main`.
- `services/api-python/scripts/render_case.py` — new, committed by Worker after STOP? **NO**: Worker has not committed anything. Status: untracked. TL decides whether to:
  - keep as part of Path A/D resumption (Worker continues, commits after Stage B closure), or
  - revert (`git rm scripts/render_case.py`) under Path C STOP-program scenario.

## Verification command for TL (reproduce findings)

```bash
cd /Users/ilya/Projects/astro/services/api-python
.venv/bin/python -c "
import json
from app.pdf.transit_themes import transit_matrix_by_month
facts = json.loads(open('../../packages/test-fixtures/golden-cases/07-mariya-2025-2026.expected.json').read())
sr_jd = facts['solar_chart']['return_jd']
rows = transit_matrix_by_month(facts['annual_transit_table'], sr_jd)
for r in rows:
    print(r['label'], 'M=' + str(r.get('Mars','?')), 'S=' + str(r.get('Saturn','?')),
          'J=' + str(r.get('Jupiter','?')), 'V=' + str(r.get('Venus','?')))
"
```

Marina reference rows from `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_4.pdf` p. 6-7 listed in § Stage A.2 findings table above.

## Pytest / build state at STOP

- `cabal build`: Up to date (unchanged).
- `pytest --tb=no -q`: 150 passed, 0 xfailed, 0 failed (baseline preserved; no Worker changes to product code besides the new `render_case.py` which has no test wiring yet).
- `git status --short`: 1 new file (`services/api-python/scripts/render_case.py`) + pre-existing `.claude/scheduled_tasks.lock` untracked. No modifications to tracked files.

## Process note

Worker did NOT bump TASK Status to `review`. Per accept-task lifecycle, only review-stage TASKs can transition to done; Worker leaves Status at `in-progress` so TL can either:
- override Stage A.2 gate, raise Status to `review`, then accept-task → done; or
- decline acceptance, declare new TASK 7c per Path D, archive this TASK with a closing note.
