# HANDOFF: worker → tl — planet-returns-core-domain (Phase B)

- Status: closed
- Date: 2026-06-05 (executed; reference env currentDate 2026-06-05)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker (strict, Tier A)
- TASK: project-overlays/astro/TASKS/2026-05-24-planet-returns-core-domain.md
- Memo: project-overlays/astro/ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md (§ 0.1/0.2 locked params, § 3.1 design, § 7 phases)
- Phase A proof (empirical reference): HANDOFFS/archive/2026-05-24-worker-to-tl-planet-returns-stage0-empirical-proof.md (overlay 3471e64)
- **Product repo status: committed (`a1e0c75` on main, backup pushed `ba806d5..a1e0c75` → /Users/ilya/Backups/astro.git, parity verified)**

## Summary

Phase B of the «planet returns» epic — a **pure Core (Haskell) engine** for
nearest planet returns of the 10 classical planets. Two steps, one product
commit:

- **B.1 — extract `Domain.TransitMath`** (new): lifted the retro-aware detection
  core out of `Domain.TransitCalendar` so `analyzeAnnualCalendar` and the new
  `Domain.Returns` share ONE implementation (bright line #7 / Correction 004).
- **B.2 — new `Domain.Returns`**: `findNearestReturns` per TASK § B.2.
- **B.3 — new `Test.Domain.ReturnsSpec`**: 33 unit tests incl. a realistic
  Marina Saturn cross-check.

**`cabal build` clean (0 warnings under `-Wall -Wcompat -Wredundant-constraints`).
`cabal test` = 275 examples, 0 failures (242 baseline + 33 new). Golden
`synthetic-solar-1` + all `TransitCalendar` cases pass UNCHANGED — 0 expected-file
edits. 0 STOP triggers fired.**

## Files changed (product, single commit `a1e0c75`)

| File | Change |
|---|---|
| `core/astrology-hs/src/Domain/TransitMath.hs` | **NEW** — shared movement primitives. |
| `core/astrology-hs/src/Domain/Returns.hs` | **NEW** — `findNearestReturns` + records. |
| `core/astrology-hs/src/Domain/TransitCalendar.hs` | import refactor (deletes 6 helpers + `CalSample`; `numberContactsFor` delegates to `numberPasses`). |
| `core/astrology-hs/astrology-core.cabal` | `+ Domain.TransitMath`, `+ Domain.Returns` (lib exposed-modules); `+ Test.Domain.ReturnsSpec` (test other-modules). |
| `core/astrology-hs/test/Test/Domain/ReturnsSpec.hs` | **NEW** — 33 unit tests. |
| `core/astrology-hs/test/Spec.hs` | wire `Test.Domain.ReturnsSpec` into the suite. |

Net: 6 files, +926 / −168.

## B.1 — extraction (bit-identical proof)

Lifted into `Domain.TransitMath` (behaviour-preserving, verbatim):
`CalSample`, `signedArc`, `interpolateZero`, `interpolateOrbBoundary`,
`findCrossings`, `findOrbWindows`, `phaseFromSpeedAndPass`. Added a
**record-agnostic kernel `numberPasses`** = the sort-by-jd + `zip [1..]` +
`phaseFromSpeedAndPass` logic that previously lived inline in
`numberContactsFor`. `TransitCalendar.numberContactsFor` now keeps only the
aspect grouping + `TransitContact` construction and delegates the per-group
numbering to `numberPasses` — so the loop-pass numbering math exists in exactly
ONE place. No copy-paste (Correction 004 honoured).

**Bit-identical confirmation** — `cabal test` summary line, golden case:
```
Golden.Solar
  synthetic-solar-1
    input fixture exists [✔]
    expected fixture exists [✔]
    runSolar reproduces the expected JSON output [✔]
...
275 examples, 0 failures
Test suite astrology-core-tests: PASS
```
`git status --short` shows **no** `*.expected.json` and no `test/golden/`
modification. All `TransitCalendar` behavioural tests (direct conjunction,
retro loop, Asc/MC, Quincunx A.1, orb-window A.2, drift-only, cross-year A.3)
pass unchanged. The 242→275 delta is purely the new `ReturnsSpec`.

## B.2 — `Domain.Returns.findNearestReturns`

Signature exactly per TASK § B.2 (record fields incl. `prPassNumber`,
`prBeyondLifespan`):
```haskell
findNearestReturns
  :: [PlanetPosition] -> Double
  -> Map Planet [(Double,Double,Double)] -> ReturnsResult
```
Behaviour per natal planet: build the planet's `CalSample` stream → `findCrossings`
of the natal longitude (retro-aware, both directions) → drop crossings ≤
`reference_jd` (return must be strictly future) → `numberPasses` (pass_number +
phase) → attach the enclosing 1° orb window (`findOrbWindows`). **Fast**
(Sun/Moon/Mercury/Venus/Mars) → `take 1` (nearest single). **Slow**
(Jupiter/Saturn/Uranus/Neptune/Pluto) → whole loop series (headline = pass 1).
`prBeyondLifespan` = True for Neptune/Pluto only (Uranus once-in-life = False,
separate note). `prPeriodYears` = reference sidereal period. Output ordered
Sun..Pluto (sort by `fromEnum . ppPlanet`).

- **NO `findSolarReturnJd` reuse** (Phase A proved its forward-only `crossesArc`
  misses retro crossings).
- **NO wildcard** in any Planet match — `periodYearsFor`, `beyondLifespanFor`,
  `isSlowPlanet` all enumerate the 10 constructors (Correction 002).
- **NO `data Planet` extension.**
- One small local helper `enclosingWindow` (pure interval containment over
  `findOrbWindows` output) — NOT crossing/orb detection math, so not a bright
  line #7 duplication. Flagged for Reviewer transparency.

Note on the motion-phase type: TASK § B.2 draft names the field
`prMotion :: TransitPhase`, but the canonical type in this codebase is
`Domain.Types.MotionPhase` (Direct | Retrograde | DirectReturn) — the same type
`TransitContact.tcPhase` uses. I used `MotionPhase` rather than introduce a
synonym; documented in the `PlanetReturn` haddock.

## B.3 — tests + realistic cross-check

`Test.Domain.ReturnsSpec` (33 examples, all green):
1. **Synthetic direct crossing** — Sun 1°/day across natal 100° → 1 return, exact
   JD recovered at +10.5 d to < 1 minute, pass 1 / Direct.
2. **Synthetic retro loop** — Saturn direct→retro→direct → 3-pass series,
   pass_number [1,2,3], phases [Direct, Retrograde, DirectReturn], JDs +10.5 /
   +31.5 / +52.5 d.
3. **Orb 1° window** — enter < exact < exit; width ≈ 2 d (1°/day); applying side
   ≈ 1 d (1°) before exact.
4. **reference_jd boundary** — every contact strictly > reference; mid-reference
   skips past contacts; a contact exactly AT the reference is not counted.
5. **beyond_lifespan** — Neptune/Pluto True; Uranus False; no fast/social planet True.
6. **Determinism + ordering** — identical output on re-run; headline returns
   ordered Sun..Pluto; absent planet → no entry.
7. **Realistic Marina Saturn cross-check** — transiting Saturn samples for the
   2048 loop generated one-off via the pyswisseph venv (`FLG_SWIEPH|FLG_SPEED`,
   geocentric, 10-day step), **hardcoded** in the test file (Core-only, no data
   file). natal Saturn 283.104556°. Engine recovers the full 3-pass loop:
   pass 1 ≈ **2048-02-23** (Direct, within ±1 d of Phase A's 2048-02-23 05:58),
   pass 2 ≈ 2048-06-28 (Retrograde), pass 3 ≈ 2048-11-22 (DirectReturn);
   `beyond_lifespan=False`; period ≈ 29.46 y. **Matches Phase A HANDOFF § 0.4.**

## Verification (run on committed state `a1e0c75`)

```
$ cabal build --project-dir=core/astrology-hs all   # clean, 0 warnings
$ cabal test  --project-dir=core/astrology-hs all
275 examples, 0 failures
Test suite astrology-core-tests: PASS
$ git status --short    # only pre-existing unrelated entries; NO *.expected.json
 M .claude/launch.json
?? _marina-deliverables
?? marketing-site/
```
(`.claude/launch.json`, `_marina-deliverables`, `marketing-site/` were already
dirty/untracked in the baseline working tree and are NOT part of this task — they
were deliberately excluded from the commit via explicit `git add` of the 6 Core
files only, per Correction 008.)

Toolchain note: cabal 3.14.2.0 / ghc 9.6.6 live under `~/.ghcup/bin` (not on the
login PATH). The TASK's `cabal --project-dir core/astrology-hs build` form needs
`--project-dir=core/astrology-hs` (the `=` is required in 3.14) — used the
absolute-path `=` form throughout.

## Self-review checklist

- [x] `Domain.TransitMath` extracted; `TransitCalendar` imports it; NO math duplication (`numberPasses` is the single numbering kernel).
- [x] `analyzeAnnualCalendar` bit-identical — golden cases pass, 0 expected edits (test summary + `git status` pasted above).
- [x] `findNearestReturns`: fast=single, slow=series w/ pass_number, orb 1°, applying→exact window, reference boundary strictly-after, beyond_lifespan Neptune/Pluto.
- [x] No `findSolarReturnJd` reuse; no wildcard Planet match; no `data Planet` extension.
- [x] `cabal build` + `cabal test` green (275/0); 0 warnings under `-Wall`.
- [x] No schema/Bridge/Main/Python/frontend touched (only Core + tests + cabal).
- [x] HANDOFF + STATUS_RU + backups pushed.

## STOP triggers fired: 0

## Reviewer-Ready — what to verify (Tier A Core math, Reviewer REQUIRED)

TL spawns the external Reviewer (Worker runtime has no Agent tool — recurring
precedent). Independent checks:

1. **Golden bit-identical:** independently run `cabal test --project-dir=core/astrology-hs all`;
   confirm `synthetic-solar-1` + all `TransitCalendar` cases pass and `git status`
   shows zero `*.expected.json` / `test/golden/` diffs.
2. **No math duplication:** confirm the 6 primitives live only in `TransitMath`
   and `numberContactsFor` delegates numbering to `numberPasses` (no copy-paste).
3. **`findNearestReturns` correctness:** synthetic forward exact JD; retro 3-pass
   series with correct pass_number + phases; orb 1° window enter<exact<exit;
   reference strictly-after (incl. contact-at-reference excluded); beyond_lifespan
   flags; Sun..Pluto ordering + determinism.
4. **Retro-series semantics:** pass-numbering / phases match TransitCalendar
   semantics (`phaseFromSpeedAndPass`: pass≥3 & spd≥0 → DirectReturn).
5. **No `findSolarReturnJd` on retro; no wildcard Planet match; no `data Planet`
   extension.**
6. **Realistic anchor:** Marina Saturn pass 1 ≈ 2048-02-23 (Phase A parity).
7. **0 STOP triggers.**

## Open questions for TL (not blockers — Phase C+ scope)

1. Phase A flagged: outer "nearest return" headline = pass 1 (first-after-today,
   owner's § 0 wording) — implemented as pass 1 with the full loop series also
   emitted. Confirm this is the intended headline for Phase E presentation.
2. Action-window: `prOrbEnterJd`/`prOrbExitJd` are the tight 1° orb window per
   pass (memo "~2 weeks" framing). The full retro-loop span (Saturn ~272 d) is
   recoverable as pass1.enter → pass3.exit downstream — confirm which the
   Python/PDF surface should show (Phase D/E decision, not Core).
