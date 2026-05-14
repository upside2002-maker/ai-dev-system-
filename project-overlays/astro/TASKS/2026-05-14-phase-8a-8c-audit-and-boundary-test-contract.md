# TASK: phase-8a-8c-audit-and-boundary-test-contract

- Status: open
- Ready: no
- Date: 2026-05-14
- Project: astro
- Layer: overlay (audit report) + services (test contract additions)
- Risk tier: C (audit + tests; no product semantic code; Worker DOES NOT fix anything in this TASK)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

TASK 7b closure 2026-05-13 was premature (Phase 8.0 documented). Two-stage corrective work:

- **Phase 8A** — read-only full-folder audit: inventory all Marina etalon PDFs in `/Users/ilya/Downloads/Gmail (3)/`, match to fixtures in `packages/test-fixtures/golden-cases/`, per-case diff vs current PDF output, classification TYPE-A/B/C/D, prioritized fix plan.
- **Phase 8C** — test contract additions FIRST: extend `test_multi_case_calibration.py` with outer-card interval boundary assertions (start/end ±2 days, structured overrides only where Phase 8A explicitly decided). Tests must catch Данила Neptune Венере W3 + Юпитеру W4 as RED before any fix attempt.

Combined in one TASK because Phase 8C boundary assertions need Phase 8A Marina-listed dates as **single source of truth** (extract once during audit; reuse in tests).

**Phase 8B is a separate TASK** authored after 8A+8C closes — fixes built on top of audit findings.

## Stages

### Phase 8A — Read-only full-folder audit

#### A.1 — Marina etalon inventory

Source dir: `/Users/ilya/Downloads/Gmail (3)/`. Worker lists every PDF found, with:
- Filename + Marina case label (e.g. «Соляр 2025-2026_2.pdf» → case 05 Екатерина).
- Match status: matched-to-fixture / unmatched / data-quality-incomplete.
- For matched: fixture path + SR-date/place/timezone confirmation (Δ < 60s in SR time per prior TASK 7 inventory pattern).
- For unmatched: reason (no fixture exists / fixture exists but mismatched / fixture incomplete).

Output table format:
```
| Marina PDF | Marina case | Fixture | SR confirm | Status |
| ... | ... | ... | ... | matched / unmatched-no-fixture / mismatched / incomplete |
```

#### A.2 — Per-case diff

For each **matched** case (and current 4 calibrated cases: 05/07/08/10), Worker performs:

- **Outer cards diff:**
  - Allowlist match (count + triples).
  - Card title (lexical: «трине» vs «тригоне», etc.).
  - Interval count per card.
  - **Interval boundaries:** start_str + end_str per window vs Marina-listed dates (extract Marina dates from etalon PDF). Report any Δ > 2 days.
  - Golden-rule table values (5 cells per card: transit_natal_house, target_natal_house, transit_ruled_houses, target_ruled_houses, transit_walks_house). Note: facts populated only for 05/08/10 per current allowlist.
  - Psychology + event-level text presence (not verbatim match — Marina paraphrase OK).
- **Monthly transit table:** label sequence + cell values vs Marina. Already covered for 05/07/10 per existing tests; expand to other cases.
- **Per-house section:** house numbers per planet vs Marina.
- **Calendar smoke:** entry count + target_house_set presence.

Output per case in audit report § 3.X.

#### A.3 — Classification

