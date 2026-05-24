# HANDOFF: worker → tl — intercepted-sign-rulership-fix

- Status: open
- Date: 2026-05-24 10:11
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7[1m]
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-24-intercepted-sign-rulership-fix.md

## Summary

**Stage 0 STOP gate triggered (Path A).** Worker выполнил все 5 sub-stages эмпирического baseline согласно clarification 6 = (a). Все три chart layers, доступные в системе (natal Placidus / solar Placidus / whole-sign natal), **противоречат user expectations** (Mars → 1, Uranus → 11/12, Venus → 7, Useful people Scorpio/Taurus axis). Никакой стандартной интерпретации, при которой ожидаемый mapping получается из cusps Ольги, обнаружить не удалось. Worker НЕ фабрикует и НЕ трогает product code — требуется user clarification до Stage 1.

## Done

### Stage 0.1 — Chart layer identification

**Engine emission inventory (Olga consultation 12):**
- `facts.natal_chart.house_systems` keys: `['Placidus']` only — whole-sign **не emit'ed** engine'ом.
- `facts.solar_chart.house_systems` keys: `['Placidus']` only.
- Direct DB inspection: `consultations.facts_json` для id=12 содержит **только Placidus** для обеих карт.

**Callsite-level data flow (current production):**
- `app/pdf/outer_cards.py:1907` — `_build_generic_card`: `cusps = _natal_cusps(natal_chart)` → читает **natal Placidus cusps**.
- `app/pdf/outer_cards.py:1938-1939` — `rulership_houses(tp, cusps)` / `rulership_houses(tgt, cusps)` → **natal Placidus**.
- `app/pdf/transit_themes.py:49,1193` — `_target_house_set(tgt, natal_chart)` → **natal Placidus** через `natal_chart.house_systems.Placidus.cusps`.
- `app/pdf/synthesis_themes.py:1531` — `_useful_people_block` использует `_solar_asc_sign(facts) or _natal_asc_sign(facts)` (solar Placidus с natal fallback), и `_solar_mc_sign(...) or _natal_mc_sign(...)`. Не использует rulership_houses helper'а.

**Calibrated path (outer_cards.py:1297-1304):** `_OUTER_CARD_FACTS` row 3 «Управление домами радикса» reads **curated** `facts.transit_ruled_houses` / `target_ruled_houses` per-case dict — **не auto-derived** через helper. Изменение helper'а не повлияет на calibrated cards (rows 01/02/03/04/05/08/09/10).

**Generic path (outer_cards.py:1938-1939):** auto-derived через `rulership_houses(...)` — изменение helper'а изменит generic-fallback outer cards (Olga consultation 12 — generic path, `case_label=None`).

**Verdict 0.1:** Chart layer однозначно identifiable. Текущая логика:
- Outer cards «Управление домами радикса»: **natal Placidus cusps** (для generic path; calibrated curated).
- Calendar «Дома цели»: **natal Placidus cusps** + placement.
- Useful people: natal/solar Asc + natal/solar MC + natal 1st-house planets + natal Sun sign (НЕ использует rulership_houses helper).

### Stage 0.2 — Olga's intercepted signs per house (natal Placidus)

Cusps Ольги (DB-verified, round 2 decimals matches TASK prelim exactly):
```
[94.15, 108.33, 123.56, 143.31, 173.99, 224.85, 274.15, 288.33, 303.56, 323.31, 353.99, 44.85]
```

**Strict intercepted signs** (signs fully contained, per clarification 2 = (a)):

