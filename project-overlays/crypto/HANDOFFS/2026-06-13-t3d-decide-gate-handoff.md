# HANDOFF: t3d-decide-gate

- Дата: 2026-06-13
- Задача: TASK `2026-06-13-t3d-decide-gate` (crypto, layer core, tier A, mode strict)
- Репозиторий: `/Users/ilya/Projects/crypto-platform` (master)
- Worker: Claude Code (Opus) — ФИНАЛИЗАЦИЯ (предыдущий Worker оборван на финале внешним сбоем; код был написан, не закоммичен)
- Статус задачи: review (open → in-progress → review)

## Summary

Последний кусок ядра CPDS (4/4) — сборка решения. Заглушка `CpdsStub` заменена
настоящим `Cpds.decideModule` (предлагает атомы по сигналу, на принятых
Signal/Profit/Reentry), риск-ворота `Gate` усилены (порог прибыли §9.3, лимиты
профиля и красная линия §9.4, проброс блокировок). Впервые в выходе ядра МОГУТ
появиться денежные атомы — но строго в рамках ворот; РЕГРЕСС §9.5 инв.3
(`critical_ok=false` → observe_only, денег нет) сохранён. Новый сьют
`core/test/DecideSpec.hs` — 43 интеграционных/property теста на все 7 пунктов
Acceptance. `make check` зелёный из чистого клона. Никаких Double/Float, журналов,
сети, ключей; schemas/ не тронуты — выход валиден по `decision_output.schema.json`.

Я — финализирующий Worker. Код предыдущего НЕ переписывал; реальных поломок не
нашёл (всё зелёное, диверсии ловятся). Доделал: протокольный прогон чистого
клона, ещё две диверсии (порядок атомов, красная линия) + повтор первой
(critical_ok), строку KNOWN_LIMITATIONS про v1-приближение доли (предыдущий не
добавил), осмысленные коммиты, чистку рабочего дерева от чужих артефактов
компиляции, этот HANDOFF.

## Сделано (по каждому пункту Acceptance)

1. **`make check` зелёный с чистого клона; DecideSpec добавлен; прежние сьюты целы.**
   Сделал свежий `git clone` репозитория в `/tmp/t3d-verify` НА УЖЕ
   ЗАКОММИЧЕННОМ HEAD и прогнал `make check` с нуля (новый `.venv` и
   `dist-newstyle`). Все стадии зелёные:
   - Python-тесты (валидация схем + канонизация + хэши + контур данных) — pass;
   - 5 Haskell-сьютов: **core 27, profit 36, signal 44, reentry 50, decide 43**
     (итого 200 кейсов);
   - кросс-хэш Python↔Haskell — 8/8 золотых совпали;
   - злой корпус — 24 валидных (кросс-хэш совпал) + 17 невалидных (оба языка
     отвергли), расхождений нет;
   - приёмка CLI — пройдена (пустой `{}` и `critical_ok=false` → observe_only).
   Сьют `cpds-decide-test` подключён в `cpds-core.cabal`. Кросс-хэш и злой корпус
   целы (модуль не трогал канонизацию/хэши).

2. **РЕГРЕСС (главный, §9.5 инв.3): `critical_ok=false` → observe_only.**
   `Gate.gate` ловит `not (criticalOk snap)` РАНЬШЕ построения входа модуля и
   возвращает `noRights` — ровно один `Observe` с причиной, `data_rights =
   observe_only`, денежные атомы невыразимы по построению (их там физически
   неоткуда взять), предупреждение «нет права на денежные решения»,
   `human_review_required=false`. Тесты `tRegress`: `critical_ok=false` при зонах
   extreme → `["Observe"]`, без денег, предупреждение на месте; плюс `{}` и
   непарсимый вход; плюс прямой модульный гейт `Unconfirmed → [Observe]`.

3. **Перегрев + `net ≥ min_net_profit` → `[TakeProfit, DistributeProfit, CreateSaleLock]`.**
   `Cpds.overheat` считает `computeNetProfit` на лотах+траншем+ценой снимка, и
   при `net ≥ min` собирает тройку СТРОГО в этом порядке (`takeProfitTriple`).
   Тест проверяет **равенство** списка атомов (не «содержит») → перестановка/
   лишний/недостающий валит. Σ распределения = net проверена интеграционно через
   `allocateProfit (net, карта) → Σ сумм == net` (§9.5 инв.1). `distribution_plan`
   несёт доли карты профиля (K1/K2/K3); `estimated_net_profit` одинаков у
   TakeProfit и DistributeProfit; `position_pct` = транш.

