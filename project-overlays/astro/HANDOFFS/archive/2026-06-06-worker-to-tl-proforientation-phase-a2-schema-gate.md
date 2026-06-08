# HANDOFF: worker → tl — proforientation-phase-a2-schema-gate

- Status: closed
- Date: 2026-06-06 (executed 2026-06-07)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker (strict, Tier A)
- TASK: project-overlays/astro/TASKS/2026-06-06-proforientation-phase-a2-schema-gate.md
- A1 HANDOFF: project-overlays/astro/HANDOFFS/archive/2026-06-06-worker-to-tl-proforientation-phase-a1-core-vocation.md
- A1 Reviewer HANDOFF: project-overlays/astro/HANDOFFS/archive/2026-06-06-reviewer-to-tl-proforientation-phase-a1.md
- Schema-gate model: project-overlays/astro/HANDOFFS/archive/2026-05-24-planet-returns-schema-gate.md (Phase C, 37db1c2)
- **Product repo status: committed (b7cf858 — astro main, all 5 artifacts + F1 in ONE commit)**

## Summary

Phase A2 of the proforientation epic — the **schema-change-gate (bright line #8)** for
a new **standalone `vocation` workflow**. The Phase A1 Core engine
(`Domain.Vocation.analyzeVocation`, product `7dc313e`, independent APPROVE) is now
carried across the process boundary: a greenfield contract pair + Bridge DTO + Main
dispatch + Haskell golden roundtrip + Python contract test + TS types. **All 5
artifacts + the A1 review's F1 dead-code cleanup landed in ONE atomic product commit
`b7cf858`.** solar/returns schemas / golden / fixtures bit-for-bit untouched;
`runSolar`/`runReturns` dispatch intact. **0 STOP triggers fired.**

Vocation is a **static natal analysis**: unlike solar/returns there is no time-series,
so the input carries NO `transit_samples` and NO `reference_jd` — just the resolved
natal chart (positions + Placidus cusps + meta). The output is machine factor keys
only — **no interpretation text** (stage 5 = Phase B).

## The 5 artifacts (paths) + F1

1. **Contracts** (greenfield; solar/returns schemas not touched):
   - `packages/contracts/vocation-input.schema.json`
   - `packages/contracts/vocation-output.schema.json`
2. **Bridge + dispatch**:
   - `core/astrology-hs/src/Bridge/Vocation.hs` (new)
   - `core/astrology-hs/app/Main.hs` (additive `vocation` dispatch)
   - `core/astrology-hs/astrology-core.cabal` (register `Bridge.Vocation` + `Test.GoldenVocation`)
3. **Haskell golden roundtrip**:
   - `core/astrology-hs/test/golden/vocation-sample.input.json`
   - `core/astrology-hs/test/golden/vocation-sample.expected.json`
   - `core/astrology-hs/test/Test/GoldenVocation.hs` (new) + `test/Spec.hs` wiring
4. **Python contract test**:
   - `packages/test-fixtures/vocation-sample.json` (mirror of expected output)
   - `services/api-python/tests/test_contracts.py` (3 new tests)
5. **TS types**:
   - `apps/web-react/src/types.ts` (`VocationComputedFacts` + sub-types)
- **F1 (A1 review finding):** `core/astrology-hs/src/Domain/Vocation.hs` — deleted the
  dead `planetsInHouse` (was defined, not exported, not used). Golden stays bit-identical
  (it was never on any code path); the A1 VocationSpec stays green.

## Locked-decision compliance

- **Standalone `vocation` workflow.** `app/Main.hs` dispatches on the input `workflow`
  field: `"solar"` → `runSolar` (unchanged), `"returns"` → `runReturns` (unchanged),
  `"vocation"` → new `runVocation`, unknown → exit 2 with clean stderr. Verified live
  (see below).
- **Input = static natal (no time-series).** `vocation-input` = `natal_positions` +
  `house_cusps` (Placidus, 12 cusps + Asc + MC; `dsc`/`ic` optional, engine-derived
  Asc+180 / MC+180 when absent) + `meta`. No `transit_samples`, no `reference_jd`. The
  engine only reads cusp longitudes (house rulers + placements), Asc (Asc ruler) and MC
  (elevation), so those are the load-bearing fields.
- **Output = combos + factor_table, no interpretation text.** `top_combinations` =
  `{planet, connected_houses, factor_keys, rank, score}` (≤ 3, rank 1-based); `factor_table`
  = the total ten-row per-planet realization (stage 1) + abilities (stage 2) rows with
  MACHINE keys. No prose anywhere (stage 5 = Phase B substitutes rules onto these keys).
- **DTO reuse, not duplication (Correction 001).** `Bridge.Vocation` imports
  `BridgePlanetPosition` + `BridgeMeta` from `Bridge.Solar`. No parallel records of the
  same meaning, and **zero changes to `Bridge.Solar`** this time (the house-cusps INPUT
  shape `BridgeHouseCuspsIn` is a genuinely new meaning — there is no existing input
  house-cusps DTO; the solar `BridgePlacidusResult` is an output-only projection that
  also emits a `"system"` const, so reusing it for input would be wrong). The
  `factor_table` rows reuse the existing `Domain.Vocation.PlanetFactors` ToJSON shape
  verbatim, so schema ↔ Bridge stay byte-consistent.
- **Field naming matches what Bridge ToJSON emits.** The expected fixture was generated
  from the actual CLI output and pretty-printed; the schemas were written to match it
  field-for-field (`factor`/`house` realization objects, snake_case ability keys,
  `<key>_<house>` flat combo factor_keys).

## Sample of runVocation output (from the golden expected fixture)

Fixture = Daragan's published worked example «Карта 11. Банкир» (the same chart anchored
cell-by-cell in the A1 golden).

