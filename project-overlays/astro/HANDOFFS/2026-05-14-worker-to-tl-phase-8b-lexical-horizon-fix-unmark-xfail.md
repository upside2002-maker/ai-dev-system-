## HANDOFF: worker → tl — phase-8b-lexical-horizon-fix-unmark-xfail (ESCALATION)

- Status: escalation (STOP at Stage B2.2 — spec premise contradicts empirical evidence)
- Date: 2026-05-14
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker (subagent)
- TASK: project-overlays/astro/TASKS/2026-05-14-phase-8b-lexical-horizon-fix-unmark-xfail.md

## TL;DR

Stage B1 (lexical «трине» → «тригоне») landed cleanly in working tree: 219 passed + 2 xfailed preserved. Stage B2.1 trace done — horizon parameter is `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 540` in `services/api-python/app/ephemeris/bridge.py:204-205` (Python side, not Haskell — engine treats sample stream as opaque). Stage B2.2 bloat analysis at proposed `outer_card_lookahead_days ≈ 1096d` (buffer_after 540 → 730) shows clean impact: presentation rows ratio 1.00× across all 4 cases, raw rows +10-13 per case (≤1.15×). **B2.2 surfaced a finding that triggers spec STOP rule B.2.5.a but on a false premise:** the Phase 4b «Marina-editorial» N-J W3 end +17d Δ for case 08 (Натальи) is in fact **the same engine finite-horizon truncation as Данила** — baseline exit_jd = `2461800.5928` = Натальи SR + 906d = horizon cutoff. Post-extension exit_jd = `2461817.9332` = Marina's `16.02.2028 12:00` within 1.4 hours. The Phase 4b structured override `tolerance_override = +20d` was protecting against a horizon artifact, not a Marina-editorial choice. Per Tier-B Worker discipline + spec § STOP triggers, Worker stops before B2.3-B2.5/B3 and escalates to TL for ack on revised acceptance criteria.

## What's in working tree (not committed)

Two files modified, both belong to Stage B1 (clean, ready to commit):

1. `services/api-python/app/pdf/outer_cards.py` — two edits:
   - Line 162 (comment): `«трине»` → `«тригоне»`.
   - Line 193 (aspect-locative dict): `"Trine": "трине"` → `"Trine": "тригоне"`.

2. `services/api-python/tests/test_multi_case_calibration.py` — two edits to sync existing acceptance to new wording:
   - Line 344: `("Нептун", "трине", "Юпитером")` → `("Нептун", "тригоне", "Юпитером")` in `test_outer_card_titles_marina_style` parametrize for case 05.
   - Line 725: `r"трин\w*"` → `r"тригон\w*"` in `test_rendered_pdf_contains_outer_card_titles` parametrize for case 05.

Without the test edits, the lexical fix would have caused 2 test failures (FAILED tests pinned the old «трине» wording — confirmed by running pytest after only the engine edit). After both engine + test edits: **219 passed + 2 xfailed** preserved.

PDF re-render of case 05 confirms post-B1 visual acceptance: page 11 shows «тр Нептун в **тригоне** c нат Юпитером» (extracted via pypdf). Case 07/08/10 PDFs verified — no «трине» or «тригоне» titles (none have Trine outer cards). 0 lexical regression.

## Stage B2.1 trace — horizon is Python-side

Spec § B.2.1 expects horizon in `Domain.TransitCalendar`. Reality:

- `core/astrology-hs/src/Domain/TransitCalendar.hs:618-623` docstring: «sample window MAY (and after Tier A 2026-05-11 SHOULD) extend beyond the strict [solar_return_jd, solar_return_jd + 365.25] range … The engine treats samples as a single contiguous stream and emits contacts wherever they fall (no internal date filtering).» Engine reads samples opaque, no horizon parameter.
- `services/api-python/app/ephemeris/bridge.py:204-205` — the actual horizon constants:
  ```python
  _TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE = 540
  _TRANSIT_SAMPLE_BUFFER_DAYS_AFTER  = 540
  ```