4. **Перегрев, `net < min_net_profit` → Observe (невыгодно), денег нет.**
   `overheat`: `net < minNet` → один `Observe` с причиной «фиксировать
   невыгодно». Тесты: `net=1520 < min=2000000` → `["Observe"]`, без денег, права
   full; перегрев без лотов (нет позиции) → Observe; граница `net РОВНО = min` →
   тройка разрешена (нестрогое `≥`).

5. **Капитуляция + `canReenter` / активная блокировка.**
   `Cpds.capitulation`: `BuyDipFromBuffer` долей `buyback_per_event_pct` ТОЛЬКО
   если `canReenter asset price locks` разрешает; иначе `Observe` (перезаход
   заблокирован); `buyback ≤ 0` → Observe. Тесты: нет блокировок → BuyDip;
   активная блокировка дешевле (sale 25000 < price 30000) → Observe; reset →
   BuyDip; активная не дешевле (sale 30000 ≥ price 30000) → BuyDip; блокировка
   ДРУГОГО актива (ETH) не влияет на BTC. `BuyDipFromBuffer` несёт
   `estimated_net_profit = 0.00000000` (покупка, реализованной прибыли нет — ровно
   ноль, не «неизвестно»; удовлетворяет условную обязательность схемы).

6. **Доля > `max_unconfirmed_action_pct` → ManualReview; транш > 5% → ManualReview в любом профиле.**
   `Gate.applyLimits`: любое действие с `position_pct > max_unconfirmed` → к
   списку добавляется атом `ManualReview` (через него `human_review_required=true`)
   + предупреждение, денежные предложения НЕ исполняются молча. Красная линия §9.4
   (`redLineTranche = 0.05000000 ×10^8`): транш ФИКСАЦИИ (TakeProfit/CreateSaleLock)
   > 5% → ManualReview В ЛЮБОМ профиле, даже при щедром `max_unconfirmed`. Тесты:
   транш 0.04 > max 0.02 → ManualReview + список `[TP,DP,CSL,ManualReview]`; доля ≤
   max → нет ManualReview; красная линия на ТРЁХ профилях (conservative 0.06/maxUnconf
   0.10; balanced 0.07/0.10; aggressive 0.08/0.20) → ManualReview несмотря на щедрый
   max; транш РОВНО 0.05 (= линия, строгое `>`) и ≤ max → нет ManualReview; красная
   линия НЕ срабатывает на обратном ходе буфера (BuyDipFromBuffer — это
   `max_unconfirmed`, а не транш фиксации).

7. **Выход валиден по схеме на наборе входов; CLI-приёмка цела; нет Double/Float; детерминизм; price>0 в Reentry.**
   - Структура выхода: обязательные поля присутствуют и нужного типа; денежные/
     долевые поля — СТРОКИ фикс. точности (валидаторы `validFraction`/`validMoney`
     по pattern схемы); хэши длиной 64. Полная JSON-Schema-валидация выхода идёт в
     `make check` (Python golden `decision_output/valid.2.json` + cli-accept).
   - CLI-приёмка (`scripts/cli_accept.sh` в `make check`): `{}` и `critical_ok=false`
     по-прежнему observe_only — зелёная.
   - Детерминизм: один вход → байт-в-байт одинаковый канон выхода (тест на
     `Canonical.canonicalText`).
   - `grep -E "Double|Float"` по `Cpds.hs`/`Gate.hs`/`Types.hs`/`Render.hs`/
     `DecideSpec.hs` — совпадения ТОЛЬКО в комментариях («никаких Double/Float»,
     «float во входе/выходе»), ни одного типа в коде.
   - Предусловие `price > 0` задокументировано в `Reentry.hs` (haddock к
     `canReenter`) — добавлено в этой задаче, логика не тронута.

## Как собран decideModule + riskGate

**`Cpds.decideModule :: ModuleInput -> [Action]`** — чистая детерминированная
функция «структурированный вход → список предлагаемых атомов». Про JSON не знает
(это ворота). Ветвление по `SignalState` (классификация уже посчитана воротами
через `classifySignal`, логика сигнала не дублируется):
- `OverheatStrong`/`OverheatMild` → транш `strong_overheat_pct`/`normal_pct`;
  `computeNetProfit` (переиспользует Profit) → при `net ≥ min` тройка
  TakeProfit→DistributeProfit→CreateSaleLock (`allocateProfit` по distribution_map),
  иначе Observe;
