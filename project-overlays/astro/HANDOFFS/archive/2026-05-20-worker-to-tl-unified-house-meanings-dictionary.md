# HANDOFF: Worker → TL — unified-house-meanings-dictionary

- Date: 2026-05-20 20:05
- From: Worker (astro)
- To: Tech Lead (astro)
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: `project-overlays/astro/TASKS/2026-05-20-unified-house-meanings-dictionary.md`
- Status: closed
- Product repo status: committed (`22dc672` on `main`, backup pushed)

## Что сделано

Tier C consolidation refactor — единый источник правды для значений
12 домов в PDF слое. Четыре ранее локальных dict'а теперь derived
aliases поверх одного канонического модуля.

### Артефакты

- new product: `services/api-python/app/pdf/house_meanings.py`
  (canonical dict 12 × 7 fields + helper API).
- new product: `services/api-python/tests/test_house_meanings.py`
  (9 категорий + helper API smoke = 10 тестов).
- modify product: `services/api-python/app/pdf/synthesis_themes.py`
  (`_HOUSE_TOPICS_RU` + `_HOUSE_SHORT_RU` → derived aliases over
  `HOUSE_MEANINGS`).
- modify product: `services/api-python/app/pdf/house_pair_themes.py`
  (`SOLAR_HOUSE_FRAMING` + `NATAL_HOUSE_DOMAIN` → derived aliases;
  `HOUSE_PAIR_THEMES` 144 cells НЕ тронуты).
- Product commit SHA: `22dc672` on `main` (backup push:
  `5070ea0..22dc672  main -> main`).
- Overlay commit SHA: this commit (HANDOFF + STATUS_RU update).

## Канонический dict structure

`HOUSE_MEANINGS: dict[int, dict[str, Any]]` — 12 домов × 7 полей.

Поля: `title` (uppercase RU heading) / `main` (primary keyword
tuple) / `additional` (secondary keyword tuple) / `compact` (short
factual descriptor для «Итоги») / `solar_framing` (year-as-solar-
house framing) / `natal_domain` (natal life domain) / `short`
(inline insertion).

### Keyword counts per house

| House | `main` | `additional` | total |
|---|---|---|---|
| 1  ЛИЧНОСТЬ      | 7 | 6 | 13 |
| 2  ДЕНЬГИ         | 7 | 6 | 13 |
| 3  ДОКУМЕНТЫ      | 7 | 7 | 14 |
| 4  ДОМ            | 7 | 7 | 14 |
| 5  ДЕТИ           | 7 | 7 | 14 |
| 6  РАБОТА         | 7 | 7 | 14 |
| 7  БРАК           | 7 | 7 | 14 |
| 8  ЧУЖИЕ ДЕНЬГИ   | 7 | 7 | 14 |
| 9  ЗАГРАНИЦА      | 7 | 7 | 14 |
| 10 КАРЬЕРА        | 7 | 7 | 14 |
| 11 ДРУЗЬЯ         | 7 | 7 | 14 |
| 12 ИЗОЛЯЦИЯ       | 7 | 7 | 14 |

Все в диапазоне `~6-12` из TASK § 1.4. Author's own short Russian
phrasings (Daragan + traditional archetypes; no verbatim copy).

## Migration trace (soft transition, derived-alias pattern)

Per clarification 2 = (b) soft transition. Старые имена preserved
as derived aliases; существующие callsites unchanged.

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

Existing callsites продолжают работать:
- `synthesis_themes._house_topic_phrase` (line 710 — single + multi).
- `synthesis_themes._phrase_personality_partner` (line 2519).
- `_phrase_resources_partner` (line 2564).
- Houses inline insertion (line 2858).
- `house_pair_themes.house_pair_text` fallback (lines 261-262).

**HOUSE_PAIR_THEMES (144 curated cells) НЕ тронуты.** Verified via
`git diff --stat`: only `SOLAR_HOUSE_FRAMING` + `NATAL_HOUSE_DOMAIN`
regions modified; cells region unchanged.

## 48 required keywords verification

Per TASK § Stage 4.2 — case-insensitive substring match в `main`
OR `additional`. Все 48 подтверждены present.

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

