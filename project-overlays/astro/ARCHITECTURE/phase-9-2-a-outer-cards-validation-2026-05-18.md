# Phase 9.2A — Outer Cards Filter Validation (Stage 0 gate)

Дата: 2026-05-18
Tier: C (analytical/empirical validation memo only — no product code, no tests, no PDF changes).
Source TASK: `project-overlays/astro/TASKS/2026-05-18-phase-9-2-a-outer-cards-filter-validation.md`.
Baseline: product main @ `941b78f` (Phase 9.4 β tests landed); overlay master @ `7c0602e` (TASK Ready: yes + 5 clarifications). Pytest baseline `372 passed + 2 skipped + 0 failed` (preserved — no test files written). Cabal: clean.

Cross-references:
- Memo Phase 9.0 (target file): `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` § 1.1 (Marina selections inventory), § 1.2 (per-case windows), § 1.3 (Ольга engine-emit context), § 2.2 (sub-problem B diff table), § 3.2 (hypothesis tests), § 5.2 (verdict «hybrid»), § 6 TASK 2 (filter proposal).
- Phase 9.1 erratum precedent (memo § 5.1 «hybrid/deterministic-leaning» superseded): same memo.
- Phase 9.4 erratum precedent (memo § 5.4 «deterministic 8/8» superseded): same memo.
- Filter target file (READ-ONLY for этой validation): `services/api-python/app/pdf/outer_cards.py:1656-1748` (`generic_outer_cards`).

---

## § 0. Validation framing

### § 0.1 Gate condition (per user direction 2026-05-18 + TASK clarification 3)

> «Significator supplement оставить как secondary check. Но это не должен быть gate для implementation. Gate только: `target ∉ angles` не drop'ает Marina-selected cards.»

**Gate criterion:** Hypothetical filter `target ∉ {Asc, MC, IC, DC}` applied to engine outer-card emit set MUST NOT drop any Marina-selected card в любом из 10 cases.

- **Filter may over-include** (false-positive count > 0 — engine output exceeds Marina selection) — acceptable per user direction.
- **Filter MUST NOT under-include** (false-negative count > 0 — Marina-selected card removed) — gate FAIL.

### § 0.2 Engine target naming convention (codebase verification)

Engine `Domain.TransitCalendar.TransitTarget` (core/astrology-hs/src/Domain/TransitCalendar.hs:79-94) emits **only 3 target shapes**:

```haskell
data TransitTarget
  = TargetNatalPlanet !Planet  -- serialized as the planet's name
  | TargetNatalAsc             -- serialized as "Asc"
  | TargetNatalMc              -- serialized as "MC"
```

Empirical consequence для filter scope: engine **never emits** `IC` or `DC` as outer-card targets. Filter `target ∉ {Asc, MC, IC, DC}` reduces empirically to `target ∉ {Asc, MC}`. The four-angle wording is robust to potential future extensions but operationally equivalent today.

### § 0.3 Sources used

- **Calibrated cases (01-10):** `OUTER_CARD_ALLOWLIST[case_id]` от `services/api-python/app/pdf/outer_cards.py:160-254`. By Phase 4 / 7b / 8D design the allowlist content IS Marina-curated selection (engine pre-filter emit set ≡ Marina selection by construction для calibrated path).
- **Non-calibrated 11-olga:** memo § 1.3 explicit engine-emit list (9 named triples + «~3+ unnamed Marina-rejected partial extract»; total stated «~13»). Marina selection (6 cards) from memo § 1.1 + § 1.3.
- **NO ad-hoc PDF re-extraction** (per user direction + STOP discipline).

### § 0.4 Inventory ambiguity disclosure (memo § 1.3 partial extract)

Memo § 1.3 explicitly states «**~13 unique aspect triples — partial extract from PDF**» for 11-olga: 9 named (Уран секст Меркурий, Уран кв МС, Уран кв Венера, Уран опп Уран, Уран опп Юпитер, Нептун кв АС, Нептун триг Юпитер, Нептун триг Уран, Плутон секст Уран) + «(some others Marina-rejected)»; total «~3+ Marina-rejected unnamed». Worker validates **only on the 9 named triples** — does not extrapolate beyond memo data. The Marina-rejected unnamed cards are explicitly not enumerated in any analytical source available to Worker per TASK STOP discipline («не извлекать заново из PDF»). This affects only the false-positive headcount (not the gate); it is documented as an inventory note in § 1 below.

