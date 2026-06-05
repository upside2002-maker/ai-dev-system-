# HANDOFF: worker → tl — planet-returns-stage0-empirical-proof

- Status: open (Stage 0 proof complete; gate for Phase B Core)
- Date: 2026-05-24 (analysis executed; reference_date 2026-06-05 — see § reference_date note)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-24-planet-returns-stage0-empirical-proof.md
- Memo: project-overlays/astro/ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md
- **Product repo status: not applicable (read-only Stage 0, no product changes)**

## Summary

Stage 0 empirical proof for the standalone `returns` workflow. READ-ONLY: nearest
planet returns computed via pyswisseph for Marina (person_id=4) on her real natal
chart, matching the existing engine's ephemeris convention exactly. **All sanity
STOP-criteria PASS. 0 STOP triggers fired.** Retro-loop returns confirmed on REAL
data (Saturn/Uranus/Neptune/Pluto each cross natal longitude 3× in a direct→retro→
direct loop) — no synthetic example needed. Reuse conclusion confirms the memo:
`SolarReturn.findSolarReturnJd` cannot be reused (forward-only `crossesArc`);
extract `findCrossings`/`findOrbWindows`/`interpolateOrbBoundary`/`numberContactsFor`/
`phaseFromSpeedAndPass`/`signedArc` from `TransitCalendar.hs` into `Domain.TransitMath`.

## Ephemeris convention (matched to existing engine)

Source verified: `services/api-python/app/ephemeris/bridge.py:179-181, 290-307`.
- Flags: **`swe.FLG_SWIEPH | swe.FLG_SPEED`** — tropical zodiac, geocentric, no
  sidereal flag, no heliocentric. Longitude normalized `% 360`; retrograde =
  `speed (xx[3]) < 0`.
- JD ↔ datetime via `swe.julday` / `swe.revjul` (GREG_CAL). All return datetimes UTC.
- Planet IDs identical to `bridge.py` `_PLANET_IDS`.
- **No sidereal introduced.** Western/tropical only, per project convention.

Cross-check: recomputing the 10 natal longitudes via pyswisseph at the engine's
own `natal_chart.julian_day` (2447607.6069444446) reproduces the Haskell-engine
`facts_json` longitudes to **0.00 arcsec** for all 10 planets — same flags, same
ephemeris. facts_json longitudes are the canonical return TARGETS.

## reference_date note

Environment `currentDate` = **2026-06-05**. The TASK frames Stage 0 as dated
2026-05-24; the proof was actually executed on 2026-06-05, so **reference_date =
2026-06-05T00:00:00Z** is the honest "today" used for every nearest-return search.
(Approach is reference-date-agnostic; the Sun-return birthday sanity check holds
for either date since both precede 2027-03-22.)

---

## 0.1 — Natal longitudes (Marina, person_id=4, consultation 15)

Source: `consultations.facts_json` id=15 → `natal_chart.positions[*]` (canonical
Haskell-engine output). Birth 1989-03-22 05:34 Europe/Moscow, Ковров.
natal julian_day = 2447607.6069444446.

| Planet | Longitude (°) | Sign | °′″ within sign | Natal retro |
|---|---:|---|---|:--:|
| Sun | 1.451361 | Aries | 1°27′05″ | no |
| Moon | 178.114990 | Virgo | 28°06′54″ | no |
| Mercury | 348.878381 | Pisces | 18°52′42″ | no |
| Venus | 357.928669 | Pisces | 27°55′43″ | no |
| Mars | 66.551934 | Gemini | 6°33′07″ | no |
| Jupiter | 61.720442 | Gemini | 1°43′14″ | no |
| Saturn | 283.104556 | Capricorn | 13°06′16″ | no |
| Uranus | 275.189995 | Capricorn | 5°11′24″ | no |
| Neptune | 282.239501 | Capricorn | 12°14′22″ | no |
| Pluto | 224.868326 | Scorpio | 14°52′06″ | **yes** |

pyswisseph cross-check vs engine facts_json: max discrepancy **0.00 arcsec**
(exact match for all 10) — confirms the proof's ephemeris == the production engine's.

---

## 0.2 — Nearest return per planet (first crossing strictly after reference_date)

