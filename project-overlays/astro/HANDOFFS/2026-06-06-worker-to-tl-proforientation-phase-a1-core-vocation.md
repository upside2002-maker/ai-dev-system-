# HANDOFF: worker → tl — proforientation-phase-a1-core-vocation

- Status: ready-for-review
- Date: 2026-06-06 (executed 2026-06-07)
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-8
- Role mode: Worker (Tier A / strict)
- TASK: project-overlays/astro/TASKS/2026-06-06-proforientation-phase-a1-core-vocation.md
- Method extract: project-overlays/astro/RESEARCH/daragan-proforientation-method-extract.md
- Phase 0 HANDOFF: project-overlays/astro/HANDOFFS/archive/2026-06-06-worker-to-tl-proforientation-phase0-method-proof.md
- Memo: project-overlays/astro/ARCHITECTURE/proforientation-module-architecture-2026-06-06.md
- **Product repo status: committed (7dc313e on main; baseline 51f1e57)**

## Summary

Phase A1 of the proforientation epic: new pure-Core **`Domain.Vocation`**
implementing Daragan's career-guidance algorithm stages 1–4 + the missing factor
helpers + golden/unit tests. **NO schema/Bridge/Main (Phase A2); NO Python/PDF/UI
(Phase B).** All значимость-logic in core (bright line #7 / AST-ARCH-1).

**Both goldens reproduce the method. The Банкир golden reproduces Daragan's
published stage-1/2 table (printed p. 302) cell-by-cell on every enumerated cell
+ the top conclusion (Jupiter = упр.X в VIII → банкир). Marina top-3 =
Jupiter(X→II) / Venus / Sun, Moon & Neptune excluded.** `cabal test` 334/0; the
solar and returns goldens are **bit-identical (0 edits)**. 0 STOP triggers.

---

## Files changed (product, commit 7dc313e — 7 files, +1420)

New Core:
- `core/astrology-hs/src/Domain/Vocation.hs` — engine (stages 1–4) + factor
  table/combo output types + `rulersOfHouse` / `rulerOfSolarSign`.
- `core/astrology-hs/src/Domain/Vocation/Reception.hs` — mutual reception.
- `core/astrology-hs/src/Domain/Vocation/Satellites.hs` — Дорифорий/Возничий.
- `core/astrology-hs/src/Domain/Vocation/JonesPattern.hs` — bucket/sling handle.
- `core/astrology-hs/test/Test/Domain/VocationSpec.hs` — 55 tests (goldens + units).

Modified Core (wiring only):
- `core/astrology-hs/astrology-core.cabal` — 4 new lib modules + 1 test module.
- `core/astrology-hs/test/Spec.hs` — register VocationSpec.

NOT touched: schema/contracts, Bridge/*, app/Main.hs, Python, PDF, UI, existing
golden fixtures (`test/golden/` diff empty). Pre-existing untracked
(`_marina-deliverables`, `marketing-site/`, `services/api-python/data/`) and the
pre-existing `.claude/launch.json` modification were left out per Correction 008.

---

## Verification (run from `core/astrology-hs`)

```
PATH="/Users/ilya/.ghcup/bin:$PATH" cabal build   # clean, 0 warnings/errors
PATH="/Users/ilya/.ghcup/bin:$PATH" cabal test    # 334 examples, 0 failures
```

- **334 examples, 0 failures** (baseline 279 + 55 new Vocation). Verified on the
  committed state (HEAD = 7dc313e) after commit, per Correction 008.
- **Solar golden bit-identical** — `git diff --stat -- core/astrology-hs/test/golden/`
  is EMPTY. `Test.GoldenSolar` and `Test.GoldenReturns` pass unchanged. 0 expected
  edits, as required.
- `git status --short` clean for intended: only the 7 Core files staged/committed.

---

## Factor helpers built (A1.1)

| Helper | Module | Definition |
|---|---|---|
| **Mutual reception** | `Domain.Vocation.Reception` | symmetric; each planet in the other's domicile/exaltation sign; mixed domicile×exaltation allowed (`dignitySigns = exaltation : domicile`). Built from `Dignities` (grep 0 in core). |
| **Дорифорий / Возничий** | `Domain.Vocation.Satellites` | signed ecliptic separation from the Sun, normalised to (−180,180]; Дорифорий = nearest negative (before), Возничий = nearest positive (after); all 10 planets, no orb cap; `shortestArc` is unsigned so the signed helper lives here. |
| **Jones bucket/sling handle** | `Domain.Vocation.JonesPattern` | 360° distribution detector: remove each candidate, measure the other 9's span (smallest containing arc = 360 − largest gap); body span ≤126° ⇒ Sling, ≤186° ⇒ Bucket; candidate must be detached (≥40° from the nearer body edge). Sling beats Bucket; ties by detachment then enum. `Stellium` (per-house) is NOT reusable. |
| **House ruler** | `Domain.Vocation.rulersOfHouse` | cusp-sign rulers ∪ intercepted-sign rulers (the inverse of the cusp+intercepted loop in `Directions.housesForPlanet`), via `rulersOfSign`. |
| **Ruler of solar sign** | `Domain.Vocation.rulerOfSolarSign` | `rulersOfSign (signOf Sun)`. |

REUSED as planned: `planetInHouse`, `interceptedSigns`, `rulersOfSign`,
`isDomicile`/`isExaltation`, `findAspects`/`filterHarmonious`, `isAboveHorizon`.

---

## Engine (A1.2) — stages 1–4

- **Stage 1 realization:** per money house X/II/VI/VIII — (а) ruler, (б) planet-
  in-house, (в) conj∪harmonic to ruler. (г) reception is computed **per partner**
  (not per house) and deduped to ONE factor per reception pair, attributed to the
  partner's single best money-house role (ruler beats placement; best tier among
  rulerships). This reproduces Daragan's table, which records each reception once
  by its strongest role.
- **Stage 2 abilities:** Asc-ruler + 1st-house; Дорифорий/Возничий; domicile/
  exaltation; ruler-of-solar-sign; conj∪harmonic to Sun; single most-elevated
  (nearest MC among houses 7–12); Jones handle. **Fixed stars OMITTED** (no
  Daragan list — TL-locked).
- **Stage 3 filter:** keep planets in BOTH columns (realization ∧ abilities ≥1).
- **Stage 4 ranking:** key = (X-connection first, best house tier X>II>VI>VIII,
  total factor count desc, Planet enum). Top 3 combos.
- **Conjunction ∪ Harmonious is EXPLICIT** (`conjOrHarmonic` = aspectType==Conjunction
  OR in `filterHarmonious`); quincunx never enters (natal engine doesn't emit it).
  **No wildcard over Planet** (all sum-type matches enumerate constructors).
- Output = factor table (all 10 planets, Sun..Pluto) + ranked combos with machine
  factor keys. No interpretation text, no schema, no stage-5.

---

## Банкир golden — fidelity proof (the key deliverable)

Engine output vs Daragan's published table (printed p. 302), every enumerated cell:

| Daragan p. 302 | Engine | Match |
|---|---|---|
| упр.X = Jupiter | `rulersOfHouse 10` = [Jupiter] | ✓ |
| упр.II = Mars | [Mars] | ✓ |
| упр.VI = Moon | [Moon] | ✓ |
| упр.VIII = Venus | [Venus] | ✓ |
| упр.Асц = Uranus, соупр = Saturn | Asc Aquarius → [Uranus,Saturn] | ✓ |
| Sun = Пл.VIII + соед. упр.II,X | PlacedInHouse VIII + ConjOrHarmonicToRulerOf II + …X | ✓ |
| Moon = упр.VI + Пл.II / экзальт + ручка | RulerOfHouse VI + PlacedInHouse II / InDomOrExalt + JonesHandle | ✓ |
| Mercury = Пл.VIII + соед. упр.II,X | ✓ | ✓ |
| Venus = упр.VIII + рецепция с упр.X / упр.солн.знака + элевация | RulerOfHouse VIII + ReceptionWithRulerOf X / RulerOfSolarSign + MostElevated | ✓ |
| Mars = Пл.VIII + упр.II + соед.упр.X / соед.Солнце | ✓ / ConjOrHarmonicToSun | ✓ |
| Jupiter = Пл.VIII + упр.X + соед.упр.II + рец.упр.VIII + смеш.рец.пл.X / Дорифорий + соед.Солнце | RulerOfHouse X + PlacedInHouse VIII + ConjToRulerOf II + ReceptionWithRulerOf VIII + ReceptionWithPlanetInHouseOf X / IsDoryphoros + ConjToSun | ✓ |
| Saturn = Пл.X + смеш.рец.упр.X / соупр.Асц + секстиль Солнце | PlacedInHouse X + ReceptionWithRulerOf X / AscRuler + ConjOrHarmonicToSun | ✓ |
| Uranus = (real пусто) / упр.Асц | realization [] / AscRuler | ✓ |
| Neptune = Пл.VIII / Возничий | PlacedInHouse VIII / IsAuriga | ✓ |
| **Pluto = NOT a significator (both empty)** | realization [] + abilities [] | ✓ |
| **Дорифорий = Jupiter, Возничий = Neptune** | selectSatellites = (Just Jupiter, Just Neptune) | ✓ |
| Луна = ручка Пращи (handle planet = Moon) | detectJonesHandle → handle = Moon | ✓ |
| filtration: «целых пять» densely filled | Moon/Venus/Jupiter/Saturn all both-columns ≥2 each | ✓ |
| **conclusion: Jupiter упр.X в VIII** | top combo = Jupiter, connectedToX, placement VIII, RulerOfHouse X | ✓ |
| Jupiter > Луна (selection) | Jupiter ranks above Moon | ✓ |

**Every enumerated cell + the top conclusion reproduces Daragan.** Fidelity proven
on the published worked example.

### Two documented, non-load-bearing divergences (flagged, NOT massaged)

1. **Uranus «секстиль с Солнцем» (Daragan ability) is NOT reproduced.** Daragan's
   own chart has Uranus 16° Pisces (346°) vs Sun 17° Libra (197°) = **149° = a
   quincunx, not a sextile**. The TL-locked decision excludes quincunx from the
   harmonious set, and the natal engine doesn't emit it, so the engine gives
   Uranus abilities = {AscRuler} (1) instead of Daragan's {упр.Асц, секстиль}.
   **Impact: NONE.** Uranus has empty realization → filtered out either way; not
   in any combo; not an enumerated must-match cell. This is the book's loose
   quincunx-as-harmonious labelling vs our locked rule — reported, not fitted.

2. **Saturn carries two extra realization aspects the table omits.** Saturn 11°
   Sag (251°) forms real sextiles to Mars (191°, 60°) and Jupiter (194°, 57°) in
   addition to the Sun-sextile Daragan lists. The Libra cluster (Sun/Mars/Jupiter
   within ~6°) makes a Sun-sextile geometrically inseparable from sextiles to the
   others — true of Daragan's own degrees too; he simply recorded only the
   salient Sun one. Per the locked «Conjunction ∪ Harmonious» rule the engine
   includes them (no scope narrowing). **Impact: NONE on the conclusion** —
   Jupiter still ranks #1 (Jupiter & Saturn both Σ7, tie broken by enum:
   Jupiter < Saturn; and Saturn is планета-X not упр-X). Saturn does rank #2 in
   the combo list (Daragan compares Jupiter vs Moon narratively), but the optimum
   is unchanged.

---

## Marina golden (person 4)

Engine top-3 (matches Phase 0 manual run exactly):
1. **Jupiter** — ruler-of-X placed in II; connected {X,II,VI,VIII}; Σ7 (densest).
2. **Venus** — ruler-of-II, in I; Дорифорий; connected {X,II}; Σ6.
3. **Sun** — in I; connected {X,II,VIII}; Σ5.

**Moon & Neptune excluded** (empty abilities column). ✓

---

## Edge-case flags (for Marina / Reviewer)

- **Jones figure-type (Bucket vs Sling):** Daragan calls the Банкир figure «Праща»
  (Sling); the engine's geometric threshold classifies the 9-body span (~171°) as
  a Bowl→**Bucket**. The **handle PLANET is identical (Moon)** — that is what feeds
  stage-2(ж) — so the table cell matches; only the internal figure label differs.
  Jones figure-type is doctrine-loose at the boundaries (the memo/Phase-0 both
  flagged this). Synthetic unit tests cover clean Sling and clean Bucket cases.
- **Doryphory:** the simple nearest-before/after-Sun rule (Globa-school/Банкир),
  not strict Hellenistic — already flagged Phase 0; reproduces Банкир + Marina.
- **Reception with outer planets:** the locked formula (domicile/exaltation incl.
  modern outer-planet dignities) can form receptions classical-only analysis
  wouldn't (e.g. a raw «2° Scorpio» Neptune read would force a spurious
  Uranus↔Neptune reception). The Банкир fixture follows Daragan's table (Neptune
  in late Libra / house VIII, per the wheel + his «Планета VIII»), which avoids it;
  the engine's reception definition is unchanged.

---

## Golden fixtures

Both charts are embedded in `VocationSpec.hs` as synthetic positions+cusps (Core-
only, no external data files — same convention as the returns golden). Cusps are
chosen so each money-house cusp SIGN and every planet's HOUSE match Daragan/Phase-0
exactly; Placidus geometry is not replicated because the factor table depends only
on cusp signs + placements + longitudes. Банкир longitudes transcribed from the
p. 301 wheel (rendered at 400 DPI and read glyph-by-glyph); Marina from the Phase 0
HANDOFF § 4 (consultation 15 facts_json).

---

## Self-review checklist

- [x] Factors built (reception, doryphoros/auriga, Jones bucket/sling, house-ruler, ruler-of-solar-sign).
- [x] Stages 1–4 → top-2–3 combos + factor table; no stage-5/schema/output.
- [x] Банкир golden reproduces Daragan's table + conclusion (comparison above).
- [x] Marina top-3 = Jupiter(X→II)/Venus/Sun; Moon & Neptune excluded.
- [x] Conjunction∪Harmonious union explicit; quincunx excluded; fixed stars omitted; no invented factors.
- [x] cabal build+test green (334/0); solar golden bit-identical (0 edits — stated, diff empty); no wildcard over Planet.
- [x] No A2/B scope; product committed (7dc313e); overlay committed (this HANDOFF + journal).
- [x] Backups pushed; parity verified.

## Reviewer-Ready (Tier A — independent Reviewer required, Correction 021)

TL spawns a separate Reviewer session. Confirm:
1. **Банкир golden reproduces Daragan** (p. 302 table cell-by-cell + conclusion
   Jupiter упр.X в VIII) — comparison table above; 2 flagged non-load-bearing
   divergences (Uranus-quincunx, Saturn-extra-aspects) with NONE impact.
2. **Marina top-3** = Jupiter(X→II)/Venus/Sun; Moon & Neptune excluded.
3. **Factor correctness vs method:** reception (symmetric domicile/exaltation,
   mixed allowed, per-partner dedup), doryphoros/auriga (nearest before/after Sun),
   Jones (bucket/sling handle, handle planet feeds 2ж).
4. **Solar golden bit-identical** (`test/golden/` diff empty; GoldenSolar passes).
5. **No wildcard over Planet, no quincunx in harmonious, no invented factors, no
   fixed-star list.**
6. **0 STOP triggers.**

## Open questions for TL

- The 2 flagged divergences (Uranus-quincunx, Saturn-extra-aspects) are inherent to
  reproducing a hand-analysed chart with a uniform mechanical aspect rule; both are
  non-load-bearing. Confirm the golden's «assert Daragan's cells are PRESENT»
  (`shouldContain`) approach is acceptable vs «row is EXACTLY equal».
- Carried from Phase 0 (not blocking A1): benefic-star list (omitted v1), doryphory
  rule sign-off, Jones figure-type labelling, additional reference charts for golden.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
