# TASK: transit-contact-window-semantics

- Status: open
- Ready: yes
- Date: 2026-05-13
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

После Phase 4 Path 3 (TASK 4 closed, commit `8c9588d`) у нас остались **2 Category 4 Neptune interval xfail tests** в `test_natalya_transits_acceptance.py`, отмеченные reason'ом `"TASK 4a — Neptune slow-loop contact window semantics"`:

- `test_neptune_square_jupiter_three_touches_tolerance_2d` — Neptune-Jupiter window 3 boundary engine 30.01.2028 vs Marina 16.02.2028 (Δ ≈ 17 дней).
- `test_neptune_square_neptune_three_touches_tolerance_2d` — Neptune-Neptune window 1 boundary engine 02.04.2024 vs Marina 27.09.2024 (Δ ≈ 178 дней).

Корень проблемы — несовпадение **семантик** между engine output и Marina-style representation:

- **Engine** эмитит **hit per motion phase** внутри orb-окна. Для медленных планет (Нептун) одно orb-окно может содержать 2 фазы (D+R или R+DR) → raw hit count > unique windows.
- **Engine** считает orb-окно от **первого пересечения 1.0° threshold**. Для Нептун-Нептун это апрель 2024.
- **Marina** показывает **3 «касания»** = **3 display windows** конкретной формы; для Нептун-Нептун первое касание начинается в сентябре 2024, не апреле. Marina видимо игнорирует «drift period» и считает «касание» только последний близкий заход в орб перед началом DirectReturn петли.

Текущее состояние — Phase 4 Worker реализовал aggregation `raw hits → 3 display windows` per allowlist triple (Marina-style display) с tolerance ±1d для Урана-Венеры (быстрый), но для Нептуна расхождение боундари окон остаётся:
- Neptune-Jupiter window 3: ±17d (выходит за ±2d test tolerance).
- Neptune-Neptune window 1: ±178d (катастрофически выходит за ±2d).

Phase 2 test `_assert_three_phase_intervals` написан с предположением «engine эмитит ровно 3 hits» (что выдерживается для быстрых, но не для медленных планет). Это **design gap из Phase 2**.

Задача TASK 4a — **формализовать таксономию transit contact concepts**, проанализировать раcхождения engine vs Marina, и **выдать TL рекомендацию** (Path 1 / Path 2 / Path 3) для окончательного решения. **Эта задача не строит фикс** — она строит SoT по семантике + analysis memo.

После memo TL эскалирует пользователю; пользователь выбирает path; открывается отдельный TASK (Tier C test contract OR Tier A engine) для actual implementation.

## Taxonomy to formalise

Worker формализует следующие 5 концептов как явные definitions в analysis memo:

1. **`raw hit`** — engine emission: одно exact moment + motion phase. Per `Domain.TransitCalendar` сейчас. Hit count > 3 для медленных планет где одно orb-окно содержит 2 фазы.

2. **`motion phase hit`** — синоним raw hit (используется в context раcсуждений о Direct/Retrograde/DirectReturn).

3. **`orb window`** — диапазон `[orb_enter_jd, orb_exit_jd]` где |signed arc| ≤ class orb. Engine эмитит одно orb window per «approach + retreat» (один заход в орб + выход). Для медленных планет одно orb window может содержать несколько exact moments (несколько raw hits).

4. **`display contact`** — Marina-style «касание»: то, что показывается клиенту как один из 3 интервалов в карточке. **Не идентично orb window** для Нептун-Нептун (engine считает window 1 = 6 месяцев; Marina показывает «касание 1» только последние ~2 недели перед DR петли).

5. **`tight Marina window`** — гипотеза: то, что Marina рисует — это не полный orb window от 1° threshold, а более узкий subset (e.g. от 0.5° или от первого после D-DR turnpoint approach). Worker проверяет эту гипотезу на raw engine data Нептун-Нептун: можно ли вывести Marina's 27.09.2024 boundary через какое-то deterministic правило (tight orb threshold, or «start of approach to last exact before DR»).

## Path options (memo recommends one to TL)