- `compute_transit_samples(solar_jd, days=366, buffer_days_before=540, buffer_days_after=540)` samples `540 + 366 + 540 = 1446` days at 1-day step. Result: `last_sample_jd = SR + 906d`.
- This window applies to ALL `_TRANSIT_PLANETS` = `(Mars, Venus, Jupiter, Saturn, Uranus, Neptune, Pluto)` — same horizon for inner-mover and outer-planet samples (a single contiguous window per planet).
- Per Tier-B bright-line #7 (Python owns ephemeris sampling), this is the correct layer.

**Scope verification for Данила finite-horizon symptom:** Данила SR = `2460892.8224` (05.08.2025 07:44 UTC). SR + 906d = `2461798.8224` = `28.01.2028 07:44 UTC` ≈ `28.01.2028 10:44 GMT+3`. Matches audit § A.2.1 «engine `orb_exit_jd` = 2461798.822368622» **exactly**.

Same calculation for Натальи 08: SR = `2460894.5928` (07.08.2025 02:13 UTC). SR + 906d = `2461800.5928` = `30.01.2028 02:13 UTC`. Matches engine N-J W3 end exit_jd = `2461800.5928` **exactly**.

**Implication:** Both Данила (case 10) AND Натальи (case 08) N-J W3 end suffer from the same horizon truncation. This was NOT flagged in audit § A.2.1 because Натальи's Marina W3 end (`16.02.2028`) is only +17d past our cutoff, looking like editorial divergence; Данила's Marina W3/W4 end (07.03.2028 / 18.03.2028) is +38/+49d past — too far to plausibly be editorial.

## Stage B2.2 — target horizon + bloat analysis

Proposed `outer_card_lookahead_days = 365.25 * 3 ≈ 1096d`, decomposed in existing structure as `days = 366` + `buffer_days_after = 730` (BEFORE buffer unchanged at 540). Rationale: spec § B.2.2 default, ~3 solar years; provides ~73d safety past Marina's farthest displayed boundary (Данила W4 Юпитеру = 18.03.2028 = SR+960d).

### Bloat measurement table (per spec § B.2.5.b)

Methodology: regenerated `.input.json` `transit_samples` with new buffer in /tmp/, ran Haskell core CLI fresh, counted resulting `annual_transit_table` rows (raw) and `transit_aspects_by_month` rows (presentation, post Phase 6 clipping). No fixture file was overwritten.

| case | raw_pre | raw_post | Δraw | ratio_raw | pres_pre | pres_post | ratio_pres | within 1.5× threshold? |
|------|---------|----------|------|-----------|----------|-----------|------------|-------------------------|
| 05-ekaterina-2025-2026 | 88 | 101 | +13 | 1.15× | 48 | 48 | 1.00× | YES |
| 07-mariya-2025-2026    | 96 | 106 | +10 | 1.10× | 33 | 33 | 1.00× | YES |
| 08-natalya-2025-2026   | 100 | 110 | +10 | 1.10× | 48 | 48 | 1.00× | YES |
| 10-danila-2025-2026    | 99 | 110 | +11 | 1.11× | 76 | 76 | 1.00× | YES |

**Findings:**
- Presentation calendar **does not bloat at all** (1.00× across the board). Phase 6 clipping `[sr_jd, sr_jd + 365.25]` already isolates calendar rows to solar-year span; extending sample window only affects entries outside that span.
- Raw `annual_transit_table` grows by 10-13 rows per case — well within 1.5× threshold. New rows are new house-stay intervals in the extended post-SR window for slow planets.

### Boundary verification — Данила (the intended fix targets)

| case 10 boundary | Marina | Pre-fix engine | Post-fix engine | Δ pre | Δ post | status |
|---|---|---|---|---|---|---|
| N-V W3 end | 2028-03-07 | 2028-01-28 | **2028-03-07** | −39d | **0d** | converges (Δ within ±2d default tolerance) |
| N-J W4 end | 2028-03-18 | 2028-01-28 | **2028-03-18** | −50d | **0d** | converges (Δ within ±2d default tolerance) |

Both Данила targets resolve cleanly with horizon extension. xfail markers in `test_multi_case_calibration.py` would naturally `xpass(strict)` post-fix.

