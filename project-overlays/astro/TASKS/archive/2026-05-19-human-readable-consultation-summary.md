# TASK: human-readable-consultation-summary

- Status: done
- Ready: yes
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

Full text recorded in source message 2026-05-19.

**Codex example status (per user clarification 2): STYLE ANCHOR, NOT EXACT TARGET.** Не копировать дословно. Worker MUST держать уровень: живой язык, смысловые переходы, практический вывод, минимум голой символики. Semantic acceptance criteria cover content; Codex text shows tone/depth bar.

Style features (from Codex example, used as anchor):
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

Weighting (user-provided directional; **Worker proposes concrete numerics с justification в HANDOFF per user clarification 3**):

- солярная ось / доминирующая ось: **высокий вес**.
- прогрессивная Луна: **высокий вес**.
- дирекции: **высокий вес**.
- транзиты высших планет: **высокий вес**.
- Юпитер / Сатурн по домам: **средний вес**.
- повтор темы в нескольких методах: **boost**.

User direction 2026-05-19 verbatim: «Важно не само число, а чтобы было видно: почему тема попала в итог, какие сигналы её усилили.» Worker HANDOFF must include per-theme score breakdown (which signals fired + their contributions) для Olga + 2-3 calibrated cases.

«Если тема не подтверждена фактами, не надо писать про неё длинный абзац "для красоты"». Empty-block guard preserved from previous TASK.

### Layer 3 — Human narrative renderer

Output = **текст консультации**, не list символов.

❌ Bad format: «Солярный 1 дом попадает в 5 дом. Ось 5-11. Дирекция 1+5. Транзит Урана к Венере.»

✅ Good format: «В этом году личная тема раскрывается через детей, творчество, хобби, удовольствие и право на собственное желание. Это не год ухода в себя, а год включённости: важно проявляться, пробовать новое, общаться, создавать и не обесценивать то, что действительно радует.»

**Architecture choice for layer 3 (per user clarification 4 — Worker proposes architecture с hard guard):**

Worker выбирает между:
- (a) Per-theme deep templates с conditional phrase composition based on evidence patterns.
- (b) Phrase-library + composition rules per (evidence-shape, theme).
- (c) Hybrid (a) + (b) или Worker-proposed alternative.

**Hard guard (per user verbatim clarification 4): «не generic soup».** Worker MUST доказать на Olga + 2-3 calibrated cases, что текст **case-specific**, не generic-applicable-to-anyone. Side-by-side рендеринг в HANDOFF (Olga ЛИЧНОСТЬ vs Maxim ЛИЧНОСТЬ vs Natalya ЛИЧНОСТЬ): blocks должны явно различаться по содержанию (not just by inserted dates/numbers).

## Required output structure

Section structure (per user clarification 1 — **12 sections required**):

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
12. **Общий вывод** (closing synthesis paragraph — gathers text into consultation, не leaves набор разделов; per user verbatim 2026-05-19: «Финальный абзац важен: он собирает текст в консультацию»).

Each section evidence-driven: weak themes brief or omitted; strong themes deeper.

## Acceptance case: Ольга consultation 11/12

Олga summary должен передавать (semantic acceptance, per user verbatim 2026-05-19):

- Год **НЕ про одиночество**, **НЕ про "1-12"**.
- Главная тема: люди / планы / дети / творчество / хобби / будущее / коллектив.
- ЛИЧНОСТЬ раскрывается через 5 дом: дети, радость, самовыражение, творчество.
- Asc Libra → партнёрство, договорённости, баланс.
- MC Cancer → цель связана с домом, семьёй, опорой, недвижимостью.
- Прогрессивная Луна 11 дом → планы, друзья, группы, будущее.
- Mars ingress / shift after **02.09.2026** → больше инициативы и лидерства. **Date MUST be dynamically derived per user clarification 5** — Worker сначала investigates which engine fact yields this date (вероятнее всего progressed Moon sign-change / house-state transition или Mars ingress). **If source unclear → STOP and report; DO NOT hardcode Olga's 02.09.2026 date.** Worker HANDOFF documents derivation algorithm.
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