reference_date = 2026-06-05T00:00:00Z. For each planet the transiting longitude
was sampled forward over the memo § 4 window with a retro-aware sign-change
bracketer (signed-arc crossing detection, both motion directions), refined to
~1-second precision by bisection. "First crossing" = nearest return.

| Planet | Nearest return (UTC) | Δ from ref | Period (y) | Motion @ return | Note |
|---|---|---:|---:|:--:|---|
| Sun | 2027-03-22 07:29:39 | 0.79 y | 1.00 | direct | — |
| Moon | 2026-06-21 17:23:25 | 16.72 d | 0.075 | direct | — |
| Mercury | 2027-04-01 23:37:16 | 0.82 y | 1.00 | direct | — |
| Venus | 2027-04-18 10:55:08 | 0.87 y | 1.00 | direct | — |
| Mars | 2026-07-08 01:24:31 | 0.09 y | 1.88 | direct | — |
| Jupiter | 2036-05-16 23:10:37 | 9.95 y | 11.86 | direct | — |
| Saturn | 2048-02-23 05:58:35 | 21.7 y | 29.46 | direct | retro loop follows (3 passes) |
| Uranus | 2073-02-13 08:25:02 | 46.7 y | 84.01 | direct | **once-in-life (~84 y)**; retro loop |
| Neptune | 2153-02-23 10:01:41 | 127 y | 164.79 | direct | **beyond lifespan**; retro loop |
| Pluto | 2235-12-13 01:41:15 | 210 y | 247.94 | direct | **beyond lifespan**; retro loop |

The nearest return is the FIRST (pass 1) crossing in every case — for the slow
planets pass 1 happens to be the direct ingress before the retrograde loop opens
(see § 0.4 for the full per-pass breakdown of the loops).

---

## 0.3 — Sanity checks (the STOP criteria) — ALL PASS

| Check | Result | Verdict |
|---|---|:--:|
| **Sun** ≈ Marina's next birthday (~22 Mar) | Sun return 2027-03-22 07:29Z vs birthday 2027-03-22 → **Δ = +0.31 d** | **PASS** (≤ ±2 d) |
| **Moon** within one lunar month | nearest +16.72 d; **next** return +27.34 d later (= 27.32 d sidereal month) | **PASS** |
| **Mars** within ~2 y | +0.09 y (next loop pass 2028-06-16) | **PASS** |
| **Saturn** ≈ age × 29.46 | age at return = **58.92 y = 2 × 29.46** (2nd Saturn return; Marina is 37 now) | **PASS** |
| **Jupiter** ≈ multiple of 11.86 | age at return = **47.15 y ≈ 4 × 11.86** | **PASS** |
| **Uranus** once-in-life (~84 y) | age = **83.90 y ≈ 84** → single lifetime return | **PASS** → `beyond_lifespan=false`, note "once-in-life" |
| **Neptune** beyond lifespan | age = **163.92 y** | **PASS** → `beyond_lifespan=true` |
| **Pluto** beyond lifespan | age = **246.72 y** | **PASS** → `beyond_lifespan=true` |

### Moon note (why +16.72 d is correct, not a STOP)

The "~27–28 days" criterion describes the lunar **period** (the upper bound on the
gap to the nearest return). From an arbitrary reference date the nearest return
lands anywhere in [0, 27.3] d. At ref the Moon is at 305.13° and the natal target
is 178.11° → signed arc −127°; at ~13.18°/day the first forward crossing is ~16.7 d
out (confirmed exact). The spacing between consecutive returns is **27.34 d** =
the 27.32 d sidereal month. So the engine reproduces the lunar cycle exactly;
+16.72 d is inside one month → PASS, no STOP.

### Age-at-return basis

Ages computed from birth JD `swe.julday(1989,3,22,02:34 UT)` (= 05:34 MSK − 3 h).
Saturn 58.92 y and Uranus 83.90 y are the textbook "second Saturn return" and
"Uranus return" landmarks — strong confirmation the nearest-return approach
reproduces known life-cycle astronomy.

---

## 0.4 — Retrograde case (REAL data — no synthetic example needed)

Sampling each planet across its full return window and collecting **every**
crossing of the natal longitude (signed-arc sign-change, direction-agnostic)
surfaces classic retrograde loops on four planets. Each crosses its natal degree
**3 times** in a direct → retrograde → direct pattern:

