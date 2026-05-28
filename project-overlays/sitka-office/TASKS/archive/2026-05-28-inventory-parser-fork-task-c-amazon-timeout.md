# TASK: inventory-parser-fork-task-c-amazon-timeout

- Status: done
- Ready: yes
- Date: 2026-05-28
- Project: sitka-office
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Закрывает **P0-2** из архитектурного аудита 2026-05-21 (`research/inventory-parser-architecture-audit-2026-05-21.md`, §6).

Amazon де-факто не работает в выдаче. `app/inventory/runtime/service.py:29` объявляет `_RUN_STORE_TIMEOUT_SECONDS = 35.0` — runtime cap для `asyncio.wait_for` вокруг `run_store` (line 175-178). Внутри Amazon-адаптера (`app/inventory/adapters/stores/amazon.py:34`) объявлен собственный `search_timeout_seconds = 180` — он передаётся в `ApifyRunner.run_actor_sync` (line 61) как параметр Apify actor. Apify junglee-actor ~30s typical, с холодным стартом легко 60+s.

В итоге: runtime cap 35s срабатывает раньше любого realistic Apify ответа. Каждый поиск с Amazon возвращает `failed:store_timeout`. Оператор не видит Amazon-результатов **никогда**.

**Цель TASK C:** сделать runtime cap **per-adapter**, чтобы slow-by-design адаптеры с честно объявленным `search_timeout_seconds` получали достаточный бюджет. Дефолт для остальных остаётся 35s (норма для HTML-парсинга). Плюс аудит других потенциально slow адаптеров (ebay, eurooptic) на тот же тип коллизии.

## Решение (TL direction; Worker может скорректировать в HANDOFF, если найдёт лучше)

Поменять hardcoded `_RUN_STORE_TIMEOUT_SECONDS` на helper, который возвращает `max(adapter.search_timeout_seconds, _RUN_STORE_TIMEOUT_SECONDS_DEFAULT)`. То есть:
- По умолчанию (адаптеры без override) — 35s как сейчас.
- Amazon (180s declared) — 180s + buffer (~5-10s на сетевой overhead).
- Future slow adapters — задают `search_timeout_seconds = N` на классе и автоматически получают per-adapter cap.

Буфер на сетевой overhead — `+10s` сверху adapter-declared. Или явно `adapter.search_timeout_seconds + 10`. Worker может выбрать.

## Files

- modify: `sitka-services/app/inventory/runtime/service.py` (`_RUN_STORE_TIMEOUT_SECONDS` → helper + замена `timeout=...` в `asyncio.wait_for`).
- modify: `sitka-services/app/inventory/adapters/base.py` — добавить class attribute `search_timeout_seconds: float = 35.0` в `BaseStoreAdapter` как явный default (чтобы все адаптеры имели атрибут, и `getattr`-fallback не требовался).
- new: `sitka-services/tests/test_inventory_runtime_timeout.py` — тесты:
  - Default-timeout адаптер (без override `search_timeout_seconds`) получает 35s cap.
  - Amazon-стиль адаптер (с `search_timeout_seconds = 180`) получает 180+ cap.
  - Адаптер с `search_timeout_seconds < 35` (если возможно) — должен получить минимум 35s (защита от не-внимательного override).
  - Timeout сработка на стандартном адаптере при медленной search — кейс симулируем через async sleep.
  - **Не сетевой** — только моки.

## Do not touch

- **Amazon adapter `search_timeout_seconds = 180`** — менять не нужно, value корректное.
- **Substring-check в `title_matches`** — это TASK B (закрыт PR #91).
- **`_PRODUCT_CHECK_TIMEOUT_SECONDS = 25.0`** — отдельный таймаут на product check, не path этого TASK. Если найдёшь похожую коллизию (адаптер с `check_product_timeout_seconds`) — флаг в HANDOFF, не чини здесь.
- **`_RUN_MANY_CONCURRENCY = 2`** — это P1, не P0. Не меняем.
- **Adapter store files** кроме `amazon.py` для аудита (read-only) — fix локален в `base.py` + `runtime/service.py`.
- **`_sitka_catalog.py`** — TASK A2.
- **`sitka-core/`, миграции, avito vendor, prod.yml** — не трогать.

## Acceptance

- [ ] `BaseStoreAdapter` в `app/inventory/adapters/base.py` имеет class attribute `search_timeout_seconds: float = 35.0` (или эквивалент через property/getattr).
- [ ] `app/inventory/runtime/service.py` use per-adapter cap при вызове `asyncio.wait_for`. Helper типа `_store_run_timeout(adapter: BaseStoreAdapter) -> float` или inline `max(adapter.search_timeout_seconds + buffer, default)`.
- [ ] **Аудит других адаптеров в HANDOFF:** Worker проверяет grep'ом все `adapters/stores/*.py` на собственный `search_timeout_seconds` override. Сейчас известно: только Amazon. Если найдёт другие — фиксирует в HANDOFF (без правок здесь — это P1 followup).
- [ ] `sitka-services/tests/test_inventory_runtime_timeout.py` — новый файл, **не сетевые** тесты (моки):
  - default cap = 35s (или явный конфиг).
  - Amazon-стиль (subclass с `search_timeout_seconds = 180`) → cap ≥ 180.
  - Timeout срабатывает корректно (через моковую медленную `run_store`).
- [ ] `cd sitka-services && .venv/bin/python -m pytest tests/test_inventory_runtime_timeout.py -v` зелёный.
- [ ] Полный `make services-test` зелёный.
- [ ] CI зелёный (8 lanes).
- [ ] **Prod smoke после deploy:** `POST /api/sourcing/search` с `desiredItem="sitka jetstream"` (или другой популярный запрос), `stores=["amazon"]` → status НЕ `failed:store_timeout`. Допустимые: `ok` с items, `empty`, `blocked` (Apify token issues — другая история). **Не**: `failed:store_timeout`. До fix'а — всегда `failed:store_timeout`.

## Context

- Architecture audit §6 P0-2: «Поднять `_RUN_STORE_TIMEOUT_SECONDS` или сделать его per-adapter. Сейчас Amazon де-факто не работает.»
- TASK A (master `8f1d5c4`) — `runtime/service.py` уже живёт в `app/inventory/`.
- TASK B (master `89a6c25`) — substring-check fix; не влияет на этот TASK.
- Параллельно — recurring CORE_AUTH drift закрыт через override.yml (PR #92 master `53a738e`); auto-deploy теперь должен идти без сюрпризов.

После закрытия — TL отчитывается запиской в `to-admin.md` (PR-номер + что закрыто из аудита + SHA master + prod smoke результат Amazon-запроса). TASK D идёт следующим (overlay refresh + CODEOWNERS — финиш-линия).
