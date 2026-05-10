# TASK: transits-section-rebuild-to-reference

- Status: done
- Ready: yes
- Date: 2026-05-10
- Project: astro
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: normal

## Problem

Текущий раздел `Транзиты` в клиентском PDF считать **не сделанным**. Структура частично присутствует (`solar.html.j2:491-669` имеет subsections «Транзиты планет по домам», «Транзиты социальных планет», «Транзиты высших планет»), но **не выровнена под Marina reference**. Cм. § Required output shape ниже.

Нужно **не чинить по мелочи, а пересобрать раздел по образцу**.

## Goal

Сделать раздел `Транзиты` в PDF **структурно и визуально близким к Marina reference** (`Соляр 2025-2026_5.pdf`), без самодельной логики подачи.

## Scope

Только раздел `Транзиты`.

Рабочие файлы (предварительный recon):
- `services/api-python/app/pdf/templates/solar.html.j2:491-669` — текущая Транзиты-секция (intro + 3 subsection'а + empty state)
- `services/api-python/app/pdf/builder.py` — Jinja env, фильтры, передача facts
- `services/api-python/app/pdf/transit_themes.py` — closed-dictionary interpretations для transit-by-house. Docstring уже фиксирует Marina structure: «1. Short intro per planet — 2. for each house ... a 30-60 word interpretation». **Outer planets (Uranus/Neptune/Pluto) явно flag'нуты в docstring как «out of scope этого dict'а — Phase 0.9b refinement»** — это первая зона возможного blocker'а.
- Связанные: возможно `synthesis_themes.py` (если transit-aspect narratives живут там), `house_pair_themes.py` (если cross-house themes используются)

## Marina reference structure (page range 7-23, по info Owner'а)

Worker читает **только pages 7-23** в `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` (29 pages total, остальное out of scope для этой TASK):

- **7-8**: intro по транзитам
- **9**: monthly table по домам (главный сруктурный референс для §2 ниже)
- **9-13**: разворот по планетам (per-planet narratives)
- **14-15**: аспекты социальных/высших планет (структурный референс для §5)
- **16-19**: narratives по аспектам (тон/функция)
- **19-22**: календарь транзитных аспектов
- **22-23**: «как пользоваться транзитами» (заключительный how-to блок)

## Required output shape

Эти 6 секций должны идти именно в этом порядке, как в reference:

### 1. Intro
- Короткий вводный блок по транзитам
- Без авторской самодеятельности
- По тону и функции как в образце

### 2. Monthly transit-by-house table (главное structural-критическое место)
Сделать таблицу как в образце (page 9):
- **Строки** = месячные периоды
- **Колонки** = нужные транзитные планеты
- **Ячейка** = дом или дома, в которых планета находится в этот период
- **Если в периоде 2 дома, это явно показать** (cross-month transition)

**Не подменять это**:
- списком дат
- prose-описанием
- свободной таблицей другой формы

### 3. Social planets
Выделить отдельный блок:
- `Юпитер`
- `Сатурн`

**Не смешивать его с высшими.**

### 4. Outer planets
Выделить отдельный блок:
- `Уран`
- `Нептун`
- `Плутон`

**Отдельно от социальных.** Если data-shape/text для outer planets long-transit narratives отсутствует — это **blocker** (см. § If blocked ниже), не маскировать шаблоном.

### 5. Transit aspects
Сделать отдельный блок по аспектам социальных и высших планет:
- **Не прятать его внутрь других секций**
- **Не заменять коротким summary**
- Подача должна быть как в образце, а не «вольно пересказанная»

Если `facts.analysis.transit_aspects` (или эквивалентный data-shape) не emit'ится из engine'а — это **blocker** (Tier A schema gate cascade).

### 6. Дальнейшие пояснения/трактовки
В порядке как в образце (pages 16-23):
- narratives по аспектам
- календарь транзитных аспектов
- «как пользоваться транзитами»

## Hard constraints

- НЕ трогать wheel / glyphs (`wheel.py`, `wheel_glyphs.py`, `build_wheel_glyphs.py`, `assets/`)
- НЕ трогать дирекции (`direction_themes.py`)
- НЕ трогать итоги консультации (synthesis section в template'е, `synthesis_themes.py` в той части что не относится к транзитам)
- НЕ менять другие разделы PDF (Натальная карта, Солярная карта, Прогрессии, любой раздел вне Транзиты)
- НЕ придумывать новые названия секций
- НЕ менять порядок раздела на свой вкус
- НЕ писать «улучшенные» объяснения от себя, если их нет в образце
- НЕ трогать `core/`, `packages/`, `apps/` (pure presentation TASK — services-layer only)

## If blocked (escalation rules)

Если выяснится, что для одного из этих требуется data-shape, которого нет в текущем engine output:

1. **Monthly table 2-house cross-month**: если facts не предоставляют чистый «месяц → планета → [дом1, дом2?]» mapping → blocker
2. **Transit aspects** (§5): если `facts.analysis.transit_aspects` отсутствует → blocker
3. **Outer-planets long-transit narratives** (§4): если для них нет ни data-shape, ни closed-dictionary text → blocker

В случае blocker'а:
- НЕ изобретать presentation-layer workaround
- Явно зафиксировать blocker в HANDOFF
- Указать **какой именно data-shape отсутствует** и **в каком модуле он должен появиться** (например: «нужна field `transit_aspects: list[...]` в `solar-computed-facts.schema.json`, эмитится из `core/astrology-hs/src/Analysis/...`»)
- TL escalates к Owner для решения о переходе на Tier A schema gate

## Acceptance

1. Раздел `Транзиты` в новом PDF структурно похож на образец.
2. Таблица по месяцам выглядит как в образце (rows=месяцы, cols=планеты, cell=дом[а]).
3. Социальные и высшие планеты разделены.
4. Есть отдельный блок транзитных аспектов.
5. В разделе нет самодельной структуры «от себя».
6. `pytest` 70/70 (или больше если новые tests).
7. Real PDF Натальи рендерится без поломок.

## Embedded Reviewer checklist (TL inline review + Worker self-check)

```
- [ ] Секция Транзиты в новом PDF идёт в правильном месте и не ломает остальные разделы
- [ ] Есть вводный блок по транзитам, и он по функции/тону похож на образец
- [ ] Есть monthly table по домам
- [ ] В monthly table строки = месячные периоды, а не точные события
- [ ] В monthly table колонки = нужные планеты, а не произвольный набор
- [ ] Если в периоде планета занимает 2 дома, это явно показано
- [ ] Социальные планеты вынесены в отдельный блок
- [ ] Высшие планеты вынесены в отдельный блок
- [ ] Социальные и высшие планеты не смешаны
- [ ] Есть отдельный блок транзитных аспектов
- [ ] Блок транзитных аспектов не спрятан внутрь другого раздела
- [ ] В разделе нет самодельных новых названий секций
- [ ] В разделе нет debug/info dump
- [ ] Если каких-то данных для точного совпадения не хватает, Worker явно зафиксировал blocker, а не замаскировал его шаблоном
- [ ] Показаны именно страницы Транзиты нового PDF + side-by-side с образцом
```

## Deliverable

После правок Worker предоставляет:
- Новый PDF Натальи: `/tmp/astro-natalya-transits-rebuild.pdf`
- PNG страниц раздела `Транзиты` (тех страниц, на которых раздел рендерится в новом PDF) — `/tmp/transits-rebuild-pN.png`
- Side-by-side composites: новый PDF (Транзиты pages) ↔ образец Marina (pages 7-23) — `/tmp/transits-side-by-side.png` (или несколько композитов если страниц много)
- HANDOFF документ с self-check checklist'ом (15 items выше) marked as PASS/FAIL/N/A с evidence

## Context

- **Mode normal** (Tier B); Worker subagent **mandatory** (separate session, fresh memory). TL inline review per embedded checklist выше; sign-off — Owner via TL relay.
- Baseline: `astro:309468a` (wheel-glyphs-asset-pack-swap closed), pytest 70/70, working tree clean, 0 active TASKs.
- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pages 7-23 (page breakdown в § Marina reference structure выше).
- Standalone render harness: `/tmp/render_natalya_2ffa002.py` (existing — Worker меняет `OUT_PATH` под этот цикл).
- IP guidance для Worker'а: Marina reference используется **структурно** (section order, table format, tone) — НЕ копировать analytical text verbatim. Если closed-dictionary text для outer planets отсутствует — писать в Marina-idiom похожем стиле (как делал автор `transit_themes.py` для inner-house entries) ИЛИ flag'нуть как blocker.

## References

- Marina reference: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf` pp. 7-23
- Current implementation: `services/api-python/app/pdf/templates/solar.html.j2:491-669`
- Closed-dict module: `services/api-python/app/pdf/transit_themes.py` (docstring already documents Marina structure)
- Filter registration: `services/api-python/app/pdf/builder.py:33` (`transit_matrix_by_month`)
- Project CLAUDE.md: `/Users/ilya/Projects/astro/CLAUDE.md`
- Architecture invariants: `/Users/ilya/Projects/astro/.claude/architecture-invariants.md` (bright line #8 для schema cascade — релевантно если blocker'ы)

**Execution isolation**: Worker subagent (separate session, fresh memory) per Mode normal Tier B. Worker submit'ит HANDOFF после full implementation OR blocker escalation. TL inline review per embedded checklist; sign-off — Owner via TL relay, side-by-side с Marina reference pages 7-23.
