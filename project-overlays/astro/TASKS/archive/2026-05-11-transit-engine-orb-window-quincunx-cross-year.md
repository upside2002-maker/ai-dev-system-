# TASK: transit-engine-orb-window-quincunx-cross-year

- Status: done
- Ready: yes
- Date: 2026-05-11
- Project: astro
- Layer: mixed
- Risk tier: A
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: strict

## Problem

Marina-side feedback по свежему PDF Натальи (HEAD `7b8fd24`, iter-1 outer/social aspect tables): из 6 строк-расхождений против reference (`/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`) **5 имеют zero engine hits в `annual_transit_table`**. Это не презентационная проблема — это расчётная. Корневой движок `Domain.TransitCalendar.analyzeAnnualCalendar` не эмитит данные, которые reference Марины ожидает увидеть.

Три сцепленных причины, каждая со своим фиксом, все три обязательны в одном atomic-cascade:

**A.1 — Quincunx revoke (scope = transits only).** `calendarAspects` в `TransitCalendar.hs` явно исключает Quincunx (150°) с пометкой «Phase 0.4 lock-in: directions-only». Marina reference содержит квинконсы среди транзитных аспектов внешних/социальных планет. Revoke применяется **только** к транзитному движку. Natal/solar aspect engine (`Domain.Aspects`), синтез (`synthesis_themes.py`), прогрессии и cross-aspects дирекций — Quincunx по-прежнему запрещён.

**A.2 — Orb-window scanner (вместо exact-only zero-crossing).** Текущий `findCrossings` ловит только точные zero-crossings `signedArc`. Аспекты внешних планет, которые подходят в орб (например, до 1.25°) и остаются там полгода, но никогда не достигают exact, движок не видит — выдаёт zero hits. Marina reference показывает такие аспекты как «активные» с указанием периода в орбисе. Engine должен эмитить и точные касания (когда есть), и период действия в орбисе (`orb_enter_jd` / `orb_exit_jd`).

**A.3 — Cross-year scan expansion.** Сейчас Python (`services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month`) обрезает результат по окну `[solar_return_jd, +365.25d]`. Семплы из Python-bridge (`bridge.py`) генерируются на ту же длину. Ретроградные петли медленных планет (особенно Pluto / Neptune ~5 месяцев между D и DR-касаниями) часто пересекают границу солярного года; engine их обрезает. Marina reference показывает полный период петли независимо от границы. Sample-window и фильтрация должны быть расширены, чтобы захватывать loops, начинающиеся до или заканчивающиеся после солярного периода.

Цель — численно точное совпадение с reference Марины по 4 осям: (1) наличие строк, (2) число касаний, (3) даты касаний, (4) период транзита. «Похоже» не принимается.

## Files

- modify (Haskell core — A.1 + A.2):
  - `core/astrology-hs/src/Domain/TransitCalendar.hs` — `calendarAspects` добавить Quincunx; `shiftedTargets` добавить ветку Quincunx → `[target+150, target-150]`; ввести orb-window enrichment (по аспекту + per-planet-class orb): для каждой триплеты `(transiting_planet, target, aspect)` где |angle-nominal| ≤ orb_class в ходе sample-window — эмитить orb-window-границы (`orb_enter_jd`, `orb_exit_jd`); zero-crossing-emission точных касаний сохранить как есть для случаев, где они есть.
  - `core/astrology-hs/src/Domain/Aspects.hs` — `maxOrbFor` для Quincunx сейчас возвращает 0, что корректно для natal/solar engine; **не менять** (separation of concerns). Per-planet-class orb для транзитов конфигурируется отдельно в `TransitCalendar.hs` / ruleset, не через общий `OrbConfig`.

- modify (Haskell core — A.3, sample-window):
  - `core/astrology-hs/src/Bridge/Solar.hs` — проверить (а) поддерживает ли `SolarResolvedInput.sriTransitSamples` window шире солярного года; (б) если sample-stream идёт ровно `[sr_jd, sr_jd+365.25]` — добавить поле или принять wider window без структурных изменений (`transit_samples` — list of (jd, lon, speed), engine читает min/max). Документировать новое ожидание Bridge: «sample-window MAY extend before/after solar year».

