# TASK: target-architecture-conscious-deviations-sync

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`architecture-drift-recon.md` § 5.1 идентифицировал 9 conscious deviations (bizdev-эволюция под прямые запросы Марины), которые расширили Phase 0 за рамки prescription'а `target-architecture.md` от 2026-04-24, особенно § 6 «PDF layout — Phase 0». Документ продолжает декларировать «Чего НЕТ в Phase 0: SVG графика, текстовые интерпретации, дирекции» — это уже неправда на `astro:b7774cf`.

Цель — синхронизировать `target-architecture.md` с реальностью **по 4 пунктам** из go-сообщения пользователя:

1. SVG натал-колесо уже в Phase 0 (`pdf/wheel.py`).
2. Theme-grouped closed-dictionary text-интерпретации уже в Phase 0 (`pdf/{direction,house_pair,transit,synthesis}_themes.py`).
3. Directions (Solar Arc) уже в Phase 0 (`Domain/Directions.hs` + `pdf/direction_themes.py`).
4. Draft / editor layer (Phase 0.8) уже появился как conscious UX evolution (`migrations/002_draft_overrides.sql`, `apps/web-react/src/pages/DraftEditor.tsx` + 16 components, `consultation-draft-overrides.schema.json`).

Не входит — и это **критично против scope creep:** не переписывать § 1-4 (treangle / layers / domain / workflow), не трогать bright lines § 11, не делать новых решений по Phase 0.2 / Phase 1+ (это отдельные задачи, не recon-sync).

## Scope

Входит — surgical edits в overlay-документы, без product code touches:

### Edit A — `target-architecture.md` § 5.2 storage paragraph

Один абзац (строки ~369) сейчас:

> `InterpretationRule`, `Draft`, `Artifact` — **отсутствуют в Phase 0**. Правила живут у Марины в PDF на её стороне; draft и artifact — это просто `consultations.facts_json` + `consultations.pdf_path` в одной таблице.

Переписать как:

> **Phase 0.8 evolved beyond this baseline.** К `consultations` таблице Phase 0.8 добавил отдельный editorial-overrides slot (`migrations/002_draft_overrides.sql`) — `facts_json` остаётся immutable после `compute`, ручные overrides через UI пишутся отдельной колонкой (или связанной таблицей; см. реальную миграцию). `InterpretationRule` как rules engine по-прежнему **отсутствует** — closed-dictionary template-фразы в `services/api-python/app/pdf/*_themes.py` это **не** rules engine (см. § 6.1 ниже). `Artifact`-как-таблица отсутствует; PDF-путь по-прежнему `consultations.pdf_path`. См. `architecture-drift-recon.md` § 5.1.

### Edit B — `target-architecture.md` § 6 PDF layout (substantial restructure)

Текущий § 6 переписать **сохраняя нумерованный блок-list**, но:

**B.1.** После заголовка `## 6. PDF layout — Phase 0` вставить новый абзац-преамбулу:

> **Эволюция scope (2026-05-06):** § 6 был зафиксирован 2026-04-24 как «структурированные факты без графики и интерпретации». Продуктовая итерация 2026-04-24 → 2026-05-06 расширила Phase 0 PDF под прямые запросы Марины: добавлены SVG натал-колесо, closed-dictionary text-интерпретации (не rules engine), блок дирекций (Solar Arc), и editorial overrides layer (`Draft`). Это conscious deviations — UX evolution, не дисциплинарный drift. См. `architecture-drift-recon.md` § 5.1. Bright lines (§ 11) сохраняются: интерпретации остаются closed-dictionary template-фразами (не free-text / LLM / rules engine); PDF rendering продолжает жить в Python+WeasyPrint; ephemeris/aspects/houses в Haskell core.

**B.2.** Обновить «Цель» одним предложением:

> Цель: PDF-отчёт — **структурированные факты + графический натал-референс + closed-dictionary заголовки и подсказки** — на основе чего Марина пишет финальную интерпретацию для клиента (с editorial overrides через DraftEditor если нужно).

