# TASK: human-readable-consultation-summary

- Status: open
- Ready: no
- Date: 2026-05-19
- Project: astro
- Layer: services (Python presentation: `synthesis_themes.py` substantive architecture + tests; minimal template changes if needed)
- Risk tier: B+ (1 substantive file rewrite — 3-layer architecture + theme planner + narrative renderer; new tests; possibly minor template touch; no engine, no schema)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Предыдущий TASK `evidence-based-consultation-summary-rewrite` (closed 2026-05-19, product `a6a3331`) убрал hardcoded Natalya defaults и сделал synthesis evidence-driven. Bug fix успешный (Olga больше НЕ описывается как «наедине с собой / 1-12»), но result звучит **технически — list символов, не консультация живому человеку**.

Post-fix Olga «Итоги консультации» содержит фразы вида:

> Тематически это личность, самопредъявление, начало нового цикла; дети, творчество, любовь, хобби, самовыражение; статус, карьера, публичная роль, цель (дома 1-5-10); сетка соляра: сол. 1 → нат. 5, сол. 2 → нат. 5, сол. 5 → нат. 9, сол. 6 → нат. 10, сол. 10 → нат. 1; engine отмечает главная ось 5-11 (подсчёт 4).

Это **factually correct** но **звучит как dump engine output**. Marina's reference PDFs пишут «Итоги консультации» как живой текст для клиента — synthesis события и тем, не listing символики.

**Programme classification:** continuation TASK, не Phase 9.x verdict. Code-quality uplift на pre-existing evidence-driven base.

## Worker framing (verbatim user direction 2026-05-19)

> «Сделать так, чтобы софт генерировал раздел «Итоги консультации» человеческим языком, как в эталонах Марины и как в примере, который сейчас написал Codex: не набор символики, не "дом 1 → дом 5", не сухой список, а связный вывод по году. Сейчас проблема такая: софт уже считает прогностику выше в PDF, но итоговый текст всё ещё звучит слишком технически и местами не делает настоящего синтеза. Нужно, чтобы итог строился из уже рассчитанных данных: соляр, прогрессии, дирекции, транзиты, outer-card события, календарь аспектов, оси года.»

> **«Не писать руками текст только для Ольги. Нужно сделать генератор, который работает на все гороскопы.»** Ольга — acceptance case; quality bar.

## Target-style anchor (verbatim Codex example, user-provided 2026-05-19)

Reference example для Olga — Worker MUST design generator that produces output of comparable quality/depth/tone (NOT hardcode this text):

> **ИТОГИ КОНСУЛЬТАЦИИ**
>
> Главная тема года — не одиночество и не уход "в себя", а включённость в людей, планы, детей, творчество, круг единомышленников и будущее. Этот соляр больше про то, как через контакт с другими людьми, через идеи, обучение, договорённости и личную инициативу вы перестраиваете свою жизнь.
>
> Год просит не ждать, пока обстоятельства сами сложатся, а занимать активную позицию. Особенно в вопросах статуса, работы, семьи, жилья, детей, творчества и планов. [...]
>
> Психологически первая часть года больше связана с тонким чувствованием людей, интуицией, планированием, внутренним созреванием идеи. Но со 2 сентября 2026 года настрой становится более активным: появляется больше смелости, прямоты, желания действовать, вести за собой, пробовать новое и не откладывать решения.
>
> **ЛИЧНОСТЬ**
>
> В этом году ваша личность раскрывается не через изоляцию, а через живое участие: дети, творчество, хобби, романтика, радость, личный вкус, самовыражение. Важно вернуть себе ощущение: "я могу хотеть, выбирать, создавать, радоваться".
>
> При этом год не только про удовольствие. Ваше личное участие напрямую влияет на статус и результат. [...]
>
> **ФИНАНСЫ**
>
> Финансовая тема связана с личными желаниями, детьми, творческими проектами, обучением и изменением привычного образа жизни. [...]
>
> [9 more blocks similarly written...]
>
> **ОБЩИЙ ВЫВОД**
>
> Год про обновление через людей, творчество, детей, планы, обучение и личную инициативу. Не про закрыться, а про выйти в более живой контакт с жизнью. [...]

Full text recorded in source message 2026-05-19. Style features:
- Human consultation tone (NOT engine-output style).
- Explanatory connectives: «год просит», «при этом», «важно вернуть себе ощущение».
- Astrological symbolism present but as **context**, не main text.
- Evidence-aware: dates mentioned when relevant («со 2 сентября 2026»), houses mentioned when illustrative.
- Sectional but variable depth — strong themes get more words; weak themes are brief or omitted.

## Required 3-layer architecture (verbatim user spec)

### Layer 1 — Evidence extraction

