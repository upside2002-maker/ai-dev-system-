# TASK: unified-house-meanings-dictionary

- Status: open
- Ready: no
- Date: 2026-05-20
- Project: astro
- Layer: services (Python presentation: new `app/pdf/house_meanings.py` canonical dict + refactor existing local dicts в synthesis_themes.py + house_pair_themes.py)
- Risk tier: C (consolidation refactor — single source of truth для house meanings; no behavior change expected; locks tests cover regression)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User Marina-show preparation audit 2026-05-20 identified architectural fragmentation: значения 12 домов используются в software, но разрозненно и в укороченном виде:

- `services/api-python/app/pdf/synthesis_themes.py:375` `_HOUSE_TOPICS_RU` — короткий dict (compact topic phrases).
- `services/api-python/app/pdf/synthesis_themes.py:2459` `_HOUSE_SHORT_RU` — мини-dict для inline-фраз.
- `services/api-python/app/pdf/house_pair_themes.py:40` `SOLAR_HOUSE_FRAMING` — солярная рамка дома.
- `services/api-python/app/pdf/house_pair_themes.py:57` `NATAL_HOUSE_DOMAIN` — натальная сфера дома.
- `services/api-python/app/pdf/house_pair_themes.py:80` `HOUSE_PAIR_THEMES` — 144 curated prose cells (**НЕ трогать**).
- Часть смыслов размазана по cross-house phrases + helper'ам в synthesis pipeline.

User direction 2026-05-20: «Нужно сделать единый источник правды для значений домов, чтобы генератор итогов и трактовок опирался на полный словарь, а не на обрезанные локальные версии.»

**Programme classification:** consolidation refactor. Single source of truth + adapter pattern. No behavior change в rendered output (regression tests anchor existing PDF text bit-identical).

## Worker framing (verbatim user direction 2026-05-20)

> «Создать единый канонический словарь 1–12 домов и подключить его к текущим synthesis / house-pair / summary путям.»

> «Важно: PDF не должен выводить этот словарь как справочник. Словарь нужен как semantic source для генерации человеческих фраз.»

> «Не переписывать 144 готовые ячейки `HOUSE_PAIR_THEMES` в этой задаче. Они уже являются curated prose. Меняем только единый источник базовых значений домов.»

## Scope (Tier C consolidation refactor)

### Stage 1 — Создание модуля `house_meanings.py`

**1.1 — Новый файл:** `services/api-python/app/pdf/house_meanings.py`

**1.2 — Структура:**

```python
HOUSE_MEANINGS: dict[int, dict[str, Any]] = {
    1: {
        "title": "ЛИЧНОСТЬ, ВНЕШНОСТЬ, ЛИЧНЫЕ ИНИЦИАТИВЫ",
        "main": ("личность", "тело", "внешний вид", "инициативы", ...),
        "additional": (...),
        "compact": "...",          # короткая фраза для «Итоги»
        "solar_framing": "...",    # как солярный дом года
        "natal_domain": "...",     # как натальная сфера
        "short": "...",            # inline-фраза
    },
    ...
    12: { ... },
}
```

**1.3 — Семантика полей (per user spec 2026-05-20):**

| Поле | Назначение |
|---|---|
| `title` | Название дома (uppercase as в user reference) |
| `main` | Главные значения дома (tuple of keywords) |
| `additional` | Дополнительные значения (tuple of keywords) |
| `compact` | Короткая фраза для итогов консультации (replaces current `_HOUSE_TOPICS_RU` value) |
| `solar_framing` | Как этот дом звучит как солярный дом года (replaces current `SOLAR_HOUSE_FRAMING` value) |
| `natal_domain` | Как этот дом звучит как сфера натала (replaces current `NATAL_HOUSE_DOMAIN` value) |
| `short` | Короткая вставка для inline-фраз (replaces current `_HOUSE_SHORT_RU` value) |

**1.4 — Content authoring (per § Ready clarification 1):**

Worker fills `main` + `additional` based on user-listed required keywords (см. § Acceptance Stage 3 ниже). Worker discretion для adjacent keywords + ordering. Worker channels Daragan + traditional Russian astrology archetypes для каждого дома; exact wording author's own.

**1.5 — Helper API (optional, Worker discretion):**