```jsonc
// top_combinations — the ranked answer (Jupiter ruler-of-X в VIII at rank 1)
{ "planet": "Jupiter", "rank": 1, "score": 7,
  "connected_houses": [10, 2, 8],
  "factor_keys": ["ruler_of_house_10", "placed_in_house_8",
                  "conj_or_harmonic_to_ruler_of_2", "reception_with_ruler_of_8",
                  "reception_with_planet_in_house_of_10", "doryphoros",
                  "conj_or_harmonic_to_sun"] }
{ "planet": "Saturn",  "rank": 2, "score": 6, "connected_houses": [10, 2], ... }
{ "planet": "Venus",   "rank": 3, "score": 4, "connected_houses": [10, 8], ... }

// factor_table — total ten-row table; excerpt (Jupiter row, the densest)
{ "planet": "Jupiter", "realization_count": 5, "ability_count": 2, "total_count": 7,
  "realization": [ {"factor":"ruler_of_house","house":10},
                   {"factor":"placed_in_house","house":8},
                   {"factor":"conj_or_harmonic_to_ruler_of","house":2},
                   {"factor":"reception_with_ruler_of","house":8},
                   {"factor":"reception_with_planet_in_house_of","house":10} ],
  "abilities": ["doryphoros", "conj_or_harmonic_to_sun"] }
// Pluto row is fully empty (the A1 teaching point): realization [], abilities [], total 0.
```

This reproduces the A1 golden conclusion: top combo **Jupiter ruler-of-X в VIII**, then
Saturn, then Venus; Moon/Neptune (one column empty) and Uranus (empty realization) and
Pluto (both empty) excluded from combos but still present as factor_table rows.

## Verification (run from /Users/ilya/Projects/astro)

- **Haskell** (`cd core/astrology-hs && cabal build && cabal test`): build clean
  (0 warnings); **338 examples, 0 failures** (baseline 334 + 4 new vocation golden:
  input exists, expected exists, runVocation == expected, input parse→encode→parse
  stable). All existing solar/returns/vocation-A1 tests PASS with **0 edits** to any
  solar/returns golden/fixture, and the A1 VocationSpec stays green after the F1 deletion.
- **Python** (`.venv/bin/pytest tests/test_contracts.py -q`): **11 passed** (8 baseline +
  3 new: input check_schema, output check_schema, fixture validate + total-table /
  rank-order / no-prose / Jupiter-ruler-of-X semantics).
- **Frontend** (`apps/web-react && npx tsc --noEmit`): **clean (exit 0)**.
- Post-commit re-verification on committed state `b7cf858` (Correction 008): cabal 338/0,
  pytest test_contracts 11/11, tsc exit 0.

## Reviewer-Ready (Tier A schema-gate — independent Reviewer REQUIRED, Correction 021)

- **Atomicity — all 5 artifacts + F1 in ONE commit `b7cf858`** (`git show --stat`):

  ```
   apps/web-react/src/types.ts                        |  74 +++++
   core/astrology-hs/app/Main.hs                      |  25 +-
   core/astrology-hs/astrology-core.cabal             |   2 +
   core/astrology-hs/src/Bridge/Vocation.hs           | 317 +++++
   core/astrology-hs/src/Domain/Vocation.hs           |   5 -      (F1 dead-code removal)
   core/astrology-hs/test/Spec.hs                     |   2 +
   core/astrology-hs/test/Test/GoldenVocation.hs      |  74 +++++
   core/astrology-hs/test/golden/vocation-sample.expected.json |  261 +++++
   core/astrology-hs/test/golden/vocation-sample.input.json    |   27 ++
   packages/contracts/vocation-input.schema.json      | 107 +++++
   packages/contracts/vocation-output.schema.json     | 167 +++++
   packages/test-fixtures/vocation-sample.json        | 261 +++++
   services/api-python/tests/test_contracts.py        |  60 ++++
   13 files changed, 1374 insertions(+), 8 deletions(-)
  ```

