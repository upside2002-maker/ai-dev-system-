# HANDOFF: worker → tl — planet-returns-python-endpoint

- Status: open (Phase D delivered; ready for TL inline-verify / optional Reviewer)
- Date: 2026-05-24 (executed 2026-06-05)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker (normal, Tier B)
- TASK: project-overlays/astro/TASKS/2026-05-24-planet-returns-python-endpoint.md
- Memo: project-overlays/astro/ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md (§ 3.2 / § 4)
- **Product repo status: committed (4bdf1b1 — astro main; sampler + endpoint + router + tests)**

## Summary

Phase D of the planet-returns epic — the **Python Services layer**: an ephemeris
sampler, orchestration via ONE Haskell subprocess call, and the FastAPI endpoint
`GET /persons/{id}/returns`. The Phase B Core engine
(`Domain.Returns.findNearestReturns`) + Phase C `returns` workflow contract are now
driven end-to-end from Python. **No return/aspect/crossing math in Python** (bright
line #7 — delegated to Haskell); **exactly ONE subprocess call per request** (bright
line #6 — one snapshot in / snapshot out); **no DB write** (result depends on the
moving `as_of` reference → would go stale). Schema / Haskell / Main.hs / UI all
untouched. **0 STOP triggers fired.**

## Files changed (product, commit 4bdf1b1)

- new: `services/api-python/app/ephemeris/returns_sampler.py` — D.1 sampler.
- new: `services/api-python/app/api/returns.py` — D.3 endpoint + router.
- new: `services/api-python/tests/test_returns_endpoint.py` — D.4 tests (7).
- modify: `services/api-python/app/main.py` — register `returns_router` under `/api/v1`
  (+2 effective lines: import + `include_router`, mirroring the geocode pattern).

(Out of scope, intentionally NOT committed: pre-existing unrelated working-tree
artifacts `.claude/launch.json` edit, `_marina-deliverables/`, `marketing-site/` —
these belong to separate marketing work, not Phase D. Only the four returns files
were staged. `git status --short` clean for intended changes.)

## D.1 — Ephemeris sampler

`returns_sampler.build_returns_snapshot(person, reference_jd)`:
- natal positions (10 classical) via `bridge.compute_planet_positions` — **reuses the
  exact solar-path ephemeris** (`FLG_SWIEPH | FLG_SPEED`, tropical, geocentric); no
  sidereal, no divergent convention;
- per-planet forward streams via `compute_returns_samples` over memo § 4
  windows/cadence (`_RETURNS_SAMPLE_PLAN`): Moon 35 d/6 h; Sun/Mercury/Venus 400 d/daily;
  Mars 800 d/daily; Jupiter 13 y/weekly; Saturn 30 y/10 d; Uranus 85 y, Neptune 166 y,
  Pluto 249 y / monthly. Windows sized to each planet's period so the nearest return
  (and, for slow planets, the whole retro loop that follows it) is always inside the
  stream;
- assembles the `returns-input` snapshot (`workflow:"returns"`, `natal_positions`,
  `reference_jd`, `samples`, `meta`). **No crossing/return math.**
- `reference_jd_from_iso(as_of)` converts the ISO param (date or datetime; bare 'Z'
  accepted; naive→UTC) to JD; `None` → now (server UTC).
- lat/lon are deliberately NOT used: a return is a longitude conjunction
  (observer-independent), so only the natal instant matters.

Cadence safety vs the engine's crossing detector
(`Domain.TransitMath.findCrossings`: `abs d1 < 90 && abs d2 < 90`): max angular step
per cadence (Moon ≈3.3°, Mercury ≈2.2°, Jupiter ≈1.7°, Saturn ≈1.3°, outers <1.8°) is
far below the 90° wrap-guard, so every loop pass is cleanly bracketed.

## D.2 — Orchestration: the ONE subprocess-call code path (proof)

The endpoint calls the existing solar helper `core_client.run_core_analysis` exactly
once. Code path in `app/api/returns.py::get_person_returns`:

```python
snapshot = build_returns_snapshot(person, reference_jd)   # one snapshot, all 10 planets
...
result = run_core_analysis(snapshot)   # <-- the SINGLE subprocess call (workflow="returns")
return result                          # returns-output as-is; no DB write
```

`run_core_analysis` (unchanged, reused verbatim) does exactly one
`subprocess.run([binary], input=payload, ...)`. There is no loop, no per-planet call,
no second invocation anywhere in the request. The bridge helper was reused **additively
without modification** (the returns input is just a different `workflow` value).

## D.3 — Endpoint

`GET /api/v1/persons/{id}/returns?as_of=<iso>` (default now): load person → reference_jd
→ sampler → ONE Haskell call → return `returns-output` verbatim (JD stays JD;
date conversion is Phase E). Router registered in `main.py` under `/api/v1` (mirrors
geocode). 404 for missing person; 422 for missing birth_timezone / invalid `as_of`;
502 on core failure. **No DB write** (own DB dependency mirrors `main.get_db`; only
reads the person row).

## D.4 — Tests (7, all green)

- `test_sampler_builds_valid_returns_input` — snapshot validates against
  `returns-input.schema.json`; 10 natal positions; per-planet streams ascending,
  all ≥ reference; natal Sun longitude == Phase A 1.451361°.