```python
def house_topic(house: int) -> str:
    """Compact topic phrase. Replaces _HOUSE_TOPICS_RU[house] usage."""
    return HOUSE_MEANINGS[house]["compact"]

def house_short(house: int) -> str:
    """Inline short phrase. Replaces _HOUSE_SHORT_RU[house] usage."""
    return HOUSE_MEANINGS[house]["short"]

def solar_framing(house: int) -> str:
    """Solar-framing phrase. Replaces SOLAR_HOUSE_FRAMING[house] usage."""
    return HOUSE_MEANINGS[house]["solar_framing"]

def natal_domain(house: int) -> str:
    """Natal-domain phrase. Replaces NATAL_HOUSE_DOMAIN[house] usage."""
    return HOUSE_MEANINGS[house]["natal_domain"]
```

OR Worker может keep dict-only API (callers use `HOUSE_MEANINGS[h]["compact"]` etc directly). Choice per Worker style preference; tests verify field presence and values, не API surface.

### Stage 2 — Migration: `synthesis_themes.py`

**2.1 — Заменить `_HOUSE_TOPICS_RU`** (lines 375-388):
- Old: hardcoded dict literal.
- New: derived from `HOUSE_MEANINGS` (e.g. `{h: HOUSE_MEANINGS[h]["compact"] for h in range(1, 13)}` OR direct callsite usage).
- Callsites using `_HOUSE_TOPICS_RU.get(h, "")` — Worker decides: keep alias OR switch к direct lookup.

**2.2 — Заменить `_HOUSE_SHORT_RU`** (line 2459+):
- Same pattern as 2.1 для `short` field.

**2.3 — Migration approach (per § Ready clarification 2):**

- (a) **Hard replacement:** remove old local dicts entirely; all callsites use `house_meanings` module.
- (b) **Soft transition:** keep old names as aliases for one release («`_HOUSE_TOPICS_RU = {h: HOUSE_MEANINGS[h]["compact"] for h in HOUSE_MEANINGS}`»); deprecation note inline.
- (c) Worker proposes.

### Stage 3 — Migration: `house_pair_themes.py`

**3.1 — Заменить `SOLAR_HOUSE_FRAMING`** (line 40):
- Old: hardcoded dict.
- New: derived from `HOUSE_MEANINGS` (`{h: HOUSE_MEANINGS[h]["solar_framing"] for h in ...}` OR direct usage).

**3.2 — Заменить `NATAL_HOUSE_DOMAIN`** (line 57):
- Same pattern для `natal_domain` field.

**3.3 — `HOUSE_PAIR_THEMES` (line 80) НЕ ТРОГАТЬ.** 144 curated prose cells preserved bit-identical. `house_pair_text()` fallback (lines 259-262) использует SOLAR_HOUSE_FRAMING + NATAL_HOUSE_DOMAIN — после refactor должно использовать canonical dict.

### Stage 4 — Tests

**4.1 — Новый файл `services/api-python/tests/test_house_meanings.py`** (per user spec 2026-05-20).

**4.2 — Test categories (per user verbatim):**

1. **Completeness:** все дома 1–12 присутствуют.
2. **Field coverage:** у каждого дома заполнены `title`, `main`, `additional`, `compact`, `solar_framing`, `natal_domain`, `short` — все 7 fields non-empty.
3. **Required keywords per house** (user-listed acceptance):
   - 1: `личность`, `тело`, `внешний вид`, `инициативы`
   - 2: `деньги`, `заработок`, `имущество`, `расходы`
   - 3: `документы`, `коммуникации`, `поездки`, `родственники`
   - 4: `дом`, `семья`, `недвижимость`, `земельные участки`
   - 5: `дети`, `творчество`, `романтические отношения`, `беременность`
   - 6: `работа`, `здоровье`, `коллеги`, `питомцы`
   - 7: `брак`, `партнёр`, `договоры`, `судебные процессы`
   - 8: `чужие деньги`, `кредиты`, `наследство`, `кризисы`
   - 9: `заграница`, `высшее образование`, `право`, `публикации`
   - 10: `карьера`, `статус`, `репутация`, `начальство`
   - 11: `друзья`, `коллективы`, `планы`, `социальные связи`
   - 12: `изоляция`, `тайны`, `закрытые учреждения`, `завершение жизненного этапа`
   
   Each keyword must appear в `main` OR `additional` (case-insensitive substring OK; user did not specify strict word boundary).

4. **synthesis_themes `_house_topic_phrase` regression:** возвращает `compact` из canonical dict.

