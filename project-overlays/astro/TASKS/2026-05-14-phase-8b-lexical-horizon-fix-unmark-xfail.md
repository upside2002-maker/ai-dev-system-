# TASK: phase-8b-lexical-horizon-fix-unmark-xfail

- Status: open
- Ready: yes
- Date: 2026-05-14
- Project: astro
- Layer: services + core (Haskell engine + Python presentation + tests)
- Risk tier: B (Haskell engine `Domain.TransitCalendar` horizon parameter touch; escalation to Tier A if schema cascade triggered)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 8A audit (audit report § A.4) identified two Phase 8B fixes:

1. **Lexical:** case 05 card 3 title shows «тр Нептун в **трине** с нат Юпитером»; Marina (`Соляр 2025-2026_2.pdf` p. 36) shows «в **тригоне**». One-word fix in `outer_cards.py` aspect-locative dict.

2. **Данила finite-horizon truncation:** case 10 outer-card windows Нептун кв Венере W3 + Нептун кв Юпитеру W4 both terminate at engine `orb_exit_jd = 2461798.822368622 = 28.01.2028 10:44 GMT+3` — engine sample window cutoff. Marina ends:
   - W3 Венере: `07.03.2028` (Δ -39d).
   - W4 Юпитеру: `18.03.2028` (Δ -50d).
   Both currently marked `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon ...")` per Phase 8C contract.

Per user directive 2026-05-14 + audit § A.4 § 3 Worker recommendation: **Path A primary** (engine sample horizon extension); **Path B optional defensive fence** (not first fix).

## Stages

### Stage B1 — Lexical fix (Tier C, ~1 line)

`services/api-python/app/pdf/outer_cards.py` — aspect-locative dict (Russian instrumental case for aspect names). Search for «трине» (Trine→локатив). Replace with «тригоне».

Likely location: aspect-name dict mapping `("Trine", "instr")` or similar. Worker identifies exact location, applies one-word fix.

**Acceptance:** rendered case 05 card 3 title contains «в тригоне с нат Юпитером»; case 10 card titles unchanged (cases 10 has no Trine aspects in allowlist); case 08 Натальи titles unchanged (no Trine).

### Stage B2 — Данила horizon fix (Tier B engine; possibly Tier A if schema cascade)

#### B2.1 — Trace current horizon

Worker locates current sample-window horizon parameter в Haskell `Domain.TransitCalendar` (or wherever outer-planet hits sampling window is bounded). Reports:
- Current horizon value (e.g. «540 days post-solar-return» per recovery program SoT, or different value).
- Where horizon enters the calculation (function signature, module constant, CLI flag default).
- Whether horizon affects only outer-planet hits, or all `annual_transit_table` entries.

#### B2.2 — Determine target horizon (systemic, not Данила-specific)

Worker MUST first locate the **current horizon formula** in the engine code (per B2.1) — likely a constant like `outer_card_lookahead_days` or `sample_window_post_solar_return_days`, or a hardcoded numeric. Report explicitly.

Target: introduce or extend a **named systemic parameter**, NOT pin a number tuned to Данила:

- **Recommended rule:** `horizon_end = solar_return + outer_card_lookahead_days` (named constant, no magic number).
- **Default proposal:** `outer_card_lookahead_days = 365.25 * 3` (3 solar years, ~1095.75 days). Rationale:
  - Covers slow Neptune/Pluto loops with multiple Direct/Retrograde passes.
  - Future-proofs against analogous regressions on cases not yet calibrated (Phase 8A § A.2.1 found Данила; nothing prevents another future case hitting same horizon limit).
  - Marina's typical outer-card windows fit within 3 years post-SR per Phase 8A observations.
- **Bloat impact analysis BEFORE committing default** — Worker runs B2.5.b presentation-calendar bloat check against the proposed `outer_card_lookahead_days` value FIRST.
- If `365.25 * 3` overshoots the threshold for any case → Worker proposes alternative (e.g. `365.25 * 2.5` или `365.25 * 2`) with row-count reasoning в HANDOFF.
- This is a **systemic policy for future slow loops**, not a Данила-specific tuning fence.

**Anti-pattern (STOP trigger):** if Worker is tempted to set `outer_card_lookahead_days = max(Marina W3 end Данила, Marina W4 end Данила) + 60d` — that's tuning to Данила, not systemic. STOP, reread B2.2.

#### B2.3 — Schema-cascade detection

