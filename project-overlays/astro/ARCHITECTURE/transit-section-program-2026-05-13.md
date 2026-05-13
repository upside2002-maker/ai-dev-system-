# Transit Section Recovery Program

Дата: 2026-05-13

Статус: fixed (после ack пользователя 2026-05-13 + TL refinements по 10 пунктам)

Владелец решения: пользователь (как Owner) + Project Tech Lead (executor)

Основные артефакты сверки:

- Эталон Марины: `/Users/ilya/Downloads/Gmail (3)/Соляр 2025-2026_5.pdf`
- Последний проверенный вывод программы: `/tmp/astro-natalya-monthstart-iter1.pdf`
- Основной репозиторий: `/Users/ilya/Projects/astro`
- Worktree, из которого был собран проблемный PDF: `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`
- Базовая фикстура Натальи в main: `packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json`
- Регрессивная фикстура/рабочий вывод в worktree: `.claude/worktrees/dreamy-moore-46f5eb/packages/test-fixtures/golden-cases/08-natalya-2025-2026.expected.json`

## 1. Текущий статус и gate

Раздел `Транзиты` в пользовательском PDF не готов к показу Марине. Прежний accept по Tier C (presentation rebuild + quincunx filter + monthly mid-month, 2026-05-12) был преждевременным: были проверены календарь, monthly table и верхняя структура секций, но не была выполнена постраничная сверка всего раздела с эталоном.

На 2026-05-13 программа работ по транзитам открыта заново. До закрытия hard acceptance ниже запрещено считать PDF production-ready, показывать его Марине или перезаписывать golden expected-файлы новым выводом программы.

Ключевой gate: сначала фиксируется единый источник правды и provenance рендера, затем добавляются жесткие acceptance assertions по Наталье. Только после этого можно открывать задачи на перестройку engine/presentation.

## 2. Подтвержденные дефекты раздела "Транзиты"

1. В трактовках по домам появился `Сатурн в 6 доме`, хотя в эталоне по текущему соляру Сатурн затрагивает только 7 и 8 дома.

   Main fixture содержит для Сатурна дома `[7, 8]`. Worktree fixture содержит `[6, 7, 8]`, потому что в нее попали расширенные транзитные интервалы за пределами солярного года. Конкретно `Сатурн в 6 доме` пришел из периода 2024 года, не из соляра 2025-2026.

2. В PDF отсутствует полноценная структура блока высших планет из эталона.

   В эталоне есть отдельные outer-planet cards:

   - `тр Уран в квадрате c нат Венерой`
   - `тр Нептун в квадрате c нат Юпитером`
   - `тр Нептун в квадрате c нат Нептуном`

   Каждая карточка содержит интервалы реализации, таблицу `Золотое правило транзита`, психологический уровень и событийный уровень. Последний вывод программы заменяет это общим правилом и календарем, поэтому важный слой информации отсутствует.

3. `Дома цели` в календаре считаются как placement-only.

   Сейчас календарь берет только дом натальной планеты-цели. Эталонная логика требует house set: положение планеты в доме радикса плюс дома, которыми планета управляет. Например, для Нептуна/Юпитера должны появляться темы 4 и 7 домов, а не только 4 дом.

4. Не разделены горизонты данных.

   Engine должен уметь смотреть шире солярного года, чтобы ловить полные петли высших планет. Но presentation не имеет права использовать этот широкий горизонт для monthly table, трактовок по домам и итоговых выводов солярного года. Сейчас фильтрация частичная, поэтому даты и дома вне соляра протекают в клиентский раздел.

5. Есть конфликт артефактов и источников.

   Проблемный PDF был собран из `.claude/worktrees/dreamy-moore-46f5eb`, тогда как основной repo содержит другую версию шаблона и другую golden fixture. Без render provenance нельзя надежно понять, какой код и какие facts породили конкретный PDF.

## 3. Root causes

1. Нет единого source of truth для рендера PDF.

   Рендеры могут запускаться из main, из worktree или из временного harness script. PDF не несет достаточной информации о git SHA, root path, fixture path, recompute/render mode и версии facts. Это создает drift: исправление может быть сделано в одном дереве, а проверяется PDF из другого.

2. `annual_transit_table` перегружен двумя задачами.

   Один и тот же список используется как:

   - календарь домов текущего солярного года;
   - широкий scan window для петель высших планет;
   - источник событий для аспектного календаря;
   - источник трактовок по домам;
   - источник итогового синтеза.

   Эти задачи имеют разные правила отсечения по датам. Смешивание приводит к утечкам 2024/2027/2028 в текущий соляр.