- `Capitulation` → BuyDipFromBuffer при `canReenter` (переиспользует Reentry),
  иначе Observe;
- `Neutral`/`Unconfirmed` → Observe.

**`Gate.decide :: String -> Json`** (ворота РЕШАЮТ, модуль ПРЕДЛАГАЕТ):
1. `parseJson` → нет/кривой → `noRights` (observe_only);
2. нет snapshot / `critical_ok=false` → `noRights` (РЕГРЕСС §9.5 инв.3);
3. `critical_ok=true`, но профиль/семьи не разбираются → `noRights` (деньги без
   полностью валидных данных невыразимы — второй пояс инв.3);
4. иначе `buildModuleInput` (единый разбор JSON в одном месте: профиль, пять зон
   семей, транши, карта, корзины, лимит `max_unconfirmed`, лоты, блокировки,
   целевой актив) → `Cpds.decideModule` → `applyLimits` (лимиты профиля + красная
   линия) → `DecisionOutput` с `data_rights=full`, хэшами входа/конфига и
   `core_version`.

Целевой актив v1: лексикографически первый тикер с открытыми лотами; нет лотов →
первый тикер снимка (для обратного хода капитуляции лоты не нужны).

## v1-приближение доли (что зафиксировал, где)

Лимиты профиля (`max_unconfirmed_action_pct`) и красная линия §9.4 («транш > 5%
→ ManualReview всегда») в v1 сравнивают **долю ПОЗИЦИИ актива** (`position_pct`),
а НЕ долю денежного капитала всего портфеля. Полной стоимости портфеля (Σ по всем
активам в деньгах) ядро пока не знает — вход несёт лоты и цены, но не
агрегированную капитализацию. Для одного актива доля позиции ≈ доля капитала; при
многоактивном портфеле они расходятся. Приближение санкционировано ТЗ как явное
v1-упрощение.

Зафиксировано:
- **HANDOFF** — этот раздел + «Отклонения».
- **`KNOWN_LIMITATIONS.md`** — новая строка `Я-2` (раздел «Сборка решения — ядро
  CPDS»): мерить долю как (объём действия в деньгах ÷ стоимость портфеля), когда
  вход понесёт полную стоимость портфеля; правка точечная в `Gate.applyLimits`.
- **Haddock `Gate.hs`/`Cpds.hs`** — блок про v1-приближение доли позиции.

Попутно зафиксировал и второе v1-упрощение того же модуля (присутствует в коде):
**комиссии/спред = 0** (`miFees = 0`) — контракт входа их не несёт, схему менять
нельзя; прогноз net оптимистичен на величину комиссий. Строка `Я-3` в
KNOWN_LIMITATIONS; арифметика `computeNetProfit` комиссии уже учитывает, нужен
только источник числа.

## Артефакты (пути, коммиты)

Репозиторий `crypto-platform` (master):
- `core/src/Cpds.hs` — новый модуль `decideModule` (заменяет `CpdsStub`).
- `core/src/CpdsStub.hs` — УДАЛЁН (заглушка Т-0; роль перешла к Cpds).
- `core/src/Gate.hs` — усиленные ворота (порог прибыли, лимиты профиля, красная
  линия, проброс блокировок, импорт Cpds вместо CpdsStub).
- `core/src/Types.hs` — `DistributionPlan` + денежные поля `Action`
  (position_pct, estimated_net_profit, distribution_plan), `isMoneyAtom`.
- `core/src/Render.hs` — сериализация новых полей строками фикс. точности.
- `core/src/Reentry.hs` — ТОЛЬКО haddock предусловия `price > 0` (логика не тронута).
- `core/test/DecideSpec.hs` — новый сьют (43 кейса).
- `core/test/Spec.hs` — `gateValidOk` приведён к новому поведению (неполный
  профиль при critical_ok=true → observe_only; цена в фикс. точности).
- `core/cpds-core.cabal` — library: `Cpds` вместо `CpdsStub`; test-suite
  `cpds-decide-test`; обновлены synopsis/description.

Коммиты (master, реальные SHA):
- `117c1e9` feat(core): денежные поля Action в контракте выхода (Types + Render).
- `adbb6dc` feat(core): настоящий decideModule вместо заглушки CpdsStub (Cpds +
  удаление CpdsStub + cabal: library Cpds и test-suite cpds-decide-test).
