# TASK: pdf-transit-rule-description-text-fix

- Status: done
- Ready: yes
- Date: 2026-05-09
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code
- Mode: light

## Problem

После Tier A `important-transit-planets-rule-fix` (commit `7b86cf9`) и Tier C `pdf-transit-reason-ru-cleanup` (commit `2ffa002`) per-planet labels в PDF теперь корректно показывают 5 продуктовых правил Архиповой. Но **header-prose** в template'е `solar.html.j2:499` остался описанием старого 4-rule engine'а:

```
Правило отбора: управитель Асц + управитель MC + планеты 10 дома + король аспектов.
```

Это вводит читателя (Марину/клиента) в заблуждение:
- упоминается «планеты 10 дома» — критерий, который больше не входит в `ImportantTransitReason` enum
- отсутствуют 2 новых правила: `управитель знака Солнца` и `управитель знака стеллиума`
- отсутствует дублирующий-управитель exception для Водолея / Рыб / Скорпиона
- header врёт про 4 правила, тогда как список ниже показывает 5

Reviewer Tier A не флагнул эту строку (out of scope: Tier A был ограничен core+schema+TS+fixtures, presentation explicitly out per Do not touch). Обнаружено TL'ом при post-Tier-C re-render для Marina product check (`/tmp/astro-natalya-after-tier-a-2ffa002.pdf`).

## Files

- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2:499` — заменить hardcoded prose описания правила отбора на текст, точно соответствующий 5-правильной логике + dual-ruler exception. 1 строка содержательного изменения (можно разбить на 2 для читабельности).

## Do not touch

- `core/astrology-hs/**`, `packages/**`, `apps/**`, `services/api-python/app/pdf/builder.py` (dict уже исправлен в `2ffa002`), любые другие участки template'а.
- Per-planet rendering loop (`solar.html.j2:502-512`) — он работает корректно через `tr_transit_reason` хелпер, не трогаем.
- `solar.html.j2:415` — упоминание «управитель Асц» в формулах домов, другая семантика, не часть этого fix'а.

## Acceptance

- [ ] `pytest` 70 passed / 0 failed (template-only edit, no Python код).
- [ ] `git show --stat HEAD` показывает ровно 1 файл (`services/api-python/app/pdf/templates/solar.html.j2`).
- [ ] 1 atomic commit поверх `2ffa002`.
- [ ] Re-render Натальи (`/tmp/render_natalya_2ffa002.py` → новое имя): `pdftotext ... | grep "Правило отбора"` показывает только новый текст с 5 правилами, без «планеты 10 дома».
- [ ] Список из 5 правил в prose **терминологически совпадает** с per-planet labels из `_TRANSIT_REASON_RU` dict (в т.ч. «управитель знака Солнца», «управитель знака стеллиума» — тот же word order).
- [ ] Dual-ruler exception (Водолей / Рыбы / Скорпион) явно упомянут в prose.

## Context

- Mode `light` (Tier C); same-session TL inline. No Worker, no Reviewer.
- Baseline: `astro:2ffa002`, pytest 70/70.
- Trigger: TL post-render check перед Marina product feedback. Принято решение не показывать артефакт со stale prose (cost: один лишний цикл review с Мариной на уже-исправленный fact).
- Терминологический выбор:
  - matched dict word order: «управитель знака Солнца», не «управитель солнечного знака»
  - matched dict word order: «управитель знака стеллиума», не «управитель стеллиумного знака»
- Двойной управитель exception: Водолей (Сатурн+Уран), Рыбы (Юпитер+Нептун), Скорпион (Марс+Плутон). В prose упоминаются только знаки — детали в самом списке per-planet видно через accumulate.

**Execution isolation**: same-session TL inline accepted (Tier C mechanical, ≤2 lines text change).
