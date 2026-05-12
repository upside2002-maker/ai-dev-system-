# TASK: transit-presentation-rebuild-marina-format

- Status: done
- Ready: yes
- Date: 2026-05-12
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

После acceptance Tier A engine cascade (`2e4c394`) пользователь визуально сравнил свежий PDF Натальи с Marina reference (`/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`) и зафиксировал **presentation REJECT** по разделу `Транзиты`. Engine считает правильно, но в PDF теперь печатается **сырой расчётный материал**, а не клиентский формат Марины. Раздел стал визуально дальше от эталона, чем был до iter-1 / Tier A работы.

Математика остаётся как есть. Quincunx (150°), петли, cross-year scan, расчёт касаний и периодов — **не пересчитывать, не трогать**. Работа только в Python presentation слое.

## Owner's verbatim corrective directive

> `Транзиты` — **presentation REJECT**.
>
> Математику **не трогать**:
> - квинконс оставить;
> - петли оставить;
> - cross-year scan оставить;
> - расчёт касаний и периодов не пересчитывать.
>
> Проблема не в engine, а в том, что **раздел `Транзиты` в PDF оформлен не как у Марины**.
>
> ## Что исправить
>
> ### 1. Убрать raw engine dump из PDF
> Убрать текущие большие таблицы:
> - `Транзиты высших планет`
> - `Транзиты социальных планет`
>
> в их нынешнем виде на нескольких страницах.
>
> Это backend-данные, а не клиентская подача.
>
> ### 2. Убрать блок `Какие транзиты особенно важны`
> Из вступления к `Транзитам` убрать секцию:
> - `Какие транзиты особенно важны для этой натальной карты`
>
> Она уводит раздел от формата образца.
>
> ### 3. Месячная таблица по домам
> Оставить monthly table, но привести к виду образца:
> - в ячейках **простые номера домов**;
> - без стрелок `1 → 2`, `11 → 12 → 1` и т.п.;
> - визуально и структурно как у Марины.
>
> ### 4. Вернуть формат раздела к образцу
> Нужна подача как у Марины:
>
> 1. короткий вводный блок;
> 2. monthly table по домам;
> 3. трактовки по домам;
> 4. объяснение аспектов / видов аспектов;
> 5. `Золотое правило транзита`;
> 6. **месячный календарь транзитных аспектов** короткими строками по месяцам.
>
> ### 5. Календарь аспектов
> Именно сюда должен идти результат нового движка.
>
> Не raw-таблицы по всем аспектам, а:
> - **отфильтрованный месячный календарь**;
> - короткие строки по релевантным месяцам;
> - в формате, близком к Marina reference;
> - engine используется как backend-источник, но не печатается напрямую.
>
> ## Важно
> - не менять математику;
> - не лезть в Haskell core;
> - не трогать другие разделы PDF;
> - не придумывать новую структуру;
> - цель: **вернуть визуальную и редакторскую форму Марины, сохранив новую математику под капотом**.

## Files

