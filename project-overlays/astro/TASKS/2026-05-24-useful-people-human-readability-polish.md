# TASK: useful-people-human-readability-polish

- Status: open
- Ready: no
- Date: 2026-05-24
- Project: astro
- Layer: services (Python presentation: `synthesis_themes.py` `_useful_people_block` — text-only polish; no engine, no architecture, no schema change)
- Risk tier: B− (text polish on top of just-closed Path 1 Intercepted-Sign Rulership Fix; existing Olga acceptance must remain green; new Marina acceptance added)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

После закрытия TASK `intercepted-sign-rulership-fix` (Path 1, product `d43e05e`) свежий render Marina consultation 15 (`/tmp/marina-15-fresh.pdf`) показал, что новый `_useful_people_block` **архитектурно работает правильно** — все эмитированные фразы evidence-driven (axis 1-7 signs от Marina's natal cusps, 1st-house planets реально на месте, natal Sun match). **Но текстуально читается шероховато:**

### Bug 1 — повторное «и» в списках знаков

Текущий код:

```python
inter_names = " и ".join(_SIGN_PEOPLE_RU.get(s, s) for s in asc_intercepted)
sentences.append(f"Вам опорно рядом {asc_label} и {inter_names} — ...")
```

При Marina (Дом 1 cusp Aquarius, intercepted [Pisces, Aries]) выдаёт: **«Вам опорно рядом Водолеи и Рыбы и Овны»** (трижды «и»). Нормальный русский: **«Вам опорно рядом Водолеи, Рыбы и Овны»**.

То же для Дом 7: **«По партнёрской оси — Львы и Девы и Весы»** → **«По партнёрской оси — Львы, Девы и Весы»**.

Olga unaffected (1 знак на axis 1 cusp Cancer, 1 знак intercepted nothing; 1 знак axis 7 cusp Capricorn) — Olga axis sentences остаются «Раки» / «Козероги» без списков.

### Bug 2 — астрологический жаргон в 1st-house planet phrases

`_FIRST_HOUSE_PLANET_PEOPLE_RU` (synthesis_themes.py:927) использует архетипические термины («солнечное присутствие», «меркурианская лёгкость», «венерианский вкус», «плутоническая глубина»). Эти фразы:

* **Evidence-driven**: эмитируются только когда planet реально в natal Дом 1.
* **Не для клиента**: читаются эзотерически / канцелярски. Клиент не должен интерпретировать «нептунианское чувствование» сам.

User direction 2026-05-24 verbatim:

> «Они evidence-driven, но звучат немного эзотерически/канцелярски. Лучше сделать человечески:
> - Sun в 1: «люди яркие, самостоятельные, с сильным личным центром»
> - Mercury в 1: «люди лёгкие в общении, быстрые на мысль, помогающие договориться и найти нужные слова»
> - Venus в 1, если выводим: «люди мягкие, эстетичные, умеющие сглаживать острые углы»
> - Mars в 1: «люди инициативные, прямые, готовые действовать»
> - Pluto в 1: «люди сильные, собранные, умеющие проходить через кризисы»»

5 фраз даны verbatim; для остальных 5 планет (Moon, Jupiter, Saturn, Uranus, Neptune) wording предстоит зафиксировать — см. § Ready clarification 1.

### Bug 3 (potential) — `[:2]` limit на 1st-house planets

`synthesis_themes.py:1662` `for planet in first_house_planets[:2]:` — берёт первые две планеты. У Marina natal Дом 1 содержит **3 планеты** (Sun + Mercury + Venus); сейчас Venus обрезана `[:2]`. Поведение незадокументировано и без явного теста. См. § Ready clarification 2.

### Не bug — структура 3-го предложения (information-only)

Текущая форма: «Также в этом году хорошо рядом — {phrase_A}; {phrase_B}; и солнечные {Sun_sign} по той же оси.» 3 клаузы через `;`. У Marina разворачивается длинно. У Olga короче (1 phrase + solar). См. § Ready clarification 3 — оставлять как есть или также reshape.

## Worker framing (verbatim user direction 2026-05-24)

> «Я бы открыл маленький follow-up TASK: Useful People Human Readability Polish. Scope узкий: `_useful_people_block`; helper join для списков людей; заменить `_FIRST_HOUSE_PLANET_PEOPLE_RU` фразы на человеческие; возможно убрать лимит `[:2]` или оставить, но если оставлять — явно тестом зафиксировать; tests на Olga и Marina.»

> «Это не blocker для астрологической корректности, но для клиентского чтения я бы сделал.»

## Scope (Tier B− text polish)

### Stage 1 — Join helper для списков знаков

Новый helper:

```python
def _join_sign_people(signs: list[str]) -> str:
    """Join list of sign codes into human-readable Russian list.
    
    Examples:
        _join_sign_people(["Cancer"])               → "Раки"
        _join_sign_people(["Cancer", "Leo"])        → "Раки и Львы"
        _join_sign_people(["Aquarius", "Pisces",
                           "Aries"])                → "Водолеи, Рыбы и Овны"
    """
```

Логика:
- 0 signs → `""` (caller handles fallback).
- 1 sign → `_SIGN_PEOPLE_RU.get(s, s)` напрямую.
- 2 signs → `«{a} и {b}»`.
- 3+ signs → `«{a}, {b}, ..., {y} и {z}»` (запятые между всеми кроме последней пары, perед последним — `и`).

Apply в axis 1 sentence + axis 7 sentence. Удалить вложенную `{cusp_label} и {intercepted_join}` логику (она теряет смысл с новым helper'ом — просто `_join_sign_people(asc_signs)` / `_join_sign_people(dsc_signs)`).

### Stage 2 — Replace `_FIRST_HOUSE_PLANET_PEOPLE_RU` с human-readable phrasing

5 фраз verbatim per user direction:

```python
_FIRST_HOUSE_PLANET_PEOPLE_RU: dict[str, str] = {
    "Sun":     "люди яркие, самостоятельные, с сильным личным центром",
    "Mercury": "люди лёгкие в общении, быстрые на мысль, помогающие договориться и найти нужные слова",
    "Venus":   "люди мягкие, эстетичные, умеющие сглаживать острые углы",
    "Mars":    "люди инициативные, прямые, готовые действовать",
    "Pluto":   "люди сильные, собранные, умеющие проходить через кризисы",
    # Moon / Jupiter / Saturn / Uranus / Neptune — см. § Ready clarification 1.
}
```

Старая dict сохранить как `_FIRST_HOUSE_PLANET_PEOPLE_RU_LEGACY` (или удалить — см. § Ready clarification 4).

### Stage 3 — `[:2]` cap decision

Per § Ready clarification 2: keep `[:2]` с explicit test ИЛИ remove (mention all 1st-house planets) ИЛИ другой cap (e.g. 3 с явным `;`-join).

### Stage 4 — Tests

**4.1 — Join helper unit tests:**

```python
def test_join_sign_people_empty():    assert _join_sign_people([]) == ""
def test_join_sign_people_one():      assert _join_sign_people(["Cancer"]) == "Раки"
def test_join_sign_people_two():      assert _join_sign_people(["Cancer", "Leo"]) == "Раки и Львы"
def test_join_sign_people_three():    assert _join_sign_people(["Aquarius", "Pisces", "Aries"]) == "Водолеи, Рыбы и Овны"
def test_join_sign_people_four():     # Just to lock the comma+«и» pattern.
```

**4.2 — Olga regression (Path 1 acceptance preserved + adjusted for new Mars phrasing):**

```python
def test_olga_useful_people_block_present():
    # Required (axis Cancer-Capricorn empirical):
    assert "Раки" in text       # Asc Cancer
    assert "Козероги" in text   # Дом 7 Capricorn
    # New Mars phrasing replaces «марсианская инициатива»:
    assert "инициатив" in text  # «люди инициативные, прямые, готовые действовать»
    assert "солнечные Раки" in text  # natal Sun Cancer on axis 1
    # Forbidden phrases (still forbidden):
    forbidden = ["Овны", "Львы", "Скорпион", "Тельц",
                 "солнечное присутствие", "меркурианская лёгкость"]
    for phrase in forbidden:
        assert phrase not in text
    # New forbidden: legacy join repetition
    assert " и Раки и" not in text
    assert " и Козероги и" not in text
```

**4.3 — Marina regression (NEW):**

```python
def test_marina_useful_people_block_axis_signs():
    # Marina natal Asc=Aquarius 28°48', cusp 2 Taurus 5°43' → axis 1 = Aquarius + Pisces + Aries
    # Marina natal cusp 7=Leo 28°48', cusp 8 Scorpio 5°43' → axis 7 = Leo + Virgo + Libra
    assert "Водолеи, Рыбы и Овны" in text     # axis 1 list with Oxford-style join
    assert "Львы, Девы и Весы" in text         # axis 7 list
    assert "Водолеи и Рыбы и Овны" not in text  # OLD legacy repetition
    assert "Львы и Девы и Весы" not in text

def test_marina_useful_people_block_first_house_planets():
    # Marina natal Дом 1: Sun (Aries 1°27') + Mercury (Pisces 18°53') + Venus (Pisces 27°56')
    # Per `[:2]` cap (or whatever clarification 2 decides):
    assert "люди яркие, самостоятельные" in text  # Sun
    assert "лёгкие в общении" in text             # Mercury
    # Venus — depends on clarification 2 / 4 decision.
    # Legacy phrases forbidden:
    assert "солнечное присутствие" not in text
    assert "меркурианская лёгкость" not in text
    # Solar Sun Aries on axis:
    assert "солнечные Овны" in text
```

**4.4 — Calibrated 6 cases regression:**

All 6 (02 / 03 / 05 / 07 / 08 / 10) — verify «Полезные люди» block renders without crash and без legacy phrases. Document any diff в HANDOFF; if calibrated golden-rule tests break, STOP и escalate.

### Stage 5 — Fresh PDF render verification

Render Marina (consultation 15) + Olga (consultation 12). Inspect rendered «Полезные люди» block в both PDFs. Quote rendered text в HANDOFF.

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` (~30 lines: new join helper + axis sentences refactor + `_FIRST_HOUSE_PLANET_PEOPLE_RU` rewrite).
  - `services/api-python/tests/test_consultation_summary_evidence.py` (Olga + Marina assertions; new Marina test possibly separate file).
  - Possibly new `services/api-python/tests/test_useful_people_polish.py` (join helper unit tests + Marina regression).
  - `project-overlays/astro/STATUS_RU.md`.

- new (likely):
  - `services/api-python/tests/test_useful_people_polish.py` (если Worker решит вынести).

- delete:
  - `_FIRST_HOUSE_PLANET_PEOPLE_RU_LEGACY` (if clarification 4 = delete) — нет.

## Do not touch

- Haskell core / engine / schema / fixtures.
- DB schema.
- `rulership_houses.py` (closed TASK; helper stable).
- `_OUTER_CARD_FACTS` curated dict.
- `_useful_people_block_legacy` (preserved 5-channel legacy от Path 1 TASK).
- Calibrated outer-card golden-rule tests.
- `solar_house_distribution.py`.
- `house_meanings.py`.
- `geocode.py`.
- Solar Meeting Place plumbing.
- **NO LLM.**
- **NO fabrication** (every emitted phrase must trace to natal chart fact).
- **NO Daragan verbatim.**
- **NO engine touch.**
- Preserve все existing forbidden phrases для Olga (Path 1 acceptance).

## Acceptance

### Primary

- [ ] Join helper `_join_sign_people` handles 0/1/2/3+ signs (4 unit tests).
- [ ] Marina axis 1 sentence reads «Водолеи, Рыбы и Овны» (not «и X и Y и Z»).
- [ ] Marina axis 7 sentence reads «Львы, Девы и Весы».
- [ ] Marina 1st-house planet phrases human-readable per user spec (Sun + Mercury at minimum).
- [ ] Marina `«солнечное присутствие»` / `«меркурианская лёгкость»` absent в rendered «Полезные люди» block.
- [ ] Marina `«солнечные Овны по той же оси»` preserved (Path 1 solar-axis logic unchanged).
- [ ] Olga «Раки» / «Козероги» / «солнечные Раки» preserved.
- [ ] Olga forbidden phrases (Овны / Львы / Скорпион* / Тельц* / «солнечное присутствие» / «меркурианская лёгкость») all still absent.
- [ ] `[:2]` cap decision (per clarification 2) — explicit test fixes the cap.
- [ ] Calibrated 6 cases: «Полезные люди» renders без crash, без legacy phrases.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 697 + N`. 0 failed, 0 xfailed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (synthesis_themes.py + tests).
- [ ] One overlay commit (HANDOFF + STATUS_RU).
- [ ] Push backup, parity verified.

### Discipline

- [ ] NO engine touch.
- [ ] NO DB schema change.
- [ ] NO `_OUTER_CARD_FACTS` modification.
- [ ] NO Daragan verbatim.
- [ ] NO LLM.
- [ ] NO fabrication.
- [ ] Path 1 invariants preserved (Olga `_useful_people_block` output meets Path 1 acceptance + Marina new acceptance).

## STOP triggers

- Worker fabricates 1st-house planet phrase для planet, которая не в natal Дом 1 → STOP.
- Worker touches Haskell core → STOP.
- Worker modifies `rulership_houses.py` → STOP.
- Worker modifies `_OUTER_CARD_FACTS` → STOP.
- Worker breaks Olga «Полезные люди» Path 1 acceptance (any forbidden phrase reappears OR any required phrase disappears) → STOP.
- Worker breaks calibrated 6-case PDF render → STOP.
- Worker introduces LLM → STOP.
- Worker copies Daragan verbatim → STOP.

## Reviewer subagent — optional (Worker self-review by default)

Tier B− text polish, no astrology semantics change. External Reviewer optional (TL discretion); Worker self-review sufficient by default.

If Worker introduces wording for Moon/Jupiter/Saturn/Uranus/Neptune (clarification 1 = (a) Worker drafts), Reviewer recommended для wording sanity check.

## Context

**Mode normal + Tier B−.** Worker mode: normal.

**Baseline:**
- Product main @ `d43e05e` (Intercepted-Sign Rulership CLOSED).
- Overlay master @ `93492a4` (closure cascade landed).
- Pytest baseline: `697 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- `synthesis_themes.py:1497-1700` `_useful_people_block` (Path 1 implementation).
- `synthesis_themes.py:927` `_FIRST_HOUSE_PLANET_PEOPLE_RU` (target dict).
- `synthesis_themes.py:1618-1654` axis 1 / axis 7 sentence emit (target refactor).
- `synthesis_themes.py:1662` `[:2]` cap (target decision).
- `rulership_houses.py:138` `house_signs` (input for axis_signs / dsc_signs — not modified by this TASK).
- Marina natal cusps (DB-verified, person_id=4, consultation 15):
  ```
  [328.79, 35.71, 63.01, 80.25, 95.44, 113.48, 148.79, 215.71, 243.01, 260.25, 275.44, 293.48]
  ```
  Asc = Aquarius 28°48′. Дом 1 intercepted [Pisces, Aries]. Cusp 7 = Leo 28°48′. Дом 7 intercepted [Virgo, Libra]. Natal Дом 1 planets = Sun + Mercury + Venus.
- Olga natal cusps (DB-verified, person_id=3, consultation 12) — unchanged regression target.

**Reference renders (pre-polish):**
- `/tmp/marina-15-fresh.pdf` (rendered 2026-05-24 для acceptance comparison; Worker может regenerate).
- `/tmp/olga-12-fresh.pdf` (Path 1 acceptance reference — preserve).

**Not in scope (explicit):**
- Engine modifications.
- DB schema.
- House system / rulership convention.
- LLM.
- Solar Meeting Place / Geocode / House Meanings / Solar planet distribution.
- `_OUTER_CARD_FACTS` curated data.
- Path 1 acceptance invariants (must remain green).
- `_useful_people_block_legacy` (Phase 9.3A legacy, preserved as rollback ref).

**Ready: no** — 4 clarifications pending:

1. **Other 5 planet phrases (Moon / Jupiter / Saturn / Uranus / Neptune):**
   - (a) Worker drafts wording in same human spirit; Reviewer + user check at submit.
   - (b) User provides 5 phrases verbatim now → Worker uses verbatim.
   - (c) Block emission for those planets (skip if planet in Дом 1 — not emit phrase) until wording approved.

2. **`[:2]` cap on 1st-house planets:**
   - (a) Keep `[:2]` с явным cap test (`test_useful_people_caps_first_house_at_two`); Marina Venus dropped, Sun + Mercury mentioned.
   - (b) Remove cap; mention all 1st-house planets (Marina would emit Sun + Mercury + Venus joined via `;`).
   - (c) Different cap (e.g. 3) — explicit value + test.

3. **3rd sentence structure (current 3-clause «X; Y; и солнечные Z по той же оси»):**
   - (a) Keep structure, only replace inner phrases (per Bug 2 fix).
   - (b) Also restructure: 2 separate sentences («В этом году вокруг вас будут полезны {phrases}. И солнечные {Sun_sign} по той же оси.»).
   - (c) Other rewrite Worker proposes — document in HANDOFF.

4. **Legacy preservation of `_FIRST_HOUSE_PLANET_PEOPLE_RU`:**
   - (a) Rename old dict → `_FIRST_HOUSE_PLANET_PEOPLE_RU_LEGACY`, keep in file for rollback reference.
   - (b) Delete old dict (Path 1 closed, no rollback expected).
   - (c) Don't preserve separately, but commit-message explicitly references commit that introduced old wording (для git-blame trace).
