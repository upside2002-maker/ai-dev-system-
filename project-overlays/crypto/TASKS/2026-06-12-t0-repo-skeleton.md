# TASK: t0-repo-skeleton

- Status: open
- Ready: yes
- Date: 2026-06-12
- Project: crypto
- Layer: infra
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code (Opus)
- Mode: normal
- Critical approved by: (нет)
- Reviewer: (обязателен — независимая сессия; схемы и канонизация — фундамент денежного учёта)

## Problem

Создать каркас репозитория продукта `~/Projects/crypto-platform` — фундамент
этапа «данные и стенд» по архитектуре v1.1. Три кита задачи: (1) схемы-контракты
снимка дня, четырёх журналов, профиля и решения как JSON Schema — единственный
источник истины для Python и Haskell; (2) каноническая сериализация с хэшами,
дающая одинаковый хэш из обоих языков; (3) болванка боевого ядра (риск-ворота +
заглушка модуля CPDS), которая на любом входе без валидных критичных данных
отвечает «наблюдение: данных нет» и никогда не предлагает денежных действий.
Никакой бизнес-логики стратегий в этой задаче нет.

## Files

Всё — в НОВОМ репозитории `~/Projects/crypto-platform` (git init входит в задачу):

- new: README.md                         — карта репо, как запускать проверки
- new: Makefile                          — `make check` (единая точка: схемы + тесты обоих языков + кросс-хэш)
- new: schemas/*.schema.json             — market_snapshot, lot_journal, realized_profit_journal, distribution_journal, sale_lock_journal, profile_config, decision_output (поля — архитектура §3.2, §9.1, §10; в decision_output: actions[] атомарные, data_rights, estimated_net_profit в атомах; в realized_profit_journal: realized_net_profit)
- new: golden/*.json                     — золотые образцы: по 1–2 валидных и 1 невалидному на схему + образец DecisionInput/DecisionOutput
- new: platform/ (Python-пакет)          — canonical.py (каноническая сериализация + SHA-256), validate.py (валидация по схемам), тесты pytest
- new: core/ (Haskell, cabal-проект)     — типы по схемам, Canonical.hs (та же канонизация), Gate.hs (риск-ворота: пропуск/отказ по data_rights), CpdsStub.hs (заглушка модуля: всегда Observe), CLI `cpds-core`: DecisionInput JSON на stdin → DecisionOutput JSON на stdout; тесты
- new: docs/CONTRACTS.md                 — краткая карта схем и правил канонизации (для будущих задач)

- modify: (в ai-dev-system — только этот TASK при сдаче: Status, HANDOFF-ссылка)

## Do not touch

- Любые файлы ai-dev-system кроме этого TASK-файла и своего HANDOFF.
- Никаких сетевых вызовов, ключей, секретов, обращений к биржам — в этой
  задаче их нет по определению.
- Никакой логики семей скоров, порогов, профильных значений — только типы
  и заглушки (логика придёт в Т-3 отдельным TASK).

## Acceptance

- [ ] `make check` зелёный одной командой с чистого клона (документировано в README).
- [ ] Все золотые образцы валидируются против схем; невалидные образцы отвергаются (негативные тесты есть).
- [ ] Кросс-языковый хэш: для каждого золотого образца хэш из Python == хэш из Haskell (тест в `make check`). Канонизация: ключи отсортированы, денежные числа — строки фиксированной точности, время — UTC ISO-8601, NaN/бесконечности запрещены (архитектура §10).
- [ ] `echo '{}' | cpds-core` и подача снимка с `critical_ok=false` → валидный DecisionOutput: `actions=[Observe]`, `data_rights=observe_only`, предупреждение «нет права на денежные решения»; денежных атомов в выходе нет ни на каком входе (заглушка).
- [ ] DecisionOutput болванки проходит валидацию по schemas/decision_output.schema.json.
- [ ] В репо нет ни одного запроса в сеть (проверка ревьюером по коду).

## Context

- Архитектура (источник истины): `ai-dev-system/docs/CRYPTOBOT_ARCHITECTURE_2026-06-12.md` — §3.2 снимок, §9 боевой контур (ворота+модули, actions[], data_rights), §9.5 инварианты, §10 журналы + канонизация + один источник схем, §13 строка Т-0.
- Концепт: `docs/CRYPTOBOT_CPDS_CONCEPT_2026-06-12.md` §6-к (контракт ядра), §6-л (труба стратегии — не реализуется здесь, только не противоречить).
- Мандат: `charters/crypto-bot.md` (красные линии §3 — прочитать до старта).
- Решение по слову Owner'а 12.06: этап «данные и стенд» открыт; живых денег нет нигде.
- Кто за чем: эта задача — фундамент для Т-1 (сборщики), Т-3 (ядро всерьёз, Tier A strict). Сюда бизнес-логику не тащить.