## Additional guard — «Human-read» smoke test (per user direction 2026-05-19, verbatim)

> «Итоговый текст должен проходить "human read" smoke: если убрать астрологические термины, абзац всё равно должен оставаться понятным советом человеку. Если абзац держится только на формулах домов/аспектов — это FAIL.»

**Operationalisation:**
- Take any rendered paragraph from «Итоги консультации».
- Mentally strip astrological terms: «солярный», «натальный», «дом», «градусы», «аспект», «оппозиция / тригон / квадрат / секстиль», planet names (Солнце / Луна / Меркурий / Венера / Марс / Юпитер / Сатурн / Уран / Нептун / Плутон), sign names (Овен / Телец / ...), formula tokens («1+5», «10+1»), «ось 5-11», «прогрессивная Луна» as label.
- **Remaining text must still be understandable as life advice к конкретному человеку.**
- If остаток reads as «mumble formulas mumble dates» с no human content → FAIL.

**Examples:**

✅ PASS: «В этом году личная тема раскрывается через детей, творчество, хобби, удовольствие и право на собственное желание. Это не год ухода в себя, а год включённости: важно проявляться, пробовать новое, общаться, создавать и не обесценивать то, что действительно радует.» (Strip astrology terms → still meaningful советы человеку.)

❌ FAIL: «Тематически это личность, самопредъявление, начало нового цикла; дети, творчество, любовь, хобби, самовыражение; статус, карьера, публичная роль, цель (дома 1-5-10); сетка соляра: сол. 1 → нат. 5, сол. 2 → нат. 5, сол. 5 → нат. 9, сол. 6 → нат. 10, сол. 10 → нат. 1; engine отмечает главная ось 5-11 (подсчёт 4).» (Strip astrology terms → unintelligible fragments. Current predecessor output. This is the bar we are RAISING.)

This guard applied across:
- Style requirements (output prose must pass smoke).
- Acceptance (test verifies smoke for Olga + 2-3 calibrated).
- STOP triggers (paragraph fails smoke → STOP architecture).
- Reviewer criteria (manual smoke spot-check ≥3 cases).

## Files

- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` — substantive 3-layer architecture rewrite on top of existing evidence-collection helpers.
  - `services/api-python/tests/test_consultation_summary_evidence.py` — **EXTEND existing file per user clarification 6** (16 strict-negative + positive tests preserved as foundation; new semantic-human tests added в same file).
  - `project-overlays/astro/STATUS_RU.md`.
  - `services/api-python/app/templates/solar.html.j2` — ONLY if current template cannot render new output structure (verify first, modify minimally).

- new: —

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
- [ ] External Reviewer pass REQUIRED (per user clarification 7).
- [ ] **Human-read smoke test passes для Olga + 2-3 calibrated** — paragraph stripped of astrological terms remains понятным советом человеку.

### Discipline

- [ ] NO LLM call. Deterministic templates only.
- [ ] NO engine modifications.
- [ ] NO Marina-narrative copying as defaults.
- [ ] NO Olga-only hardcoded text.
- [ ] Each rendered block cites concrete evidence-source.
- [ ] Empty-evidence blocks omitted (no padding).
- [ ] Theme planner uses evidence-weight scoring (NOT static priority list).
- [ ] Calibrated diff documented per case в HANDOFF.

## STOP triggers (per user verbatim 2026-05-19 + clarifications 2026-05-19)

Worker MUST stop and escalate if:

- Приходится **вручную писать текст только под Ольгу** → STOP, generator must be generic.
- Хочется добавить **LLM** → STOP, deterministic only.
- Хочется менять **engine** → STOP, use existing facts.
- Результат становится **generic soup** → STOP, fix architecture.
- Тесты проходят, но **текст выглядит как символический список** → STOP, narrative renderer не достигает quality bar.
- Для calibrated cases появляются **очевидно чужие темы** → STOP, theme planner regression.
- Невозможно получить нужные факты из **текущего `facts_json`** → STOP, escalate (NO engine modifications для new fields).
- **«После 02.09.2026» date derivation source неочевиден** → STOP, доклад через HANDOFF, NOT hardcode Olga's date (per clarification 5).
- **Paragraph fails «human-read» smoke** (held only by formulas/houses/aspects, no advice meaning remaining when astrology terms stripped) → STOP, fix architecture (per additional guard 2026-05-19).
- Side-by-side case comparison shows blocks **generic-applicable-to-anyone** (only differ by dates/numbers, not content) → STOP (per clarification 4 hard guard).

## Reviewer subagent — REQUIRED (per user clarification 7)

Tier B+ substantive rewrite. User direction 2026-05-19 verbatim: «Это уже не "подправить фразу", а качество консультационного синтеза. Нужен внешний pass.»

External Reviewer pass REQUIRED after Worker self-submit. If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 5th+ occurrence), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- Architecture follows 3-layer (extraction + planner + renderer) verbatim.
- Theme planner uses evidence-weight scoring (not static); HANDOFF includes per-theme score breakdown.
- Narrative renderer produces consultation-quality prose (verified by reading sample output Olga + 2-3 calibrated).
- **Side-by-side case comparison shows text is case-specific, not generic-applicable-to-anyone** (hard guard per clarification 4).
- **Human-read smoke test passes:** убрать астрологические термины из абзаца — оставшийся текст должен быть понятным советом человеку. Если абзац держится только на формулах домов/аспектов → FAIL.
- All STOP triggers honoured.
- No Olga-only hardcoded text.
- Calibrated cases independently spot-checked (≥3 of 6).
- 0 LLM / engine / schema touches.

## Context

**Mode normal + Tier B+ (Reviewer REQUIRED per user clarification 7).** Worker mode: normal.

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

**Ready: yes** — 7 clarifications applied 2026-05-19 + additional «human-read smoke» guard:

1. **12 sections required.** Opener `Выводы` + 10 themed blocks + closer `Общий вывод`. Финальный абзац важен — собирает текст в консультацию. Applied output structure section.

2. **Codex example = style anchor, NOT exact target.** Не копировать дословно; держать level: живой язык, смысловые переходы, практический вывод, минимум голой символики. Applied Codex example section + style requirements.

3. **Theme planner scoring numerics — Worker proposes с justification в HANDOFF.** Не само число важно; важно чтобы было видно почему тема попала в итог и какие сигналы её усилили. Per-theme score breakdown в HANDOFF для Olga + 2-3 calibrated. Applied Layer 2 section.

4. **Narrative renderer architecture — Worker proposes** (per-theme templates / phrase-library / hybrid). **Hard guard: not generic soup.** Worker должен доказать на Olga + 2-3 calibrated, что текст case-specific (not generic-applicable-to-anyone). Side-by-side рендеринг блоков в HANDOFF. Applied Layer 3 section.

5. **«После 02.09.2026» dynamic derivation.** Worker investigates which engine fact yields the date (вероятнее всего progressed Moon sign-change / house-state transition или Mars ingress). **Если source неочевиден → STOP and report**; NOT hardcode Olga's date. Worker HANDOFF documents derivation algorithm. Applied Acceptance + STOP trigger.

6. **Extend existing `test_consultation_summary_evidence.py`.** 16 existing tests preserved as foundation; new semantic-human tests добавлены в same file. NO new test file. Applied Files section.

7. **Reviewer REQUIRED.** External Reviewer pass after Worker submit. User verbatim: «Это уже не "подправить фразу", а качество консультационного синтеза. Нужен внешний pass.» If Agent tool unavailable в Worker runtime, TL spawns external Reviewer post-submission. Applied Reviewer section + Acceptance.

**Additional guard (per user direction 2026-05-19, verbatim):**

> «Итоговый текст должен проходить "human read" smoke: если убрать астрологические термины, абзац всё равно должен оставаться понятным советом человеку. Если абзац держится только на формулах домов/аспектов — это FAIL.»

Applied across Style requirements + Acceptance + STOP triggers + Reviewer criteria. Operationalised в dedicated «Additional guard» section с PASS/FAIL examples.