- `test_sampler_payload_size_is_reasonable` — payload-guard: <20k samples / <3 MB;
  asserts the sampler logged the size.
- `test_returns_endpoint_200_ten_planets` — HTTP 200, all 10 planets, output validates
  against `returns-output.schema.json`, every return strictly after reference.
- `test_returns_phase_a_parity` — Sun ≈ 22 Mar 2027; Saturn multi-pass series
  (pass_number 1..N consecutive, Direct + Retrograde present, shared natal/period);
  Neptune/Pluto `beyond_lifespan=true`, Uranus `false`; fast planets one contact each.
- `test_returns_missing_person_404`, `test_returns_default_as_of_is_now`,
  `test_returns_invalid_as_of_422`.

(The 3 e2e tests `pytest.skip` if the Haskell binary isn't built; here they ran via the
`cabal list-bin` fallback and passed.)

## Verification

- `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=short -q`
  → **715 passed, 3 skipped, 0 failed** (708 prior + 7 new returns tests; the 3 skips
  are pre-existing and unrelated).
- `cabal test` not affected — no Haskell change (Phase C closed, untouched).
- `git status --short` clean for intended changes (only the unrelated pre-existing
  marketing artifacts remain unstaged, by design).

## Endpoint output sample — person 4 (Marina), `as_of=2026-05-24`

10 distinct planets, 18 total entries (fast = 1 each; Saturn/Uranus/Neptune/Pluto =
3-pass loops). `reference_jd = 2461184.5`. Selected entries (JD; Phase E converts to
dates):

```json
{
  "planet": "Sun",      "pass_number": 1, "motion": "Direct",
  "exact_jd": 2461486.8123198086,           // ≈ 2027-03-22 07:29 UTC (Marina's birthday; Phase A Δ ~5s)
  "orb_enter_jd": 2461485.805, "orb_exit_jd": 2461487.820,
  "period_years": 1, "beyond_lifespan": false, "natal_longitude": 1.45136064
}
{
  "planet": "Saturn",   "pass_number": 2, "motion": "Retrograde",
  "exact_jd": 2469255.7007830027,           // ≈ 2048 Saturn-return retro pass (Phase A: 2048 series)
  "orb_enter_jd": 2469241.402, "orb_exit_jd": 2469269.346,
  "period_years": 29.46, "beyond_lifespan": false, "natal_longitude": 283.10455574
}
{
  "planet": "Neptune",  "pass_number": 1, "motion": "Direct",
  "exact_jd": 2507482.500574492,            // beyond lifespan
  "orb_enter_jd": 2507449.549, "orb_exit_jd": 2507621.425,
  "period_years": 164.79, "beyond_lifespan": true, "natal_longitude": 282.23950130
}
```

Full table (sampler → endpoint, dates via swe.revjul) matches Phase A reference
(overlay 3471e64) to the day for slow planets and to seconds for the Sun: Sun
2027-03-22, Moon ~2026-05-25, Mars 2026-07-08, Jupiter 2036-05-16, Saturn 2048
(3 passes), Uranus 2073 (3 passes, beyond_lifespan=false), Neptune 2153 / Pluto 2235
(3 passes each, beyond_lifespan=true). Sub-day differences from Phase A's fine
throwaway sampler on the outers come from the coarse production cadence (10 d/30 d);
the Haskell bisection refines each contact, so the rendered date is identical.

## Payload size logged

Sampler logs (INFO, `app.ephemeris.returns_sampler`): for Marina,
**10 009 total samples across 10 planets** (~820 KB JSON), per-planet
`{Moon:141, Sun:401, Mercury:401, Venus:401, Mars:801, Jupiter:679, Saturn:1096,
Uranus:1035, Neptune:2022, Pluto:3032}`. Modest — slow planets move slowly, so even
multi-century windows at coarse cadence stay small. Asserted < 20 k samples / < 3 MB.

## Self-review checklist

- [x] Sampler output validates against `returns-input.schema.json`.
- [x] Exactly ONE Haskell subprocess call per request (single `run_core_analysis` in
      `get_person_returns`; helper does one `subprocess.run`; no loop/second call).
- [x] No aspect/return math in Python (sampler emits raw ephemeris only; engine detects).
- [x] Endpoint returns 10 planets; Sun ≈ birthday, Saturn series, Neptune/Pluto
      beyond_lifespan, Uranus not (Phase A parity).
- [x] No DB write for returns; no schema/Haskell/Main.hs/UI changes; no sidereal.
- [x] pytest green (715/3/0); product committed (4bdf1b1); backup pushed; overlay
      committed + pushed.

## STOP triggers fired: 0

## Notes for TL (not blockers)

- Reviewer is optional per TASK (Tier B Services; math delegated). TL inline-verify
  suffices.
- Phase E (UI panel + PDF section + JD→date conversion) is the next phase; the endpoint
  returns JD verbatim as specified, ready for that presentation layer.
- The slow-planet `as_of`-dependent dates (Saturn/outers) are sensitive to cadence at
  the second level but stable at the day level — adequate for the MVP date display.
