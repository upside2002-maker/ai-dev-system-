# TASK: proforientation-phase-a1-core-vocation

- Status: done
- Ready: yes
- Date: 2026-06-06
- Project: astro
- Layer: core (Haskell: новый `Domain.Vocation` + factor-хелперы; pure, без I/O; БЕЗ схемы/Bridge — это A2)
- Risk tier: A (домен-математика/отбор профориентации; money/career-класс)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: upside2002@gmail.com («го» 2026-06-06)
- Reviewer: независимый Reviewer-агент (отдельная сессия 2026-06-06) — APPROVE-WITH-FINDINGS (F1 low dead-code → A2; F2/F3 info); verdict в `HANDOFFS/archive/2026-06-06-reviewer-to-tl-proforientation-phase-a1.md`

## Problem

Phase A1 эпика профориентации (мемо `ARCHITECTURE/proforientation-module-architecture-2026-06-06.md`). Phase 0 (закрыт, `c986e99`) доказал метод против книжного worked-example «Банкир» и дал build-карту. Phase A разбита на **A1 (ядро+факторы+тесты, без схемы)** → A2 (schema-gate), по образцу возвратов (B core / C schema).

A1: новый pure-Core `Domain.Vocation` — стадии 1–4 алгоритма Дарагана (реализация → способности → фильтрация → топ-2–3 сочетания) + достройка отсутствующих факторов + golden/unit-тесты. **Стадия 5 (толкование) и схема/выдача — НЕ здесь** (Phase B / A2). Выход A1 = сочетания «планета+дом» + факторы-ключи (in-memory), проверенные golden'ом.

**Источник метода:** `RESEARCH/daragan-proforientation-method-extract.md` (алгоритм) + книга `~/Downloads/Константин_Дараган_Профессиональная_астрология.pdf` (offset PDF=книга+1) для дочитывания. Phase 0 HANDOFF (`HANDOFFS/archive/2026-06-06-worker-to-tl-proforientation-phase0-method-proof.md`) — reuse-vs-build, конвенции, Банкир-разбор.

## Решения TL (locked — не пересматривать в A1)

- **Благие фикс.звёзды (стадия 2з): ОМИТ в v1.** В книге списка нет (Дараган относит к элекциям). Не выдумывать (TZ). Флаг Марине на будущее; стадия 2 работает на 7 остальных признаках.
- **Дорифорий/Возничий:** ближайшая планета ДО Солнца по эклиптической долготе = Дорифорий, ПОСЛЕ = Возничий (все 10 планет, без орб-капа). Reverse-validated против таблицы Банкира в Phase 0.
- **Фигуры Джонса:** реализовать «ручку корзины» (bucket handle) и «пращу» (sling handle) — стандартная доктрина Джонса; пограничные случаи — флаг в HANDOFF.
- **«Соединение ИЛИ гармоничный аспект»** = Conjunction ∪ Harmonious. В ядре Conjunction = Neutral → явно объединять с гармоничными (sextile/trine), НЕ полагаться на nature=Harmonious для соединения.
- **Квинконс НЕ входит** в «гармоничные» (нет расширения scope; в отличие от возвратов — здесь quincunx не нужен).

## Scope (стадии 1–4 + факторы)

### A1.1 — Достройка факторов (новые хелперы)
В `Domain.Vocation` или под-модулях (`Domain.Vocation.Reception`, `.Satellites`, `.JonesPattern`):
- **Взаимная рецепция** по обители/экзальтации (две планеты в знаках друг друга) — BUILD (в ядре нет, grep 0).
- **Дорифорий/Возничий** — селектор по долготе относительно Солнца (см. решение).
- **Детектор фигур Джонса** — bucket handle / sling handle (360°-форма; существующий `Stellium` — per-house, не подходит).
- **Управитель дома** — тонкий аксессор (паттерн уже в `Directions.housesForPlanet` — reuse/вынести).
- **Управитель солнечного знака** — композиция из `rulersOfSign`.

REUSE (подтверждено Phase 0): `planetInHouse`, `interceptedSigns`, `rulersOfSign` (modern+traditional), `isDomicile`/`isExaltation`, `findAspects`/`filterHarmonious`, `ascendantZodiacPosition`, `isAboveHorizon` (элевация).

### A1.2 — `Domain.Vocation` стадии 1–4
- **Стадия 1 (реализация):** для домов X/II/VI/VIII собрать {управитель; планеты в доме; соединение/гармония с управителем; рецепция с управителем/планетами дома}.
- **Стадия 2 (способности):** {упр.Асц + планеты I дома; дорифорий/возничий; обитель/экзальтация; упр.солн.знака; соединение/гармония с Солнцем; элевация; ручка Джонса; [фикс.звёзды — омит v1]}. Счётчик повторов планет.
- **Стадия 3 (фильтрация):** планеты в ОБОИХ списках; плотность строк (планета с пустыми полями — нежелательна); приоритет способностей = лучший знак + лучшая аспектация; иерархия реализации X>II>VI; VIII только при очень удачных.
- **Стадия 4 (выбор):** ранжирование → топ-2–3 «планета+дом», приоритет связи с X.
- Типы: таблица факторов + ранжированные сочетания с ключами факторов (для Phase B толкования). Без текста толкования. Без rulership-побочки. NO wildcard над Planet (Correction 002).

