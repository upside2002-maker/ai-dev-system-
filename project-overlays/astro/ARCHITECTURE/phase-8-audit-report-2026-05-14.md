# Phase 8A Audit Report — Marina Etalons Full-Folder Inventory + Boundary SoT

Date: 2026-05-14
Author: Worker subagent (TASK Phase 8A+8C, `2026-05-14-phase-8a-8c-audit-and-boundary-test-contract`)
Owner: Project Tech Lead
Scope: Read-only audit. **No product code changes in this report.**

Architecture SoT: `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
Calibration baseline: `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md`.
Phase 8.0 reopen: `project-overlays/astro/TASKS/archive/2026-05-14-phase-8-0-reopen-audit-trail.md`.

Baseline at audit time:
- Product main @ `c936dd1` (TASK 7b Stage B closure).
- Pytest baseline: `183 passed, 0 xfailed, 0 failed` (verified before Phase 8C additions).
- Cabal `astrology-core-cli` build: up-to-date.

---

## § A.1 Marina etalon inventory

Source dir: `/Users/ilya/Downloads/Gmail (3)/`. 10 PDFs total. Each PDF's «Время запуска» caption on page 1 was converted to UTC and compared against the matching `expected.json` `solar_chart.return_jd`. Tolerance: Δ < 60 s.

| # | Marina PDF | SR caption (local) | SR UTC | Fixture | Δ SR | Status |
|---|---|---|---|---|---|---|
| 1 | `Соляр 2024-2025.pdf` | 19.11.2024 06:14:30 GMT+3 | 19.11.2024 03:14:30 | `01-kseniya-2024-2025` | < 1 s | matched |
| 2 | `Солярный гороскоп 2025-2026.pdf` | 04.09.2025 17:44:25 GMT+3 | 04.09.2025 14:44:25 | `02-maksim-2025-2026` | ~ 10 s | matched |
| 3 | `Соляр 2025-2026.pdf` | 27.09.2025 14:16:30 GMT+3 | 27.09.2025 11:16:30 | `03-artem-2025-2026` | ~ 11 s | matched |
| 4 | `Соляр 2025-2026_1.pdf` | 28.03.2025 14:18:30 GMT-5 | 28.03.2025 19:18:30 | `04-valeriya-2025-2026` | ~ 6 s | matched |
| 5 | `Соляр 2025-2026_2.pdf` | 11.03.2025 09:34:30 GMT+3 | 11.03.2025 06:34:30 | `05-ekaterina-2025-2026` | ~ 45 s | matched |
| 6 | `Соляр 2025-2026_3.pdf` | 05.09.2025 12:16:30 GMT+3 | 05.09.2025 09:16:30 | (no match) | — | **data-quality-incomplete (TYPE-D)** |
| 7 | `Соляр 2025-2026_4.pdf` | 01.07.2025 22:11 GMT+3 | 01.07.2025 19:11 | `07-mariya-2025-2026` | < 60 s | matched |
| 8 | `Соляр 2025-2026_5.pdf` | 07.08.2025 05:13:30 GMT+3 | 07.08.2025 02:13:30 | `08-natalya-2025-2026` | ~ 10 s | matched |
| 9 | `Соляр 2025-2026 для Анастасии.pdf` | 14.05.2025 13:53:45 GMT+3 | 14.05.2025 10:53:45 | `09-anastasiya-2025-2026` | **~ 59 min 42 s** | **mismatched (TYPE-D)** |
| 10 | `Соляр 2025-2026 для Данилы.pdf` | 05.08.2025 10:44:12 GMT+3 | 05.08.2025 07:44:12 | `10-danila-2025-2026` | ~ 0 s | matched |

**Summary:** 8 of 10 PDFs match an existing fixture within Δ < 60 s. 2 PDFs are data-quality blockers:

- `Соляр 2025-2026_3.pdf` (SR 05.09.2025 09:16:30 UTC) — no fixture has matching SR. Page 1 shows Asc Скорпион / MC Дева but natal metadata cannot be reproduced from current fixture set. **TYPE-D — listing only; not in Phase 8 scope.**
- `Соляр 2025-2026 для Анастасии.pdf` (SR 14.05.2025 10:53:45 UTC) vs `09-anastasiya-2025-2026` SR (09:54:03 UTC). Δ ≈ 60 min — likely SR-time / timezone offset issue in fixture or PDF caption. **TYPE-D — listing only; not in Phase 8 scope.**

Matched fixtures used in Phase 8A § A.2 below:
- `01-kseniya-2024-2025` (Соляр 2024-2025.pdf — 2024-2025 solar year, NB: previous year)
- `02-maksim-2025-2026` (Солярный гороскоп 2025-2026.pdf)
- `03-artem-2025-2026` (Соляр 2025-2026.pdf)
- `04-valeriya-2025-2026` (Соляр 2025-2026_1.pdf)
- `05-ekaterina-2025-2026` (Соляр 2025-2026_2.pdf) — Phase 7 default trio
- `07-mariya-2025-2026` (Соляр 2025-2026_4.pdf) — Phase 7 default trio
- `08-natalya-2025-2026` (Соляр 2025-2026_5.pdf) — Phase 1-7 anchor
- `09-anastasiya-2025-2026` (Соляр 2025-2026 для Анастасии.pdf) — **mismatched SR**
- `10-danila-2025-2026` (Соляр 2025-2026 для Данилы.pdf) — Phase 7 default trio

---

## § A.2 Per-case diff

### Already-covered cases (Phase 7 calibration scope: 05, 07, 08, 10)

Per § A.2 of TASK spec, the four Phase 7 calibrated cases (05/07/08/10) are re-inspected here for **outer-card interval boundaries** in particular — that was the test contract gap the Phase 8.0 audit revealed.

The other dimensions for 05/07/08/10 (monthly table, per-house, calendar smoke, outer-card structure, golden-rule, psychology/event text presence) are documented in calibration report § 3.1 / § 3.2 / § 3.3 / § 1-2 / Phase 1-7 acceptance suite and not re-audited in this report (already pinned in tests). Stage A.2 of the calibration report verifies:
- Case 05: monthly cells 51/52 match (Venus Jul 2025 = TYPE-A anchor); 3 outer cards present; calendar populated; per-house list matches Marina set.
- Case 07: monthly cells 11/13 (rows 12-13 = TYPE-A); 0 outer cards (Marina editorial); calendar populated.
- Case 08: full Phase 4b structured assertions in `test_natalya_transits_acceptance.py` (3 outer cards, 9 phase-set windows, 7 boundary assertions, 2 structured tolerance overrides for N-J W3 end +20d & N-N W1 start +200d).
- Case 10: monthly cells 52/52; 3 outer cards (incl. 4-window Нептун-Юпитер); calendar populated; per-house list matches Marina set.

### Newly inspected matched cases (01, 02, 03, 04, 09)

These 5 fixtures match Marina PDFs but were not in Phase 7 calibration scope. This audit inspects them for outer-card structure and the gap class observed.

| Case | Marina outer cards (unique titles in PDF) | Our outer cards (`outer_cards_for_case`) | Allowlist | Gap class |
|---|---|---|---|---|
| 01-kseniya | 5 (Нептун кв Марс, Нептун триг Солнце, Плутон триг Юпитер, Уран опп Солнце, Уран опп Уран) | 0 | empty | TYPE-A |
| 02-maksim | 2 (Уран опп Плутон, Уран триг Уран) | 0 | empty | TYPE-A |
| 03-artem | 9 (4 Neptune, 2 Pluto, 3 Uranus) | 0 | empty | TYPE-A |
| 04-valeriya | 2 (Уран кв Сатурн, Уран опп Плутон) | 0 | empty | TYPE-A |
| 09-anastasiya | 2 (Нептун секст Меркурий, Уран соед Меркурий) | 0 | empty | TYPE-A + **SR mismatch (TYPE-D)** — boundary diff is moot until fixture corrected |

Cases 01-04 and 09 share the same closed-config gap as the original 05/10 had pre-Stage-B (Phase 7 / TASK 7b). Fix pattern: extend `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` from Marina reference per case. **Resolution is Phase 8B scope, not this TASK.**

For 09-anastasiya, the SR-mismatch (~60 min) means engine output cannot be trusted to align with Marina dates even if the allowlist were populated. **Data-revision sub-task TYPE-D required before allowlist work.**

### Lexical divergence — case 05

Card 3 title:
- **Our PDF / engine output:** «тр Нептун в **трине** c нат Юпитером».
- **Marina PDF p. 35:** «тр Нептун в **тригоне** c нат Юпитером».

Aspect locative dict in `services/api-python/app/pdf/outer_cards.py` maps `Trine → «трине»`; Marina uses «тригоне». One-word lexical fix. **TYPE-A — Phase 8B scope.**

---

## § A.2.1 Marina boundary dates table — canonical SoT

**This is the single source-of-truth for Phase 8C boundary assertions.** Tests in `test_multi_case_calibration.py` and `test_natalya_transits_acceptance.py` reference this table by `# SoT: project-overlays/astro/ARCHITECTURE/phase-8-audit-report-2026-05-14.md § A.2.1` comment. No ad-hoc re-extraction from PDFs in test code.