### Boundary verification — Phase 4b Натальи (the **STOP-trigger** finding)

Per spec § B.2.5.a, Worker must verify:
- 08 N-J W3 end stays Δ -17d (Marina `16.02.2028` vs ours `30.01.2028`).
- 08 N-N W1 start stays Δ -178d (Marina `27.09.2024` vs ours `02.04.2024`).

| case 08 boundary | Marina | Pre-fix engine | Post-fix engine | Δ pre | Δ post | spec premise | empirical reality |
|---|---|---|---|---|---|---|---|
| N-J W3 end (Retrograde+DirectReturn) | 2028-02-16 12:00 | 2028-01-30 02:13 | **2028-02-16 10:24** | −17d | **−0.06d (≈ −1.4h)** | Marina editorial choice | **horizon truncation: pre-fix exit_jd = SR + 906d EXACTLY** |
| N-N W1 start (Direct) | 2024-09-27 | 2024-04-02 | 2024-04-02 (unchanged) | −178d | −178d | Marina editorial choice | unchanged (BEFORE buffer not extended) — could still be Marina-editorial OR could be ALSO a finite-horizon question on the BEFORE side, untested |

**N-N W1 start (`02.04.2024`) is preserved** — extension AFTER does not affect BEFORE-side hits. Δ stays −178d per spec § B.2.5.a.

**N-J W3 end shifts from `30.01.2028` to `16.02.2028`** — Δ moves from −17d to ~0d (Marina match within 1.4 hours).

### The premise contradiction

Spec § B.2.5.a STOP trigger: «If Δ values **shift** → STOP (means horizon over-corrects Marina-editorial gap).»

The parenthetical encodes the **assumption** that N-J W3 end's −17d divergence is Marina-editorial (per Phase 4b memo `transit-contact-window-semantics-2026-05-13.md` § 4.4: H4 «editorial / non-deterministic» best-fit).

Empirical finding contradicts this premise:
- Pre-fix `orb_exit_jd = 2461800.5928` = Натальи SR (`2460894.5928`) + **906.0000 d**.
- 906d = `days + buffer_days_after` = `366 + 540` = engine sample window cutoff.
- This is the **same artifact** as Данила (both end at SR+906d).
- Post-fix `orb_exit_jd = 2461817.9332` = Marina's `2028-02-16 12:00 MSK` ± 1.4 hours. **Natural convergence**, no Marina-editorial choice needed.

The Phase 4b memo § 4.3 H3 verdict «N-J W1 vs N-N W1 морфологически идентичны, но Marina рисует одно как full window, другое как 15-day tail» was based on assumption N-J W3 end = `30.01.2028` was the «true» engine output. Once horizon is extended, N-J W3 end becomes `16.02.2028`, matching Marina. The H4 «editorial» classification for N-J W3 end was a false attribution — it was actually finite-horizon truncation that the Phase 4b memo did not diagnose.

N-N W1 start (`02.04.2024`) remains under the H4 «editorial» classification. Whether extending the BEFORE buffer would similarly converge with Marina (`27.09.2024`) is **untested** in this analysis (spec § B.2.2 only proposed AFTER extension).

### Spec STOP rule, literal application

Per spec § STOP triggers AND § B.2.5.a:
> «Phase 4b Натальи N-J W3 end OR N-N W1 start Δ values **shift** post-fix.»
> «If Δ values shift → STOP (means horizon over-corrects Marina-editorial gap).»

N-J W3 end Δ shifts from −17d to ~0d. The literal rule fires.

The parenthetical reason («over-correcting Marina-editorial gap») does not apply factually — N-J W3 end is not editorial. But the Worker cannot unilaterally override the literal STOP rule on the basis of «the spec encodes an outdated assumption». Per Tier-B Worker discipline (§ Authorization framing): «Stage B2 (Haskell engine touch) cannot land without Reviewer APPROVE. … STOP + escalation memo on any scope ambiguity or unexpected finding.»

Worker escalates to PTL.

## Stage B2.3 — schema-cascade detection (analysis-only)