### A1.3 — Тесты (golden + unit)
- **Golden «Банкир»** (Phase 0 validated): воспроизвести таблицу стадий 1–2 Дарагана (упр.X=Юпитер, упр.II=Марс, упр.VI=Луна, упр.VIII=Венера, Плутон-не-сигнификатор, упр.солн.знака=Венера, упр.Асц=Уран+Сатурн, Дорифорий=Юпитер/Возничий=Нептун) + топ-вывод (Юпитер упр.X в VIII → банкир/фин.менеджер). Карта Банкира — из книги (PDF ~301).
- **Marina (person 4):** топ-3 = Юпитер(упр.X в II)/Венера(упр.II в I, дорифорий)/Солнце(в I); Луна/Нептун исключены (пустой столбец способностей).
- **Unit:** рецепция (две планеты в знаках друг друга), дорифорий/возничий (синтетика), Джонс bucket/sling handle (синтетика), детерминизм/порядок.
- Существующие golden (solar) — без изменений (Domain.Vocation аддитивен).

## Files
- new: `core/astrology-hs/src/Domain/Vocation.hs` (+ под-модули по необходимости).
- new: `core/astrology-hs/test/Test/Domain/VocationSpec.hs` + golden-фикстуры (Банкир, Marina).
- modify: `core/astrology-hs/*.cabal` (модули + test); возможно тонкий экспорт house-ruler из `Directions`/`Dignities`.
- modify: `OPERATING/journal/2026-06.md`.
- delete: —

## Do not touch
- Схема/контракт (`packages/contracts/*`), `Bridge/*`, `app/Main.hs` — это **A2** (schema-gate).
- Python, frontend, PDF — Phase B.
- Существующие golden expected (solar) — без изменений.
- `Domain.Returns`/`TransitMath`/`TransitCalendar` — не трогать.
- **NO выдумывания факторов** вне метода (TZ). Сомнение → сверка с книгой/Phase 0 HANDOFF, иначе флаг.
- **NO фикс.звёзд-списка** (омит v1).
- **NO wildcard над Planet** (Correction 002). **NO квинконс в гармоничных.**
- **NO LLM.**

## Acceptance
### Primary
- [ ] Факторы достроены: рецепция, дорифорий/возничий, Джонс bucket/sling, house-ruler аксессор, упр.солн.знака.
- [ ] `Domain.Vocation` стадии 1–4 → топ-2–3 «планета+дом» + таблица факторов.
- [ ] **Golden «Банкир»**: таблица стадий 1–2 воспроизводит Дарагана дословно + топ-вывод совпадает.
- [ ] **Marina**: топ-3 = Юпитер(X→II)/Венера/Солнце.
- [ ] Unit-тесты факторов (рецепция/дорифорий/Джонс) + детерминизм.
- [ ] Стадия 5 / схема / выдача НЕ реализованы (A2/B).

### Common
- [ ] `cabal build` clean; `cabal test` зелёный, существующие golden (solar) бит-в-бит.
- [ ] `git status --short` чисто для intended.
- [ ] Один product commit (Vocation + факторы + тесты + cabal).
- [ ] Один overlay commit (HANDOFF + journal).
- [ ] Push backup, parity.
- [ ] **Reviewer REQUIRED (Tier A, независимый — Correction 021).**

### Discipline
- [ ] NO схема/Bridge/Main (A2). NO Python/frontend/PDF (B).
- [ ] NO solar golden правок. NO wildcard. NO квинконс-в-гармоничных. NO фикс.звёзд-выдумки. NO LLM.

## STOP triggers
- Вывод `Domain.Vocation` расходится с таблицей Банкира Дарагана → STOP (метод не воспроизведён).
- Worker выдумывает фактор вне метода / придумывает список фикс.звёзд → STOP.
- Worker трогает схему/Bridge/Main/Python/PDF → STOP (не та фаза).
- Worker ломает существующие solar golden → STOP.
- Worker вводит wildcard над Planet или квинконс в гармоничные → STOP.

## Reviewer subagent — REQUIRED (Tier A, независимый)
После self-submit TL спускает независимого Reviewer (отдельная сессия — Correction 021). Критерии: golden Банкир воспроизводит Дарагана; Marina топ-3; корректность факторов (рецепция/дорифорий/Джонс) против метода; solar golden бит-в-бит; нет wildcard/квинконса/выдумок; 0 STOP.

## Context
**Mode strict + Tier A.** Critical approved: upside2002@gmail.com «го» 2026-06-06.
**Baseline:** product `51f1e57`; overlay свежий; `cabal test` 279/0.
**Cross-references:** метод-extract + Phase 0 HANDOFF (reuse-vs-build, Банкир, конвенции); мемо §3–4; `Domain/Dignities.hs`, `Domain/StrengthAnalysis.hs`, `Domain/Aspects.hs`, `Domain/Houses/`, `Domain/Directions.hs` (house-ruler паттерн), `Domain/Stellium.hs` (НЕ годится для Джонса — per-house).
**Не в scope:** A2 schema-gate, Phase B толкование+выдача, фикс.звёзды.
**Ready: yes** — метод доказан Phase 0, build-карта дана, решения locked.