---

## § 1. Per-case empirical table (Stage 0 mandatory gate)

Worker applies hypothetical filter `target ∉ {Asc, MC, IC, DC}` to engine outer-card emit set per case. Engine emit set = `OUTER_CARD_ALLOWLIST[case_id]` (calibrated 01-10) or memo § 1.3 named-triple list (11-olga, non-calibrated).

Symbols:
- **Engine emit count** — number of unique `(transit_planet, aspect, target)` triples emitted by engine before filter.
- **Marina-selected count** — number of cards Marina shows in her PDF (per memo § 1.1).
- **Filter output count** — engine emit count minus angle-targeted triples (`target ∈ {Asc, MC}` is the effective constraint per § 0.2).
- **FN (false negative)** — Marina-selected cards filter drops. **Gate criterion = 0 FN total.**
- **FP (false positive)** — filter-output cards NOT in Marina selection. Informational only.
- **Verdict:** `match` (filter output = Marina selection); `over-include` (filter keeps more than Marina but drops none); `drop` (filter removes Marina-selected card → gate FAIL).

| case_id | engine emit | Marina-selected | filter output | FP count | FN count | FP list | FN list | verdict |
|---|---|---|---|---|---|---|---|---|
| 01-kseniya-2024-2025 | 5 | 5 | 5 | 0 | 0 | — | — | match |
| 02-maksim-2025-2026 | 2 | 2 | 2 | 0 | 0 | — | — | match |
| 03-artem-2025-2026 | 9 | 9 | 9 | 0 | 0 | — | — | match |
| 04-valeriya-2025-2026 | 2 | 2 | 2 | 0 | 0 | — | — | match |
| 05-ekaterina-2025-2026 | 3 | 3 | 3 | 0 | 0 | — | — | match |
| 07-mariya-2025-2026 | 0 (allowlist `[]`) | 0 | 0 | 0 | 0 | — | — | match (empty) |
| 08-natalya-2025-2026 | 3 | 3 | 3 | 0 | 0 | — | — | match |
| 09-anastasiya-2025-2026 | 2 | 2 | 2 | 0 | 0 | — | — | match |
| 10-danila-2025-2026 | 3 | 3 | 3 | 0 | 0 | — | — | match |
| 11-olga (non-calibrated) | 9 named (~13 stated) | 6 | 7 (named filter output; +4 unnamed-rejected per § 0.4) | 1 named (Уран секст Меркурий) + ~3 unnamed | 0 | Уран секст Меркурий (planet-target; Marina-rejected per memo § 2.2) | — | over-include |

### § 1.1 Per-case derivation (calibrated 01-10)

For calibrated cases the allowlist branch in `outer_cards_for_case` (services/api-python/app/pdf/outer_cards.py:1812-1822) uses the curated list directly without invoking `generic_outer_cards`. The hypothetical filter `target ∉ angles` is therefore applied conceptually to the allowlist content to test «if generic-rule were to drive calibrated cases, would it preserve them?»

All allowlist targets across cases 01/02/03/04/05/08/09/10 are **personal/social/outer planets**, never `Asc`/`MC` (verified by reading outer_cards.py:166-253):

- **01:** Sun, Uranus, Sun, Mars, Jupiter — 5 planet-targets.
- **02:** Pluto, Uranus — 2 planet-targets.
- **03:** Sun, Mercury, Mars, Sun, Mercury, Mars, Uranus, Sun, Mars — 9 planet-targets (4 unique target planets).
- **04:** Saturn, Pluto — 2 planet-targets.
- **05:** Moon, Jupiter, Jupiter — 3 planet-targets.
- **07:** empty allowlist (Marina explicit «нет аспектов от высших планет», `[]` literal).
- **08:** Venus, Jupiter, Neptune — 3 planet-targets.
- **09:** Mercury, Mercury — 2 planet-targets.
- **10:** Moon, Venus, Jupiter — 3 planet-targets.

⇒ For all 9 non-empty calibrated cases: filter is a no-op (0 FN, 0 FP). Case 07 is trivial (empty in, empty out, 0 FN, 0 FP).

### § 1.2 Per-case derivation (11-olga, non-calibrated)