No schema cascade triggered by horizon extension. `_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER` is a runtime parameter; same field types in `solar-resolved-input.schema.json` (`transit_samples: {planet: [{jd, longitude, speed}, …]}`); same `TransitContact` shape in `solar-facts.schema.json`. The payload changes only in list length (more samples / hits). Tier B sufficient per spec § B.2.3.

## Stage B2.4 / B2.5 / B3 — not performed

Worker stopped before applying horizon extension. No Haskell change, no `bridge.py` constant edit, no fixture regen, no xfail unmark.

## Decision tree for TL

Three paths Worker proposes for TL ack. All depend on TL's product decision about Phase 4b N-J W3 end classification.

### Path 1 — Accept horizon convergence; revise Phase 4b classification

**Rationale:** N-J W3 end is empirically demonstrated NOT to be Marina-editorial — it was finite-horizon artifact. Phase 4b memo § 4 hypothesis testing should be reread with the post-extension data; H4 «editorial» verdict was a false attribution caused by horizon truncation hiding the natural engine output.

**Actions:**
1. Extend horizon (`_TRANSIT_SAMPLE_BUFFER_DAYS_AFTER = 540 → 730`) per Worker's B2.2 default proposal.
2. **Remove the Phase 4b structured override for N-J W3 end +20d** in `test_natalya_transits_acceptance.py` (`_assert_three_phase_intervals` per-window tolerance_override). The override was protecting a horizon artifact; post-fix, the natural engine output is within default ±2d of Marina.
3. **Keep** the Phase 4b structured override for N-N W1 start +200d. N-N W1 start is on the BEFORE side; AFTER extension does not affect it. Whether N-N W1 start is also a horizon artifact (BEFORE-side) or genuine Marina editorial is a separate question — Worker recommends a follow-up analysis but NOT in this TASK.
4. Regen all 4 affected fixtures (`05/07/08/10.expected.json`). Per-case justification table:

| case | raw row count before | raw row count after | Δ rows | why changed | downstream assertion proving intended |
|------|----------------------|---------------------|--------|-------------|----------------------------------------|
| 05-ekaterina-2025-2026 | 88 | 101 | +13 | horizon extended SR+906d → SR+1096d → engine emits new entries for Saturn/Uranus/Neptune/Pluto in extended window (no Marina-displayed boundaries within new range, but raw stream legitimately grows) | `test_multi_case_calibration.py::test_outer_card_window_boundary_within_tolerance` — all 18 case-05 boundary assertions continue to pass at ±2d default |
| 07-mariya-2025-2026 | 96 | 106 | +10 | same — extended sample window emits new entries | no card-related assertions for 07 (Marina editorial 0 outer cards); presentation calendar unchanged (33→33) |
| 08-natalya-2025-2026 | 100 | 110 | +10 | same — extended window emits new entries; **plus** N-J W3 end now reflects natural engine output (`16.02.2028 10:24 UTC`) instead of horizon cutoff (`30.01.2028 02:13 UTC`) | `test_natalya_transits_acceptance.py` — N-J W3 end tolerance_override removed; default ±2d passes; all other phase-set assertions unchanged |
| 10-danila-2025-2026 | 99 | 110 | +11 | same — extended window emits new entries; **plus** N-V W3 end and N-J W4 end now reflect natural engine output (matching Marina exactly) | `test_multi_case_calibration.py::test_outer_card_window_boundary_within_tolerance` — 2 Данила xfail markers naturally `xpass(strict)`, then Stage B3 unmarks them |

5. Stage B3 unmark 2 Данила xfail markers + `_PHASE_8B_DANILA_XFAIL_BOUNDARIES` data structure.
6. `test_natalya_transits_acceptance.py` — remove `tolerance_override` for N-J W3 end. Verify pytest 219 passed + 2 xfailed → 221 passed + 0 xfailed.
7. Overlay updates: STATUS_RU + audit report § A.2.1 (08 N-J W3 end reclassified from «Phase 4b accepted editorial» → «resolved via horizon extension Phase 8B»); calibration report § 6.