Marina dates extracted directly from PDFs (date-only; HH:MM dropped). Our dates parsed from `interval["start_str"]` / `interval["end_str"]` (current format `«DD.MM.YYYY HH:MM (GMT+3)»`) to `datetime.date`. Δ = our − Marina, signed integer days. Tolerance: ±2 days date-only per side.

Reference page numbers in Marina PDFs:
- Case 05 → `Соляр 2025-2026_2.pdf` pp. 34-36.
- Case 08 → `Соляр 2025-2026_5.pdf` pp. 16-19 (covered by Phase 4b suite — listed here for completeness; numbers match calibration report § 6 reference).
- Case 10 → `Соляр 2025-2026 для Данилы.pdf` pp. 16-19.

| case | card | W | Marina start | Marina end | our start | our end | Δ start (d) | Δ end (d) | status |
|------|------|---|--------------|------------|-----------|---------|-------------|-----------|--------|
| 05 | Uranus Square Moon | W1 | 2025-07-21 | 2025-10-24 | 2025-07-20 | 2025-10-24 | -1 | 0 | OK |
| 05 | Uranus Square Moon | W2 | 2026-05-06 | 2026-06-09 | 2026-05-05 | 2026-06-09 | -1 | 0 | OK |
| 05 | Uranus Square Moon | W3 | 2026-12-25 | 2027-03-25 | 2026-12-24 | 2027-03-25 | -1 | 0 | OK |
| 05 | Uranus Sextile Jupiter | W1 | 2025-06-05 | 2025-07-14 | 2025-06-04 | 2025-07-14 | -1 | 0 | OK |
| 05 | Uranus Sextile Jupiter | W2 | 2025-10-31 | 2025-12-20 | 2025-10-31 | 2025-12-20 | 0 | 0 | OK |
| 05 | Uranus Sextile Jupiter | W3 | 2026-03-21 | 2026-05-01 | 2026-03-21 | 2026-05-01 | 0 | 0 | OK |
| 05 | Neptune Trine Jupiter | W1 | 2024-04-12 | 2024-09-28 | 2024-04-12 | 2024-09-28 | 0 | 0 | OK |
| 05 | Neptune Trine Jupiter | W2 | 2025-02-12 | 2025-04-08 | 2025-02-12 | 2025-04-08 | 0 | 0 | OK |
| 05 | Neptune Trine Jupiter | W3 | 2025-10-10 | 2026-02-07 | 2025-10-09 | 2026-02-07 | -1 | 0 | OK |
| 08 | Uranus Square Venus | W1 | 2025-06-03 | 2025-07-12 | 2025-06-03 | 2025-07-12 | 0 | 0 | OK |
| 08 | Uranus Square Venus | W2 | 2025-11-02 | 2025-12-22 | 2025-11-02 | 2025-12-22 | 0 | 0 | OK |
| 08 | Uranus Square Venus | W3 | 2026-03-19 | 2026-04-30 | 2026-03-18 | 2026-04-30 | -1 | 0 | OK |
| 08 | Neptune Square Jupiter | W1 | 2026-04-21 | 2026-09-28 | 2026-04-21 | 2026-09-28 | 0 | 0 | OK |
| 08 | Neptune Square Jupiter | W2 | 2027-02-21 | 2027-04-16 | 2027-02-21 | 2027-04-16 | 0 | 0 | OK |
| 08 | Neptune Square Jupiter | W3 | 2027-10-10 | 2028-02-16 | 2027-10-09 | 2028-01-30 | -1 | **-17** | **OUT-end** (Phase 4b accepted divergence — N-J W3 end +20d structured override in `test_natalya_transits_acceptance.py`; Marina editorial) |
| 08 | Neptune Square Neptune | W1 | 2024-09-27 | 2024-10-12 | 2024-04-02 | 2024-10-12 | **-178** | 0 | **OUT-start** (Phase 4b accepted divergence — N-N W1 start +200d structured override in `test_natalya_transits_acceptance.py`; Marina editorial) |
| 08 | Neptune Square Neptune | W2 | 2025-01-31 | 2025-03-29 | 2025-01-31 | 2025-03-29 | 0 | 0 | OK |
| 08 | Neptune Square Neptune | W3 | 2025-10-25 | 2026-01-24 | 2025-10-24 | 2026-01-24 | -1 | 0 | OK |
| 10 | Uranus Square Moon | W1 | 2024-07-11 | 2024-10-25 | 2024-07-11 | 2024-10-25 | 0 | 0 | OK |
| 10 | Uranus Square Moon | W2 | 2025-04-28 | 2025-06-02 | 2025-04-28 | 2025-06-02 | 0 | 0 | OK |
| 10 | Uranus Square Moon | W3 | 2025-12-25 | 2026-03-16 | 2025-12-25 | 2026-03-16 | 0 | 0 | OK |
| 10 | Neptune Square Venus | W1 | 2026-05-14 | 2026-09-02 | 2026-05-13 | 2026-09-02 | -1 | 0 | OK |
| 10 | Neptune Square Venus | W2 | 2027-03-13 | 2027-05-07 | 2027-03-12 | 2027-05-07 | -1 | 0 | OK |
| 10 | Neptune Square Venus | W3 | 2027-09-15 | **2028-03-07** | 2027-09-14 | **2028-01-28** | -1 | **-39** | **OUT-end** (Phase 8B target — Данила finite scan horizon; engine `orb_exit_jd` = 2461798.822368622 = 28.01.2028) |
| 10 | Neptune Square Jupiter | W1 | 2026-05-30 | 2026-08-15 | 2026-05-30 | 2026-08-15 | 0 | 0 | OK |
| 10 | Neptune Square Jupiter | W2 | 2027-03-24 | 2027-05-22 | 2027-03-23 | 2027-05-22 | -1 | 0 | OK |
| 10 | Neptune Square Jupiter | W3 | 2027-08-30 | 2027-11-20 | 2027-08-29 | 2027-11-20 | -1 | 0 | OK |
| 10 | Neptune Square Jupiter | W4 | 2028-01-09 | **2028-03-18** | 2028-01-09 | **2028-01-28** | 0 | **-50** | **OUT-end** (Phase 8B target — Данила finite scan horizon; engine `orb_exit_jd` = 2461798.822368622 = 28.01.2028) |