- **Roundtrip green (independently):** Haskell golden vocation + input roundtrip (cabal
  test 338/0), Python contract (`jsonschema.validate` + `check_schema` ×2, pytest 11/11),
  `tsc --noEmit` clean.
- **Solar/returns untouched (git diff proof):**
  `git diff --stat 7dc313e b7cf858 -- 'packages/contracts/solar-*.schema.json'
  'packages/contracts/returns-*.schema.json' 'core/astrology-hs/test/golden/synthetic-solar-1.*'
  'core/astrology-hs/test/golden/returns-*' 'packages/test-fixtures/returns-sample.json'`
  → **empty** (bit-for-bit untouched). `Bridge.Solar` has **zero** changes this phase.
  `runSolar`/`runReturns` dispatch verified live (solar input → `workflow:"solar"`;
  returns input → `workflow:"returns"`; vocation input → `workflow:"vocation"`;
  `{"workflow":"bogus"}` → exit 2).
- **Schema ↔ Bridge ↔ TS consistency:** output `factor_table` rows
  (`planet, realization[{factor,house}], abilities[], realization_count, ability_count,
  total_count`) match `Domain.Vocation.PlanetFactors` ToJSON 1:1 and the TS `PlanetFactors`
  interface 1:1; `top_combinations` entries
  (`planet, connected_houses, factor_keys, rank, score`) match `BridgeVocationCombination`
  ToJSON 1:1 and the TS `VocationCombination` 1:1; the realization-factor-type enum and
  ability-factor enum are identical across schema / Bridge / TS; money-house numbers
  pinned to {10,2,6,8} in all three. The expected fixture was generated FROM the CLI
  output, so schema↔Bridge is verified by construction (the Python `jsonschema.validate`
  is the cross-check).
- **DTO reuse not duplication:** `Bridge.Vocation` imports `BridgePlanetPosition` +
  `BridgeMeta` from `Bridge.Solar`; `factor_table` rows reuse `PlanetFactors` ToJSON; the
  only new record is the input house-cusps shape (a new meaning). Zero `Bridge.Solar`
  edits (Correction 001).
- **F1 removed + golden bit-identical:** `planetsInHouse` deleted from `Domain/Vocation.hs`
  (−5 lines, the only Domain.Vocation change); cabal test green incl. the unchanged A1
  VocationSpec; vocation/solar/returns golden all bit-identical.
- **No interpretation text:** output carries only machine keys (snake_case factor tokens +
  numeric houses); the Python test asserts no spaces / lowercase on ability keys and
  numeric money-houses. Stage-1–4 logic unchanged (no stage 5).
- **0 STOP triggers.**

## Self-review checklist

- [x] All 5 artifacts + F1 in ONE product commit `b7cf858` (`git show --stat` above).
- [x] vocation golden roundtrip + input roundtrip pass (cabal 338/0).
- [x] solar/returns untouched: 0 edits to solar/returns schema/golden/fixtures (git diff
      empty); runSolar/runReturns dispatch intact (verified live).
- [x] input = natal+cusps (no samples, no reference_jd); output = combos + factor_table,
      no interpretation text.
- [x] BridgePlanetPosition/BridgeMeta reused; PlanetFactors ToJSON reused; no duplication;
      zero Bridge.Solar edits.
- [x] cabal build+test green (338/0), pytest test_contracts green (11/11), tsc clean.
- [x] F1 dead `planetsInHouse` removed; golden bit-identical.
- [x] No Phase-B scope creep (no Python sampler/endpoint; no UI/PDF beyond types.ts +
      test_contracts.py); no stage-5; no LLM.
- [x] Product committed (b7cf858); overlay committed (this HANDOFF + journal); backups
      pushed + parity.

## Notes / for TL attention

- **Optional `dsc`/`ic` on input.** The Vocation engine never reads dsc/ic, so the input
  schema makes them optional and the Bridge derives them (Asc+180 / MC+180) for the total
  `HouseCusps` record. The golden input fixture supplies them explicitly (so the optional
  roundtrip path is exercised); they roundtrip stably (omitted-when-absent ToJSON pattern,
  mirroring solar's optional-field handling). A producer may omit them.
- **`connected_houses` order** is Daragan's house-priority order (X, II, VI, VIII =
  10, 2, 6, 8), NOT numeric ascending — the schema description says so explicitly and the
  Python test only checks the value set, not the order.
- **Pre-existing working-tree noise** (`.claude/launch.json` modified; `_marina-deliverables/`,
  `marketing-site/`, `services/api-python/data/` untracked) was present at session start
  and deliberately NOT staged — the product commit contains exactly the 13 intended files.

## Next (not in this scope)

- Phase B: stage-5 interpretation rules (prose substituted onto these machine factor keys)
  + the proforientation section of the consultation PDF + UI panel; Python vocation
  endpoint + orchestration.
