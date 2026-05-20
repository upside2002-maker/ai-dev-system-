# TASK: humanize-generic-outer-card-psychology

- Status: review
- Ready: yes
- Date: 2026-05-20
- Project: astro
- Layer: services (Python presentation: `outer_cards.py` `_generic_psychology_text` rewrite + supporting phrase libraries)
- Risk tier: B (single helper rewrite + 3 phrase libraries; new tests; no architecture change; no engine touch; no calibrated data touch)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User code review 2026-05-20 (`services/api-python/app/pdf/outer_cards.py:1470-1504`) identified that `_generic_psychology_text` смешивает 4 разных слоя в одном выводе:

```python
return (
    f"Транзит {transit_ru} в {aspect_loc} c натальным {target_ru}"
    f"{house_phrase}. Транзитная планета {archetype}. "
    f"Этот аспект — {_ASPECT_CHARACTER_RU.get(aspect, '')}."
)
```

**Current output example (generic card для Olga «Уран кв Венера»):**

> «Транзит Уран в квадрате c натальной Венерой в области 4 натального дома. Транзитная планета приносит неожиданные перемены и пробуждение. Этот аспект — напряжённая ситуация, требующая преодоления.»

**Bug breakdown:**
- Психологический уровень starts as technical engine string «Транзит X в Y c натальной Z в области N дома» — это не «что человек переживает внутри».
- Дома вставляются в psychological level — должны жить в event level / golden rule table.
- Звучит как engine-comment, не как consultation.
- Mixes psychological + event + technical aspect description в одном параграфе.
- В PDF рядом уже есть golden-rule table с домами — duplication.

**Programme classification:** code-quality bug в generic outer-card pipeline. Calibrated Marina cards (`_OUTER_CARD_FACTS`) untouched — у них psychology уже curated. Generic-fallback path (Olga consultation 12, non-calibrated clients) — это где bug surfaces.

## Worker framing (verbatim user direction 2026-05-20)

> «Психологический уровень — это не "какие дома затронет", а "что внутри человека меняется под контактом". Дома — ниже, в событийности и золотом правиле.»

> «Не копировать книгу Дарагана дословно. Можно опираться на Дарагановскую логику транзитов и общий астрологический смысл, но формулировки должны быть авторскими, короткими и deterministic.»

> «Психологический уровень должен строиться из: транзитная планета (Уран/Нептун/Плутон), натальная цель (Венера/Марс/Луна/Юпитер/Уран/Нептун/...), тип аспекта (соединение/секстиль/квадрат/тригон/оппозиция). Без домов.»

## Target style (verbatim user-provided 2026-05-20)

**Уран квадрат Венера:**

> «Внутри появляется потребность в свежести: иначе чувствовать, иначе выбирать, иначе реагировать на близость, красоту и удовольствие. Может тянуть к новому стилю, новым симпатиям, свободе в чувствах. Старые вкусы и привычные способы получать радость начинают казаться тесными.»

**Нептун тригон Юпитер:**

> «Этот транзит усиливает веру, воображение и ощущение большого смысла. Может появиться желание довериться мечте, увидеть более широкий горизонт, почувствовать поддержку там, где раньше было мало уверенности. Важно не путать вдохновение с уходом от реальности.»

**Плутон секстиль Уран:**

> «Психологически это период глубокой внутренней перестройки: меняется отношение к свободе, самостоятельности и будущему. Старые реакции постепенно теряют силу, появляется готовность к более смелым решениям.»

Worker designs final phrasings within этого style envelope. **NOT verbatim copy.** Author's own short deterministic prose.

## Scope (Tier B helper rewrite + phrase libraries)

### Stage 1 — Audit current state

Worker inventories:
- `_generic_psychology_text` (line 1470) — primary rewrite target.
- `_generic_event_level_text` (line 1507) — **DO NOT TOUCH** (event level uses houses correctly; preserve verbatim).
- `_OUTER_CARD_FACTS` (lines ~496-810) — **DO NOT TOUCH** (calibrated Marina cards curated psychology; preserve).
- `_PLANET_NOM_RU` / `_PLANET_INSTR_RU` / `_ASPECT_LOC_RU` / `_ASPECT_NOM_RU` / `_ASPECT_CHARACTER_RU` — existing helper dicts; preserve unchanged.

