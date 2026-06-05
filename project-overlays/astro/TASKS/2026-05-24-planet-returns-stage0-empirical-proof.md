# TASK: planet-returns-stage0-empirical-proof

- Status: open
- Ready: yes
- Date: 2026-05-24
- Project: astro
- Layer: docs (Stage 0 эмпирическая проверка — READ-ONLY анализ через эфемериды; продуктового кода НЕТ)
- Risk tier: B (gate для Tier A эпика «возвраты планет»; сам Stage 0 read-only/reversible)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Перед любым продуктовым кодом для нового standalone `returns`-workflow (см. мемо `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md`) нужно **эмпирически доказать**, что подход «найти ближайший возврат каждой планеты от текущей даты» корректно воспроизводит известные астрономические факты на реальной карте. Трижды-подтверждённый meta-урок проекта (Stage 0 STOP gate): не шить движок под ожидания, пока эфемериды их не подтвердят.

**Возврат планеты** = транзитная планета приходит в тот же градус/минуту/секунду эклиптической долготы, что в натале. Для каждой из 10 планет нужна **первая** дата возврата строго после reference_date (сегодня).

Проверочная карта: **Марина, person_id=4** в `/Users/ilya/Projects/astro/data/astro.db` (натал 1989-03-22 05:34 Europe/Moscow, Ковров).

## Worker framing (методология Марины verbatim)

> «Возврат планеты — это когда Солнце, Луна, Меркурий и т.д. возвращаются в те же градусы, минуты и секунды того знака зодиака, который есть в натальной карте. Солнце — раз в год (~ДР), Луна — раз в месяц, Марс — раз в два года. Найти ближайшие даты возврата всех 10 планет. Высшие планеты — с пометкой.»

## Scope (Stage 0 — READ-ONLY эмпирический proof)

### 0.1 — Натальные долготы Марины

Считать из `facts_json` consultation Марины (или пересчитать через pyswisseph по birth data person 4) натальные эклиптические долготы всех 10 планет (Sun..Pluto). Таблица: планета → долгота (градус/знак/мин/сек).

