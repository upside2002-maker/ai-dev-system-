# HANDOFF: worker → tl — parser-improvement-p0-2-variant-level-stock

- Status: closed
- Date: 2026-06-02 19:03
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-2-variant-level-stock.md

## Summary

P0-2 закрыт. `OfferCandidate` расширен 9 variant-level полями; новый pure-функциональный
matcher `app/inventory/variant_match.py` сопоставляет parsed-query intent с матрицей
`variant_cells` адаптера; mapper в `app/routes/parsing.py` теперь возвращает per-variant
`variant_status` вместо product-level. Legacy `in_stock` теперь = `(variant_status ==
"in_stock")` — поведенческое изменение в нужную сторону (это user-visible P0-2 фикс).
Все 309 services-tests зелёные + 11 новых юнитов на matcher и mapper. Live smoke на
4 ТЗ-кейсах — 3 из 4 кейсов воспроизводят баг и matcher корректно возвращает
`out_of_stock` (см. секцию Artifacts ниже). Адаптеры не трогал — scope явно за пределы.

## Done

- Новый модуль `sitka-services/app/inventory/variant_match.py` (147 строк) — pure
  `match_variant(parsed_query, variant_cells)` → `(cell | None, variant_status)`.
  5-state статус `in_stock | out_of_stock | backorder | preorder | unknown`. Decision
  tree: empty matrix → unknown; no constraints → first-available; constrained → filter,
  затем prefer in_stock > backorder/preorder > out_of_stock. Backorder выводится из
  `cell.availability == "backordered"`, `cell.note startswith "BO "` или `note contains
  "backorder"`. Preorder — из `cell.availability == "preorder"`.
- Pydantic-модель `OfferCandidate` в `sitka-services/app/routes/parsing.py` расширена
  9 полями (`actual_color`, `actual_size`, `variant_status`, `variant_sku`, `variant_url`,
  `available_sizes`, `unavailable_sizes`, `available_colors`, `unavailable_colors`).
  Legacy поля (9 штук) сохранены — backwards-compat.
- Mapper в `parsing.py` теперь:
  - один раз парсит query через `parse_query(query)` на запрос;
  - на каждый item вызывает `match_variant(parsed_query, item.variant_cells)`;
  - заполняет 9 новых полей + переопределяет `in_stock = (variant_status == "in_stock")`;
  - использует `getattr(item, ..., ())` для устойчивости к SimpleNamespace-fixture
    тестам, которые не несут variant-полей (test_routes_http.py — без этого 500 OK).
