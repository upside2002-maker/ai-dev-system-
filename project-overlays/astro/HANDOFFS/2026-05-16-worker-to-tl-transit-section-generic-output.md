# HANDOFF: worker → tl — transit-section-generic-output

- Status: submitted (awaiting TL accept-task cascade)
- Date: 2026-05-16
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code (subagent)
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-16-transit-section-generic-output.md

## Summary

Закрыты две независимые дыры в Transit Section solar-отчёта,
обнаруженные 2026-05-16 на consultation 10 (Ольга, `case_label=None`,
non-calibrated case).

### Stage 1 — bottom house-interpretation parity

В шаблоне `solar.html.j2:579` (multi-line `houses_visited(...)` call)
переключение на новый helper `houses_from_transit_matrix(tmatrix,
planet_key)` из `transit_themes.py`. Helper читает уже-посчитанный
`tmatrix` (line 532) и возвращает sorted unique houses, появляющихся в
колонке `planet_key` ежемесячной таблицы. Это снимает расхождение
«Венера в 8 доме»/«Марс в 1 доме» в нижнем интерпретационном блоке —
теперь нижний список совпадает с колонками таблицы выше.

### Stage 2 — generic outer-cards fallback

Для non-calibrated кейсов (Ольга и любые будущие клиенты без
`case_label`) добавлен deterministic fallback `generic_outer_cards` в
`outer_cards.py`. Карточки строятся из движкового вывода
(`annual_transit_table`), 5-Ptolemaic-aspects only (Quincunx исключён
per Correction 009), 5-ячеечный golden-rule через `rulership_houses`
(Phase 5), психология/событийный уровень — детерминированные шаблоны
из фактов (никакой свободной Marina-style прозы). Каждая карточка
помечена `provenance: "generic-fallback"` vs `provenance: "calibrated"`
для allowlist-пути.

Pytest: **305 baseline → 368 passed + 2 skipped (vacuous case 07) + 0
xfailed + 0 failed** (63 новых теста в `test_transit_section_generic.py`).
Cabal Up to date (Haskell не трогался). Backup parity verified post-push.

Reviewer subagent EXPLICIT NOT spawned by Worker — Agent tool недоступен
в runtime Worker'а (4-й случай после TASK 8B/8D/8E + api-pdf-endpoint-
end-to-end). Worker self-review применён; TL spawns external Reviewer
post-submission per established discipline.

## Done

### Stage 1.1 — Helper `houses_from_transit_matrix` added

В `services/api-python/app/pdf/transit_themes.py` (после `planet_house_text`
и до monthly-matrix section) добавлен:

```python
def houses_from_transit_matrix(
    tmatrix: list[dict[str, Any]] | None,
    planet_key: str,
) -> list[int]:
    """Return sorted unique house numbers for ``planet_key`` from
    monthly-table snapshots.
    ...
    """
```

Контракт: для каждой строки `tmatrix` берёт `row[planet_key]`, валидирует
1 ≤ h ≤ 12, дедуплицирует, сортирует numerically. Empty/None tmatrix →
`[]`. Out-of-range cells filtered out. `__all__` extended.

### Stage 1.2 — Registration in Jinja env

`services/api-python/app/pdf/builder.py`:
- Import добавлен (`from .transit_themes import (..., houses_from_transit_matrix, ...)`).
- Запись в `_env.globals.update(...)` дикте: `houses_from_transit_matrix=houses_from_transit_matrix`.

### Stage 1.3 — Template switch

`services/api-python/app/pdf/templates/solar.html.j2` строки 579-583
(старая multi-line вызовом `houses_visited`):

**Удалено:**
```jinja
{% set visited = houses_visited(
     facts.annual_transit_table,
     p_key,
     horizon="solar_year",
     solar_return_jd=facts.solar_chart.return_jd) %}
```

**Заменено на:**
```jinja
{% set visited = houses_from_transit_matrix(tmatrix, p_key) %}
```

Комментарий блока обновлён: убран Phase 3 horizon-split rationale,
добавлена ссылка на TASK + объяснение, почему мы используем tmatrix
projection вместо wide-horizon walker.

