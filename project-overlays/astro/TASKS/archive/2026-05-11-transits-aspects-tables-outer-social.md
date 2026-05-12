# TASK: transits-aspects-tables-outer-social

- Status: rejected
- Ready: yes
- Date: 2026-05-11
- Project: astro
- Layer: services (likely) / possibly core if Tier A escalation
- Risk tier: B (with possible Tier A escalation per blocker rules below)
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: normal
- Superseded by: 2026-05-12-transit-presentation-rebuild-marina-format (accepted)

> **Rejection note (TL 2026-05-12):** Iter-1 решение (commit `7b8fd24` —
> добавил большие raw-таблицы «Транзиты высших/социальных планет» как
> отдельные subsections) после Tier A engine cascade выглядело визуально
> как engine dump, не как клиентский PDF Марины. User REJECT на presentation
> 2026-05-12. Iter-1 helpers (`transit_aspects_table` / `transit_aspects_outer`
> / `transit_aspects_social`) физически удалены в presentation rebuild
> (`9f47f45`). Календарь аспектов Marina-style теперь идёт через
> `transit_aspects_by_month` коротких строк по месяцам — это и есть
> правильное место для аспектного календаря. Iter-1 формат — отвергнут.

## Problem

В разделе `Транзиты` (HEAD `df6351a`) сейчас есть intro + monthly transit-by-house table + flat per-house interpretations + aspect calendar (spread-across-months) + how-to. Owner directive: добавить **2 отдельных табличных блока** для аспектов высших и социальных планет к натальной карте, с учётом ретроградных петель и периодов, выходящих за границу солярного года.

## Owner's verbatim directive

> Добавь в раздел `Транзиты` отдельные табличные блоки:
>
> 1. **Транзиты высших планет**
> - Уран
> - Нептун
> - Плутон
>
> 2. **Транзиты социальных планет**
> - Сатурн
> - Юпитер
>
> Что считать:
> - мажорные аспекты к натальной карте;
> - не только в пределах солярного года, но и с учётом **петель**;
> - если аспект идёт в петле, показывать все касания и весь период действия, даже если он выходит за рамки солярного года.
>
> Орбисы:
> - Юпитер / Сатурн: `2–3°`
> - Уран / Нептун / Плутон: `1–1.5°`
>
> Output:
> - не prose;
> - не трактовки по домам;
> - а **таблица**:
>   - планета
>   - аспект
>   - натальная точка
>   - период
>   - касания / повторные проходы
>   - признак петли
>
> Важно:
> - не смешивать это с monthly table по домам;
> - не обрезать петлю по границе солярного года;
> - не писать summary "от себя".
>
> Порядок в PDF:
> 1. высшие планеты
> 2. социальные планеты

## Data shape investigation (mandatory for Worker before implementing)

Текущий `annual_transit_table` в schema (`packages/contracts/solar-computed-facts.schema.json`) описан как «Phase 0.2 будет populate'ить, Phase 0.1 emit'ит empty array». В Натальи fixture (`08-natalya-2025-2026.expected.json`) сейчас **empty**.

Но iter-1/2/3 transits-rebuild каким-то образом рендерили реальные данные → значит расчёт может идти **runtime'ом** через `transit_themes.py` или эквивалентный модуль. Worker должен:

1. Найти откуда `transit_matrix_by_month()` и `transit_aspects_by_month()` берут реальные данные на runtime
2. Определить покрывает ли существующий data flow:
   - Major aspects ✓?
   - Per-planet-class orbs (J/S = 2-3°, U/N/P = 1-1.5°) ✓?
   - Retrograde loops (3 touches per aspect with retrograde station within orb) ✓?
   - **Period extension beyond solar year boundary** для loops ✓?
   - Loop flag (boolean indicating whether this aspect cycles in a loop) ✓?

## Blocker escalation rules

Если хотя бы один из требований выше **не покрыт** существующим data flow:

**Это blocker. STOP, write blocker HANDOFF, не маскировать template'ом.**

Конкретные сценарии blocker'а:

- **Orbs hard-coded global**: если engine использует один global orb для всех аспектов, не per-planet-class → schema + engine change needed → **Tier A escalation**
- **Loops are not detected**: если transit window list does not differentiate single-pass from loop-3-touch → engine logic change → **Tier A escalation**
- **Window truncated at solar year**: если data window strictly `[solar_return_jd, solar_return_jd + 365.25]` без extension для loops crossing boundary → engine change → **Tier A escalation**
- **No `loop_flag` / `touches` exposed**: если data emit'ит только aggregated hits без structure для loop classification → schema gate cascade → **Tier A escalation**

В blocker HANDOFF указать:
- Какой именно data shape отсутствует (e.g., «нужен field `transit_aspects_extended: list[{planet, aspect, target, period_start_jd, period_end_jd, touches: list[jd], is_loop: bool, orb_class: enum}]`»)
- Какой модуль должен его emit'ить (e.g., `core/astrology-hs/src/Analysis/TransitAspects.hs` + schema update + Aeson roundtrip)
- TL escalates Owner для решения о переходе на Tier A schema gate cascade

## Acceptance (если Tier B path возможен — data все есть runtime'ом)

1. В разделе `Транзиты` после flat per-house interpretations (и до или вместо existing aspect calendar — Worker decides per scope discipline) появляются **2 новые табличные блока**:
   - Первый: «Транзиты высших планет» (Уран / Нептун / Плутон)
   - Второй: «Транзиты социальных планет» (Сатурн / Юпитер)
