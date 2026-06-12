# HANDOFF: t0-repo-skeleton

- Дата: 2026-06-12
- TASK: `project-overlays/crypto/TASKS/2026-06-12-t0-repo-skeleton.md`
- Worker: Claude Code (Opus)
- Репозиторий продукта: `/Users/ilya/Projects/crypto-platform` (новый, git init, ветка `master`)
- Статус сдачи: готов к ревью. `make check` зелёный с чистого клона.

## Summary

Каркас репозитория крипто-платформы (Т-0) собран целиком, не заблокирован.
Полный Haskell-тулчейн на машине есть (GHC 9.6.6, cabal 3.14) — Haskell-часть
**собирается и тестируется по-настоящему**, кросс-языковый хэш-тест реальный, а
не заглушка. Все три кита Т-0 на месте: схемы-контракты, каноническая
сериализация с одинаковым хэшем из Python и Haskell, болванка ядра, которая на
любом входе без валидных критичных данных отвечает «наблюдение» и не предлагает
денежных действий. Сети, ключей и обращений к биржам в коде продукта нет.

## Сделано

- **7 схем + вспомогательная** (`schemas/*.schema.json`): market_snapshot,
  lot_journal, realized_profit_journal, distribution_journal, sale_lock_journal,
  profile_config, decision_output; плюс decision_input (композиция для CLI и
  golden). Деньги/доли — строки фикс. точности (`^-?[0-9]+\.[0-9]+$`), время —
  UTC ISO-8601, `additionalProperties:false` везде. В decision_output: `actions[]`
  из атомов (Observe | TakeProfit | DistributeProfit | CreateSaleLock |
  BuyDipFromBuffer | MoveBufferToTerminal | ManualReview), `data_rights`
  (full | observe_only), у денежных атомов `estimated_net_profit`. В
  realized_profit_journal — `realized_net_profit` (факт).
- **Golden** (`golden/`): по 2 валидных и 1 невалидному образцу на схему,
  образцы DecisionInput (валидный critical_ok=true; critical_ok=false; невалидный)
  и DecisionOutput. `golden/manifest.json` — карта golden→схема + набор для
  кросс-хэша. Невалидные образцы бьют по делу (float вместо строки, ts без Z,
  пропуск realized_net_profit, bucket K0, статус вне enum, profile_id вне enum,
  input_hash не SHA-256, пропуск profile).
- **Python-обвязка** (`platform/`): `canonical.py` (сортировка ключей, без
  пробелов, ASCII-only escaping, запрет float/NaN/∞, SHA-256 от канонических
  байт), `validate.py` (валидация по схемам с резолвером локальных $ref),
  `hash_cli.py` (хэш файла для кросс-теста), pytest (35 тестов: позитив/негатив
  валидации, правила канона, отказы, закреплённые хэши золотых образцов).
- **Haskell-ядро** (`core/`, cabal): `Json.hs` (свой парсер), `Sha256.hs` (свой
  SHA-256, проверен на векторах FIPS), `Canonical.hs` (канонизация байт в байт с
  Python), `Types.hs`/`Render.hs` (типы решения и сериализация), `Gate.hs`
  (риск-ворота), `CpdsStub.hs` (модуль №1 — всегда Observe), CLI `cpds-core`
  (stdin DecisionInput → stdout DecisionOutput; подкоманда `hash`), тесты (12).
- **Makefile**: `make check` одной командой — валидация схем + тесты Python +
  тесты Haskell + кросс-языковый хэш-тест + приёмка CLI.
- **README.md** (карта репо, как гонять проверки, что нужно на машине),
  **docs/CONTRACTS.md** (карта схем, словарь атомов, права на данные, правила
  канонизации).

## Артефакты

Пути — в репозитории `/Users/ilya/Projects/crypto-platform`.

Коммиты (ветка master):
- `890d367` t0: схемы-контракты (7 + decision_input) и golden-образцы
- `ae4f599` t0: боевое ядро на Haskell — канонизация, SHA-256, риск-ворота, заглушка CPDS
- `b13f82a` t0: make check (единая точка) + README + карта контрактов

Ключевые файлы:
- Схемы: `schemas/`
- Golden + манифест: `golden/`, `golden/manifest.json`
- Python: `platform/cpds_platform/{canonical,validate,hash_cli}.py`, `platform/tests/`
- Haskell: `core/src/{Json,Sha256,Canonical,Types,Render,CpdsStub,Gate}.hs`, `core/app/Main.hs`, `core/test/Spec.hs`, `core/cpds-core.cabal`
- Проверки: `Makefile`, `scripts/cross_hash.sh`, `scripts/cli_accept.sh`
- Документы: `README.md`, `docs/CONTRACTS.md`

Закреплённые кросс-хэши (Python == Haskell, совпадают):
- market_snapshot/valid.1: `9a9eebd1cb04db0c90d9776d6a1d69dd9ac0511078c41c13b75921bfb963954f`
- decision_input/valid.1: `153a8fe71fb423e498ede779ee82f88e0414b3806277d947907cc172917ec101`
- profile_config/valid.1: `29c1a40d4a76faf0c310553a734465d161ae20ce776cf9ff5f8f27e9e55d34ed`

## Как проверить

```
cd /Users/ilya/Projects/crypto-platform
make check
```

Ожидается финальная строка `=== make check: ВСЁ ЗЕЛЁНОЕ ===`. Проверено с
полностью чистого состояния (`make clean` + `make check`): 35 Python-тестов,
12 Haskell-тестов, 3 кросс-хэша совпали, приёмка CLI пройдена. Холодный прогон ~40 с.