**Aggregate status:**

| Aspect | Tolerance (±2d date-only) | Out-of-tolerance windows |
|---|---|---|
| 05 boundaries | 9 windows × 2 sides = 18 boundary assertions | 0 |
| 08 boundaries | 9 windows × 2 sides = 18 boundary assertions | 2 (both Phase 4b accepted; structured override in Natalya suite) |
| 10 boundaries | 10 windows × 2 sides = 20 boundary assertions | 2 (both Данила finite-horizon — Phase 8C marks `xfail(strict=True)`; Phase 8B target) |
| **Total** | **56 boundary assertions across 28 windows** | **4 OUT-of-tolerance (2 accepted; 2 to xfail)** |

Both Данила OUT-of-tolerance windows terminate at the same engine `orb_exit_jd` (2461798.822368622 = 28.01.2028 10:44 GMT+3). This is a single root cause (engine sample horizon cutoff), affecting two distinct outer cards. Marina's W3 end (Венере, 07.03.2028) and W4 end (Юпитеру, 18.03.2028) are 38 + 49 days past our horizon. Difference between the two is explained by aspect orb width × planet speed at exit.

---

## § A.3 Classification

Aggregating across all cases inspected in Phase 8A + Phase 7 calibration report § 4:

### TYPE-A — closed-config gap (Phase 8B Stage-B-pattern fix)

