# TASK: inventory-parser-fork-task-a2-extend-sitka-catalog

- Status: done
- Ready: yes
- Date: 2026-05-28
- Project: sitka-office
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

После TASK A (inventory fork, master `8f1d5c4`) скопировано **только 10 символов** из `vendor/avito_parser/shared/product/sitka_catalog/` в `app/inventory/_sitka_catalog.py` — именно те, которые импортирует `query.py`. Worker'ская инвентаризация в TASK A HANDOFF показала, что **ещё 9 alive адаптеров** в `app/inventory/` импортируют дополнительные 15 символов из `shared.product.sitka_catalog` (резолвится через avito vendor editable install).

Список impacted адаптеров (TASK A HANDOFF, Conflicts п.1):
- `app/inventory/adapters/stores/eurooptic.py` → `infer_color_label_from_text, infer_size_label_from_text, is_color_axis_label, is_size_axis_label`
- `app/inventory/adapters/stores/franks.py` → `contains_label_candidate, label_match_candidates, match_segment_label, normalize_text, repair_color_label, significant_product_tokens`
- `app/inventory/adapters/stores/outdoor_insiders.py` → `normalize_text`
- `app/inventory/adapters/stores/als.py` → `compact_size_length_label, is_color_axis_label, is_size_aux_axis_label, is_size_axis_label`
- `app/inventory/adapters/stores/shopify_stores.py` → `canonical_color_key`
- `app/inventory/adapters/families/shopify_support.py` → `is_color_axis_label, is_size_axis_label, move_tall_marker_from_color`
- `app/inventory/adapters/families/bigcommerce_support.py` → `combine_size_label, is_color_axis_label, is_size_aux_axis_label, is_size_axis_label`
- `app/inventory/catalog/sitka_canon.py` → `canonical_product_title`

Уникально **15 дополнительных символов** (с учётом дублей).

Цель TASK A2 — разорвать скрытую cross-vendor связь до начала avito-аудита (запущен параллельно в этой же сессии 2026-05-28). Если avito будет fork'нут — текущие импорты `from shared.product.sitka_catalog` в inventory-адаптерах сломаются. A2 — обязательный pre-req для avito-форка.

## Решение (TL direction; Worker может скорректировать в HANDOFF, если найдёт лучше)

Расширить `app/inventory/_sitka_catalog.py` до полного набора нужных символов (10 уже скопированных + 15 новых). Переписать импорты в 9 alive файлах с `from shared.product.sitka_catalog` на `from app.inventory._sitka_catalog`. После этого `grep -rE "^from shared\." sitka-services/app/inventory/` должен возвращать пусто.

**Возможные осложнения:**
1. Часть новых символов может иметь transitive dependencies на другие модули внутри `shared.product.sitka_catalog/canonical.py` или `shared.product.sitka_catalog/__init__.py` — нужно тоже копировать private machinery. Worker делает grounding read: для каждого нового символа смотрит реализацию в `vendor/avito_parser/shared/product/sitka_catalog/` и тащит **минимальный** набор зависимостей.
2. Дубли возможны — несколько адаптеров импортируют одно и то же. Считать **уникальных** символов (15), не суммой импорт-строк.

## Files

- modify: `sitka-services/app/inventory/_sitka_catalog.py` — расширение до полного набора публичных символов + их private machinery.
- modify: 8 файлов с заменой импорта `from shared.product.sitka_catalog import ...` → `from app.inventory._sitka_catalog import ...`:
  - `app/inventory/adapters/stores/eurooptic.py`
  - `app/inventory/adapters/stores/franks.py`
  - `app/inventory/adapters/stores/outdoor_insiders.py`
  - `app/inventory/adapters/stores/als.py`
  - `app/inventory/adapters/stores/shopify_stores.py`
  - `app/inventory/adapters/families/shopify_support.py`
  - `app/inventory/adapters/families/bigcommerce_support.py`
  - `app/inventory/catalog/sitka_canon.py`
- modify (optional): `sitka-services/tests/test_inventory_query.py` или новый `test_inventory_sitka_catalog.py` — короткие тесты на extended symbols (smoke import + 2-3 базовых функциональных проверки). На усмотрение Worker'а.

## Do not touch

- **`vendor/avito_parser/`** — отдельный аудит запущен параллельно. Не трогаем. Только **читаем** `shared/product/sitka_catalog/` для копирования символов.
- **`adapters/base.py title_matches`** — TASK B территория, закрыто.
- **`runtime/service.py` timeout config** — TASK C территория, закрыто.
- **`query.py`** — порог `<= 2` (PR #89) и текущие 10 символов в `_sitka_catalog.py` — уже стоят правильно. Только добавляешь новые символы в `_sitka_catalog.py`, импорт в `query.py` не трогаешь.
- **`sitka-core/`, миграции, prod.yml, auto-deploy.sh** — не трогать.

## Acceptance

- [ ] `app/inventory/_sitka_catalog.py` содержит все 25 публичных символов (10 + 15 новых из списка выше).
- [ ] Все 8 файлов в Files.modify имеют импорт `from app.inventory._sitka_catalog`, **не** `from shared.product.sitka_catalog`.
- [ ] `grep -rE "^from shared\.product\.sitka_catalog" sitka-services/app/inventory/` возвращает пусто (exit 1).
- [ ] `make services-test` зелёный — никаких регрессий в существующих 283+ тестах.
- [ ] Smoke `cd sitka-services && .venv/bin/python -c "import asyncio; from app.parsers.inventory_v2 import run_parser_search; r = asyncio.run(run_parser_search('blizzard', ['rogers', '1shot'])); print([(s.store, s.status, len(s.items)) for s in r])"` возвращает hits на rogers и 1shot.
- [ ] CI зелёный (8 lanes).

## Context

- TASK A HANDOFF (archived): `~/Projects/ai-dev-system/project-overlays/sitka-office/HANDOFFS/archive/2026-05-27-worker-to-tl-inventory-parser-fork-task-a.md` — Conflicts п.1 содержит точный список 9 файлов и 15 символов.
- Architecture audit §3 F-CANON-1 — упоминание дублирования между inventory `sitka_canon.py` и avito vendor `shared.product.sitka_catalog`.
- Параллельно — AVITO architecture audit запущен subagent'ом 2026-05-28 (subagent сохранит отчёт в `research/avito-parser-architecture-audit-2026-05-28.md`).
- Прецедент: spike-записка TL Sitka в `MAILBOX/to-admin.md` от 2026-05-25 (поздняя ночь) недооценила scope: писала «1 live import», по факту 9 sites / 16 distinct symbols. TASK A2 закрывает этот residual.

После закрытия — TL отчитывается запиской в `to-admin.md` (PR-номер + что закрыто + SHA master). Avito аудит может прийти параллельно из subagent'а — обрабатывается отдельным TL-flow.
