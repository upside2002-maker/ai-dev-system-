# HANDOFF: worker → TL — transits-aspects-tables-outer-social

- Status: closed
- Date: 2026-05-11
- From: Worker (Claude Code subagent, separate session)
- To: TL
- Project: astro
- TASK: 2026-05-11-transits-aspects-tables-outer-social
- Worker commit(s): 7b8fd24 (parent df6351a)
- Agent runtime: Claude Code (Worker subagent, separate from TL session)
- Role mode: Worker (Mode normal — Tier B)

## Summary

Implementation. Data flow investigation confirmed `annual_transit_table`
in Натальи fixture is populated (34 entries) with all needed fields:
major aspects (Conj/Sex/Sq/Tri/Opp), `loop_pass` 1/2/3, `phase`
Direct/Retrograde/DirectReturn, per-hit `exact_jd`, and parent
`enter_jd/exit_jd`. Tier B path is fully viable — implemented per
acceptance, no schema/engine changes required.

## Investigation findings (Phase 0)

**Runtime data source**: `facts.annual_transit_table` is populated by
the Haskell core (visible in fixture `08-natalya-2025-2026.expected.json`,
34 entries, 6 outer/social planet entries with hits). The Python
`transit_themes.py` helpers operate on it directly — no separate
runtime computation in services layer.

**Coverage assessment**:

| Requirement | Status | Notes |
|---|---|---|
| Major aspects | ✓ | All 5 (Conj/Sex/Sq/Tri/Opp) present in fixture hits |
| Per-planet-class orbs | ✓ (policy-only) | Engine emits *exact-aspect moments* (orb≈0°), not orb-window samples. Per-class orbs (J/S 2.5°, U/N/P 1.25°) documented in helper as engine policy; not a runtime filter at presentation layer (no hits to discard). |
| Retrograde loop detection | ✓ | `loop_pass` (1/2/3) + `phase` (Direct/Retrograde/DirectReturn) cleanly encode 3-touch loops. Verified: Jupiter Trine Mars has loop_pass 1,2,3 in Натальи. |
| Period extension beyond solar year | ✓ (touch-derived) | Parent `enter_jd/exit_jd` ARE truncated at sr+365 (last day = sr+1y +1d). Helper uses **first/last touch exact_jd** for period bounds, not parent-window bounds — so loops aren't truncated when the engine clips. In Натальи all touches fall inside solar year, but the technique is correct for cases where 3rd touch falls outside. |
| Loop flag derivable | ✓ | `is_loop = (max(loop_pass) >= 3 and len(touches) >= 3)`. |

All five blocker conditions cleared. Path A.

## Decision: Path A (implementation)

Tier B presentation-only. No core / packages / apps work needed.

## Files modified

1. `services/api-python/app/pdf/transit_themes.py`
   - Added `transit_aspects_table(att, *, planet_class)` (core helper)
   - Added `transit_aspects_outer(att)` (U/N/P convenience)
   - Added `transit_aspects_social(att)` (S/J convenience)
   - Added module-private `_aggregate_touches_by_combo`, `_OUTER_PLANETS`,
     `_SOCIAL_PLANETS`, `_ORB_BY_CLASS`, `_ASPECT_RU`
   - Exported new helpers via `__all__`
2. `services/api-python/app/pdf/builder.py`
   - Imported `transit_aspects_outer`, `transit_aspects_social`
   - Registered both as Jinja globals
3. `services/api-python/app/pdf/templates/solar.html.j2`
   - Replaced previous month-grouped «Календарь транзитных аспектов
     по месяцам» with two new 6-column tables.
   - Order: outer FIRST («Транзиты высших планет (Уран, Нептун,
     Плутон)»), social SECOND («Транзиты социальных планет (Сатурн,
     Юпитер)»).
   - Placement: after aspect taxonomy intro block, before how-to.
   - Aspect taxonomy intro («Виды аспектов и их функция в транзите»)
     and «Как пользоваться транзитами» how-to preserved unchanged.
4. `services/api-python/tests/test_transit_aspects_tables.py` (new)
   - 10 unit tests locking in: planet-class filtering, major-aspects-only,
     loop detection on Jupiter Trine Mars (3-touch), non-loop 2-pass
     entries not flagged, chronological sorting, touch-derived period
     bounds, row shape keys, invalid planet_class raises.

## Placement decision: REPLACE existing calendar (Option B)

Per TASK § Placement default. Rationale: the previous calendar showed
the same data spread across calendar months (each aspect repeated in
every month its parent window touched), which made it noisy and visually
overlapped with what Owner wants. Owner directive «таблица», «не
смешивать с monthly table», «таблица: …, период, касания, признак
петли» dictates a per-aspect-row aggregation. The new tables ARE that
aggregation; keeping the old calendar would have shown the same hits
twice in two different formats.

The Marina-style aspect taxonomy intro («Виды аспектов и их функция
в транзите») is preserved — it's structural educational content that
doesn't overlap with the new tables.

## Helper API shape