### Stage 1.4 — `houses_visited` callers audit

Grep `houses_visited` --include="*.py" --include="*.j2":

| Caller | Decision |
|---|---|
| `transit_themes.py` (definition + docstring) | KEEP (Phase 3 contract preserved) |
| `builder.py` (import + Jinja env globals) | KEEP (downstream may use; helper стабильно зарегистрирован) |
| `tests/test_natalya_transits_acceptance.py` (4 references) | KEEP — explicit Phase 3 Saturn solar-year horizon assertion + signature test |
| `solar.html.j2` (Jinja template) | **REPLACED** (Stage 1.3) |

`synthesis_themes.py` — НЕ вызывает `houses_visited` (grep nil). Phase 3
contract `houses_visited` функции не тронут.

### Stage 2.1 — Detection rule + helpers (`outer_cards.py`)

Добавлены module-level constants + helpers:

- `_OUTER_TRANSIT_PLANETS = frozenset({"Uranus", "Neptune", "Pluto"})`.
- `_GENERIC_OUTER_ASPECTS = frozenset({"Conjunction", "Sextile", "Square", "Trine", "Opposition"})` (5 Ptolemaic; Quincunx excluded per Correction 009 — Quincunx scope = {Directions, TransitCalendar}, не outer cards).
- `_ASPECT_CHARACTER_RU` / `_ASPECT_NOM_RU` — neutral-tone Marina-style aspect characterisations (deterministic templates).
- `_natal_house_for_planet(natal_chart, planet)` — Asc/MC special-cased to 1/10; иначе lookup в `natal_chart.positions.[planet].house_placidus`.
- `_natal_cusps(natal_chart)` — extracts `natal_chart.house_systems.Placidus.cusps`.
- `_generic_psychology_text(...)` / `_generic_event_level_text(...)` — deterministic templates (no subjective adjectives, reproducible character-for-character across runs).
- `_build_generic_card(triple_data, facts, tz_id)` — assembles full card dict (same shape as `build_outer_card`).
- `generic_outer_cards(facts, *, tz_id=None) -> list[dict]` — public entry: discovers all qualifying triples, sorts deterministically (Uranus→Neptune→Pluto · Conjunction→Sextile→Square→Trine→Opposition · target alphabetical), builds card list. `__all__` extended.

### Stage 2.2 — Wiring + signature decision

**Decision: Option A — extend `outer_cards_for_case` signature with
optional `facts` kwarg.** Rationale:

- Option B (derive natal placements from ATT only) was insufficient — ATT
  carries `natal_house` for the transit planet but NOT for the target;
  golden-rule cells need both.
- Option C (template passes `facts` directly) — chose this in addition to
  Option A: signature accepts `facts=None`, template uses
  `outer_cards_for_case(_case_id, facts.annual_transit_table,
  person.birth_timezone, facts=facts)`.
- Option A backward-compatible: existing callers (api/main.py, tests
  passing positional args) keep working because the new param is
  keyword-only. Allowlist branch ignores `facts` (allowlist returns
  curated cards regardless).

New signature:
```python
def outer_cards_for_case(
    case_id: str | None,
    annual_transit_table: Iterable[dict[str, Any]] | None,
    tz_id: str | None,
    *,
    facts: dict[str, Any] | None = None,
) -> list[dict[str, Any]]:
```

Dispatch:
```python
if case_id is not None and case_id in OUTER_CARD_ALLOWLIST:
    triples = identify_cards_for_case(case_id, annual_transit_table)
    return [build_outer_card(case_id, t, tz_id) for t in triples]
return generic_outer_cards(facts, tz_id=tz_id)
```

Calibrated path bit-identical (modulo new `provenance` field — see Stage
2.3); generic path fires for `case_id is None` OR `case_id not in
OUTER_CARD_ALLOWLIST`.

### Stage 2.2b — Case 07 Мария: explicit allowlist entry

