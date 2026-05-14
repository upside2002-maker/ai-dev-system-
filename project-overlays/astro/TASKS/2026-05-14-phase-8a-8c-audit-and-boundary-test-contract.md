# TASK: phase-8a-8c-audit-and-boundary-test-contract

- Status: review
- Ready: yes
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
  - **Interval boundaries:** start_str + end_str per window vs Marina-listed dates (extract Marina dates from etalon PDF). Report any Δ > 2 days (date-only comparison, see C.1 tolerance definition).
  - Golden-rule table values (5 cells per card: transit_natal_house, target_natal_house, transit_ruled_houses, target_ruled_houses, transit_walks_house). Note: facts populated only for 05/08/10 per current allowlist.
  - Psychology + event-level text presence (not verbatim match — Marina paraphrase OK).
- **Monthly transit table:** label sequence + cell values vs Marina. Already covered for 05/07/10 per existing tests; expand to other cases.
- **Per-house section:** house numbers per planet vs Marina.
- **Calendar smoke:** entry count + target_house_set presence.

##### A.2.1 — Marina boundary dates table (single source of truth)

Output a single **human-readable Markdown table** in audit report § A.2.1, columns:

| case | card | W | Marina start | Marina end | our start | our end | Δ start (days) | Δ end (days) | status |
|------|------|---|--------------|------------|-----------|---------|----------------|--------------|--------|

- Marina dates read from etalon PDFs (date-only, no time-of-day).
- Our dates read from `outer_cards_for_case` output (`start_str`/`end_str` parsed to date-only).
- `Δ` = signed integer days (our minus Marina).
- `status` = `OK` (|Δ| ≤ 2 both sides) / `OUT-OF-TOLERANCE start` / `OUT-OF-TOLERANCE end` / `OUT-OF-TOLERANCE both`.