**Зафиксировать reference_date** = «сегодня» (дата выполнения Worker'ом; задокументировать конкретное значение).

### 0.2 — Ближайший возврат каждой планеты (через pyswisseph)

Для каждой из 10 планет: сэмплить транзитную долготу вперёд от reference_date, найти **первое** пересечение натальной долготы, уточнить дату. Окна семплинга (мемо § 4): Луна ~35 дн, Солнце/Меркурий/Венера ~370-400 дн, Марс ~800 дн, Юпитер ~13 л, Сатурн ~30 л, Уран ~85 л, Нептун ~166 л, Плутон ~249 л.

Выход: таблица «планета → ближайшая дата возврата → период обращения → пометка (если внешняя)».

### 0.3 — Sanity-проверки (это и есть STOP-критерии)

- **Солнце:** ближайший возврат ≈ следующий день рождения Марины (≈ 22 марта). Если Δ > ±2 дня → подход сломан → STOP.
- **Луна:** ближайший возврат в пределах ~27-28 дней от reference. Если вне диапазона → STOP.
- **Марс:** в пределах ~2 лет. **Сатурн** ≈ возраст кратный ~29.5. **Юпитер** ≈ кратный ~12.
- **Внешние:** подтвердить, что Нептун (~165 л) и Плутон (~248 л) дают дату за пределами жизни → флаг `beyond_lifespan` оправдан. Уран (~84 г) — раз в жизнь.

### 0.4 — Retro-кейс (критично для дизайна)

Найти хотя бы одну планету, которая **у своего возврата ретроградит** (транзитная долгота пересекает натальную несколько раз в ретро-петле). Разобрать: сколько проходов, какой «истинный возврат», как нумеровать (pass_number). Если ни одна из 10 у ближайшего возврата не ретроградит — синтетически подтвердить логику на гипотетическом примере. Документировать поведение retro-aware брекетера (вход для Phase B `Domain.TransitMath`).

### 0.5 — Вывод по reuse

Подтвердить/опровергнуть вывод мемо: `SolarReturn.findSolarReturnJd` НЕ переиспользуется напрямую (его `crossesArc` предполагает только прямое движение). Сформулировать, что именно выносить из `TransitCalendar.hs` в `Domain.TransitMath` для retro-aware nearest-return.

## Files

- new:
  - HANDOFF: `project-overlays/astro/HANDOFFS/2026-05-24-worker-to-tl-planet-returns-stage0-empirical-proof.md` (таблицы 0.1-0.4 + вывод 0.5).
- modify:
  - `project-overlays/astro/STATUS_RU.md` (Stage 0 proof entry).
- delete: —

Может использовать throwaway-скрипты в `/tmp` для pyswisseph-расчётов (НЕ коммитить в продукт).

## Do not touch

- Любой продуктовый код (Haskell core, Python services, frontend) — Stage 0 read-only.
- `solar-computed-facts.schema.json` и solar-фикстуры.
- DB (только чтение person 4).
- `_OUTER_CARD_FACTS`, synthesis_themes, прочие закрытые модули.
- **NO продуктовый код вообще** — анализ-only фаза.
- **NO LLM.**

## Acceptance

- [ ] Таблица натальных долгот 10 планет Марины (0.1).
- [ ] reference_date зафиксирован явно.
- [ ] Таблица ближайших возвратов 10 планет (0.2).
- [ ] Sun-return ≈ ДР (±2 дня) — иначе STOP-эскалация (0.3).
- [ ] Moon-return в ~27-28 дн (0.3).
- [ ] Внешние Нептун/Плутон → дата вне жизни (флаг оправдан) (0.3).
- [ ] Retro-кейс разобран (реальный или синтетический) с pass-нумерацией (0.4).
- [ ] Вывод по reuse: что выносить в `Domain.TransitMath`, почему `findSolarReturnJd` недостаточен (0.5).
- [ ] HANDOFF написан; STATUS_RU обновлён.
- [ ] Один overlay-коммит (HANDOFF + STATUS_RU). Продуктового коммита НЕТ.

## STOP triggers

- Sun-return не совпадает с ДР Марины (±2 дня) → STOP, подход неверен, эскалация до Phase B.
- Worker пишет продуктовый код → STOP (read-only фаза).
- Worker трогает schema / DB-запись / закрытые модули → STOP.
- Worker не может разобрать retro-кейс → документировать как открытый вопрос, НЕ выдумывать.

## Context

**Mode normal + Tier B (read-only proof, gate для Tier A эпика).**

**Baseline:**
- Product main @ `ba806d5` (Useful People Polish landed, ждёт closure).
- Overlay master @ свежий (memo + этот TASK).
- API DB: `/Users/ilya/Projects/astro/data/astro.db` (person 4 = Марина; consultations 13/14/15).
- pyswisseph доступен в `services/api-python/.venv`.

**Cross-references:**
- Мемо: `ARCHITECTURE/planet-cycles-module-architecture-2026-05-24.md` (§ 2 reuse, § 4 окна, § 7 фазы).
- `core/astrology-hs/src/Domain/SolarReturn.hs:48` — `findSolarReturnJd` (прецедент бисекции, monotonic-only).
- `core/astrology-hs/src/Domain/TransitCalendar.hs:330-606` — retro-aware детекция/орб-окна/pass-нумерация (источник выноса).
- Marina natal positions: из DB facts_json person 4 / consultation 15.

**Не в scope:** продуктовый код (Phase B+), самоаспекты/куспиды (волны 2-3), Lilith (волна 5), трактовки (волна 4).

**Ready: yes** — scope определён мемо + решениями владельца 2026-05-24. Stage 0 не требует доп. уточнений (эмпирическая проверка против эфемерид).