### Stage 2 — Phrase library design

Worker designs **3 controlled phrase libraries** (per implementation hint):

**2.1 — Transit planet inner-process dict (`_TRANSIT_PSYCHOLOGY_RU`):**

```python
_TRANSIT_PSYCHOLOGY_RU = {
    "Uranus":  "...",  # внутренний толчок к свободе / неожиданному / новому
    "Neptune": "...",  # размывание границ / усиление чувствования / идеализация
    "Pluto":   "...",  # глубинная перестройка / тяга к концентрации силы
}
```

Each value: short phrase (~10-20 words) evoking the inner process the transit planet brings.

**2.2 — Target planet psychic-function dict (`_TARGET_PSYCHOLOGY_RU`):**

Covering 10 target planets (Sun / Moon / Mercury / Venus / Mars / Jupiter / Saturn / Uranus / Neptune / Pluto):

```python
_TARGET_PSYCHOLOGY_RU = {
    "Sun":     "...",  # ego / жизненная воля / самоощущение
    "Moon":    "...",  # эмоциональная база / уют / переживание дома
    "Mercury": "...",  # ум / общение / способ обработки информации
    "Venus":   "...",  # близость / удовольствие / красота / вкусы
    "Mars":    "...",  # действие / напор / способ заявлять себя
    "Jupiter": "...",  # вера / горизонт / смысл / расширение
    "Saturn":  "...",  # структура / ответственность / границы
    "Uranus":  "...",  # свобода / самостоятельность / необычное
    "Neptune": "...",  # мечта / вдохновение / растворение в общем
    "Pluto":   "...",  # глубина / сила / тёмные ресурсы психики
}
```

**2.3 — Aspect tone dict (`_ASPECT_PSYCHOLOGY_RU`):**

5 Ptolemaic aspects (Conjunction / Sextile / Square / Trine / Opposition):

```python
_ASPECT_PSYCHOLOGY_RU = {
    "Conjunction": "...",  # тесное слияние / перепрошивка темы
    "Sextile":     "...",  # мягкая поддержка / шанс
    "Square":      "...",  # напряжение / преодоление / тесные старые формы
    "Trine":       "...",  # поддержка / естественное раскрытие
    "Opposition":  "...",  # выбор / диалог между двумя сторонами / зеркалирование
}
```

### Stage 3 — Composition algorithm (per user clarification 1 = (c) hybrid)

User direction 2026-05-20 verbatim: «Короткий opener от транзитной планеты, затем target-психика, затем aspect tone. Главное — чтобы читалось как цельный абзац, не как три склеенные карточки.»

Worker implements **hybrid composition**:
1. **Short opener** anchored к transit planet's archetypal inner-process (1 sentence).
2. **Target-psyche middle** showing which psychic function is touched (1 sentence).
3. **Aspect tone closer** showing tension/support/transformation character (1 sentence).

Connectors между sentences MUST flow naturally («Внутри появляется...», «Эта тема касается...», «И это идёт через...», «Старое начинает...»). NOT три склеенные карточки.

Worker may merge sentences 2+3 if natural — composition target is **single coherent paragraph**, not strict 3-sentence template.

### Stage 4 — Edge cases

**Same-planet outer aspects** — per user clarification 3 = (a) specialized phrasing:

User direction 2026-05-20 verbatim: «Особенно важно для Уран–Уран, Нептун–Нептун, Плутон–Плутон: это возрастные/поколенческие этапы, а не обычный target.»

Worker implements **specialized phrasing** acknowledging «возрастной / поколенческий» context для same-planet outer aspects:

- **Uranus aspect Uranus** (especially Square ~21 years, Opposition ~42 years, Trine ~28 years, Return ~84 years): emit phrasing evoking age-stage of freedom/self-renewal («это возрастной перелом темы свободы и самостоятельности — что отжило, заменяется новым»).
- **Neptune aspect Neptune** (especially Square ~42 years — midlife dream check): emit phrasing evoking dream-check-point («это возрастная проверка большой мечты — пересборка того, во что верится»).
- **Pluto aspect Pluto** (especially Square ~36-40 years): emit phrasing evoking power-stage transformation («это возрастная инициация в собственную силу — старые источники власти теряют силу»).

