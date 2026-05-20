# TASK: consultation-summary-specificity-enrichment

- Status: open
- Ready: no
- Date: 2026-05-20
- Project: astro
- Layer: services (Python presentation: `synthesis_themes.py` Layer 1 evidence enrichment + Layer 3 templates; new themed mini-block; tests)
- Risk tier: B+ (multi-block content uplift; possible new Layer 1 evidence channels; new «Полезные люди» section; new tests; no architecture rewrite; no engine touch)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User comparison 2026-05-20 (свежий software рендер `consultation-12.pdf` @ product `1074cf8` vs эталон `/Users/ilya/Downloads/Соляр 2026-2027 (2).pdf`) verdict: **«Итоги консультации стали сильно лучше и уже читаются как живой текст, но по смысловой конкретике всё ещё слабее Марины. До "готово как эталон" ещё один слой нужен.»**

### What PASSES (preserved, do not regress)

- Раздел уже не Natalyа-shaped.
- Нет «наедине с собой» / «внутреннего цикла» / 1-12 как главной темы Olga.
- Правильная логика: 5-11, ЛИЧНОСТЬ через 5 дом, Asc Libra, MC Cancer, прогрессивная Луна 11, дата 02.09.2026.
- Opener + ЛИЧНОСТЬ + Общий вывод — читаются как консультация.
- Канцелярит вычищен (tail polish 2026-05-19 closed).

### What FAILS (specificity gap)

1. **ФИНАНСЫ слишком общие.** Эталон: траты на детей / радости / возможная поддержка от ребёнка или ребёнок начинает зарабатывать / дирекционно выделены заработки. Software: «ресурсы и доходы требуют пересмотра...» — нормально, но универсально.

2. **НЕДВИЖИМОСТЬ/СЕМЬЯ без конкретных периодов.** Эталон: «ноябрь 2026 – январь 2027 и июль 2027 благоприятны для ремонта / жилплощади / земли / юридических бумаг.» Software: нет дат.

3. **ЛЮБОВЬ/ТВОРЧЕСТВО/ДЕТИ не вытаскивает Уран–Венера.** Эталон: «Уран 90 Венера до 15.04.2027 — искусство/красота/дизайн, новизна вкусов и чувств.» Software: тема названа красиво, но без этого прогностического факта.

4. **РАБОТА/СТАТУС без Нептун–Юпитер.** Эталон: «Нептун 120 Юпитер до 05.02.2027 как реализация социальной мечты — благоприятно для повышения.» Software: статус живее, но связка не поднята.

5. **ПЛАНЫ/КОЛЛЕКТИВ слишком общий.** Эталон: «планы трансформируются, связаны с партнёрством и 3 домом.» Software: команда/будущее/Нептун — менее предметно.

6. **«Полезные люди» отсутствуют.** Эталон: финальный практический блок «Весы/Овны, люди с Венерой/Солнцем в 1 доме, солнечные Раки». Software: нет аналога.

### Not in scope (known issues, deferred)

- **Дирекции 9 vs 4 over-include** — Phase 9.1 editorial verdict (closed; editorial/curation-required).
- **Outer cards 11 vs 6 planet-target over-include** — Phase 9.3 editorial/horizon (deferred per user 2026-05-19).
- **Календарь аспектов Плутон 150 повторы** — Phase 9.5A deferred (new sub-problem).

## Worker framing (verbatim user direction 2026-05-20)

> «Цель: тематические блоки должны подтягивать конкретные факты прогностики:
> - финансы → дети/радости/заработки/дирекции;
> - недвижимость → окна Юпитера;
> - любовь/дети → Уран–Венера + дата;
> - работа/статус → Нептун–Юпитер + повышение;
> - планы → трансформация планов + партнёрство + 3 дом;
> - финальный mini-block "полезные люди".»

> **«Главный guard: не копировать Марину, а генерировать из computed facts. Марина тут oracle смысла, не база текстов.»**