Normalize structured facts из уже рассчитанной прогностики:

- солярные оси + распределение планет;
- связь солярных домов с натальными (rows);
- Asc / MC соляра (signs);
- прогрессивная Луна (знак / дом / дата перехода);
- дирекции (формулы; важные aspects, особенно Asc/MC/personal);
- транзитная таблица по домам;
- outer-card события высших планет (Уран/Нептун/Плутон + dates);
- календарь аспектов (если усиливает тему).

Каждый factual item привязан к тематическому tag: личность / финансы / документы / дом-семья / дети-творчество / работа-здоровье / партнёрство / заграница-обучение / статус / планы-друзья.

### Layer 2 — Theme planner

Выбрать главные темы года **по силе подтверждения**, не по статическому списку.

Weighting (user-provided directional, Worker proposes numerics per § Ready clarification 3):

- солярная ось / доминирующая ось: **высокий вес**.
- прогрессивная Луна: **высокий вес**.
- дирекции: **высокий вес**.
- транзиты высших планет: **высокий вес**.
- Юпитер / Сатурн по домам: **средний вес**.
- повтор темы в нескольких методах: **boost**.

«Если тема не подтверждена фактами, не надо писать про неё длинный абзац "для красоты"». Empty-block guard preserved from previous TASK.

### Layer 3 — Human narrative renderer

Output = **текст консультации**, не list символов.

❌ Bad format: «Солярный 1 дом попадает в 5 дом. Ось 5-11. Дирекция 1+5. Транзит Урана к Венере.»

✅ Good format: «В этом году личная тема раскрывается через детей, творчество, хобби, удовольствие и право на собственное желание. Это не год ухода в себя, а год включённости: важно проявляться, пробовать новое, общаться, создавать и не обесценивать то, что действительно радует.»

**Architecture choice for layer 3 (Worker proposes per § Ready clarification 4):**
- (a) Per-theme deep templates с conditional phrase composition based on evidence patterns.
- (b) Phrase-library + composition rules per (evidence-shape, theme).
- (c) Marina-style consultation phrase corpus + facts-driven selection.

## Required output structure

Section structure (per user direction):

1. **Выводы** (opening synthesis paragraph(s) — top-level themes of the year).
2. **ЛИЧНОСТЬ**.
3. **ФИНАНСЫ**.
4. **ДОКУМЕНТЫ / КУРСЫ / ПОЕЗДКИ**.
5. **НЕДВИЖИМОСТЬ / СЕМЬЯ**.
6. **ЛЮБОВЬ / ХОББИ / ТВОРЧЕСТВО / ДЕТИ**.
7. **РАБОТА / ЗДОРОВЬЕ**.
8. **ПАРТНЁРСТВО / КОНТРАКТЫ**.
9. **ЗАГРАНИЦА / ОБУЧЕНИЕ / ЮРИДИЧЕСКИЕ ВОПРОСЫ**.
10. **СТАТУС**.
11. **ПЛАНЫ / ДРУЗЬЯ / КОЛЛЕКТИВ**.

Optional 12th section **«Общий вывод»** at bottom (per § Ready clarification 1) — closing synthesis paragraph.

Each section evidence-driven: weak themes brief or omitted; strong themes deeper.

## Acceptance case: Ольга consultation 11/12

Олga summary должен передавать (semantic acceptance, per user verbatim 2026-05-19):

- Год **НЕ про одиночество**, **НЕ про "1-12"**.
- Главная тема: люди / планы / дети / творчество / хобби / будущее / коллектив.
- ЛИЧНОСТЬ раскрывается через 5 дом: дети, радость, самовыражение, творчество.
- Asc Libra → партнёрство, договорённости, баланс.
- MC Cancer → цель связана с домом, семьёй, опорой, недвижимостью.
- Прогрессивная Луна 11 дом → планы, друзья, группы, будущее.
- Mars ingress / shift after **02.09.2026** → больше инициативы и лидерства (date dynamically derived per § Ready clarification 5).
- Уран к Венере → обновление вкусов, чувств, удовольствий, темы детей/творчества.
- Нептун / Юпитер → мечта, расширение, профессиональный план.
- Вывод **звучит как консультация живому человеку**.

### Strict-string negative (preserved from previous TASK)

- Не должно быть `"наедине с собой"`.
- Не должно быть `"подводить итоги внутреннего цикла"`.
- Не должно быть `"1-12"` как главной темы личности.
- Не должно быть текста, явно перенесённого из Натальи.

### Semantic positive (new)

- Содержит смысл про детей / творчество / хобби / удовольствие.
- Содержит смысл про планы / друзей / коллектив.
- Содержит Asc Libra / партнёрство / договорённости.
- Содержит MC Cancer / дом / семья / опора.
- Содержит прогрессивную Луну в 11 доме.
- Содержит переход после 02.09.2026 к большей инициативности.
- Содержит не менее **5 содержательных** тематических блоков.