Engine emit set per memo § 1.3 (9 named + ~3-4 unnamed partial extract):

| # | engine emit triple | target | target type | Marina selected? | filter keeps? | classification |
|---|---|---|---|---|---|---|
| 1 | Уран секст Меркурий | Mercury | planet | NO (per § 2.2) | YES | FP |
| 2 | Уран кв МС | MC | angle | NO (per § 2.2) | NO | TN |
| 3 | Уран кв Венера | Venus | planet | YES (§ 1.1) | YES | TP |
| 4 | Уран опп Уран | Uranus | planet | YES (§ 1.1) | YES | TP |
| 5 | Уран опп Юпитер | Jupiter | planet | YES (§ 1.1) | YES | TP |
| 6 | Нептун кв АС | Asc | angle | NO (per § 2.2) | NO | TN |
| 7 | Нептун триг Юпитер | Jupiter | planet | YES (§ 1.1) | YES | TP |
| 8 | Нептун триг Уран | Uranus | planet | YES (§ 1.1) | YES | TP |
| 9 | Плутон секст Уран | Uranus | planet | YES (§ 1.1) | YES | TP |

**Named-set summary:** TP=6, TN=2, FP=1, FN=0. Filter drops 2 of 9 named (both angle-targets, both Marina-rejected → correct drops).

**Unnamed partial extract:** memo § 1.3 states ~3+ additional Marina-rejected triples без specific target enumeration. Worker cannot classify each individually without ad-hoc PDF re-extraction (forbidden per STOP discipline). The unnamed cards add to the FP count if their targets are planets, or to TN if angles. Since memo § 1.3 says they are «Marina-rejected», none contribute to FN regardless of target type.

⇒ For 11-olga: **0 FN confirmed** (all 6 Marina-selected cards are planet-targets and the filter keeps them). FP count ≥ 1 (named) + ≤ 4 (unnamed) = `1–5` over-include. Acceptable per gate criterion.

### § 1.3 Inventory verification per Marina-selected card target

Direct check that every Marina-selected card across all 10 cases has a non-angle target:

| Case | Marina-selected cards (target only) | Any target ∈ {Asc, MC, IC, DC}? |
|---|---|---|
| 01 | Sun, Uranus, Sun, Mars, Jupiter | no |
| 02 | Pluto, Uranus | no |
| 03 | Sun, Mercury, Mars, Sun, Mercury, Mars, Uranus, Sun, Mars | no |
| 04 | Saturn, Pluto | no |
| 05 | Moon, Jupiter, Jupiter | no |
| 07 | (none) | n/a |
| 08 | Venus, Jupiter, Neptune | no |
| 09 | Mercury, Mercury | no |
| 10 | Moon, Venus, Jupiter | no |
| 11 | Venus, Uranus, Jupiter, Jupiter, Uranus, Uranus | no |

**Aggregate:** 0/35 Marina-selected cards have angle-target (29 calibrated + 6 Ольга). 100% planet-target across all Marina-selected. ⇒ Filter `target ∉ angles` cannot drop any Marina-selected card by construction.

---

## § 2. Aggregate score

**Gate condition (per user direction 2026-05-18):** filter yields 0 false negatives across all 10 cases.

| metric | value | gate? |
|---|---|---|
| Cases analyzed | 10 (01, 02, 03, 04, 05, 07, 08, 09, 10, 11-olga) | — |
| Total Marina-selected cards | 35 (29 calibrated + 6 Ольга) | — |
| Marina-selected cards with angle-target | 0 / 35 | PASS-relevant |
| **Total FN (filter drops Marina-selected)** | **0 / 35** | **PASS** |
| Total FP (filter keeps non-Marina) | 1 named (Olga: Уран секст Меркурий) + up to 4 unnamed | — informational |
| Per-case verdict «drop» count | 0 / 10 | PASS |
| Per-case verdict «match» count | 9 / 10 (01, 02, 03, 04, 05, 07, 08, 09, 10) | — |
| Per-case verdict «over-include» count | 1 / 10 (11-olga) | acceptable per user direction |

**Stage 0 gate condition (no Marina-selected drops) = SATISFIED.**