1. **[New, Phase 8A]** Cases 01/02/03/04/09 outer cards — Marina shows 2-9 cards per case; our `OUTER_CARD_ALLOWLIST` entries empty for all 5 cases. Same gap as original case 05/10 had pre-Stage-B (calibration report § 4 TYPE-A items 1-2). Fix pattern: extend `OUTER_CARD_ALLOWLIST` + `_OUTER_CARD_FACTS` from Marina reference per case.
2. **[New, Phase 8A]** Case 05 card 3 title — lexical «трине» (our) vs «тригоне» (Marina). One-word fix in aspect-locative dict in `outer_cards.py`. Affects every Trine outer card across all cases (not just case 05).
3. **[Phase 7]** Case 05 Venus Jul 2025 monthly cell — anchor-convention boundary divergence (mid-15 vs 01st). Documented note per calibration report § 4 item 3.
4. **[Phase 7]** Case 07 rows 12-13 monthly cells (Июнь/Июль 2026) — same anchor convention. Documented notes per calibration report § 4 items 4-5.

### TYPE-B — generic logic regression (escalation worthy; no Stage B fix possible)

1. **[Phase 7 — RESOLVED]** Case 07 monthly label arithmetic bug — resolved 2026-05-13 by TASK 7a (commit `8a4865e`). Regression test pinned. Listed for completeness.

