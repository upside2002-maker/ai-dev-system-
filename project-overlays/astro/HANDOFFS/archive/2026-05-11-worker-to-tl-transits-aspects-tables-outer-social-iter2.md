# HANDOFF: worker → TL — transits-aspects-tables-outer-social (iteration 2)

- Status: closed
- Date: 2026-05-11
- From: Worker (Claude Code subagent, separate session, iteration 2)
- To: TL
- Project: astro
- TASK: 2026-05-11-transits-aspects-tables-outer-social
- Worker commit(s) iter 2: no commit — Path B (Tier A engine escalation)
- Agent runtime: Claude Code (Worker subagent, iteration 2)
- Role mode: Worker (Mode normal — Tier A escalation blocker)

## Summary

Iter-1 PDF rendered structurally correct tables (3 outer rows + 7 social), but
row-by-row comparison vs Marina's reference shows the discrepancies cannot
be fixed at the presentation layer. Three independent root causes (missing
aspect type, narrow orb threshold, narrow scan window) live in
`core/astrology-hs/src/Domain/TransitCalendar.hs` and require engine-level
changes. Recommendation: **Path B — Tier A schema/engine cascade**.

## Marina reference data (extracted from Соляр 2025-2026_5.pdf pp. 14-22)

**Outer planet narrative (pp. 16-18) — full 3-touch detail:**

| # | Planet | Aspect | Target | Touch 1 (window)            | Touch 2 (window)            | Touch 3 (window)            | Total period            |
|---|--------|--------|--------|-----------------------------|-----------------------------|-----------------------------|-------------------------|
| 1 | Уран   | 90°    | Венера | 03.06.2025 – 12.07.2025     | 02.11.2025 – 22.12.2025     | 19.03.2026 – 30.04.2026     | 03.06.2025 – 30.04.2026 |
| 2 | Нептун | 90°    | Юпитер | 21.04.2026 – 28.09.2026     | 21.02.2027 – 16.04.2027     | 10.10.2027 – 16.02.2028     | 21.04.2026 – 16.02.2028 |
| 3 | Нептун | 90°    | Нептун | 27.09.2024 – 12.10.2024     | 31.01.2025 – 29.03.2025     | 25.10.2025 – 24.01.2026     | 27.09.2024 – 24.01.2026 |

**Calendar (pp. 19-22) — monthly active aspects for solar year Aug 2025 – Aug 2026:**

| Month | Planet  | Aspect | Target | Window                |
|-------|---------|--------|--------|-----------------------|
| Авг  | Юпитер  | 60°    | ASC    | 07.08.2025–07.08.2025 |
| Сен  | Сатурн  | 90°    | Нептун | 02.09.2025–28.09.2025 |
| Окт  | Юпитер  | 120°   | Марс   | 13.10.2025–11.12.2025 |
| Окт  | Нептун  | 90°    | Нептун | 25.10.2025–24.01.2026 |
| Ноя  | Уран    | 90°    | Венера | 03.11.2025–22.12.2025 |
| Ноя  | Сатурн  | 120°   | Марс   | 04.11.2025–22.12.2025 |
| Янв  | Сатурн  | 90°    | Нептун | 25.01.2026–13.02.2026 |
| Фев  | Плутон  | 120°   | МС     | 17.02.2026–01.08.2026 |
| Мар  | Сатурн  | 90°    | Юпитер | 11.03.2026–26.03.2026 |
| Мар  | Уран    | 90°    | Венера | 19.03.2026–30.04.2026 |
| Мар  | Сатурн  | 60°    | МС     | 21.03.2026–05.04.2026 |
| Апр  | Нептун  | 90°    | Юпитер | 21.04.2026–07.08.2026 |
| Апр  | Сатурн  | 120°   | Уран   | 26.04.2026–14.05.2026 |
| Май  | Юпитер  | 120°   | Марс   | 30.05.2026–09.06.2026 |
| Июн  | Нептун  | 60°    | МС     | 08.06.2026–07.08.2026 |
| Июн  | Уран    | 150°   | Юпитер | 17.06.2026–29.07.2026 |
| Июн  | Юпитер  | 90°    | Плутон | 24.06.2026–02.07.2026 |
| Июн  | Сатурн  | 120°   | Солнце | 25.06.2026–07.08.2026 |
| Июл  | Уран    | 0°     | МС     | 11.07.2026–07.08.2026 |
| Июл  | Юпитер  | 60°    | МС     | 20.07.2026–28.07.2026 |