- modify (Python services — A.3 sample-window + A.2 wiring):
  - `services/api-python/app/ephemeris/bridge.py` — расширить sample-window. Дельта (`N`) определяется per slowest planet × per max retrograde excursion. Worker подбирает конкретное `N` (рекомендация: ≥ 150 дней — покрывает Pluto retro ~5 мес).
  - `services/api-python/app/pdf/transit_themes.py` — (а) `transit_aspects_table.major` добавить `"Quincunx"`; (б) `transit_aspects_by_month` снять `in_window` обрезку для loops (или применять её только когда aspect НЕ loop); (в) `transit_aspects_table` использовать orb-window поля из engine для `period_start_jd`/`period_end_jd` (если они эмитятся), fallback на min/max(exact_jds) для аспектов без orb-window данных.

- modify (schema — bright-line #8 cascade):
  - `packages/contracts/solar-computed-facts.schema.json` — (а) обновить description `AspectType`: убрать утверждение «Quincunx (150°) is emitted ONLY by the directions analysis»; (б) расширить `TransitContact` definition новыми optional полями `orb_enter_jd: number`, `orb_exit_jd: number` если orb-window выбран как enrichment (worker подтверждает выбор в HANDOFF).
  - `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs` — расширить fixture или добавить тест что Quincunx + orb-window поля roundtripают.
  - `services/api-python/tests/test_contracts.py` — обновить contract test под новые optional поля + Quincunx-allowed в transit context.
  - `apps/web-react/src/types.ts` — добавить optional `orb_enter_jd?: number; orb_exit_jd?: number` в TS-тип TransitContact (или эквивалентный hit type).

- modify (tests — Haskell):
  - `core/astrology-hs/test/Test/Domain/TransitCalendarSpec.hs` — добавить:
    - Quincunx detection test (synthetic sample-stream проходит через `natal+150°`, ожидать hit с `aspect: Quincunx`)
    - Orb-window emission test (synthetic stream входит в орб, никогда не exact, выходит — ожидать одну запись с orb_enter_jd < orb_exit_jd и без exact_jd ИЛИ с exact_jd-в-середине-окна — worker выбирает семантику и фиксирует в тесте)
    - Cross-year boundary test (loop с D-касанием за солярный год, R и DR внутри — ожидать все 3 касания эмитятся)

- modify (ruleset):
  - `packages/rulesets/daragan-orbs-v1.json` — добавить новый блок `transit_per_planet_class` с орбисами `{Sun:1.0, Moon:1.0, Mercury:1.0, Venus:1.0, Mars:1.0, Jupiter:2.5, Saturn:2.5, Uranus:1.25, Neptune:1.25, Pluto:1.25}`. Существующий `prognostic` block оставить как есть (используется natal/solar engine с прежним смыслом).

- modify (fixtures — обязательный regenerate):
  - `packages/test-fixtures/golden-cases/01-kseniya-2024-2025.expected.json`
  - `packages/test-fixtures/golden-cases/02-maksim-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/03-artem-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/04-valeriya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/05-ekaterina-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/07-mariya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json` (oracle case)
  - `packages/test-fixtures/golden-cases/09-anastasiya-2025-2026.expected.json`
  - `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`
  - `packages/test-fixtures/solar-facts-sample.json` (если затрагивается shape `TransitContact`)

  Worker регенерирует через rebuilt CLI: `cabal build`, затем feed `*.input.json` → CLI → сохранить как `*.expected.json`. **Cabal build РАЗРЕШЁН** для этого TASK (Tier A core change требует rebuild).

- modify (project corrections):
  - `astro/.claude/corrections.md` — добавить новую `Correction 009: Quincunx scoped revoke — допустим в Domain.TransitCalendar, запрещён в natal/solar aspect engine и синтезе`. Body: BAD / GOOD / WHY с указанием конкретных модулей где допустим, где нет. Это фиксация scope revoke'а явно, чтобы будущие сессии не ослабили lock-in за пределами транзитов.

- new: —
- delete: —

**1 atomic commit** в продуктовом repo (либо ≤3 если есть чистая граница, но 1 строго предпочтительнее). Все перечисленные правки одним коммитом — иначе bright-line #8 violation.

## Do not touch

- Haskell core, не перечисленный в Files:
  - `Domain.{Directions, PriorityWindows, SolarReportSkeleton, Stellium, KingOfAspects, HouseAxisAnalysis, Progressions, SolarReturn, Houses, Types, Zodiac, Planets, Ascendant, StrengthAnalysis, WeaknessAnalysis, ImportantTransitPlanets, Dignities}` — out of scope. Особо: `ImportantTransitPlanets.hs` это **selection** rule (какие планеты считать важными), а этот TASK фиксирует **detection** engine (какие касания эмитить). Не путать.
  - `Domain.Aspects` — `OrbConfig` менять нельзя; quincunx по-прежнему возвращает 0 орб для natal/solar engine.
  - `Domain.Transits` (модуль для Asc-only zero-crossing scanning) — out of scope, не путать с `TransitCalendar`.
- PDF presentation, не перечисленный в Files: `wheel.py`, `wheel_glyphs.py`, `synthesis_themes.py`, `direction_themes.py`, `house_pair_themes.py`, `solar.html.j2` (template structure), `builder.py` (кроме регистрации новых Jinja-helpers если нужно — minimal patch ≤10 строк). Никаких visual/layout правок.
- Python services не перечисленные: `main.py`, `db.py`, `persons.py`, `consultations.py`, `draft.py`, `core_client.py`, `models.py`, `migrations/**`, `ephemeris/cache.py`.
- Frontend `apps/web-react/**` кроме `src/types.ts`.
- Lilith / NorthNode / SouthNode / Chiron / FixedStars — отдельный Tier A TASK (`solar-nodes-lilith-retro-display`), не трогать.
- `astro/.claude/architecture-invariants.md` — invariants не меняются; они уже допускают Quincunx через `AspectType` enum.
- `CLAUDE.md`, `docs/`, `infra/`, `data/`, overlay (`project-overlays/**`) — out of scope.
- Глобальные corrections (`/Users/ilya/Projects/ai-dev-system/corrections/global-corrections.md`) — out of scope.
- Quincunx lock-in в других контекстах (`synthesis_themes.py`, `Directions.hs` cross-aspects, прогрессии) — ОСТАЁТСЯ. Этот TASK НЕ глобальный revoke, а scoped (только транзитный движок).

## Acceptance

### Behavioural invariants (objective, automated)

- [ ] `cabal build` зелёный после правок core. **cabal build РАЗРЕШЁН** (Tier A core change требует rebuild).
- [ ] `cabal test` зелёный, включая обновлённый `Test.Domain.TransitCalendarSpec` (3 новых теста: Quincunx detection, orb-window emission, cross-year boundary).
- [ ] `pytest 70/70` (или больше при добавлении новых) после regen всех 9 fixtures.
- [ ] `git show --stat HEAD` (один commit) показывает все правки cascade:
  - `core/astrology-hs/src/Domain/TransitCalendar.hs`
  - `core/astrology-hs/src/Bridge/Solar.hs` (если затронут)
  - `services/api-python/app/ephemeris/bridge.py`
  - `services/api-python/app/pdf/transit_themes.py`
  - `packages/contracts/solar-computed-facts.schema.json`
  - `core/astrology-hs/test/Test/Bridge/SolarRoundtripSpec.hs`
  - `services/api-python/tests/test_contracts.py`
  - `apps/web-react/src/types.ts`
  - `core/astrology-hs/test/Test/Domain/TransitCalendarSpec.hs`
  - `packages/rulesets/daragan-orbs-v1.json`
  - 9 golden case `*.expected.json` файлов
  - `astro/.claude/corrections.md`
- [ ] `git log --oneline 7b8fd24..HEAD` = 1 commit (atomic cascade). При ≤3 commits — Worker в HANDOFF обосновывает чистую границу разбиения; default = 1.
- [ ] Backup parity: `git ls-remote backup main` соответствует local HEAD после push.

### A.1 — Quincunx revoke (transits only)

- [ ] `Domain.TransitCalendar.calendarAspects` содержит `Quincunx` среди списка.
- [ ] `Domain.TransitCalendar.shiftedTargets` имеет ветку для `Quincunx` (или fallthrough через `nominalAngle` если унифицирован) — эмитит `[target+150, target-150]`.
- [ ] `Domain.Aspects.maxOrbFor Quincunx = 0` НЕ изменилось (natal/solar engine по-прежнему не эмитит).
- [ ] `transit_themes.transit_aspects_table.major` set содержит `"Quincunx"`.
- [ ] `astro/.claude/corrections.md` содержит новую `Correction 009` явно фиксирующую scope revoke'а.

### A.2 — Orb-window scanner

- [ ] `Domain.TransitCalendar` эмитит orb-window-границы (`orb_enter_jd`, `orb_exit_jd`) для каждой триплеты `(transiting_planet, target, aspect)` где angle входит в орб за время sample-window, **даже если exact не достигается**.
- [ ] Per-planet-class orb прочитан из ruleset (`packages/rulesets/daragan-orbs-v1.json:transit_per_planet_class`), не hard-coded в коде.
- [ ] Exact-touches (`exact_jd`) продолжают эмититься когда они есть (loop_pass numbering сохранён).
- [ ] Schema description обновлён: `TransitContact` поддерживает оба сценария (exact-touch + orb-window).
- [ ] Тест `TransitCalendarSpec` подтверждает: synthetic stream входит в орб без exact-touch → эмитится запись с orb_enter_jd < orb_exit_jd.

### A.3 — Cross-year scan expansion

- [ ] `services/api-python/app/ephemeris/bridge.py` генерит sample-stream с буфером ≥ 150 дней до и после `[sr_jd, sr_jd+365.25]`.
- [ ] `services/api-python/app/pdf/transit_themes.py:transit_aspects_by_month` не обрезает loops по границе солярного года (или обрезает только если aspect НЕ is_loop).
- [ ] Тест `TransitCalendarSpec` подтверждает: synthetic loop с D-касанием за пределами «солярного года» и R/DR внутри — все 3 касания эмитятся в output engine.
- [ ] Натальная фикстура `08-natalya-2025-2026.expected.json` после регена содержит хотя бы одну запись с `period_end_jd > solar_return_jd + 365.25` (peer-evidence что cross-year работает в реальных данных).

### Oracle (Натальин соляр 2025-2026)

- [ ] Worker открывает Marina reference `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`, извлекает таблицы транзитных аспектов высших + социальных планет (страницы транзитного блока).
- [ ] Worker пробегает по reference построчно (planet × target × aspect × period × touches × loop flag) и сверяет с output `transit_aspects_table(annual_transit_table, planet_class='outer')` + `..., planet_class='social'` после регена `08-natalya-2025-2026.expected.json`.
- [ ] Сверка по 4 осям:
  1. **Наличие строк** — каждая строка из Marina reference присутствует в output (or worker явно объясняет отсутствие в HANDOFF; для acceptance — должно совпадать).
  2. **Число касаний** — для каждой совпадающей строки `len(touches)` совпадает с reference (1 для direct-only, 2 для D+R, 3 для D+R+DR loop).
  3. **Даты касаний** — каждая дата касания совпадает с reference в пределах ± 1 день (eph/timezone-level точность).
  4. **Период транзита** — `period_start_jd` и `period_end_jd` совпадают с reference в пределах ± 1 день.
- [ ] Worker фиксирует в HANDOFF row-by-row diff: для каждой строки reference — match / mismatch + причина mismatch'а если есть.

### Other 8 cases (sanity, не oracle)

- [ ] Для каждого из case 1, 2, 3, 4, 5, 7, 9, 10: после regen каждая новая запись в `annual_transit_table` (Quincunx + orb-window + cross-year) объяснима — Reviewer пробегает и подтверждает что engine не эмитит мусор.
- [ ] Если запись не объяснима ни одним из A.1/A.2/A.3 механизмов — automatic REJECT.

### Process invariants

- [ ] Worker применил Correction 008 — `git status --short` checked перед commit.
- [ ] **Mode strict**: отдельный Worker subagent + отдельный Reviewer subagent (cold-start, разные Agent-spawn'ы).
- [ ] Worker subagent сам создаёт + заполняет HANDOFF + вызывает `make submit-task`.
- [ ] Reviewer subagent сам создаёт + заполняет Reviewer HANDOFF + verdict (ACCEPT / REJECT / TUNE).
- [ ] TL accepts ТОЛЬКО при Reviewer verdict = ACCEPT.

### Reviewer checklist (operational, embedded для cold-start subagent)

```
## Independent re-verification
- [ ] cabal build + cabal test зелёные
- [ ] pytest 70+ зелёный после regen
- [ ] git diff schema: AspectType enum по-прежнему 6 values; TransitContact расширен optional orb_enter_jd/orb_exit_jd
- [ ] git diff: соответствие schema ↔ Haskell TransitContact ↔ TS types
- [ ] Roundtrip test (Test.Bridge.SolarRoundtripSpec) обновлён и зелёный

## A.1 — Quincunx scope
- [ ] calendarAspects содержит Quincunx (transit engine)
- [ ] maxOrbFor Quincunx = 0 в Domain.Aspects (natal/solar engine не затронут)
- [ ] transit_themes.major содержит "Quincunx"
- [ ] synthesis_themes.py, Domain.Aspects, Domain.Directions cross-aspects — НЕ затронуты
- [ ] Correction 009 в astro/.claude/corrections.md явно ограничивает scope транзитным движком

## A.2 — Orb-window
- [ ] Engine эмитит orb_enter_jd / orb_exit_jd для (planet,target,aspect) где |angle-nominal| ≤ orb_class
- [ ] Per-class orbs читаются из daragan-orbs-v1.json:transit_per_planet_class
- [ ] Synthetic test «вход в орб без exact-touch» проходит

## A.3 — Cross-year
- [ ] bridge.py sample-window расширен ≥ 150 дней до и после
- [ ] transit_themes.transit_aspects_by_month не обрезает loops
- [ ] 08-natalya fixture содержит хотя бы один period_end_jd > sr_jd + 365.25
- [ ] Synthetic loop test «D за пределами, R+DR внутри» — все 3 касания эмитятся

## Oracle (Наталья — Marina reference)
- [ ] Reviewer INDEPENDENTLY открывает Marina reference PDF
- [ ] Reviewer INDEPENDENTLY генерит PDF Натальи на новом коммите
- [ ] Reviewer INDEPENDENTLY сравнивает построчно по 4 осям
- [ ] Reviewer фиксирует в своём HANDOFF row-by-row diff (НЕ копирует Worker'ов отчёт)
- [ ] Все Marina-reference строки матчатся в output по 4 осям. Любая mismatch → REJECT.

## Scope discipline
- [ ] git show --stat: затронуты только expected files; ничего лишнего
- [ ] solar.html.j2 структура, wheel*.py, synthesis_themes.py — НЕ затронуты
- [ ] Directions / Progressions / Aspects (OrbConfig) — НЕ затронуты
- [ ] Lilith / Nodes / Chiron / FixedStars — НЕ добавлены

## Process
- [ ] 1 atomic commit (или ≤3 с обоснованием границ)
- [ ] Backup parity verified
- [ ] Worker применил Correction 008
```

## Context

**Mode strict + Tier A** (User decision 2026-05-11): полный путь по трём пунктам. `policies/MODES.md` § strict требует отдельный Worker subagent + отдельный Reviewer subagent (cold-start, разные Agent-spawn'ы). Same-session inline ЗАПРЕЩЁН.

**Worker subagent** = separate Agent tool call, fresh memory, owns full lifecycle:
1. Read TASK + WORKER role definition + project CLAUDE.md + .claude/architecture-invariants.md + .claude/corrections.md
2. Read Marina reference PDF (`/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`) — извлечь оракул-таблицы транзитных аспектов
3. Execute через `cabal build` (РАЗРЕШЁН) → fixture regen × 9 → schema cascade → 1 atomic commit → push backup → `make new-handoff` → заполнить тело → `make submit-task` → краткий summary

**Reviewer subagent** = separate Agent tool call после Worker submit, fresh memory:
- Дано: путь к Worker HANDOFF + Reviewer checklist (embedded выше)
- Owns own HANDOFF + verdict
- INDEPENDENTLY re-verifies oracle: открывает Marina PDF, генерит свежий PDF Натальи, сравнивает построчно
- **Mandatory.** Не accept'ить Worker без Reviewer.

**Oracle ground truth:** Marina reference PDF `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` — единственный источник 4-осевого acceptance. Worker и Reviewer оба читают её НЕЗАВИСИМО. Если читают разные страницы / разные интерпретации — это red flag, TL арбитрирует.

**Orb values:** worker подтверждает конкретные значения per planet class при чтении reference Марины. Default (если reference допускает диапазон): J/S = 2.5°, U/N/P = 1.25° (середина owner-directive диапазонов 2-3° и 1-1.5°). Sun/Moon/Mercury/Venus/Mars не входят в outer/social фильтр иначе чем как target.

**Cross-year buffer N:** worker подтверждает конкретное значение. Default: 150 дней (≥ Pluto retro-loop max excursion). Может потребоваться расширение до 180 если reference показывает loops с большей дистанцией.

**Bright-line #8 cascade obligatory.** Schema `solar-computed-facts.schema.json` затронут (description AspectType + новые optional поля TransitContact). One atomic commit обязателен: schema + Haskell ADT/code + Haskell roundtrip test + Python contract test + TS types + Haskell unit tests + 9 fixture regen + ruleset + corrections.

**Не выходить за scope:**
- Не делать partial fix (A.1 без A.2, или A.2 без A.3). Полный путь.
- Не трогать Quincunx lock-in вне транзитного движка. Scope revoke явный.
- Не запускать смежные backlog-задачи (`solar-nodes-lilith-retro-display`, `consultation-summary-matrix-rewrite`, `section-order-recon`).
- Не «улучшать» презентацию по дороге — отдельный Tier C TASK после accept этого engine fix'а.

**Baseline**: `astro:7b8fd24` (после `transits-aspects-tables-outer-social` iter-1, на ветке `claude/dreamy-moore-46f5eb` через worktree `.claude/worktrees/dreamy-moore-46f5eb`), pytest 70/70, branch clean. Backup parity ✓ (на момент TASK creation).

**Worktree context:** Worker работает в worktree path `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`. Commit landing на ветке `claude/dreamy-moore-46f5eb`; интеграция в `main` — после accept этого TASK через отдельный merge step (или прямой push если ветка trivially-fast-forwards; решение TL после verdict).

**References:**
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` (Натальин соляр 2025-2026, p. 14+ для transit aspects блока).
- Previous Tier A precedent: `2026-05-08-important-transit-planets-rule-fix.md` (важные планеты — selection rule; aналогичный cascade pattern).
- Open iter-1 TASK: `2026-05-11-transits-aspects-tables-outer-social.md` (presentation layer for new tables — этот engine fix добавит данные, которые iter-1 templates уже умеют рендерить).
- Schema cascade pattern: `target-architecture.md § 8.3` + `architecture-invariants.md` bright line #8.
- Quincunx history: `astro/.claude/corrections.md` Correction 005 (где явно сказано «Quincunx добавлен в Domain.Directions Phase 0.4 как scoped-only aspect, не в общий aspect engine») — этот TASK расширяет scope ИМЕННО на transit calendar, ничего другого.

**Ready: no** — Worker НЕ стартует без явного TL flip Ready → yes (после User approval). После TL go: TL flip'ает `Ready: yes` single-field edit, spawn'ит Worker subagent через Agent tool с self-contained cold-start prompt (включает 3 фикса + oracle Marina PDF + Reviewer checklist для self-verification).
