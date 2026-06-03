# TASK: parser-improvement-p0-2-variant-level-stock

- Status: done
- Ready: yes (после P0-1 closed)
- Date: 2026-06-02
- Project: sitka-office
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: strict
- Critical approved by: TL Sitka (Mode strict оправдан: меняет контракт API наружу + критичная бизнес-семантика «в наличии в этом цвете и размере» — оператор полагается на точность)

## Problem

Закрывает **P0-2** из `docs/PARSER_IMPROVEMENT_TZ.md` — главная боль ТЗ: «Stock-статус возвращается на product-уровне, а не на variant-уровне».

Четыре живых кейса из ТЗ:
| Запрос | Парсер сказал | Реальность |
|---|---|---|
| `Sitka VentLite GTX Boot 11 Olive Green` | Rogers $319.20 in_stock | На странице 11 в Olive Green не было, был только 13 |
| `Sitka Equinox Guard Pant Lead 36R` | EuroOptic $129.99 in_stock, Lancaster $169 in_stock | На обоих 36R **отсутствовал**, был только 40R |
| `Sitka Ascent Pant Deep Lichen 36R` | Lancaster $135 in_stock | На странице — Backorder 2-3 weeks для всех размеров |
| `Sitka Drifter Duffle 50L Optifade Elevated II` | Rogers $99.50 in_stock | EV2 был sold out, в стоке только Subalpine |

**КРИТИЧЕСКИ ВАЖНОЕ ОТКРЫТИЕ (TL grounding pass 2026-06-02):**

В `app/inventory/types.py:ItemResult` **variant matrix УЖЕ извлекается** адаптерами:
```python
available_sizes: tuple[str, ...]
unavailable_sizes: tuple[str, ...]
available_colors: tuple[str, ...]
unavailable_colors: tuple[str, ...]
available_variants: tuple[str, ...]
unavailable_variants: tuple[str, ...]
variant_cells: tuple[VariantCell, ...]   # ← variant-level matrix
```

Но **теряется на route-границе** в `app/routes/parsing.py` где mapper `ItemResult → OfferCandidate` тупо берёт только `title/url/status/price`:
```python
OfferCandidate(
    status=item_payload.get("status") or "unknown",
    in_stock=item_payload.get("status") == "in_stock",   # ← product-level
    ...
)
```

Это **F-WIRE-1** из inventory-аудита 2026-05-21 (§4 «Phase-E enrichment теряется на route-границе»). ТЗ описывает эту же проблему уже с точки зрения оператора.

**Цель TASK:** прокинуть variant-info с уровня `ItemResult.variant_cells` / `available_sizes` / `available_colors` до фронта через `OfferCandidate`, и добавить matcher запрос→variant который возвращает **`variant_status` для именно запрошенного size×color**, не product-level boolean.

## Решение (TL direction)

1. **Расширить `OfferCandidate`** в `app/routes/parsing.py` (Pydantic model):
   ```python
   class OfferCandidate(BaseModel):
       # ... existing fields ...
       in_stock: bool   # ОСТАВЛЯЕМ — backwards-compat; теперь = (variant_status == "in_stock")
       # new variant-level fields:
       actual_color: str | None = None
       actual_size: str | None = None
       variant_status: Literal["in_stock", "out_of_stock", "backorder", "preorder", "unknown"] = "unknown"
       variant_sku: str | None = None
       variant_url: str | None = None
       available_sizes: list[str] = []     # для UI «в твоём цвете доступны: M, L, XL»
       unavailable_sizes: list[str] = []
       available_colors: list[str] = []
       unavailable_colors: list[str] = []
   ```
   Backwards-compat: фронт не сломается (старые поля остаются), новые поля опциональны.

2. **Расширить mapper в `parsing.py`** — пробросить новые поля из `item_payload` (`asdict(ItemResult)`). Worker делает grounding: какие именно ключи возвращают адаптеры в `variant_cells` / `available_*`. Тип VariantCell в `types.py` — копировать relevant поля.

3. **Добавить variant-matcher** — функция (например в `app/parsers/inventory_v2.py` или `app/inventory/query.py` extend, или новый `app/inventory/variant_match.py`):
   ```python
   def match_variant(
       parsed_query: ParsedQuery,
       variant_cells: tuple[VariantCell, ...],
   ) -> tuple[VariantCell | None, Literal["in_stock", "out_of_stock", "backorder", "preorder", "unknown"]]:
       """Из query вытаскиваем желаемые size/color; матчим с variant_cells; возвращаем матч + статус.
       Если матча нет — возвращаем None + "out_of_stock"."""
   ```
   Используется в mapper'е → заполняет `actual_size`, `actual_color`, `variant_status`, `variant_sku`, `variant_url`.

4. **Перевод `OfferCandidate.in_stock` на variant-level**: `in_stock = (variant_status == "in_stock")`. Если фронт ожидал product-level — это **поведенческое изменение в нужную сторону** (это и есть фикс P0-2: «4 кейса должны вернуть out_of_stock / backorder, а не in_stock»).

5. **Live smoke** на 4 ТЗ-кейсах: для каждого ожидаемый `variant_status` указан в таблице выше. Per Admin'у — «один из 4 P0-2 кейсов должен пройти реально на live-сайте». Worker делает probe против реального сервиса (без auth, через сервер dev).