**Pros:**
- Engine becomes truth-source for **3 boundaries**, not just 2 (N-J W3 end joins N-V W3 end + N-J W4 end as horizon fixes).
- Phase 4b classification corrected — one false-attribution removed from the «accepted Marina divergence» list.
- Test contract becomes uniform (default ±2d) for that boundary; structured override count reduces from 2 to 1 in `test_natalya_transits_acceptance.py`.
- Marina/PDF parity improves for case 08 (one less editorial divergence to explain).

**Cons:**
- Worker is overriding spec STOP rule literal text on basis of empirical evidence — requires explicit TL ack that Worker's interpretation is correct.
- Phase 4b memo `transit-contact-window-semantics-2026-05-13.md` § 4-6 needs retraction note (the H4 «editorial / non-deterministic» best-fit verdict for N-J W3 end was based on outdated data).
- Reviewer subagent (required for B2 per Tier-B discipline) still needed before commit.

### Path 2 — Honour spec STOP literally; do not extend horizon

**Rationale:** Spec § B.2.5.a STOP is unambiguous. Worker stops, no horizon change, Phase 8B Данила targets remain xfail-strict. The empirical finding is reported but no product change applied.

**Actions:**
- Stage B1 lexical fix commits as-is (independent of B2).
- Stage B2 abandoned. Phase 8B closes incomplete — Данила finite-horizon truncation remains documented but unfixed.
- Audit report § A.2.1 + § A.4 item 3 unchanged. Phase 8B sub-task #3 remains open.
- Worker documents finding (this HANDOFF) but does not act on it.

**Pros:**
- Pure spec compliance.

**Cons:**
- Данила finite-horizon truncation remains unfixed despite Worker having identified the clean systemic fix.
- Phase 4b N-J W3 end misclassification not corrected — false-attribution stays in record.
- TL must reopen Phase 8B with revised spec to proceed.

### Path 3 — Hybrid (extend AFTER for Данила; leave Phase 4b override intact for case 08)

**Rationale:** Apply horizon extension, but treat the 08 N-J W3 end Δ shift as a side-effect and update the Phase 4b override to «±0d» (effectively no override needed). Keep Phase 4b memo's N-J W3 classification intact but note it «happens to converge under Phase 8B horizon extension».

**Actions:**
- Same as Path 1 except: no Phase 4b memo retraction; no formal reclassification of N-J W3 end. Just remove the +20d tolerance_override mechanically because the default ±2d now works.

**Pros:**
- Minimal documentation churn.
- Same code-side outcome as Path 1.

**Cons:**
- Phase 4b memo's «editorial» verdict remains in record despite being demonstrably wrong for N-J W3 end. Confusing for future agents.
- Spec STOP rule treated as «soft trigger» (warning, not stop). Sets precedent for Worker discretion that contradicts Tier-B discipline.

### Worker recommendation

**Path 1.** The empirical finding is a clear refutation of the Phase 4b N-J W3 end editorial classification. Engine accuracy improves; one false-attribution removed; downstream test discipline stays clean. The Phase 4b memo retraction note is small (one-paragraph addendum in § 4). Reviewer subagent is still required to validate the regen + interpretation before commit.

## Files in working tree (B1 only — clean, awaiting decision)

- `services/api-python/app/pdf/outer_cards.py` — lexical fix.
- `services/api-python/tests/test_multi_case_calibration.py` — sync tests to new wording.

Both verified: pytest 219 passed + 2 xfailed; cabal build clean.

`/tmp/measure_horizon_impact.py` and `/tmp/check_boundaries.py` — analysis scripts; can be discarded or retained by TL preference.

`/tmp/*.ext.facts.json` — proof-of-concept extended fixtures (4 files); not for commit.

## Acceptance checklist status

### Stage B1 — Lexical
- [x] Rendered case 05 card 3 title: «тр Нептун в **тригоне** с нат Юпитером» (verified via pypdf extract from `/tmp/05-ekaterina-stage-b1.pdf` page 11).
- [x] Cases 07/08/10 PDF titles unchanged (no Trine outer cards; verified empty match on «трине»/«тригон» across all 3).
- [x] No other lexical regression.