| Дом | Cusp | Arc° | Cusp sign | Intercepted | All signs |
|---|---|---|---|---|---|
| 1  | 4°09′ Cancer       | 14.18 | Cancer       | —             | Cancer |
| 2  | 18°20′ Cancer      | 15.23 | Cancer       | —             | Cancer |
| 3  | 3°34′ Leo          | 19.75 | Leo          | —             | Leo |
| 4  | 23°18′ Leo (IC)    | 30.68 | Leo          | —             | Leo |
| 5  | 23°59′ Virgo       | 50.86 | Virgo        | **Libra**     | Virgo, Libra |
| 6  | 14°51′ Scorpio     | 49.30 | Scorpio      | **Sagittarius** | Scorpio, Sagittarius |
| 7  | 4°09′ Capricorn    | 14.18 | Capricorn    | —             | Capricorn |
| 8  | 18°20′ Capricorn   | 15.23 | Capricorn    | —             | Capricorn |
| 9  | 3°34′ Aquarius     | 19.75 | Aquarius     | —             | Aquarius |
| 10 | 23°18′ Aquarius (MC)| 30.68 | Aquarius    | —             | Aquarius |
| 11 | 23°59′ Pisces      | 50.86 | Pisces       | **Aries**     | Pisces, Aries |
| 12 | 14°51′ Taurus      | 49.30 | Taurus       | **Gemini**    | Taurus, Gemini |

**Correction to TL prelim:** TL prelim said «Дом 5 Libra intercepted, Дом 6 Sagittarius intercepted, Дом 11 Aries intercepted, Дом 12 Gemini intercepted» — **confirmed exactly**. (Worker первый прогон содержал bug в intercepted algorithm — fixed; final inventory выше match TL prelim.)

### Stage 0.3 — Current vs new rulership comparison (natal Placidus)

| Planet | Rules | Current (cusp-only) | New (with intercepted) | Diff |
|---|---|---|---|---|
| Sun     | Leo                  | [3, 4]        | [3, 4]        | — |
| Moon    | Cancer               | [1, 2]        | [1, 2]        | — |
| Mercury | Gemini, Virgo        | [5]           | [5, **12**]   | +12 (Gemini intercepted в 12) |
| Venus   | Taurus, Libra        | [12]          | [**5**, 12]   | +5 (Libra intercepted в 5) |
| Mars    | Aries, Scorpio       | [6]           | [6, **11**]   | +11 (Aries intercepted в 11) |
| Jupiter | Sagittarius, Pisces  | [11]          | [**6**, 11]   | +6 (Sagittarius intercepted в 6) |
| Saturn  | Capricorn, Aquarius  | [7, 8, 9, 10] | [7, 8, 9, 10] | — |
| Uranus  | Aquarius             | [9, 10]       | [9, 10]       | — |
| Neptune | Pisces               | [11]          | [11]          | — |
| Pluto   | Scorpio              | [6]           | [6]           | — |

### Stage 0.4 — Useful people empirical (Olga)

| Field | Empirical value |
|---|---|
| Natal Asc | **4°09′ Cancer** (lon 94.15) |
| Natal MC  | 23°18′ Aquarius (lon 323.31) |
| Solar Asc | **9°29′ Libra** (lon 189.48) |
| Solar MC  | 13°03′ Cancer (lon 103.05) |
| Natal Дом 1 cusp sign | **Cancer** |
| Natal Дом 1 intercepted | — (arc 14°) |
| Natal Дом 7 cusp sign | **Capricorn** |
| Natal Дом 7 intercepted | — (arc 14°) |
| Natal 1st-house planets | **Mars** (Cancer, 9°51′, h=1) |
| Natal Sun | Cancer, h=2 |

**Axis 1-7 natal: Cancer ↔ Capricorn.** NOT Scorpio/Taurus. Solar Asc Libra (NOT Scorpio nor Taurus).

### Stage 0.5 — STOP gate evaluation

**User expectations** (from § Problem):
1. Mars co-rules **Дом 1** (Aries intercepted в 1).
2. Uranus rules **11, 12**.
3. Jupiter co-rules **1, 9, 10**.
4. Venus co-rules **7** (Taurus intercepted).
5. Useful people axis: **Скорпион / Телец**; солнечные Тельцы / Скорпионы; Венера / Марс / Плутон в Доме 1.

**Empirical reality across all available chart layers:**

