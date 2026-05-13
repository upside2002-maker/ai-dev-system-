# TASK: transit-horizon-split

- Status: done
- Ready: yes
- Date: 2026-05-13
- Project: astro
- Layer: mixed
- Risk tier: C — AUTHORIZED for Path B (presentation-level). Tier A path requires STOP + escalation memo, NOT silent escalation в этой сессии.
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal — at Tier C. Tier A path requires explicit go from user в отдельной задаче.
- Critical approved by: (нет; при Tier-A escalation — открывается отдельный Tier A TASK с новым approval)

## Problem

Phase 3 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 3, § 4 архитектурное решение части 1+2, § 8 TASK 3). Цель — устранить root cause #2 из § 3 документа («`annual_transit_table` перегружен двумя задачами»).

Сейчас один `annual_transit_table` обслуживает одновременно:
- календарь домов текущего солярного года → `houses_visited()` → трактовки по домам;
- широкий scan window для петель высших планет (540 дней до/после соляра, A.3 Tier A cascade);
- источник событий для аспектного календаря;
- источник итогового синтеза.

Эти задачи имеют разные правила отсечения по датам. Смешивание приводит к утечкам 2024/2027/2028 в текущий соляр (например, `Сатурн в 6 доме` из 2024 года в трактовках per-house — defect #1 из § 2 документа).

Задача — **разделить два горизонта данных** на уровне engine или presentation (Worker анализирует и выбирает; см. Two paths ниже). После закрытия эта задача снимает 5 xfail-тестов в `test_natalya_transits_acceptance.py` (Phase 3 mapping).

## Two paths (Worker chooses, justifies in HANDOFF)

### Path A — Engine-level split (Tier-A escalation expected)

Изменения в Haskell `Domain.TransitCalendar`:
- Domain эмитит **два** results вместо одного `annual_transit_table`:
  - `solar_year_transits` — строго clipped к `[sr_jd, sr_jd + 365.25]`;
  - `loop_transit_windows` — full extended horizon.
- Bridge.Solar JSON shape расширяется новыми top-level полями (или новые поля внутри `SolarComputedFacts`).
- Schema cascade (bright-line #8): `solar-computed-facts.schema.json` + Haskell roundtrip + Python contract + TS types + 9 fixture regen + ruleset (если нужно).

**Эскалация в Tier A автоматическая** если этот path выбран. Mode strict. Отдельный Worker + Reviewer subagent. Атомарный commit.

### Path B — Presentation-level split (остаётся Tier C)

Engine продолжает эмитить один `annual_transit_table` с extended horizon. Python presentation derives два view'а:
- `transit_themes.solar_year_transits(annual_transit_table, sr_jd)` — фильтр в Python.
- `transit_themes.loop_transit_windows(annual_transit_table)` — pass-through extended view.

`houses_visited()` и synthesis-helpers переключаются на `solar_year_transits` view. Outer cards (Phase 4) получают `loop_transit_windows`.

Schema без изменений. Tier C, Mode normal. Worker subagent один.

### Worker decision criteria

Worker анализирует и выбирает path, **обосновывая в HANDOFF**:
- complexity / coupling (как часто schema будет меняться при добавлении новых split-related fields);
- maintainability (Haskell core ≈ canonical, Python ≈ flexible derivation);
- test surface (Tier A schema cascade требует обновления fixtures для 9 cases — overhead);
- архитектурный документ § 4 говорит «Ввести явное разделение» — намекает на engine-level, но не предписывает строго.

**Дефолт TL:** Path B (presentation-level), если Worker не находит сильного основания для Path A. Path A нужен если split нужен для downstream системы (TS frontend, API consumers) — а это не наша явная нужда сейчас.

### Path A gating — STOP-and-escalate (не silent escalation)

**Этот TASK авторизует реализацию Path B только.** Если Worker анализом приходит к выводу что Path B недостаточен и нужен Path A:

1. **STOP** — не начинать никаких schema/core cascade изменений внутри этой сессии.
2. Записать в HANDOFF **escalation memo** с явными секциями:
   - **Rationale**: почему Path B недостаточен (конкретные технические аргументы, не «было бы лучше»);
   - **Files**: точный список schema/core/fixture/types файлов, которые должны измениться;
   - **Contracts touched**: какие external API contracts (schema, TS types) меняются;
   - **Reviewer requirement**: какой Reviewer'ский cold-start spec нужен (Tier A + strict mode + independent verification scope);
   - **Cost estimate**: сколько примерно стоит cascade (fixture regen × 9 cases, schema validation, roundtrip tests).
3. Submit HANDOFF с пометкой `BLOCKED — Path A escalation memo`.
4. **TL эскалирует пользователю; ждёт explicit go перед открытием нового Tier A TASK'а** с правильной изоляцией (отдельный Worker subagent + Reviewer subagent в strict mode).

Worker НЕ выбирает Path A молча и НЕ начинает Tier A работу внутри этой Tier C сессии.

## Files

### Path A (engine-level, Tier-A cascade)

- modify:
  - `core/astrology-hs/src/Domain/TransitCalendar.hs` — два output records.
  - `core/astrology-hs/src/Bridge/Solar.hs` — расширить SolarComputedFacts JSON shape.
  - `packages/contracts/solar-computed-facts.schema.json` — schema cascade.
  - `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs` — roundtrip.
  - `services/api-python/tests/test_contracts.py` — Python contract.
  - `apps/web-react/src/types.ts` — TS types.
  - 9 `packages/test-fixtures/golden-cases/*.expected.json` — regen.
  - `services/api-python/app/pdf/transit_themes.py` — переключить `houses_visited()` и synthesis на новые fields.
  - `core/astrology-hs/test/Test/Domain/TransitCalendarSpec.hs` — тесты на split.

### Path B (presentation-level, Tier C) — AUTHORIZED PATH FOR THIS TASK

- modify:
  - `services/api-python/app/pdf/transit_themes.py` — добавить `solar_year_transits()` и `loop_transit_windows()` view-фильтры; переключить `houses_visited()` на solar-year view.
  - **`services/api-python/app/pdf/synthesis_themes.py`** — переключить все references на `annual_transit_table` на `solar_year_transits` view. Stale 2024/2027/2028 даты протекали в итоговый synthesis (раздел `Итоги консультации`) — это не только проблема per-house блока. После Phase 3 final synthesis должен ссылаться **только** на солярный год.
  - `services/api-python/app/pdf/builder.py` (minimal, ≤ 15 строк) — registration Jinja, если view'ы передаются явно; либо single derivation point на верхнем уровне рендера.
  - `services/api-python/app/pdf/templates/solar.html.j2` (minimal) — wiring если нужен (template ссылки на `annual_transit_table` могут потребовать pass'а явного view).
  - `services/api-python/tests/test_transit_aspects_tables.py` — обновить если зависит от старого contract.

### Both paths

- new: возможно `services/api-python/tests/test_horizon_split.py` (Path B) или Haskell spec (Path A) — Worker выбирает.

## Do not touch

- **`expected.json` fixtures без cabal rebuild** — если Path A: fixture regen ОБЯЗАТЕЛЬНО предшествовать `cabal build`. Worker заявляет в HANDOFF SHA cabal binary использованного при regen.
- **Math engine values** — splitting не должен менять значения транзитов, только их распределение между двумя views.
- **Quincunx scope** — Correction 009 lock-in. Не расширять/сужать.
- **Sample window N (540 days)** — стабильно. Не менять.
- **PDF templates / outer card structure** — Phase 4 работа, не Phase 3.
- **TASK 2 hard acceptance assertions** — НЕ unmark xfail-теги в этой задаче. Только Phase 3 acceptance assertions (5 штук из § 8 TASK 2 Phase 3 mapping) могут флипнуться. Если другие xfail неожиданно xpass'нули — это сигнал, исследовать.
- **Worktree** `.claude/worktrees/dreamy-moore-46f5eb` — orphaned, не трогать.

## Acceptance

### Path decision

- [ ] Worker в HANDOFF фиксирует выбранный path (A или B) с обоснованием минимум 3-5 sentences. Если Path A — explicit Tier-A escalation note + Mode strict обоснование.

### Common acceptance (любой path — но в этом TASK'е только Path B авторизован)

- [ ] `houses_visited()` или его replacement принимает явный `horizon` parameter / автоматически использует solar-year-only view.
- [ ] Per-house трактовки в PDF Натальи показывают Сатурн только в домах `[7, 8]`. Никаких `Сатурн в 6 доме`.
- [ ] Per-house section в PDF не содержит дат `2024`, `2027`, `2028`.
- [ ] **Final synthesis блок (раздел `Итоги консультации`) использует только solar-year view.** Никаких ссылок на даты вне солярного года (2024 / 2027 / 2028) в итоговых выводах. Worker подтверждает в HANDOFF проверкой extracted PDF text по synthesis section.
- [ ] Outer cards / календарь (когда Phase 4-6 закрыты) получают доступ к full-loop horizon, не теряют касания за границей соляра.

### Test contract (Phase 2 xfail flips)

- [ ] После landing TASK 3 запуск `pytest tests/test_natalya_transits_acceptance.py -v` показывает:
  - Phase 3 mapping (5 xfail tests) переходит в **passed**:
    - `test_saturn_solar_year_houses_only_seven_and_eight`
    - `test_pdf_text_does_not_contain_saturn_six_house`
    - `test_houses_visited_accepts_explicit_horizon`
    - `test_no_saturn_six_house_regression` (regression ban)
    - (+ возможно ещё один из category 2 если xpass'нет)
  - Worker обязан **unmark xfail** для passing tests (per § 8 TASK 2 xfail-strict rationale). Иначе strict-flip отвалит CI.
  - Phase 4/5/6 xfail-теги **остаются xfail** (соответствующие работы ещё не закрыты).

### Tests + clean state

- [ ] `cabal build` перед running pytest (если Path A). Worker фиксирует SHA cabal binary использованного.
- [ ] Если Path A: `cabal test` — 242+ green.
- [ ] `cd services/api-python && .venv/bin/pytest` — все 102+ green (Phase 3 flips увеличивают passed count).
- [ ] `git status --short` чисто **для intended product changes**. Pre-existing `.claude/worktrees/` разрешён.
- [ ] Path A: один atomic commit per bright-line #8. Path B: один commit (≤ 2 при чистой границе).
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent отдельная Agent-сессия.
- [ ] **Если Path A:** Reviewer subagent **обязателен** (Tier A + strict mode требование). Cold-start, разная сессия от Worker.
- [ ] **Если Path B:** Reviewer subagent необязателен, TL inline-verify.
- [ ] HANDOFF содержит path decision rationale + xfail flip status (which tests flipped from xfail to passed).

## Context

**Mode normal + Tier C** на default Path B. **Tier A + Mode strict** на Path A (Worker определяет в первой фазе работы и эскалирует, если выбрал A).

**Baseline:** main @ `fb47aca` (Phase 2 closed). Tests 102 passed + 21 xfailed. После Phase 3 ожидается 107+ passed + 16- xfailed (Phase 3 flips).

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- § 4 архитектурное решение 1+2 (engine-level split predicted).
- § 5 Phase 3.
- § 7 запрет 6 («Не открывать Worker subagents на задачи Phase 3-7, пока Phase 1 и Phase 2 не закрыты») — теперь снят, Phase 1 + Phase 2 закрыты.
- § 8 TASK 3 — formal spec.

**Cabal build hygiene (lesson из Phase 2 verification):** Phase 2 Worker обнаружил 9 «pre-existing» test_golden_cases.py failures на baseline — оказалось stale cabal cache. После `cabal build` все 9 проходят. Worker Phase 3 **обязан** запускать `cabal build` перед pytest при работе с engine (Path A), даже если кажется что core не меняли. STATUS_RU отражает этот lesson.

**xfail flip discipline:** Phase 3 Worker при closing своего commit должен:
1. Запустить `pytest tests/test_natalya_transits_acceptance.py -v` post-fix.
2. Идентифицировать tests которые из xfailed перешли в xpassed (strict mode флипнет CI).
3. **В том же commit** убрать `@pytest.mark.xfail` decorator с этих tests (per § 8 TASK 2).
4. Если test ожидаемо xpass'ит но не — investigate, не unmark наугад.

**Phase 4-7 на ожидании:** TL открывает TASK 4 только после accept Phase 3.

**Ready: no** — TL flip'ает в `yes` после ack пользователя на TASK 3 spec.
