# TASK: humanize-generic-outer-card-psychology

- Status: open
- Ready: no
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

### Stage 3 — Composition algorithm (per § Ready clarification 1)

Worker implements deterministic composition of 2-3 sentences combining 3 dimensions:

- (a) Template substitution: `«{transit_inner}. Эта тема касается {target_function} — {aspect_tone}»`.
- (b) Sentence pool per dimension (3 sentences total, one per dimension).
- (c) Hybrid: short opener (transit) + middle (target affected) + closer (aspect tone).
- (d) Worker proposes alternative в HANDOFF.

### Stage 4 — Edge cases

**Same-planet outer aspects** (Uranus-Uranus return, Neptune-Neptune square, Pluto-Pluto sextile — generational signatures):
- Worker design choice: emit specialized phrasing acknowledging «возрастной / поколенческий» context, OR fall back to standard composition с note.

**Outer-outer aspects** (Uranus-Neptune, Uranus-Pluto, Neptune-Pluto — generational social signatures):
- Worker uses same composition algorithm; output naturally reflects «деятельно общественное» nature через outer-target psychology dict entries.

**Fallback (unknown planet/aspect):**
- If composition cannot produce text (missing key в any of 3 dicts), Worker decision per § Ready clarification 2:
  - (a) Generic fallback phrase «Психологический уровень этого транзита раскрывается через интуитивное переживание контакта.»
  - (b) Skip entirely — return empty string; event_level paragraph carries the card alone.

### Stage 5 — Acceptance tests

Extend existing `services/api-python/tests/test_transit_section_generic.py` (or new file if Worker prefers — per § Ready clarification 4).

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
- [ ] Empty-input path produces fallback OR omits psychology paragraph per clarification 2 (not generic «красивая вода» padding).

## STOP triggers

- Worker tempted to copy Daragan book verbatim → STOP, author own short phrasings.
- Worker tempted to add LLM call → STOP, deterministic templates only.
- Worker tempted to keep house phrase в psychology text → STOP, this IS the bug.
- Worker tempted to modify `_generic_event_level_text` → STOP, event-level is correct; out of scope.
- Worker tempted to modify `_OUTER_CARD_FACTS` calibrated psychology → STOP, calibrated allowlist preserved.
- Worker writes generic «универсальной красивой воды» applicable к any (planet, target, aspect) combination → STOP, each dimension dict entry must be specific к that planet/target/aspect archetype.
- Worker finds calibrated case regression (psychology text changes for allowlist card) → STOP, refine.
- Worker finds engine output / facts shape requires changes для new dimensions → STOP, use existing signature.

## Reviewer subagent — per § Ready clarification 5

Tier B single-file rewrite + phrase library design. Per recent precedent:
- Phase 9.2A / 9.3A / Tail Polish (Tier C): Reviewer optional + TL inline-verify.
- Human-Readable / Specificity (Tier B+): Reviewer REQUIRED.

This TASK Tier B borderline — Reviewer disposition per § Ready.

## Context

**Mode normal + Tier B (Reviewer disposition per § Ready).** Worker mode: normal.

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

**Ready: no** — pending 5 clarifications below.

## Ready clarifications (pending user direction 2026-05-20)

1. **Composition algorithm (Stage 3).**
   - (a) Template substitution: `«{transit_inner}. Эта тема касается {target_function} — {aspect_tone}.»` (compact, 1-2 sentences).
   - (b) Sentence pool per dimension — 3 sentences total, one per dimension (rich, 3 sentences).
   - (c) Hybrid — short opener (transit) + middle (target affected) + closer (aspect tone), naturally flows.
   - (d) Worker proposes alternative с justification.

2. **Fallback for missing-dimension dict entry (Stage 4).**
   - (a) Generic fallback phrase «Психологический уровень этого транзита раскрывается через интуитивное переживание контакта.»
   - (b) Skip entirely — return empty string; event_level paragraph carries card alone.
   - (c) Worker proposes другое handling.

3. **Same-planet outer aspects** (Uranus-Uranus return, Neptune-Neptune square, Pluto-Pluto sextile).
   - (a) Specialized phrasing acknowledging «возрастной / поколенческий» context.
   - (b) Standard composition (works generically через outer-target psychology dict).
   - (c) Worker proposes.

4. **Test file location.**
   - (a) Extend existing `test_transit_section_generic.py` (consistent с previous synthesis tests).
   - (b) New file `test_generic_psychology_humanization.py`.

5. **Reviewer disposition.**
   - (a) Optional + TL inline-verify (consistent с 9.2A / 9.3A / Tail Polish Tier C precedent).
   - (b) REQUIRED external Reviewer (Tier B substantive content rewrite; visible end-user impact).