5. **house_pair_themes `house_pair_text` fallback regression:** uses `solar_framing` + `natal_domain` из canonical dict (when pair NOT в curated `HOUSE_PAIR_THEMES`).

**4.3 — Test scope expansion (per § Ready clarification 3):**

- (a) Strict 5 user-listed categories.
- (b) Worker may add adjacent regression tests if discovers consolidation edge cases (e.g. import order, circular deps, missing field validation).
- (c) Worker proposes.

### Stage 5 — Regression check (no behavior change)

Existing PDF output должен оставаться **bit-identical** к pre-refactor baseline:
- Olga consultation 12 PDF render (post current-year filter, post meeting place fix) — text-extract `pdftotext -layout` bit-identical pre/post.
- Calibrated cases (01/02/03/04/05/07/08/09/10) PDF render — bit-identical.

Worker verifies через existing acceptance tests (`test_calibrated_cards_bit_identical_except_provenance` + `test_olga_*` family + Phase 9.4 axis tests) — all PASS.

Если any regression detected → Worker investigates: либо canonical dict value mismatch (fix value) либо migration broke callsite (fix callsite).

## Files

- new:
  - `services/api-python/app/pdf/house_meanings.py` (canonical dict + optional helpers).
  - `services/api-python/tests/test_house_meanings.py`.

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` — remove/alias `_HOUSE_TOPICS_RU` + `_HOUSE_SHORT_RU`; import from `house_meanings`.
  - `services/api-python/app/pdf/house_pair_themes.py` — remove/alias `SOLAR_HOUSE_FRAMING` + `NATAL_HOUSE_DOMAIN`; import from `house_meanings`.
  - `project-overlays/astro/STATUS_RU.md`.

- delete: —

## Do not touch

- **`HOUSE_PAIR_THEMES` (144 curated cells)** — Marina-style prose; preserved bit-identical per user direction.
- Engine: Haskell core, schema, fixtures.
- `core/astrology-hs/` — astrologические algorithms.
- Solar meeting place plumbing (just closed).
- Outer cards (Phase 9.2B + 9.3A + Generic Psychology + Current-Year filter).
- Generic psychology dicts (`_TRANSIT_PSYCHOLOGY_RU` / `_TARGET_PSYCHOLOGY_RU` / `_ASPECT_PSYCHOLOGY_RU` / `_SAME_PLANET_PSYCHOLOGY_RU` / `_SPECIFIC_PSYCHOLOGY_RU`) — Daragan archetype layer, unrelated to house meanings.
- `direction_themes.py` / `transit_themes.py` / `rulership_houses.py` — separate concerns.
- `solar.html.j2` template.
- `builder.py`.
- Calibrated allowlist / `_OUTER_CARD_FACTS`.
- Phase 4b structured overrides.
- Phase 9.x artifacts.
- **NO LLM.**
- **NO PDF surface change.** Canonical dict is semantic source; PDF text remains bit-identical к pre-refactor baseline.
- **NO `main` / `additional` output в PDF.** Dictionary is internal semantic source; PDF stays human prose (synthesis + house-pair + outer cards).

## Acceptance

### Primary

- [ ] `house_meanings.py` created с `HOUSE_MEANINGS` dict (12 houses × 7 fields).
- [ ] All 12 houses present.
- [ ] All 7 fields filled per house.
- [ ] User-listed required keywords (4 per house × 12 = 48 keywords) all present в `main` OR `additional`.
- [ ] `synthesis_themes._HOUSE_TOPICS_RU` derived from canonical dict.
- [ ] `synthesis_themes._HOUSE_SHORT_RU` derived from canonical dict.
- [ ] `house_pair_themes.SOLAR_HOUSE_FRAMING` derived from canonical dict.
- [ ] `house_pair_themes.NATAL_HOUSE_DOMAIN` derived from canonical dict.
- [ ] `HOUSE_PAIR_THEMES` 144 cells bit-identical (NOT touched).
- [ ] New test file covers 5 user-listed categories.

### Regression (no behavior change)

- [ ] Olga consultation 12 PDF text bit-identical pre/post refactor (text-extract comparison).
- [ ] Calibrated cases PDF text bit-identical pre/post.
- [ ] Existing acceptance tests pass (`test_calibrated_cards_bit_identical_except_provenance` + Phase 9.4 + `test_consultation_summary_evidence` + `test_transit_section_generic` + house pair tests).

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 633 + N` (N = new tests). 0 failed, 0 xfailed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (consolidation refactor + new module + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 4.

### Discipline

- [ ] NO PDF surface change.
- [ ] NO LLM.
- [ ] NO engine touch.
- [ ] NO HOUSE_PAIR_THEMES 144 cells modification.
- [ ] NO `main` / `additional` keyword list output в PDF (canonical dict is internal semantic source).
- [ ] Single source of truth: 4 existing local dicts now derive from `house_meanings.HOUSE_MEANINGS`.
- [ ] Worker channels Daragan + traditional Russian astrology archetypes для каждого дома; не verbatim copy.

## STOP triggers

- Worker tempted to modify `HOUSE_PAIR_THEMES` 144 curated cells → STOP, preserved bit-identical per user direction.
- Worker tempted to add LLM → STOP, deterministic content authoring only.
- Worker tempted to touch engine → STOP, scope is Python presentation only.
- Worker tempted to output `main` / `additional` keyword lists в PDF → STOP, canonical dict is semantic source only.
- Worker finds existing PDF output changes substantively post-refactor → STOP, canonical dict value mismatch OR migration broke callsite; investigate.
- Worker copies Daragan book verbatim → STOP, archetypes в author's own short phrasings.

## Reviewer subagent — per § Ready clarification 4

Tier C consolidation refactor. Per recent precedent:
- Tier C TASKs (Phase 9.2A / 9.3A / Tail Polish): Reviewer optional + TL inline-verify.
- Refactor TASKs с no behavior change typically lower Reviewer priority.

## Context

**Mode normal + Tier C (Reviewer disposition per § Ready).** Worker mode: normal.

**Baseline:**
- Product main @ `5070ea0` (solar meeting place closed).
- Overlay master @ `60f749f` (latest closure).
- Pytest baseline: `633 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- `_HOUSE_TOPICS_RU` current: `services/api-python/app/pdf/synthesis_themes.py:375-388`.
- `_HOUSE_SHORT_RU` current: `services/api-python/app/pdf/synthesis_themes.py:2459+`.
- `SOLAR_HOUSE_FRAMING` current: `services/api-python/app/pdf/house_pair_themes.py:40-56`.
- `NATAL_HOUSE_DOMAIN` current: `services/api-python/app/pdf/house_pair_themes.py:57-79`.
- `HOUSE_PAIR_THEMES` (NOT TOUCH): `services/api-python/app/pdf/house_pair_themes.py:80-258` (144 cells).
- `house_pair_text()` fallback logic: `house_pair_themes.py:259-262`.
- `_house_topic_phrase()` usage: `synthesis_themes.py:698-710`.

**Not in scope (explicit):**
- HOUSE_PAIR_THEMES 144 curated prose cells.
- Engine modifications.
- LLM integration.
- Solar meeting place (just closed).
- Generic psychology dicts.
- Outer cards filter / psychology / specificity logic.
- PDF surface changes.

**Ready: no** — pending 4 clarifications below.

## Ready clarifications (pending user direction 2026-05-20)

1. **`main` / `additional` content scope.**
   - (a) Worker fills based on user-listed required keywords (4 per house from § Acceptance Stage 3) + Worker discretion for adjacent keywords (~6-12 keywords per `main`, ~6-12 per `additional`).
   - (b) Worker fills strict-minimal (only user-listed required keywords + 1-2 adjacents per house).
   - (c) Worker proposes scope.

2. **Migration approach (Stage 2.3).**
   - (a) **Hard replacement:** remove old local dicts entirely; callsites use `house_meanings` module directly.
   - (b) **Soft transition:** keep old names as derived aliases for backward compat («`_HOUSE_TOPICS_RU = {h: HOUSE_MEANINGS[h]["compact"] for h in HOUSE_MEANINGS}`») + deprecation note inline.
   - (c) Worker proposes.

3. **Test scope expansion (Stage 4.3).**
   - (a) Strict 5 user-listed categories.
   - (b) Worker may add adjacent regression tests (import order, circular deps, missing field validation, helper API surface).
   - (c) Worker proposes.

4. **Reviewer subagent.**
   - (a) Optional + TL inline-verify (consistent с Tier C refactor precedent).
   - (b) REQUIRED external Reviewer (canonical dict authoring + migration touchpoints).