3. Presentation пишет текст напрямую из низкоуровневых фактов.

   `houses_visited()` и тематический synthesis читают entries из `annual_transit_table` без явного контекста: "solar-year only" или "full-loop horizon". Поэтому корректное расширение engine ломает пользовательский текст.

4. Логика домов-целей не использует rulerships.

   В directions уже есть подход "placement плюс дома управления". В transit calendar/presentation эта логика не переиспользована, поэтому календарь теряет часть домов и расходится с таблицами Марины.

5. Текущие тесты не являются acceptance contract против эталона Марины.

   Часть тестов проверяет форму данных или соответствие текущему `expected.json`. Если `expected.json` перезаписан регрессивными facts, тесты могут остаться зелеными. Нужны независимые, содержательные assertions по PDF/structured presentation facts.

## 4. Архитектурное решение

Ввести явное разделение транзитных представлений:

1. `solar_year_transits`

   Строгое пересечение с солярным годом. Используется для:

   - monthly table `Транзиты планет по домам`;
   - трактовок `Сатурн по 7 дому`, `Сатурн по 8 дому` и аналогичных;
   - итогового синтеза по сферам;
   - любых текстов, которые говорят "в текущем соляре".

2. `loop_transit_windows`

   Расширенный горизонт для высших планет и полных петель. Используется только для:

   - outer-planet cards;
   - интервалов реализации 1/2/3 касания;
   - ретроспективных/будущих касаний, если они нужны для понимания петли.

3. `transit_target_house_sets`

   Единый helper для домов цели:

   - `target_placement_house`;
   - `target_rulership_houses`;
   - `target_house_set = placement union rulerships`;
   - для таблицы `Золотое правило транзита` дополнительно нужны house set транзитной планеты и дом, по которому транзитная планета фактически идет.

4. `outer_transit_cards`

   Отдельная presentation-модель, собранная из `loop_transit_windows`, natal positions, rulerships и словарей интерпретаций. Jinja-шаблон не должен вычислять эти карточки ad hoc.

5. Render provenance

   Каждый PDF/render run должен фиксировать:

   - git SHA;
   - repo/worktree root;
   - render script или API endpoint;
   - source facts path/hash;
   - input fixture path/hash;
   - mode: recomputed или fixture-render;
   - core CLI path/version;
   - timestamp.

   Provenance должен быть доступен минимум в stdout/render log и metadata/sidecar. Клиентские страницы PDF не должны засоряться техническими строками без явного debug mode.

## 5. Программа работ по фазам

**Phase 0. Freeze and audit trail**

Deliverable: настоящий документ зафиксирован (в `ai-dev-system` overlay) + `STATUS_RU.md` отражает freeze, premature accept по Tier C 2026-05-12 и факт, что PDF Натальи не production-ready.

- Документ-программа создан и принят: настоящий файл.
- `STATUS_RU.md` обновлён.
- Запреты § 7 действуют.
- Не запускать новые work tickets по presentation, пока не закрыт provenance (Phase 1).
- Не менять `expected.json` до появления hard acceptance tests (Phase 2).

**Phase 1. Single source of truth + render provenance**

- Выбрать canonical render path для Натальи.
- Убрать/пометить временные harness scripts, которые создают неоднозначные PDF.
- Добавить render provenance в PDF metadata/sidecar/stdout.
- Зафиксировать, из какого root и какой SHA строится каждый проверочный PDF.
- Решить судьбу `.claude/worktrees/dreamy-moore-46f5eb`: merge, cherry-pick или discard. Нельзя держать две конкурирующие версии шаблона как равноправные. Решение по merge/discard остаётся за пользователем; Worker имплементирует mechanics.

**Phase 2. Hard acceptance assertions before more presentation work**

- Добавить тесты, которые падают на подтвержденные дефекты независимо от текущего `expected.json`.
- Тесты должны проверять structured presentation helpers и, где возможно, extracted PDF text.
- Тесты должны быть привязаны к case `08-natalya-2025-2026`.

**Phase 3. Horizon split**

- Ввести `solar_year_transits` и `loop_transit_windows`.
- Все трактовки по домам и итоговый synthesis перевести на `solar_year_transits`.
- Outer-planet cards оставить на `loop_transit_windows`.

**Phase 4. Outer-planet cards generator**