No new TYPE-B identified by Phase 8A.

### TYPE-B-equivalent — finite-horizon truncation (Phase 8B engine-or-presentation fix)

1. **[New, Phase 8A]** Case 10 Данила Neptune outer cards W3 end (Venus) + W4 end (Jupiter) — both terminate at identical engine `orb_exit_jd` = 2461798.822368622 = 28.01.2028 10:44 GMT+3. Marina W3 end = 07.03.2028 (+39d past horizon); Marina W4 end = 18.03.2028 (+50d past horizon). **Per user directive 2026-05-14: NOT accepted divergence.** Per Phase 8.0 audit findings: «engine finite-horizon sample window truncation, not Marina editorial». Distinct from Phase 4b 08 accepted (which is Marina-editorial). Phase 8B options (Path A engine horizon extension vs Path B presentation truncation marker) — see § A.4 item 3 below.

### TYPE-C — Marina editorial; document only (no fix)

1. **[Phase 7]** Case 07 Мария — 0 outer cards by Marina editorial choice (Соляр 2025-2026_4.pdf p. 15: «у вас не будет транзитных аспектов от высших планет»). Empty allowlist entry for case 07 is correct.
2. **[Phase 4b]** Case 08 Натальи N-J W3 end +20d, N-N W1 start +200d — Marina editorial choice on display window boundaries beyond engine 1° orb threshold; accepted divergence per Path 4 decision 2026-05-13. Already captured via structured `tolerance_overrides` in `test_natalya_transits_acceptance.py`. **Distinct from TYPE-B-equivalent Данила case: 08 is editorial; 10 is engine horizon.**

### TYPE-D — data quality (separate from code regressions; NOT in Phase 8 scope)

1. **[New, Phase 8A]** `Соляр 2025-2026_3.pdf` — SR 05.09.2025 09:16:30 UTC, no matching fixture. Natal metadata cannot be reproduced from current fixture set. Page 1 shows Asc Скорпион / MC Дева. **Diagnostic: needs separate data-revision sub-task to either (a) create a new fixture matching this etalon's natal data, or (b) confirm it represents a closed (unrelated) client and exclude from package scope.**
2. **[New, Phase 8A]** `Соляр 2025-2026 для Анастасии.pdf` — SR 14.05.2025 10:53:45 UTC vs fixture `09-anastasiya-2025-2026` SR 09:54:03 UTC. Δ ≈ 60 min. **Diagnostic: most likely timezone offset error (1-hour gap matches DST or TZ-name change) either in fixture's birth-time/timezone resolution or in PDF caption interpretation. Needs separate data-revision sub-task to verify (a) Marina's intended birth-time, (b) place-of-birth timezone in 2025-05, (c) DST status. Resolution may require re-resolving the fixture via Python's geocoding+timezonefinder pipeline.**

**Both TYPE-D items: listing + short diagnostic only per Phase 8A refinement. Not in Phase 8 scope.**

---

## § A.4 Prioritized Phase 8B sub-task proposals

Ordered by impact and dependency, suitable for follow-up TASK drafting.

### 1. **[CLOSED]** Test contract gap — Phase 8C (this TASK)