2. Каждая таблица имеет 6 колонок:
   - **Планета** (transiting)
   - **Аспект** (conjunction / sextile / square / trine / opposition — major only)
   - **Натальная точка** (natal Sun / Moon / Mercury / ... / Asc / MC — кого аспектирует)
   - **Период** (date range, локальное время; для loop'а — full enter_to_exit window)
   - **Касания / повторные проходы** (количество exact-aspect моментов с датами; обычно 1 для direct, 3 для loop)
   - **Признак петли** (boolean: «да» / пусто или «петля»/«-»)
3. Орбисы применяются per planet class:
   - Юпитер / Сатурн: 2–3° (Worker decides exact within range — possibly 2.5° если single value нужен)
   - Уран / Нептун / Плутон: 1–1.5°
4. Loops не обрезаются по границе солярного года — full period даже если выходит за пределы.
5. `pytest` 70/70 (или больше если новые tests добавляются для data flow).
6. Real PDF Натальи рендерится без поломок.

## Hard constraints

- НЕ смешивать с monthly transit-by-house table (она остаётся как есть, выше в разделе)
- НЕ обрезать loop'ы по границе солярного года
- НЕ писать prose summary «от себя» — table only, no narrative
- НЕ переписывать flat per-house interpretations (уже accepted в iter-3)
- НЕ трогать другие разделы PDF (Натальная карта, Солярная карта, Прогрессии, итоги)
- НЕ трогать wheel/glyphs/Saturn (accepted ранее)
- НЕ трогать `core/`, `packages/`, `apps/` если Tier B path (только presentation). Если требуется engine work → blocker → Tier A separate task

## Scope (если Tier B path)

Worker рабочие файлы:
- `services/api-python/app/pdf/transit_themes.py` — likely место для нового helper'а `transit_aspects_by_class()` или эквивалент (table-shaped output)
- `services/api-python/app/pdf/templates/solar.html.j2` — добавить 2 новых subsection'а с tables в Транзиты разделе
- `services/api-python/app/pdf/builder.py` — register new helper as Jinja global

Existing `transit_aspects_by_month()` (iter-1) был ориентирован на month-grouped calendar list. Новый helper нужен с другой aggregation: **per-aspect-row group** (1 row = 1 transit-aspect, с её period + touches + loop flag).

## Placement decision

Existing iter-1/2/3 calendar блок «Календарь транзитных аспектов по месяцам» (spread-across-months listing) функционально пересекается с тем что Owner просит. Worker должен решить:

- **Option A**: ADD новые tables BEFORE existing calendar (calendar остаётся как secondary view) — может быть избыточно
- **Option B**: REPLACE existing calendar новыми tables — Owner directive «Добавь» предлагает ADD, но если calendar показывает то же самое в худшем формате, REPLACE может быть правильно
- **Option C**: REWORK calendar чтобы он стал одной из новых tables — гибрид

Worker рекомендует один из этих в HANDOFF + executes. Дефолт — **Option B** (REPLACE existing calendar новыми aggregated tables), потому что Owner directive «не смешивать», «таблица», и явное structure dictates dual-mode (calendar + tables) был бы redundant.

## Acceptance (если Tier A escalation)

В случае blocker:
1. Worker НЕ implements ничего
2. Worker submits blocker HANDOFF с (a) data shape requirements (b) module locations (c) recommended schema cascade plan
3. TL разворачивает в Tier A TASK после Owner verdict
4. Текущая TASK переходит в Status: blocked

## Tests

1. `cd services/api-python && .venv/bin/pytest` → 70/70 (или больше)
2. Real PDF render:
   - `OUT_PATH = Path("/tmp/astro-natalya-aspects-tables.pdf")` в render harness
   - Run via `.venv/bin/python`
3. Render Транзиты pages to PNG via `pdftoppm`. Inspect via Read tool.
4. Verify:
   - Outer planets table appears FIRST (before social), per Owner directive
   - Both tables have all 6 columns
   - At least one row shows loop=true with 3 touches (Натальи это типичный случай для slow transits)
   - At least one period extends beyond solar year boundary for loops
   - No prose summary, no house-interpretation text mixed in
5. `git status --short` BEFORE commit

## Context

- **Mode normal** (Tier B initial classification); Worker subagent **mandatory**. Tier A escalation per blocker rules
- Baseline: `astro:df6351a` (transits-section-rebuild closed), pytest 70/70, working tree clean, 0 active TASKs
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 14-22 (transit aspects section — structural reference for table format)
- IP guidance: Marina reference for structural use only. Table data and Russian column labels designed по Owner directive, not transcribed.

## References

- TASK file: this
- Current Транзиты state: `services/api-python/app/pdf/templates/solar.html.j2` (post-iter-3)
- Existing helpers: `services/api-python/app/pdf/transit_themes.py` (transit_matrix_by_month, transit_aspects_by_month, ASPECT_DEFINITIONS, HOWTO_PARAGRAPHS)
- Schema: `packages/contracts/solar-computed-facts.schema.json` (annual_transit_table currently Phase 0.1 placeholder)

**Execution isolation**: Worker subagent (separate session, fresh memory) per Mode normal Tier B. Worker submit'ит full implementation HANDOFF OR blocker HANDOFF. TL inline review per acceptance + visual artifact check.