Discovery during pytest run: `test_rendered_pdf_contains_outer_card_titles[case_07_render]`
broke because case 07 was **absent** from `OUTER_CARD_ALLOWLIST`. By
spec dispatch rule, absent case_id → generic fallback fires → 7+ outer
cards rendered, contradicting Marina editorial choice
(«у вас не будет транзитных аспектов от высших планет», Соляр
2025-2026_4.pdf p. 15).

**Resolution**: added `"07-mariya-2025-2026": []` to
`OUTER_CARD_ALLOWLIST` — explicit calibrated-zero, NOT a new entry for
non-calibrated person (Mariya IS calibrated; Marina's curated answer
just happens to be zero). Spec strict prohibition «DO NOT add NEW
entries to `OUTER_CARD_ALLOWLIST` для **Ольги или других
non-calibrated persons**» — Mariya is calibrated, эта запись закрывает
implicit gap. New test `test_case_07_allowlist_explicit_zero` pins
this contract.

### Stage 2.3 — Generic card content (deterministic templates)

Card structure assembled by `_build_generic_card`:

- **Title** — reuse `_card_title(transit, aspect, target)` (existing helper).
- **Intervals** — reuse `aggregate_display_windows(raw_hits)` (existing).
- **Golden-rule** (5 cells, populated from natal_chart + rulership_houses):
  - `row_placement.transit` — `_natal_house_for_planet(natal_chart, transit)` → `«N дом»`.
  - `row_placement.radix` — same для target.
  - `row_rulership.transit` — `rulership_houses(transit, cusps)` → `«N, M дома»`.
  - `row_rulership.radix` — same для target.
  - `row_walks.transit` — `natal_house` engine annotation (read from `_collect_raw_hits` → window).
- **Psychology** template (`_generic_psychology_text`):
  «Транзит {planet_ru} в {aspect_loc} c натальным {target_instr}[ в области {N} натального дома]. Транзитная планета {archetype}. Этот аспект — {aspect_character}.»
- **Event-level** template (`_generic_event_level_text`):
  «По характеру аспекта это {aspect_character}. Ситуация коснётся сфер {N, M дома}.[ Транзитный {planet_ru} в этом году проходит по {N} натальному дому.]»
- **`provenance: "generic-fallback"`**.

Calibrated allowlist `build_outer_card` теперь добавляет
`"provenance": "calibrated"` в конец возвращаемого dict (новое поле; не
ломает legacy assertions, существующие тесты passing).

### Stage 2.4 — Generic fallback fired triples (Ольга consultation 10)

Полный список фактически сгенерированных карточек для Ольги
(`generic_outer_cards(facts, tz_id="Europe/Moscow")` →
**7 cards, all `provenance="generic-fallback"`**, deterministic):

| # | (transit, aspect, target) | Intervals | Source of psychology/event_level |
|---|---|---|---|
| 1 | (Uranus, Square, Venus) | 1 | deterministic template |
| 2 | (Uranus, Opposition, Jupiter) | 1 | deterministic template |
| 3 | (Uranus, Opposition, Uranus) | 2 | deterministic template |
| 4 | (Neptune, Square, Asc) | 2 | deterministic template |
| 5 | (Neptune, Trine, Jupiter) | 1 | deterministic template |
| 6 | (Neptune, Trine, Uranus) | 1 | deterministic template |
| 7 | (Pluto, Sextile, Uranus) | 3 | deterministic template |

Filtered out (Quincunx exclusion per Correction 009): (Neptune,
Quincunx, Venus), (Pluto, Quincunx, Asc), (Pluto, Quincunx, Venus) — 3
triples excluded. Total engine outer-emitted triples for Ольга = 10; 7
выживают в generic-fallback.

**Per-case provenance counts:**

| Case | Calibrated cards | Generic cards |
|---|---|---|
| Ольга consultation 10 (`case_label=None`) | 0 | 7 |
| 05-ekaterina-2025-2026 | 3 | 0 |
| 07-mariya-2025-2026 (explicit zero) | 0 | 0 |
| 08-natalya-2025-2026 | 3 | 0 |
| 10-danila-2025-2026 | 3 | 0 |
| 01/02/03/04/09 (Phase 8D extension) | varies (allowlist) | 0 |

