# TASK: parser-two-word-broad-mode

- Status: done
- Ready: yes
- Date: 2026-05-21
- Project: sitka-office
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)
- Tier judgment call (TL, 2026-05-21): формально файл попадает под `sitka-services/**/*.py` → Tier B (`.claude/risk-tiers.md:88`). Понижен до C на этой задаче: одна строка в vendored package, нет изменений API/auth/shape/migrations, unit-тесты pin'ят регрессию на узком уровне, smoke probe на сервере после deploy = de-facto integration test через wire. Если Reviewer возразит — арбитрирую отдельно.

## Problem

Парсер магазинов отбрасывает валидные товары на двухсловных запросах. Прецедент 2026-05-13: оператор искал «Blizzard parka», все четыре магазина (Rogers / 1shot / ALS / Lancaster) вернули `no_hits`, хотя «Blizzard AeroLite Parka» ($538.30 на 1shot) и «Sitka Blizzard Pro Parka» ($800 на Rogers) реально в наличии.

Корневая причина — в `sitka-services/vendor/inventory_parser/inventory/v2/query.py:113`:

```python
query_mode = "broad" if not size and not color and len(search_tokens) <= 1 else "target"
```

Двухсловный запрос попадает в `target` режим, где `BaseStoreAdapter.title_matches` (`adapters/base.py:452-462`) после проверки матча всех токенов **дополнительно** требует, чтобы фраза целиком (`search_phrase`) была substring в `normalized_title`. У реальных названий между токенами стоит вставка («Blizzard **AeroLite** Parka»), substring не матчится — товар выбрасывается.

Решение: поднять порог `<= 1` → `<= 2`. Двухсловные запросы пойдут в `broad`, где `title_matches` всё ещё требует **все** токены в названии (`len(matched_tokens) != len(parsed_query.search_tokens)` → False), но без substring-условия. Запрос «Marmot Parka» не пройдёт, потому что `marmot` не в названии «Sitka Blizzard Pro Parka»; запрос «Blizzard Parka» пройдёт. Шума не добавится.

Worker probe-данные от TL для контекста регрессионных тестов:
- `blizzard` (1 токен → уже broad) → 5 hits на Rogers, включая «Sitka Blizzard Pro Parka».
- `blizzard parka` (2 токена → станет broad после fix) → ожидаются те же hits на каждом из 4 магазинов.
- `sitka stratus jacket` (3 токена → останется target) → остаётся строгим, substring «stratus jacket» в `normalized_title`.

## Files

- new:    `sitka-services/tests/test_inventory_v2_query.py`
- modify: `sitka-services/vendor/inventory_parser/inventory/v2/query.py` (одна строка, 113)
- delete: (нет)

Если Worker увидит, что fix требует дополнительно тронуть `adapters/base.py` или другой файл — возвращается через HANDOFF, не делает молча.

## Do not touch

- `sitka-core/` целиком — Haskell ядро не нужно для этой задачи.
- Любые миграции БД.
- Adapter-файлы под `vendor/inventory_parser/inventory/v2/adapters/stores/*.py` — fix должен работать на shared `BaseStoreAdapter`, специфичные адаптеры менять не нужно.
- Avito-стек (`app/parsers/avito_*.py`, `vendor/avito_parser/`) — другой vendor, другая логика.
- `pricing settings`, касса, money-flow — параллельная история.

## Acceptance

- [ ] Строка `sitka-services/vendor/inventory_parser/inventory/v2/query.py:113` изменена с `<= 1` на `<= 2`. Других правок в `query.py` нет.
- [ ] Новый файл `sitka-services/tests/test_inventory_v2_query.py` создан, покрывает:
  - 1-словный запрос («blizzard») → `query_mode == "broad"` (регрессия: не сломали то, что работало).
  - 2-словный запрос («blizzard parka») → `query_mode == "broad"` (главный fix).
  - 3-словный запрос **без stopwords** («blizzard aerolite parka») → `query_mode == "target"` (граница не сдвинута дальше). **Поправка TL 2026-05-21:** изначально написал «sitka stratus jacket», но `sitka` — в `_STOPWORDS`, после фильтрации эффективных токенов 2 → было бы broad. Worker заменил на корректный 3-non-stopword пример, intent совпал.
  - Запрос с size/color → `query_mode == "target"` независимо от количества токенов (size-условие не нарушено).
- [ ] `cd sitka-services && .venv/bin/python -m pytest tests/test_inventory_v2_query.py -v` зелёный.
- [ ] Полный `make services-test` зелёный (не сломали другие тесты).
- [ ] `cd sitka-services/vendor/inventory_parser && python -c "from inventory.v2.query import parse_query; print(parse_query('blizzard parka').query_mode)"` печатает `broad`.

## Context

Прецедент: задокументирован в `OPERATING/backlog.md` → раздел «Backend / data integrity» → пункт про двусловные запросы (от 2026-05-13). Запрошен Admin'ом запиской 2026-05-20 04:55 в `MAILBOX/to-tl-sitka.md`.

После принятия — обновить `OPERATING.md` (заметка в «Заметки»), пометить пункт backlog'а как закрытый (strike-through, ссылка на PR), отправить записку с PR-номером и ссылкой на тест в `MAILBOX/to-admin.md`. Deploy на сервер через `bash deploy/auto-deploy.sh` (от 2026-05-14, scope=services).