Note: «match» for calibrated 01-10 is structural (allowlist == Marina). For 11-olga «over-include» means filter keeps 7 named cards (engine 9 named − 2 angle-targets) versus Marina's 6 — 1 named FP (Уран секст Меркурий, Mercury target) plus an unbounded unnamed remainder per § 0.4. FP-reduction is **not gate-relevant** per user direction.

---

## § 3. Significator-supplement diagnostic (informational, NOT gate)

Per user direction 2026-05-18 + TASK clarification 3: significator-set hypothesis is diagnostic for false-positive structure, **NOT** a gate criterion. Worker computes it for understanding only; **§ 4 verdict is independent**.

### § 3.1 Significator-set definition (per memo § 6 TASK 2 proposal)

For each case, significator set = `{Asc-ruler, MC-ruler, 1st-house planets, Sun-sign ruler, stellium-ruler}` per memo § 6 TASK 2 step 2. Worker computes Olga's significator set from `consultation-11.facts.json` natal positions + house cusps (engine-emitted facts — no Marina-PDF re-extraction):

For 11-olga:
- Cusps: 1=94.15° (Cancer 4°), 4=143.31° (Leo 23°), 7=274.15° (Capricorn 4°), 10=323.31° (Aquarius 23°).
- Asc-ruler = Cancer ruler = **Moon**.
- MC-ruler = Aquarius ruler (modern) = **Uranus** (classical Saturn — modern preferred by Marina per memo § 5.2).
- 1st-house planets: Mars (lon=99.86° between cusp 1=94.15° and cusp 2=108.33°) ⇒ **Mars**.
- Sun-sign: Sun at 111° = Cancer 21° ⇒ Cancer ruler = **Moon** (duplicates Asc-ruler).
- Stellium: house 6 carries 3 planets (Jupiter, Uranus, Neptune); cusp 6 = 224.85° = Scorpio 14° ⇒ Scorpio ruler (modern) = **Pluto**.

⇒ Significator-set Olga = {Moon, Uranus, Mars, Pluto}.

Per memo § 5.2 + memo § 6 TASK 2 step 3: combined rule = «target ∈ significator-set OR target ∈ {Uranus, Neptune, Pluto} (outer-outer)» → extended set = {Moon, Mars, Uranus, Neptune, Pluto}.

### § 3.2 Hypothetical both-rules combination test (Olga only)

Hypothesis: filter = `target ∉ angles AND (target ∈ significator-set OR target ∈ {U, N, P})`. Apply to 11-olga 9 named engine emit:

| # | engine emit triple | target | target ∉ angles? | target ∈ ext-sig-set? | combined filter keeps? | Marina selected? | classification |
|---|---|---|---|---|---|---|---|
| 1 | Уран секст Меркурий | Mercury | YES | NO (Mercury ∉ ext-sig) | NO | NO | TN (combined) — significator removes named FP |
| 2 | Уран кв МС | MC | NO | n/a | NO | NO | TN |
| 3 | Уран кв Венера | Venus | YES | NO (Venus ∉ ext-sig) | NO | YES | **FN** (combined-rule drops Marina-selected) |
| 4 | Уран опп Уран | Uranus | YES | YES | YES | YES | TP |
| 5 | Уран опп Юпитер | Jupiter | YES | NO (Jupiter ∉ ext-sig) | NO | YES | **FN** (combined drops Marina-selected) |
| 6 | Нептун кв АС | Asc | NO | n/a | NO | NO | TN |
| 7 | Нептун триг Юпитер | Jupiter | YES | NO | NO | YES | **FN** |
| 8 | Нептун триг Уран | Uranus | YES | YES | YES | YES | TP |
| 9 | Плутон секст Уран | Uranus | YES | YES | YES | YES | TP |

**Combined-rule false-negative count on Olga = 3** (Уран кв Венера; Уран опп Юпитер; Нептун триг Юпитер). All three are Marina-selected planet-target cards that the significator-supplement would drop because Venus and Jupiter are not in Olga's `{Moon, Mars, U, N, P}` extended significator set.

### § 3.3 Diagnostic interpretation

The significator-set definition from memo § 6 TASK 2 step 2 (Asc-ruler / MC-ruler / 1st-house / Sun-sign / stellium-ruler), when applied with the outer-outer extension, **drops 3 of 6 Marina-selected outer cards для Olga**. This reproduces the Phase 9.1 family pattern (memo erratum 2026-05-17): memo-proposed significator-style rules over-prune empirical Marina selections.