**This table is the canonical SoT.** Phase 8C boundary dates dict in test file references this table (Worker copies values + code comment «// SoT: audit report § A.2.1»). No ad-hoc re-extraction of Marina dates from PDFs in test code.

Output per case in audit report § 3.X (existing structure) + the canonical A.2.1 table aggregating ALL cases.

#### A.3 — Classification

Each finding tagged:
- **TYPE-A** — closed-config gap (allowlist missing, card-facts missing, lexical fix). Resolvable in Phase 8B Stage B-pattern.
- **TYPE-B** — generic logic regression. Requires engine / semantic-code change. (Note: Данила Neptune boundary is **NOT** TYPE-B in the original sense — it's engine sample horizon limit. Worker documents as either «TYPE-B-equivalent: finite-horizon truncation» OR «TYPE-A-extension: presentation-layer marker», per audit reasoning. User directive: **NOT accepted divergence**.)
- **TYPE-C** — Marina-specific editorial; document only (e.g. case 07 no outer cards by Marina choice).
- **TYPE-D** — data quality (fixture incomplete, fixture-vs-reference mismatch). Held separate from code regressions.

Output classification table in audit report § 4.

#### A.4 — Prioritized fix plan

Worker proposes discrete Phase 8B sub-tasks ordered by:
1. Test contract gap (Phase 8C, this TASK — already part of scope).
2. Quick wins (lexical «трине → тригоне» — case 05 card 3 title).
3. **Boundary regression decisions for Данила** — Worker MUST present **both** paths with cost estimates + recommendation. **No code changes proposed/applied in this TASK.** Required content:

   **Path A — expand outer-card loop horizon / sample horizon:**
   - Where: Haskell engine `Domain.TransitCalendar` (annual_transit_table generator) or wherever outer-planet hits sampling window is bounded. Worker traces actual source.
   - Cost estimate: schema impact (likely none — same field types), test impact (Tier A engine regression run for Natalya / case 05/07/10 baselines), risk (slow planet drift may overreach into very distant years and bloat hits list).
   - Outcome: Marina Δ should narrow / disappear for Данила Венере W3 + Юпитеру W4 (and any analogous cases discovered in Phase 8A).

   **Path B — presentation-layer truncation marker:**
   - Where: `services/api-python/app/pdf/outer_cards.py` aggregation or `solar.html.j2` template. Worker proposes exact location.
   - Approach: detect when an interval's `orb_exit_jd` equals engine sample-window boundary; render «(окно truncated, sample horizon)» in PDF instead of pretending cutoff date is the real window end.
   - Cost estimate: presentation-only change (Tier C), no engine touch, no fixture regen.
   - Outcome: Δ still present in raw numbers, but PDF text is honest; no false claim of «28.01.2028» as real end.

   **Worker recommendation:** must pick one with clear reasoning (engine accuracy vs presentation honesty). User/PTL final decision lands in Phase 8B TASK ack.

4. Allowlist expansion (cases 01/02/03/04/09 — count, complexity, Marina pages, estimated card count per case from Phase 8A audit).
5. TYPE-D data-quality follow-ups (`_3.pdf` missing-fields list; Анастасия SR/tz mismatch suspected location). **Listing only; not in Phase 8 scope** — punt to separate data-revision tasks.

Output in audit report § 5 as numbered Phase 8B sub-task proposals.

### Phase 8C — Test contract: outer-card boundary assertions

After Phase 8A audit completes (sections A.1-A.4):

#### C.1 — Helper for boundary parsing (date-only)

Add helper in `test_multi_case_calibration.py` (or shared test util):
- Parse `interval["start_str"]` + `interval["end_str"]` (current format: `«DD.MM.YYYY HH:MM (GMT+3)»`) to `datetime.date` objects (date-only, no time-of-day).
- Compare against Marina-listed dates (also `datetime.date`).
- Default tolerance: **±2 days** per side (start AND end), date-only comparison.
- Rationale: time-of-day comparison adds noise on normal windows (where Δ is hours, not days) without saving truly broken cases (Данила Δ is 38-49 days — orders of magnitude larger than tolerance regardless of date-vs-datetime).

#### C.2 — Boundary assertions per case

For each outer-card window per case (05/08/10 current; no new cases in this TASK), assert:
- `start_str` parsed-date within ±2 days of Marina-listed start.
- `end_str` parsed-date within ±2 days of Marina-listed end.

Marina-listed dates come from a single source-of-truth dict in the test file, **populated by copying values from audit report § A.2.1 table** (Phase 8A canonical SoT). Worker adds code comment at the dict definition: `# SoT: project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md § A.2.1`. No ad-hoc re-extraction of Marina dates from PDFs in test code.

#### C.3 — Structured overrides

No new `tolerance_overrides` introduced. Per user directive 2026-05-14: Данила Neptune boundaries are **NOT** accepted divergence. Phase 4b structured-override pattern stays only for Натальи 2 Neptune cases (N-J W3 +20d end; N-N W1 +200d start) in `test_natalya_transits_acceptance.py` — DO NOT extend.

#### C.4 — Test execution discipline (xfail-strict for Данила)

After 8C changes land, **all boundary tests landed including 2 known-failing Данила windows, but Данила two windows are marked `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon")`.** This is the Phase 2 discipline that worked well: tests document the contract gap explicitly; CI stays green; when Phase 8B fix lands the failing tests become xpass, strict-mode flips to FAILED, forcing Worker to unmark in same Phase 8B TASK.

Specifically:
- All boundary tests for Натальи (08): green (Phase 4b overrides applied via separate `test_natalya_transits_acceptance.py`).
- All boundary tests for Екатерины (05): green.
- All boundary tests for Данилы (10) **except** Нептун кв Венере W3 end + Нептун кв Юпитеру W4 end: green.
- 2 Данила boundary tests (Нептун кв Венере W3 end; Нептун кв Юпитеру W4 end): marked `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon (engine sample window cutoff 2461798.822368622 = 28.01.2028)")`.
- Case 07 (Мария): no outer cards by Marina editorial — no boundary tests.

Expected final pytest report: `(183 baseline) + N new boundary tests passed + 2 xfailed (Данила Венере W3 end; Данила Юпитеру W4 end) + 0 failed`. **CI green.**

**STOP triggers (do not commit + escalate):**
- Any Данила xfail test **xpasses** (i.e. passes when expected to fail) → bug in test or Marina dates — investigate.
- Any non-Данила boundary test fails → new TYPE-A/B finding not anticipated — escalate.
- Worker tempted to use plain `pytest.skip` or non-strict `xfail` — STOP, only strict-xfail acceptable (Phase 2 discipline).

#### C.5 — No fixes in this TASK

Worker explicitly **does not** fix any failing semantic — neither Данила horizon, nor lexical «трине», nor allowlist 01-09. Phase 8B scope. Worker's TASK 8A+8C completion criteria = audit report delivered + test contract code landed + Данила 2 windows xfail-strict-marked + all expected-green green + 0 new tolerance overrides + CI green.

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
- [ ] § A.2.1 — **Marina boundary dates table** (single SoT, columns: case / card / W / Marina start / Marina end / our start / our end / Δ start / Δ end / status).
- [ ] § A.3 — Classification table: each finding TYPE-A/B/C/D with rationale.
- [ ] § A.4 — Prioritized Phase 8B sub-task proposals (numbered). **Item 3 = Данила with BOTH paths (A horizon extension + B truncation marker) + cost estimates + recommendation.** **TYPE-D items (5) = listing + short diagnostic only.**

### Phase 8C

- [ ] `test_multi_case_calibration.py` updated with:
  - Marina-listed boundary dates dict (single SoT, copied from audit report § A.2.1 with code-comment cross-ref).
  - Boundary parsing helper (`datetime.date`, no time-of-day).
  - Per-window start_str + end_str assertions (±2 days per side, date-only).
  - 0 new tolerance overrides (Phase 4b Натальи overrides unchanged).
  - **2 Данила boundary tests marked `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon ...")`**: Нептун кв Венере W3 end; Нептун кв Юпитеру W4 end.
- [ ] `pytest` reports: 2 xfailed (Данила) + N new boundary tests passed + all 183 baseline preserved + 0 failed. **CI GREEN.**
- [ ] 0 product semantic code changes (Worker does NOT fix anything; Phase 8B scope).

### Common

- [ ] `cabal build`: clean.
- [ ] `pytest --tb=no -q`:
  - Acceptance count formula: `(183 baseline) + (N new boundary tests passed) + 2 xfailed (Данила Venus W3 end + Jupiter W4 end) + 0 failed`.
  - CI green (no RED at HEAD).
- [ ] `git status --short` clean for intended product changes; pre-existing `.claude/scheduled_tasks.lock` allowed.
- [ ] Push backup, parity verified.
- [ ] Single Worker session (no parallel sessions); HANDOFF Worker → TL contains: audit-report path; § A.2.1 boundary table summary (numbers per case); Phase 8C test-state summary (N new tests, 2 xfailed); Phase 8B sub-task proposals echoed with recommended path for Данила.

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
- 2 Данила xfail-strict tests **xpass** at HEAD (i.e. pass when expected to fail) → STOP, investigate Marina dates / engine output / xfail marker semantics. **Do NOT just remove xfail to make it green.**
- Any non-Данила boundary test fails → new finding not anticipated; STOP, escalation.
- Worker tempted to use plain `pytest.skip` or non-strict `xfail` → STOP, only `xfail(strict=True, reason=...)` acceptable (Phase 2 discipline).
- Worker tempted to fix any item discovered in 8A — STOP, that's Phase 8B scope (lexical / Данила horizon / allowlist).
- Worker tempted to extend Phase 4b structured-override pattern to Данила (per user directive) — STOP, that's NOT acceptable in 8A/8C; this is **not** accepted divergence.
- TYPE-D blockers (`_3.pdf` / Анастасия) consuming Phase 8A scope → STOP, that's listing-only + short diagnostic per refinement.

**Production-readiness gate:** Phase 8A+8C closure does NOT close program. Phase 8B (fixes) remains. PDF Марине (кроме Натальи отдельным framing — independent track) — НЕ показывать.

**Parallel artifact track — Наталя:**
Fresh PDF + sidecar already produced on `c936dd1`. Independent of Phase 8 progress. **NOT mixed into this Worker TASK** — delivery-to-Marina lives separately from contract repair (per user directive 2026-05-14). TL prepares lightweight framing memo for Marina on separate request, not in this TASK.

**Worker lifecycle:**
- accept-task.sh at start (Status: open → in-progress).
- Phase 8A first (audit), then Phase 8C (test contract). Do NOT skip A.
- HANDOFF Worker → TL at end.
- accept-handoff.sh / submit-task.sh per current overlay scripts (Worker noted prior accept-handoff.sh signature changed; use current toolchain).

**Ready: yes** — flipped 2026-05-14 после user ack + 5 refinements applied:
1. Tolerance ±2 дня **date-only** (без времени суток).
2. Marina dates → **human-readable § A.2.1 table** в audit report как single SoT; C.2 dict copies values с cross-ref comment.
3. C.4 final outcome = **2 Данила tests marked `xfail(strict=True, reason=...)`** (Phase 2 discipline) — CI green; xpass на fix → strict-fail forces unmark в Phase 8B.
4. A.4 § Данила proposals = **обе** опции (Path A horizon extension + Path B truncation marker) с cost estimates + recommendation. Без code changes.
5. TYPE-D items (`_3.pdf`, Анастасия) — listing + short diagnostic only; не съедают Phase 8A scope.

Наталя framing memo — отдельный lightweight artifact, не в этом Worker TASK (per user directive: «не смешивать delivery-to-Marina и contract repair»).