> «Сейчас итог: форма уже хорошая, человеческая. Не хватает именно фактической насыщенности как у Марины.»

## Scope (Tier B+ specificity enrichment)

### Stage 1 — Evidence channel enrichment (Layer 1)

Audit existing `_collect_theme_evidence` channels; add granularity for content gaps:

**1.1 — Dated event extraction:**
- For each outer transit (Уран/Нептун/Плутон) aspecting personal planet (Sun/Moon/Mercury/Venus/Mars/Jupiter): pull window end date.
- For each Jupiter/Saturn house-transit: pull window end date.
- Surface to Layer 2/3 as `dated_events` evidence channel per theme.

**1.2 — Cross-house combinations:**
- For each solar→natal row, identify cross-theme implications:
  - Solar 2 → natal 5 = «финансы ↔ дети/творчество» combination.
  - Solar 4 → natal 7 = «дом ↔ партнёрство» combination.
  - Solar 5 → natal 2 = «дети ↔ финансы» (children earnings / spending on children).
  - Generic rule per § Ready clarification 3.

**1.3 — Outer-card primary signals:**
- For Olga's 6 Marina-selected cards (Уран кв Венера, Уран опп Уран, Уран опп Юпитер, Нептун трин Юпитер, Нептун трин Уран, Плутон секст Уран):
  - Each card → tagged to theme (Уран кв Венера → ЛЮБОВЬ-творчество; Нептун трин Юпитер → СТАТУС-работа).
  - Pull window dates (engine emits these в `display_windows`).
- Generic mapping: «outer planet + aspect + personal-planet target → block theme tag».

**1.4 — Jupiter/Saturn house-presence windows:**
- For each calendar month / quarter of solar year:
  - Identify Jupiter natal house at start/end of month.
  - Identify Saturn natal house.
  - Aggregate into «Jupiter в N доме до DATE» / «Saturn держит N дом» themed signals.

### Stage 2 — Block-specific specificity rules

For each themed block, define which evidence types surface (per user direction):

**2.1 — ФИНАНСЫ (block 3):**
- IF solar 2 → natal house involves 5 (children) → emit «возможные траты на детей / творческие проекты / удовольствие».
- IF solar 5 → natal 2 OR engine direction connects 5+2 → emit «возможный источник дохода через детей / творчество».
- IF outer transit aspects natal 2-ruler → emit «дирекционно выделены заработки до DATE».
- IF Jupiter в 2 доме до DATE → emit «период финансовой удачи / расширения дохода до DATE».
- Generic guard: ≥1 specific factual reference per case, не «универсально».

**2.2 — НЕДВИЖИМОСТЬ/СЕМЬЯ (block 5):**
- IF Jupiter в 4 доме starting MONTH или ending MONTH → emit «MONTH-MONTH благоприятен для ремонта / жилплощади / земли / юридических бумаг».
- IF Saturn aspect 4 → emit «требует структурных решений по дому».
- IF outer transit к natal 4-ruler → emit «глубинная работа с темой дома до DATE».
- IF direction 1+4 OR 4+10 active → emit «личное участие в семейных решениях до DATE».

**2.3 — ЛЮБОВЬ/ТВОРЧЕСТВО/ДЕТИ (block 6):**
- IF Uranus aspect Venus → emit «Уран PHASE Венера до DATE — обновление вкусов / иначе выглядеть / новизна стиля / искусство / красота / дизайн».
- IF Neptune aspect Venus → emit «Нептун PHASE Венера — мечтательность / идеализация / творческое вдохновение до DATE».
- IF Jupiter в 5 доме → emit «период радости / расширения через детей-творчество до DATE».
- IF direction with 5-house involvement → emit «дирекционно подтверждено».

**2.4 — РАБОТА/СТАТУС (blocks 7 + 10 — merge for evidence purposes):**
- IF Neptune trine/sextile Jupiter → emit «Нептун PHASE Юпитер до DATE — реализация социальной мечты / благоприятно для повышения».
- IF Jupiter в 10 доме → emit «период карьерного роста / расширения статуса до DATE».
- IF Saturn aspect MC ruler → emit «требует ответственности / структурных решений по карьере».
- IF direction 10+1 OR 1+10 active → emit «личная активность напрямую влияет на статус до DATE».