This is **diagnostic only** per user direction 2026-05-18. Implications:

- The significator-set definition as memo-proposed is **insufficiently inclusive** to fit Marina's outer-card selection — Marina includes Venus and Jupiter targets for Olga despite neither being Asc/MC/1st-house/Sun-sign/stellium ruler.
- Possible expansions Marina may use (untested per STOP discipline, NOT proposed as filter changes): «king-of-aspects» lexical markers in Marina's PDF text («Транзиты Юпитера — король аспектов»); per-natal-house significance weight; per-target classical-importance hierarchy (social planets Jupiter/Saturn often included unconditionally).
- For non-Olga cases the significator computation requires per-case natal data Worker did not extract (out of TASK scope). Calibrated cases (01-10) are not analyzed for significator-set fit because the calibrated allowlist branch is unaffected by `generic_outer_cards` regardless of filter content.

**FP-reduction count для Olga (combined vs angle-only):** combined drops Уран секст Меркурий (1 named FP eliminated) at cost of 3 Marina-selected drops. **Net effect = worse fit**, consistent with Phase 9.1 lesson against silent rule complication.

**Diagnostic does NOT change § 4 verdict.** Gate is angle-exclusion alone per user direction.

---

## § 4. Verdict

### § 4.1 Stage 0 gate outcome

| criterion | result |
|---|---|
| Filter drops any Marina-selected card across 10 cases? | **NO** (0 FN / 35 Marina-selected) |
| All Marina-selected card targets are non-angle? | **YES** (35 / 35 planet-targets) |
| Calibrated path (01-10) affected by filter? | NO (allowlist branch unaffected; filter operates on `generic_outer_cards` only) |
| Non-calibrated 11-olga: filter preserves Marina-6? | **YES** (all 6 Marina-selected pass) |
| Filter over-includes non-calibrated case? | YES (Olga: ≥1 named FP «Уран секст Меркурий» + up to 4 unnamed) — informational, not gate |

### § 4.2 Verdict

**Stage 0 = PASS.**

`target ∉ {Asc, MC, IC, DC}` filter yields **10/10 cases without false negatives** against Marina-selected sets per memo § 1.1 / § 1.2 / § 1.3 inventory.

Memo § 5.2 verdict «hybrid» is empirically supported **specifically для the angle-exclusion deterministic component** (Rule B1 per memo § 5.2): «Target must be a planet, NOT an angle (AC/MC/IC/DC). Angle-targets get monthly-calendar treatment, не deep-dive cards.» — confirmed по inventory data Worker had access to.

**Memo § 5.2 verdict is NOT downgraded by this validation.** Worker is NOT proposing erratum to memo § 5.2 (per STOP discipline: erratum only on FAIL).

### § 4.3 Significator-supplement deferral (per user direction)

Memo § 5.2 Rule B2 («per-client significator weighting») is **NOT validated by Stage 0 gate** and remains in the «editorial / per-case curation» bucket per user direction. Significator-supplement diagnostic (§ 3) shows the memo-proposed definition drops 3 of 6 Marina-selected cards для Olga, replicating Phase 9.1 over-pruning pattern. **No significator filter is proposed for Phase 9.2B implementation.**

---

## § 5. Recommended next step

### § 5.1 PASS → Phase 9.2B implementation TASK draft outline