## Style requirements (verbatim user spec)

Текст должен быть:

- **человеческий**;
- **консультативный**;
- **понятный без знания домов и аспектов** (символика как пояснение, не как основной текст);
- с астрологической опорой, но без перегруза символикой;
- **не "эзотерическая вода"**;
- **не универсальный текст, который подходит всем**;
- **без LLM / runtime generation**;
- **deterministic template-based generation from facts**.

Допустимо упоминание символики как контекст:

> «Это подтверждается сразу несколькими методами прогностики: соляр выделяет ось планов и творчества, прогрессивная Луна идёт по теме коллектива, а дирекции включают личную активность и статус.»

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` — substantive 3-layer architecture rewrite on top of existing evidence-collection helpers.
  - `services/api-python/tests/test_consultation_summary_evidence.py` (extend OR replace per § Ready clarification 6).
  - `project-overlays/astro/STATUS_RU.md`.
  - `services/api-python/app/templates/solar.html.j2` — ONLY if current template cannot render new output structure (verify first, modify minimally).

- new (likely):
  - `services/api-python/tests/test_consultation_summary_human.py` (per § Ready clarification 6) — Olga semantic positive + Natalya regression + 4 calibrated regression.

- delete: —

## Do not touch

- Haskell engine, schema, fixtures.
- Phase 4/7/8 calibrated data (`OUTER_CARD_ALLOWLIST`, `_OUTER_CARD_FACTS`, `MARINA_OUTER_CARD_BOUNDARIES`).
- Phase 9.2B `generic_outer_cards` / `ANGLE_TARGETS`.
- Phase 9.4 `test_summary_themes.py` (pins primary_axis engine values).
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- `builder.py` — minimal touch only if synthesis_themes API surface changes.
- `data/astro.db`.
- API endpoint plumbing.
- PDF provenance.
- **NO LLM / GPT API / LangChain call** — deterministic only.
- **NO Marina-narrative copying from one client's PDF as another client's default**.
- **NO writing text manually only for Olga** (STOP trigger).
- **NO engine modifications** (use existing facts).
- **NO new engine facts fields requested** — Worker uses what's already in `consultations.facts_json`.

## Acceptance

### Primary (Olga consultation 11/12)

- [ ] PDF Olga «Итоги консультации» reads as **human consultation**, not symbolic listing.
- [ ] All strict-string negative assertions hold (preserved from previous TASK).
- [ ] All 7 semantic positive assertions hold (per § Acceptance case).
- [ ] Output has **≥5 substantive thematic blocks**.
- [ ] Each rendered block paragraph cites concrete evidence-source.
- [ ] Empty-evidence blocks omitted (no «красивая пустота»).

### Calibrated regression

- [ ] All 6 calibrated cases (02 / 03 / 05 / 07 / 08-Natalya / 10) render «Итоги консультации» without errors.
- [ ] No client's hardcoded text leaks to another client (no Natalya phrasings in non-Natalya outputs).
- [ ] Themes per case correspond к case facts (not static defaults).
- [ ] Worker shows diff per case в HANDOFF (similar Stage 4 calibrated regression в previous TASK).
- [ ] «Improved factuality» OR «consultation-quality uplift» verdict per case; «lost meaningful content» / «added generic soup» triggers STOP.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes baseline `398/2/0 + N` (N = new tests). **0 failed AND 0 xfailed.**
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (synthesis_themes.py + new test file + optional template tweak).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] External Reviewer pass (per § Ready clarification 7).

### Discipline

- [ ] NO LLM call. Deterministic templates only.
- [ ] NO engine modifications.
- [ ] NO Marina-narrative copying as defaults.
- [ ] NO Olga-only hardcoded text.
- [ ] Each rendered block cites concrete evidence-source.
- [ ] Empty-evidence blocks omitted (no padding).
- [ ] Theme planner uses evidence-weight scoring (NOT static priority list).
- [ ] Calibrated diff documented per case в HANDOFF.

## STOP triggers (per user verbatim 2026-05-19)

Worker MUST stop and escalate if:

- Приходится **вручную писать текст только под Ольгу** → STOP, generator must be generic.
- Хочется добавить **LLM** → STOP, deterministic only.
- Хочется менять **engine** → STOP, use existing facts.
- Результат становится **generic soup** → STOP, fix architecture.
- Тесты проходят, но **текст выглядит как символический список** → STOP, narrative renderer не достигает quality bar.
- Для calibrated cases появляются **очевидно чужие темы** → STOP, theme planner regression.
- Невозможно получить нужные факты из **текущего `facts_json`** → STOP, escalate (NO engine modifications для new fields).

## Reviewer subagent — per § Ready clarification 7

Tier B+ substantive rewrite. Previous similar TASK (`evidence-based-consultation-summary-rewrite`) used Reviewer REQUIRED (clarification 6 = (b)). Same disposition likely для этого TASK.

If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- Architecture follows 3-layer (extraction + planner + renderer) verbatim.
- Theme planner uses evidence-weight scoring (not static).
- Narrative renderer produces consultation-quality prose (verified by reading sample output).
- All STOP triggers honoured.
- No Olga-only hardcoded text.
- Calibrated cases independently spot-checked (≥3 of 6).
- 0 LLM / engine / schema touches.

## Context

**Mode normal + Tier B+ (Reviewer disposition per § Ready).** Worker mode: normal.

**Baseline:**
- Product main @ `a6a3331` (previous TASK closed).
- Overlay master @ `6f3e3fd` (previous TASK closure).
- Pytest baseline: `398 passed + 2 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Predecessor TASK (closed 2026-05-19): `project-overlays/astro/TASKS/archive/2026-05-19-evidence-based-consultation-summary-rewrite.md` + HANDOFF.
- Predecessor commit: product `a6a3331`.
- Existing acceptance tests (preserve / extend): `services/api-python/tests/test_consultation_summary_evidence.py`.
- Olga DB consultations: `/Users/ilya/Projects/astro/data/astro.db` rows id=10/11/12.
- Marina-Olga reference PDF: `/Users/ilya/Downloads/Соляр 2026-2027.pdf`.
- Codex example text (style anchor): source message 2026-05-19.
- Phase 9.0 memo (sub-problem D — summary themes): `project-overlays/astro/ARCHITECTURE/marina-significance-selection-analysis-2026-05-17.md` § 5.4 + errata.
- Phase 9.4 axis tests (preserved unchanged): `services/api-python/tests/test_summary_themes.py`.