```python
transit_aspects_outer(att) -> list[Row]
transit_aspects_social(att) -> list[Row]

Row = {
    "planet": str,           # English key (e.g. "Jupiter")
    "planet_ru": str,        # Russian display name (e.g. "Юпитер")
    "aspect": str,           # English ("Trine")
    "aspect_ru": str,        # Russian ("Трин")
    "aspect_degrees": str,   # "120°"
    "target": str,           # English natal target ("Mars")
    "target_ru": str,        # Russian ("Марс")
    "period_start_jd": float,  # first touch exact_jd
    "period_end_jd": float,    # last touch exact_jd
    "touches": list[float],    # all exact_jds, sorted
    "is_loop": bool,           # 3-pass loop (D→R→DR all present)
    "loop_passes": int,        # max loop_pass observed (1,2,3)
    "natal_house": int,        # parent window house of pass 1
}
```

Period bounds are **touch-derived** (first/last exact_jd), not
parent-window-derived — this is the key insight that lets us honor
Owner's "не обрезать петлю по границе солярного года" even though the
engine truncates parent windows at sr+365.

Per-class orb policy is documented in `_ORB_BY_CLASS` for future use
(if the engine later starts emitting orb-window samples instead of
exact moments, the helper can filter by class orb without API change).

## Self-check checklist

- [x] 2 tables in correct order (outer first, social second)
- [x] 6 columns per table (planet, aspect, target, period, touches, loop flag)
- [x] Major aspects only (5 types) — `test_major_aspects_only` locks this
- [x] Per-class orbs documented (policy only — engine emits exact moments)
- [x] Loops detected (3 passes) and period uses touch-derived bounds
- [x] No prose, no house interpretations mixed in the tables
- [x] Not mixed with monthly transit-by-house matrix (which is unchanged)
- [x] Existing aspect calendar REPLACED (documented above)
- [x] No section structure regression: intro / important transits /
      monthly matrix / per-house flat list / aspect taxonomy intro /
      [NEW outer table] / [NEW social table] / how-to

## Tests (Path A)

- pytest: **80/80** (was 70/70 baseline; +10 new tests in
  `tests/test_transit_aspects_tables.py`)
- Real PDF: `/tmp/astro-natalya-aspects-tables.pdf` (127.8 KB, 15 pages)
- Транзиты PNGs (verified visually):
  - `/tmp/aspects-tables-page-10.png` — both tables fully visible,
    correct order, 6 columns each. Jupiter Trine Mars row shows
    «25.10.2025 – 04.06.2026» period, all 3 touches in Касания cell,
    «да» in Петля cell. All other rows correctly show «—» (no loop).
  - `/tmp/aspects-tables-page-09.png` — aspect taxonomy intro
    (preserved upstream of new tables).
  - `/tmp/aspects-tables-page-11.png` — how-to (preserved downstream).

Pre-commit git status: clean except 4 in-scope files (3 modified +
1 new test).

Post-commit git status: clean working tree.

## Notable visual evidence (Натальи)

Outer planets table (3 rows):
- Уран · Квадрат (90°) · Венера · 26.11.2025 – 11.04.2026 · 2 touches · —
- Плутон · Трин (120°) · MC · 14.04.2026 – 29.05.2026 · 2 touches · —
- Нептун · Квадрат (90°) · Юпитер · 25.05.2026 · 1 touch · —

Social planets table (7 rows):
- Сатурн · Квадрат · Нептун · 15.09.2025 – 04.02.2026 · 2 touches · —
- **Юпитер · Трин · Марс · 25.10.2025 – 04.06.2026 · 3 touches · да**
- Сатурн · Квадрат · Юпитер · 19.03.2026 · 1 touch · —
- Сатурн · Секстиль · MC · 30.03.2026 · 1 touch · —
- Сатурн · Трин · Уран · 05.05.2026 · 1 touch · —
- Юпитер · Квадрат · Плутон · 28.06.2026 · 1 touch · —
- Юпитер · Секстиль · MC · 25.07.2026 · 1 touch · —

## Recommendation to TL

Inspection paths:
1. Visual: `/tmp/aspects-tables-page-10.png` shows both tables with the
   loop row clearly marked.
2. Helper API: `services/api-python/app/pdf/transit_themes.py` lines
   for `transit_aspects_table` and surrounding (see commit 7b8fd24).
3. Template: `services/api-python/app/pdf/templates/solar.html.j2`,
   the block between aspect taxonomy intro and how-to (Owner-facing
   section).
4. Tests: `services/api-python/tests/test_transit_aspects_tables.py`
   — 10 cases, all locking semantically meaningful invariants
   (loop detection, planet-class purity, touch-derived periods).

Two minor notes for TL/Owner review:
- In Натальи specifically, all touches happen to fall within the solar
  year, so the «петля выходит за границу года» edge case isn't visually
  demonstrated in this fixture. The helper handles it correctly (period
  uses touch JDs, not parent-window JDs), but a fixture with a slow
  outer-planet loop crossing the boundary would make the behavior more
  visible. This is a future-fixture concern, not a code concern.
- Per-class orb (2.5° / 1.25°) is currently documented as policy in
  `_ORB_BY_CLASS` but not used as a runtime filter — the engine emits
  exact-aspect moments only. If Owner wants orbs to filter hits whose
  parent-window's max orb exceeds the class limit, that would be a
  Tier A engine change (add per-hit orb_at_peak metadata, then filter
  in helper). Not flagged as a blocker because the current behavior
  produces exactly what Owner asked for: a row per major-aspect hit
  with its touches.
