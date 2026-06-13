# HANDOFF: worker → reviewer — t4a-paper-executor

- Status: review
- Date: 2026-06-13
- Project: crypto
- From: worker
- To: reviewer (независимая сессия)
- Agent runtime: Claude Code
- Model: Opus
- Role mode: Worker
- TASK: project-overlays/crypto/TASKS/2026-06-13-t4a-paper-executor.md
- Risk tier: B, mode normal

## Summary

Собран первый кусок бумажного полигона (Т-4а): виртуальный исполнитель.
`apply_decision` применяет `DecisionOutput` ядра к состоянию бумажного счёта по
цене снимка с моделью издержек §7 и обновляет четыре журнала — те самые, что
ядро на следующий день читает как вход. Цикл «снимок → ядро → решение →
исполнение на бумаге → журналы → снова вход ядра» **замкнут и проверен на
реальном собранном cpds-core**. Денежная арифметика — целые ×10^8 (зеркало
`core/src/Profit.hs`), БЕЗ float. `make check` зелёный с чистого клона в /tmp.
core/ и schemas/ не тронуты. Готов к ревью.

## Сделано (по каждому пункту Acceptance)

1. **make check зелёный с чистого клона; тесты на фикстурах.** Проверено сам:
   `git clone` в `/tmp/cpds-clean-verify` (без `dist-newstyle`, без `.venv` из
   git — они ignored), `make check` собрал Haskell офлайн с нуля и прошёл всё
   зелёным (core 27+profit 36+signal 44+reentry 50, кросс-хэш 8, злой корпус
   24/17, cli-accept, Python в т.ч. 22 теста полигона). `/tmp`-клон удалён,
   рабочее дерево чистое.

2. **TakeProfit: realized по факту с издержками; лоты по средневзвешенной;
   запись валидна по схеме (табличный кейс до 1e-8).**
   `test_take_profit_realized_with_costs_table`: 0.5 BTC@30000, продаём 4%
   позиции @68000 →
   - sell_qty = 0.04·0.5 = 0.02 BTC;
   - proceeds = 0.02·68000 = 1360.00000000;
   - fees = 1360·0.002 = 2.72000000 (издержки §7);
   - cost_basis = 0.02·30000 = 600.00000000 (средневзвешенная);
   - **realized = 1360 − 600 − 2.72 = 757.28000000** (ФАКТ < estimated 760 ядра).
   Проверено целыми ×10^8 ровно (= 75728000000). Лоты уменьшаются по
   средневзвешенной (`test_..._reduces_lots_weighted_average`: 0.3@20000 +
   0.2@45000, продаём 10% → lot1 0.27, lot2 0.18, status partial, цена остатка
   средневзвеш. = 30000 цела; cost_basis = 1500 ровно). Полное закрытие →
   status closed, qty 0. Продажа в убыток → realized < 0, схема допускает знак.
   Журнал прибыли валиден по `realized_profit_journal.schema.json`.

3. **DistributeProfit: Σ корзин = realized РОВНО (доли×realized, остаток
   крупнейшей доле); запись валидна по схеме.**
   `test_distribute_sum_equals_realized_exactly`: тройка TakeProfit→Distribute,
   Σ сумм по K1/K2/K3 = realized до 1e-8 (= Σ корзин счёта). Остаток (от floor)
   крупнейшей доле — `test_distribute_remainder_to_largest_share` (доли
   0.5/0.35/0.15, realized=7 → K1=4, K2=2, K3=1). Ничья → первая по
   K1<K1_5<K2<K3 — `test_distribute_tie_goes_to_first_in_order` (4×0.25,
   realized=10 → K1=4, остальные 2). Σ долей ≠ 1.0 → стоп. Зеркало
   `allocateProfit` ядра, но умножает доли на ФАКТ realized, не на прогноз
   (контракт Т-3d). Журнал валиден по `distribution_journal.schema.json`.

4. **CreateSaleLock и BuyDipFromBuffer обновляют журналы/буфер; dip_buy.**
   `test_create_sale_lock_writes_active_lock`: блокировка status=active,
   sale_price = цена снимка, qty = проданное количество (0.02). BuyDip:
   `test_buy_dip_creates_dip_buy_lot_reduces_buffer` — новый лот origin=dip_buy,
   цена входа с издержками = 20000·1.002 = 20040, буфер уменьшен на потраченное
   (1000 → 750), qty = spend/eff_price целочисленно. Пустой буфер → стоп.
   Журналы валидны по `sale_lock_journal`/`lot_journal`.