**2.5 — ПЛАНЫ/КОЛЛЕКТИВ (block 11):**
- IF solar 11 → natal 7 (partnership) → emit «планы связаны с партнёрством».
- IF solar 11 → natal 3 (contacts) → emit «планы через 3-й дом — учёба, переговоры, ближний круг».
- IF outer transit aspect 11-house planets → emit «трансформация планов / переоценка коллектива до DATE».
- IF Pluto в 11 доме → emit «глубокая перестройка круга единомышленников».

### Stage 3 — «Полезные люди» mini-block (new section 13 OR within closer per § Ready clarification 4)

Generic derivation from natal chart (per user clarification 1 strategy):

- **Asc sign + opposing sign** → «вам в этом году помогают [Asc-sign-people] и [opposing-sign-people]» (e.g. Olga Libra Asc → Весы/Овны).
- **1st-house planets** → «люди с [1st-house-planet]-доминантой» (e.g. Olga Mars в 1 → люди с Марсом-доминантой).
- **Sun sign** → «солнечные [Sun-sign]» (e.g. Olga Sun в Раке → солнечные Раки).
- **MC sign** → «люди со статусом в [MC-sign]» (e.g. Olga MC Cancer → люди семейного склада).

Generic deterministic mapping. NO Marina-copy. NO LLM. Each item traces к specific natal evidence.

### Stage 4 — Cross-house combinations layer

Per user clarification 3 mechanism, implement either:
- (a) Generic rule: «if solar→natal row connects theme_X house to theme_Y house, emit cross-phrasing in block_X referring к block_Y».
- (b) Curated cross-house mapping (e.g. 2→5 = «дети-расходы»; 5→2 = «дети-доход»; 4→7 = «дом-партнёрство»).
- (c) Worker proposes.

### Stage 5 — Acceptance tests

Extend existing `services/api-python/tests/test_consultation_summary_evidence.py` (NO new file, per predecessor convention):

**Olga acceptance (per user spec 2026-05-20):**

