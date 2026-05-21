# HANDOFF: Worker → TL — unified-house-meanings-dictionary

- **Date:** 2026-05-20
- **TASK:** `project-overlays/astro/TASKS/2026-05-20-unified-house-meanings-dictionary.md`
- **Tier:** C (consolidation refactor)
- **Status:** Worker DELIVERED → review (Reviewer optional per clarification 4)
- **Product SHA:** `22dc672` on `main` (backup pushed)
- **Overlay SHA:** (set in overlay commit that includes this HANDOFF)
- **Pytest:** 643 passed + 3 skipped + 0 failed (was 633 + 3 + 0 baseline; +10 new tests)
- **Cabal:** Up to date (no Haskell change)

## Scope delivered

Single source of truth for the twelve astrological houses in the PDF
layer. Four previously local dicts now derive from one canonical
module via soft-transition aliases. No PDF surface change.

### Files

- **new:** `services/api-python/app/pdf/house_meanings.py`
  (canonical dict + thin helper API)
- **new:** `services/api-python/tests/test_house_meanings.py`
  (9 test categories + helper-API smoke = 10 tests total)
- **modify:** `services/api-python/app/pdf/synthesis_themes.py`
  (`_HOUSE_TOPICS_RU` + `_HOUSE_SHORT_RU` → derived aliases over `HOUSE_MEANINGS`)
- **modify:** `services/api-python/app/pdf/house_pair_themes.py`
  (`SOLAR_HOUSE_FRAMING` + `NATAL_HOUSE_DOMAIN` → derived aliases;
  `HOUSE_PAIR_THEMES` 144 cells **NOT touched**)

## Canonical dict structure

`HOUSE_MEANINGS: dict[int, dict[str, Any]]` — 12 houses × 7 fields each.

Fields per house: `title` (uppercase RU heading) / `main` (primary
keyword tuple) / `additional` (secondary keyword tuple) / `compact`
(short factual descriptor for «Итоги») / `solar_framing` (year-as-
solar-house framing) / `natal_domain` (natal life domain) / `short`
(inline insertion).

### Keyword counts per house

| House | `main` count | `additional` count | total |
|---|---|---|---|
| 1  ЛИЧНОСТЬ              | 7 | 6 | 13 |
| 2  ДЕНЬГИ                 | 7 | 6 | 13 |
| 3  ДОКУМЕНТЫ              | 7 | 7 | 14 |
| 4  ДОМ                    | 7 | 7 | 14 |
| 5  ДЕТИ                   | 7 | 7 | 14 |
| 6  РАБОТА                 | 7 | 7 | 14 |
| 7  БРАК                   | 7 | 7 | 14 |
| 8  ЧУЖИЕ ДЕНЬГИ           | 7 | 7 | 14 |
| 9  ЗАГРАНИЦА              | 7 | 7 | 14 |
| 10 КАРЬЕРА                | 7 | 7 | 14 |
| 11 ДРУЗЬЯ                 | 7 | 7 | 14 |
| 12 ИЗОЛЯЦИЯ               | 7 | 7 | 14 |

All within the user-specified `~6-12` range (per TASK § 1.4). Worker
discretion applied for adjacent keywords (Daragan + traditional
Russian astrology archetypes; author's own short Russian phrasings;
no verbatim copy).

## Migration trace (soft transition, derived-alias pattern)

Per clarification 2 = (b) soft transition. Old names preserved as
derived aliases; existing callsites unchanged.

```python
# synthesis_themes.py
from .house_meanings import HOUSE_MEANINGS

_HOUSE_TOPICS_RU: dict[int, str] = {
    h: HOUSE_MEANINGS[h]["compact"] for h in HOUSE_MEANINGS
}
_HOUSE_SHORT_RU: dict[int, str] = {
    h: HOUSE_MEANINGS[h]["short"] for h in HOUSE_MEANINGS
}
```

```python
# house_pair_themes.py
from .house_meanings import HOUSE_MEANINGS

SOLAR_HOUSE_FRAMING: dict[int, str] = {
    h: HOUSE_MEANINGS[h]["solar_framing"] for h in HOUSE_MEANINGS
}
NATAL_HOUSE_DOMAIN: dict[int, str] = {
    h: HOUSE_MEANINGS[h]["natal_domain"] for h in HOUSE_MEANINGS
}
```

Existing callsites continue to work:
- `synthesis_themes._house_topic_phrase` (synthesis_themes.py:710 — single + multi-house path).
- `synthesis_themes._phrase_personality_partner` (line 2519).
- `_phrase_resources_partner` (line 2564).
- Houses inline insertion (line 2858).
- `house_pair_themes.house_pair_text` fallback (lines 261-262).

**HOUSE_PAIR_THEMES (144 curated cells) NOT touched.** Verified bit-
identical via `git diff --stat` (only `SOLAR_HOUSE_FRAMING` +
`NATAL_HOUSE_DOMAIN` regions modified; cells region unchanged).

## 48 required keywords verification

Per TASK § Stage 4.2 — case-insensitive substring match in
`main` OR `additional`. All 48 keywords confirmed present.