- `e2eda6a` feat(core): усилить риск-ворота — лимиты профиля и красная линия (Gate).
- `c6f1750` docs(core): задокументировать предусловие price>0 в canReenter (Reentry).
- `6836f9b` test(core): сьют DecideSpec + поправка Spec под новые ворота.

(Примечание: stanza `cpds-decide-test` в cabal попала в коммит `adbb6dc` вместе с
wiring модуля — это build-target новой пары модуль+сьют. Сообщение коммита
`6836f9b` упоминает её как контекст; на содержимое и чистоту дерева это не влияет.)

Репозиторий `ai-dev-system` (только разрешённые файлы):
- TASK `2026-06-13-t3d-decide-gate.md` — Status → review.
- `KNOWN_LIMITATIONS.md` — новые строки `Я-2` (доля позиции вместо капитала) и
  `Я-3` (комиссии = 0).
- этот HANDOFF.

## Как проверить

```
cd /Users/ilya/Projects/crypto-platform
export PATH="$HOME/.ghcup/bin:$PATH"
make check                       # всё зелёное; в т.ч. cli-accept (РЕГРЕСС observe_only)
```

Только сьют решения:
```
cd core && cabal test cpds-decide-test --offline   # All 43 decide tests passed.
```

Регресс observe_only (внутри make check, стадия cli-accept):
```
CPDS="$(cd core && cabal list-bin cpds-core)"; echo '{}' | "$CPDS"   # observe_only, [Observe], без денег
```
(в DecideSpec — раздел `tRegress`: critical_ok=false при extreme зонах → без денег.)

Греп-гард (требование ТЗ):
```
grep -nE "Double|Float" core/src/Cpds.hs core/src/Gate.hs core/src/Types.hs core/src/Render.hs   # только в комментариях
```

Проверка чистого клона (как делал сам, на закоммиченном HEAD):
```
git clone /Users/ilya/Projects/crypto-platform /tmp/t3d-verify
cd /tmp/t3d-verify && make check    # === make check: ВСЁ ЗЕЛЁНОЕ ===
```

## Diversion-проверка (все 3 — тесты реально ловят нарушения)

Проверял на ИДЕНТИЧНОЙ копии кода (рабочее дерево; реальный репозиторий при этом
не трогал), каждую диверсию ОТКАТИЛ и переподтвердил зелёный прогон. После всех
трёх файлы байт-в-байт совпадают с закоммиченным состоянием.

| № | Диверсия (намеренная поломка) | Что обязано покраснеть | Результат |
|---|---|---|---|
| 1 | Снять гейт `critical_ok` в `Gate.gate` (`not (True)`) | РЕГРЕСС: critical_ok=false → денежные атомы | **2 теста красные** — «РЕГРЕСС: critical_ok=false → observe_only, ровно [Observe], без денег» и «даже зоны extreme при critical_ok=false НЕ дают денег». (`{}`/непарсимый — зелёные, т.к. ловятся раньше, на parse/Nothing-гарде — корректно.) |
| 2a | Сломать порядок атомов в `Cpds.takeProfitTriple` (первый атом CreateSaleLock вместо TakeProfit) | целевой тест порядка | **8 тестов красные**, в т.ч. «перегрев, net ≥ min → атомы [TakeProfit, DistributeProfit, CreateSaleLock] СТРОГО в порядке» и «decideModule: OverheatStrong → [TakeProfit, DistributeProfit, CreateSaleLock]». Строгое равенство списка поймало перестановку. |
| 2b | Ослабить красную линию в `Gate.hs` (`redLineTranche` 5% → 100%) | тесты красной линии >5% | **ровно 3 теста красные** — три профиля (conservative/balanced/aggressive) с траншем 0.06/0.07/0.08 > 5% при щедром max_unconfirmed перестали давать ManualReview. Несвязанные тесты (граница 0.05, обратный ход буфера) остались зелёными — линия меряется именно как >5%, независимо от `max_unconfirmed`. |

Все три диверсии пойманы целевыми тестами. **Дыр не найдено** — дозаписывать
тесты или отмечать риск не потребовалось. Зелёный прогон не маскирует подмену
логики (равенства на списке атомов и на отсутствии денег, а не «содержит»).

## Отклонения

1. **v1: доля = доля позиции, не доля капитала** (KNOWN `Я-2`). Санкционировано
   ТЗ как явное v1-приближение; зафиксировано в KNOWN/HANDOFF/haddock.