5. **Observe/ManualReview не меняют состояние.**
   `test_observe_does_not_change_state` и `test_manual_review_does_not_change_state`:
   журналы/буфер/корзины не изменились (сверка `to_dict`), updates пуст, в логе
   событие (ManualReview несёт пометку «ждёт человека»). Доп.:
   `test_observe_only_rejects_money_atom` — денежный атом при
   data_rights=observe_only → ExecutorError (§9.5 инв.3; ядро такое не выпускает,
   исполнитель не проглатывает молча).

6. **Замыкание цикла (интеграционный тест).**
   `test_closed_loop_journals_valid_as_core_input`:
   - из состояния счёта + снимок перегрева (все семьи extreme, critical_ok=true)
     + balanced-профиль собираем `decision_input` → валиден по схеме;
   - гоним **реальный cpds-core** (собран; найден через `cabal list-bin`), он
     даёт денежную тройку TakeProfit→DistributeProfit→CreateSaleLock,
     data_rights=full; выход валиден по `decision_output.schema.json`;
   - `apply_decision` применяет → четыре журнала непусты и валидны каждый;
   - **из обновлённых журналов собираем НОВЫЙ decision_input — снова валиден как
     вход ядра** (цикл замкнут);
   - повторно прогоняем НОВЫЙ вход через ядро — оно не падает на наших журналах
     (полное замыкание день→день).
   Σ распределения = realized держится и на боевой тройке ядра. Есть фолбэк на
   зафиксированный `DecisionOutput`, если ядро не собрано (тест не стал бы
   зелёным «по умолчанию»). В прогоне (рабочем и /tmp-клоне) шла именно ветка с
   реальным ядром. Доп.: `test_closed_loop_buy_dip_then_core_reads` — после
   BuyDip журнал лотов (с dip_buy) снова валиден как вход ядра.

7. **Деньги без float; детерминизм.**
   Вся денежная арифметика — целые ×10^8 (`parse_fixed8`/`render_fixed8`/
   `mul_fixed8`/`div_round_half_up` — зеркало ядра). `test_no_floats_in_money_outputs`:
   `canonical_bytes` журналов проходит (он падает на любом float — это и есть
   греп-проверка), все денежные поля — строки, корзины — int. Детерминизм:
   `test_determinism_same_input_same_journals` — повторное применение даёт
   побайтово равные канонические журналы и равный `to_dict`. Сериализация
   туда-обратно (`to_dict`/`from_dict`) тождественна.

## Модель издержек (что зафиксировал)

Источник истины — `config/paper.yaml` (НЕ код). На каждую сделку к цене снимка
применяются три удержания, суммируемые в одну долю:

- `fee_rate = 0.00100000` (0.10% тейкер — рыночное исполнение в симуляции);
- `spread_rate = 0.00050000` (0.05% половина спреда);
- `slippage_rate = 0.00050000` (0.05% проскальзывание, консервативно);
- **cost_rate = 0.00200000** (0.20% на сделку) — считает исполнитель.

- **Продажа** (TakeProfit): proceeds = qty·price (выручка-брутто, в журнал как
  `proceeds`); fees = proceeds·cost_rate (комиссии+спред+проскальзывание ОДНОЙ
  строкой, как требует схема); realized = proceeds − cost_basis − fees.
  cost_basis — пропорциональная средневзвешенная одной дробью с единственным
  округлением (зеркало `computeNetProfit`).
- **Покупка** (BuyDipFromBuffer): цена входа лота = price·(1 + cost_rate)
  (издержки удорожают вход); из буфера списывается потраченное.

v1: мейкер/тейкер сведены к одной ставке тейкера (на Т-4а типов ордеров нет,
исполнение по цене снимка немедленное). Старт. размеры депо: buffer_start=0.20
(20% депо в буфере обратного хода), depo_unit=1.0 (нормировка §8).

## Замыкание цикла (как проверил)

См. п.6. Главное: `state.journals()` отдаёт журналы ровно в форме схем (без
перекладки), поэтому собранный из них `decision_input` валиден по схеме, и
реальный `cpds-core` читает его без падения и до, и ПОСЛЕ исполнения. Проверено
на собранном ядре (ветка `used_core=True`), не на болванке.

## Артефакты