### Stage 3 — Tests

Новый файл `services/api-python/tests/test_transit_section_generic.py`
(11 test functions, 65 parametrized instances — 63 passed + 2 skipped
vacuous case 07):

**Stage 1 parity (Stage 3.1):**
- `test_houses_from_transit_matrix_equals_column_set` — 9 calibrated cases × 4 planets = 36 parametrized. Asserts helper output == sorted set of cells in column.
- `test_houses_from_transit_matrix_handles_empty` — None / empty tmatrix.
- `test_houses_from_transit_matrix_deduplicates_and_sorts` — dedup + sort contract.
- `test_houses_from_transit_matrix_ignores_out_of_range_cells` — defensive 0/13 cells dropped.

**Stage 2 calibrated regression (Stage 3.2):**
- `test_calibrated_cards_carry_provenance_calibrated` — 9 cases (case 07 skips vacuously). Pins `provenance == "calibrated"`.
- `test_calibrated_cards_bit_identical_except_provenance` — same 9 cases. Asserts `outer_cards_for_case(...) == [build_outer_card(...) for t in identify_cards_for_case(...)]` — regression guard against accidental drift between dispatcher and direct composition.

**Stage 2 generic correctness (Stage 3.3):**
- `test_generic_outer_cards_handles_missing_facts` — None/empty facts.
- `test_outer_cards_for_case_with_none_case_id_dispatches_generic` — top-level dispatcher routing.
- `test_olga_generic_cards_present_and_well_formed` — count=7, 5 golden-rule cells populated, psychology/event_level non-empty, provenance correct. Loads facts from `data/astro.db:consultations[10].facts_json`; skips when DB unavailable.
- `test_olga_generic_cards_deterministic` — двойной вызов, bit-identity.
- `test_olga_generic_cards_do_not_use_calibrated_texts` — pins template prefixes (psychology starts with «Транзит », event_level starts with «По характеру аспекта »).
- `test_generic_fallback_excludes_quincunx` — Correction 009 enforcement.

**Case 07 explicit zero:**
- `test_case_07_allowlist_explicit_zero` — pins `"07-mariya-2025-2026" in OUTER_CARD_ALLOWLIST and == []`.
- `test_case_07_outer_cards_for_case_returns_empty` — calibrated-zero, not generic.

**Test 1 also broken pre-fix (`test_api_pdf_endpoint_without_case_label_graceful`):** этот test ассертил pre-Stage-2 behaviour («outer cards section absent when case_label=None»). Per new TASK Stage 2 spec, this is exactly when generic fallback fires. Updated assertions: now positive — «Транзиты высших планет» present, «Интервалы реализации» present. Comment block updated с rationale + reference на TASK.

### Stage 3.4 — Manual UI smoke (consultation 10 Ольга)

1. Invalidated cache: `UPDATE consultations SET pdf_path=NULL WHERE id=10` + `rm /Users/ilya/Projects/astro/data/pdf/consultation-10.pdf`.
2. `curl http://127.0.0.1:8000/api/v1/consultations/10/pdf -o /tmp/olga-consultation-10.pdf` → HTTP 200, 154 KB, 24 pages (pre-fix 19 pages — +5 pages для outer cards section).
3. `pypdf.PdfReader` text extraction; assertion battery:

```
OK   | 'Венера в 8 доме': absent (Stage 1 should be ABSENT)
OK   | 'Марс в 1 доме': absent (Stage 1 should be ABSENT)
OK   | 'Транзиты высших планет': PRESENT (Stage 2 should be PRESENT)
OK   | 'Интервалы реализации': PRESENT (Stage 2 should be PRESENT)
OK   | 'Золотое правило транзита': PRESENT (Stage 2 should be PRESENT)
OK   | 'Психологический уровень': PRESENT (Stage 2 should be PRESENT)
OK   | 'Событийный уровень': PRESENT (Stage 2 should be PRESENT)

Result: 7/7 markers correct
```