**Path 1 — Test contract semantic fix (Tier C low cost):**
- Изменить `_assert_three_phase_intervals` логику: вместо `len(hits) == 3` — `len(unique_windows) == 3` + per-window phase set assertion. Это уже частично сделано Phase 4 aggregation в `outer_cards.py`.
- Tolerance ±2d для boundary остаётся, но only applied within-window для accepted Marina-equivalent windows. Window 1 Neptune-Neptune Δ178d — documented exception или explicit per-aspect tolerance override.
- Pros: cheap; не трогает engine.
- Cons: 178d shift всё ещё расходится — это либо documented exception (engineer says «engine видит начало раньше Marina, это OK») либо потеря строгости test contract.

**Path 2 — Engine semantic adjustment (Tier A cascade):**
- Изменить `Domain.TransitCalendar.findCrossings` чтобы первое orb window начиналось не с первого пересечения wide orb (1°) threshold, а с входа в `tight_orb` threshold (e.g. 0.5°) ИЛИ с первого Direct exact moment.
- **Может решить** 178d / 17d shifts — но это **гипотеза**, не гарантия. Worker memo обязан **доказать deterministic rule** на трёх примерах Натальи (Уран-Венера, Нептун-Юпитер, Нептун-Нептун): какая конкретная formula (tight_orb threshold value? exact-Direct anchored? approach-direction-based?) воспроизводит Marina'ины boundaries в пределах ±2d на всех трёх. Если rule выводится только на 2 из 3 — Path 2 не закрывает root cause, нужен либо другой rule, либо признать что Marina использует non-deterministic editorial judgement.
- **Blast radius assessment обязателен**: Worker анализирует impact новой rule на остальные 8 golden cases (01-05, 07, 09, 10). Какие aspects в каждом case'е сейчас работают на wide-orb logic; что изменится при переходе на tight-orb / Direct-anchored. Не «может сломать что-то» — конкретный list affected aspects per case.
- Pros: правильно по semantic если rule доказан; tests pass без exceptions; consistent с Marina на всех outer cards.
- Cons: Tier A cascade (schema, fixtures × 9 cases regen, roundtrip, contract test); риск регрессии на других cases если deterministic rule не universal; высокая стоимость если в итоге не воспроизводится.

**Path 3 — Accept documented exception (Tier C zero cost):**
- Test contract отражает реальность: engine эмитит wide orb windows, Marina narrow display windows.
- 2 Neptune Cat 4 tests остаются xfail постоянно с reason: `"engine semantic vs Marina narrow display — accepted divergence per TL/user decision, presentation aggregates to 3 windows per card"`.
- Phase 4 PDF rendering уже handles aggregation; user видит 3 cards с engine dates (не Marina dates).
- **Acceptable только если TL/user явно принимает**, что PDF может не совпадать с Marina dates для Neptune boundaries. Эта оценка («критично vs приемлемо» для клиентской интерпретации) — **продуктовое решение TL/user после memo**, не предрешённый вывод Worker'а.
- Pros: zero implementation cost; reality reflected; no regression risk.
- Cons: не закрывается дисциплина «hard acceptance assertions» — Cat 4 xfails становятся «forever xfail», что противоречит идее Phase 2 design; продуктово — Марина увидит расхождение на этих двух boundaries при показе PDF.

**Worker задача** — проанализировать engine code, Marina эталон, raw data; формализовать таксономию; рекомендовать один из трёх path с обоснованием 5-10 предложений.

## Files

- new:
  - **`project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md`** — analysis memo. Структура:
    - § 1 Контекст (откуда пришло — Phase 4 preflight + Path 3 + 2 Cat 4 xfails).
    - § 2 Taxonomy (5 concepts с явными definitions + примеры из engine output Нептун-Нептун и Нептун-Юпитер).
    - § 3 Engine semantic analysis (читает `Domain.TransitCalendar.hs` + `Domain.Transits.hs` — где именно эмитится hit per phase, где orb window определяется).
    - § 4 Marina semantic hypothesis (читает Marina pp. 18, 19, 20, 21 + сверяет с raw engine output для 4 примеров: Уран-Венера clean, Нептун-Юпитер w3 Δ17d, Нептун-Нептун w1 Δ178d, опционально других outer transits если есть в фикстуре).
    - § 5 Path analysis (Path 1 / Path 2 / Path 3, каждый с pros/cons/cost estimate).
    - § 6 Recommendation (один path + обоснование).
    - § 7 If TL accepts Path X — следующий TASK template (что нужно сделать, кто Worker, какое scope).

