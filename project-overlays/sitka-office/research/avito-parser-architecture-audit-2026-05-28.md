# Архитектурный аудит vendor/avito_parser

Дата: 2026-05-28
Автор: tech-lead (sub-agent, deep research mode)
Источник: `sitka-services/vendor/avito_parser/`, vendor commit `b4babc0` (2026-04-26, последний touch vendor-дерева).
Адресат: TL Sitka → Admin

---

## 1. Краткое резюме

**Светофор: ЖЁЛТЫЙ.**

1. Парсер реально работает в проде через два чистых entry-point'а (`/api/avito/search` для Lead Inbox, `/api/sourcing/search` для общего sourcing), у обоих обвязка адаптирована в `app/parsers/avito_v2_adapter.py`. Vendor-дерево не правится 34 дня (`b4babc0` 2026-04-26 → 2026-05-28), zero drift между нашим клоном и тем что было импортировано — то есть код **либо живой и стабильный, либо upstream-abandoned**. Это принципиально отличает ситуацию от inventory-аудита.
2. Реальный объём vendor'а ~4.9K LOC — на порядок меньше inventory-парсера. Из них **~1.7K LOC активно используются** (market core + `shared.query_intent` + `shared.config` + `shared.product.sitka_catalog`), остальные ~3.2K LOC (`shared.product.interpreter`, `shared.product.weight_profiles`, `shared.playwright_utils`, `shared.price_utils`, `shared.product_weight_profiles`, и `market.cli` который сломан — импортирует отсутствующий `orchestrator.query_intent`) — dead. Соотношение dead-к-alive ~2:1, но абсолют небольшой — поверхность re-vendor'а managable.
3. Главная архитектурная проблема **не в самом парсере, а в его роли cross-vendor donor для `app/inventory/`** после форка inventory-парсера 2026-05-27 (`8f1d5c4`, PR #90). 10 файлов из forked inventory кода **продолжают импортировать `shared.product.sitka_catalog` и `shared.apify_runner` из vendor/avito_parser/**. То есть `vendor/avito_parser/` сейчас обслуживает два независимых консумера: свой собственный `market.*` API + namespace-package `shared.*` для забранного-в-fork соседа. TASK A2 (queued, blocked by TASK D) должен это закрыть.

Один реальный риск-сигнал (не блокирующий) — **дубль реализации Apify-runner'а** в одном vendor'е: `market/avito/client.py` (`ZenStudioAvitoClient`, sync, urllib, 195 LOC) и `shared/apify_runner.py` (`ApifyRunner`, async, aiohttp, 199 LOC). Оба делают token rotation, curl-fallback на SSL-ошибки, _is_rotation_error матчинг. 394 LOC двух почти-идентичных реализаций — потенциальный источник расхождения поведения между Avito- и Amazon/eBay-каналами.

Рекомендация (см. §7): **оставить как vendored** — с двумя условиями (см. §6 backlog).

---

## 2. Карта парсера

### Точка входа из нашего кода

```
Lead Inbox UI («Поиск на Авито»)
    │ POST /api/avito/search
    ▼
sitka-services/app/routes/avito.py:114 avito_search
    │ calls search_market(query, size, color, max_results, location)
    ▼
sitka-services/app/parsers/avito_v2_adapter.py:166 search_market
    │ → asyncio.to_thread(MarketService.get_market_snapshot)
    ▼
vendor/avito_parser/market/service.py:319 MarketService.get_market_snapshot
    │ → cost_guard → ZenStudioAvitoClient.search → normalize → match → snapshot
```

И параллельно:

```
sitka-web (UI «Парсер», sourcing tab)
    │ POST /api/sourcing/search   (include_avito=true)
    ▼
sitka-services/app/routes/parsing.py:227 search_avito (v1-shape compatibility)
    ▼
sitka-services/app/parsers/avito_v2_adapter.py:92 search_avito
    │ → MarketService.get_market_snapshot → _to_v1 (down-convert)
    ▼
v1-shape list[AvitoListing]   (title, url, price_rub, seller, condition, availability)
```

### Что внутри парсера

| Слой | Файл | LOC | Назначение |
|------|------|-----|------------|
| Facade | `market/__init__.py`, `market/avito/__init__.py` | 16+11 | Re-export `MarketService`, `get_market_snapshot`, `ZenStudioAvitoClient`, etc. |
| Контракты | `market/models.py` | 53 | `AvitoListing` (raw + v2 catalog detection), `MarketSnapshot` (aggregate). |
| Service | `market/service.py` | 434 | `MarketService.get_market_snapshot` + match logic (`_match_listing`, exact/similar/all). 24h cache via CostGuard. Stats: `_price_stats`, `_seller_breakdown`. |
| Cost guard | `market/cost_guard.py` | 36 | `query_key` (sha256[:16]), `should_fetch` (cache TTL check). Single-flight отсутствует — комментарий 22-28 явно фиксирует "not thread-safe / async-safe, max_concurrent_queries=1 is assumed". |
| DB | `market/database.py` | 262 | SQLite (`avito_listings`, `market_runs`, `market_snapshots`). WAL + synchronous=NORMAL. Default path через `shared.config.ROOT_DIR / "data/market.db"` (в проде override через `SITKA_MARKET_DB_PATH=/app/market-cache/...`). |
| Client | `market/avito/client.py` | 195 | `ZenStudioAvitoClient` — **sync** urllib-based, Apify run-then-poll (`/runs` + `/actor-runs/:id` + `/datasets/:id/items`). Token rotation (`_is_token_rotation_error`: 401/402/429 + 403-with-quota-text). `_request_json_via_curl` fallback на macOS-SSL-fail. |
| Normalize | `market/avito/normalize.py` | 148 | Raw Apify item → `AvitoListing`. Detect `model_family`, `camo_color`, `size`, `is_preorder`, `is_non_sitka` через `shared.product.sitka_catalog`. |
| Query builder | `market/avito/query_builder.py` | 15 | Тривиальный: `brand + model_tokens` join, fallback на `raw_query`. **Игнорирует color/size** — см. F-MATCH-1. |
| CLI | `market/cli.py` | 127 | **СЛОМАН**: импортирует `from orchestrator.query_intent import parse_query_intent`, но папки `orchestrator/` нет в vendor-дереве. См. F-DEAD-1. |
| Catalog facts | `shared/product/sitka_catalog/{__init__,canonical,facts,matching,contracts}.py` | 178+504+~640+288+175 ≈ 1.8K | Brand-knowledge: Optifade-паттерны, размеры, ailas-lookup, model_family detection. **Используется как нашим парсером, так и forked inventory** (cross-vendor donor — см. §3). |
| Shared infra (alive) | `shared/__init__.py`, `shared/config.py`, `shared/query_intent.py`, `shared/apify_runner.py` | 13+193+13+199 = 418 | `config` — `SITKA_*` env mapping + JSON config files; `query_intent` — `QueryIntent` dataclass (brand/model_tokens/color/size); `apify_runner` — **второй** Apify клиент (async, aiohttp), отдельно от `ZenStudioAvitoClient`. |
| **Не используется приложением** | `shared/product/interpreter/{__init__,contracts,semantics}.py` (722 LOC), `shared/product/weight_profiles.py` (307), `shared/product_weight_profiles.py` (4 — compat shim), `shared/price_utils.py` (59), `shared/playwright_utils.py` (32), `market/cli.py` (127 + сломан), `market/test_market.py` (479 — не в CI pytest path) | ~1.7K | Dead для нашего use case. См. F-DEAD-1/2. |

### LOC alive vs dead

| Категория | LOC | % vendor |
|-----------|-----|----------|
| Alive (используется через `app/parsers/avito_v2_adapter.py` и через `/api/avito/search`) | ~1,840 | 38% |
| Alive (cross-vendor donor для `app/inventory/`) — `shared.product.sitka_catalog.*` + `shared.apify_runner` | ~1,985 | 41% |
| Dead для нашего use case | ~1,030 | 21% |
| **Total vendor** | **4,855** | **100%** |

(Cross-vendor donor overlap: `sitka_catalog` живёт в первой строке для `avito_v2_adapter` → `normalize_listing` → `detect_model_family` тоже. Но основная масса его import'ов идёт от inventory-кода.)

### Транзитивные связи

- `market.service` → `shared.query_intent`, `shared.config`, `market.avito.{client,normalize,query_builder}`, `market.{cost_guard,database,models}`.
- `market.avito.client` → `shared.config` (для `get_secret_value("apify_token")`).
- `market.avito.normalize` → `shared.product.sitka_catalog` (для `detect_model_family`, `infer_color_label_from_text`, `infer_size_label_from_text`).
- `shared.apify_runner` → `shared.config` (для tokens). **Никогда не импортируется из `market/`** — он только для inventory-консумеров. То есть в нашем сценарии это **второй**, изолированный код-путь, который к Avito-парсеру самому отношения не имеет.

### Что возвращается

`MarketSnapshot` (models.py:32–53) — aggregate:
- `query`, `location`, `source_actor` (`"zen-studio/avito-listings-scraper"`), `total_listings`, `exact_count`, `similar_count`.
- Price stats: `min_price`, `median_price`, `max_price`, `avg_price`, `price_basis` (`"exact"|"similar"|"all"|"none"`), `priced_count`.
- Channel split: `delivery_count`, `private_seller_count`, `professional_seller_count`, `unknown_seller_count`.
- `representative_examples: list[AvitoListing]` (top-3 — `representative_examples_limit`), `listings: list[AvitoListing]` (все).
- `cached: bool`, `generated_at`.

`AvitoListing` (models.py:7–29) с v2 catalog detections: `model_family`, `camo_color`, `size`, `is_preorder`, `is_non_sitka`, `query_source` + raw passthrough.

### Куда уходит результат

- `/api/avito/search` → `AvitoSearchResponse` (routes/avito.py:69–90), **полная shape** — Lead Inbox UI получает median_price, seller_breakdown, representative_examples, флаги preorder/non-sitka.
- `/api/sourcing/search` (include_avito=true) → `_to_v1` (avito_v2_adapter.py:55–89) сжимает в legacy `AvitoListing` (title/url/price_rub/seller/condition/availability/size/color/location) → `AvitoReferenceCandidate` фронту. **Phase-2 enrichment (model_family, is_preorder, is_non_sitka, seller_type) теряется на границе** — см. F-WIRE-1.
- Никакого взаимодействия с Haskell core'ом — `/api/avito/search` и `/api/sourcing/search` живут целиком в Python. Бизнес-смысл (RUB-quote, маржа) выводит core по `POST /api/leads/:id/quotes`.

---

## 3. Соответствие нашей архитектуре

### Correction 001 — domain decisions в integration layer

**Вердикт: соблюдается лучше, чем у inventory-парсера. Локальные утечки есть.**

- `MarketService` возвращает только статистику и raw-listings — нет ни "good deal / bad deal", ни "margin OK / not OK", ни "this is a quote price". Решения принимает Haskell core отдельным шагом (см. квоутер `Engine.Pricing`). Это правильная граница.
- `is_non_sitka` (normalize.py:88-100) — **флаг качества данных**, не бизнес-решение. Корректно живёт в integration: parser знает что zen-studio actor шумит соседними брендами, отмечает это, оставляет downstream'у решать. Аналогично `is_preorder` (normalize.py:67-85).
- `_match_listing` (service.py:196-216) выставляет `exact_count` / `similar_count` — это **скоринг данных**, не финальный outcome. ОК.
- **Утечка**: `_known_brand_tokens` (service.py:181-182) `{"sitka"}` захардкожен в Python-сервисе. Если завтра компания добавит "Kuiu" или "Sitka Big Game" — правка в integration. Это пограничный случай: парсер должен знать "чьи листинги мы ищем" чтобы фильтровать шум; но это бренд-знание которое в идеале должно быть параметризовано из core. Сейчас приемлемо.
- **Утечка** (более серьёзная): `_generic_product_type_tokens` (service.py:102-120) и `_product_type_clusters` (service.py:123-150) — таксономия товарных типов SITKA (jacket=upper_body, bib=lower_body, etc.). Это **brand-domain knowledge** в интеграционном слое. Если SITKA выпустит новый тип (например, гетры — gaiters уже в clusters но не в generic), правка тут. Дублирует бренд-таксономию в `shared/product/sitka_catalog/facts.py` (`PRODUCT_TYPE_TOKENS`) — две копии одного словаря.
- `shared/product/weight_profiles.py` (307 LOC) — **полностью dead в нашем сценарии**, но содержит pricing-knowledge (`OUNCE_TO_KG`, `DEW_POINT_JACKET_KG`). Если кто-то подключит модуль, получим вторую pricing-модель параллельно с `Engine.Pricing`. Пока dead — не нарушение, но потенциальный risk.

### Граница integration vs domain

- **Интеграция (Python services)** — да: HTTP-fetch Apify, parsing/normalize raw payload, dedup, кэш SQLite, retry-token-rotation, scoring exact/similar.
- **Домен (Haskell core)** — quote-формула, USD↔RUB, marge%, lead-pipeline — не трогается парсером. ОК.
- **Серая зона**: `_match_listing` решает "это exact match для запроса оператора или similar" — это **policy** ("совпадение бренда + всех model-токенов + color + size = exact, иначе similar"). Для бизнеса это уже логика интерпретации цены (на exact-матчах median считается надёжно, на similar — анчор). Сейчас приемлемо потому что фронт показывает обе цифры; не приемлемо станет если бизнес-логика начнёт делать решения "автоквоут если exact median > X". Тогда формулу надо вытаскивать в core.

### Cross-vendor coupling — критично для §3, см. также §6/§7

Forked inventory-код (`sitka-services/app/inventory/`, выделен 2026-05-27 в `8f1d5c4`/PR #90) **продолжает импортировать** из vendor/avito_parser:

| Файл | Импорт |
|------|--------|
| `app/inventory/catalog/sitka_canon.py:10` | `from shared.product.sitka_catalog import canonical_product_title` |
| `app/inventory/adapters/stores/ebay.py:17` | `from shared.apify_runner import ApifyAllTokensExhaustedError, ApifyError, ApifyRunner` |
| `app/inventory/adapters/stores/amazon.py:24` | `from shared.apify_runner import ApifyAllTokensExhaustedError, ApifyError, ApifyRunner` |
| `app/inventory/adapters/stores/eurooptic.py:23` | `from shared.product.sitka_catalog import (...)` |
| `app/inventory/adapters/stores/outdoor_insiders.py:15` | `from shared.product.sitka_catalog import normalize_text` |
| `app/inventory/adapters/stores/shopify_stores.py:12` | `from shared.product.sitka_catalog import canonical_color_key` |
| `app/inventory/adapters/stores/als.py:14` | `from shared.product.sitka_catalog import compact_size_length_label, is_color_axis_label, is_size_aux_axis_label, is_size_axis_label` |
| `app/inventory/adapters/stores/franks.py:18` | `from shared.product.sitka_catalog import (...)` |
| `app/inventory/adapters/families/bigcommerce_support.py:15` | `from shared.product.sitka_catalog import (...)` |
| `app/inventory/adapters/families/shopify_support.py:17` | `from shared.product.sitka_catalog import (...)` |

То есть **10 inventory-файлов завязаны на vendor/avito_parser/shared/**. Если завтра TASK A2 (запланированный) расширит `app/inventory/_sitka_catalog.py` и `app/inventory/_apify_runner.py` чтобы покрыть весь surface, эти 10 импортов переедут на `app.inventory._*` — и **avito_parser перестанет быть cross-vendor donor**. После A2 vendor обслуживает только своего natural консумера (`market.service`).

До A2 нельзя удалять или сильно модифицировать `shared/product/sitka_catalog/` и `shared/apify_runner.py` — сломаются inventory-адаптеры. Это надо явно понимать: vendor сейчас находится "под двумя контрактами", один из которых временный.

### Архитектурные инварианты (architecture-invariants.md)

| Инвариант | Соответствие |
|-----------|--------------|
| I1. Layer import discipline (Haskell) | N/A — Python parser. |
| I3. ExchangeRate locked | N/A — парсер не считает RUB на основе курса; price_rub приходит "сырым" из Avito. |
| I4. Auth fail-closed | `/api/avito/search` и `/api/sourcing/search` под bearer-auth по умолчанию — см. `tests/test_security.py:56` `/api/avito/stats` 401 без токена. |
| I5. DB CHECK constraints | N/A — SQLite кэш в Python, не Haskell core. |
| P5. Scientific end-to-end | N/A для парсера; цены приходят как `float` из Apify, и `_price_stats` возвращает `Optional[float]` (statistics.median/mean). На границе `_to_v1` → `AvitoListing.price_rub: Optional[float]` → `AvitoReferenceCandidate.price_rub: float`. Никакого Scientific в нашем парсер-flow, что согласуется с тем что core отвечает за денежные домены. |
| Operational data → Services (Correction 006) | Соблюдается — listings, snapshots, market_runs все живут в Python SQLite (`/app/market-cache/market.sqlite3` в проде). |

### Risk tier

`app/parsers/avito_v2_adapter.py`, `app/routes/avito.py`, `app/routes/parsing.py` — **Tier B** (sitka-services/**/*.py). Сам vendor формально не в tiers; де-факто `market/service.py` и `market/avito/client.py` имеют blast-radius на оба route-эндпоинта → Tier B при касании.

`shared/product/sitka_catalog/` имеет дополнительный blast-radius: ещё 10 inventory-файлов в `app/inventory/` (Tier B), плюс собственно `normalize.py`. Любое изменение alias-таблиц или canonical-функций затрагивает обе цепочки. Это **самый горячий vendor-файл** в обоих контурах.

---

## 4. Потенциальные проблемы по категориям

### 4.1 Производительность

| Параметр | Значение | Замечание |
|----------|----------|-----------|
| `poll_interval_seconds` | 3 | client.py:63-67, дефолт. Не агрессивно — для long-running Apify актора (десятки секунд) разумно. |
| `timeout_seconds` (request) | 60 | client.py:68-72, дефолт. Покрывает один Apify run; total deadline в `_call_actor_with_token` = `time.time() + 60`. |
| `cache_ttl_hours` | 24 | cost_guard.py:13. Один и тот же запрос второй раз не бьёт Apify — медиана / max_price из cached snapshot. Это хорошо для cost-control. Если оператор хочет "свежие данные сегодня" — нужна invalidation, но её нет (см. F-CACHE-1). |
| `representative_examples_limit` | 3 | service.py:339. Что показать оператору. |
| **Concurrency** | **NONE** | `CostGuard.should_fetch` явно помечен (cost_guard.py:22-28): "not thread-safe / async-safe, max_concurrent_queries=1 assumed". В нашей системе `/api/avito/search` запускается из UI и из poller'а — пока операторов один, ок; при двух параллельных запросах на тот же query risk двух Apify run'ов. См. F-CONC-1. |
| **`MarketService` instantiation** | новая на каждый запрос | `avito_v2_adapter.py:127` / `:198` — `MarketService()` строит свежий `ZenStudioAvitoClient` и `MarketDatabase` per call. `MarketDatabase` открывает SQLite-connection в `_connect()` per-method (`with self._connect() as connection`). Нет re-use connection pool. Для редких запросов (≤ десятки в день) — допустимо; latency overhead на SQLite connect ~1ms. |
| **`asyncio.to_thread`** | да, `avito_v2_adapter.py:131` | MarketService sync, обёртка делает `to_thread`. Нет потенциальной блокировки event-loop'а. ОК. |

**Apify cost.** Стоимость каждого uncached run'а = 1 Apify actor-run в free-плане (10/месяц на токен). С multiple tokens через `_load_configured_tokens` (client.py:35-43) + rotation (client.py:97-111) — суммарно `N_tokens × 10` запросов в месяц. При 30 deal/мес и 2 search-кликах per deal = 60 Apify runs / месяц. На 6+ токенах вполне покрывается, но **операция строго рассчитана на free-tier scale**. Если придёт второй оператор и начнёт активно использовать UI — будет затыкаться в `AvitoApifyQuotaExhausted` (route/avito.py:133-142 → 402).

### 4.2 Надёжность

- **Apify меняет API**: один из самых стабильных компонентов (zen-studio actor-id хардкоден `"zen-studio~avito-listings-scraper"` в client.py:48 — если автор актора удалит/ренейм, ловим `MarketClientError` без специфичного reason'а). Нет fixture / contract тестов.
- **Avito меняет HTML/JSON layout**: парсер сам не скрейпит HTML — это делает Apify-актор. Если зен-студио сломается на стороне Avito, мы это узнаём через empty/error от Apify, не через свой код. Это **сильный плюс** vendor'а — изоляция от поломки источника.
- **Network flap**: `_request_json` (client.py:150) **нет retry** — одна 5xx или TCP-reset на любом из трёх вызовов (POST /runs, GET /actor-runs, GET /datasets/items) → `MarketClientError` → 502 у нас. Token rotation работает **только** для quota-сигналов (401/402/429), не для генерических 5xx.
- **Долгий Apify run**: дефолтный timeout 60s покрывает большинство кейсов. На особо медленных актор-стартах (cold-start ~30-60s + execution ~30s) можем напороться. В `avito_v2_adapter.py:131` `asyncio.to_thread` подразумевает что мы блокирующе ждём весь run в отдельном потоке — клиент HTTP-запроса может уйти (timeout у nginx/uvicorn) пока Apify ещё считает, но Apify run продолжится и snapshot будет сохранён в БД — следующий запрос с тем же query попадёт в cache. Это не баг, но это **silent fail для оператора** при долгом UI-таймауте.
- **Apify quota exhaustion**: обрабатывается явно через `MarketTokenExhaustedError` → `MarketClientError("All Apify tokens failed: ...")` (client.py:106-111). На route-уровне мы дополнительно ловим `_detect_apify_quota_exhaustion` (avito_v2_adapter.py:148-163) для случая когда актор возвращает sentinel `{"_upgradeRequired": True}` — потому что в этом сценарии `MarketService` НЕ ловит ошибку, а строит "пустой" `AvitoListing` со sentinel в raw. **Это правильно построенная defence**.
- **Logging**: `market.service`, `market.avito.client`, `market.cost_guard`, `market.database` — **ни одного `logger.warning/info`** в alive surface. `avito_v2_adapter.py` имеет logger но почти не использует (только pass-through через exception). При проблеме на проде debug возможен только через HTTP-уровень logs или через SQLite `market_runs.status` (где записан `"fetched"|"cache_hit"`). Reason'а провала там нет.
- **`is_non_sitka` true-positive vs Apify noise**: zen-studio actor на узких русских запросах подсовывает соседние бренды (Kuiu, Sitka-альтернативы) — флаг работает (normalize.py:74-78 hard-coded regex), но на новых брендах будем пропускать. UI должен фильтровать `is_non_sitka=true` — проверка не сделана в `/api/avito/search` маппере (см. routes/avito.py:108).

### 4.3 Безопасность

- **Credentials**: 
  - Apify tokens через env (`SITKA_APIFY_TOKEN(S)`) → `shared.config.get_secret_value`. ОК.
  - Avito OAuth tokens (для Messenger API, не парсера) — отдельный `app/channels/avito/client.py`, не в scope этого аудита.
  - Нет ни одного hardcoded API key в vendor'е (в отличие от inventory's `_KLEVU_API_KEY` в `rogers.py`).
- **Query injection**: 
  - `ZenStudioAvitoClient.search` собирает payload как dict, передаёт через `json.dumps` (client.py:154). Безопасно.
  - URL strings через f-string (client.py:115, 124, 128) — токен попадает в query string. Это идиоматично для Apify API (они так показывают примеры), но **token логируется** если кто-то залогирует full URL. Сейчас не логируется явно, но любой `logger.debug("requesting %s", url)` ниже по стеку утечёт. Низкий risk.
  - `CostGuard.query_key` (cost_guard.py:18-20) делает sha256 от `query|location|max_results` — не identifier-injection, нет SQL-уровня. ОК.
- **Headers**: `_request_json` шлёт минимум — `Accept`/`Content-Type`. Нет fingerprint headers, нет custom User-Agent → запрос идёт от urllib дефолтного UA. Для Apify API нормально, для прямого Avito-скрейпинга было бы блок — но прямого Avito-скрейпинга нет.
- **SSL fallback через curl**: `_request_json_via_curl` (client.py:171-195) запускается только на `CERTIFICATE_VERIFY_FAILED`. На проде Linux это не должно происходить (certifi работает). На macOS dev — workaround для отсутствующего Python-installer'ов root-cert'а. **Никакого weakening SSL** — curl использует системные сертификаты. ОК.
- **Параллельный `shared/apify_runner.py` _curl_post_dataset** — то же самое, аналогичный fallback (apify_runner.py:176-199), та же модель безопасности.
- **SQLite местоположение**: `shared.config.ROOT_DIR = Path(__file__).resolve().parent.parent` → `sitka-services/vendor/avito_parser/`. Default DB-path `data/market.db` → внутри vendor-директории! В **dev** это значит что pytest-команда (или прямой запуск `python -m market.cli`) пишет в `vendor/avito_parser/data/market.db` — vendor становится "dirty". В **проде** override через `SITKA_MARKET_DB_PATH=/app/market-cache/market.sqlite3` (docker-compose.yml:80) спасает. Но при разработке локально без переменной — да, vendor мутируется. См. F-CONF-1.

### 4.4 Поддерживаемость

- **Изоляция кода**: высокая. Vendor читается как монолитный пакет (`market.*` + `shared.*`), точка соприкосновения с приложением узкая — `avito_v2_adapter.py` импортирует ровно две вещи: `market.service.MarketService` и `shared.query_intent.QueryIntent`. Можно мысленно "вырвать" vendor и заменить — поломаются только эти строки.
- **Cross-vendor donor статус** (см. §3): пока есть, ограничивает свободу правки `shared/product/sitka_catalog/*`. После TASK A2 — снимется.
- **Дублирование Apify-runner'а**: `market/avito/client.py` (`ZenStudioAvitoClient`, sync, urllib, **195 LOC**) и `shared/apify_runner.py` (`ApifyRunner`, async, aiohttp, **199 LOC**) — оба делают одно: запустить Apify актор, подождать результат, ротировать токены при quota. Различия:
  - `ZenStudioAvitoClient` — два-фазный `POST /runs` + поллинг `GET /actor-runs/:id` + `GET /datasets/:id/items`. Sync.
  - `ApifyRunner` — однофазный `POST /acts/:actor_ref/run-sync-get-dataset-items`. Async.
  - `_is_token_rotation_error` (client.py:139-148) vs `_is_rotation_error` (apify_runner.py:48-55) — реализуют **одну и ту же логику** (`401/402/429` + `403`-with-quota-text), но порог "quota markers" отличается: client использует `("token", "quota", "credit", "rate limit", "too many requests", "monthly", "usage")`, runner — `("token", "quota", "credit", "limit", "monthly", "usage")` (нет "rate limit" / "too many requests" в runner). То есть **граница "когда переключить токен" неодинаковая** между Avito-парсером (наш use case) и Amazon/eBay inventory-адаптерами. См. F-DUP-1.
  - 394 LOC всего на двух почти-идентичных клиентов. Если завтра Apify ротирует API URL или добавит новую quota-сигнатуру, придётся править в двух местах.
- **Добавление новой Avito-секции** (например, фильтр по региону): тривиально — `build_market_query` в query_builder.py + параметр в `search_market`. Адаптер `MarketService.get_market_snapshot` принимает intent целиком.
- **Добавление поддержки другого actor'а** (например, замена zen-studio при поломке): требует копипаст `ZenStudioAvitoClient` с новым actor_ref. Класс не параметризован по actor'у — `actor_name`/`actor_ref` — class-атрибуты.
- **Тесты vendor'а**: 479 LOC в `market/test_market.py` — **не в CI pytest path**. CI workflow (.github/workflows/ci.yml:255-257) запускает `python -m pytest tests/ -v` в `sitka-services/` (не в vendor). Тесты vendor'а инструктивны (мокают `ZenStudioAvitoClient` через `FakeZenClient`, проверяют exact/similar matching, token rotation, cache TTL) — это **рабочий golden source** для regression-testing'а, но de-facto он отключён. Никто не узнает если вендор-логика поломается. См. F-TEST-1.
- **Наши тесты vendor-функциональности** в `sitka-services/tests/` — нет ни одного. `test_avito_client.py`, `test_avito_poller.py`, `test_avito_sender.py` все про Messenger OAuth API (`app/channels/avito/`), не про парсер. `tests/test_routes_http.py` мокает sourcing search, но Avito-ветку (`include_avito=True`) не покрывает.
- **Re-vendor процедура**: НЕ задокументирована. Нет `UPSTREAM.md`. Информация о происхождении живёт только в комментариях:
  - `pyproject.toml:7-10`: "Renamed on vendor import (2026-04-24) from upstream 'sitka-office' to 'sitka-avito-parser' so the package name doesn't clash with this repo". Upstream — `github.com/upside2002-maker/sitka` (README.md:239-240).
  - Git history: 2 коммита (`a5fd928` 2026-04-24 + `b4babc0` 2026-04-26). **34 дня** с последнего vendor-touch'а.
- **Заметная странность vendor README.md**: содержит огромный block ("Sitka Office is a Python monolith ... `delivery/telegram/` = product Telegram bot ... `orchestrator/` = task routing ... `knowledge/` = local memory") про модули которых **физически нет в нашем vendor-tree** (только `market/` и `shared/`). README описывает upstream целиком, а к нам импортирован только submodule. Это запутывает агентов: можно думать что у нас есть `orchestrator.query_intent`, а на самом деле нет (см. F-DEAD-2 — сломанный `market/cli.py`).

### 4.5 Тесты

- **В vendor'е** `market/test_market.py` 479 LOC — но не запускается ни в CI, ни локально через `python -m pytest`. Покрывает:
  - Token rotation (3 теста).
  - `build_market_query` (2 теста).
  - `normalize_listing` field mapping (1 тест).
  - `_match_listing` exact/similar/all (≥4 тестов).
  - `CostGuard.should_fetch` cache TTL behaviour.
  - `MarketDatabase` upsert / save_snapshot / get_latest_snapshot_metadata / latest_run_status.
  - Всё через `FakeZenClient` или real `MarketDatabase` на tmp file.
  Тесты **good quality**, golden-style assertions. Их можно подключить в CI парой строк → `pytest -v vendor/avito_parser/market/test_market.py`. См. F-TEST-1, P1-2.
- **На стороне `sitka-services/tests/`**:
  - `test_avito_client.py`, `test_avito_poller.py`, `test_avito_sender.py` — про **Messenger OAuth API**, не про парсер. Не относится к этому аудиту.
  - `test_security.py:56-63` — проверяет что `/api/avito/stats` требует auth. Минимальное покрытие route.
  - `test_routes_http.py` — есть тесты `/api/sourcing/search` но Avito-ветку (`include_avito=True`) не трогают.
  - **Нет ни одного теста на `app/parsers/avito_v2_adapter.py`**. `search_market`, `search_avito`, `_to_v1`, `_detect_apify_quota_exhaustion` не покрыты ничем.
  - **Нет integration-теста** через `/api/avito/search` с mocked `MarketService`.
- **Нет fixture / golden-теста на сырой Apify-ответ**. Если завтра zen-studio actor поменяет shape (например, `priceFormatted` станет `price_text`), `normalize_listing` молча начнёт давать `price_text=None` на каждом листинге — оператор увидит "цена отсутствует" но не поймёт почему. Простой record-and-replay fixture (одна реальная страничка JSON, 5-10 KB) закрыл бы класс регрессий.
- **Нет property-тестов** на `_match_listing` / `_match_listing` exact/similar границы. Чистые функции, идеальные кандидаты. Случай "Sitka Jetstream Black XL" vs title "Sitka Men's Jetstream Bib Jacket Black" — exact или similar? Решает `len(matched_tokens) == len(model_tokens)` (service.py:212) — easy to break при добавлении новых tokens.

---

## 5. Конкретные находки

Координаты `file:line`. По каждой: что увидел, почему проблема, направление фикса (без кода).

### F-DUP-1 (high) — две независимые Apify-runner реализации в одном vendor'е

**Файлы**: `vendor/avito_parser/market/avito/client.py:46-195` (`ZenStudioAvitoClient`, sync/urllib, 195 LOC) и `vendor/avito_parser/shared/apify_runner.py:67-199` (`ApifyRunner`, async/aiohttp, 199 LOC).
**Проблема.** Оба реализуют одно и то же — запустить Apify актор, дождаться dataset, ротировать токен при quota. Логически конкурирующие cовпадения:
- `_is_token_rotation_error` (client.py:139-148): markers `("token", "quota", "credit", "rate limit", "too many requests", "monthly", "usage")`.
- `_is_rotation_error` (apify_runner.py:48-55): markers `("token", "quota", "credit", "limit", "monthly", "usage")`.
- Разница: avito-клиент детектит `rate limit` / `too many requests` отдельно, inventory-runner — только общее `limit`. Это значит **при rate-limit (НЕ quota) на 403 от Amazon-actor'а inventory токен НЕ ротируется**, а на Avito-actor'е — ротируется. Разное поведение в той же ситуации.

Дополнительно: `MarketTokenExhaustedError` (client.py:19) vs `ApifyTokenExhaustedError` (apify_runner.py:28) — два разных типа exception на одну сущность. `app/parsers/avito_v2_adapter.py:138 AvitoApifyQuotaExhausted` — третий тип, на route-уровне.

**Направление.** При v2 vendor-обновлении выяснить у upstream'а почему два клиента; если случайный артефакт эволюции — мерджить в один (предпочтительно `ApifyRunner`-стиль, async, `run-sync-get-dataset-items` однофазный — он более минимальный). Если намеренно — задокументировать в `UPSTREAM.md` "почему два" и зафиксировать инвариант "рoutator-markers одинаковые". До слияния — синхронизировать markers вручную (добавить `"rate limit"`, `"too many requests"` в `_is_rotation_error`) и закрыть property-тестом.

### F-DEAD-1 (medium) — `market/cli.py` сломан (импортирует несуществующий модуль)

**Файл**: `vendor/avito_parser/market/cli.py:11-17`.
```
try:
    from market.cost_guard import CostGuard
    from market.database import MarketDatabase
    from market.service import get_market_snapshot
    from orchestrator.query_intent import parse_query_intent
    ...
except ImportError:
    ...
    from orchestrator.query_intent import parse_query_intent
    ...
```
**Проблема.** Папки `orchestrator/` нет ни в vendor-tree, ни в `app/`. Любой `python -m market.cli snapshot "..."` упадёт `ModuleNotFoundError: No module named 'orchestrator'`. Это **upstream-only CLI** (на upstream'е есть orchestrator/), который у нас просто dead. Никто не зовёт `market.cli` из нашего кода (grep чистый). pyproject.toml:38-46 list'ает `"orchestrator*"` в packages.find — но папки нет, setuptools тихо пропустит.

**Направление.** Удалить `market/cli.py` (127 LOC) и `market/test_market.py`-зависимости на cli (если есть — посмотреть). Либо оставить с явным `# UPSTREAM-ONLY: requires orchestrator/ which we don't vendor` комментарием. **Не приоритет** — никого не ломает, занимает 127 LOC мусора.

### F-DEAD-2 (low) — ~1K LOC vendor'а никем не используется

**Файлы**:
- `shared/product/interpreter/{__init__,contracts,semantics}.py` (722 LOC) — query interpretation на основе catalog facts. Никто из `app/` или `market/*` не импортирует. Внутри vendor'а используется только `shared.product.interpreter.semantics` тестами `test_market.py`, но через `query_intent` (которое мы юзаем). Удалить interpreter — потеряем тесты, но не runtime.
- `shared/product/weight_profiles.py` (307 LOC) — pricing/oz-to-kg helpers, `DEW_POINT_JACKET_KG` константы. Полностью dead, дублирует/конкурирует с `Engine.Pricing` если кто-то подключит.
- `shared/product_weight_profiles.py` (4 LOC compat shim) — re-export первого. Dead.
- `shared/playwright_utils.py` (32 LOC) — `wait_ms`, `goto_with_wait`, `click_with_wait`. Для browser-парсинга, который мы не используем. Dead.
- `shared/price_utils.py` (59 LOC) — `extract_price_values`, `extract_price_range`. Для HTML-scrape store-адаптеров (наш Avito парсит через Apify-actor, не HTML). Dead.

Всего ~1.1K LOC dead. Меньше чем у inventory (30K), но всё-равно тянется в Docker-образ.

**Направление.** При v2 vendor-rsync — экранировать через эксклюды (`shared/product/interpreter/`, `shared/product/weight_profiles.py`, `shared/product_weight_profiles.py`, `shared/playwright_utils.py`, `shared/price_utils.py`). Это даст ~1.1K LOC reduction, ~22% от vendor surface. Не блокирующее — приемлемо как было.

### F-CACHE-1 (medium) — нет invalidation 24h-кэша, нет "force-refresh"

**Файл**: `vendor/avito_parser/market/service.py:336-354` (`MarketService.get_market_snapshot` cache branch) + `vendor/avito_parser/market/cost_guard.py:22-36` (`should_fetch`).
**Проблема.** `CostGuard.should_fetch` возвращает `USE_CACHE` если `latest_created_at <= 24h`. Оператор не может попросить "перепроверь Avito сейчас, кэш плевать" — нет параметра. UI вызывает `/api/avito/search` без force-флага. Если оператор обновляет ту же страничку и думает что увидит свежие цены — увидит cached snapshot до конца 24h.

В реальности это редко мешает: 24h — разумное окно. Но при ситуации "оператор клиента ведёт прямо сейчас и хочет последнюю цену" этой кнопки нет.

**Направление.** Добавить `force_refresh: bool = False` параметр в `MarketService.get_market_snapshot` → bypass cost_guard когда true. Прокинуть до `AvitoSearchRequest.force_refresh` в route. UI добавляет кнопку "Обновить" (отдельно от обычного search). LOC ~10. Не блокирующее, но low-cost UX win.

### F-MATCH-1 (medium) — `build_market_query` теряет color/size

**Файл**: `vendor/avito_parser/market/avito/query_builder.py:9-15`.
```
def build_market_query(intent: QueryIntent) -> str:
    parts = []
    if intent.brand:
        parts.append(intent.brand)
    parts.extend(token for token in intent.model_tokens if token)
    query = " ".join(parts).strip()
    return query or str(intent.raw_query or "").strip()
```
**Проблема.** Если оператор передаёт color="Subalpine" и size="XL", они **молча выбрасываются** при построении query — Apify видит только `"sitka jetstream"`. Дальше `_match_listing` (service.py:196-216) использует color/size **для фильтрации результатов**, но запрос изначально широкий. То есть мы:
1. Качаем 10 (`max_results`) листингов на бренд+модель — не фильтруем по цвету/размеру.
2. Из них считаем exact (= в title есть и color и size) — может быть 0 если top-10 — другие цвета.
3. Снапшот говорит "0 exact" но это не значит "нет в продаже" — просто не в первой странице Apify.

Фронт показывает оператору `exact_count=0` — соблазн интерпретировать как "оригинал в этом размере не продают". Реальность: "не было в первой странице, надо смотреть больше".

**Направление.** Включать color/size в query когда они есть (`f"sitka jetstream subalpine XL"`). Тестировать на корпусе реальных кейсов — Avito search neutralизирует non-matches, что может ухудшить total_listings (больше "0 results" reasons). Это **trade-off**, надо мерять. Низкий приоритет — `exact_count` сейчас работает как noisy-signal-but-better-than-nothing, но семантика confusing.

### F-CONC-1 (low) — `CostGuard` не thread-safe; явный комментарий "max_concurrent_queries=1"

**Файл**: `vendor/avito_parser/market/cost_guard.py:22-28` (комментарий в `should_fetch`).
**Проблема.** При двух параллельных запросах на один и тот же `query_key`:
- Оба видят `latest_created_at = None` (или старше 24h) → оба `FETCH`.
- Оба бьют Apify (waste tokens).
- Оба пишут snapshot row в DB (race на `record_run` — autoincrement спасает от deadlock, но семантически два запуска).

Vendor авторы это знают (комментарий), но не закрыли. У нас сегодня риск низкий — `/api/avito/search` зовётся UI'ем одного оператора. При двух операторах или при cron'ах риск растёт.

**Направление.** Single-flight per query_key через asyncio.Lock dict, либо через FOR UPDATE SKIP LOCKED-логику в SQLite. Минимум — задокументировать в `app/parsers/avito_v2_adapter.py` "do not call concurrently for same query". Не блокирующее на текущем масштабе.

### F-WIRE-1 (medium) — Phase-2 enrichment теряется в legacy v1-shape

**Файл**: `app/parsers/avito_v2_adapter.py:55-89` (`_to_v1`).
**Проблема.** `AvitoListing` (v2, models.py:7-29) несёт `model_family`, `camo_color`, `size`, `is_preorder`, `is_non_sitka`, `query_source`, `seller_type` (`"private"|"company"|"shop"`), `image_url`, `category_id`. `_to_v1` берёт title/url/price_rub/seller/condition (всегда `"unknown"`)/availability/size/color/location и выбрасывает остальное.

`/api/sourcing/search` (через `search_avito` → `_to_v1`) — это где enrichment теряется.
`/api/avito/search` (через `search_market`) — проходит как есть, **enrichment виден в Lead Inbox UI**.

То есть Lead Inbox видит больше, чем sourcing-таблица. Это **дизайн-выбор**, но сейчас оператор должен помнить "в Lead Inbox смотрю seller_type+is_non_sitka, в sourcing-табе нет". Cognitive load.

Аналогично F-WIRE-1 в inventory-аудите. Поведение consistent — мы платим за enrichment и не везде его показываем.

**Направление.** Расширить `AvitoReferenceCandidate` (route/parsing.py) полями `seller_type`, `is_preorder`, `is_non_sitka`, `model_family` — или **наоборот**, явно задокументировать в комментарии `_to_v1` "Phase-2 fields intentionally dropped, sourcing-tab UI doesn't need them". Продуктовая задача, не блокирующее.

### F-CONF-1 (low) — vendor пишет SQLite внутрь vendor-дерева при отсутствии env override

**Файл**: `vendor/avito_parser/shared/config.py:8` (`ROOT_DIR = Path(__file__).resolve().parent.parent` → vendor-root) + `vendor/avito_parser/market/database.py:28-31` (default `data/market.db` относительно ROOT_DIR).
**Проблема.** Если `SITKA_MARKET_DB_PATH` не выставлен (dev / smoke / тест), `MarketDatabase()` создаст `sitka-services/vendor/avito_parser/data/market.db`. Это:
- Мутирует vendor-дерево (плохо для git status).
- Если несколько dev-инстансов работают параллельно, делят файл.
- На re-vendor (когда придёт) можно случайно перетереть.

В проде override `SITKA_MARKET_DB_PATH=/app/market-cache/market.sqlite3` (docker-compose.yml:80, .env.example:98) — норм. Но в dev'е и в pytest по умолчанию — да.

Тестам vendor'а (`test_market.py`) это не мешает — они явно передают `MarketDatabase(str(Path(tmp_dir) / "market.db"))`.

**Направление.** В `MarketDatabase.__init__` — если default path попадает внутрь vendor (Path(...) detection), переписать на `Path("/tmp/sitka-market-dev.db")` с warning'ом. Либо просто документировать в README + добавить fail-loud check "ROOT_DIR содержит 'vendor' — выставьте SITKA_MARKET_DB_PATH явно". Не блокирующее.

### F-TEST-1 (medium) — vendor's `test_market.py` (479 LOC) не запускается в CI

**Файл**: `vendor/avito_parser/market/test_market.py` (479 LOC, ~12 тестовых классов/методов) + `.github/workflows/ci.yml:255-257` (pytest path `tests/` без vendor).
**Проблема.** Vendor имеет хороший golden-source тестов (`FakeZenClient`, `RotatingZenClient`, проверки `_match_listing` exact/similar, cache TTL, token rotation). Но pytest конфигурируется только на `sitka-services/tests/`. Если кто-то изменит vendor (а мы не правили его 34 дня, но **можем**), regression поймает только прод-trafficker.

**Направление.** Добавить в CI step `pytest sitka-services/vendor/avito_parser/market/test_market.py -v` отдельным или к существующему пайплайну. ~3 LOC в `.github/workflows/ci.yml`. Может потребовать import-path трюк (vendor `try: from market...; except ImportError: from ...`) — пара дополнительных строк. Сэкономит десятки часов на следующей же сломаной верстке.

### F-OBS-1 (low) — нулевая обзорность runtime'а

**Файл**: весь vendor'ный `market/` + `shared/`.
**Проблема.** Нет `logger.info("running market query=%s", query)`, нет `logger.warning("Apify took %.1fs", elapsed)`, нет `logger.error("token rotation, used=%d/%d", ...)`. При проблеме на проде — debug возможен только через SQL по `market_runs` (status='fetched'/'cache_hit', cost_usd=null всегда).

Параллельный `app/channels/avito/client.py` — отлично логирован. Парсер — silent.

**Направление.** Подключить `logger = logging.getLogger("market.service")` / `"market.avito.client"` / `"market.cost_guard"`. Логировать на каждый `should_fetch` → решение, на каждый `_call_actor_with_token` → token_idx + elapsed + result. Низкий приоритет — но при первом инциденте превратится в high.

### F-CANON-1 (low) — бренд-таксономия SITKA в shared/product/sitka_catalog

**Файл**: `vendor/avito_parser/shared/product/sitka_catalog/facts.py` (~640 LOC бренд-знания: Optifade-паттерны, размеры, model-family aliases, color-aliases).
**Проблема.** Это **бренд-данные SITKA Gear** в integration layer. Если SITKA выпустит новый паттерн (Marsh 2.0?) или новый размер (4XLT?), правка тут — а не в core. Параллельно те же данные дублируются в `app/parsers/avito_classify.py` (SITKA_PATTERNS, SIZE_PATTERNS — частично, для Russian text), `app/inventory/_sitka_catalog.py` (slice того же facts.py), `Engine.Marketing.atLeast` (Haskell — но не для каталога) и legacy `app/parsers/_archive/avito_v1.py`.

Это **тот же F-CANON-1 из inventory-аудита**, проявленный с другого края. Канонический Sitka brand data разбросан по 4 местам.

**Направление.** Long-term: single-source-of-truth (отдельный пакет или таблица в core, синхронизация). Sitka не часто меняет таксономию; сейчас приемлемо как состояние.

---

## 6. Приоритизированный backlog

### P0 — критично, влияет на оператора прямо сейчас

**Нет.** Это структурно отличает avito-парсер от inventory-парсера. F-PARSE-1 (`title_matches` substring bug) inventory-парсера блокировал двусловные запросы; здесь аналогичного блокирующего бага не найдено. `MarketService` работает; `/api/avito/search` отвечает; cost-guard кэширует; token rotation покрывает quota.

### P1 — важно, видно при детальном использовании

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| P1-1 | Синхронизировать `_is_rotation_error` markers между `client.py` и `apify_runner.py` (добавить `"rate limit"`, `"too many requests"` в runner) (F-DUP-1). | ~5 LOC | На rate-limit от Amazon/eBay inventory НЕ ротируем токен → потеря квоты на простой 429 retry. Avito-парсер ротирует — поведение разное в той же ситуации. |
| P1-2 | Подключить vendor's `test_market.py` к CI (F-TEST-1). | ~3-5 LOC в `.github/workflows/ci.yml` | Vendor logic regressions не ловятся. При случайном edit'е vendor'а узнаем только на проде. |
| P1-3 | TASK A2 (отдельный, уже queued): расширить `app/inventory/_sitka_catalog.py` и завести `app/inventory/_apify_runner.py`, чтобы закрыть 10 cross-vendor imports (F-CANON-1, §3). | ~150-200 LOC (расширение + удаление импортов в 10 файлах) | После A2 — vendor/avito_parser перестаёт быть cross-vendor donor → свобода правки `shared/product/sitka_catalog/*` восстанавливается. До A2 любая правка catalog потенциально ломает inventory. |
| P1-4 | Force-refresh параметр в `/api/avito/search` (F-CACHE-1). | ~10 LOC | Оператор не может сбросить cache когда хочет свежие цены прямо сейчас. |

### P2 — следует сделать при следующей крупной vendor-итерации или вместе с P1-1/P1-3

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| P2-1 | Создать `vendor/avito_parser/UPSTREAM.md` (когда impоrted, какой commit, как делать re-vendor, какие модули dead). | ~30 LOC docs | При смене подрядчика / новой сессии следующий аудит-агент тратит время на reverse-engineering "что это и откуда". |
| P2-2 | Удалить `market/cli.py` (сломанный, тянет несуществующий `orchestrator`) (F-DEAD-1). | -127 LOC | Чисто шум. Низкий риск (никто не зовёт). |
| P2-3 | Vendor exclude'ы при re-vendor: `shared/product/interpreter/`, `shared/product/weight_profiles.py`, `shared/product_weight_profiles.py`, `shared/playwright_utils.py`, `shared/price_utils.py` (F-DEAD-2). | ~1.1K LOC vendor reduction + ~15 строк rsync эксклюдов | Носим в Docker-образ ~1.1K LOC что никем не зовётся. Может потребоваться повторная сверка после TASK A2 (interpreter может стать dead-er). |
| P2-4 | Прокинуть Phase-2 enrichment в `AvitoReferenceCandidate` или явно задокументировать "не нужно" (F-WIRE-1). | 30-50 LOC route + опционально web | Cognitive load: одинаковые данные в двух UI-вкладках по-разному. Продуктовое решение. |
| P2-5 | Подключить logging в `market/service.py` и `market/avito/client.py` (F-OBS-1). | ~15-20 LOC | При первом инциденте debug возможен только через SQLite. На текущем масштабе живёшь без этого. |

### Nice-to-have

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| N-1 | Property-тест на `_match_listing` exact/similar/none граница (F-MATCH-1 связан). | ~50 LOC | Нулевая обзорность регрессий чистых функций. |
| N-2 | Record-and-replay fixture на 1 реальный zen-studio Apify dataset (Sitka Jetstream Jacket, 20 KB JSON). | ~30 LOC test + 20 KB fixture | Поломка zen-studio actor'а ловится только на проде. |
| N-3 | Решить про `build_market_query` color/size (F-MATCH-1) — измерить на корпусе queries. | ~5 LOC fix + product analysis | `exact_count=0` сейчас confusing — оператор может неверно интерпретировать. |
| N-4 | Single-flight per `query_key` через asyncio.Lock (F-CONC-1). | ~15 LOC | Пока операторов 1, риск низкий. При 2+ или при cron-trigger'ах — растёт. |
| N-5 | Merge `ZenStudioAvitoClient` и `ApifyRunner` в один runner (F-DUP-1, второй уровень). | -200 LOC + refactor | После P1-1 (синхронизация markers) — это уже cosmetics. Можно никогда не делать, если оба клиента стабильны. |

---

## 7. Рекомендация по работе дальше

**Оставить как vendored.** С двумя условиями.

Обоснование (отличия от inventory-аудита):

1. **Vendor не меняется**. 34 дня (2026-04-26 → 2026-05-28) — zero modifications к vendor-tree. Все наши правки (F-PARSE-1 substring fix, F-PERF-1 timeout cap) делались в **inventory** (fork) — здесь не понадобились. Сейчас vendor живёт как закрытый чёрный ящик с одним вызовом из `avito_v2_adapter.py`. Если так и останется, fork-стоимость превышает пользу.

2. **Объём управляемый**. 4.9K LOC vendor vs 40K у inventory. Из них ~1.8K alive (`market/` + `shared/{config,query_intent}`). При re-vendor мы рассматриваем меньше кода чем при чтении одного среднего PR. `shared/product/sitka_catalog/` (1.8K) сегодня нужен и как parser-data, и (временно) для inventory — fork сейчас означает выбор между двумя контрактами одновременно, что усложняет.

3. **Поверхность контакта с приложением узкая и стабильная**. `avito_v2_adapter.py` импортирует ровно 2 символа из vendor'а: `MarketService` и `QueryIntent`. Cost-of-fork-vs-keep упирается в эти 2 import'а — а они стабильны (никто не предлагает их менять).

4. **Cross-vendor donor — временный**. До TASK A2 vendor/avito_parser обслуживает inventory-fork (10 файлов). После A2 — снимется. **Делать fork avito_parser до завершения A2 — это запутывание зависимостей** (одновременно перепрыгиваем catalog facts из vendor в две независимые форк-зоны). А после A2 — посмотрим, есть ли реальная нужда форкнуть; скорее всего нет.

5. **Поломок upstream не видно**. Inventory rec'нул `F-PARSE-1` потому что нашли реальный регрессионный баг (двусловные запросы). У avito такого блокера нет — `MarketService` рабочий, fix-list по приоритету начинается с P1.

6. **Никаких "невозможно патчить чисто"**. P1-1 (синхронизация markers) — 5 LOC, можно сделать как vendor-patch с комментарием `# UPSTREAM-DIFF: kept rate-limit marker for parity` + добавить в `UPSTREAM.md` "if you re-vendor, re-apply this 5-LOC diff". P1-4 (force_refresh) — можно сделать в `avito_v2_adapter.py` через bypass `MarketService` пути (вызывать `client.search` напрямую), без правки vendor'а. Всё что в P1 — обвязывается на нашей стороне.

Альтернативы (отвергнутые):

- **Fork & own**. Сейчас даёт **отрицательный** ROI: создаст вторую копию `shared/product/sitka_catalog/` (одну в forked avito, вторую в forked inventory), параллельную с третьей в `app/inventory/_sitka_catalog.py`. Три копии бренд-таксономии — точно хуже чем сейчас.
- **Переписать частично**. F-DUP-1 (два Apify-runner'а) — единственный кандидат на "переписать". Но это вторичная оптимизация: оба работают, оба синхронизированно делают рабочее дело. Слияние — N-5 уровень, не сейчас.
- **Не трогать вообще**. Сильнее текущей рекомендации. Сейчас всё-таки нужны P1-1, P1-2, P1-4 — это insurance. Их можно сделать без форка.

**Условия "оставить как vendored":**

(a) **Завести `UPSTREAM.md`** в `vendor/avito_parser/` (P2-1) — когда импортировано, какой commit, как делать re-vendor, что dead, какие наши patch'и (если появятся). Сейчас этой информации нет, что **создаёт реальный риск** для следующей сессии (как для inventory: `UPSTREAM.md` существовал и спас от перепутывания).

(b) **Сделать P1-2 (vendor tests в CI)** в ближайшую неделю — `~5 LOC`, окупается на первом же случайном edit'е. Без этого vendor — это "trusted but not verified" чёрный ящик.

После TASK A2 (закрывает cross-vendor coupling) — **переоценить**. Если к тому моменту upstream `sitka-office` (от которого vendor'или) подал bugfix или новый Avito-actor — заберём через re-vendor, продолжим vendored. Если upstream мёртв (не было PR за полгода после нашего forking inventory) — тогда форк станет естественной эволюцией. Сейчас этого не видно.

Cost оценка: UPSTREAM.md + CI hookup = ~30 минут работы. P1-1 sync markers + P1-4 force_refresh = ещё ~30 минут. Total: одна короткая сессия. Без этой работы парсер продолжает работать; с ней — закрываем три из четырёх P1 без структурных изменений.