| Planet | Pass 1 (UTC) | speed | Pass 2 (UTC) | speed | Pass 3 (UTC) | speed | Loop span |
|---|---|---:|---|---:|---|---:|---:|
| **Saturn** | 2048-02-23 05:58 | +0.0881 (direct) | 2048-06-28 05:03 | **−0.0732 (retro)** | 2048-11-22 02:16 | +0.0972 (direct) | 272.8 d |
| **Uranus** | 2073-02-13 08:25 | +0.0438 (direct) | 2073-06-07 14:01 | **−0.0380 (retro)** | 2073-12-03 17:35 | +0.0566 (direct) | 293.4 d |
| **Neptune** | 2153-02-23 10:01 | +0.0258 (direct) | 2153-06-05 11:14 | **−0.0232 (retro)** | 2153-12-24 04:18 | +0.0374 (direct) | 303.8 d |
| **Pluto** | 2235-12-13 01:41 | +0.0347 (direct) | 2236-04-30 19:33 | **−0.0281 (retro)** | 2236-10-08 19:37 | +0.0364 (direct) | 300.7 d |

(Sun, Mercury, Venus, Jupiter: single fast direct crossing in window. Mars: 2
crossings — but these are two *separate* synodic returns ~1.94 y apart, not a
single retro loop; both direct. Mercury/Venus do go retrograde generally but did
not retrograde *across the natal degree* at their nearest return in this window.)

### Pass-numbering / "true return" semantics for `Domain.TransitMath`

For a 3-pass retro loop the bracketer must:

1. **Detect ALL crossings** via signed-arc sign change (works for direct AND retro
   steps), NOT a forward-only arc test. Sort ascending by JD.
2. **Number passes** 1, 2, 3 in JD order (`pass_number` / `tcLoopPass`). This is
   exactly `TransitCalendar.numberContactsFor` (`zip [1..] . sortOn jd`).