Ручная проверка приёмки CLI:
```
cd core && BIN=$(cabal list-bin cpds-core)
echo '{}' | "$BIN"                                   # observe_only, [Observe], предупреждение
cat ../golden/decision_input/valid.2.critical_false.json | "$BIN"   # то же
cat ../golden/decision_input/valid.1.json | "$BIN"   # full, [Observe], денежных атомов нет
"$BIN" hash ../golden/market_snapshot/valid.1.json   # = 9a9eeb...
```

## Соответствие Acceptance ТЗ

- [x] `make check` зелёный одной командой с чистого клона (документировано в README).
- [x] Все золотые образцы валидируются; невалидные отвергаются (негативные тесты есть).
- [x] Кросс-языковый хэш: для каждого образца хэш Python == хэш Haskell (в make check). Канон: ключи сортированы, деньги — строки, время — UTC ISO-8601, NaN/∞ запрещены.
- [x] `echo '{}' | cpds-core` и снимок с `critical_ok=false` → валидный DecisionOutput: `actions=[Observe]`, `data_rights=observe_only`, предупреждение «нет права на денежные решения»; денежных атомов нет ни на каком входе (заглушка).
- [x] DecisionOutput болванки проходит валидацию по `schemas/decision_output.schema.json` (проверяется в `make cli-accept`).
- [x] В репо нет ни одного сетевого запроса (grep по коду продукта чист; проверяемо ревьюером).

## Отклонения от ТЗ и почему

1. **Имя Python-пакета — `cpds_platform`, а не `platform`.** Каталог
   `platform/` как требует ТЗ, но импортируемый пакет внутри переименован: имя
   `platform` затеняет стандартный модуль `platform`, который тянет зависимость
   `jsonschema` (через `attrs`) — без переименования валидация падала на импорте.
   Каталог и роль не изменились, только внутреннее имя пакета.
2. **Добавлена 8-я схема `decision_input.schema.json`.** ТЗ перечисляет 7 схем;
   вход ядра (§9.1) — композиция снимка + 4 журналов + профиля, нужен для CLI и
   golden-образцов DecisionInput. Это не подмена 7 основных, а вспомогательная
   схема-композиция. Все 7 на месте.
3. **SHA-256 и JSON в Haskell написаны вручную (свои модули).** Не aeson/crypton:
   ради офлайн-сборки `make check` с чистого клона ядро зависит только от пакетов
   из поставки GHC. Это убирает сетевой шаг и хрупкость 60-дневного индекса
   hackage при сборке. Корректность SHA-256 закреплена тестами на известных
   векторах FIPS 180-4.
4. **Сверх ТЗ: цель `cli-accept`** в `make check` (структурная валидация выхода
   заглушки по схеме + проверка observe_only/без-денег). ТЗ требует это как
   Acceptance, я оформил как автоматическую проверку, а не ручную.

## Блокеры

Нет. Haskell-тулчейн присутствует, всё собирается и проходит. Честного блокера
из ТЗ («нет тулчейна») не возникло.

## Риски для ревью (куда смотреть ломателю)

1. **Канонизация — сердце контракта.** Главный риск разъезда — escaping и числа.
   Сейчас: не-ASCII → `\uXXXX` (ASCII-only выход), целые нормализуются
   (`-0`→`0`, ведущие нули срезаются), число с точкой/экспонентой отвергается.
   Стоит атаковать краевыми строками (символы вне BMP — суррогатные пары,
   управляющие символы, уже-экранированные `\u` во входе) и проверить, что
   Python и Haskell дают одинаковые байты. Кросс-хэш сейчас гоняет 3 образца —
   можно добавить «злые» строки в golden и в `manifest.cross_hash`.
2. **Деньги-как-строки не проверяются на арифметическую корректность** — это Т-3.
   Схема ловит формат, но не «realized_net_profit = proceeds − cost_basis − fees»
   и не «сумма распределения = чистой прибыли». Инварианты §9.5 №1 — намеренно НЕ
   здесь. Ревью: убедиться, что мы не протащили арифметику раньше времени (не
   протащили).
3. **Схема decision_output допускает денежные атомы при `observe_only`** — это
   осознанно: схема описывает общий контракт (будущий полноправный модуль выдаёт
   денежные атомы), а запрет денег при observe_only — инвариант риск-ворот, не
   схемы. Проверяется в Gate.hs и тестах, не в JSON Schema. Документировано в
   CONTRACTS.md. Если ревью хочет жёстче — это меняет роль схемы; обсуждаемо.
4. **Заглушка CpdsStub игнорирует вход** — `proposeActions _ = [Observe]`. Это by
   design для Т-0 (денежные атомы невыразимы из заглушки). Ревью: подтвердить, что
   именно такого поведения ждём до Т-3.
5. **`make check` тянет pytest/jsonschema из PyPI при первой установке** (один
   раз, в `.venv`). Это dev-инструменты, не код продукта; в продукте сети нет.
   На офлайн-машине без pip-кэша первый `make check` потребует интернет для двух
   пакетов — отмечено в README. Haskell-часть офлайн полностью.
6. **JSON-парсер в Haskell — минимальный, строгий под наш контракт.** Не
   общего назначения (не для произвольного JSON из мира). Принимает наши схемы;
   на мусоре даёт Left, который Gate трактует как observe_only. Ревью: проверить,
   что нестандартный, но валидный JSON (напр. экспоненты, escape-последовательности
   в ключах) обрабатывается ожидаемо или явно отвергается.