Dedicated `_SAME_PLANET_PSYCHOLOGY_RU` mini-dict keyed by `(planet, aspect)` tuples (e.g. `("Uranus", "Square")`, `("Neptune", "Square")`, etc.); composition routes к этому dict when `transit_planet == target`.

**Outer-outer aspects** (Uranus-Neptune, Uranus-Pluto, Neptune-Pluto — generational social signatures):
- Worker uses same composition algorithm; output naturally reflects «деятельно общественное» nature через outer-target psychology dict entries.

**Fallback (unknown planet/aspect) — per user clarification 2 = (b) skip entirely:**

User direction 2026-05-20 verbatim: «Никаких generic-padding фраз. Лучше пусто, чем "интуитивное переживание контакта".»

If composition cannot produce text (missing key в any of 3 dicts) → return **empty string**; event_level paragraph carries the card alone. Fabrication-guard-consistent: no generic-soup fallback. Empty rendering allowed; padding forbidden.

### Stage 5 — Acceptance tests (per user clarification 4 = (a) extend existing)

**Extend** `services/api-python/tests/test_transit_section_generic.py` (consistent с previous synthesis tests; no new file fragmentation).

**Strict-string negative for psychology text (per user spec 2026-05-20):**

Generic psychology output для Olga / non-calibrated cases MUST NOT contain:
- `дом` (substring)
- `натального дома`
- `в области`
- `Ситуация коснётся`
- `сферы X дома` (regex `сферы \d+ дома`)
- `Транзит [Уран|Нептун|Плутон] в [квадрате|тригоне|оппозиции|секстиле|соединении] c натальной` (regex full technical-string pattern)

**Semantic positive for psychology text:**
- Uranus-Venus psychology contains keywords: `свежесть` / `свобода` / `вкус` / `чувства` / `новизн`.
- Neptune-Jupiter psychology contains: `вер` / `мечт` / `смысл` / `вдохновен` / `идеализ`.
- Pluto-Uranus psychology contains: `перестройк` / `глубин` / `свобод` / `трансформ` / `смел`.
- Uranus / Neptune / Pluto produce **different** psychology text для same target+aspect.
- Square / Trine / Opposition / Sextile produce **different** tonality.

**Event-level test (preserve):**
- `_generic_event_level_text` output STILL contains house language — `Ситуация коснётся` / `сферы X дома` etc.
- House language moved FROM psychology TO event level only.

**Calibrated regression:**
- All 6 calibrated cases (`OUTER_CARD_ALLOWLIST` entries) render без изменений — curated psychology / event text preserved bit-identical.
- `_OUTER_CARD_FACTS` not modified.

## Files

- modify:
  - `services/api-python/app/pdf/outer_cards.py` (rewrite `_generic_psychology_text` + add 3 phrase library dicts).
  - `services/api-python/tests/test_transit_section_generic.py` (extend per § Ready clarification 4 OR new file).
  - `project-overlays/astro/STATUS_RU.md`.

- new (optional, Worker discretion):
  - `services/api-python/tests/test_generic_psychology_humanization.py`.

- delete: —

## Do not touch

- `_OUTER_CARD_FACTS` calibrated psychology / event text (preserved bit-identical).
- `_generic_event_level_text` (event level uses houses correctly; preserve).
- `OUTER_CARD_ALLOWLIST`.
- Calibrated cases 01/02/03/04/05/07/08/09/10 outputs.
- Phase 9.2B angle filter / Phase 9.3A horizon / Phase 9.4 axis tests.
- Engine: Haskell core, schema, fixtures.
- Predecessor `synthesis_themes.py` work (separate module; не trogать).
- `solar.html.j2` template.
- `builder.py`.
- Interval logic / outer-card window selection.
- **NO LLM / GPT API.**
- **NO Daragan verbatim copying.** Use Daragan logic of archetypes; author's own short phrasings.
- **NO engine modifications.** All inputs from existing helper signature.
- **NO house references в psychology text** (hard guard per user spec).

## Acceptance

### Primary (Olga consultation 12, generic outer cards)

- [ ] All generic-card psychology text passes 6 strict-string negative assertions (no `дом` / `натального дома` / `в области` / `Ситуация коснётся` / `сферы X дома` / technical-string regex).
- [ ] All generic-card psychology text passes semantic positive assertions:
  - Uranus-Venus → freshness/freedom/taste keywords.
  - Neptune-Jupiter → belief/dream/meaning keywords.
  - Pluto-Uranus → restructure/depth/freedom keywords.
