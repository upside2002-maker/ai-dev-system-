# TASK: inventory-parser-fork-task-a

- Status: open
- Ready: yes
- Date: 2026-05-27
- Project: sitka-office
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Owner принял решение 2026-05-25 — форкнуть `sitka-services/vendor/inventory_parser/` (см. архитектурный аудит 2026-05-21 §7 + Admin-записку 2026-05-25). TASK A — первый из четырёх:

- **Spike (закрыт TL):** записка в `MAILBOX/to-admin.md` от 2026-05-25 поздняя ночь — namespace `sitka-services/app/inventory/`, сглаженная v2-структура, alive 9116 LOC, dead 30 676 LOC.
- **TASK A (этот):** физический форк + чистка dead + миграция точек входа + тесты с нуля + CI без editable-install хака.
- **TASK B (следующий):** P0-1 — substring drop в `title_matches`.
- **TASK C (следующий):** P0-2 — Amazon timeout collision.
- **TASK D (последний):** overlay refresh + CODEOWNERS.

Каждый — отдельный PR + auto-deploy + smoke. Этот TASK не должен включать P0 фиксы (B/C) и не должен трогать avito vendor.

## Files

### new (всё под `sitka-services/app/inventory/`)

Структура сглаженной v2 (убираем `v2/` префикс):

- new: `sitka-services/app/inventory/__init__.py` — public re-export: `ParserService`, `ItemResult`, `StoreRunResult`, `parse_query`, `DEFAULT_STORE_NAMES`.
- new: `sitka-services/app/inventory/core.py` — facade (тонкий wrapper, копия из vendor `inventory/v2/core.py`).
- new: `sitka-services/app/inventory/types.py` — dataclasses + enums (копия `vendor/inventory_parser/inventory/v2/types.py`).
- new: `sitka-services/app/inventory/query.py` — `parse_query()`. **Импорт `from shared.product.sitka_catalog` заменить на `from app.inventory._sitka_catalog`** (см. ниже).
- new: `sitka-services/app/inventory/_sitka_catalog.py` — копия нужных функций из `vendor/avito_parser/shared/product/sitka_catalog/__init__.py`. Использовать `inventory/v2/query.py` как референс — копировать **только** функции/константы которые там импортируются: `COLOR_PARSE_TERMS`, `SIZE_PARSE_TERMS`, `canonical_color_key`, `canonical_product_tokens`, `canonical_size_key`, `canonical_token_variants`, `color_matches`, `normalize_match_text`, `phrase_pattern`, `size_matches`. Сверь grep'ом: `grep -E "^from shared\." vendor/inventory_parser/inventory/v2/query.py` показывает один live импорт со списком.
- new: `sitka-services/app/inventory/registry.py` — копия `inventory/v2/registry.py`, **удалить** `basspro` импорт и регистрацию (basspro dead, не в DEFAULT_STORE_NAMES).
- new: `sitka-services/app/inventory/_governor.py` — Protocol stub (копия `inventory/v2/snapshot/types.py` → только `Governor` Protocol; остальные классы из этого файла не нужны).
- new: `sitka-services/app/inventory/proxy_pool.py` — копия `inventory/v2/snapshot/proxy_pool.py`. Нужен `eurooptic.py` И `scheels.py`. Hardcoded путь `/srv/sitka-qa/config/proxies.txt` оставить как есть — это тема P1 (P1-3 в backlog аудита), не TASK A scope.
- new: `sitka-services/app/inventory/runtime/__init__.py`.
- new: `sitka-services/app/inventory/runtime/service.py` — `ParserService`. **Импорт `from inventory.v2.snapshot.types import Governor` → `from app.inventory._governor import Governor`**.
- new: `sitka-services/app/inventory/runtime/execution.py`.
- new: `sitka-services/app/inventory/runtime/postprocess.py`.
- new: `sitka-services/app/inventory/runtime/session.py`.
- new: `sitka-services/app/inventory/adapters/__init__.py`.
- new: `sitka-services/app/inventory/adapters/base.py` — `BaseStoreAdapter`. Скопировать **как есть** включая substring-drop в `title_matches`. Fix substring — это TASK B, не A.
- new: `sitka-services/app/inventory/adapters/identity_coverage.py`.
- new: `sitka-services/app/inventory/adapters/families/__init__.py`.
- new: `sitka-services/app/inventory/adapters/families/shopify_support.py`.
- new: `sitka-services/app/inventory/adapters/families/bigcommerce_support.py`.
- new: `sitka-services/app/inventory/adapters/stores/__init__.py`.
- new: `sitka-services/app/inventory/adapters/stores/*.py` × 23 файла из `vendor/inventory_parser/inventory/v2/adapters/stores/` **БЕЗ basspro.py**. Импорты `from inventory.v2.snapshot.proxy_pool` → `from app.inventory.proxy_pool` (в `eurooptic.py` и `scheels.py`).
- new: `sitka-services/app/inventory/catalog/__init__.py`.
- new: `sitka-services/app/inventory/catalog/sitka_canon.py`.