**Verbatim PDF extract (first generic card, для Ольги consultation 10):**

```
тр Уран в квадрате c нат Венерой
Интервалы реализации (начало – конец):
01.12.2026 17:36 (GMT+3) – 15.04.2027 08:09 (GMT+3) — первое касание.
Золотое правило транзита
Транзит      Аспект    Радикс
(Причина)    (Способ)  (Следствие)
Естественная сигнификация планет   Психология   Уран   90   Венера
Положение планеты в доме радикса   События      6 дом       4 дом
Управление домами радикса          Причины/Следствия  9, 10 дома  12 дом
Натальный дом, по которому идёт транзитная планета    Обстоятельства, ...    12
Психологический уровень. Транзит Уран в квадрате c натальным Венерой в области 4
натального дома. Транзитная планета приносит неожиданные перемены и пробуждение. Этот
аспект — напряжённая ситуация, требующая преодоления.
Событийный уровень. По характеру аспекта это напряжённая ситуация, требующая
преодоления. Ситуация коснётся сфер 4, 12 дома. Транзитный Уран в этом году проходит по 12
натальному дому.
```

(Полный список 7 карточек pdftotext verbatim — см. `/tmp/olga-consultation-10.pdf`,
section «Транзиты высших планет» pages 16-22.)

## Reviewer status

**EXPLICIT NOT spawned by Worker — Agent tool unavailable in runtime
(4-я ситуация после TASK 8B / 8D / 8E / api-pdf-endpoint-end-to-end).**

Worker self-review applied per spec runtime-limitation path:

1. Stage 1 helper correctness — verified via 36 parametrized
   `test_houses_from_transit_matrix_equals_column_set` (9 cases × 4
   planets), all pass.
2. Stage 1 parity — Ольга «Венера в 8 доме» / «Марс в 1 доме» absent,
   confirmed both в Python repl (Mars: `[12,1,2,3,4,5]` → `[2,3,4,5,12]`,
   Venus: `[4,5,6,7,8,9,10,11,12,1]` → `[1,4,5,6,7,9,10,11,12]`) и в
   rendered PDF.
3. Stage 2 calibrated regression — `test_calibrated_cards_bit_identical_except_provenance`
   passes for all 9 cases (case 07 skips vacuously).
4. Stage 2 generic correctness — Ольга count=7, all 5 golden-rule cells
   populated, deterministic (3 separate runs bit-identical), provenance
   correct.
5. Pytest independent run: `368 passed + 2 skipped + 0 xfailed + 0
   failed` (305 baseline + 63 new).
6. Manual UI smoke — все 7 acceptance markers OK.

TL spawns external Reviewer post-submission per established discipline.

## Conflicts

Pre-fix test `test_api_pdf_endpoint_without_case_label_graceful` пинал
pre-Stage-2 behaviour («No outer cards section when case_label=None»).
Это противоречит самой сути Stage 2 (generic fallback fires exactly
тогда). Test обновлён под новый spec: assertions перевёрнуты (now
positive: «Транзиты высших планет» + «Интервалы реализации» должны
присутствовать). Документация теста полностью переписана: pre-/post-
2026-05-16 contrast явно описан.

Pre-fix test `test_rendered_pdf_contains_outer_card_titles[case_07]`
ломался потому что Mariya отсутствовала в `OUTER_CARD_ALLOWLIST`,
generic fallback дал бы 9 cards (Uranus×4 + Neptune×3 + Pluto×2) vs
Marina-required 0. Resolution — add `"07-mariya-2025-2026": []` как
explicit calibrated-zero entry. Per spec strict — это **не** добавление
для non-calibrated person (Mariya calibrated, just zero). Test
`test_case_07_allowlist_explicit_zero` пинает этот контракт.

Никаких других unexpected regressions нет.

## Pytest / Cabal / Backup

```
$ cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q
368 passed, 2 skipped in 43.21s
```