- [ ] Uranus / Neptune / Pluto produce distinct psychology output для same (target, aspect).
- [ ] Different aspects (Square / Trine / Opposition / Sextile / Conjunction) produce distinct tonality.
- [ ] Psychology text reads as «внутреннее переживание», NOT engine-comment.
- [ ] Each rendered psychology paragraph traces к 3 dimension dicts (transit + target + aspect); composition deterministic.

### Event-level preservation

- [ ] `_generic_event_level_text` output unchanged.
- [ ] Generic event-level text still contains house language («Ситуация коснётся сфер X дома» etc.).
- [ ] House content moved FROM psychology TO event level only; no loss of house information в overall card.

### Layer-separation guard (per user direction 2026-05-20, verbatim)

> «In generic cards, psychology must not mention houses, but event_level must mention houses. This split is mandatory and tested on at least 3 cards.»

- [ ] **Layer-separation test parametrized on ≥3 distinct cards** (e.g. Olga's Uranus Square Venus / Neptune Trine Jupiter / Pluto Sextile Uranus): for each card, assert `psychology` contains NO house language AND `event_level` contains house language.
- [ ] Test failure mode: ANY card violating split → STOP.

### Calibrated regression

- [ ] All 6 calibrated cases render с unchanged Marina-curated psychology / event text.
- [ ] `_OUTER_CARD_FACTS` not modified.
- [ ] Pytest baseline (calibrated allowlist tests) passes без regressions.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean.
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 527 + N` (N = new tests). 0 failed, 0 xfailed.
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (psychology rewrite + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 5.

### Discipline

- [ ] NO Daragan verbatim copying. Author's own short phrasings.
- [ ] NO LLM.
- [ ] NO engine modifications.
- [ ] NO house references в psychology text.
- [ ] NO change to event-level helper.
- [ ] NO calibrated allowlist data modifications.
- [ ] Composition deterministic — same input yields same output character-for-character.
- [ ] Empty-input path produces EMPTY string per clarification 2 = (b) (not generic «красивая вода» padding; fabrication-guard-consistent).
- [ ] **Layer-separation guard** (per user direction): psychology layer never mentions houses; event_level layer mentions houses. Tested on ≥3 distinct cards.
- [ ] Same-planet outer aspects (Uranus-Uranus / Neptune-Neptune / Pluto-Pluto) route к dedicated `_SAME_PLANET_PSYCHOLOGY_RU` dict с generational phrasing (per clarification 3 = (a)).

## STOP triggers

- Worker tempted to copy Daragan book verbatim → STOP, author own short phrasings.
- Worker tempted to add LLM call → STOP, deterministic templates only.
- Worker tempted to keep house phrase в psychology text → STOP, this IS the bug.
- Worker tempted to modify `_generic_event_level_text` → STOP, event-level is correct; out of scope.
- Worker tempted to modify `_OUTER_CARD_FACTS` calibrated psychology → STOP, calibrated allowlist preserved.
- Worker writes generic «универсальной красивой воды» applicable к any (planet, target, aspect) combination → STOP, each dimension dict entry must be specific к that planet/target/aspect archetype.
- Worker finds calibrated case regression (psychology text changes for allowlist card) → STOP, refine.
- Worker finds engine output / facts shape requires changes для new dimensions → STOP, use existing signature.
- **Worker tempted to emit generic-padding fallback** («интуитивное переживание контакта» или подобное) when dimension dict entry missing → STOP, emit empty string per clarification 2 = (b).
- **Worker writes psychology containing house language** («дом» / «натальный дом» / «в области» etc.) → STOP, layer-separation guard violated. Houses live in event_level only.
- **Worker writes event_level WITHOUT house language** для generic card → STOP, layer-separation guard violated. Event-level must surface houses.
- **Worker treats same-planet outer aspect (Uranus-Uranus / Neptune-Neptune / Pluto-Pluto) с standard 3-dimension composition** → STOP, route к `_SAME_PLANET_PSYCHOLOGY_RU` dedicated dict.
- **Worker composition reads as three glued cards** (no natural connectors between sentences) → STOP, refine flow per clarification 1 = (c) hybrid «цельный абзац».

## Reviewer subagent — REQUIRED (per user clarification 5 = (b))

User direction 2026-05-20 verbatim: «Тут нужен внешний взгляд: текст психологического уровня должен быть астрологически адекватным и человеческим.»

External Reviewer pass REQUIRED после Worker self-submit. If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- Composition follows hybrid algorithm (transit opener + target-psyche middle + aspect tone closer); reads as single coherent paragraph, NOT three glued cards.
- 3 phrase library dicts (`_TRANSIT_PSYCHOLOGY_RU`, `_TARGET_PSYCHOLOGY_RU`, `_ASPECT_PSYCHOLOGY_RU`) + 4th `_SAME_PLANET_PSYCHOLOGY_RU` для generational signatures.
- **Layer separation verified on ≥3 cards: psychology MUST NOT mention houses; event_level MUST mention houses.**
- Psychological text reads astrologically adequate + humanly (Reviewer reads ≥5 generic-card outputs).
- No Daragan verbatim copying detected (Reviewer spot-checks phrasings against Daragan-style archetypal logic — uses Daragan logic, не его words).
- No fabricated psychology (empty string emitted if dimension dict entry absent; no «интуитивное переживание контакта» padding).
- Calibrated allowlist cards bit-identical (no `_OUTER_CARD_FACTS` regression).
- 0 STOP triggers fired.

## Context

**Mode normal + Tier B (Reviewer REQUIRED per user clarification 5).** Worker mode: normal.

**Baseline:**
- Product main @ `8e59ea9` (specificity enrichment closed).
- Overlay master @ `0374570` (specificity enrichment closure).
- Pytest baseline: `527 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Buggy code: `services/api-python/app/pdf/outer_cards.py:1470-1504` (`_generic_psychology_text`).
- Correct event-level reference: `services/api-python/app/pdf/outer_cards.py:1507-1543` (`_generic_event_level_text`).
- Calibrated curated psychology (DO NOT TOUCH): `services/api-python/app/pdf/outer_cards.py:496-810` (`_OUTER_CARD_FACTS`).
- Olga generic-fallback cards: rendered when `case_label` is None или not в `OUTER_CARD_ALLOWLIST` (Olga consultation 12 path).
- Marina-Olga reference PDF (style anchor, NOT text-copy source): `/Users/ilya/Downloads/Соляр 2026-2027 (2).pdf`.

**Not in scope (explicit):**
- `_generic_event_level_text` (event level correct; preserved).
- `_OUTER_CARD_FACTS` calibrated cards (preserved).
- Engine output modifications.
- Phase 9.x sub-problems.
- Daragan book copy-paste.
- LLM integration.

**Ready: yes** — 5 clarifications applied 2026-05-20 + layer-separation guard:

1. **Composition = (c) hybrid.** Short transit opener + target-psyche middle + aspect tone closer; reads as single coherent paragraph («цельный абзац»), NOT three glued cards. Natural connectors required. Applied Stage 3.

2. **Fallback = (b) skip entirely.** Empty string when dimension dict entry missing. No generic-padding phrases. Fabrication-guard-consistent. Applied Stage 4.

3. **Same-planet outer aspects = (a) specialized phrasing.** Dedicated `_SAME_PLANET_PSYCHOLOGY_RU` dict с generational phrasings (Uranus-Uranus = «возрастной перелом темы свободы»; Neptune-Neptune square = «возрастная проверка большой мечты»; Pluto-Pluto = «возрастная инициация в собственную силу»). Applied Stage 4 + STOP trigger.

4. **Test file = (a) extend** `test_transit_section_generic.py`. NO new file. Applied Stage 5.

5. **Reviewer = (b) REQUIRED.** External pass after Worker submit. Verifies astrological adequacy + human readability + layer separation + no Daragan-verbatim. Applied Reviewer section.

**Additional guard (verbatim user direction 2026-05-20):**

> «In generic cards, psychology must not mention houses, but event_level must mention houses. This split is mandatory and tested on at least 3 cards.»

**Layer-separation guard** applied across:
- Stage 5 Acceptance tests: parametrized layer-separation test на ≥3 cards (e.g. Olga's Uranus Square Venus / Neptune Trine Jupiter / Pluto Sextile Uranus).
- Discipline checklist: psychology never mentions houses; event_level mentions houses.
- STOP triggers: layer-separation violation в либо direction → STOP.