- Собрать `outer_transit_cards` **только** для тех outer-transit aspects, которые представлены в эталоне Марины как outer cards. **НЕ** для всех outer-aspects из календаря.
- Карточка должна включать интервалы реализации, таблицу `Золотое правило транзита`, психологический и событийный уровни.
- Для Натальи обязательны три карточки: Уран-Венера, Нептун-Юпитер, Нептун-Нептун.
- `Уран 150° Юпитер` остаётся календарным пунктом, не автоматической четвёртой карточкой, пока эталон Марины не показывает его как card.

**Phase 5. Rulership-expanded house sets**

- Вынести общую логику placement plus rulerships.
- Переиспользовать ее для `Дома цели`, outer cards и golden-rule tables.
- Сверить с эталоном Марины по Наталье через её golden-rule tables.

**Phase 6. Per-context cutoff policy**

- Для календаря аспектов обрезать окна по солярному году.
- Для outer cards показывать полный loop context, включая касания вне солярного года, если так сделано в эталоне.
- Для per-house interpretations и final synthesis запрещены дома/даты вне соляра.

**Phase 7. Calibration beyond Natalya**

- Default набор: `05-ekaterina`, `07-mariya`, `10-danila`. Альтернативно TL может выбрать 3 из `{01, 02, 03, 04, 05, 07, 09, 10}` с коротким обоснованием выбора.
- Все найденные расхождения переводить в explicit assertions или documented exceptions.
- Программа считается завершённой только после явного ack пользователя по всему набору calibration cases.

## 6. Hard acceptance assertions по Наталье

Эти assertions должны быть добавлены до новых presentation refactors.

**Render provenance:**

- Проверочный PDF/sidecar/log содержит git SHA.
- Проверочный PDF/sidecar/log содержит repo root или worktree root.
- Проверочный PDF/sidecar/log содержит source facts path/hash.
- Проверочный PDF/sidecar/log содержит mode: `fixture-render` или `recomputed`.
- Проверочный PDF/sidecar/log позволяет однозначно восстановить, каким кодом и какими facts был создан артефакт.

**Per-house transit interpretations:**

- Для Натальи в solar-year контексте Сатурн посещает только дома `[7, 8]`.
- В section `Транзиты планет по домам` и сразу после нее нет строки `Сатурн в 6 доме`.
- В трактовках по домам нет дат/домов из 2024 года.
- В трактовках по домам нет дат/домов из 2027-2028 годов.
- `houses_visited()` или его replacement принимает явный horizon/context и не читает full-loop table без фильтра.

**Outer-planet structure:**

- В PDF есть блок `Транзиты высших планет`.
- Есть карточка `тр Уран в квадрате c нат Венерой`.
- Есть карточка `тр Нептун в квадрате c нат Юпитером`.
- Есть карточка `тр Нептун в квадрате c нат Нептуном`.
- Каждая карточка содержит таблицу `Золотое правило транзита`.
- Каждая карточка содержит психологический уровень.
- Каждая карточка содержит событийный уровень.

**Outer-planet intervals** (tolerance ±2 дня на границы; **3 display windows (касания)** per карточку; **строго D → R → DR порядок по фазам внутри окон**, текстовый формат совпадает с эталонным стилем; **никакого exact timestamp equality**):

> **ERRATUM 2026-05-13 (после Phase 4 preflight BLOCKED + TL Path 3 decision):**
> Прежняя формулировка «строго 3 касания» оказалась неточной. Marina-style «касание» = **display window (orb-window)**, не **raw engine hit per motion phase**. Engine эмитит **hit-per-motion-phase** внутри orb-окна; для медленных планет (Нептун) одно orb-окно может содержать 2 фазы (D+R или R+DR), поэтому raw hit count = 4-5 при 3 display windows.
>
> Правильная семантика для card display:
> - **3 display windows** per карточка (Marina-style: 1-е/2-е/3-е касание).
> - Worker presentation агрегирует raw hits по уникальным `(orb_enter, orb_exit)` tuples в display windows.
> - Phase order проверяется как **set of phases per window**, не как точный list (window 1 для Нептун-Юпитер: `{Direct, Retrograde}`; window 3: `{Retrograde, DirectReturn}`).
>
> Reference даты ниже корректны для display windows у Урана-Венеры (где engine эмитит 3 окна = 3 hits, потому что Уран быстрее). Для Нептуна (одно окно может содержать 2 фазы) reference даты ниже **могут расходиться** с engine output на границах окон (особенно Нептун-Нептун окно 1 — 178d shift). Это **TASK 4a domain** — `Transit contact window semantics for slow outer loops` — открывается после Phase 4 close.
>
> Phase 4 acceptance Phase 4 retroactively суживается с 9 → 7 xfail flips; 2 Neptune interval tests остаются xfail до TASK 4a.