2. **v1: комиссии `miFees = 0`** (KNOWN `Я-3`). Контракт входа комиссий не несёт,
   схему менять нельзя; прогноз net оптимистичен на величину комиссий. Арифметика
   `computeNetProfit` их уже учитывает — нужен лишь источник числа во входе.
3. **`Spec.hs/gateValidOk` изменён по поведению.** В каркасе Т-0 заглушка на ЛЮБОМ
   профиле возвращала full+Observe. Теперь ворота читают профиль и при неполном
   профиле (нет весов/траншей/карты) честно деградируют в observe_only (деньги
   требуют полностью валидных данных — второй пояс инв.3). Тест приведён к новому,
   более строгому контракту; это усиление, не ослабление безопасности.
4. **stanza `cpds-decide-test` в cabal попала в коммит `adbb6dc`** (с wiring
   модуля), а не в тестовый коммит `6836f9b`. Это build-target новой пары
   модуль+сьют; на чистоту дерева и сборку не влияет (интерактивный split хунков
   одного файла в этой среде недоступен).

## Заметка о чистке рабочего дерева

В рабочем дереве `crypto-platform` лежали ЧУЖИЕ артефакты компиляции
`core/src/Signal.hi` и `core/src/Signal.o` (вероятно от ручного `ghc`-запуска;
оба покрыты `.gitignore` через `*.hi`/`*.o`, в индекс не попадали). Удалил, чтобы
оставить дерево чистым. `.gitignore` НЕ трогал (правила `*.hi`/`*.o`/`dist-newstyle/`
уже есть). После коммитов и чистки `git status` — пусто.

## Жёсткие рамки — соблюдены

- `Signal.hs`, `Profit.hs` — только импорт/использование, логика не менялась.
- `Canonical.hs`, `Json.hs`, `Sha256.hs` — не тронуты (кросс-хэш и злой корпус
  зелёные).
- `schemas/` — не тронуты; выход валиден по `decision_output.schema.json`
  (golden + cli-accept в `make check`).
- `platform/` — не тронут.
- `Reentry.hs` — только haddock (логика без изменений).
- Никаких `Double`/`Float` (grep чист). Журналы не пишутся (CreateSaleLock —
  ПРЕДЛОЖЕНИЕ атома, не запись). Сети/ключей нет.
- В `ai-dev-system` тронуты только свой TASK, свой HANDOFF и `KNOWN_LIMITATIONS.md`
  (две строки Я-2/Я-3).

## Риски для ревью (на что смотреть особенно)

1. **Денежное сердце: впервые денежные атомы в выходе.** Главное — что они
   появляются ТОЛЬКО при `data_rights=full` (critical_ok=true + валидный профиль)
   и проходят лимиты. Стоит перепроверить, что нет пути «деньги при observe_only»
   (РЕГРЕСС инв.3) — диверсия 1 это покрыла, но это сердце.
2. **Красная линия §9.4 на транше фиксации.** `applyLimits` применяет линию >5%
   к TakeProfit/CreateSaleLock (транш ПРОДАЖИ), но НЕ к BuyDipFromBuffer (обратный
   ход — только `max_unconfirmed`). Стоит подтвердить, что это верное прочтение
   §9.4 (линия — про фиксацию, не про откуп), и что список атомов-«фиксаций» полон.
3. **v1-приближение доли позиции vs капитала** (Я-2) — ревью на согласие с
   формулировкой и записью в KNOWN; при многоактивном портфеле лимиты меряются по
   позиции, не по капиталу.
4. **Целевой актив v1 = первый по алфавиту с лотами / первый тикер снимка.**
   Одноактивный выбор — упрощение Т-3d (один актив на решение). Стоит подтвердить,
   что многоактивная развязка корректно отложена (не молчаливая потеря решений по
   другим активам).
5. **`buildModuleInput` → Nothing деградирует в observe_only.** Любое отсутствие
   обязательного поля профиля гасит деньги. Стоит убедиться, что это не слишком
   агрессивно для валидных, но скромных профилей (хотя осторожность тут желательна).
6. **`estimated_net_profit = 0.00000000` у BuyDipFromBuffer** — «событие без
   прибыли», а не «прибыль неизвестна». Ревью на согласие, что нулевая строка
   удовлетворяет условную обязательность схемы и не вводит в заблуждение.