Pre-submit script: `errors=0`. Тест
`test_required_keywords_present_in_main_or_additional` enforces
ongoing presence.

## PDF text-extract diff proof (Critical preservation guard)

Pre-refactor renders captured at product SHA `5070ea0` (baseline);
post-refactor renders at SHA `22dc672` (post migration).

Diff: `diff <case>-pre.txt <case>-post.txt | wc -l`.

| Case | Pre bytes | Post bytes | Diff lines |
|---|---|---|---|
| 02-maksim-2025-2026  | 56452 | 56452 | **0** |
| 05-ekaterina-2025-2026 | 55966 | 55966 | **0** |
| 08-natalya-2025-2026  | 56785 | 56785 | **0** |

PDF surface = unchanged. Critical preservation guard satisfied: все
четыре legacy dict'а теперь derive verbatim из canonical, любой
template rendering path который читал эти dicts эмитит тот же текст.

Olga consultation 12 (DB-based, нет golden-case fixture) не
рендерилась live в этом Worker запуске; regression coverage
опирается на calibrated cases sharing same code paths
(`_house_topic_phrase`, `house_pair_text` fallback, inline `short`
insertions). Тест `test_derived_aliases_match_canonical_projection`
enforces четыре dict'а = их canonical projection — любой future
drift fails test rather than silently change Olga's PDF.

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
| 10 | `test_helper_api_returns_canonical_values` | Bonus smoke (`house_topic`/`house_short`/`solar_framing`/`natal_domain`) |

Все 10 PASS в 0.34s.

## Discipline checklist

- [x] NO `HOUSE_PAIR_THEMES` 144 cells modification.
- [x] NO PDF surface change (0-char diff на 3 calibrated cases).
- [x] NO LLM.
- [x] NO engine touch (cabal Up to date).
- [x] NO `main` / `additional` keyword list output в PDF (internal semantic source).
- [x] NO Daragan verbatim copy (author's own short Russian phrasings).
- [x] NO improving/rewriting existing `compact`/`solar_framing`/`natal_domain`/`short` (char-for-char copy).
- [x] NO refactor beyond derived-alias substitution.
- [x] Single source of truth: 4 legacy dicts derive из `HOUSE_MEANINGS`.
- [x] `house_meanings.py` импортирует только stdlib (`typing`) — нет circular dependency.

## Verification before submit

- [x] `cabal build` clean from `core/astrology-hs` (Up to date).
- [x] Pytest 643 passed + 3 skipped + 0 failed (was 633 + 3 + 0 baseline; +10 new).
- [x] PDF text-extract diff = 0 chars для 02-maksim + 05-ekaterina + 08-natalya.
- [x] Product `git status --short` clean for intended files (4 files: 1 new module + 2 modified + 1 new test).
- [x] Backup parity: `5070ea0..22dc672  main -> main` (product backup), overlay backup pending в commit, который содержит этот HANDOFF.

## Что осталось

Закрытие cycle: TL inline-verify per clarification 4 = (a) optional
Reviewer. Worker self-review applied. Если TL satisfied, TASK
`review → done` + HANDOFF `open → closed` + archive.

## Конфликты / открытые вопросы

Нет. Future deprecation-lifecycle TASK (per TASK § Stage 2.3 «оставлен
для future cleanup TASK») может удалить четыре legacy alias names
entirely. Out of scope здесь.

## Reviewer status

Per clarification 4 = (a) optional. Worker self-review applied.
Critical PDF preservation guard satisfied 0-char diff на 3
calibrated cases + `test_derived_aliases_match_canonical_projection`
locking четыре legacy dicts к canonical values.

TL inline-verify focus areas (per TASK § Reviewer subagent):
- [x] Canonical dict completeness (12 × 7 fields) — `test_field_coverage_seven_fields_non_empty_per_house`.
- [x] All 48 required keywords present — `test_required_keywords_present_in_main_or_additional`.
- [x] Soft-alias derivation works (old names importable + return correct values) — `test_derived_aliases_match_canonical_projection`.
- [x] PDF text bit-identical для ≥2 calibrated cases (delivered 3: 02 / 05 / 08).
- [x] Existing acceptance tests all pass (643 PASS; full suite).