### new (тесты с нуля)

- new: `sitka-services/tests/test_inventory_query.py` — расширение существующего `test_inventory_v2_query.py` (тот переименуется или сольётся). Кейсы: `parse_query` 1/2/3+ token broad/target boundary, size/color extraction, stopwords filter.
- new: `sitka-services/tests/test_inventory_title_matches.py` — `BaseStoreAdapter.title_matches` positives (broad mode: оба токена в названии без substring) + negatives (broad mode: один токен в названии → False; target mode: substring требуется → текущее поведение пинить, чтобы TASK B мог явно его поменять).
- new: `sitka-services/tests/test_inventory_registry.py` — `build_registry()` возвращает 23 store без basspro, `DEFAULT_STORE_NAMES` содержит rogers/1shot/als/lancaster.
- new: `sitka-services/tests/test_inventory_smoke.py` — smoke на адаптерах с локальными HTML/JSON fixtures (минимум rogers + 1shot + один shopify + один bigcommerce). Не сеть. Fixture лежит в `sitka-services/tests/fixtures/inventory/<store>/<query>.html`. **Без real-network тестов** — это backlog N-2 из аудита, отдельный TASK.

Старый тест `sitka-services/tests/test_inventory_v2_query.py` (PR #89, 7 кейсов) **переименовать в `test_inventory_query.py`** через `git mv`, обновить импорты с `inventory.v2.query` на `app.inventory.query`. Все 7 кейсов должны остаться зелёными (регрессия PR #89 пинится).

### modify

- modify: `sitka-services/app/parsers/inventory_v2.py` — заменить `from inventory.v2.core import ParserService as _PS` на `from app.inventory.core import ParserService as _PS`. **Файл оставить** как backwards-compat alias — это минимизирует scope изменения в `app/routes/parsing.py`. Имя файла оставить (`inventory_v2.py`) или переименовать в `inventory.py` — на твоё усмотрение, если переименуешь — обнови импорт в `parsing.py`.
- modify: `sitka-services/Dockerfile` — удалить строку `RUN pip install --no-cache-dir -e ./vendor/inventory_parser` (строка ~33). `app/inventory/` теперь часть `app/` и приедет через стандартный `COPY . .`.
- modify: `.github/workflows/ci.yml` — удалить добавленную в PR #89 строку `pip install -e ./vendor/inventory_parser` в Python-test job. Оставить `pip install -e ./vendor/avito_parser` (avito vendor живёт ещё).

### delete

- delete: **весь каталог** `sitka-services/vendor/inventory_parser/` через `git rm -rf`. Перед удалением — `git mv` всех файлов из старых путей в новые, **не копировать** через `cp` (git history по файлам сохранится только при `git mv`; копией мы потеряем blame).

  **Метод предлагается:** делай в 2 коммита:
  1. Commit 1 — «move»: `git mv` файлов из `vendor/inventory_parser/inventory/v2/<X>` в `sitka-services/app/inventory/<X>` для всех alive файлов, плюс перестройка путей (snapshot/types.py → _governor.py, snapshot/proxy_pool.py → proxy_pool.py). Импорты не трогать. Этот коммит — чистый rename, git это распознает.
  2. Commit 2 — «rewrite imports + cleanup»: переписать импорты внутри moved-файлов (`inventory.v2.*` → `app.inventory.*`, `shared.product.sitka_catalog` → `app.inventory._sitka_catalog`), создать `_sitka_catalog.py`, удалить остатки `vendor/inventory_parser/` (`git rm -rf` уже не нужного), обновить `app/parsers/inventory_v2.py`, `Dockerfile`, `ci.yml`.

  Это разбиение нужно чтобы Reviewer мог отдельно проверить «правильно ли мы переместили» vs «правильно ли переписали импорты». Если предпочитаешь один коммит — флаг, оба варианта приемлемы, но раздельные дают чище blame.

## Do not touch

- **Avito vendor** (`sitka-services/vendor/avito_parser/`) и весь `shared/` namespace внутри него — следующий аудит (см. AVITO записку 2026-05-25 в `to-tl-sitka.md`). Не форкаем, не трогаем, не уносим.
- **`sitka-core/` целиком** — Haskell ядро, парсер с ним не общается.
- **Миграции БД** — этот TASK не трогает persistent state.
- **Substring-drop в `title_matches`** — копируем как есть. Fix — TASK B, отдельный PR.
- **Amazon timeout** в `runtime/service.py` (`_RUN_STORE_TIMEOUT_SECONDS=35`) — копируем как есть. Fix — TASK C.
- **`hardcoded /srv/sitka-qa/config/proxies.txt`** в proxy_pool.py — копируем как есть, это P1 backlog (P1-3).
- **`request_ssl=False` на адаптерах** — копируем как есть, это P2 backlog (F-SEC-2).
- **CODEOWNERS** — обновляется в TASK D.
- **PROJECT_MAP / KNOWN_ISSUES / OPERATING / NEXT_ACTIONS** — overlay-документы обновляются в TASK D.

## Acceptance

- [ ] `sitka-services/app/inventory/` создан со сглаженной v2-структурой (см. секцию Files выше).
- [ ] Все 23 alive store (без `basspro`) переехали в `app/inventory/adapters/stores/`.
- [ ] `vendor/inventory_parser/` удалён через `git rm -rf` (Reviewer должен подтвердить отсутствие).
- [ ] Все импорты `from inventory.v2.*` заменены на `from app.inventory.*` в живых файлах + в `app/parsers/inventory_v2.py`. `grep -rE "^from inventory\.v2" sitka-services/ --include="*.py"` возвращает пустой результат.
- [ ] Импорт `from shared.product.sitka_catalog` в `query.py` заменён на `from app.inventory._sitka_catalog`. `app/inventory/_sitka_catalog.py` создан и содержит **только** 10 функций/констант из списка в Files.new.
- [ ] `sitka-services/Dockerfile` больше не содержит строку `pip install -e ./vendor/inventory_parser`. Остаётся только avito vendor install.
- [ ] `.github/workflows/ci.yml` Python-test job больше не содержит `pip install -e ./vendor/inventory_parser`. Avito vendor install остаётся.
- [ ] Тесты:
  - [ ] `sitka-services/tests/test_inventory_query.py` (7 кейсов из PR #89 + новые) — зелёный.
  - [ ] `sitka-services/tests/test_inventory_title_matches.py` — зелёный, покрывает broad positives/negatives + target substring (текущее поведение).
  - [ ] `sitka-services/tests/test_inventory_registry.py` — `build_registry()` × 23 store без basspro.
  - [ ] `sitka-services/tests/test_inventory_smoke.py` — fixture-based, минимум rogers + 1shot + shopify + bigcommerce.
- [ ] `make services-test` зелёный целиком.
- [ ] `cd sitka-services && .venv/bin/python -c "from app.inventory.core import ParserService; print(ParserService)"` работает без editable install vendor.
- [ ] Smoke на dev: `cd sitka-services && python -c "import asyncio; from app.parsers.inventory_v2 import run_parser_search; r = asyncio.run(run_parser_search('blizzard', ['rogers'])); print(len(r[0].items))"` возвращает > 0.
- [ ] Pre-commit hooks все Passed.
- [ ] CI зелёный целиком (8 lanes) — особое внимание Python-test (там самое большое расхождение прошлого раза, PR #89).

## Context

- Architecture audit: `project-overlays/sitka-office/research/inventory-parser-architecture-audit-2026-05-21.md` — §2 Карта парсера, §5 F-DEAD-1 / F-DEAD-2 / F-CANON-1, §7 Рекомендация по работе дальше.
- Admin записки в `MAILBOX/to-tl-sitka.md`: 2026-05-25 вечер (решение Owner'а форкать), 2026-05-25 ночь ANSWERS (5 скоп-вопросов закрыты).
- Spike записка TL Sitka в `MAILBOX/to-admin.md`: 2026-05-25 поздняя ночь («Spike inventory fork»).
- PR #89 (master `ccac24b`) — `tests/test_inventory_v2_query.py` создан тогда, в этом TASK переименовывается в `test_inventory_query.py` с обновлёнными импортами. Все 7 кейсов сохранить — они пинят регрессию двусловного fix'а.

После закрытия TASK A: TL отчитывается запиской в `to-admin.md` (PR-номер + что закрыто + SHA master + цифры LOC было/стало), TASK B стартует следующим (substring drop fix через property-тесты).
