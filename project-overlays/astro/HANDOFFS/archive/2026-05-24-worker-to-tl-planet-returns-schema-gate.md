# HANDOFF: worker → tl — planet-returns-schema-gate

- Status: closed
- Date: 2026-05-24 (executed 2026-06-05)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker (strict, Tier A)
- TASK: project-overlays/astro/TASKS/2026-05-24-planet-returns-schema-gate.md
- Memo: project-overlays/astro/ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md (§ 5 / § 6)
- **Product repo status: committed (37db1c2 — astro main, all 5 artifacts in ONE commit)**

## Summary

Phase C of the planet-returns epic — the **schema-change-gate (bright line #8)** for
a new **standalone `returns` workflow**. The Phase B Core engine
(`Domain.Returns.findNearestReturns`, product `a1e0c75`, closed) is now carried across
the process boundary: a greenfield contract pair + Bridge DTO + Main dispatch + Haskell
golden roundtrip + Python contract test + TS types. **All 5 artifacts landed in ONE
atomic product commit `37db1c2`.** Solar schema / golden / fixtures bit-for-bit
untouched; `runSolar` dispatch verified end-to-end. **0 STOP triggers fired.**

## The 5 artifacts (paths)

1. **Contracts** (greenfield; solar schema not touched):
   - `packages/contracts/returns-input.schema.json`
   - `packages/contracts/returns-output.schema.json`
2. **Bridge + dispatch**:
   - `core/astrology-hs/src/Bridge/Returns.hs` (new)
   - `core/astrology-hs/app/Main.hs` (additive `returns` dispatch)
   - `core/astrology-hs/src/Bridge/Solar.hs` (additive: export `planetFromText`)
   - `core/astrology-hs/astrology-core.cabal` (register `Bridge.Returns` + `Test.GoldenReturns`)
3. **Haskell golden roundtrip**:
   - `core/astrology-hs/test/golden/returns-sample.input.json`
   - `core/astrology-hs/test/golden/returns-sample.expected.json`
   - `core/astrology-hs/test/Test/GoldenReturns.hs` (new) + `test/Spec.hs` wiring
4. **Python contract test**:
   - `packages/test-fixtures/returns-sample.json` (mirror of expected output)
   - `services/api-python/tests/test_contracts.py` (3 new tests)
5. **TS types**:
   - `apps/web-react/src/types.ts` (`PlanetReturn` + `ReturnsComputedFacts`)

## Locked-decision compliance

- **Standalone `returns` workflow.** `app/Main.hs` dispatches on the input `workflow`
  field: `"solar"` → `runSolar` (unchanged), `"returns"` → new `runReturns`, unknown →
  exit 2 with clean stderr. Verified live: solar input → `workflow:"solar"`; returns
  input → `workflow:"returns"` (5 entries); `{"workflow":"bogus"}` → exit 2.
- **JD convention (NOT ISO).** `exact_jd` / `orb_enter_jd` / `orb_exit_jd` are Julian
  Day numbers, mirroring `annual_transit_table`'s `enter_jd`/`exit_jd`. No ISO datetime
  anywhere in either contract. JD→ISO stays Phase E (Python/PDF).
- **DTO reuse, not duplication (Correction 001).** `Bridge.Returns` imports
  `BridgePlanetPosition`, `BridgeTransitSample`, `BridgeMeta` and `planetFromText` from
  `Bridge.Solar`. No parallel records of the same meaning. The only change to
  `Bridge.Solar` is a 2-line additive export of `planetFromText` (runSolar + all DTOs
  byte-identical — see git diff below).
- **`returns[]` is a flat list.** Slow planet = multi-pass series; fast = single.
  Confirmed by the golden fixture: Sun + Mars one entry each; Saturn three
  (pass 1 Direct / pass 2 Retrograde / pass 3 DirectReturn, shared `natal_longitude`).
- **MotionPhase mapping.** `motion` serialises via the existing `Domain.Types`
  `MotionPhase` Generic instance — the SAME `"Direct" | "Retrograde" | "DirectReturn"`
  enum the solar `phase` field (TransitContact) already emits and the solar schema
  already pins (`$defs.MotionPhase.enum`). The returns schema + TS mirror that exact
  enum, so schema ↔ Bridge ↔ TS are byte-consistent. (NB: the TASK's illustrative
  schema sketch wrote lowercase `direct|retrograde|direct_return`; I followed the
  explicit locked instruction — "match the exact mapping Bridge.Solar already uses for
  tcPhase" / "match field naming to what your Bridge ToJSON actually emits" — which is
  PascalCase. Lowercase would have introduced a divergent enum and broken DTO reuse.)

## Sample of runReturns output (from the golden expected fixture)

Natal: 1971-06-15 12:00 UTC; reference_jd 2451711.0 (2000-06-15). Real Swiss-Eph samples.

```jsonc
// fast planet — single contact
{ "planet": "Sun", "natal_longitude": 83.741399, "exact_jd": 2452075.264450274,
  "orb_enter_jd": 2452074.2177208327, "orb_exit_jd": 2452076.311299441,
  "motion": "Direct", "pass_number": 1, "period_years": 1, "beyond_lifespan": false }

// slow planet — retrograde-loop series (pass 2 of 3)
{ "planet": "Saturn", "natal_longitude": 59.615406, "exact_jd": 2451839.891512991,
  "orb_enter_jd": 2451820.0784372385, "orb_exit_jd": 2451853.9461251358,
  "motion": "Retrograde", "pass_number": 2, "period_years": 29.46, "beyond_lifespan": false }
```

Saturn full series: pass 1 Direct (jd 2451760 ≈ 2000-08-04), pass 2 Retrograde
(jd 2451840 ≈ 2000-10-22), pass 3 DirectReturn (jd 2452017 ≈ 2001-04-17). Dates match
the independent pyswisseph crossing probe.

## Verification (run from /Users/ilya/Projects/astro)

- **Haskell** (`cd core/astrology-hs && cabal build && cabal test`): **279 examples,
  0 failures** (baseline 275 + 4 new returns golden: input exists, expected exists,
  runReturns == expected, input parse→encode→parse stable). All existing solar/golden
  tests PASS with **0 edits** to `synthetic-solar-1.*` or any solar golden/fixture.
- **Python** (`.venv/bin/pytest tests/test_contracts.py -q`): **8 passed**
  (5 baseline + 3 new: input check_schema, output check_schema, fixture validate +
  flat-list/JD semantics). Full suite sanity: **708 passed, 3 skipped**.
- **Frontend** (`apps/web-react && npx tsc --noEmit`): **clean (exit 0)**.
- Post-commit re-verification on committed state `37db1c2`: cabal 279/0, pytest
  test_contracts 8/8 (Correction 008 — verified AFTER commit).

## Reviewer-Ready (Tier A schema-gate — REQUIRED)

- **Atomicity — all 5 artifacts in ONE commit `37db1c2`** (`git show --stat`):

  ```
   apps/web-react/src/types.ts                        |   33 +
   core/astrology-hs/app/Main.hs                      |   22 +-
   core/astrology-hs/astrology-core.cabal             |    2 +
   core/astrology-hs/src/Bridge/Returns.hs            |  228 +
   core/astrology-hs/src/Bridge/Solar.hs              |    2 +
   core/astrology-hs/test/Spec.hs                     |    2 +
   core/astrology-hs/test/Test/GoldenReturns.hs       |   72 +
   core/astrology-hs/test/golden/returns-sample.expected.json |   65 +
   core/astrology-hs/test/golden/returns-sample.input.json    | 6614 +++++++++
   packages/contracts/returns-input.schema.json       |  106 +
   packages/contracts/returns-output.schema.json      |  115 +
   packages/test-fixtures/returns-sample.json         |   65 +
   services/api-python/tests/test_contracts.py        |   42 +
   13 files changed, 7366 insertions(+), 2 deletions(-)
  ```

- **Roundtrip green (independently):** Haskell golden returns + input roundtrip (cabal
  test 279/0), Python contract (`jsonschema.validate` + `check_schema` ×2, pytest 8/8),
  `tsc --noEmit` clean.
- **Solar untouched (git diff proof):**
  `git diff --stat a1e0c75 37db1c2 -- 'packages/contracts/solar-*.schema.json'
  'core/astrology-hs/test/golden/synthetic-solar-*' 'packages/test-fixtures/solar-*'
  'packages/test-fixtures/golden-cases'` → **empty** (bit-for-bit untouched). The only
  `Bridge/Solar.hs` change is the additive `planetFromText` export:
  ```
  +    -- * Shared helpers (reused by Bridge.Returns — no duplicate mapping)
  +  , planetFromText
  ```
  runSolar verified working end-to-end on `synthetic-solar-1.input.json` →
  `workflow:"solar"`.
- **JD-not-ISO:** grep of both schemas — no `date-time`/ISO format; all JD fields are
  bare `number`.
- **DTO reuse not duplication:** `Bridge.Returns` imports the three Bridge sub-types +
  `planetFromText` from `Bridge.Solar`; no parallel records (Correction 001).
- **Schema ↔ Bridge ↔ TS consistency:** output `PlanetReturn` fields
  (`planet, natal_longitude, exact_jd, orb_enter_jd, orb_exit_jd, motion, pass_number,
  period_years, beyond_lifespan`) match `BridgePlanetReturn` ToJSON 1:1 and the TS
  `PlanetReturn` interface 1:1; `motion` enum identical across all three; nullable
  `orb_*` modelled as `["number","null"]` (schema) / `number | null` (TS) /
  `Maybe Double` (Haskell). The input fixture also validates against
  `returns-input.schema.json` (bonus cross-check).
- **0 STOP triggers.**

## Self-review checklist

- [x] All 5 artifacts in ONE product commit `37db1c2` (`git show --stat` above).
- [x] returns golden roundtrip + input roundtrip pass (cabal 279/0).
- [x] Solar untouched: 0 edits to solar schema/golden/fixtures (git diff empty);
      runSolar dispatch still works (verified live).
- [x] JD convention (no ISO in contract).
- [x] BridgePlanetPosition/BridgeTransitSample/BridgeMeta reused, not duplicated.
- [x] returns[] flat: slow = series (Saturn 3), fast = single (Sun/Mars 1).
- [x] cabal build+test green (279/0), pytest test_contracts green (8/8), tsc clean.
- [x] No Phase D/E scope creep (no Python sampler/endpoint; no UI/PDF beyond types.ts).

## Notes / for TL attention

- **MotionPhase casing** is the one place the implementation deviates from the TASK's
  illustrative schema sketch (lowercase) in favour of the locked "match Bridge.Solar
  exactly" instruction (PascalCase). Flagged above — this is the schema-gate's core
  consistency requirement and avoids a divergent enum. If the product later wants
  lowercase wire values, that is a separate, deliberate `MotionPhase` ToJSON change
  cutting across solar too (its own bright-line-#8 gate), not something to fork here.
- **Pre-existing working-tree noise** (`.claude/launch.json` modified, `_marina-
  deliverables/`, `marketing-site/`) was present at session start and deliberately NOT
  staged — the product commit contains exactly the 13 intended files.
- Reference date used for the fixture is a fixed historical natal/return pair (1971 →
  2000-2001) chosen for a deterministic, real 3-pass Saturn loop; not tied to "today".

## Next (not in this scope)

- Phase D: Python returns sampler + `GET /persons/{id}/returns` endpoint + orchestration.
- Phase E: UI "Ближайшие возвраты" panel + solar-PDF returns section.