### Stage B2 — Horizon fix
- [x] Stage B2.1: current horizon traced (Python `bridge.py:204-205`, not Haskell).
- [x] Stage B2.2: target horizon analyzed; default `outer_card_lookahead_days ≈ 1096d` (buffer_after 540 → 730) yields presentation ratio 1.00× across 4 cases.
- [x] Stage B2.3: schema-cascade check — no cascade (runtime parameter; same field types).
- [ ] Stage B2.4: horizon extension applied — **NOT performed; awaiting TL decision**.
- [ ] Stage B2.5 regression guards — **NOT performed; B2.5.a STOP trigger fired**.

### Stage B3 — Unmark Данила xfail
- [ ] **NOT performed; depends on B2 application**.

## Pytest baseline

```
$ cd services/api-python && .venv/bin/pytest --tb=no -q
219 passed, 2 xfailed in 98.78s
```

Baseline preserved with Stage B1 working-tree edits in place.

## Cabal build

```
$ cd core/astrology-hs && cabal build
Up to date
```

(no Haskell changes proposed or applied in this session.)

## Artifacts

- branch: main
- commit(s): **none** — Worker did not commit any product or overlay change pending TL decision.
- PR: not applicable.
- tests: 219 passed + 2 xfailed + 0 failed (baseline preserved; Stage B1 working-tree applied).
- cabal: Up to date (no changes).
- Product repo status: **modified-not-staged** for B1 (2 files: `outer_cards.py` + `test_multi_case_calibration.py`); analysis scripts in `/tmp/` (not for commit).
- Overlay repo status: clean except this HANDOFF.
- Push backup: not performed (no commits to push).

## Conflicts / discoveries

1. **Spec § B.2.1 expected Haskell horizon parameter; actually Python.** Per Tier-B bright-line #7 (Python owns ephemeris sampling), the Python location is correct. Spec wording «modify: `core/astrology-hs/src/Domain/TransitCalendar.hs` (or wherever horizon parameter lives)» already hedged this — no formal contradiction, just clarification: this is a Python-side Tier-B change (still requires Reviewer per Tier-B discipline because the regression scope is wide).

2. **Phase 4b N-J W3 end Δ -17d classification is empirically incorrect.** Per § «The premise contradiction» above. Engine pre-fix output (`30.01.2028 02:13 UTC`) matches Натальи SR + 906d **exactly**; post-fix output (`16.02.2028 10:24 UTC`) matches Marina (`16.02.2028 12:00 MSK = 09:00 UTC`) within 1.4 hours. Phase 4b memo `transit-contact-window-semantics-2026-05-13.md` § 4 «H4 editorial» classification needs retraction for this boundary.

3. **Phase 4b N-N W1 start Δ -178d classification — untested.** Worker did not extend the BEFORE buffer. Whether N-N W1 start would similarly converge with Marina under BEFORE buffer extension is a separate question. Spec § B.2.2 only proposed AFTER extension. Worker recommends this as a Phase 8B follow-up sub-task if TL chooses Path 1.

4. **Reviewer subagent not yet spawned.** Per Tier-B discipline + TASK § Authorization framing, Reviewer is required for B2 commit. Worker has not reached the commit point because of B2.2 STOP. If TL accepts Path 1, Worker will spawn Reviewer subagent after applying horizon extension and regen-ing fixtures, before committing.

## Next step

TL ack on one of three paths (Path 1 recommended). After ack:

- Path 1: Worker resumes Stage B2.4 (apply horizon), regens 4 fixtures with per-case justification table, spawns Reviewer subagent for B2 review, removes Phase 4b N-J W3 +20d override, executes Stage B3, commits product (2-3 commits per spec) + overlay, pushes backup.
- Path 2: Worker commits Stage B1 only as a single product commit; closes TASK 8B-lexical-only; reopens Phase 8B-horizon as new TASK with revised acceptance criteria.
- Path 3: Worker resumes per Path 1 actions except keeps Phase 4b memo classification intact; HANDOFF marks N-J W3 end as «converges incidentally under Phase 8B horizon extension; original Phase 4b classification not retracted».

End of HANDOFF.