- modify:
  - **Не модифицировать `transit-section-program-2026-05-13.md`** — analysis memo создаётся как sibling документ, не правит recovery program SoT. После TL accept Path X — recovery program может получить cross-reference на memo.

- delete: —

## Do not touch

- **Haskell core (`core/astrology-hs/**`)** — analysis only, никаких code changes в этой задаче.
- **Python code (services/api-python/**.py)** — analysis only.
- **Tests** — анализ читает но не модифицирует `test_natalya_transits_acceptance.py` или другие.
- **Fixtures** — `expected.json` категорически не правится.
- **Schema, rulesets, TS types** — не трогать.
- **Phase 5/6 xfails** — не трогать.
- **2 Cat 4 Neptune xfails** — НЕ unmark, НЕ menять reason. Phase 4 Worker уже обновил reason на `"TASK 4a — ..."`; TASK 4a memo не правит их статус (это работа отдельного follow-up TASK после user decision по Path).

## Acceptance

### Analysis deliverable

- [ ] `project-overlays/astro/ARCHITECTURE/transit-contact-window-semantics-2026-05-13.md` создан с 7 sections выше.
- [ ] § 2 Taxonomy формализует 5 concepts (`raw hit`, `motion phase hit`, `orb window`, `display contact`, `tight Marina window`) — каждый с определением + минимум 1 пример из engine output Натальи.
- [ ] § 3 Engine semantic analysis — Worker читает `Domain.TransitCalendar.hs` (особенно `findCrossings`, `analyzeAnnualCalendar`) и формализует что именно эмитится. Reference на конкретные lines кода.
- [ ] § 4 Marina semantic hypothesis — для **минимум 3 примеров** (Uranus-Venus, Neptune-Jupiter, Neptune-Neptune) Worker сверяет engine raw output с Marina reference и формулирует гипотезу о Marina's display contact rule.
- [ ] § 5 Path analysis — 3 path с pros/cons + cost estimate (для Path 2 — список файлов schema cascade).
- [ ] § 6 Recommendation — один path с обоснованием минимум 5 предложений.
- [ ] § 7 Next TASK template — если TL accepts Path X, какой Worker / какой scope / какие acceptance assertions.

### Tests + clean state

- [ ] `cd services/api-python && .venv/bin/pytest --tb=no -q` — green; ожидание `113 passed + 10 xfailed` (без изменений — analysis-only TASK).
- [ ] `git status --short` чисто.
- [ ] Один commit. Conventional message. Reference на analysis document.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent — отдельная Agent-сессия.
- [ ] Reviewer subagent необязателен per Tier C; TL inline-reads memo + escalates на user для path decision.
- [ ] HANDOFF содержит:
  - path к memo;
  - 1-paragraph executive summary (для TL's escalation message).
  - top-3 findings которые Worker считает наиболее важными.

## Context

**Mode normal + Tier C** (analysis/spec). Layer: `docs` (documentation deliverable). Worker subagent. Без code changes.

**Baseline:** main @ `8c9588d` (Phase 4 closed). Tests 113 passed + 10 xfailed.

**Architecture SoT программы:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 6 Outer-planet intervals ERRATUM block (написан после Path 3 decision) — context для текущей задачи.

**Recovery program status:** Phase 0-4 closed. Phase 4a (этот TASK) — analysis/spec. Phase 5/6/7 — wait for 4a memo + TL/user decision.

**Worker scope discipline:** analysis-only. **НЕ строить code, НЕ запускать engine fix, НЕ модифицировать tests, НЕ модифицировать fixtures.** Только deliverable — markdown memo + recommendation.

**Marina reference:** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 17-22. Worker внимательно перечитывает + сравнивает с raw engine output из `08-natalya-2025-2026.expected.json`.

**Phase 4 archived HANDOFFs:**
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/HANDOFFS/archive/2026-05-13-worker-to-tl-outer-planet-cards-generator-preflight-blocked.md` — preflight diagnostic с raw engine output для Neptune triples.
- `/Users/ilya/Projects/ai-dev-system/project-overlays/astro/HANDOFFS/archive/2026-05-13-worker-to-tl-outer-planet-cards-generator-phase4-path3.md` — Phase 4 Path 3 closing с aggregation logic.
Worker читает оба как input для analysis.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 4a spec.