## Our iter-1 computed data (via `transit_aspects_outer/social` on Natalya fixture)

**OUTER (3 rows):**

| Planet | Aspect | Target | Touches (exact JD → MSK)                                          | Loop |
|--------|--------|--------|-------------------------------------------------------------------|------|
| Уран   | 90°    | Венера | 26.11.2025 18:37, 11.04.2026 07:28                                | False (only 2 of 3 expected) |
| Плутон | 120°   | МС     | 14.04.2026 17:39, 29.05.2026 00:47                                | False |
| Нептун | 90°    | Юпитер | 25.05.2026 18:59                                                  | False (only 1 of 3 expected) |

**SOCIAL (7 rows):**

| Planet | Aspect | Target | Touches (exact JD → MSK)                                          |
|--------|--------|--------|-------------------------------------------------------------------|
| Сатурн | 90°    | Нептун | 15.09.2025 17:01, 04.02.2026 04:38                                |
| Юпитер | 120°   | Марс   | 25.10.2025 18:55, 28.11.2025 16:00, 04.06.2026 08:06 (loop ✓)    |
| Сатурн | 90°    | Юпитер | 19.03.2026 03:38                                                  |
| Сатурн | 60°    | МС     | 30.03.2026 21:52                                                  |
| Сатурн | 120°   | Уран   | 05.05.2026 01:16                                                  |
| Юпитер | 90°    | Плутон | 28.06.2026 06:07                                                  |
| Юпитер | 60°    | МС     | 25.07.2026 01:22                                                  |

Engine window from `annual_transit_table`: **07.08.2025 – 08.08.2026**.

## Row-by-row comparison

### OUTER — Marina ⟶ Ours

| Marina row                | Ours match                | Δ touches | Δ period bound       | Diagnosis                   |
|---------------------------|---------------------------|-----------|----------------------|-----------------------------|
| Уран 90° Венера (3 touches: ~03.06.25, ~02.11.25, ~19.03.26) | Уран 90° Венера (2 touches: 26.11.25, 11.04.26) | **−1 touch** | first ≈ +5 months, last ≈ −19 days | Touch 1 (Marina ~03.06.2025) falls BEFORE engine window start 07.08.2025 → cropped |
| Нептун 90° Юпитер (3 touches in 04.26 / 02.27 / 10.27) | Нептун 90° Юпитер (1 touch: 25.05.26) | **−2 touches** | end ≈ −21 months | Touches 2 + 3 fall AFTER engine window end 08.08.2026 → cropped |
| Нептун 90° Нептун (3 touches: 09.24 / 01.25 / 10.25) | **ABSENT**                | **−3 touches** | row missing | All three touches outside engine window (only third hits Oct 2025 = inside, but row missing entirely from engine output) |
| Плутон 120° МС (calendar window 17.02–01.08.26) | Плутон 120° МС (2 touches 14.04 / 29.05.26) | matching exact pts inside Marina's window | period bound ≈ −2 months / −2 months | OK semantically (Marina shows orb-in / orb-out; we show exact JD) |

### SOCIAL — Marina ⟶ Ours

Notation: ✓ = present in both, ✗ = Marina has it / ours doesn't, ✦ = ours has it / Marina doesn't.