- Уран квадрат Венера содержит три display windows (reference):
  - `03.06.2025 12:00 - 12.07.2025 12:00`
  - `02.11.2025 12:00 - 22.12.2025 12:00`
  - `19.03.2026 00:00 - 30.04.2026 00:00`
- Нептун квадрат Юпитер содержит три display windows (reference; engine emit 5 hits in 3 windows):
  - `21.04.2026 12:00 - 28.09.2026 12:00`
  - `21.02.2027 12:00 - 16.04.2027 12:00`
  - `10.10.2027 00:00 - 16.02.2028 12:00`
- Нептун квадрат Нептун содержит три display windows (reference; engine emit 4 hits in 3 windows; window 1 has ~178d shift — TASK 4a domain):
  - `27.09.2024 00:00 - 12.10.2024 00:00`
  - `31.01.2025 12:00 - 29.03.2025 00:00`
  - `25.10.2025 00:00 - 24.01.2026 12:00`

**Calendar dates and clipping** — explicit rule:

- `period_end = min(actual_period_end, solar_return_jd + 365.25)`.
- `period_start = max(actual_period_start, solar_return_jd)` (для соляра — клипом по началу).
- Calendar row `Нептун 90° Юпитер` в солярном календаре обрезан по концу солярного года, как в эталоне: `21.04.2026 - 07.08.2026`.
- Calendar row `Уран 0° MC` клипнется до `07.08.2026` (конец соляра Натальи). Хвост до ноября 2026 в клиентском календаре запрещён.
- Calendar rows не показывают месяцы вне solar-year span.

**Target houses** (source = Marina golden-rule tables из эталона, **НЕ** «наша логика сказала»):

- `Дома цели` не может быть placement-only, если у target planet есть rulership houses.
- Для `Сатурн 90° Нептун` ожидается house set, явно совпадающий с Marina golden-rule table — sверять при TASK 5 implementation.
- Для `Нептун 90° Юпитер` ожидается house set, явно совпадающий с Marina golden-rule table. Worker проверяет натальные куспиды Натальи (Юпитер в 4 доме, управление Стрельцом и Рыбами через куспиды натальной карты) и сверяет результат с Marina table. `{4, 7}` принимается как expected **только через эту сверку**.
- Для `Юпитер 120° Марс` ожидается house set, явно совпадающий с Marina golden-rule table.
- Для `Уран 90° Венера` expected set берётся **прямо из Marina golden-rule table** (визуальный reference / скриншот эталона). Не от «наша логика вывела». В текущем выводе `12` alone is a failure.

**Regression bans:**

- Нельзя принимать PDF, если он содержит `Сатурн в 6 доме` в текущем solar-year transit interpretation.
- Нельзя принимать PDF, если outer-planet cards отсутствуют, даже если общий календарь есть.
- Нельзя принимать PDF, если `Дома цели` выводят только один house для multi-house target.
- Нельзя принимать PDF, если provenance не позволяет отличить main от worktree.

## 7. Запреты против drift

1. Не перезаписывать `packages/test-fixtures/golden-cases/*expected.json` результатом текущего engine без отдельного diff review и acceptance tests.

2. Не считать зеленые snapshot/golden tests достаточным доказательством близости к Марине.

3. Не использовать full-loop horizon для текстов, которые описывают текущий солярный год.

4. Не добавлять свободный интерпретационный текст, который не связан с проверенной таблицей facts. Любая трактовка после таблицы должна ссылаться на тот же house/aspect set, который отображен в таблице.

5. Не держать одновременно main и worktree как равноправные источники PDF. У каждого проверочного артефакта должен быть один root and SHA.

6. Не открывать Worker subagents на задачи Phase 3-7, пока Phase 1 и Phase 2 не закрыты.

7. **Не показывать Марине PDF до закрытия всей программы — включая Phase 7 — и финального ack пользователя.** Промежуточные PDF (после Phase 1, после Phase 2, и т.д.) — это внутренние debug/QA артефакты команды, не клиентский deliverable. Показ Марине «на 80%» запрещён.

## 8. Порядок открытия TASK'ов

**TASK 1. Single source of truth + render provenance**