- ФИНАНСЫ block содержит ≥1 specific factual reference (детей/творчества/Юпитера/Плутона + DATE).
- НЕДВИЖИМОСТЬ block содержит ≥1 specific Jupiter window date (e.g. «ноябрь 2026 – январь 2027»).
- ЛЮБОВЬ block содержит «Уран» AND «Венера» AND date (Уран 90 Венера до 15.04.2027 OR similar).
- СТАТУС block содержит «Нептун» AND «Юпитер» AND date (Нептун 120 Юпитер до 05.02.2027 OR similar).
- ПЛАНЫ block содержит «партнёрств» OR «3-й дом» reference.
- Final «Полезные люди» mini-block содержит: Весы / Овны OR Libra/Aries; солнечные Раки OR Cancer Suns; reference к 1-house planets (Mars или другое в Olga's 1st house).

**Calibrated regression:**
- All 6 calibrated cases (02/03/05/07/08/10) render без errors.
- Each case's blocks pull case-specific facts (Maxim's финансы references его specific axis evidence; Natalya's статус references her facts; etc.).
- No client-specific text leaks (no Olga-style phrasings в Maxim/Natalya outputs).

**Strict-string negative preserved (from predecessor TASKs):**
- All Natalya hardcoded phrases still absent.
- All tail-polish hard-removal phrases still absent.

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` (Layer 1 evidence channels enrichment + Layer 3 block-specific specificity rules + «Полезные люди» mini-block).
  - `services/api-python/tests/test_consultation_summary_evidence.py` (extend per predecessor convention).
  - `project-overlays/astro/STATUS_RU.md`.
  - `services/api-python/app/pdf/templates/solar.html.j2` — ONLY if «Полезные люди» mini-block needs new template section (Worker verifies; minimal touch).

- new: —

- delete: —

## Do not touch

- Layer 1 architectural skeleton (existing helpers like `_collect_theme_evidence` can be **extended**, не replaced).
- Layer 2 `_score_themes` numerics (preserved).
- Opener / closer structural code (extend evidence references только; structure preserved).
- Themed block headings + display order (preserved).
- Section count (12 sections; «Полезные люди» либо section 13 либо within closer per § Ready clarification 4).
- Phase 4/7/8 calibrated data.
- Phase 9.2B angle filter / Phase 9.3A horizon / Phase 9.4 axis tests.
- Engine: Haskell core, schema, fixtures.
- `_legacy_compose_theme_prose` (orphan).
- **NO LLM / GPT API.**
- **NO Marina-narrative copying from her PDFs.** Marina is oracle of meaning, NOT text base.
- **NO Olga-only hardcoded text.** Generator must work universally.
- **NO engine output modifications.** All evidence channels read from existing `facts_json`.

## Acceptance

### Primary (Olga consultation 12)

- [ ] ФИНАНСЫ contains ≥1 specific factual reference (children / creative / Jupiter / Pluto + DATE).
- [ ] НЕДВИЖИМОСТЬ contains Jupiter window dates («ноябрь 2026 – январь 2027» equivalent).
- [ ] ЛЮБОВЬ contains «Уран» + «Венера» + date (Уран 90° Венера до 15.04.2027 — engine actually emits this; surface).
- [ ] СТАТУС contains «Нептун» + «Юпитер» + date (Нептун 120° Юпитер до 05.02.2027 — engine actually emits this; surface).
- [ ] ПЛАНЫ contains partnership OR 3rd-house reference.
- [ ] «Полезные люди» mini-block contains: Asc-sign-people (Весы), opposing-sign-people (Овны), Sun-sign-people (солнечные Раки), 1st-house-planet-people (with Mars-derived phrasing OR similar).
- [ ] All preserved acceptance items from previous TASKs (no Natalya phrases / no «1-12» / no canclerite tail repeats / no «Год партнёрства» в ЛИЧНОСТЬ / etc.).

### Calibrated regression

- [ ] All 6 calibrated cases render с case-specific evidence в каждом block.
- [ ] No client text leakage across cases.
- [ ] Worker shows per-case diff в HANDOFF (before vs after enrichment).

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `503 + N` (N = new acceptance tests). **0 failed AND 0 xfailed.**
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (synthesis_themes enrichment + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 6.

### Discipline

- [ ] NO Marina-text copying from her PDFs.
- [ ] NO Olga-only hardcoded text.
- [ ] NO LLM.
- [ ] NO engine modifications.
- [ ] All emitted facts trace к existing `facts_json` data.
- [ ] Each block-specific specificity rule applies universally (Worker tests на 6 calibrated cases что rules не Olga-specific).
- [ ] Length-non-increase guard relaxed per § Ready clarification 5 (specificity expansion expected to grow content; Worker shows growth attributable к factual references, не canclerite re-introduction).

## STOP triggers

- Worker tempted to add LLM → STOP, deterministic templates only.
- Worker tempted to modify engine → STOP, use existing facts.
- Worker tempted to write Olga-specific hardcoded text → STOP, generator must be generic.
- Worker tempted to copy Marina-narrative from her PDFs → STOP, Marina is oracle of meaning, not text base.
- Worker finds calibrated case loses content или gains nonsensical content (e.g. ФИНАНСЫ для Maxim suddenly mentions «дети» which his evidence doesn't support) → STOP, refine.
- Worker finds existing acceptance test breaks (Natalya phrasings appear, canclerite returns) → STOP.
- «Полезные люди» mini-block requires evidence Worker doesn't have в facts_json → STOP, escalate (NO engine new fields).
- Worker finds factual claim emitted (e.g. «Уран 90 Венера до 15.04.2027») что НЕ matches engine output для этого case → STOP, fix evidence-extraction logic.

## Reviewer subagent — per § Ready clarification 6

Tier B+ multi-block content uplift. Previous similar TASK (`human-readable-consultation-summary`) used REQUIRED. This TASK has comparable scope.

## Context

**Mode normal + Tier B+ (Reviewer disposition per § Ready).** Worker mode: normal.

**Baseline:**
- Product main @ `1074cf8` (tail polish closed).
- Overlay master @ `783f4cb` (tail polish closure).
- Pytest baseline: `503 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Predecessor TASK 1 (Natalya-defaults removal): `project-overlays/astro/TASKS/archive/2026-05-19-evidence-based-consultation-summary-rewrite.md`.
- Predecessor TASK 2 (3-layer architecture): `project-overlays/astro/TASKS/archive/2026-05-19-human-readable-consultation-summary.md`.
- Predecessor TASK 3 (tail polish): `project-overlays/astro/TASKS/archive/2026-05-19-synthesis-tail-template-polish.md`.
- User comparison report 2026-05-20: source message (PASS list + FAIL list verbatim).
- Marina-Olga reference PDF (oracle of meaning only): `/Users/ilya/Downloads/Соляр 2026-2027 (2).pdf`.
- Current Olga PDF (baseline pre-enrichment): `/Users/ilya/Projects/astro/data/pdf/consultation-12.pdf` @ product `1074cf8`.
- Olga DB consultations: `/Users/ilya/Projects/astro/data/astro.db` rows 10/11/12.

**Not in scope (explicit per user 2026-05-20):**
- Phase 9.1 directions over-include (closed; editorial).
- Phase 9.3 outer-card horizon (deferred).
- Phase 9.5A calendar aspects (deferred).
- Engine output modifications.
- Marina-text copying.

**Ready: no** — pending 6 clarifications below.

## Ready clarifications (pending user direction 2026-05-20)

1. **«Полезные люди» derivation algorithm (Stage 3).**
   - (a) Asc sign + opposing + 1st-house planets + Sun sign + MC sign — 5 evidence channels.
   - (b) Personal-significator inference (Asc-ruler, MC-ruler, Sun-sign — emit those sign-people).
   - (c) Worker proposes algorithm.

2. **Date extraction strategy (Stage 1.1):**
   - (a) Reuse already-computed `outer_cards.display_windows` + extract Jupiter/Saturn house-window dates from `annual_transit_table`.
   - (b) Add new Layer 1 evidence channel `dated_events` with structured `(planet, aspect, target, start_date, end_date)` per theme.
   - (c) Worker proposes.

3. **Cross-house combinations (Stage 4):**
   - (a) Generic rule: «if solar→natal row connects theme_X house to theme_Y house, emit cross-phrasing in block_X».
   - (b) Curated cross-house mapping (e.g. 2↔5 = «дети-расходы»/«дети-доход»; 4↔7 = «дом-партнёрство»; etc.).
   - (c) Worker proposes.

4. **«Полезные люди» mini-block placement.**
   - (a) New section 13 after «Общий вывод» (extends structure 12 → 13 sections).
   - (b) Paragraph inside «Общий вывод» closer (preserves 12 sections).
   - (c) Separate «Полезные люди / окружение» section before closer (12-th moved to «Общий вывод» becomes 13-th).

5. **Length-non-increase guard disposition.** Previous TASK had strict «length ≤ pre-polish». This TASK expects specificity expansion — content grows from factual references.
   - (a) Drop length guard для этого TASK; specificity > brevity.
   - (b) Soft guard — length may grow, но Worker shows growth attributable к factual references (≥80% of new chars are dated events / cross-house combos / Полезные люди), не canclerite re-introduction.
   - (c) Strict guard — must stay within ±10% of current.

6. **Reviewer subagent.**
   - (a) REQUIRED external Reviewer (parallel к `human-readable-consultation-summary` predecessor).
   - (b) Optional + TL inline-verify (lower discipline; Tier B+ borderline).