Already in scope of this TASK. Closes the test-contract hole by adding outer-card boundary assertions to `test_multi_case_calibration.py`. Status updates with this TASK's submission.

### 2. Lexical fix — case 05 card 3 title «трине» → «тригоне» (Tier C, quick win)

- Location: `services/api-python/app/pdf/outer_cards.py` aspect-locative dict (look for the dict mapping `Trine`).
- Effort: 1 line change + comment.
- Test impact: 0 (no test currently pins the «трине» wording; new test could be added in Phase 8B as fence).
- Affects all Trine outer cards across all cases — not case-05-specific.
- Cost estimate: < 30 min Worker time.

### 3. **Boundary regression decisions for Данила** — engine horizon vs presentation marker

Both 10 Neptune W3-end (Venus) and W4-end (Jupiter) terminate at identical `orb_exit_jd` (2461798.822368622 = 28.01.2028 10:44 GMT+3). Marina W3 end = 07.03.2028 (+39d), W4 end = 18.03.2028 (+50d). Single root cause: engine sample window cutoff. Per user directive 2026-05-14: **not accepted divergence**. Phase 8C marks the 2 boundary tests `xfail(strict=True, reason="Phase 8B — Данила finite scan horizon (engine sample window cutoff 2461798.822368622 = 28.01.2028)")`; Phase 8B must close them with a real fix.

#### Path A — engine sample horizon extension