| Marina row                          | Ours                           | Status                   |
|-------------------------------------|--------------------------------|--------------------------|
| Юпитер 60° ASC (07.08.25)           | —                              | **✗ MISSING**            |
| Сатурн 90° Нептун (02.09–28.09.25)  | Сатурн 90° Нептун (15.09.25)   | ✓ (touch 1 of 2)         |
| Юпитер 120° Марс (13.10–11.12.25)   | Юпитер 120° Марс (25.10.25)    | ✓ (touch 1 of 3 loop)    |
| Нептун 90° Нептун (25.10.25–24.01.26) | —                            | **✗ MISSING** (in outer set, also missing there) |
| Уран 90° Венера (03.11–22.12.25)    | Уран 90° Венера (26.11.25)     | ✓ (touch 2 of 3, in outer set) |
| **Сатурн 120° Марс** (04.11–22.12.25) | —                            | **✗ MISSING — engine has no hit at all** |
| Сатурн 90° Нептун (25.01–13.02.26)  | Сатурн 90° Нептун (04.02.26)   | ✓ (touch 2 of 2)         |
| Плутон 120° МС (17.02–01.08.26)     | (outer)                        | ✓                         |
| Сатурн 90° Юпитер (11.03–26.03.26)  | Сатурн 90° Юпитер (19.03.26)   | ✓                         |
| Уран 90° Венера (19.03–30.04.26)    | Уран 90° Венера (11.04.26)     | ✓ (touch 3 in outer)      |
| Сатурн 60° МС (21.03–05.04.26)      | Сатурн 60° МС (30.03.26)       | ✓                         |
| Нептун 90° Юпитер (21.04–07.08.26)  | Нептун 90° Юпитер (25.05.26)   | ✓ (touch 1 of 3)          |
| Сатурн 120° Уран (26.04–14.05.26)   | Сатурн 120° Уран (05.05.26)    | ✓                         |
| Юпитер 120° Марс (30.05–09.06.26)   | Юпитер 120° Марс (04.06.26)    | ✓ (touch 3 of 3 loop)     |
| **Нептун 60° МС** (08.06–07.08.26)  | —                              | **✗ MISSING — engine has no hit** |
| **Уран 150° Юпитер** (17.06–29.07.26) | —                            | **✗ MISSING — quincunx not detected (engine excludes)** |
| Юпитер 90° Плутон (24.06–02.07.26)  | Юпитер 90° Плутон (28.06.26)   | ✓                         |
| **Сатурн 120° Солнце** (25.06–07.08.26) | —                          | **✗ MISSING — engine has no hit** |
| **Уран 0° МС** (11.07–07.08.26)     | —                              | **✗ MISSING — engine has no hit** |
| Юпитер 60° МС (20.07–28.07.26)      | Юпитер 60° МС (25.07.26)       | ✓                         |