- modify (Python presentation only):
  - `services/api-python/app/pdf/templates/solar.html.j2` — структурная переработка раздела «Транзиты»:
    - убрать блок «Какие транзиты особенно важны для этой натальной карты» (или эквивалентное название) из вступления раздела;
    - убрать таблицы «Транзиты высших планет» и «Транзиты социальных планет» в их iter-1 виде (большие per-row таблицы с периодами 2024-2028);
    - месячная таблица по домам — упростить ячейки до simple номера дома без стрелок-разделителей;
    - вернуть структуру 1-6 как в Owner directive (intro → monthly table → трактовки по домам → объяснение аспектов → золотое правило → месячный календарь короткими строками).
  - `services/api-python/app/pdf/transit_themes.py` — пересмотреть helpers:
    - `transit_matrix_by_month` — ячейки simple номера домов вместо `"7 → 8"` (если планета пересекает дом мид-месяц, выбрать «доминирующий» дом — тот в котором планета провела больше времени за месяц — или иной Marina-style fallback; посмотреть Marina эталон pp. 7-8);
    - `transit_aspects_table` (outer / social) — либо удалить целиком (раз не используется), либо оставить как dead-code helper с пометкой `# unused: see transit_aspects_by_month` (Worker решает по cleanliness);
    - `transit_aspects_by_month` — сделать **основным** источником календаря; отфильтровать short-window/drift-only-без-overlap записи, чтобы не печатать engine super-set; короткие строки в Marina-формате «{Planet_ru} {aspect_deg}° {target_ru} ({label}) — DD.MM.YYYY–DD.MM.YYYY → Дома цели: {N — name; ...}.»;
    - убедиться что Quincunx (150°) в `transit_aspects_by_month` фильтруется как и остальные major aspects (math остаётся, presentation должна показывать его в формате Marina).
  - `services/api-python/app/pdf/builder.py` — registration Jinja-globals: если убираем `transit_aspects_outer`/`transit_aspects_social` — снять регистрацию; если `transit_matrix_by_month` поменял contract — обновить wiring; minimal patch ≤ 30 строк.

- modify (tests):
  - `services/api-python/tests/test_transit_aspects_tables.py` — обновить под новый helper contract. Если helper'ы удаляются — соответствующие test_*.py удалить либо упростить до smoke на новых helper'ах.
  - Другие test файлы — обновлять только если их contract зависел от удаляемого helper'а.

- new: —
- delete: возможно один-два теста на `transit_aspects_table` outer/social если helper'ы удаляются.

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — out of scope. Tier C presentation, не engine.
- **`packages/contracts/*.schema.json`** — math contract стабилен.
- **`packages/test-fixtures/golden-cases/*.expected.json`** и `*.input.json` — НЕ регенерировать. Engine-output стабилен.
- **`packages/rulesets/daragan-orbs-v1.json`** — не менять.
- **Другие разделы PDF**: Натальная карта, Солярная карта, Прогрессии, Дирекции, Итоги консультации — НЕ трогать.
- **Wheel рендеринг**: `wheel.py`, `wheel_glyphs.py` — out of scope.
- **Synthesis themes** (`synthesis_themes.py`), Direction themes (`direction_themes.py`), House pair themes (`house_pair_themes.py`) — out of scope.
- **Ephemeris bridge** (`ephemeris/bridge.py`) — out of scope (sample window 540d сохранён).
- **TypeScript types** (`apps/web-react/src/types.ts`) — не трогать (schema стабильна).
- **Принятый TASK** `2026-05-11-transit-engine-orb-window-quincunx-cross-year.md` (в archive/) — не править.
- **Параллельный open iter-1 TASK** `2026-05-11-transits-aspects-tables-outer-social.md` — этот TASK его эффективно supersede'ит для outer/social раздела. Worker НЕ обязан formal-rejection iter-1; TL handles lifecycle отдельно после accept этого TASK.

## Acceptance

### Visual parity с Marina reference (PRIMARY)

- [ ] Worker открывает Marina reference `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` страницы 7-22 (раздел Транзиты).
- [ ] Worker генерит свежий PDF Натальи на TUNE-2 commit (`2e4c394`) + новые presentation правки. Save: `/tmp/astro-natalya-presentation-rebuild-iter1.pdf`.
- [ ] Сверка по 6-секционной структуре в Owner directive:
  1. Короткий вводный блок — присутствует, без `Какие транзиты особенно важны`.
  2. Monthly table по домам — simple номера, без стрелок.
  3. Трактовки по домам — присутствуют (уже существуют, проверить что осталась).
  4. Объяснение аспектов — присутствует (`ASPECT_DEFINITIONS` остаётся).
  5. `Золотое правило транзита` — присутствует (если был в iter-3, остаётся; если не был — Worker решает добавить short блок per Marina или оставить как есть).
  6. Месячный календарь аспектов — короткие строки по месяцам в Marina формате; raw outer/social tables убраны.