3. **Classify motion** per pass via `phaseFromSpeedAndPass`:
   - pass 1, speed ≥ 0 → `direct` (the planet's direct ingress)
   - pass 2, speed < 0 → `retrograde`
   - **pass 3 (≥3) & speed ≥ 0 → `direct_return`** ← the canonical "settling"
     contact; `TransitCalendar.hs:294` already encodes `pass >= 3 && spd >= 0 = DirectReturn`.
4. **Returns-MVP "nearest return"** = the FIRST crossing strictly after
   reference_date (pass 1 here). But the bracketer must still discover passes 2–3
   to (a) number them and (b) compute the **action window** (orb enter/exit), which
   spans the whole loop (~9–10 months for these outers) via `findOrbWindows` +
   `interpolateOrbBoundary`. Reporting only pass 1 without the loop would under-
   state the window — hence `prOrbEnterJd`/`prOrbExitJd` in the memo's `PlanetReturn`.

`pass_number` for the surfaced returns: Sun/Moon/Mercury/Venus/Jupiter = 1 (single
contact). Saturn/Uranus/Neptune/Pluto nearest = pass 1 of a 3-pass loop; the
loop's `direct_return` is pass 3. **Open design choice for TL**: whether the MVP
"nearest return" date shown to the user should be pass 1 (first exact contact) or
pass 3 (`direct_return`, the loop's resolution). Empirics support pass 1 = literal
"first return strictly after today" (memo § 0 owner decision: "первый возврат
строго после reference_date"); the action window then covers passes 1→3. Flagged,
not fabricated.

---

## 0.5 — Reuse conclusion

### `SolarReturn.findSolarReturnJd` CANNOT be reused directly — CONFIRMED

`core/astrology-hs/src/Domain/SolarReturn.hs:85-89` `crossesArc` models a step as a
**forward (CCW) arc** `forwardDelta lonA lonB` and tests whether natal lies inside
it. Its own docstring (lines 67-69) states it assumes "Sun is never retrograde".

**Empirical proof on the real Saturn retro pass (2048-06-27→29, planet moving
backward through 283.10°):**
- `lonA = 283.193`, `lonB = 283.047` (lonB < lonA, retrograde step).
- `forwardDelta(lonA, lonB) = 359.85°` (the CCW arc wraps almost the whole circle
  because the actual motion is backward), `forwardDelta(lonA, natal) = 359.91°`.
- `crossesArc` fires iff `offsetNat ≤ deltaArc` → 359.91 ≤ 359.85 = **False**.
- → `crossesArc` **MISSES the genuine retrograde crossing**.
- Contrast `TransitCalendar.signedArc`: −0.0885 → +0.0579 (sign flip) → crossing
  **correctly detected**.

So for Mercury/Venus/Mars and the outer-planet retro loops `findSolarReturnJd`
would silently skip retrograde contacts. The bisection *technique* is fine; the
*bracket detector* is the broken part.

### What to extract into `Domain.TransitMath` (Phase B step 1)

Lift these retro-aware primitives **verbatim** (behaviour-preserving — golden
`analyzeAnnualCalendar` cases must stay bit-identical, the memo's invariant) from
`core/astrology-hs/src/Domain/TransitCalendar.hs`:

| Helper | Line(s) | Role for returns |
|---|---|---|
| `signedArc` | 249 | direction-agnostic angular distance; basis of all crossing/window logic |
| `findCrossings` | 303-321 | all exact crossings of a target (direct + retro), with speed → motion |
| `interpolateOrbBoundary` | 275-290 | sub-day refinement of orb enter/exit |
| `findOrbWindows` | 333-404 | action-window (enter/exit) per contact — `prOrbEnterJd/ExitJd` |
| `numberContactsFor` | 586-606 | sort-by-JD + pass numbering (`pass_number`) |
| `phaseFromSpeedAndPass` | 292-301 | motion phase incl. `DirectReturn` on pass ≥ 3 |

`matchTouchesToWindows` (514-531) and `windowOnlyContacts` (536-549) are useful if
the returns workflow wants the same touch↔window pairing semantics, but the MVP
(nearest contact + its enclosing window) may only need `findCrossings` +
`findOrbWindows` + `numberContactsFor`.

`Domain.Returns.findNearestReturns` (memo § 3.1) then = per natal planet: take its
forward sample stream from `reference_jd`, run `findCrossings`, drop crossings ≤
`reference_jd`, take the first (nearest), number passes, attach orb window, set
`prBeyondLifespan` (Neptune/Pluto true; Uranus false + "once-in-life" note),
`prPeriodYears` reference value. No math duplicated (bright line #7 / Correction
004): `analyzeAnnualCalendar` and `Domain.Returns` both consume the SAME
`Domain.TransitMath`.

---

## Self-review

- [x] All 10 natal longitudes tabulated (§ 0.1); reference_date explicit (2026-06-05Z).
- [x] All 10 nearest returns computed (§ 0.2); flags match engine (tropical, `FLG_SWIEPH|FLG_SPEED`); natal cross-check 0.00 arcsec.
- [x] Sun return Δ = +0.31 d ≤ ±2 d — **PASS** (no STOP).
- [x] Moon nearest +16.72 d, consecutive spacing 27.34 d = sidereal month — **PASS**.
- [x] Neptune (163.92 y) / Pluto (246.72 y) beyond lifespan; Uranus (83.90 y) once-in-life.
- [x] Retro case analyzed on REAL data (Saturn/Uranus/Neptune/Pluto 3-pass loops) with pass-numbering + `direct_return` semantics.
- [x] Reuse conclusion: 6 helpers → `Domain.TransitMath`; `findSolarReturnJd` insufficient (forward-only `crossesArc` proven to miss real Saturn retro crossing).
- [x] Product repo clean (no product code written; throwaway scripts in /tmp only).

## STOP triggers fired: 0

## Open questions for TL (not blockers)

1. MVP "nearest return" date for an outer planet whose nearest contact is pass 1 of
   a retro loop: report pass 1 (literal first-after-today, owner's § 0 wording) or
   pass 3 `direct_return` (loop resolution)? Empirics + owner decision favour pass 1
   with the action window spanning passes 1→3.
2. Action-window orb for returns (memo says "~2 weeks"): outer-planet retro loops
   span ~9–10 months in-orb (Saturn loop 272 d). TL to confirm whether the displayed
   "~2 week" window is the tight conjunction orb (e.g. ±1°) vs the full loop span.