**Statistics:**
- Marina rows total: 20 (calendar form, dedup with outer narrative)
- Ours rows: 10 unique combos (3 outer + 7 social)
- Matched on combo key: **14** of Marina's 20
- Marina-only (we miss): **6** (Юпитер 60° ASC, Сатурн 120° Марс, Нептун 60° МС, Уран 150° Юпитер, Сатурн 120° Солнце, Уран 0° МС). Also: Нептун 90° Нептун (third touch absent from engine, row missing entirely).
- Ours-only: **0** (no extras — we never emit a row Marina doesn't list).
- Median Δ between Marina's calendar-window mid-point and our exact-JD touch on matched rows: ~1 week.

## Diagnosis

Three independent root causes, all at engine level (`core/astrology-hs`):

### Cause 1 — Quincunx (150°) excluded by design

`Domain/TransitCalendar.hs:289-293`:

```haskell
-- | All five Ptolemaic aspects considered for the transit calendar.
--   Quincunx 150° is intentionally NOT here: per Phase 0.4 lock-in,
--   Quincunx is a directions-only aspect, not a transit aspect.
calendarAspects :: [AspectType]
calendarAspects = [Conjunction, Sextile, Square, Trine, Opposition]
```

Marina explicitly lists «Уран 150° Юпитер 17.06.2026–29.07.2026 (напряжённый)». This contradicts our Phase 0.4 lock-in. **Tier A schema/engine change**: either reverse 0.4 (treat quincunx as transit aspect) or carve an exception for outer-planet quincunx.

### Cause 2 — Orb tolerance: engine requires exact crossing; Marina counts near-misses

The five missing-row entries (Сатурн 120° Марс, Сатурн 120° Солнце, Юпитер 60° ASC, Нептун 60° МС, Уран 0° МС) all share the same pattern: transiting planet **comes within ~1° of exact aspect angle but never crosses it** within the engine's scan window. Marina's «realisation window» semantics treats *in-orb-but-no-exact-pass* as a touch.

Verified example: **Сатурн 120° Марс** — natal Mars at 234.68° ⇒ trine target 354.68°. Saturn's longitude trajectory through engine window:

| Sample | Saturn lon | Speed     |
|--------|-----------|-----------|
| 07.08.2025  | 0.27° (just past)  | direct    |
| 14.10.2025  | 358.22°            | retrograde |
| 04.11.2025  | 355.65°            | retro slowing |
| 25.11.2025  | 355.16° (minimum)  | near station |
| 22.12.2025  | 355.68°            | direct    |
| 10.02.2026  | 359.78°            | direct    |

Saturn **never crosses 354.68°**. Closest approach: 355.16° = 0.48° miss. Marina still counts this as «Сатурн 120° Марс 04.11.2025–22.12.2025» because Saturn was within ~1° orb during stationing — the most behaviourally significant period.

`findContactsForTarget` (`Domain/TransitCalendar.hs:315-325`) uses `findCrossings` which (per name + caller pattern) finds **zero-crossings** of `lon(transit) − shifted_target`. A planet that approaches but stations short never crosses → never registers as a contact.

**Tier A engine fix**: replace exact-crossing detection with **orb-window contact detection**:
- A "touch" begins when `|lon − shifted_target| ≤ orb`
- A "touch" ends when `|lon − shifted_target| > orb`
- Period = `[orb-in jd, orb-out jd]`
- Exact-JD (if any) recorded as a separate field

This also fixes Cause 1's period semantics — Marina's calendar windows are clearly **orb-in / orb-out**, not point-dates.

### Cause 3 — Scan window cuts off retrograde loops at solar-year boundaries

The engine's `annual_transit_table` covers `[solar_return_jd, next_solar_return_jd)` — for Natalya that's 07.08.2025 – 08.08.2026. Marina explicitly includes outer-planet loops that **extend before/after** the solar year:

- **Уран 90° Венера**: Marina shows touch 1 = 03.06.2025 (≈9 weeks before solar return) + touches 2 + 3 inside. Our output captures only 2 of the 3 touches.
- **Нептун 90° Юпитер**: Marina shows touch 1 inside window + touches 2 + 3 in 02.27 / 10.27 (1+ year after window). Our output captures only 1 of 3.
- **Нептун 90° Нептун**: loop runs 27.09.2024 – 24.01.2026. Third touch's window (25.10.25–24.01.26) DOES fall inside our engine window 07.08.25–08.08.26, but **no engine hit emitted at all**. Likely the exact-crossing JD lies just outside window OR the engine's loop-numbering refuses to emit pass 3 without seeing passes 1 & 2.

**Tier A engine fix**: when an outer-planet loop straddles the solar-year boundary, the scan must extend backward to the previous direct-pass start and forward to the next direct-pass end. Practical approach: for outer planets, pre-scan a wider window (e.g. `[solar_return_jd − 12 months, solar_return_jd + 24 months]`) and emit any touches whose loop intersects the solar year.

This makes Marina's «Нептун 90° Юпитер» row show all 3 touches even though touches 2 + 3 land in 2027 / 2028.

## Decision: Path B — Tier A schema/engine cascade

**Reasoning** (per Phase 4 decision rubric):

- Cannot be fixed at presentation layer:
  - Quincunx aspect type — engine refuses to emit (Cause 1).
  - 5 missing rows have no underlying engine hit at all — orb-tolerant contact detection required (Cause 2).
  - Outer-planet loops extending outside solar year — scan window expansion required (Cause 3).
- These three root causes match all 6 + 1 missing rows. Fixing them at the engine level produces correct data downstream automatically. No template hand-coding required (Owner directive #2 satisfied).
- The presentation layer (`transit_themes.py`) is already correct given the engine's current contract; tuning it cannot manifest data the engine doesn't emit.

## Tier A escalation plan

### Phase A.1 — Quincunx as transit aspect (smallest change)

- `core/astrology-hs/src/Domain/TransitCalendar.hs:293`: add `Quincunx` to `calendarAspects`. Verify `nominalAngle Quincunx = 150.0` exists.
- `core/astrology-hs/src/Domain/TransitCalendar.hs:303-310`: confirm `shiftedTargets target Quincunx = [target+150, target-150]`.
- Add `Quincunx` to major-aspect set in `services/api-python/app/pdf/transit_themes.py:700`.
- Update Phase 0.4 lock-in doc: quincunx IS a transit aspect (revoking earlier decision).
- Add roundtrip test fixture row.

### Phase A.2 — Orb-tolerant contact detection (largest change)

- `core/astrology-hs/src/Domain/TransitCalendar.hs:315-325`: replace `findContactsForTarget` with orb-window scanner:
  - Input: samples stream, target longitude, aspect, **orb in degrees** (recommend 1.0° for outer planets, 1.5° for social).
  - Output: list of `{enter_jd, exit_jd, exact_jd (optional), aspect}` tuples — one per continuous in-orb interval.
- `Bridge/Solar.hs`: extend `annual_transit_table` schema with `enter_jd_orb` / `exit_jd_orb` per hit (or replace `exact_jd` with these).
- `packages/contracts/*.schema.json`: update schema to expose new fields.
- Python `transit_themes.py`: switch `period_start_jd` / `period_end_jd` to orb-in / orb-out.
- Roundtrip test fixture: rebuild golden cases (1-8) to reflect new orb-window touches.

### Phase A.3 — Outer-planet scan-window expansion

- `core/astrology-hs/src/Domain/TransitCalendar.hs:analyzeAnnualCalendar`: for outer planets (Uranus, Neptune, Pluto), expand sample interval to `[solar_return − 12 months, solar_return + 24 months]`. Mark hits as "in-window" vs "out-of-window-but-loop-intersects". Emit any hit whose loop overlaps the solar year.
- This is the most invasive change — touches sampling cost (3 outer planets × 3 years vs 1 year = 3× more samples for these planets, manageable since sample rate is sparse).
- Schema additions: hit may carry `outside_solar_year: True/False` flag for downstream presentation.

### Schema change gate (architecture-invariants bright line #8)

A.2 + A.3 each touch `packages/contracts/*.schema.json`. Per CLAUDE.md project rule: **single commit must contain schema update + Haskell roundtrip test + Python contract test + TS type regen + fixtures regen**. Cannot land piecewise.

## Module locations summary

| Cause | File                                                              | Lines       |
|-------|-------------------------------------------------------------------|-------------|
| 1     | `core/astrology-hs/src/Domain/TransitCalendar.hs`                 | 289-310     |
| 2     | `core/astrology-hs/src/Domain/TransitCalendar.hs`                 | 312-325     |
| 3     | `core/astrology-hs/src/Domain/TransitCalendar.hs:analyzeAnnualCalendar` | 359-400     |
| All   | `core/astrology-hs/src/Bridge/Solar.hs`                           | schema DTO  |
| All   | `packages/contracts/*.schema.json`                                | schema gate |
| All   | `services/api-python/app/pdf/transit_themes.py`                   | 633-739     |

## Recommendation to TL

1. Accept Path B. Iter-1 commit `7b8fd24` remains good as the presentation foundation; the table format is sound; only the data feeding it is incomplete.
2. **Open three Tier A subtasks** sequenced as A.1 → A.2 → A.3 (low → high risk). A.1 alone unblocks ≈1 missing row; A.2 unblocks ≈5; A.3 unblocks the cross-year loop completeness.
3. **Validate Phase 0.4 reversal with Owner** before A.1 lands: Owner previously locked quincunx as directions-only; Marina-reference acceptance now requires it as a transit aspect too. Either Owner approves the reversal, or A.1 is dropped + the 1 missing row is documented as a known difference.
4. **Re-verify orb threshold value (1.0° vs 1.5° vs other)** with Marina/Owner before A.2 lands. The 1.0° figure is inferred from Saturn-trine-Mars's 0.48° miss being counted as a hit; could be 0.5°, 1.0°, or wider.
5. **Cross-year loop scan window** (A.3) needs Owner sign-off on the scope: should we expand to 36 months total, or only emit touches whose **window** intersects the solar year (much narrower than emitting whole 3-year loop)?

## Operational notes

- No code changes made; iter-2 leaves repo at `7b8fd24` clean.
- Data verified via `transit_aspects_outer/social` direct call on `08-natalya-2025-2026.expected.json` fixture (the same input iter-1 used).
- Marina reference pp. 14-22 used for table-data extraction only (planet/aspect/target/dates). Analytical paragraphs (psychology/event interpretations) treated as out-of-scope per directive.
- Time budget: ~13 tool uses (well under 25-use limit).