- Tier: C
- Layer: infra + services
- Цель: сделать каждый PDF воспроизводимым и однозначно привязанным к code/facts source.
- Acceptance:
  - render provenance присутствует в log/metadata/sidecar;
  - canonical render path для Натальи документирован;
  - временные harness scripts не создают неоднозначность;
  - main vs worktree decision зафиксирован (пользователь принимает merge/discard, Worker имплементирует);
  - новый PDF можно однозначно связать с SHA/root/facts.

**TASK 2. Hard acceptance assertions for Natalya transit section**

- Tier: C
- Layer: services + PDF tests
- Цель: поставить тестовый контракт до новых presentation правок.
- Acceptance:
  - tests fail на `Сатурн в 6 доме`;
  - tests fail на отсутствие outer-planet cards;
  - tests fail на placement-only `Дома цели`;
  - tests fail на даты вне соляра в per-house interpretations/final synthesis;
  - tests distinguish allowed loop-card dates from forbidden solar-year interpretation dates;
  - intervals tests используют tolerance ±2 дня, проверяют строгое число касаний (3) и порядок фаз (D → R → DR), не exact timestamp equality.

**TASK 3. Transit horizon split**

- Tier: C **с явным правилом эскалации до Tier A** при изменении schema/core contract (новое поле в `TransitContact` / `SolarComputedFacts` / любое visible-через-границу-процесса изменение). При эскалации — Mode strict, schema cascade per bright-line #8, отдельный Worker + Reviewer subagent.
- Layer: core + services
- Цель: разделить `solar_year_transits` и `loop_transit_windows`.
- Acceptance:
  - per-house interpretations используют только `solar_year_transits`;
  - outer cards используют `loop_transit_windows`;
  - Наталья: Сатурн solar-year houses `[7, 8]`;
  - full-loop data больше не протекает в текущий solar-year text.

**TASK 4. Outer-planet cards generator**

- Tier: C
- Layer: services + PDF presentation
- Цель: восстановить структуру Марины для высших планет — **только для тех outer-transit aspects, которые представлены в эталоне Марины как outer cards**.
- Acceptance:
  - три обязательные карточки Натальи существуют (Уран-Венера, Нептун-Юпитер, Нептун-Нептун);
  - в каждой есть intervals (с tolerance из § 6), golden-rule table, psychology, event level;
  - карточки используют structured facts, а не ad hoc Jinja logic;
  - НЕ создаётся карточек для outer-aspects, отсутствующих в эталоне как cards (`Уран 150° Юпитер` остаётся в календаре, не в cards).

**TASK 5. Rulership-expanded target houses**

- Tier: C **с эскалацией до Tier A**, если реализация попадёт в shared Haskell `Domain/` helper (core) или станет schema-visible field. При эскалации — Mode strict, schema cascade, отдельный Worker + Reviewer.
- Layer: core/services shared domain logic
- Цель: единый house-set helper для транзитов.
- Acceptance:
  - `Дома цели` включают placement plus rulerships;
  - Worker сверяет натальные куспиды Натальи (Asc Дева → конкретные куспиды Тельца/Весов для Венеры, Стрельца/Рыб для Юпитера и т.д.) с Marina golden-rule tables из эталона. Numeric expected sets фиксируются ТОЛЬКО через эту сверку.
  - Венера не деградирует до placement-only.

**TASK 6. Per-context cutoff policy**

- Tier: C
- Layer: services presentation
- Цель: разные date cutoff rules для calendar, cards и per-house text.
- Acceptance:
  - календарь обрезается по солярному году per explicit rule: `period_end = min(actual, sr_jd + 365.25)`, `period_start = max(actual, sr_jd)`;
  - cards показывают full loop context;
  - final synthesis не содержит stale dates из 2024 или future dates из 2027-2028, кроме явно разрешенных card contexts;
  - Уран 0° MC в календаре клипнется до 07.08.2026.

**TASK 7. Multi-case calibration**

- Tier: C
- Layer: services + QA
- Цель: доказать, что решение не подогнано только под Наталью.
- Acceptance:
  - default cases: `05-ekaterina`, `07-mariya`, `10-danila` — все три прогнаны; либо TL выбирает 3 из `{01, 02, 03, 04, 05, 07, 09, 10}` с обоснованием в TASK Context;
  - новые расхождения оформлены как assertions, documented exceptions или follow-up tasks;
  - PDF status можно повысить до production-ready (Марине можно показывать) только после явного ack пользователя по всему набору calibration cases.
