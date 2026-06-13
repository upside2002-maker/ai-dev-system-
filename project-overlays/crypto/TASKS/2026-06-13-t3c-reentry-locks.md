# TASK: t3c-reentry-locks

- Status: review
- Ready: yes
- Date: 2026-06-13
- Project: crypto
- Layer: core
- Risk tier: A
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus)
- Mode: strict
- Critical approved by: (нет)
- Reviewer: (обязателен — независимая сессия, tier A)

## Problem

Третий кусок ядра CPDS: блокировки перезахода (запрет ФОМО). Три чистые
функции: (1) `createSaleLock` — по продаже формирует блокировку (цена
продажи, qty, время, условия сброса из профиля, status=active); (2)
`evaluateResets` — для активных блокировок проверяет формальные условия
сброса (дизъюнкция: любое выполненное → reset); (3) `canReenter` — главный
инвариант: покупка по цене ВЫШЕ цены продажи при активной блокировке
ЗАПРЕЩЕНА; дешевле — разрешена; после сброса — свободна. Архитектура §9.3
(блокировки/сброс), §9.5 (инвариант 4). Журналы не пишутся (обвязка),
ворота и сборка решения — Т-3d.

## Files

Репозиторий /Users/ilya/Projects/crypto-platform (master):

- new: core/src/Reentry.hs — `createSaleLock`, `evaluateResets`, `canReenter`.
  Переиспользовать Fixed8/парсер из принятого ядра и `classifySignal` из
  Signal.hs (для условия сброса по капитуляции). Без float.
- new: core/test/ReentrySpec.hs — property + табличные тесты на инварианты.
- modify: core/cpds-core.cabal — подключить модуль и тест.
- modify: (в ai-dev-system — только этот TASK при сдаче + свой HANDOFF)

## Логика сброса (зафиксировать точно)

Условия сброса — дизъюнкция (любое выполненное сбрасывает блокировку):
- `drawdown_pct`: текущая цена ≤ цена_продажи × (1 − drawdown_pct).
  **v1-упрощение:** просадка считается от ЦЕНЫ ПРОДАЖИ, не от «пика после
  продажи» (пик требует истории, которой у ядра-функции от одного снимка
  нет; схема снимка не несёт peak_since_sale, менять её нельзя).
  Зафиксировать это упрощение в HANDOFF и `KNOWN_LIMITATIONS.md` (новый
  пункт: уточнить до «пика после продажи», когда обвязка начнёт прокидывать
  пик).
- `valuation_low_zone`: зона семьи `valuation` в снимке ∈ {cheap, capitulation}.
- `capitulation`: `classifySignal(...)` на текущем снимке+профиле = Capitulation.
- `timeout_months`: (год×12+месяц снимка) − (год×12+месяц продажи) ≥
  timeout_months. Календарно из ISO-дат, без float, без приблизительных «30 дней».

`canReenter(asset, price, locks)`: запрещён, если существует АКТИВНАЯ
блокировка по этому активу с `sale_price < price` (покупаем дороже, чем
продавали). Разрешён, если все активные блокировки актива имеют
`sale_price ≥ price` (покупаем не дороже) либо активных нет.

## Do not touch

- Signal.hs, Profit.hs — приняты; только импорт, логику не менять.
- Gate.hs, CpdsStub.hs — поведение CLI прежнее (Observe); подключение — Т-3d.
- Canonical.hs, Json.hs, Sha256.hs, schemas/, platform/ — не трогать.
- Никаких Double/Float (grep). Никакой сети/ключей. Журналы не писать.

## Acceptance

- [x] `make check` зелёный с чистого клона; тесты Reentry добавлены и проходят.
- [x] Инвариант 4 (§9.5, главный): при активной блокировке `canReenter`
  по цене > цены продажи = ЗАПРЕЩЕНО; по цене ≤ цены продажи = разрешено
  (property-тест на произвольных ценах и наборах блокировок).
- [x] Сброс снимает запрет: после `evaluateResets`, переведшего блокировку
  в reset, `canReenter` этой блокировкой больше не ограничивается (тест).
- [x] Дизъюнкция сброса: любое ОДНО выполненное условие сбрасывает; ни одно
  не выполнено → блокировка остаётся active (табличные кейсы на каждое из
  четырёх условий по отдельности + кейс «ни одно»).
- [x] Критичность: `critical_ok=false` → сбросы по `capitulation` и
  `valuation_low_zone` НЕ срабатывают (нельзя подтвердить без он-чейн);
  `drawdown` и `timeout` срабатывают (он-чейн не нужен). Тест.
- [x] Несколько блокировок на актив: перезаход запрещён, если хоть одна
  активная с `sale_price < price`; активные блокировки другого актива не
  влияют (тест).
- [x] timeout календарный (год/месяц), без float и без «30 дней»; граничные
  кейсы (ровно timeout_months, на месяц меньше/больше).
- [x] В Reentry.hs нет Double/Float (grep); детерминизм (одинаковый вход →
  одинаковый результат).

## Context

- Архитектура: `ai-dev-system/docs/CRYPTOBOT_ARCHITECTURE_2026-06-12.md`
  §9.3 (блокировка создаётся каждой продажей; сброс — любое из условий),
  §9.5 (инвариант 4 — перезаход дороже при активной блокировке невыразим).
- Схема-истина: `crypto-platform/schemas/sale_lock_journal.schema.json`
  (sale_price, reset_rules: drawdown_pct/valuation_low_zone/capitulation/
  timeout_months, status active|reset), `market_snapshot.schema.json`
  (зона valuation, meta.date), `profile_config.schema.json` (reset_rules).
- Принятые Т-3a/Т-3b: `archive/` + Signal.hs/Profit.hs (переиспользовать
  Fixed8 и classifySignal, не плодить).
- Кусок 3/4 ядра. Дальше: Т-3d сборка решения (actions[] + ворота +
  профили + min_net_profit-gate + ManualReview >5%) — связывает Т-3a/b/c
  в decideModule+riskGate и подключает к выходу CLI.
- Mode strict: денежное сердце (MODES: A→strict).