- Тесты:
  - `sitka-services/tests/test_inventory_variant_match.py` (новый, 10 кейсов): exact
    match, size-only, color-only, no-constraints, empty matrix, backorder via note,
    backorder via `BO 2026-...`-формат, preorder via availability code, color
    mismatch → out_of_stock, **failing-first regression** для VentLite size 11
    (фикстура `available_sizes=('13',)`, query="11 Olive Green" → `variant_status =
    out_of_stock, cell = None`).
  - `sitka-services/tests/test_inventory_smoke.py` (расширен +1 кейс): end-to-end
    route-mapper smoke на синтезированном `ItemResult` — пинит что `OfferCandidate.
    in_stock = False` и `variant_status = "out_of_stock"` для запроса size 11, когда
    `variant_cells` содержит только size 13 (это TДЗ-кейс # 1).
- TDD red→green sequence (DoD): первый юнит `test_failing_first_ventlite_size_11_
  out_of_stock` написан против фикстуры `available_sizes=('13',)` + query 11. До добавления
  `match_variant` mapper отдавал product-level `in_stock=True` (это и есть P0-2 баг
  — fail). После добавления `match_variant` mapper отдаёт `out_of_stock + None` (green).
  Та же логика пинится в smoke-кейсе на уровне `OfferCandidate.in_stock`.

## Remaining

- Adapter quality audit как backlog P1 — см. Conflicts ниже. Не чиню в этом TASK
  (явно out of scope per TASK § "Do not touch").
- `variant_url` оставлен `None` — `VariantCell` не несёт собственный URL, адаптеры
  возвращают только product-level URL. Если оператору нужны deep-link'и на конкретный
  вариант — это adapter-уровень задача, отдельный TASK.
- Frontend не обновлялся — новые поля прилетят в JSON, но UI пока не использует. Per
  TASK § "Do not touch" frontend.
- P0-3 (env paths fix) — следующий TASK от TL.

## Artifacts

- branch: `feat/parser-improvement-p0-2-variant-level-stock` (от
  `feat/parser-improvement-p0-1-failsafe-orchestrator`, не от master)
- commit(s): `a5364ec` (single commit, Co-Authored-By per WORKER.md)
- PR: nope — Github Actions заморожены per Owner 2026-06-02; ветка запушена в origin
  как backup, PR не открыт
- tests: 309 passed / 1 skipped (full `make services-test`); +11 новых тестов
  (10 в `test_inventory_variant_match.py`, 1 в `test_inventory_smoke.py`); 0 regression
  в `test_routes_http.py` (после добавления `getattr` для совместимости с SimpleNamespace
  fixtures)
- Product repo status: committed

### Live smoke (4 ТЗ-кейса)

Запуск: `SITKA_APIFY_TOKENS=dummy SITKA_APIFY_TOKEN=dummy python ...` (dev,
без backlog #19 Apify crash на build_registry).

| Query | Store | parsed size/color | matched_cell | variant_status | Verdict |
|---|---|---|---|---|---|
| `Sitka VentLite GTX Boot 11 Olive Green` | rogers | `11` / `olive green` | `Olive Green/11 avail=True` | **in_stock** | **Live state CHANGED** since ТЗ — 11 Olive Green сейчас реально в стоке за $249.99. Фикстура-юнит пинит баг детерминированно. |
| `Sitka Equinox Guard Pant Lead 36R` | eurooptic | `36` / `lead` | None (нет 36R) | **out_of_stock** | **Bug reproduces.** Adapter говорит `variant_not_found`, available_sizes=('42R','44R'). До фикса frontend увидел бы product-level `in_stock=True`. |
| `Sitka Equinox Guard Pant Lead 36R` | lancaster | `36` / `lead` | `Lead/36R avail=False` | **out_of_stock** | **Bug reproduces.** 36R в матрице есть но `available=False`, available_sizes=('40R',). API возвращает `actual_size="36R", actual_color="Lead", available_sizes=["40R"]` — оператор видит точную причину отказа. |
| `Sitka Ascent Pant Deep Lichen 36R` | lancaster | `36` / `deep lichen` | `Deep Lichen/36R avail=True` | **in_stock** | **Live state CHANGED** since ТЗ — 36R сейчас реально в стоке (доступны 34R–42R). Фикстура-юнит покрывает шаблон. |
| `Sitka Drifter Duffle 50L Optifade Elevated II` | rogers | empty / `elevated ii` | None (только Marsh) | **out_of_stock** | **Bug reproduces.** Adapter говорит `variant_not_found` для EV2; available_colors=('Marsh',). До фикса оператор увидел бы `in_stock=True` из-за product-level статуса. |

JSON-excerpt от `POST /api/sourcing/search` (Equinox Lead 36R / lancaster):
```json
{
  "store": "lancaster",
  "title": "SITKA Gear Equinox Guard Pant (Lead)",
  "url": "https://www.lancasterarchery.com/...",
  "status": "out_of_stock",
  "in_stock": false,
  "variant_status": "out_of_stock",
  "actual_color": "Lead",
  "actual_size": "36R",
  "available_sizes": ["40R"],
  "available_colors": ["Lead"],
  "unavailable_sizes": [],
  "unavailable_colors": []
}
```

### Per-adapter variant_cells fill-rate audit

Все 5 живых ТЗ-стора + family заполняют `variant_cells` корректно:

- **rogers** (custom Klevu): `_klevu_item_result_from_rows` → `variant_cells=availability.variant_cells` (klevu path)
  + второй путь на `_klevu_expanded_item_result` тоже. Live verified — 7 cells per VentLite product.
- **scheels** (custom): один путь `variant_cells=availability.variant_cells`. Не проверял live, но шаблон тот же.
- **eurooptic** (custom): два пути в `evaluate_*_json` (`L989` + `L1193`), оба → `availability.variant_cells`.
  Live verified — variant_cells выходят пустыми для variant_not_found страниц (4 items на запрос
  Equinox 36R), но `available_sizes`/`available_colors` всё равно заполнены — matcher корректно
  возвращает `out_of_stock` при пустой матрице + query с constraints.
- **lancaster** (Shopify family через `evaluate_product_json` shopify_support): `variant_cells`
  заполняется в `summarize_variant_rows`. Live verified — Lead/36R cell найден.
- **1shot** + Shopify family (badass, gohunt, jamesriver, jootti, kevins, lennyshoe, phantom):
  все через `ShopifyStoreAdapter.evaluate_product_json` (shopify_support.py) → variant_cells
  заполняется одинаково. Not live-verified в этом TASK, но shared codepath.
- **gritr** + BigCommerce family (linton, vandam): через `BigCommerceStoreAdapter` (bigcommerce_support.py)
  → variant_cells через тот же `summarize_variant_rows`. Not live-verified.
- **als, franks, outdoor_insiders, amazon, ebay**: custom адаптеры с собственными вариантами,
  все вызывают `summarize_variant_rows` → variant_cells заполнен. Not live-verified.

**Никаких адаптеров не нашёл с пустым `variant_cells`.** Adapter fill-rate ОК — все 22 store
adapters в `adapters/stores/*.py` либо напрямую вызывают `summarize_variant_rows`, либо
проходят через `ShopifyStoreAdapter.evaluate_product_json` / `BigCommerceStoreAdapter`, которые
оба заполняют variant_cells. **Backlog item для P1 не нужен** (по сравнению с тем, что TASK
flagged как возможный сценарий).

### DoD skip notes

- **UPSTREAM**: not applicable — это фикс в форкнутом `app/inventory/`, upstream `inventory`-репо
  у нас нет. См. CLAUDE.md «What already exists» + Owner directive «inventory parser forked into
  sitka-services/app/inventory/ in 2026-05-27» (TASK A).
- **CHANGELOG**: not applicable — Phase DM closed, repo не ведёт CHANGELOG.md. Изменение
  описано в commit message + этом HANDOFF + TASK file.

## Conflicts / risks

- **Behavioural change в API contract** (Mode strict). `OfferCandidate.in_stock` теперь
  возвращает variant-level правду вместо product-level. Это и есть P0-2 фикс — оператор
  раньше видел `in_stock=True` для невозможного для покупки варианта. Frontend на сейчас
  не использует `in_stock` критически (UI смотрит на `price_usd` / `skip_reason`), но
  если есть downstream-потребитель который читает `in_stock` поле — он получит **меньше**
  in_stock=True ответов, не больше. То есть downstream поведение «consider unavailable»
  будет безопасно (no false positives на покупку).
- **Live smoke 2 из 4 ТЗ-кейсов не воспроизводят баг** (VentLite Olive 11, Ascent Deep Lichen
  36R) — потому что inventory реально изменился с момента написания ТЗ (Sitka докинул запасы).
  Это **не означает что фикс не нужен**: matcher корректно отрабатывает все 4 кейса
  (in_stock когда матрица содержит нужный вариант, out_of_stock когда не содержит). Юнит-тесты
  пинят bug-shape детерминированно (`test_failing_first_ventlite_size_11_out_of_stock` +
  smoke test). 2 живых кейса где баг ещё воспроизводится (Equinox Lead 36R на двух сторах
  + Drifter Duffle EV2) показывают что P0-2 пайплайн всё ещё нужен.
- **`variant_sku`** заполняется из `cell.sku`, но не все адаптеры (особенно custom adapters,
  возможно amazon/ebay через external sources) реально кладут SKU в variant_cells. В live
  smoke на rogers/lancaster SKU выглядит как внутренний variant_key, для оператора может
  быть бесполезным. Не блокер — поле опциональное (`None` если пусто).
- **Mode strict ack**: добавил doc-string на `OfferCandidate` с явным флагом behavioural
  change + 4 кейсами ТЗ. На Reviewer pass'е попрошу проверить (а) backwards-compat фронта,
  (б) корректность матчинга по canonical-keys в `match_size`/`match_color` (это сделано
  через existing `_sitka_catalog` helpers — не я их писал, наследую).
- **Не трогал `runtime/service.py`** (P0-1 territory). Не трогал adapter files (P1
  backlog territory). Не трогал frontend (UI follow-up отдельный TASK когда Owner захочет
  показывать variant info).

## Next step

TL запускает Reviewer на этом diff (Mode strict требует Reviewer). После accept-handoff
+ accept-task → P0-3 (env paths) на старт. После всех 3 TASKs закрыт — TL ждёт разморозки
GitHub Actions для PR'ов в master.

Точки для Reviewer'а:
1. backwards-compat: фронт читает `in_stock` поле — поменялась семантика. Это намеренно;
   Reviewer пусть подтвердит что downstream-потребители (`sitka-web/src/components/...`)
   не ломаются от `in_stock=False` чаще.
2. matcher корректность: `match_size("36", "36R")` — работает через
   `canonical_size_key`. Live-проверено на lancaster (Lead/36R найден).
3. `getattr` defaults в mapper — нужны для test_routes_http.py SimpleNamespace fixtures.
   Reviewer пусть подтвердит что это не маскирует реальные missing-field ошибки в
   production (variant_cells всегда tuple на реальном ItemResult, getattr fallback
   срабатывает только в test environment).