Worker verifies whether horizon extension triggers `packages/contracts/*.schema.json` cascade:
- If horizon is implementation-only (runtime parameter, no new fields/types in JSON output) → no cascade; Tier B sufficient.
- If new schema fields needed (e.g. `truncated: bool` flag) → **STOP**, escalate to Tier A + schema cascade discipline (bright-line #8 atomic commit: schema + Haskell roundtrip + Python contract + TS types + fixtures regen).

#### B2.4 — Apply horizon extension

Worker makes the minimal Haskell change to extend sample window. NO other engine logic touched.

#### B2.5 — Regression guards (CRITICAL)

Worker MUST verify all the following pass post-fix:

**a. Phase 4b Натальи accepted-divergence values stay accepted:**
- 08 N-J W3 end Δ stays -17d (Marina `16.02.2028` vs ours `30.01.2028`) — Phase 4b structured override of ±20d.
- 08 N-N W1 start Δ stays -178d (Marina `27.09.2024` vs ours `02.04.2024`) — Phase 4b structured override of ±200d.
- These are Marina-editorial divergences — extending horizon must NOT shift our values toward Marina's (that would change Marina-editorial gap into engine fix).
- Verified by: rerun audit § A.2.1 boundary extraction; check 08 N-J W3 end and 08 N-N W1 start dates unchanged.

**b. Presentation calendar does NOT bloat (post-clipping count, not raw):**
- Threshold applies to **rendered PDF calendar rows** — i.e. `transit_aspects_by_month` output AFTER Phase 6 two-window-pair clipping (visible to Marina).
- Raw `annual_transit_table` row count в expected.json **may grow** — that's the point of horizon extension. Not a violation per se (but see fixture-regen safeguard below).
- Presentation calendar post-clipping row count для каждого case (Натальи / 05 / 07 / 08 / 10) ≤ 1.5× pre-fix.
- Worker reports actual ratios в HANDOFF table — **both raw (for context) and presentation-clipped (for threshold check)**.
- If presentation ratio > 1.5× for any case → STOP, escalation memo, tighter `outer_card_lookahead_days` proposal in B2.2.

**c. All non-Данила outer card boundaries preserved:**
- Rerun audit § A.2.1 extraction; verify all 56 boundary entries except 2 Данила targets retain the same Δ start / Δ end values.
- 4 OUT-of-tolerance entries pre-fix: 2 Phase 4b (08 N-J W3 end, 08 N-N W1 start) stay; 2 Данила (10 N-V W3 end, 10 N-J W4 end) move toward OK.

**d. Monthly transit tables preserved:**
- Cases 05 (51/52 + 1 TYPE-A Venus Jul 2025 boundary) — preserved.
- Cases 07 (11/13 + 2 TYPE-A Jun/Jul 2026 boundary rows) — preserved.
- Cases 08, 10 — preserved.

**e. Pytest baseline preserved:**
- `(219 baseline) - 2 unmarked + 2 newly-passing` = 219 still passes; 0 xfailed; 0 failed.
- Or expressed differently: 219 collected, 219 passed, 0 xfailed, 0 failed.

### Stage B3 — Unmark Данила xfail (Tier C test housekeeping)

After Stage B2 lands and Stage B2.5 regression guards pass:

`services/api-python/tests/test_multi_case_calibration.py` — remove `@pytest.mark.xfail(strict=True, reason="Phase 8B — Данила finite scan horizon ...")` from:
- `10-danila-2025-2026 :: Neptune Square Venus :: W3 :: end`
- `10-danila-2025-2026 :: Neptune Square Jupiter :: W4 :: end`

Remove associated `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` data structure (or similar — Worker checks what's there).

After unmark, pytest must report:
- `(219 passed + 2 xfailed)` → `(221 passed + 0 xfailed)` (if 2 xfailed counted in collection: tally adjusts by formula).
- Or: `219 passed, 0 xfailed, 0 failed` if Worker'оvская numerology preserved (depends on collection style).

**STOP triggers:**
- If Данила boundary tests still fail post-unmark → horizon extension didn't reach Marina dates → revert + escalation (need wider margin or Path B fallback).
- If `xpass(strict=True)` fires automatically → expected; Worker must explicitly unmark.

### Stage B4 — Optional Path B defensive fence (deferred)

**NOT in this TASK by default.** User directive: Path B as «optional guardrail, not first fix».

Future TASK 8B-2 (or extension of this TASK if scope permits): add presentation-layer marker for windows whose `orb_exit_jd` reaches the new extended horizon. Detect cases that still exceed extended horizon → render «(окно truncated)» marker. This catches edge cases where Path A's new horizon is insufficient.

If Worker has time/scope, may propose this as optional add-on в HANDOFF for user to ack separately. Don't apply unilaterally.

## Files

- modify:
  - `core/astrology-hs/src/Domain/TransitCalendar.hs` (or wherever horizon parameter lives) — extend sample window.
  - `services/api-python/app/pdf/outer_cards.py` — lexical «трине → тригоне» в aspect-locative dict.
  - `services/api-python/tests/test_multi_case_calibration.py` — remove 2 Данила xfail markers + associated structures.
  - `packages/test-fixtures/golden-cases/*.expected.json` — **possibly** if Haskell output for sample window changes; Worker assesses.
  - `project-overlays/astro/STATUS_RU.md` — narrative for Phase 8B closure.
  - `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` — update § A.4 item 3 status to [RESOLVED via TASK 8B] + § A.2.1 table re-extracted post-fix (or new appendix with post-fix table).
  - `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` — § 4 TYPE-B-equivalent item 8 [RESOLVED via TASK 8B].

- new: —

- delete: —

## Do not touch

- Schema `packages/contracts/*.schema.json` — UNLESS horizon extension forces it. If schema cascade triggers → STOP, escalation memo, separate Tier A TASK.
- Phase 4b Натальи structured overrides в `test_natalya_transits_acceptance.py` — DO NOT change tolerance_overrides values for N-J W3 (±20d end) or N-N W1 (±200d start). These are Marina-editorial divergences and must stay.
- Cases 07 Мария TYPE-A boundary rows (Jun/Jul 2026) — anchor-day convention, separate concern.
- Cases 05 Venus Jul 2025 TYPE-A monthly cell — separate concern.
- TASK 7b / 7c / 8.0 / 8A+8C archived files — historical records.
- Allowlist для 01/02/03/04/09 — separate TASK 8D scope.
- `_3.pdf` / Анастасия — TYPE-D, separate data-revision backlog.

## Acceptance

### Stage B1 — Lexical

- [ ] Rendered case 05 card 3 title: «тр Нептун в **тригоне** с нат Юпитером» (or grammatically appropriate Russian instrumental form).
- [ ] No other case titles affected.
- [ ] No other lexical regression.

### Stage B2 — Horizon fix

- [ ] Stage B2.1: current horizon traced + reported в HANDOFF (value, location, scope).
- [ ] Stage B2.2: target horizon + margin reasoning reported.
- [ ] Stage B2.3: schema-cascade check — confirmed «no cascade» OR STOP+escalation.
- [ ] Stage B2.4: horizon extension applied — minimal Haskell change.
- [ ] Stage B2.5 regression guards (ALL must pass):
  - [ ] (a) Phase 4b Натальи N-J W3 end Δ stays -17d; N-N W1 start Δ stays -178d.
  - [ ] (b) Calendar `annual_transit_table` row count ratio post/pre ≤ 1.5× для каждого case (Натальи / 05 / 07 / 08 / 10).
  - [ ] (c) All 54 non-Данила boundary entries в § A.2.1 retain pre-fix Δ values (2 Phase 4b accepted divergences stay accepted).
  - [ ] (d) Monthly tables 05 / 07 / 08 / 10 unchanged.
  - [ ] (e) Pytest `219 passed + 2 xfailed + 0 failed` baseline preserved pre-unmark.

### Stage B3 — Unmark Данила xfail

- [ ] 2 `@pytest.mark.xfail(strict=True, ...)` markers removed for Данила W3 end (Венере) + W4 end (Юпитеру).
- [ ] `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` (or analogous structure) removed.
- [ ] Pytest post-unmark: `221 passed + 0 xfailed + 0 failed` (или эквивалент per Worker collection).
- [ ] CI green.

### Common

- [ ] `cabal --project-dir core/astrology-hs build`: clean.
- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q`: green per Stage B3.
- [ ] `git status --short` clean for intended product changes; pre-existing `.claude/scheduled_tasks.lock` allowed.
- [ ] Product commit(s): structured ≤ 3 (Haskell engine + Python lexical/xfail unmark + fixture regen if needed). Worker justifies split in HANDOFF.
- [ ] Overlay commit: STATUS_RU + audit report + calibration report + HANDOFF.
- [ ] Push backup, parity verified.

### Tier B discipline

- [ ] If schema cascade triggers → STOP, escalation, **Tier A separate TASK**.
- [ ] If fixture regen needed → atomic commit (Bright Line #8): regen + Haskell roundtrip test + Python contract test + TS types if any. **See § Fixture regen safeguard below — per-case justification table в HANDOFF обязательна.**
- [ ] **Reviewer subagent REQUIRED for Stage B2** (Haskell engine touch). Reviewer reviews horizon parameter change + regression guard evidence + fixture diff before Worker commits. TL inline-verify on top of Reviewer's report.

### Fixture regen safeguard (CRITICAL — no silent regen)

If `cabal build` post-horizon-change produces different `annual_transit_table` content в golden fixtures (`packages/test-fixtures/golden-cases/*.expected.json`):

- [ ] Worker **does NOT silently overwrite** all expected.json files. Each per-case regen requires explicit justification.
- [ ] HANDOFF includes a **per-case justification table**, one row per affected case:

  | case | raw row count before | raw row count after | Δ rows | why changed | downstream assertion proving intended |
  |------|----------------------|---------------------|--------|-------------|----------------------------------------|

  - "why changed" — must reference the horizon extension (e.g. «horizon extended from N to M days → 7 new outer-planet hits in extended window»). Anything beyond «horizon extended» = semantic shift → STOP.
  - "downstream assertion" — concrete test name or audit-report-section that verifies the change is intended (e.g. `test_multi_case_calibration.py :: test_outer_card_window_boundary :: 10-danila Neptune Square Venus W3 end`).

- [ ] Worker walks through table line-by-line in HANDOFF prose; не «таблица без комментария».
- [ ] If any "why changed" cannot be tied to horizon extension → STOP, escalation memo (means semantic shift beyond horizon scope).
- [ ] Reviewer subagent independently verifies justification table before Worker commits.
- [ ] Atomic commit per Bright Line #8: Haskell engine + (schema cascade if triggered, else not) + fixtures regen + Haskell roundtrip test + Python contract test + TS types if any — **all in one product commit**, with per-case justification table in commit message.

### Scope discipline

- [ ] Затронуты: Haskell horizon parameter, `outer_cards.py` aspect-locative, `test_multi_case_calibration.py` xfail unmark, overlay docs.
- [ ] **NOT затронуты:** allowlist 01-09; TYPE-D blockers; Phase 4b Натальи overrides; case 07 TYPE-A monthly rows; case 05 Venus Jul 2025 boundary.
- [ ] No new override mechanisms; no accepted-divergence reclassification.

## Context

**Mode normal + Tier B** (Haskell engine touch + Python presentation + tests). **Reviewer subagent REQUIRED for Stage B2 Haskell change.** Worker mode: normal.

**Baseline:**
- Product main @ `9740075` (TASK 8A+8C accepted).
- Overlay @ `c7df283` (TASK 8A+8C archived + Phase 8B drafted on top).
- Pytest baseline: `219 passed, 2 xfailed (Данила Венере W3 end + Юпитеру W4 end), 0 failed`.
- Cabal build: Up to date.

**Architecture SoT:**
- `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` (recovery program).
- `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` (§ 6 has Phase 8 verdict).
- `project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md` (audit + Phase 8B proposals; § A.2.1 SoT).

**STOP triggers (do not commit + escalate):**
- Schema cascade triggered by horizon extension (Tier A territory).
- Phase 4b Натальи N-J W3 end or N-N W1 start Δ values **shift** post-fix (means horizon is over-correcting Marina-editorial gap).
- Calendar row count bloats > 1.5× for any case.
- Non-Данила boundaries change Δ values (regression).
- Данила tests still fail after unmark (horizon insufficient → wider margin or Path B fallback).
- Worker tempted to fix anything beyond scope (allowlist, TYPE-D).
- Lexical fix breaks other case titles.

**Phase 8B sequence:**
- Stage B1 (lexical) first — quick warmup, low risk.
- Stage B2 (horizon) main work — careful regression guards.
- Stage B3 (unmark xfail) — depends on B2 passing.
- Stage B4 (Path B fence) deferred — optional separate ack required.

**After TASK 8B closes + user explicit ack:** draft TASK 8D (allowlist expansion 01/02/03/04/09 per audit § A.4 item 4). Phase 8 implementation programme = 8B + 8D. TYPE-D остаётся отдельным data-revision backlog вне Phase 8.

**Parallel artifact track — Наталя:** unaffected by 8B (Phase 4b Натальи overrides preserved per regression guard B2.5.a). Marina show готовность не меняется.

**Ready: yes** — flipped 2026-05-14 после user ack + 4 refinements applied:

1. **Horizon margin (B2.2):** не tuning под Данилу. Worker first traces current horizon formula, then introduces systemic named parameter `outer_card_lookahead_days` (default proposal `365.25 * 3` = 3 solar years). Bloat impact analysis BEFORE committing default. Anti-pattern STOP trigger: «pin to Marina Данила boundaries +60d» = scope-tuning, not systemic.

2. **Calendar bloat (B2.5.b):** threshold ≤ 1.5× considers **presentation calendar rows after Phase 6 clipping**, NOT raw `annual_transit_table` count. Raw expected may grow (that's the point). Worker reports both ratios в HANDOFF — raw for context, presentation for threshold check.

3. **Reviewer required (Tier B discipline):** Reviewer subagent **REQUIRED for Stage B2** (Haskell engine touch). Reviews horizon parameter change + regression guard evidence + fixture diff before Worker commits.

4. **Fixture regen safeguard:** explicit § «Fixture regen safeguard» added — no silent regen. HANDOFF must contain per-case justification table (raw row count before/after + Δ + why + downstream assertion). Worker walks through prose. Reviewer verifies independently. Atomic commit per Bright Line #8.