- [ ] Никаких 2024 / 2027 / 2028 годов в клиентских строках кроме случаев когда они **реально активны** в солярном году Натальи (loop'ы которые легитимно пересекают границу — но без excessive «engine dump» 2024-2028 simultaneously).

### Concrete file changes

- [ ] `solar.html.j2` — раздел «Транзиты» не содержит `Какие транзиты особенно важны`.
- [ ] `solar.html.j2` — нет subsection'ов «Транзиты высших планет» / «Транзиты социальных планет» в iter-1 виде (large per-row tables).
- [ ] `transit_themes.transit_matrix_by_month` возвращает `int` (не `"7 → 8"` string) для cells, либо аналогичный Marina-style fallback.
- [ ] `transit_themes.transit_aspects_by_month` — главный источник календаря; orb-window поля engine используются для коротких строк по месяцам.

### Tests

- [ ] `cd services/api-python && .venv/bin/pytest` — все тесты зелёные. Если убран helper — соответствующие test_*.py обновлены.
- [ ] Smoke render: реальный PDF Натальи рендерится без exceptions; страницы транзитного раздела визуально совпадают со структурой Marina.

### Scope discipline

- [ ] `git show --stat` финального commit'а — затронуты ТОЛЬКО `services/api-python/app/pdf/templates/solar.html.j2`, `transit_themes.py`, `builder.py`, и tests. Никаких core/, contracts/, rulesets/, fixtures/.
- [ ] Math engine (Haskell core) — 0 lines changed.
- [ ] Другие разделы PDF (натал/соляр/прогрессии/дирекции/итоги/wheel) — 0 lines changed.

### Visual evidence для TL

- [ ] Worker сохраняет new PDF в `/tmp/astro-natalya-presentation-rebuild-iter1.pdf`.
- [ ] Worker в HANDOFF указывает (а) путь к новому PDF, (б) краткий per-section diff vs Marina (что совпадает по структуре, что осталось visually-not-1-to-1 — для TL'я в next iteration если нужно).

## Context

**Mode normal + Tier C** (presentation visual rebuild). Worker subagent **рекомендуется** для качества (cold-start fresh perspective), но не строго mandatory per Tier C матрице. TL может inline-патчить если уверен в visual match, но для visual user-facing parity предпочтительнее отдельная Worker сессия.

**Baseline:** `2e4c394` (TUNE-2 финальный), worktree `claude/dreamy-moore-46f5eb`. Math engine стабилен, pytest 82/82 зелёный, cabal 242/242 зелёный.

**Marina reference:** `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`.
- Раздел Транзиты — pp. 7-22 (intro + monthly + house-interpretations + aspects taxonomy + golden rule + monthly calendar).
- Особо смотреть **pp. 7-8** (monthly table by domains — Marina-style simple cells) и **pp. 20-22** (monthly aspect calendar — Marina-style short rows).

**Iter-1 что приходит на замену:** iter-1 (`7b8fd24`) добавил большие raw таблицы по outer/social планетам. Owner-directive в момент написания iter-1 был «Добавь отдельные табличные блоки», но после Tier A cascade engine стал эмитить много данных, и iter-1 формат превратился в engine-dump визуально. Этот TASK переписывает iter-1 presentation решение, сохраняя engine math как baseline.

**Связанные TASK'и (для контекста, не править):**
- `2026-05-11-transit-engine-orb-window-quincunx-cross-year` (Tier A, ACCEPTED, в archive/) — engine cascade. Math остаётся.
- Открытый `2026-05-11-transits-aspects-tables-outer-social` (Tier B, iter-1) — supersede'ится этим TASK'ом; TL handles lifecycle (likely reject + move to archive) после accept этого TASK.

**Worktree:** Worker работает в `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`. Один commit на ветке `claude/dreamy-moore-46f5eb` (presentation patch). Push backup после commit.

**Operator language**: HANDOFF и commit messages на внутреннем языке (Worker → TL). С пользователем общается только TL, и только на простом русском (см. CLAUDE_GLOBAL.md § «Главный закон общения с пользователем» + corrections/global-corrections.md Correction 013).