- **Where:** Haskell engine `Domain.TransitCalendar` (the module that generates `annual_transit_table`) — specifically the function that bounds the sample window for outer-planet hits. Worker traces the actual hit-generation loop in core; from Python side, `annual_transit_table` arrives via `Bridge.Solar.SolarComputedFacts.annual_transit_table` and is currently capped at JD 2461798.822368622 (= roughly natal SR + 900 days or similar horizon constant).
- **Approach:** widen the scan horizon enough that all Marina-displayed loop closures for outer planets fit (Pluto can require multi-year horizon). Likely +500-1000 days past Phase 7 current bound. Engine-level Tier A change because it crosses the Haskell/Python boundary in `SolarComputedFacts` payload semantics (same field types; payload size grows).
- **Cost estimate:**
  - Schema impact: none (same field types, list of `TransitContact` records).
  - Engine impact: function in `Domain.TransitCalendar` — single configuration constant or function parameter.
  - Test impact: full Tier A regression run for 08-natalya (5-year-back N-N window), case-05/07/10 golden fixtures, all 9 calibration cases (some may gain spurious hits beyond solar year that need cutoff in presentation per Phase 6 policy).
  - Risk: slow planet drift may overreach to very distant years for fast outer aspects (Uranus quick passes); presentation must re-confirm Phase 6 cutoff rule (`period_end = min(actual, sr_jd + 365.25)`) for solar-year text contexts.
  - Effort: 1-3 days Worker + Reviewer (Tier A with schema cascade discipline per bright-line #8 if any `TransitContact` field shape changes; if only the loop boundary widens, bright-line #8 may not trigger).
- **Outcome:** Marina Δ should narrow / disappear for Данила Венере W3 + Юпитеру W4 (and any analogous cases discovered in Phase 8A inventory cases 01-04, 09). Engine becomes the truth-source for loop closure dates.

#### Path B — presentation truncation marker

- **Where:** `services/api-python/app/pdf/outer_cards.py` aggregation step (likely in `build_outer_card` or `aggregate_display_windows`), and `services/api-python/app/templates/solar.html.j2` template for the outer-card intervals block.
- **Approach:** detect when an interval's `orb_exit_jd` equals the engine sample-window boundary (a known sentinel value, or equivalently the max `orb_exit_jd` observed across the full `annual_transit_table`), and render the interval text with a presentation marker:
  - Engine-displayed: «… - 28.01.2028 10:44 (GMT+3, окно truncated, sample horizon)».
  - Or: skip end-of-window rendering entirely with a footnote «(окно продолжается за пределы расчётного горизонта)».
- **Cost estimate:**
  - Engine touch: none.
  - Schema touch: none.
  - Test impact: 1 new test pinning the marker text; existing tests need tolerance widening or marker-aware comparison logic.
  - Effort: 0.5-1 day Worker.
- **Outcome:** Δ still present in raw numbers, but PDF text is honest. Marina sees engine truncation flagged as a presentation note rather than as a wrong cutoff date.

#### Worker recommendation

**Recommend Path A (engine sample horizon extension)** primarily, with Path B as defensive fence.

**Reasoning:**
1. Engine accuracy is preferable to presentation honesty when the engine **can** produce correct numbers. The cutoff is a configuration choice (sample horizon constant), not an inherent computational limit. Extending the horizon resolves the divergence at the root.
2. Phase 8A reveals the same risk pattern likely affects future Marina cards with multi-year outer loops (Pluto in particular). Path A future-proofs.
3. Path B is a workaround that introduces a presentation idiom Marina would have to learn to read («окно truncated»), and creates a UI surface that has no analogue in Marina's printed deck.
4. Phase 7 Stage B already established a discipline of «engine output is source of truth»; Path A maintains that. Path B adds a special-case in presentation.

**Defensive fence:** even after Path A lands, Phase 8B could optionally add Path B as a guard rail (mark windows whose `orb_exit_jd` reaches the new horizon as truncated) — to detect any case that **still** exceeds the extended horizon, instead of silently truncating in numbers.

**No code changes proposed/applied in this TASK.** Path A vs B vs hybrid decision lands in Phase 8B TASK ack.

### 4. Allowlist expansion — cases 01, 02, 03, 04, 09 (Tier C, repeatable Stage-B-pattern)

Per § A.2 above, all 5 cases have populated Marina reference outer cards but empty `OUTER_CARD_ALLOWLIST` entries.

| Case | Marina card count | Estimated allowlist entries + facts |
|---|---|---|
| 01-kseniya | 5 (Соляр 2024-2025.pdf — NB: previous year, may need year-aware fixture revision) | 5 triples + 5 `_OUTER_CARD_FACTS` entries |
| 02-maksim | 2 | 2 triples + 2 facts |
| 03-artem | 9 | 9 triples + 9 facts |
| 04-valeriya | 2 | 2 triples + 2 facts |
| 09-anastasiya | 2 (BUT **TYPE-D blocked** — see § A.3 TYPE-D item 2) | 2 triples + 2 facts (only after TYPE-D resolution) |

**Effort estimate per case:** ~2-4 hours Worker time (Marina pages typically 3-4 per card; transcribe to `_OUTER_CARD_FACTS` with psychology/event-level paraphrase per Phase 7 Stage B convention).

**Dependencies:**
- Case 09: TYPE-D SR-mismatch resolution first.
- Case 01: solar year is 2024-2025 (not 2025-2026 like the rest); fixture range may need extension or fixture year override.

**Acceptance pattern (Stage B style):** boundary assertions via Phase 8C helper added per case; Marina dates per case copied from new audit report sections § A.2.1.x (Phase 8B audit extension).

### 5. **TYPE-D data-quality follow-ups** — listing only

Per § A.3 TYPE-D items 1-2. **Not in Phase 8 scope.** Separate data-revision tasks:

- **`Соляр 2025-2026_3.pdf`** — fixture missing/mismatched. Needs:
  - Decision: create new fixture from Marina's stated SR (05.09.2025 09:16:30 UTC, Москва) + back-resolve natal data from page 1 Asc/MC info, OR exclude from package scope.
  - Action: independent overlay TASK with natal data verification step (Asc Скорпион + MC Дева as anchors).
- **Анастасия** — Δ ≈ 60 min in SR. Needs:
  - Decision: validate fixture's birth-time + timezone resolution against Marina's intended values.
  - Likely cause: DST or birth-time ambiguity (e.g. Russian summer time 2025-05 vs winter; or birth-place TZ at birth-year ≠ current TZ).
  - Action: independent overlay TASK that re-resolves `09-anastasiya-2025-2026` fixture's birth_time / timezone via Python's `timezonefinder` + manual verification against Marina's stated reference.

---

## Cross-references

- **Phase 8.0 reopen:** `project-overlays/astro/TASKS/archive/2026-05-14-phase-8-0-reopen-audit-trail.md`.
- **Phase 7 calibration report:** `project-overlays/astro/ARCHITECTURE/transit-multi-case-calibration-report-2026-05-13.md` § 1-6.
- **Architecture program:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md` § 6 + § 8.
- **Phase 4b semantics memo:** `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` § 4-6.

End of Phase 8A audit report.