**Not in scope (explicit):**
- Engine output modifications.
- New facts fields requests to engine.
- Phase 9.x sub-problem reopening.
- Outer-card filter / window logic changes (Phase 9.2/9.3 closures).
- Calendar-aspect over-include (Phase 9.5A deferred).
- LLM / GPT integration.

**Ready: no** — pending 7 clarifications below.

## Ready clarifications (pending user direction 2026-05-19)

1. **«Общий вывод» bottom section.** Codex example has both top «Выводы» (opener) и bottom «ОБЩИЙ ВЫВОД» (closer). User-provided 11-block structure list has only top «Выводы». Confirm:
   - (a) 11 sections (1 opener + 10 themed) — Codex's bottom «ОБЩИЙ ВЫВОД» rolled into top «Выводы».
   - (b) 12 sections (1 opener + 10 themed + 1 closer «Общий вывод»).

2. **Codex example status.**
   - (a) Canonical: Worker должен reproduce этот exact tone/depth/length для Olga acceptance (strict «sounds like Codex»).
   - (b) Illustrative: shows direction/style; Worker может vary as long as quality is similar и semantic criteria pass.

3. **Theme planner scoring numerics.**
   - (a) Worker proposes numerics (e.g. axis=10, prog_moon=10, directions=8, outer_transits=8, social_transit=4, repeat_boost=+3) с justification в HANDOFF.
   - (b) User pre-sets numerics before Worker starts.

4. **Layer 3 narrative renderer architecture choice.**
   - (a) Per-theme deep templates с conditional phrase composition based on evidence patterns.
   - (b) Phrase-library + composition rules per (evidence-shape, theme).
   - (c) Worker proposes alternative в HANDOFF before implementing.

5. **«После 02.09.2026 переход к инициативности» — dynamic date derivation.**
   - (a) Worker derives this date from engine facts (Mars/Sun ingress, или какой signal?). Specify which.
   - (b) Worker adds heuristic: «activity-shift date» = solar Mars ingress into fire sign within solar year.
   - (c) Worker proposes algorithm в HANDOFF before implementing.

6. **Test file disposition.**
   - (a) Extend existing `test_consultation_summary_evidence.py` (16 tests preserved, new semantic-human tests added).
   - (b) New `test_consultation_summary_human.py` (separate file для human-narrative tests; existing file unchanged).
   - (c) Replace: drop existing 16 tests, write new comprehensive suite.
   - (d) Hybrid: keep strict-negatives from existing file, write new positive-semantic in new file.

7. **Reviewer subagent.**
   - (a) REQUIRED external Reviewer pass (same as previous TASK clarification 6 = (b)).
   - (b) Optional + TL inline-verify (lower discipline than predecessor).
