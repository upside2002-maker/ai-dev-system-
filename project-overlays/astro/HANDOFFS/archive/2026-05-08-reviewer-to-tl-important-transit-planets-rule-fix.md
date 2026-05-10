# HANDOFF: reviewer → TL — important-transit-planets-rule-fix

- Status: closed
- Date: 2026-05-08
- From: Reviewer (Claude Code subagent, separate session)
- To: TL
- Project: astro
- TASK: 2026-05-08-important-transit-planets-rule-fix
- Worker commit reviewed: 7b86cf9 (parent 7edbedb)
- Agent runtime: Claude Code (Reviewer subagent, separate from TL session and Worker session)
- Role mode: Reviewer (Mode strict — Tier A)

## Verdict

**ACCEPT**

## Summary

Worker's commit `7b86cf9` is a clean, atomic implementation of Marina's 5-rule methodology for `important_transit_planets`. The schema-gate cascade (bright line #8) is fully closed in a single commit covering Haskell ADT + logic + unit tests + JSON schema + TS types + 9 product fixtures + golden-test fixture + facts sample. All 9 cases verified by independent walk-through against natal charts: every planet's reasons trace to at least one valid rule (RulerOfAsc / RulerOfMc / KingOfAspects / RulerOfSunSign / RulerOfStelliumSign), dual-rulers correctly emit both planets for Aqu/Pis/Sco signs, dedup+accumulate works, and case 8 oracle is satisfied with Mercury+Sun+Jupiter present plus Venus(KingOfAspects) as engine-spec-strict extra. Tests re-run independently: `cabal test` 231/231, `pytest` 70/70.

## Acceptance criteria evaluation

### Behavioural invariants

| Criterion | Verdict | Evidence |
|---|---|---|
| `cabal build` green | PASS | `cabal test` ran from scratch; build succeeded as part of test execution. |
| `cabal test` green | PASS | Reviewer re-ran: `Finished in 0.0923 seconds; 231 examples, 0 failures` (was 229 baseline; +2 new tests). |
| `pytest 70/70` | PASS | Reviewer re-ran via `.venv/bin/python -m pytest`: `70 passed in 27.39s`. |
| Schema cascade complete in 1 commit | PASS | All 15 expected files present. See § Schema cascade atomicity. |
| `git log --oneline 7edbedb..HEAD` = exactly 1 commit | PASS | `7b86cf9 feat(core): rewrite important_transit_planets ...` — single commit. |
| Backup parity | PASS | `git ls-remote backup main` → `7b86cf9836b156d32f4dc40b34b47626c19ae966` (matches HEAD). |

### ADT correctness

| Criterion | Verdict | Evidence |
|---|---|---|
| Haskell ADT contains exactly 5 reasons | PASS | `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs:71-78` — `RulerOfAsc | RulerOfMc | KingOfAspects | RulerOfSunSign | RulerOfStelliumSign`. |
| JSON schema enum identical | PASS | `packages/contracts/solar-computed-facts.schema.json:332` — `["RulerOfAsc","RulerOfMc","KingOfAspects","RulerOfSunSign","RulerOfStelliumSign"]`. |
| TS union identical | PASS | `apps/web-react/src/types.ts:231-236` — same 5 string literals. |
| No "second ruler" reason types | PASS | Grep across hs/ts/json: no `SecondRulerOf*`, `RulerOf*Secondary`, etc. |

### Logic correctness

| Criterion | Verdict | Evidence |
|---|---|---|
| Existing 3 reasons preserved | PASS | All cases that previously had `RulerOfAsc/RulerOfMc/KingOfAspects` still have those planets in the new output (per per-case attribution table below). |
| 2 new reasons appear where applicable | PASS | `RulerOfSunSign` appears in cases 01,02,03,04,05,07,09,10 (every case has Sun); `RulerOfStelliumSign` appears in cases 01,02,03,07,08,09,10 (where ≥3-planet sign-stellium exists). |
| Dual-ruler for Aqu/Pis/Sco | PASS | Case 01 Asc=Aqu → Saturn+Uranus(RulerOfAsc), Sun=Sco → Pluto+Mars(RulerOfSunSign), stellium Sco → Pluto+Mars(RulerOfStelliumSign). Case 02 Asc=Sco → Pluto+Mars(RulerOfAsc). Case 03 MC=Aqu → Saturn+Uranus(RulerOfMc). Case 05 Asc=Aqu → Saturn+Uranus(RulerOfAsc), Sun=Pis → Jupiter+Neptune(RulerOfSunSign). Case 10 stellium Aqu → Saturn+Uranus(RulerOfStelliumSign). |
| Dedup | PASS | Inspected all 9 expected.json — no planet appears twice in any `important_transit_planets[]` array. |
| Accumulate reasons | PASS | Numerous examples: case 02 Mercury=[RulerOfMc,RulerOfSunSign]; case 03 Saturn=[RulerOfMc,RulerOfStelliumSign]; case 04 Venus=[RulerOfAsc,KingOfAspects]; case 05 Jupiter=[RulerOfMc,RulerOfSunSign]; case 07 Mercury=[RulerOfAsc,RulerOfMc]; case 08 Mercury=[RulerOfAsc,RulerOfMc]; case 09 Venus=[RulerOfMc,RulerOfSunSign,RulerOfStelliumSign] (3 reasons); case 10 Sun=[KingOfAspects,RulerOfSunSign]. |

### Oracle (Наталья case 8)

| Criterion | Verdict | Evidence |
|---|---|---|
| Mercury, Sun, Jupiter all present | PASS | `golden-cases/08-natalya-2025-2026.expected.json` `important_transit_planets`: Sun([RulerOfSunSign]), Mercury([RulerOfAsc,RulerOfMc]), Venus([KingOfAspects]), Jupiter([RulerOfStelliumSign]). |
| Each oracle planet rule-justified | PASS | Mercury: Asc=Virgo→Mercury (RulerOfAsc) AND MC=Gemini→Mercury (RulerOfMc); Sun: Sun-sign=Leo→Sun (RulerOfSunSign); Jupiter: Sagittarius hosts ≥3 planets (Moon+Uranus+Neptune)→ruler Jupiter (RulerOfStelliumSign). All match Marina ref Соляр_5.pdf p.7. |
| Extra Venus(KoA) acceptable | PASS | Independent KoA recompute on natal aspects: Venus=5 major aspects (max). Per User decision (A) engine-spec-strict, KoA always applies — extra rule-justified planet allowed. |

### Other 9 cases sanity

| Criterion | Verdict | Evidence |
|---|---|---|
| Each planet rule-justifiable in all cases | PASS | Per-case attribution table below. Every reason in every entry traces to a valid rule against the natal chart. |
| No unjustifiable random planet | PASS | Walk-through clean: 0 entries lack a valid rule. |

### Process invariants

| Criterion | Verdict | Evidence |
|---|---|---|
| Correction 008 applied | PASS | Worker HANDOFF § Process compliance documents `git status --short --branch` checked pre/post `git add -A`; commit consistency confirmed by `git log --oneline 7edbedb..HEAD` = 1 commit and no untracked product files in commit. |
| Mode strict (separate Worker + Reviewer subagents) | PASS | Worker subagent ran in separate session (HANDOFF dated 2026-05-08 23:16); Reviewer (this) running in fresh session, independent walkthrough. |
| Worker filled HANDOFF + submit | PASS | `2026-05-08-worker-to-tl-important-transit-planets-rule-fix.md` exists, complete, signed off. |
| Reviewer fills HANDOFF + verdict | PASS | This document. |
| TL accepts only on Reviewer ACCEPT | DEFERRED | TL action; Reviewer issues ACCEPT herein. |

## Embedded Reviewer checklist evaluation

### Independent re-verification

- [x] **Cabal build + cabal test green** — PASS. Reviewer re-ran `cd core/astrology-hs && cabal test`: 231/231 (`Finished in 0.0923 seconds; Test suite astrology-core-tests: PASS`). Includes T-B.7 SolarRoundtripSpec (parses + roundtrip + smoke), Domain.ImportantTransitPlanetsSpec (5 examples including 2 new for dual-ruler and sign-stellium), Golden.Solar.synthetic-solar-1.
- [x] **pytest 70/70 (after regen)** — PASS. Reviewer re-ran `services/api-python/.venv/bin/python -m pytest`: `70 passed in 27.39s`. All 5 test files green: `test_api.py` 13, `test_bridge.py` 8, `test_contracts.py` 3, `test_draft.py` 24, `test_golden_cases.py` 11, `test_storage.py` 11.
- [x] **git diff schema: enum has exactly 5 values** — PASS. `packages/contracts/solar-computed-facts.schema.json:329-333` — enum is `["RulerOfAsc","RulerOfMc","KingOfAspects","RulerOfSunSign","RulerOfStelliumSign"]`. Removed: `"InTenthHouse"`. Description updated to mention dual-ruler semantics.
- [x] **schema ↔ Haskell ADT ↔ TS types correspondence** — PASS. All three carry the identical 5-string set, in the same order in schema and TS, semantically identical in Haskell ADT (constructor order doesn't matter for JSON enum identity since `ToJSON`/`FromJSON` instances list the strings exactly).
- [x] **Roundtrip test (Test.Bridge.SolarRoundtripSpec) green** — PASS. The roundtrip test does parse → encode → parse and a smoke encode of `runSolar` output. It does not need source-level edits because the test is generic; the regenerated `solar-input-sample.json` (untouched per scope, since this is input not output) and the new shape of `SolarComputedFacts` flow through the existing assertions unchanged. Both the input parse and the output smoke encode pass under the new ADT.

### Logic correctness

- [x] **Existing 3 reasons preservation** — PASS. Case 02 Pluto(RulerOfAsc), case 03 Moon(RulerOfAsc), case 04 Saturn(RulerOfMc), case 05 Jupiter(RulerOfMc), case 07 Mercury(RulerOfAsc,RulerOfMc), case 09 Mercury(RulerOfAsc), case 10 Jupiter(RulerOfAsc) — Asc/MC ruler attributions intact. KingOfAspects observed in every case where applicable: Venus(c01), Moon(c02), Jupiter(c03), Venus(c04), Sun(c05/c07/c09/c10), Venus(c08).
- [x] **2 new reasons emission** — PASS. `RulerOfSunSign` emitted in 8/9 cases (every case where Sun is in a sign with a ruler — i.e., always), `RulerOfStelliumSign` in 7/9 cases (skipped only in cases 04 and 05 which lack a ≥3-planet sign-stellium per natal chart inspection).
- [x] **Dual-ruler for Aqu/Pis/Sco** — PASS. Case 01 (Asc=Aqu, Sun=Sco, stellium Sco): both Saturn+Uranus emit RulerOfAsc; both Pluto+Mars emit RulerOfSunSign+RulerOfStelliumSign. Case 02 (Asc=Sco): both Pluto+Mars emit RulerOfAsc. Case 03 (MC=Aqu): both Saturn+Uranus emit RulerOfMc. Case 05 (Asc=Aqu, Sun=Pis): both Saturn+Uranus emit RulerOfAsc; both Jupiter+Neptune emit RulerOfSunSign. Case 10 (stellium Aqu): both Saturn+Uranus emit RulerOfStelliumSign.
- [x] **Dedup**: PASS. Inspected each of 9 expected.json: no duplicate planet entries.
- [x] **Accumulate reasons**: PASS. Multi-reason entries in 8/9 cases (case 01 Venus, case 01 Mars, case 01 Pluto, case 02 Mercury, case 03 Saturn, case 04 Venus, case 05 Jupiter, case 07 Mercury, case 07 Moon, case 08 Mercury, case 09 Venus(3 reasons), case 10 Sun).

### Oracle (Наталья case 8)

- [x] **Mercury, Sun, Jupiter mandatory** — PASS. Present in `golden-cases/08-natalya-2025-2026.expected.json`.
- [x] **Rule-justifiable, not random** — PASS:
  - **Mercury**: `[RulerOfAsc, RulerOfMc]` — Asc=Virgo (ruled by Mercury), MC=Gemini (ruled by Mercury). Both rules accumulate on the same planet — exactly Marina's "Асц в Деве и МС в Близнецах" mapping.
  - **Sun**: `[RulerOfSunSign]` — Sun at 134.86° → Leo (ruled by Sun).
  - **Jupiter**: `[RulerOfStelliumSign]` — Sagittarius hosts Moon (263.15°), Uranus (249.58°), Neptune (268.95°) = 3 planets ≥ threshold → Jupiter (sole ruler of Sagittarius).
- [x] **Extra Venus(KoA) acceptable** — PASS. Independent natal-aspects recount: Venus = 5 major aspects in case-8 chart (max). KoA is an explicit 1st-class source per User decision (A) engine-spec-strict; extras are allowed when rule-justified.
- [x] **Reviewer rule attribution explicit**:
  - `Mercury` → `RulerOfAsc` (Asc=Virgo) + `RulerOfMc` (MC=Gemini)
  - `Sun` → `RulerOfSunSign` (Sun in Leo)
  - `Jupiter` → `RulerOfStelliumSign` (Sagittarius stellium of 3 planets)
  - `Venus` → `KingOfAspects` (5 major aspects, max in chart)

### Other 9 cases sanity

- [x] **No random planets in 1-5, 7-10** — PASS. Per-case table below.
- [x] **Each planet matches a rule** — PASS. Walk-through confirmed; zero unjustified entries.
- [x] **Reject criterion not triggered** — N/A (no failures).

### Scope discipline

- [x] **`git show --stat`: only expected files** — PASS. 15 files exactly:
  - `apps/web-react/src/types.ts` (TS union)
  - `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs` (ADT + logic)
  - `core/astrology-hs/test/Test/Domain/ImportantTransitPlanetsSpec.hs` (unit tests)
  - `core/astrology-hs/test/golden/synthetic-solar-1.expected.json` (golden regen)
  - `packages/contracts/solar-computed-facts.schema.json` (schema enum)
  - `packages/test-fixtures/golden-cases/{01,02,03,04,05,07,08,09,10}-*.expected.json` (9 product fixtures)
  - `packages/test-fixtures/solar-facts-sample.json` (cross-layer SOT fixture)
- [x] **PDF presentation untouched** — PASS. `git diff 7edbedb..7b86cf9 -- services/api-python/app/pdf/builder.py services/api-python/app/pdf/synthesis_themes.py` returns empty.
- [x] **PriorityWindows / SolarReportSkeleton / Directions untouched** — PASS. Confirmed by file list and per-file diff probe.
- [x] **No Lilith / Nodes / SouthNode** — PASS. ADT contains only the 5 specified reasons; no new domain modules introduced.

### Process

- [x] **1 atomic commit** — PASS. `git log --oneline 7edbedb..7b86cf9` = single commit.
- [x] **Backup parity** — PASS. `git ls-remote backup main` = `7b86cf9836b156d32f4dc40b34b47626c19ae966` = local HEAD.
- [x] **Correction 008 (git status check)** — PASS per Worker HANDOFF; commit cleanly captures only the expected 15 files.

## Schema cascade atomicity

| Surface | File | In commit 7b86cf9? |
|---|---|---|
| JSON schema enum | `packages/contracts/solar-computed-facts.schema.json` | YES (enum changed from 4 to 5 values, description updated) |
| Haskell ADT | `core/astrology-hs/src/Domain/ImportantTransitPlanets.hs` | YES (5 constructors + ToJSON/FromJSON) |
| Haskell roundtrip test | `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs` | NOT MODIFIED — and not needed (the spec is generic over input parsing and output smoke; the regenerated `solar-facts-sample.json` exercises the new schema implicitly via `cabal test`'s Golden.Solar suite). PASS as N/A: the contract doesn't require touching this spec when the change is purely additive at the JSON-string level. |
| Python contract test | `services/api-python/tests/test_contracts.py` | NOT MODIFIED — and not needed (test uses generic `len(reasons) >= 1` without hardcoded enum values; jsonschema validator picks up the new schema automatically). PASS as N/A. |
| TS types | `apps/web-react/src/types.ts` | YES (union 4→5 values, identical to schema and ADT) |
| 9 product fixtures | `packages/test-fixtures/golden-cases/{01,02,03,04,05,07,08,09,10}*.expected.json` | YES (all 9) |
| Bonus regen | `core/astrology-hs/test/golden/synthetic-solar-1.expected.json` + `packages/test-fixtures/solar-facts-sample.json` | YES (Worker correctly extended cascade to keep golden fixtures in sync — defensive but cascade-correct) |

`git -C /Users/ilya/Projects/astro show 7b86cf9 --stat` shows all of the above in a single commit. Cascade is atomic and complete.

## Case 8 oracle compliance

```json
"important_transit_planets": [
  { "planet": "Sun",     "reasons": ["RulerOfSunSign"] },
  { "planet": "Mercury", "reasons": ["RulerOfAsc", "RulerOfMc"] },
  { "planet": "Venus",   "reasons": ["KingOfAspects"] },
  { "planet": "Jupiter", "reasons": ["RulerOfStelliumSign"] }
]
```

Reviewer confirms:
- **Mercury, Sun, Jupiter** — mandatory minimum from Marina ref Соляр_5.pdf p.7 — all present with semantically correct reasons matching Marina's chart explanation (Asc=Дева & MC=Близнецы → Mercury × 2 rules; Sun=Лев → Sun; стеллиум в Стрельце → Jupiter).
- **Venus(KingOfAspects)** — engine extra, rule-justified by Venus = 5 major aspects in natal chart (independently verified by reviewing all natal aspects in `08-natalya-2025-2026.expected.json natal_chart.aspects`). Per User decision (A) engine-spec-strict, this is correct.
- **No unjustified planets**.

## Per-case rule-attribution

Reviewer independently extracted Asc/MC/Sun signs from each `expected.json natal_chart.house_systems.Placidus` and counted natal sign-stellia from `natal_chart.positions[].longitude`. KoA candidates verified by counting major aspects (Conjunction/Square/Trine/Opposition/Sextile) per planet in `natal_chart.aspects`. Reasons table:

| Case | Asc | MC | Sun | Stelliums (≥3) | KoA | Engine output → reasons | All rule-justified? |
|---|---|---|---|---|---|---|---|
| 01 Kseniya | Aqu (Uranus, Saturn) | Sag (Jupiter) | Sco (Pluto, Mars) | Libra(4), Scorpio(3) | Venus(4) | Venus[KoA, Stellium-Lib]; Mars[SunSign-Sco, Stellium-Sco]; Jupiter[Mc-Sag]; Saturn[Asc-Aqu]; Uranus[Asc-Aqu]; Pluto[SunSign-Sco, Stellium-Sco] | YES |
| 02 Maksim | Sco (Pluto, Mars) | Vir (Mercury) | Vir (Mercury) | Capricorn(3) | Moon(6) | Moon[KoA]; Mercury[Mc-Vir, SunSign-Vir]; Mars[Asc-Sco]; Saturn[Stellium-Cap]; Pluto[Asc-Sco] | YES |
| 03 Artem | Can (Moon) | Aqu (Uranus, Saturn) | Lib (Venus) | Capricorn(3) | Jupiter(7) | Moon[Asc-Can]; Venus[SunSign-Lib]; Jupiter[KoA]; Saturn[Mc-Aqu, Stellium-Cap]; Uranus[Mc-Aqu] | YES |
| 04 Valeriya | Tau (Venus) | Cap (Saturn) | Ari (Mars) | none | Venus(6) | Venus[Asc-Tau, KoA]; Mars[SunSign-Ari]; Saturn[Mc-Cap] | YES |
| 05 Ekaterina | Aqu (Uranus, Saturn) | Sag (Jupiter) | Pis (Neptune, Jupiter) | none | Sun(2) | Sun[KoA]; Jupiter[Mc-Sag, SunSign-Pis]; Saturn[Asc-Aqu]; Uranus[Asc-Aqu]; Neptune[SunSign-Pis] | YES |
| 07 Mariya | Vir (Mercury) | Gem (Mercury) | Can (Moon) | Cancer(3), Capricorn(3) | Sun(5) | Sun[KoA]; Moon[SunSign-Can, Stellium-Can]; Mercury[Asc-Vir, Mc-Gem]; Saturn[Stellium-Cap] | YES |
| **08 Natalya** | **Vir (Mercury)** | **Gem (Mercury)** | **Leo (Sun)** | **Sagittarius(3)** | **Venus(5)** | **Sun[SunSign-Leo]; Mercury[Asc-Vir, Mc-Gem]; Venus[KoA]; Jupiter[Stellium-Sag]** | **YES (oracle)** |
| 09 Anastasiya | Vir (Mercury) | Tau (Venus) | Tau (Venus) | Taurus(4) | Sun(5) | Sun[KoA]; Mercury[Asc-Vir]; Venus[Mc-Tau, SunSign-Tau, Stellium-Tau] | YES |
| 10 Danila | Sag (Jupiter) | Lib (Venus) | Leo (Sun) | Aquarius(3) | Sun(5) | Sun[KoA, SunSign-Leo]; Venus[Mc-Lib]; Jupiter[Asc-Sag]; Saturn[Stellium-Aqu]; Uranus[Stellium-Aqu] | YES |

**0 cases failed**, 9/9 PASS. Every entry's reasons list has at least one valid rule justification, and where multiple rules apply they accumulate correctly on a single planet entry.

## Worker's 5 flagged risks — cross-check

### Risk 1: TASK numbering error (case 9 vs case 8)

- **TL resolution**: Explicit. TASK file § Context line 200-201: "Marina reference chart fact matches `08-natalya-2025-2026.input.json`, не case 9 (Анастасия). Worker корректно идентифицировал и proceed'нул against case 8. TL принимает Worker'овскую интерпретацию (а), TASK ссылки исправлены."
- **Worker code consistency**: Worker oriented oracle verification against case 8 chart. The 4-planet output (Mercury,Sun,Venus,Jupiter) for case 8 is correct under Marina ref. Case 9 (Anastasiya) was also independently re-verified in this review (Asc=Vir/MC=Tau/Sun=Tau/stellium-Tau): Sun[KoA], Mercury[Asc], Venus[Mc, SunSign, Stellium] — all rule-justified, no oracle conflict.
- **Verdict**: Resolved. No rework needed.

### Risk 2: Venus(KingOfAspects) extra for case 8 — "exactly 3" vs engine-spec strict

- **TL resolution**: Explicit. TASK file § Context line 201: "«ровно 3 planets» переформулировано в «3 обязательных + extras allowed if rule-justified» (per User decision (A) engine-spec strict)." Acceptance criterion at line 122: "обязательным минимумом 3 planets ... Дополнительные planets допустимы, если каждая объяснима одним из 5 правил."
- **Worker code consistency**: Engine emits all 5 sources unconditionally (rule 3 KoA has no conditional clause). For case 8 KoA = Venus(5 aspects, max), so Venus appears as a 4th entry with `[KingOfAspects]`. This matches engine-spec-strict interpretation.
- **Verdict**: Resolved. Engine output correct.

### Risk 3: Marina-reference page numbering (TASK said p.8, content on p.7)

- **TL resolution**: Explicit. TASK file § Context line 210: "Marina reference: `Соляр 2025-2026_5.pdf` p. 7 — oracle для case 8 (Наталья). См. также TL spec correction note выше — оригинальная отсылка на «case 9» была numbering error."
- **Worker code consistency**: N/A — pure documentation pointer; doesn't affect code.
- **Verdict**: Resolved. Cosmetic/citation fix. No code impact.

### Risk 4: PDF presentation `builder.py` stale `_TRANSIT_REASON_RU` dict

- **TL resolution**: Explicit. TASK § Do not touch line 81: "PDF presentation: `services/api-python/app/pdf/{wheel,builder,direction_themes,...}.py` ... — НЕ трогать. Presentation update — отдельный Tier C TASK после accept." Worker HANDOFF Remaining § 1 documents the deferred follow-up.
- **Worker code consistency**: Worker honored the boundary; `git diff 7edbedb..7b86cf9 -- services/api-python/app/pdf/builder.py` returns empty. Reviewer confirms the residual `"InTenthHouse"` key in `builder.py:197` is dead code (engine no longer emits it; `dict.get(v, v)` fallback prevents runtime errors for the 2 new reasons). Acceptable for this TASK.
- **Verdict**: Out-of-scope by design. Tier C follow-up needed but not blocker for this commit.

### Risk 5: `Domain.Stellium` not used (sign-stellium grouping inlined)

- **TL resolution**: Implicit but consistent with TASK § Files line 50 `Stellium.hs (если необходимо ... иначе не трогать)`. `Domain.Stellium.detectStellia` operates on house-based grouping; sign-grouping is a different semantic. Worker inlined a 4-line sign-counter (`Map.Map ZodiacSign Int` via `foldl' Map.insertWith`) in `ImportantTransitPlanets.hs` lines 145-153.
- **Worker code consistency**: Inline approach is correct; doesn't pollute `Domain.Stellium`'s house-based semantic. If sign-stellia are needed elsewhere later, a separate cleanup task can hoist this into `Domain.Stellium.detectSignStellia`. Threshold (3) hard-coded as `stelliumSignThreshold` constant, well-named and matches house-stellia convention.
- **Verdict**: Architecturally sound. Minor: a future helper extraction would reduce duplication risk if a third caller appears, but acceptable as-is.

## Test results

### Cabal (Haskell core)
```
$ cd /Users/ilya/Projects/astro/core/astrology-hs && cabal test
...
Domain.ImportantTransitPlanets
  identifyImportantTransitPlanets
    returns Asc-ruler + MC-ruler + Sun-sign-ruler when 10th is empty and no aspects [✔]
    deduplicates: same planet picked for multiple reasons appears once with all reasons [✔]
    includes king-of-aspects when aspects are present [✔]
    emits BOTH rulers for dual-ruler signs (Asc=Aquarius → Uranus+Saturn under RulerOfAsc) [✔]
    emits ruler of stellium-sign when 3+ planets share one sign [✔]
...
Bridge.Solar
  Bridge.Solar (T-B.7)
    parses solar-input-sample.json fixture [✔]
    is roundtrip-stable: parse → encode → parse (Eq on input) [✔]
    runSolar produces an encodable SolarComputedFacts (smoke) [✔]
Golden.Solar
  synthetic-solar-1
    input fixture exists [✔]
    expected fixture exists [✔]
    runSolar reproduces the expected JSON output [✔]

Finished in 0.0923 seconds
231 examples, 0 failures
Test suite astrology-core-tests: PASS
```

### Pytest (Python services)
```
$ cd /Users/ilya/Projects/astro/services/api-python && .venv/bin/python -m pytest
============================= test session starts ==============================
collected 70 items

tests/test_api.py .............                                          [ 18%]
tests/test_bridge.py ........                                            [ 30%]
tests/test_contracts.py ...                                              [ 34%]
tests/test_draft.py ........................                             [ 68%]
tests/test_golden_cases.py ...........                                   [ 84%]
tests/test_storage.py ...........                                        [100%]

============================= 70 passed in 27.39s ==============================
```

Both green; matches Worker's claimed 231/231 + 70/70.

## Findings

### Blockers
**None.**

### Minor (non-blocking, advisory)
1. **PDF Russian translations stale (out-of-scope)**: `services/api-python/app/pdf/builder.py:197` still has `"InTenthHouse": "планета 10 дома"` (now dead) and lacks RU strings for `RulerOfSunSign` / `RulerOfStelliumSign`. New reasons render as ASCII identifiers via `dict.get` fallback. Already flagged in Worker HANDOFF § Remaining as a follow-up Tier C TASK; do-not-touch boundary respected here. Recommend the TL spawn that follow-up promptly to avoid PDF regression visible to Marina.
2. **Sign-stellium grouping inlined, not factored to `Domain.Stellium`**: Architectural minor. Worker correctly inlined sign-based grouping rather than overload `Domain.Stellium`'s house-based semantic. If a third consumer of sign-stellia appears later, hoisting to `Domain.Stellium.detectSignStellia` is the appropriate refactor — not blocker now.
3. **Roundtrip test (`Test.Bridge.SolarRoundtripSpec`) not modified**: TASK Files list line 54 says "обновить fixture или roundtrip expectation если нужно". Worker correctly assessed it doesn't need modification (test is generic over enum values), and it passes under the new ADT. Documenting here for transparency: this is N/A, not skipped.

### Nits
1. Worker HANDOFF § Done table line for case 09 has `Anastasia` (Latin); consistency would prefer `Anastasiya` (matching filename `09-anastasiya-2025-2026`). Cosmetic; no impact.
2. `Domain.ImportantTransitPlanets.hs` haddock at lines 36-39 lists "5 групп" but code-comment numbering reads 1,2,3,4,5 with KingOfAspects as #3 (between RulerOfMc and RulerOfStelliumSign), whereas Marina's TASK file lists KingOfAspects as #3 too — consistent. Just noting that the implementation is faithful to Marina's spec ordering.

## Recommendation to TL

**ACCEPT.** All bright-line #8 cascade requirements are met in single atomic commit `7b86cf9`. Schema/ADT/TS triple-source consistency verified. All 9 cases have rule-justifiable outputs verified by independent walk-through. Case 8 oracle (Mercury+Sun+Jupiter) satisfied with rule-correct attributions and an engine-spec-justified Venus(KoA) extra. Cabal 231/231 + pytest 70/70 reproduced by Reviewer.

Next steps for TL:
1. Run accept-helpers (TASK status → done; archive HANDOFFs).
2. Spawn the deferred Tier C TASK for PDF presentation refresh: update `services/api-python/app/pdf/builder.py:194-199` `_TRANSIT_REASON_RU` dict — remove dead `"InTenthHouse"` key, add Russian translations for `"RulerOfSunSign"` ("управитель знака Солнца" or similar) and `"RulerOfStelliumSign"` ("управитель знака стеллиума"). Suggested labels per Marina's vocabulary: `RulerOfSunSign → "управитель Вашего солнечного знака"`, `RulerOfStelliumSign → "управитель знака скопления планет"`.
3. Optional: an even-later cleanup TASK to factor sign-stellium grouping into `Domain.Stellium.detectSignStellia` if/when a second caller materializes.

This commit sets a clean precedent for Tier A in this product: bright-line #8 cascade closed atomically, scope discipline tight, oracle verified independently, no rework needed.
