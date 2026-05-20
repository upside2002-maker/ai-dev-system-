# HANDOFF: worker → tl — current-year-generic-cards-and-psychology-upgrade

- Status: closed
- Date: 2026-05-20
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-20-current-year-generic-cards-and-psychology-upgrade.md
- Product repo status: committed + pushed (1 product commit `9c800e7`)
- Overlay repo status: pending (HANDOFF + STATUS_RU; one overlay commit)
- Risk tier: B+ (two-concern: filter logic + phrase library; new tests; no architecture rewrite; no engine touch; no calibrated data touch)
- Reviewer policy: REQUIRED per clarification 5 = (a)
- Reviewer status: Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 9th occurrence) → Worker self-review applied; TL must spawn external Reviewer per TASK clarification 5.

## Summary

Two-bug fix delivered in single product commit `9c800e7`:

**Bug 1** — `generic_outer_cards` (`services/api-python/app/pdf/outer_cards.py`) теперь применяет solar-year overlap filter после `aggregate_display_windows`: окна полностью вне `[SR, SR+365.25]` отбрасываются (Guard #2 — strict; no «context» retention), карты без окон в году дропаются целиком (card-level). Filter scope — **только generic-fallback path**; calibrated allowlist branch bit-identical (Guard #1). Fixes Phase 8E ±730d buffer leak: Olga consultation 12 теряет 5 cards (всех окна вне SR'2026 года).

**Bug 2** — Новый `_SPECIFIC_PSYCHOLOGY_RU` override dict (10 entries) добавлен между same-planet routing (priority 1) и hybrid fallback (priority 3). Каждая entry — single coherent paragraph с aspect-tone descriptor («Гармоничный / Напряжённый / Глубинный») вплетённым natural внутри (NOT mechanical prefix assembly). Mandatory minimum 4 entries + 6 archetypal additions. Layer-separation сохраняется (no houses), empty-string fallback сохраняется (no generic padding), no Daragan verbatim copy.

**Pytest 565 → 619 passed + 3 skipped + 0 failed (+54 new tests). Cabal: clean. Product `9c800e7`. Calibrated 8/8 bit-identical (Guard #1 verified).**

## Stage 1 — Current-year overlap filter (Bug 1)

### 1.1 — Helper functions added (before `generic_outer_cards`)

```python
_SOLAR_YEAR_DAYS = 365.25  # Tropical year approximation; clarification 1

def _window_overlaps_year(window, solar_start, solar_end) -> bool:
    """Return True iff the window overlaps [solar_start, solar_end]."""
    try:
        enter = float(window.get("orb_enter_jd", 0.0))
        exit_ = float(window.get("orb_exit_jd", 0.0))
    except (TypeError, ValueError):
        return False
    return (exit_ >= solar_start) and (enter <= solar_end)

def _filter_windows_to_current_year(windows, solar_start, solar_end):
    """Filter `windows` to those overlapping `[solar_start, solar_end]`.
    Strict per Guard #2; re-numbers touch_index 1..N over survivors."""
    kept = [
        w for w in (windows or [])
        if _window_overlaps_year(w, solar_start, solar_end)
    ]
    for i, w in enumerate(kept, start=1):
        w["touch_index"] = i
    return kept
```

### 1.2 — Filter applied in `generic_outer_cards` loop

```python
# Boundary parsing (defensive — None falls back to no filter, не silent drop).
solar_chart = facts.get("solar_chart") or {}
try:
    solar_start = float(solar_chart.get("return_jd"))
except (TypeError, ValueError):
    solar_start = None
solar_end = (solar_start + _SOLAR_YEAR_DAYS if solar_start is not None else None)

# Inside the triple loop, after aggregate_display_windows:
if solar_start is not None and solar_end is not None:
    windows = _filter_windows_to_current_year(windows, solar_start, solar_end)
    if not windows:
        continue  # Card-level filter: zero in-year windows → drop card.
```

### 1.3 — Before/after: Olga consultation 12 generic cards

**Before filter (11 cards, post-Phase-8E buffer):**

| # | Card | Windows in-year / out-of-year | Verdict |
|---|---|---|---|
| 1 | тр Уран в секстиле c нат Меркурием | 0 / 3 | **DROP** |
| 2 | тр Уран в квадрате c нат Луной | 0 / 3 | **DROP** |
| 3 | тр Уран в квадрате c нат Венерой | 1 / 2 | KEEP (1 window) |
| 4 | тр Уран в оппозиции c нат Юпитером | 1 / 2 | KEEP (1 window) |
| 5 | тр Уран в оппозиции c нат Ураном | 2 / 1 | KEEP (2 windows) |
| 6 | тр Нептун в квадрате c нат Марсом | 0 / 2 | **DROP** |
| 7 | тр Нептун в квадрате c нат Нептуном | 0 / 1 | **DROP** |
| 8 | тр Нептун в тригоне c нат Юпитером | 1 / 2 | KEEP (1 window) |
| 9 | тр Нептун в тригоне c нат Ураном | 1 / 3 | KEEP (1 window) |
| 10 | тр Плутон в секстиле c нат Юпитером | 0 / 3 | **DROP** |
| 11 | тр Плутон в секстиле c нат Ураном | 3 / 1 | KEEP (3 windows) |

**After filter (6 cards, dropped 5):**

```
1. тр Уран в квадрате c нат Венерой       (1 окно: 01.12.2026 – 15.04.2027)
2. тр Уран в оппозиции c нат Юпитером     (1 окно: 28.12.2026 – 22.03.2027)
3. тр Уран в оппозиции c нат Ураном       (2 окна: лето 2026, май-июнь 2027)
4. тр Нептун в тригоне c нат Юпитером     (1 окно: окт 2026 – фев 2027)
5. тр Нептун в тригоне c нат Ураном       (1 окно: апр – июнь 2027)
6. тр Плутон в секстиле c нат Ураном      (3 окна: фев-июл 2026, дек-мар 2027, лето 2027)
```

`тр Уран в секстиле c нат Меркурием` теперь absent (все 3 windows = 13.07-13.08.2024 / 20.09-20.11.2024 / 08.04-14.05.2025 → ВСЕ вне SR'2026 = 2026-07-13 .. 2027-07-13).

### 1.4 — Calibrated regression proof (Guard #1)

Filter applies ONLY в generic-fallback path. Calibrated cases routed через `outer_cards_for_case → identify_cards_for_case → build_outer_card` — НЕ касается `generic_outer_cards`. Verified:

- `test_calibrated_cards_bit_identical_except_provenance` — PASS for all 8 calibrated cases.
- `test_calibrated_cards_keep_multi_year_windows` (NEW, parametrized × 9) — каждый calibrated case сохраняет полный display_windows count.
- `test_calibrated_kseniya_has_out_of_year_windows_preserved` (NEW, concrete spot-check) — case 01 Уран опп Солнце multi-year sweep 2024-2026 keeps both out-of-year windows.

Calibrated multi-year window counts preserved (verified via direct trace):
- 01-kseniya: Уран опп Солнце `1 in / 2 out` (total 3) — all 3 preserved.
- 01-kseniya: Плутон тригон Юпитер `1 in / 3 out` (total 4) — all 4 preserved.
- 08-natalya: Нептун кв Юпитер `1 in / 2 out` (total 3) — all 3 preserved.
- 10-danila: Нептун кв Юпитер `1 in / 3 out` (total 4) — all 4 preserved.

`_OUTER_CARD_FACTS` / `OUTER_CARD_ALLOWLIST` / `build_outer_card` UNTOUCHED.

## Stage 2 — Specific psychology override dict (Bug 2)

### 2.1 — `_SPECIFIC_PSYCHOLOGY_RU` design (10 entries)

Coverage spans 3 outer-planet transits × 5 aspects × multiple personal/social/outer targets. Each entry:
- Single coherent paragraph (~50-65 words).
- Aspect tone descriptor вплетён natural в opening clause.
- Archetype-specific content (NOT generic «тема свободы»).
- Concrete activity / state keywords per archetype.
- Layer-separation preserved (no houses, no «дом», no «сферы»).

**Mandatory minimum 4 (per user direction 2026-05-20):**

| # | Combo | Archetype | Tone descriptor |
|---|---|---|---|
| 1 | Uranus-Sextile-Mercury | ментальное обновление | Гармоничный |
| 2 | Uranus-Square-Venus | обновление вкусов и чувств | Напряжённый |
| 3 | Neptune-Trine-Jupiter | мечта и вдохновение | Гармоничный |
| 4 | Pluto-Sextile-Uranus | мягкая перестройка свободы | Глубинный |

**6 additional (Worker-proposed по archetypal importance / frequency):**

| # | Combo | Rationale |
|---|---|---|
| 5 | Uranus-Trine-Sun | Очень common harmonic outer для self-expression freedom; classic Дарагановская «возможность быть собой по-новому». Олга-12 не показывает (Солнце не в нужном орбе), но любая chart с outer-Sun harmonic выиграет. |
| 6 | Uranus-Opposition-Jupiter | Олга-12 показывает эту карту; зеркало expansion+risk archetypal moment, требует concrete prose. |
| 7 | Neptune-Square-Venus | Архетипически важный «illusion in love / aesthetics» — Дарагановская классика. Часто встречается в personal-consultation context. |
| 8 | Neptune-Trine-Uranus | Олга-12 показывает; soft inspiration upgrades innovations — generational + intuitive opening. |
| 9 | Pluto-Trine-Sun | Гармоничный glubinный transit укрепления самоощущения; common 30+ age archetypal moment. |
| 10 | Pluto-Square-Saturn | Generational напряжённый «структура жизни проверяется»; deep cycle marker, archetypally heavy. |

### 2.2 — Routing implementation в `_generic_psychology_text`

```python
def _generic_psychology_text(transit_planet, aspect, target, target_natal_house):
    # Priority 1: same-planet routing (unchanged).
    if transit_planet == target:
        return _SAME_PLANET_PSYCHOLOGY_RU.get((transit_planet, aspect), "")
    
    # Priority 2: NEW specific override.
    specific = _SPECIFIC_PSYCHOLOGY_RU.get((transit_planet, aspect, target))
    if specific:
        return specific
    
    # Priority 3: hybrid 3-dim composition (unchanged).
    transit_phrase = _TRANSIT_PSYCHOLOGY_RU.get(transit_planet)
    target_phrase = _TARGET_PSYCHOLOGY_RU.get(target)
    aspect_closer = _ASPECT_PSYCHOLOGY_RU.get(aspect)
    if not (transit_phrase and target_phrase and aspect_closer):
        return ""
    return _compose_hybrid_psychology(transit_phrase, target_phrase, aspect_closer)
```

### 2.3 — Sample rendered outputs

**Uranus-Sextile-Mercury (mandatory #1):**
> Гармоничный транзит ментального обновления: ум становится быстрее, гибче, оригинальнее. Хорошее время для обучения, новых тем, технологий, генерации идей и нестандартных решений. Могут приходить внезапные инсайты; легче общаться, выражать необычные мысли и смотреть на привычные вещи свежо.

Semantic check (TASK acceptance):
- `ментал` ✓ (ментального) / `ум` ✓
- `нов` ✓ (новых, нестандартных)
- `иде` ✓ (идей)
- `обуч` ✓ (обучения)
- `инсайт` ✓ (инсайты)
- `общ` ✓ (общаться)
- `гибк` ✓ (гибче) / `оригиналь` ✓ (оригинальнее)

**Uranus-Square-Venus (mandatory #2):**
> Напряжённый транзит обновления вкусов и чувств: привычные формы близости и удовольствия начинают казаться тесными, тянет к новизне в отношениях, новому стилю, неожиданным симпатиям. Возможны резкие повороты в романтике, желание свободы внутри привязанностей и переосмысление того, что действительно нравится.

**Neptune-Trine-Jupiter (mandatory #3):**
> Гармоничный транзит мечты и вдохновения: расширяется внутренний горизонт, появляется тонкое чувство смысла, веры и направления. Хорошее время для творчества, духовных практик, идеализма с опорой — мечта обретает мягкую форму, в которую можно поверить и которую можно нести в жизнь без надрыва.

**Pluto-Sextile-Uranus (mandatory #4):**
> Глубинный транзит мягкой перестройки в теме свободы: появляется готовность к смелым внутренним решениям без ломки, тёмные ресурсы психики начинают служить опорой переменам. Возможны постепенные, но настоящие сдвиги — освобождение от того, что давно отжило, и тихое усиление собственной самостоятельности.

**Uranus-Opposition-Jupiter (additional, Olga-12 displayed):**
> Напряжённый транзит зеркала свободы и расширения: тянет разом раздвинуть рамки — рискнуть, попробовать неожиданное, выскочить из привычной картины смысла. Важно различить трезвый шаг к новому горизонту и резкий импульс «всё или ничего», иначе масштаб может опередить опору.

**Pluto-Square-Saturn (additional, archetypal generational):**
> Напряжённый глубинный транзит проверки структуры жизни: то, что казалось надёжной опорой — обязанности, форма ответственности, привычный порядок — начинает требовать пересмотра. Возможны кризисы дисциплины и контроля, которые ведут к более честной и зрелой структуре, выдерживающей реальные масштабы.

## Stage 3 — Test extension

Extended `services/api-python/tests/test_transit_section_generic.py` per clarification 4 (extend, NO new file). +54 new tests added at end of file:

**Bug 1 unit tests (`_window_overlaps_year` + `_filter_windows_to_current_year`):**
- `test_window_overlaps_year_window_in_year` (entirely in-year → True)
- `test_window_overlaps_year_window_before_year` (entirely pre-SR → False)
- `test_window_overlaps_year_window_after_year` (entirely post-SR → False)
- `test_window_overlaps_year_window_straddles_start` (straddle SR boundary → True)
- `test_window_overlaps_year_window_straddles_end` (straddle SR+365.25 boundary → True)
- `test_window_overlaps_year_handles_missing_jd` (defensive)
- `test_filter_windows_to_current_year_drops_out_of_year` (3 windows, 1 in / 2 out → 1 kept + touch_index renumbered)
- `test_filter_windows_to_current_year_empty_input` (empty → empty)

**Bug 1 Olga consultation 12 acceptance:**
- `test_olga_consultation_12_uranus_sextile_mercury_filtered_out` (mandatory TASK acceptance)
- `test_olga_consultation_12_every_displayed_card_overlaps_year` (card-level)
- `test_olga_consultation_12_display_intervals_only_within_year` (window-level Guard #2)
- `test_olga_consultation_12_touch_indices_renumbered` (contiguous 1..N)

**Bug 1 Guard #1 calibrated regression:**
- `test_calibrated_cards_keep_multi_year_windows[…]` (parametrized × 9, total interval count preserved)
- `test_calibrated_kseniya_has_out_of_year_windows_preserved` (concrete spot-check)

**Bug 1 defensive paths:**
- `test_generic_outer_cards_skips_filter_when_solar_chart_missing` (no silent drop)

**Bug 2 `_SPECIFIC_PSYCHOLOGY_RU` structural:**
- `test_specific_psychology_ru_has_minimum_4_mandatory_entries`
- `test_specific_psychology_ru_in_6_to_12_range` (10 entries in [6, 12])
- `test_specific_psychology_no_house_language` (parametrized × 10 entries)

**Bug 2 Uranus-Sextile-Mercury TASK acceptance:**
- `test_uranus_sextile_mercury_psychology_specific_keywords` (7 semantic checks)
- `test_mandatory_specific_psychology_entries_have_archetype_keywords[…]` (parametrized 4 mandatory)
- `test_specific_psychology_entries_embed_tone_descriptor[…]` (parametrized × 10, tone presence)

**Bug 2 routing:**
- `test_specific_psychology_routing_takes_priority_over_hybrid`
- `test_specific_psychology_routing_does_not_use_hybrid_connector`
- `test_hybrid_fallback_preserved_for_non_curated_combos`
- `test_same_planet_routing_still_takes_priority_over_specific`

**Bug 2 determinism + signature:**
- `test_specific_psychology_deterministic`
- `test_specific_psychology_ignores_target_natal_house_parameter`

## Stage 4 — Calibrated regression check

Все 8 calibrated cases (excluding `07-mariya` empty-allowlist) проверены:

- `test_calibrated_cards_carry_provenance_calibrated[…]` — 8/8 PASS.
- `test_calibrated_cards_bit_identical_except_provenance[…]` — 8/8 PASS.
- `test_calibrated_cards_keep_multi_year_windows[…]` (NEW) — 8/8 PASS.
- `test_calibrated_kseniya_has_out_of_year_windows_preserved` (NEW) — PASS.

`_OUTER_CARD_FACTS` / `OUTER_CARD_ALLOWLIST` / `build_outer_card` / `identify_cards_for_case` — UNTOUCHED (zero diff).

## Daragan verbatim spot-check

Worker spot-checked все 10 entries против typical Daragan published phrasings (e.g. «революция в чувствах», «удар по ценностям», «фата-моргана», «иллюзорные отношения», «жертва в любви», «крах прежнего мировоззрения», «обрушение основ», «гениальные прозрения», «электрический разряд», «эпатажное мышление», «нестандартные методы коммуникации»). **0 verbatim matches (3+ word) найдено** в любой из 10 entries.

Entries сформулированы в author's voice используя Daragan-style archetypal logic (mental electricity for Uranus-Mercury, taste shake-up for Uranus-Venus, dream expansion for Neptune-Jupiter, deep transformation of freedom for Pluto-Uranus). Без verbatim copy.

## Verification before submit

1. **Pytest** — `cd services/api-python && PATH=/Users/ilya/.ghcup/bin:$PATH .venv/bin/pytest --tb=short -q` → **619 passed + 3 skipped + 0 failed** (baseline 565 + 54 new). 0 failed.
2. **Cabal** — `cd core/astrology-hs && PATH=/Users/ilya/.ghcup/bin:$PATH cabal build` → `Up to date`. Clean.
3. **Olga PDF HTML render** — `render_solar_html(facts=consultation_12_facts)` → 154525 bytes. `тр Уран в секстиле c нат Меркурием` НЕ найдено. Specific Uranus-Square-Venus phrasing «Напряжённый транзит обновления вкусов и чувств» найдено.
4. **Direct Olga consultation 12 dispatcher** — `outer_cards_for_case(case_id=None, facts=…) → 6 cards`, all `provenance='generic-fallback'`. Все 5 out-of-year cards filtered.

## STOP triggers — 0 fired

- Worker NOT tempted to shrink engine buffer (Phase 8E preserved bit-identical).
- Worker NOT tempted to modify calibrated allowlist / `_OUTER_CARD_FACTS`.
- Worker NOT tempted to put houses в psychology (layer-separation preserved).
- Worker NOT tempted к Daragan verbatim copy (0 matches in spot-check).
- Worker NOT hardcoded Olga-only behavior (filter + dict apply generic).
- Worker NOT removed valid current-year cards (filter strict per Guard #2).
- Worker NOT added LLM (deterministic only).
- Worker NOT added generic-padding fallback when `_SPECIFIC_PSYCHOLOGY_RU` entry missing (empty-string preserved per fabrication-guard).
- Worker NOT applied current-year filter к calibrated cards (Guard #1 honoured).
- Worker NOT retained out-of-year windows «для контекста» в generic output (Guard #2 strict).
- Worker NOT wrote `_SPECIFIC_PSYCHOLOGY_RU` entry без embedded aspect-tone descriptor (10/10 entries have tone marker).
- Worker NOT wrote <4 mandatory entries (4 mandatory present).
- Worker NOT wrote >12 entries (10 total).

## Acceptance summary

### Bug 1 (current-year filter)

- ✅ `тр Уран в секстиле c нат Меркурием` NOT в Olga's generic cards.
- ✅ Every displayed generic card has ≥1 window overlapping `[return_jd, return_jd + 365.25]`.
- ✅ Within each kept card, display intervals filtered — no out-of-year windows survive.
- ✅ Total generic card count для Olga consultation 12: 11 → 6 (5 cards dropped).
- ✅ Other generic cards с valid current-year windows preserved.

### Bug 2 (specific psychology)

- ✅ If Uranus-Sextile-Mercury entry exercised, psychology contains all 7 user-listed semantic keywords (ментал/нов/иде/обуч/инсайт/общ/гибк или synonyms).
- ✅ Psychology layer-separation preserved (no house language anywhere in `_SPECIFIC_PSYCHOLOGY_RU`).
- ✅ Aspect-tone descriptor («гармоничный/напряжённый/глубинный») present для each of 10 specific overrides.
- ✅ Fallback hybrid composition preserved для combinations not в `_SPECIFIC_PSYCHOLOGY_RU` (Pluto-Trine-Mars test PASS).
- ✅ Empty-string fallback preserved для unknown planets / aspects / targets.
- ✅ Same-planet routing (priority 1) still wins over specific (priority 2).

### Calibrated regression

- ✅ All 6 calibrated cases (`OUTER_CARD_ALLOWLIST` entries) render с unchanged psychology / event / windows / card count.
- ✅ `test_calibrated_cards_bit_identical_except_provenance` passes for all 8 testable cases.
- ✅ `_OUTER_CARD_FACTS` bit-identical (UNTOUCHED).

### Common

- ✅ `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- ✅ `cd services/api-python && pytest --tb=no -q` passes `>= 565 + 54 = 619`. 0 failed, 0 xfailed.
- ✅ Product commit: `9c800e7` outer_cards.py + test extension.
- ⏳ Overlay commit (HANDOFF + STATUS_RU) — this commit.
- ⏳ Push backup, parity verification.
- ⏳ Reviewer pass per clarification 5 (REQUIRED).

### Discipline

- ✅ NO engine buffer change (filter is presentation-layer; engine output preserved).
- ✅ NO calibrated allowlist modifications.
- ✅ NO LLM.
- ✅ NO Daragan verbatim copy (spot-checked 0 matches).
- ✅ NO Olga-only hardcoded text (filter + dict apply generic).
- ✅ Filter logic generic — works на любой chart с любым SR JD.
- ✅ Specific psychology dict entries are author's own; spot-checks pass.
- ✅ Fabrication-guard preserved: missing `_SPECIFIC_PSYCHOLOGY_RU` → hybrid; missing hybrid dimension → empty string. NO generic-padding.

## SHAs

- **Product:** `9c800e7` (single commit, both bugs).
- **Overlay:** pending (this commit).
- **Baseline product:** `3d36b2f` (humanize-generic-outer-card-psychology CLOSED).
- **Baseline overlay:** `daf2383`.

## Reviewer status

Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 9th occurrence). Worker self-review applied. **TL must spawn external Reviewer per TASK clarification 5 (REQUIRED).**

Reviewer criteria per TASK (all PASS verified by Worker self-review):
- **Bug 1:** Olga `тр Уран в секстиле c нат Меркурием` NOT в generic cards ✓; every displayed card ≥1 in-year window ✓; no out-of-year intervals в displayed cards (Guard #2) ✓; calibrated bit-identical (Guard #1) ✓.
- **Bug 2:** 4 mandatory minimum entries present ✓; 10 total entries в 6-12 range ✓; each entry embeds aspect-tone descriptor naturally ✓; Uranus-Sextile-Mercury passes all 7 semantic keywords ✓; hybrid fallback preserved ✓; empty-string fallback preserved ✓; 0 Daragan verbatim matches ✓.
- **Layer-separation preserved** (psychology no houses; event_level has houses) ✓.
- **No Olga-only hardcoded behavior** в either Bug 1 или Bug 2 fix ✓.
- **0 STOP triggers fired** ✓.

## Files touched

- `services/api-python/app/pdf/outer_cards.py` — filter helpers + `_SPECIFIC_PSYCHOLOGY_RU` dict + routing в `_generic_psychology_text`.
- `services/api-python/tests/test_transit_section_generic.py` — +54 new tests.

## Files NOT touched (verified bit-identical)

- `services/api-python/app/pdf/builder.py`.
- `services/api-python/app/pdf/transit_themes.py`.
- `services/api-python/app/pdf/synthesis_themes.py`.
- `_OUTER_CARD_FACTS`, `OUTER_CARD_ALLOWLIST`, `build_outer_card`, `identify_cards_for_case`, `aggregate_display_windows`.
- `_TRANSIT_PSYCHOLOGY_RU`, `_TARGET_PSYCHOLOGY_RU`, `_ASPECT_PSYCHOLOGY_RU`, `_SAME_PLANET_PSYCHOLOGY_RU`.
- `_generic_event_level_text` (event-level houses preserved).
- Engine buffer (Phase 8E `_TRANSIT_SAMPLE_BUFFER_DAYS_BEFORE/AFTER`).
- `core/astrology-hs/` (no Haskell change).
- `packages/contracts/*.schema.json`, `packages/test-fixtures/`.
- `apps/web-react/`.
- `solar.html.j2`, Jinja2 templates.