**B.3.** Расширить блок-list. Заменить старые 5 блоков на актуальные ~7-8:

```
1. **Заголовок:** ФИО клиента, дата/время/место рождения, год соляра.

2. **Натал-карта (визуальная):** SVG-колесо с path-based глифами знаков и планет
   (`services/api-python/app/pdf/wheel.py`). Решение через path-based вместо
   `<text>` — продиктовано WeasyPrint 68.1 limitation; см. Correction 007 в
   `astro/.claude/corrections.md`.

3. **Натальная карта (таблицы):**
   - Таблица позиций планет (Planet, Sign, Degree°Minute, House Placidus, Retrograde?).
   - Таблица аспектов (Natal-профиль).
   - Соединения с фикс.звёздами — Phase 0.2 (`Domain.FixedStars` отсутствует
     в `astro:b7774cf`; см. `PHASE_0_TASKS.md` T-B.4).
   - Классификации (strong-planets с причинами, weak-planets с причинами).

4. **Соляр-карта:**
   - Точный момент возврата (UTC + локальное время места рождения).
   - Таблица позиций + аспекты + классификации.
   - **Closed-dictionary house-pair interpretations** (Solar/Natal — 144 ячейки
     в `services/api-python/app/pdf/house_pair_themes.py`).

5. **Дирекции (Solar Arc):**
   - Active formulas для Asc / MC / 1-house с relevance-фильтром
     (`core/astrology-hs/src/Domain/Directions.hs`).
   - **Closed-dictionary direction-text** (`services/api-python/app/pdf/direction_themes.py`).
   - Метод по умолчанию — Solar Arc (Phase 0.5 lock-in; см. Correction 006 в
     `astro/.claude/corrections.md`).

6. **Годовая таблица транзитов по домам натала:**
   - Inner movers (Mars / Venus / Saturn / Jupiter) — таблица «период X в доме Y».
   - **Closed-dictionary transit-by-house interpretations** «{планета} в {доме}»
     (84 entries в `services/api-python/app/pdf/transit_themes.py`).
   - Outer slow planets (Uranus / Neptune / Pluto) обрабатываются отдельно через
     `Domain.ImportantTransitPlanets`; их long-transit narrative — Phase 0.9b refinement.

7. **«Итоги консультации» (theme-grouped synthesis):**
   - 10 life themes (финансы, документы/переезд, партнёрство/контракты, и т.п.).
   - **Closed-dictionary synthesis blocks** (`services/api-python/app/pdf/synthesis_themes.py`).

8. **Footer:** версия ruleset, версия core, ephemeris source, дата генерации.
```

**B.4.** Заменить блок «Чего НЕТ в Phase 0 PDF»:

```
**Чего НЕТ в Phase 0 PDF (residual):**

- **Свободно-текстовых LLM-интерпретаций** — never; всё closed-dictionary by design (см. § 6.1).
- **Editor правил интерпретации в UI** — Phase 1+. DraftEditor (`apps/web-react/src/pages/DraftEditor.tsx`) — это editorial overrides поверх machine-generated skeleton, **не** rules editor; см. § 7.2.
- **Equal-from-Asc дома** — Phase 0.2 (`Domain.Houses.Equal` отсутствует на `astro:b7774cf`; см. `PHASE_0_TASKS.md` T-B.3).
- **Касаний фикс.звёзд** — Phase 0.2 (см. T-B.4).
- **Polar fallback** (`|lat| > 66.5°` → Equal) — Phase 0.2.
- **Касаний высших планет в формате отдельного long-transit раздела** — Phase 0.9b (упомянуты в `Domain.ImportantTransitPlanets`, но без выделенного PDF-блока).
```

**B.5.** Добавить новую короткую под-секцию `### 6.1 Closed-dictionary interpretations — НЕ rules engine`:

```
### 6.1 Closed-dictionary interpretations — НЕ rules engine

Phase 0 PDF содержит closed-dictionary template-фразы в `services/api-python/app/pdf/*_themes.py`. Это **не нарушает** § 5.2 («`InterpretationRule` отсутствует в Phase 0») — closed-dictionary это статические phrase-таблицы (`PriorityTheme → Text`, `(Planet, House) → Text`, и т.п.), индексируемые pure-функциями по enum/тип. Различие:

- ✅ **Closed-dictionary (Phase 0):** фиксированные таблицы в product code; no clock, no I/O, no LLM, no user-editable rules; обновляются только через product-code commit.
- ❌ **Rules engine (Phase 1+):** редактируемые в UI правила, версионированные in-DB, применяемые движком к фактам — это `InterpretationRule` сущность из § 5.2, отложенная.

Closed-dictionary frame совместим с принципом «правила живут у Марины в PDF на её стороне» — каноничные фразы Марины зафиксированы в Python-коде, не в БД с UI-редактором.
```

### Edit C — `target-architecture.md` § 7 Frontend

**C.1.** В § 7.2 после строки `ConsultationList, ConsultationForm, ConsultationView` добавить новую строку:

```
- `DraftEditor` + 16 компонентов в `components/draft-editor/` (Phase 0.8 — editorial overrides поверх machine-generated skeleton; см. § 5.2).
```

**C.2.** В § 7.3 «Что не во Frontend» — изменить пункт про редактор правил:

Текущий: `- Редактор правил интерпретации — Phase 1+.`

Заменить на:

`- **Editor правил интерпретации (rules engine UI)** — Phase 1+. Текущий `DraftEditor` (Phase 0.8) — это editorial overrides поверх machine-generated skeleton, не rules editor (см. § 6.1).`

### Edit D — короткая cross-ref в `migration-plan.md`

После заголовка `# Migration Plan: mini-MVP → Target Architecture` (строки 1-3) добавить новый блок:

```
> **Update 2026-05-06:** Phase 0 эволюционировал за рамки оригинального плана 0.1/0.2 в продуктовой работе 2026-04-24 → 2026-05-06 (внутренние «фазы 0.5–0.10b»). См. `architecture-drift-recon.md` § 3 (PHASE_0_TASKS status walk) и § 5.1 (conscious deviations) + `target-architecture.md` § 6 «Эволюция scope». Этот migration-plan остаётся валидным для **порядка** и **зависимостей** блоков; конкретный scope каждого блока — обновлён в target-architecture.md и в status-аннотациях `PHASE_0_TASKS.md`.
```

### Edit E — короткая cross-ref в `PHASE_0_TASKS.md`

После заголовка-блока (строки 1-7) добавить новый блок перед `## Phase 0 разбит на две стадии`:

```
> **Update 2026-05-06:** Status каждой задачи зафиксирован под heading'ом в формате `**Status @ astro:<hash>:** <label>`. См. `architecture-drift-recon.md` § 3 для общей карты «что закрыто / partial / not-started / obsolete» и § 5.1 для conscious deviations, расширивших Phase 0 за рамки этого документа. Сами scope/files/checks отдельных задач не пересматривались по факту evolution — только аннотированы.
```

Не входит:
- любая модификация product code в `/Users/ilya/Projects/astro/`;
- любая правка `architecture-drift-recon.md`, `current-mvp-review.md`, `git-bootstrap-{plan,execution}.md`;
- любая правка bright lines § 11 в `target-architecture.md`;
- любая правка § 1 (треугольник), § 2 (слои), § 3 (доменная модель), § 4 (workflow snapshot), § 8 (bridge protocol), § 9 (deploy), § 10 (extension points), § 12 (open questions), § 13 (как используется);
- запись в `astro/.claude/{corrections,architecture-invariants}.md`;
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` etc.;
- любая правка README.md, starts/, RESEARCH/, TASKS/archive/, HANDOFFS/archive/;
- запуск product builds / tests (`cabal`, `pytest`, `npm`, `tsc`);
- любые git-операции в `/Users/ilya/Projects/astro` (TASK overlay-only).

## Files

- new:    —
- modify:
  - `project-overlays/astro/ARCHITECTURE/target-architecture.md` (Edits A, B, C — § 5.2 / § 6 / § 7.2-7.3)
  - `project-overlays/astro/ARCHITECTURE/migration-plan.md` (Edit D — top cross-ref)
  - `project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md` (Edit E — top cross-ref, 1 abzac, не трогать существующие 29 status-аннотаций)
- delete: —

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких операций (TASK overlay-only).
- `/Users/ilya/Backups/**` — не трогать.
- `project-overlays/astro/.overlay-maturity` — `pre-phase0`.
- `target-architecture.md` секции § 1, 2, 3, 4, 8, 9, 10, 11, 12, 13 — **не трогать** (только § 5.2, § 6, § 7.2-7.3).
- `target-architecture.md § 6.1` — это новая под-секция (Edit B.5), её добавление это часть scope.
- `architecture-drift-recon.md`, `current-mvp-review.md`, `git-bootstrap-plan.md`, `git-bootstrap-execution.md` — только цитировать.
- 29 `**Status @ astro:<hash>:**` строк в `PHASE_0_TASKS.md` — не трогать (Edit E добавляет блок в шапку, не трогает аннотации).
- `project-overlays/astro/{README.md, starts/, RESEARCH/, TASKS/archive/, HANDOFFS/archive/}` — не трогать.

## Acceptance criteria

- [ ] `target-architecture.md` § 5.2 paragraph про `InterpretationRule`/`Draft`/`Artifact` переписан в формат с упоминанием Phase 0.8 + ссылкой на `architecture-drift-recon.md § 5.1`. Подтверждается: `grep -n 'Phase 0.8 evolved' project-overlays/astro/ARCHITECTURE/target-architecture.md` → 1 match.
- [ ] `target-architecture.md` § 6 содержит:
  - [ ] преамбулу `**Эволюция scope (2026-05-06):**` (1 match);
  - [ ] обновлённый блок-list 7-8 пунктов вместо 5;
  - [ ] явное упоминание `pdf/wheel.py`, `pdf/house_pair_themes.py`, `pdf/direction_themes.py`, `pdf/transit_themes.py`, `pdf/synthesis_themes.py` (5 path mentions);
  - [ ] явное упоминание `Domain/Directions.hs`;
  - [ ] обновлённый «Чего НЕТ» list — без устаревших пунктов про SVG / интерпретации / дирекции, с новыми residuals (LLM, rules engine UI, Equal-from-Asc, fixed stars, polar fallback, outer-planet long-transit раздел);
  - [ ] новая под-секция `### 6.1 Closed-dictionary interpretations — НЕ rules engine`.
- [ ] `target-architecture.md` § 7.2 содержит mention `DraftEditor` (1 match).
- [ ] `target-architecture.md` § 7.3 переформулирован про rules engine vs DraftEditor.
- [ ] `migration-plan.md` содержит блок `> **Update 2026-05-06:**` в шапке (1 match).
- [ ] `PHASE_0_TASKS.md` содержит блок `> **Update 2026-05-06:**` в шапке (1 match), 29 status-аннотаций неизменны (`grep -c '^\*\*Status @ astro:' PHASE_0_TASKS.md` остаётся = 29).
- [ ] Bright lines в § 11 `target-architecture.md` неизменны: `grep -A 25 '^## 11. Bright lines' target-architecture.md | head -30` показывает то же содержание что и до правки (Worker фиксирует в HANDOFF через `git diff` на этой секции — должен быть пустой).
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает TASK как `RECENTLY ARCHIVED` после accept.
- [ ] Worker не трогал product code: `git -C /Users/ilya/Projects/astro status --short` остаётся `## main` (clean / commit:bb5a9eb).
- [ ] Worker не запускал `cabal`, `pytest`, `npm`, `tsc`.

## Test commands

```bash
# Read-only sanity (Worker запускает чтобы спроектировать diff):
cat project-overlays/astro/ARCHITECTURE/target-architecture.md | head -50
sed -n '/^## 5.2 /,/^### 5.3/p' project-overlays/astro/ARCHITECTURE/target-architecture.md
sed -n '/^## 6\. PDF/,/^## 7\. /p'  project-overlays/astro/ARCHITECTURE/target-architecture.md
sed -n '/^## 7\. Frontend/,/^## 8\. /p' project-overlays/astro/ARCHITECTURE/target-architecture.md

# Sanity checks после edit'ов:
grep -nE 'Phase 0\.8 evolved|Эволюция scope \(2026-05-06\)|6\.1 Closed-dictionary interpretations' \
  project-overlays/astro/ARCHITECTURE/target-architecture.md
grep -nE 'pdf/(wheel|house_pair_themes|direction_themes|transit_themes|synthesis_themes)\.py' \
  project-overlays/astro/ARCHITECTURE/target-architecture.md
grep -nE 'Domain/Directions\.hs|DraftEditor' \
  project-overlays/astro/ARCHITECTURE/target-architecture.md
grep -nE 'Update 2026-05-06' \
  project-overlays/astro/ARCHITECTURE/migration-plan.md \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md

# Bright lines untouched check:
diff <(git show HEAD:project-overlays/astro/ARCHITECTURE/target-architecture.md \
        | sed -n '/^## 11\. Bright lines/,/^## 12\. /p') \
     <(sed -n '/^## 11\. Bright lines/,/^## 12\. /p' \
        project-overlays/astro/ARCHITECTURE/target-architecture.md)
# (must be empty)

# Status-annotations untouched in PHASE_0_TASKS.md:
grep -c '^\*\*Status @ astro:' \
  project-overlays/astro/ARCHITECTURE/PHASE_0_TASKS.md
# (must remain = 29)

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-target-architecture-conscious-deviations-sync.md FROM=worker TO=tl`.

В теле обязательно:
- список изменённых файлов (3: target-architecture.md, migration-plan.md, PHASE_0_TASKS.md), с per-file `wc -l` до и после;
- per-grep evidence (8 проверок из § Test commands);
- результат `make check` и `make status SLUG=astro`;
- **bright lines § 11 untouched diff** (пустой) — это ключевая гарантия от scope creep;
- **status-annotations untouched** в PHASE_0_TASKS.md (count = 29);
- `Product repo status:` — `clean / commit:bb5a9eb` (Worker overlay-only TASK, продуктовый repo не трогается);
- evidence-rule подтверждение: «Worker не выполнял операций в `/Users/ilya/Projects/astro` (даже read-only `git` команды не нужны для этого TASK — все evidence из overlay-документов)»;
- если возникли непредвиденные out-of-scope изменения (например IDE форматирование) — указать в § Conflicts.

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-target-architecture-conscious-deviations-sync.md`. **TL не делает manual edit `Status:`**.

Reviewer: optional. Tier C docs-only, по go-сообщению пользователь не запрашивал mandatory pass; TL может accept без Reviewer'а или запустить отдельным шагом если есть сомнения по поводу bright-line-preservation.

## Контекст

- `architecture-drift-recon.md` § 5.1 (conscious deviations table) — primary source of items 1-4 в § Problem.
- `architecture-drift-recon.md` § 4.6 (target § 6 «Чего НЕТ» divergent major) — основной обоснование Edit B.
- `astro:b7774cf` — Phase 0 baseline после `astro-core-naming-drift-cleanup`.
- `astro:bb5a9eb` — текущий HEAD после `audit-trail-after-b7774cf` (Correction 008 + T-B.8 status update). Этот TASK не трогает product repo, поэтому HEAD остаётся `bb5a9eb` после accept.
- Bright line constraints (target-architecture.md § 11, especially #2 «Core не рендерит PDF» и concept «правила живут у Марины в PDF на её стороне» из § 5.2) — must preserve через § 6.1 clarification.
- Не trigger'ить § 8.3 schema gate cascade (этот TASK не трогает `packages/contracts/*.schema.json` или test-fixtures).