- repo: /Users/ilya/Projects/crypto-platform, branch master
- commits:
  - 3cfc357 feat(paper): PaperAccount + apply_decision + издержки §7
  - ca14982 test(paper): тесты на 7 пунктов Acceptance + замыкание цикла; docs
- new: platform/cpds_platform/paper/{__init__,account,executor}.py
- new: config/paper.yaml
- new: platform/tests/test_paper_executor.py (22 теста)
- modify: Makefile (комментарий py-test), README.md, docs/CONTRACTS.md
- tests: 22 теста полигона зелёные; полный make check зелёный с чистого клона.

## Как проверить

```
git clone <repo> /tmp/verify && cd /tmp/verify
export PATH="$HOME/.ghcup/bin:$PATH"
make check                       # всё зелёное, Haskell собирается офлайн с нуля
# только полигон:
cd platform && PYTHONPATH=. ../.venv/bin/pytest tests/test_paper_executor.py -q
```

Замыкание на реальном ядре: тест сам находит cpds-core через `cabal list-bin`;
если ядро собрано (после `make check` оно собрано), идёт ветка с реальным
прогоном; иначе — зафиксированный DecisionOutput (тоже валидный, проверено
руками против живого ядра на том же снимке).

## Diversion-проверка

В /tmp-клоне (disposable) внёс диверсию в `_exec_distribute`: «забыл» отдать
остаток крупнейшей доле — `final = amt` всегда вместо
`amt + remainder if i == recipient_ix else amt`. Результат:

```
FAILED test_distribute_remainder_to_largest_share
FAILED test_distribute_tie_goes_to_first_in_order
2 failed, 20 passed
```

Тесты на Σ=realized/остаток покраснели — ловушка работает. Диверсия откатана,
рабочее дерево чистое (правка была только в /tmp-клоне, который удалён).

## Отклонения

- Makefile добавлять отдельную цель НЕ потребовалось: тесты полигона лежат в
  `platform/tests/` и подхватываются `pytest -q` в `py-test`, который уже входит
  в `make check`. Внёс лишь поясняющий комментарий в эхо py-test.
- `MoveBufferToTerminal` (атом из схемы) — НЕ в скоупе Т-4а (ядро его в
  покрытых ветках не выпускает): исполнитель честно отвечает ExecutorError
  «вне скоупа», а не тихим no-op. Реализация — за Т-4b при необходимости.
- Профиль в `DecisionOutput` ядра не приходит, поэтому `CreateSaleLock`
  reset_rules берёт из самого атома, если ядро их положило, иначе пустой объект
  (схема `sale_lock_journal` допускает пустой `reset_rules`). qty блокировки =
  проданное количество последней продажи решения (sale_lock в тройке следует за
  TakeProfit) — это вернее, чем доля от уже урезанной позиции.
- Ветка master напрямую (без PR): следую конвенции репозитория crypto-platform
  (прошлые HANDOFF: «локальная разработка, CI заморожен», коммиты в master).

## Риски для ревью

- **Р-1 (точность лотов на продаже):** остаток sell_qty после floor-распределения
  по лотам добирается с КОНЦА (последний открытый лот с запасом). Σ сожжённого =
  ровно sell_qty (проверено), но конкретное распределение остатка по лотам —
  выбор реализации (не влияет на realized/cost_basis, т.к. средневзвешенная
  считается от всей позиции одной дробью). Если ревью захочет иную политику
  (FIFO-сжигание) — это смена метода, согласовать.
- **Р-2 (округление BuyDip qty):** количество купленного = spend·10^8 / eff_price
  с округлением полу-вверх (единое правило ядра). Знак «полу-вверх» здесь не
  принципиален (величины ≥ 0), но зафиксирован тем же `div_round_half_up`.
- **Р-3 (одна цена снимка = цена исполнения):** Т-4а исполняет по одной цене
  снимка немедленно (нет книги ордеров, нет частичных исполнений). Проскальзывание
  моделируется константой §7. Это сознательное v1-приближение архитектуры §8;
  реалистичнее — за бэктест-движком Т-5.
- **Р-4 (estimated≠realized расхождение):** на табличном кейсе realized=757.28
  при estimated=760 (разница = fees 2.72). Это ОЖИДАЕМО и есть смысл разведения
  §9.3 — не дефект. Ревью стоит убедиться, что нигде факт не подменён прогнозом.