| User-expected fact | Natal Placidus | Solar Placidus | Whole-sign natal (Cancer-rising) |
|---|---|---|---|
| Aries в Дом 1 (Mars co-rules) | Aries intercepted в Дом **11** | Aries cusp Дом **7** | Aries в Дом **10** |
| Aquarius в Дом 11/12 (Uranus rules) | Aquarius cusp Дом **9, 10** | Aquarius cusp Дом **5** | Aquarius Дом **8** |
| Sag/Pisces в Дом 1/9/10 (Jupiter co-rules) | Sag intercepted в **6**, Pisces cusp **11** | Sag cusp **3**, Pisces cusp **6** | Sag Дом **6**, Pisces Дом **9** |
| Taurus в Дом 7 (Venus co-rules) | Taurus cusp Дом **12** | Taurus cusp Дом **8** | Taurus Дом **11** |
| Asc Scorpio/Taurus (Useful people) | Cancer | Libra | Cancer |

**ZERO out of 5 user expectations подтверждаются эмпирически.** Ни Placidus natal, ни Placidus solar, ни whole-sign natal не дают user-expected mapping. Все 5 ожиданий противоречат фактическим cusps Ольги.

**STOP triggers fired:**
- «Stage 0 empirics ≠ user expectations» (TASK § STOP triggers).
- «Worker fabricates Useful people Scorpio/Taurus axis when natal Asc = Cancer» — Worker NOT going to do this.

**Verdict: STOP. Path A submit.**

Helper change (`house_signs` + `rulership_houses` intercepted-aware extension) **does** add valid intercepted signs (Mercury +12, Venus +5, Mars +11, Jupiter +6) — это **корректный fix** для generic outer cards и calendar «Дома цели». НО **этот fix не даёт user-expected mapping** (Mars → 1, Uranus → 11/12, Venus → 7, Jupiter → 1/9/10). Помещение Mars в Дом 1 потребует **фабрикации** — что прямо запрещено STOP triggers.

## Remaining

**Pending user clarification (before Stage 1 implementation can proceed):**

Один или несколько возможных путей resolution (user должен выбрать):

1. **User revises expectations to match empirics.** Принять, что для Ольги по фактическим Placidus cusps:
   - Mars rules {6, 11} (через Scorpio cusp 6 + Aries intercepted 11).
   - Uranus rules {9, 10}.
   - Jupiter rules {6, 11}.
   - Venus rules {5, 12}.
   - Useful people axis = Cancer / Capricorn (natal) + Libra (solar Asc, NOT Scorpio).
   - Then Stage 1-6 implements intercepted-sign helper as scoped, и acceptance tests pin to **эмпирические** значения, not original user-quoted values.

2. **User changes natal/solar chart layer assumption.** Если user counts a different chart (e.g. transit-progressed, или specific date-of-consultation chart), потребуется доказать, какой именно layer + house system, и engine emit'ed ли он. **Сейчас engine emit'ит только Placidus.** Whole-sign требует engine extension (out-of-scope, Tier A).

3. **User reveals different rulership convention.** E.g. esoteric / hermetic / Egyptian terms / classical-only convention. PLANET_RULES currently locks in «modern + classical co-rulers» per Phase 0.4 Архипова lock-in. Изменение convention — отдельный schema-change decision.

4. **User reconsiders chart identity.** Возможна спутанность с другой карой клиента. Worker может проверить consultations 10/11 (другие Ольгины solar) или другие persons.

Worker НЕ может выбрать вариант самостоятельно (фабрикация запрещена).

## Artifacts

- branch:               main (overlay master)
- commit(s):            **none on product** (Path A — product не менялся, Worker остаётся на baseline 732759d)
                        overlay commit(s) ниже создаёт TL после accept-handoff либо Worker сам перед submit-task
- PR:                   (н/д — overlay-only)
- tests:                pytest 673 passed + 3 skipped + 0 failed (baseline preserved, Worker NOT touched product)
- Product repo status:  not applicable
                        — Stage 0 STOP fired до Stage 1; product code untouched per Path A submit procedure.

Stage 0 inventory artifacts:
- DB facts read directly from `/Users/ilya/Projects/astro/data/astro.db` consultations.id=12 facts_json (Olga, solar_year=2026).
- Engine emission verified: only Placidus в house_systems (natal + solar).
- Olga natal cusps round 2 decimals match TASK § Stage 0 caveat prelim exactly.

## Conflicts / risks

### Discrepancy table (re-stated for TL escalation)

User expectations cannot be reconciled с empirical Olga chart facts через standard astrology rules:

```
Expected: Mars co-rules Дом 1 (Aries intercepted в 1)
Actual:   Aries intercepted в Дом 11 (natal Placidus)
Reason:   Дом 1 arc = 14.18° (4°09'-18°20' Cancer) — single sign, no intercepted.
          Aries is fully intercepted only between Pisces cusp (Дом 11) and Taurus cusp (Дом 12).

Expected: Uranus rules Дом 11, 12
Actual:   Aquarius cusps Дом 9, 10
Reason:   Aquarius starts at cusp 9 (3°34' Aqu) and continues to cusp 10 (23°18' Aqu).
          The next cusp (Дом 11) is 23°59' Pisces — Aquarius is NOT intercepted в Дом 10.
          No Aquarius in Дом 11 nor Дом 12.

Expected: Jupiter co-rules Дом 1, 9, 10
Actual:   Sagittarius intercepted в Дом 6; Pisces cusp Дом 11
Reason:   Sag arc на cusps 6 (between Scorpio cusp + Capricorn cusp). Pisces cusp 11.
          Neither Sag nor Pisces в Доме 1, 9, или 10.

Expected: Venus co-rules Дом 7 (Taurus intercepted)
Actual:   Taurus cusp Дом 12; Libra intercepted в Дом 5
Reason:   Taurus arc = cusp 12 → cusp 1, NOT intercepted в Доме 7.
          Дом 7 cusp = Capricorn (Saturn-ruled), arc 14°. No Taurus / Libra.

Expected: Useful people «Асц в Скорпионе или Тельце; Венера/Марс/Плутон в 1 доме»
Actual:   Natal Asc = 4° Cancer; Solar Asc = 9° Libra; в natal Доме 1 — только Mars.
Reason:   Cancer-rising (natal); Libra-rising (solar). Scorpio/Taurus не появляются как Asc
          ни в одной из доступных карт. Pluto natal h=5, Venus natal h=4 — НЕ в Доме 1.
          Только Mars natal h=1 совпадает с user expectation.
```

### Operational risks

- **NO product code change** в этом cycle. Worker remains на baseline 732759d.
- **NO test additions** — Stage 5 tests deferred until Stage 1 unblocked.
- **Calibrated cards safe:** `_OUTER_CARD_FACTS` ничего не теряет — Stage 3 escalation NOT fired (helper change может произойти только после Stage 0 PASS).
- **Generic outer cards для Ольги остаются текущими** (Mars → [6], Uranus → [9, 10], etc. per current cusp-only logic).
- **NO regression risk** этого cycle: эмпирический inventory только; никакого product mutation.

### TL recommendation (Worker-derived)

Поскольку Stage 0 показывает **последовательные** empirical findings для Ольги:
- TL может escalate user к выбору одного из 4 paths в «Remaining» секции.
- При выборе path 1 (revise expectations): Worker может выполнить Stages 1-6 за один cycle с эмпирическими acceptance criteria. Helper'а fix всё ещё valuable: Mars +Дом 11, Venus +Дом 5, Mercury +Дом 12, Jupiter +Дом 6 — реальные intercepted-sign rulerships, которые сейчас выпадают. Calendar «Дома цели» benefit'нет правильно. Useful people rewrite остаётся valid (axis 1-7 = Cancer/Capricorn по фактическим cusps).
- При выборе path 2 (whole-sign): требуется engine extension (Tier A, out-of-scope TASK).
- При выборе path 3 (different rulership): требуется PLANET_RULES schema change (отдельный TASK).
- При выборе path 4 (chart identity): re-inventory consultations 10/11.

## Next step

**TL action required:** Read this HANDOFF + escalate user с discrepancy table выше + request clarification по одному из 4 paths.

**Reviewer:** Per TASK § Reviewer policy — REQUIRED post-implementation. Поскольку Stage 0 STOP fired, Reviewer pass deferred until user resolves discrepancy и Worker завершает Stages 1-6.

**Worker stays at baseline.** Готов re-engage после user clarification — повторный spawn с обновлённым acceptance criterion (e.g. «Mars → {6, 11}» если path 1 принят).