Per user direction 2026-05-18 (clarification 3) + Stage 0 PASS verdict: Worker recommends draft outline для Phase 9.2B implementation TASK. Per TASK 9.2A scope discipline («NO implementation в этом TASK; that's 9.2B») — outline only, no code.

**Phase 9.2B — Outer-card target-not-angle filter implementation (deterministic, angle-only scope).**

- **Tier proposal:** B (1 file modification + 1-2 test additions; no schema; no fixtures; no allowlist change).
- **Layer:** Services (Python).
- **Target files (proposal):**
  - `services/api-python/app/pdf/outer_cards.py` — single-line filter в `generic_outer_cards` iteration body (line ~1709 in current HEAD `941b78f`).
  - `services/api-python/tests/` — 1-2 new tests pinning angle-target exclusion для non-calibrated fixture (Olga 11-style if available, or synthetic).
- **Scope outline (proposed for 9.2B):**
  1. Define `_OUTER_CARD_ANGLE_TARGETS: frozenset[str] = frozenset({"Asc", "MC"})` constant в `outer_cards.py`. (Note empirically only 2 angle keys engine emits per § 0.2; «IC»/«DC» absent. Define-as-set keeps wording «target ∉ angles» without false reassurance.)
  2. In `generic_outer_cards` iteration filter (lines ~1702-1713 в HEAD `941b78f`), add condition: skip triples where `tgt ∈ _OUTER_CARD_ANGLE_TARGETS`.
  3. Allowlist branch (`outer_cards_for_case` lines ~1812-1822) **unchanged** — Phase 4 / 7b / 8D calibrated invariant preserved.
  4. Add 1 new test: render generic-fallback path с synthetic facts containing both planet-target and angle-target outer triples; assert filter output excludes angle-targets.
  5. Optional: 1 regression test pinning Olga-style fixture if `case_label=None` test data exists in tests/.
- **Acceptance (proposed):**
  - `generic_outer_cards` output strips angle-target triples; planet-target triples preserved.
  - All 9 non-empty calibrated cases unchanged (`outer_cards_for_case` allowlist branch unaffected; verified by existing test suite).
  - Pytest baseline 372/2/0 + new test(s) pass.
  - Cabal: no Haskell change.
- **Significator-supplement (memo § 5.2 Rule B2):** deferred OR documented as editorial residual в comment block в `outer_cards.py`. NOT shipped as filter in 9.2B per user direction. Re-validation gate analogous этой 9.2A required если future TASK proposes значимый significator rule.

### § 5.2 Erratum status (per user direction 5)

**Stage 0 PASS** ⇒ Worker does NOT draft erratum for memo § 5.2. Memo § 5.2 stands as written (verdict «hybrid», TASK 2 proposal). Phase 9.2B implementation TASK will narrow scope per § 5.1 (angle-only, significator deferred).

Если Phase 9.2B implementation hits an empirical surprise (e.g., calibrated test regression), erratum для memo § 5.2 may be drafted at that point — но not by этой 9.2A TASK.

---

## Appendix A — Files inspected (read-only)

- `services/api-python/app/pdf/outer_cards.py` lines 160-254 (OUTER_CARD_ALLOWLIST), 271-284 (`_PLANET_INSTR_RU` — angle keys verified), 1388-1390 (`_GENERIC_OUTER_ASPECTS`), 1415-1453 (helpers), 1656-1748 (`generic_outer_cards`), 1754-1828 (`outer_cards_for_case`).
- `core/astrology-hs/src/Domain/TransitCalendar.hs` lines 79-94 (`TransitTarget` ADT — confirms only `Asc`/`MC` angle targets emitted), 115-194 (TransitContact / AnnualTransitEntry / AnnualCalendar), 559-606 (engine target iteration), 624-660 (`analyzeAnnualCalendar`).
- `data/pdf/consultation-11.facts.json` (Olga natal positions + cusps used для § 3 significator-set computation only).

**NO product code modified.** **NO tests written.** **NO PDFs re-extracted.** **NO `OUTER_CARD_ALLOWLIST` / `_OUTER_CARD_FACTS` / engine / schema / fixtures touched.**

## Appendix B — Worker scope discipline

- ✓ Read TASK spec + 5 clarifications fully.
- ✓ Read CLAUDE.md + architecture-invariants.md + corrections.md + CLAUDE_GLOBAL.md.
- ✓ Read memo § 1.1 / § 1.2 / § 1.3 / § 2.2 / § 3.2 / § 5.2 / § 6.
- ✓ Read Phase 9.1 erratum + Phase 9.4 erratum precedents.
- ✓ Inspected `outer_cards.py` + `TransitCalendar.hs` (read-only).
- ✓ NO ad-hoc Marina PDF re-extraction.
- ✓ NO scope creep: significator-supplement kept strictly diagnostic per user direction.
- ✓ NO filter rule modification temptation (gate = `target ∉ angles` strict).
- ✓ Pytest baseline 372/2/0 preserved (no test files added or modified).
- ✓ Cabal clean (no Haskell change).
- ✓ Product `git status --short` empty before + after analysis.
- ✓ Stage 0 PASS does NOT trigger erratum drafting (erratum is FAIL-only per user direction 5).