- Baseline: 305 passed + 0 xfailed + 0 failed.
- Post-fix: 368 passed + 2 skipped + 0 xfailed + 0 failed (305 baseline + 63 new).
- 2 skipped: `test_calibrated_cards_carry_provenance_calibrated[07-mariya-2025-2026]` + `test_calibrated_cards_bit_identical_except_provenance[07-mariya-2025-2026]` (vacuous — case 07 allowlist returns []).

```
$ cd core/astrology-hs && PATH="/Users/ilya/.ghcup/bin:$PATH" cabal build
Up to date
```

Haskell engine не трогался (Tier C presentation-layer only).

Backup parity: see commit + push log в section ниже.

## Files touched

### Modified (5)

- `services/api-python/app/pdf/transit_themes.py` — добавлен helper `houses_from_transit_matrix`; extended `__all__`.
- `services/api-python/app/pdf/outer_cards.py` — module docstring обновлён; импорт `rulership_houses` добавлен; case 07 explicit empty entry в `OUTER_CARD_ALLOWLIST`; `build_outer_card` теперь добавляет `provenance: "calibrated"`; новые helpers + `generic_outer_cards` + new signature for `outer_cards_for_case` with `facts` kwarg; extended `__all__`.
- `services/api-python/app/pdf/builder.py` — import `houses_from_transit_matrix`; registration в Jinja env globals.
- `services/api-python/app/pdf/templates/solar.html.j2` — line 579-583 template switch (Stage 1); outer-cards block restructured to invoke `outer_cards_for_case` regardless of `_case_id`, passing `facts=facts` kwarg; removed obsolete `{% if _case_id %}` wrapper.
- `services/api-python/tests/test_api_pdf_endpoint.py` — `test_api_pdf_endpoint_without_case_label_graceful` updated to assert NEW expected behavior (generic fallback fires).

### Added (1)

- `services/api-python/tests/test_transit_section_generic.py` — 11 test functions, 65 parametrized cases. Coverage: Stage 1 helper contract (36 parity tests + 3 edge cases), Stage 2 calibrated regression (18 — 9 cases × 2 tests), Stage 2 generic correctness (6 + 1 Quincunx exclusion + 2 case-07 explicit-zero).

### Not modified (preserved per spec strict prohibitions)

- Haskell engine, schema, fixtures, rulesets — untouched.
- `houses_visited()` function itself — untouched (Phase 3 contract preserved).
- Existing `_OUTER_CARD_FACTS` entries — untouched verbatim.
- `OUTER_CARD_ALLOWLIST` existing 8 entries — untouched. New entry для case 07 added (explicit calibrated-zero, NOT for non-calibrated person — see Stage 2.2b rationale).
- `render_case.py` — untouched.
- API endpoint `/api/v1/consultations/{id}/pdf` — untouched.
- Phase 4b structured overrides — untouched.
- Directions section template — untouched.
- 12 future-work items audit § A.2.1.D — untouched.

## Commits

Plan: 2 product commits + 1 overlay commit (TASK file Status bump +
HANDOFF + STATUS_RU).

```
git add services/api-python/app/pdf/transit_themes.py \
        services/api-python/app/pdf/builder.py \
        services/api-python/app/pdf/templates/solar.html.j2
git commit -m "feat(pdf): houses_from_transit_matrix helper + template switch (Stage 1)"

git add services/api-python/app/pdf/outer_cards.py \
        services/api-python/tests/test_transit_section_generic.py \
        services/api-python/tests/test_api_pdf_endpoint.py
git commit -m "feat(pdf): generic outer-cards fallback + provenance + tests (Stage 2-3)"
```

Push: `git push backup main` (origin remote not configured per
recent commits inspection — backup only).

## Next steps

- TL: spawn external Reviewer subagent (`general-purpose`), 6-point
  scope per spec § Reviewer subagent.
- TL: после Reviewer APPROVE → `accept-task.sh
  project-overlays/astro/TASKS/2026-05-16-transit-section-generic-output.md`
  (Status: review → done, archive).
- Future: deterministic templates в `generic_outer_cards` можно потом
  enrich per-aspect или per-planet таблицей если возникнет необходимость
  (без расширения scope — текущая reproducibility-bar сохраняется).