## Files

- modify: `sitka-services/app/routes/parsing.py` — расширить `OfferCandidate` Pydantic model + mapper.
- new: `sitka-services/app/inventory/variant_match.py` (или extend `query.py`) — функция `match_variant(parsed_query, variant_cells)`.
- modify: `sitka-services/app/parsers/inventory_v2.py` — если matcher живёт там, добавить call. Иначе route mapper.
- new: `sitka-services/tests/test_inventory_variant_match.py` — unit-tests на matcher (нормальные кейсы + edge: пустой variant_cells, query без size, query с color но без size, etc.).
- modify: `sitka-services/tests/test_inventory_smoke.py` — расширить кейсы с fixture HTML на проверку variant-level статуса.

## Do not touch

- **Adapter store files** — не меняем. variant_cells уже извлекается. Если кто-то из адаптеров не заполняет variant_cells правильно (Worker найдёт через probe или Reviewer заметит) — флаг в HANDOFF как backlog item, **не чинить в этом TASK**. P0-2 = «прокинуть до route + matcher», не «починить адаптеры».
- **`title_matches` в `adapters/base.py`** — TASK B территория.
- **`runtime/service.py`** failsafe — P0-1 уже закрыл.
- **`_RUN_MANY_CONCURRENCY`**, **`_RUN_STORE_TIMEOUT_SECONDS`**, **`_PRODUCT_CHECK_TIMEOUT_SECONDS`** — нет.
- **`_sitka_catalog.py`** — нет.
- **`vendor/avito_parser/`**, sitka-core, миграции, prod.yml, auto-deploy.sh — нет.
- **Frontend (`sitka-web/`)** — НЕ трогаем. Backwards-compat поля остаются, новые поля прилетят в JSON, но UI пока их не использует. Изменения фронта — **отдельный TASK** (если Owner захочет показывать variant info оператору; не блокирует P0-2).

## Acceptance

- [ ] `OfferCandidate` в `app/routes/parsing.py` расширен: `actual_color`, `actual_size`, `variant_status`, `variant_sku`, `variant_url`, `available_sizes`, `unavailable_sizes`, `available_colors`, `unavailable_colors`. Старые поля (`title`, `url`, `status`, `price_text`, `price_usd`, `in_stock`, `added_to_core`, `skip_reason`) остаются.
- [ ] `in_stock` теперь = `(variant_status == "in_stock")` (поведенческое изменение в нужную сторону).
- [ ] `app/inventory/variant_match.py` (или эквивалент) — функция `match_variant(parsed_query, variant_cells)` с docstring, return type аннотирован.
- [ ] Mapper в `parsing.py` использует `match_variant(...)` и заполняет новые поля.
- [ ] `tests/test_inventory_variant_match.py` — unit-тесты на matcher: минимум 6 кейсов (точный матч, размер есть но не цвет, цвет есть но не размер, ничего нет, query без variant constraints, variant_cells пустой).
- [ ] `tests/test_inventory_smoke.py` — расширен fixture для одного из ТЗ-кейсов (например VentLite Olive 11) — пинит что `variant_status == "out_of_stock"` (не in_stock).
- [ ] **Failing test first** (per DoD ТЗ): unit-test воспроизводит баг на fixture с `available_sizes=['13']` и query='11' — до фикса возвращает `in_stock=True`, после фикса `variant_status='out_of_stock', in_stock=False`.
- [ ] `make services-test` зелёный.
- [ ] **Live smoke** (per DoD ТЗ): хотя бы 1 из 4 ТЗ-кейсов на dev-сервере возвращает правильный variant_status. Транскрипт + URL'ы в HANDOFF.
- [ ] Worker в HANDOFF фиксирует: какие адаптеры реально заполняют `variant_cells` корректно (через probe на dev — rogers? scheels? lancaster? eurooptic?), какие НЕ заполняют (фиксируется как backlog item P1, не чинится в этом TASK).

## Context

- ТЗ от Owner'а: `/Users/ilya/Projects/sitka-office/docs/PARSER_IMPROVEMENT_TZ.md` § «P0-2. Stock-статус возвращается на product-уровне, а не на variant-уровне».
- Архитектурный аудит 2026-05-21 §4 F-WIRE-1: «Phase-E enrichment теряется на route-границе» — точно эта проблема, описанная архитектурно.
- TL grounding pass 2026-06-02: variant matrix уже в `ItemResult` (`available_sizes/colors`, `variant_cells`), нужно только пробросить через route + matcher.
- DoD из ТЗ §«Definition of Done».
- **Mode strict** (повышен от default normal для Tier B): меняет контракт API наружу (`OfferCandidate` shape) + критичная бизнес-семантика. Reviewer обязателен.

**Branching context:** ветка `feat/parser-improvement-p0-2-variant-level-stock` берётся **от ветки P0-1** (не от master), чтобы наследовать P0-1 failsafe изменения в `runtime/service.py`. После всех 3 TASKs закрыты — TL ждёт разморозки GitHub Actions для PR'ов.

После закрытия — TL отчитывается короткой запиской в `to-admin.md` с прибавкой «4-кейсный smoke на dev». P0-3 на старт.