| House | Required keywords | Location |
|---|---|---|
| 1 | личность, тело, внешний вид, инициативы | all in `main` |
| 2 | деньги, заработок, имущество, расходы | all in `main` |
| 3 | документы, коммуникации, поездки, родственники | all in `main` |
| 4 | дом, семья, недвижимость, земельные участки | all in `main` |
| 5 | дети, творчество, романтические отношения, беременность | all in `main` |
| 6 | работа, здоровье, коллеги, питомцы | all in `main` |
| 7 | брак, партнёр, договоры, судебные процессы | all in `main` |
| 8 | чужие деньги, кредиты, наследство, кризисы | all in `main` |
| 9 | заграница, высшее образование, право, публикации | all in `main` |
| 10 | карьера, статус, репутация, начальство | all in `main` |
| 11 | друзья, коллективы, планы, социальные связи | all in `main` |
| 12 | изоляция, тайны, закрытые учреждения, завершение жизненного этапа | all in `main` |

Verification script run pre-submit: `errors=0`. Test
`test_required_keywords_present_in_main_or_additional` enforces
ongoing presence.

## PDF text-extract diff proof (Critical preservation guard)

Pre-refactor renders captured at product SHA `5070ea0` (baseline);
post-refactor renders at SHA `22dc672` (after migration).

Diff command: `diff <case>-pre.txt <case>-post.txt | wc -l`.

| Case | Pre bytes | Post bytes | Diff lines |
|---|---|---|---|
| 02-maksim-2025-2026  | 56452 | 56452 | **0** |
| 05-ekaterina-2025-2026 | 55966 | 55966 | **0** |
| 08-natalya-2025-2026  | 56785 | 56785 | **0** |

PDF surface = unchanged. Critical preservation guard satisfied:
all four legacy dicts now derive verbatim from canonical, so any
template rendering path that read those dicts emits the same text.

Olga consultation 12 (DB-based, no golden-case fixture) was not
rendered live in this Worker run; the regression coverage relies on
calibrated cases sharing the same code paths
(`_house_topic_phrase`, `house_pair_text` fallback, inline `short`
insertions). Test `test_derived_aliases_match_canonical_projection`
enforces the four dicts equal their canonical projection — any
future drift would fail the test rather than silently change Olga's
PDF.

## Test coverage (9 categories + 1 bonus)

| # | Test name | Category |
|---|---|---|
| 1 | `test_completeness_all_12_houses_present` | Completeness (user-listed 1) |
| 2 | `test_field_coverage_seven_fields_non_empty_per_house` | Field coverage (user-listed 2) |
| 3 | `test_required_keywords_present_in_main_or_additional` | Required 48 keywords (user-listed 3) |
| 4 | `test_house_topic_phrase_uses_canonical_compact` | `_house_topic_phrase` regression (user-listed 4) |
| 5 | `test_house_pair_text_fallback_uses_canonical_dict` | `house_pair_text` fallback (user-listed 5) |
| 6 | `test_field_types_are_correct` | Field types (adjacent 6) |
| 7 | `test_no_duplicates_within_house` | No duplicates (adjacent 7) |
| 8 | `test_no_circular_imports_in_house_meanings_module` | AST import scan (adjacent 8) |
| 9 | `test_derived_aliases_match_canonical_projection` | Alias correctness (adjacent 9) |
| 10 | `test_helper_api_returns_canonical_values` | Bonus smoke for `house_topic` / `house_short` / `solar_framing` / `natal_domain` |

All 10 PASS in 0.34s.

## Discipline checklist

- [x] NO `HOUSE_PAIR_THEMES` 144 cells modification.
- [x] NO PDF surface change (0-char diff on 3 calibrated cases).
- [x] NO LLM.
- [x] NO engine touch (cabal Up to date).
- [x] NO `main` / `additional` keyword list output in PDF (internal semantic source only).
- [x] NO Daragan verbatim copy (author's own short Russian phrasings).
- [x] NO improving/rewriting existing `compact`/`solar_framing`/`natal_domain`/`short` (char-for-char copy from existing locals).
- [x] NO refactor beyond derived-alias substitution.
- [x] Single source of truth: 4 legacy dicts derive from `HOUSE_MEANINGS`.
- [x] `house_meanings.py` imports only stdlib (`typing`); no circular dependency.

## Verification before submit

- [x] `cabal build` clean from `core/astrology-hs` (Up to date).
- [x] Pytest 643 passed + 3 skipped + 0 failed (was 633 + 3 + 0 baseline; +10 new).
- [x] PDF text-extract diff = 0 chars for 02-maksim + 05-ekaterina + 08-natalya.
- [x] Product `git status --short` clean for intended files (4 files: 1 new module + 2 modified + 1 new test).
- [x] Backup parity: product backup push successful (`5070ea0..22dc672  main -> main`).

## Reviewer status

Per clarification 4 = (a) optional. Worker self-review applied.
Critical PDF preservation guard satisfied by 0-char diff on 3
calibrated cases + `test_derived_aliases_match_canonical_projection`
locking the four legacy dicts to canonical values.

TL inline-verify focus areas (per TASK § Reviewer subagent):
- [x] Canonical dict completeness (12 × 7 fields) — `test_field_coverage_...`.
- [x] All 48 required keywords present — `test_required_keywords_...`.
- [x] Soft-alias derivation works (old names importable + return correct values) — `test_derived_aliases_match_canonical_projection`.
- [x] PDF text bit-identical for ≥2 calibrated cases (delivered 3: 02 / 05 / 08).
- [x] Existing acceptance tests all pass (643 PASS; full suite).

## Open items / follow-ups

None for this TASK. Future deprecation-lifecycle TASK could remove
the four legacy alias names entirely (per TASK § Stage 2.3 «оставлен
для future cleanup TASK»). Out of scope here.