Each finding tagged:
- **TYPE-A** — closed-config gap (allowlist missing, card-facts missing, lexical fix). Resolvable in Phase 8B Stage B-pattern.
- **TYPE-B** — generic logic regression. Requires engine / semantic-code change. (Note: Данила Neptune boundary is **NOT** TYPE-B in the original sense — it's engine sample horizon limit. Worker documents as either «TYPE-B-equivalent: finite-horizon truncation» OR «TYPE-A-extension: presentation-layer marker», per audit reasoning. User directive: **NOT accepted divergence**.)
- **TYPE-C** — Marina-specific editorial; document only (e.g. case 07 no outer cards by Marina choice).
- **TYPE-D** — data quality (fixture incomplete, fixture-vs-reference mismatch). Held separate from code regressions.

Output classification table in audit report § 4.

#### A.4 — Prioritized fix plan

Worker proposes discrete Phase 8B sub-tasks ordered by:
1. Test contract gap (Phase 8C, this TASK).
2. Quick wins (lexical «трине → тригоне»).
3. Boundary regression decisions (Данила: horizon extension vs truncation marker — Worker presents both options with cost estimates; user/PTL decides in 8B).
4. Allowlist expansion (cases 01/02/03/04/09 — count, complexity, Marina pages).
5. TYPE-D data-quality follow-ups (_3.pdf, Анастасия — separate diagnostic tasks).

Output in audit report § 5 as numbered Phase 8B sub-task proposals.

### Phase 8C — Test contract: outer-card boundary assertions

After Phase 8A audit completes (sections A.1-A.4):

#### C.1 — Helper for boundary parsing

Add helper in `test_multi_case_calibration.py` (or shared test util):
- Parse `interval["start_str"]` + `interval["end_str"]` (current format: `«DD.MM.YYYY HH:MM (GMT+3)»`) to comparable date objects.
- Compare against Marina-listed dates (extracted in Phase 8A).
- Default tolerance: **±2 days** end-to-end (not ±2 days per side).

#### C.2 — Boundary assertions per case

For each outer-card window per case (05/08/10 current + any new cases added in Phase 8B), assert:
- `start_str` parsed-date within ±2 days of Marina-listed start.
- `end_str` parsed-date within ±2 days of Marina-listed end.

Marina-listed dates come from a single source-of-truth dict in the test file, populated from Phase 8A audit findings. Worker does NOT extract Marina dates ad-hoc twice.

#### C.3 — Structured overrides

Overrides only where Phase 8A § 4 classification explicitly says «accepted divergence». Per user directive 2026-05-14: Данила Neptune boundaries are **NOT** accepted divergence — no overrides for those. Phase 4b structured-override pattern stays only for Натальи 2 Neptune cases (N-J W3 +20d end; N-N W1 +200d start) — DO NOT extend.

#### C.4 — Test execution discipline

After 8C changes land:
- `pytest --tb=short tests/test_multi_case_calibration.py -k boundary` must report:
  - Натальи (08) all green (Phase 4b overrides applied).
  - Данила (10) Neptune Венере W3 + Юпитеру W4 **RED** (out-of-tolerance per Marina vs our 28.01.2028).
  - All other 05/08/10 boundary windows green (within ±2d).
- If Данила тесты not RED → bug in test or in Marina-listed dates → **STOP, escalation memo**, do not flip RED-expected to xfail-strict (that would be sweeping under rug).

#### C.5 — No fixes in this TASK

Worker explicitly **does not** fix any RED test. Phase 8B scope. Worker's TASK 8A+8C completion criteria = audit report delivered + test contract code landed + Данила confirmed RED + all expected-green green + 0 new tolerance overrides.

## Files

- new:
  - `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — Phase 8A audit report (sections A.1-A.4).

- modify:
  - `services/api-python/tests/test_multi_case_calibration.py` — Phase 8C boundary assertions + Marina-listed dates dict + helpers.
  - `project-overlays/astro/STATUS_RU.md` — narrative update for Phase 8A+8C closure status.
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 4 reclassification per Phase 8A findings (add Phase 8A-derived TYPE-A/B/C/D items 6+ as needed).

- delete: —

## Do not touch

- Haskell core, schema, fixtures, rulesets.
- All product semantic code in `services/api-python/app/pdf/*.py` (including `outer_cards.py`, `transit_themes.py`, `rulership_houses.py`, etc.).
- `services/api-python/scripts/render_case.py` (Phase 7 deliverable).
- `services/api-python/tests/test_natalya_transits_acceptance.py` — Phase 4b Натальи structured overrides; helper signature; xfail/test list.
- TASK 7b file (archive, historical record).
- Calibration report § 1/§ 2/§ 3.1/§ 3.2/§ 3.3 — preserved as historical record; Phase 8A revises only by additive `§ 3.X` (where X = new cases) + § 4 additive items.
- **No fixes in this TASK:**
  - Lexical «трине → тригоне» — Phase 8B scope.
  - Данила Neptune boundary fix — Phase 8B scope.
  - Allowlist expansion (01/02/03/04/09) — Phase 8B scope after 8A inventory.
- `expected.json` golden fixtures — NEVER overwrite.

## Acceptance

### Phase 8A

- [ ] Audit report file `phase-8-audit-report-2026-05-14.md` created.
- [ ] § A.1 — Marina etalon inventory table: all PDFs from `/Users/ilya/Downloads/Gmail (3)/` listed; matched/unmatched/incomplete explicit.
- [ ] § A.2 — Per-case diff for every matched case: outer-card count + titles + interval boundaries + golden-rule + monthly + calendar + per-house smoke.
- [ ] § A.3 — Classification table: each finding TYPE-A/B/C/D with rationale.
- [ ] § A.4 — Prioritized Phase 8B sub-task proposals (numbered).

### Phase 8C

- [ ] `test_multi_case_calibration.py` updated with:
  - Marina-listed boundary dates dict (single SoT, from Phase 8A).
  - Boundary parsing helper.
  - Per-window start_str + end_str assertions (±2 days end-to-end).
  - 0 new tolerance overrides (Phase 4b Натальи overrides unchanged).
- [ ] `pytest` reports Данила Neptune Венере W3 + Юпитеру W4 RED (out-of-tolerance) as expected.
- [ ] All other 05/08/10 boundary assertions GREEN.
- [ ] 0 product semantic code changes (Worker does NOT fix RED tests).

### Common

- [ ] `cabal build`: clean.
- [ ] `pytest --tb=no -q`:
  - Expected RED count = 2 (Данила Neptune Венере W3 end; Данила Neptune Юпитеру W4 end).
  - All other tests green.
  - Acceptance count formula: `(183 baseline) + (N new boundary tests, M of which RED-expected = 2)`.
- [ ] `git status --short` clean for intended product changes; pre-existing `.claude/scheduled_tasks.lock` allowed.
- [ ] Push backup, parity verified.
- [ ] Single Worker session (no parallel sessions); HANDOFF Worker → TL contains audit-report-summary + Phase 8C test-state summary + Phase 8B sub-task proposals echoed.

### Scope discipline

- [ ] Затронуты: `tests/test_multi_case_calibration.py` (Phase 8C additions only — boundary helpers + assertions + Marina dates dict), `project-overlays/.../phase-8-audit-report-2026-05-14.md` (new), `STATUS_RU.md` (update), calibration report § 4 (additive items).
- [ ] Engine, schema, fixtures, Haskell core — 0 lines changed.
- [ ] `outer_cards.py`, `transit_themes.py`, `rulership_houses.py`, `synthesis_themes.py`, `builder.py`, `solar.html.j2`, `provenance.py`, `render_case.py` — 0 lines changed.
- [ ] `test_natalya_transits_acceptance.py` — 0 lines changed (Phase 4b stays as-is).
- [ ] No new override mechanisms; no new accepted-divergence classifications; no closure of any item that should be a fix (per user directive «не оформлять Данилу сразу как accepted divergence»).

## Context

**Mode normal + Tier C** (audit + tests; no product semantic code).

**Baseline:**
- Product main @ `c936dd1` (TASK 7b Stage B closure, premature).
- Overlay @ `2750b7e` (Phase 8.0 reopen + verdict downgrade).
- Pytest baseline: `183 passed, 0 xfailed, 0 failed` (with cabal `astrology-core-cli` built).
- Cabal build: Up to date.

**Architecture SoT:**
- `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` (original recovery program SoT).
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (calibration report; § 6 has Phase 8 verdict).
- `project-overlays/astro/TASKS/archive/2026-05-14-phase-8-0-reopen-audit-trail.md` (Phase 8.0 closure).

**STOP triggers:**
- Phase 8A audit reveals product semantic code regression beyond boundary class → STOP, escalation.
- Phase 8C tests do NOT go RED for Данила as expected → STOP, escalation.
- Worker tempted to fix any item discovered in 8A — STOP, that's Phase 8B scope.
- Worker tempted to extend Phase 4b structured-override pattern to Данила (per user directive) — STOP, that's NOT acceptable in 8A/8C; reclassification decisions belong to user in Phase 8B.

**Production-readiness gate:** Phase 8A+8C closure does NOT close program. Phase 8B (fixes) remains. PDF Марине (кроме Натальи отдельным framing — independent track) — НЕ показывать.

**Parallel artifact track — Наталя:**
Fresh PDF + sidecar already produced on `c936dd1`. Independent of Phase 8 progress. TL prepares framing memo for Marina on request.

**Worker lifecycle:**
- accept-task.sh at start (Status: open → in-progress).
- Phase 8A first (audit), then Phase 8C (test contract). Do NOT skip A.
- HANDOFF Worker → TL at end.
- accept-handoff.sh / submit-task.sh per current overlay scripts (Worker noted prior accept-handoff.sh signature changed; use current toolchain).

**Ready: no** — TL flips after user ack on TASK 8A+8C spec + any refinements.
