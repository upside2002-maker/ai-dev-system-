# Архитектурный аудит vendor/inventory_parser

Дата: 2026-05-21
Автор: tech-lead (sub-agent, deep research mode)
Источник: `sitka-services/vendor/inventory_parser/`, vendor SHA `a7dc558` (commit `b4babc0`, PR #67, 2026-04-27).
Адресат: TL Sitka → Admin

---

## 1. Краткое резюме

**Светофор: ЖЁЛТЫЙ.**

1. Парсер работает, операционно достаточен для 4 поставщиков, фундаментальной угрозы домену нет — Correction 001 не нарушена в худшей форме (бизнес-смысл назначает Haskell core через `/api/sourcing/search`, парсер только собирает данные).
2. Огромный объём dead-кода для нашего сценария: из ~40K LOC vendor'а используется только `inventory/v2/runtime/*` + `inventory/v2/adapters/*` + `inventory/v2/query.py` + `inventory/v2/types.py` + `inventory/v2/catalog/sitka_canon.py` (~9.4K LOC). Остальные ~30K LOC (`snapshot/`, `catalog_sync/`, `module_service.py`, legacy `inventory/*.py`) не вызываются нашим `app/`, но сидят в Docker-образе, импортируются транзитивно (runtime/service.py → snapshot/types.Governor) и расширяют поверхность будущих re-vendor'ов.
3. На критичных адаптерах (Amazon, eBay, eurooptic) есть скрытые внешние зависимости — Apify-токены, residential proxy pool с hardcoded путём `/srv/sitka-qa/config/proxies.txt`. Парсер тихо деградирует, если их нет: eurooptic будет 403/429 на каждой попытке, потому что fallback на прямой fetch с IP VPS заблокирован Vercel'ом — это известная upstream-проблема (см. docstring eurooptic.py:640).

Один блокирующий критический баг для нашего use case — **«contiguous phrase matching»** в `BaseStoreAdapter.title_matches` (base.py:452-470): запрос из двух слов вроде «Blizzard parka» требует чтобы подстрока `"blizzard parka"` дословно входила в title. Реальный товар «Sitka Men's Blizzard Bib Parka» не пройдёт, потому что слова не подряд. Это и есть зафиксированный баг 2026-05-13.

Рекомендация (см. §7): **fork'нуть и владеть** — vendor-модель не оправдывает себя при текущем темпе наших правок и непрозрачности upstream'а.

---

## 2. Карта парсера

### Точка входа из нашего кода

```
sitka-web (UI «Парсер»)
    │ POST /api/sourcing/search
    ▼
sitka-services/app/routes/parsing.py:160 run_predeal_sourcing
    │ calls run_parser_search(query, stores)
    ▼
sitka-services/app/parsers/inventory_v2.py:14 get_parser_service (lazy singleton)
    │ → ParserService()  (vendor)
    ▼
vendor/inventory_parser/inventory/v2/core.py
    │ thin facade →
    ▼
vendor/inventory_parser/inventory/v2/runtime/service.py:33 ParserService
```

### Что внутри парсера

| Слой | Файл | Назначение |
|------|------|------------|
| Facade | `inventory/v2/__init__.py`, `core.py` | Public surface: re-export `ParserService`, `ItemResult`, `StoreRunResult`, `parse_query`, `DEFAULT_STORE_NAMES`. |
| Контракты | `inventory/v2/types.py` | Immutable dataclasses: `ParsedQuery`, `SearchHit`, `SearchExecution`, `VariantCell`, `ItemResult`, `StoreRunResult` + три `Literal` enum'а: `QueryMode`, `StoreRunStatus`, `ItemStatus`. |
| Query | `inventory/v2/query.py` | `parse_query()` извлекает `(search_text, size, color)` из raw-строки. Зависит от `shared.product.sitka_catalog` (катамологическое знание о размерах/паттернах). |
| Runtime | `inventory/v2/runtime/service.py` | `ParserService.run_store` (один магазин), `run_many` (несколько магазинов параллельно). Параллелизм фиксирован: `_RUN_MANY_CONCURRENCY=2`, `_RUN_STORE_TIMEOUT_SECONDS=35.0`, `_PRODUCT_CHECK_TIMEOUT_SECONDS=25.0` (см. service.py:28–30). |
| Runtime helpers | `runtime/execution.py`, `postprocess.py`, `session.py` | check_product параллелизм с per-adapter semaphore, dedupe+sort, aiohttp session с certifi SSL. |
| Registry | `inventory/v2/registry.py` | Список из 20 адаптеров и их инстанцирование в `build_registry()`. |
| Adapter base | `inventory/v2/adapters/base.py` (576 строк) | `BaseStoreAdapter`: ABC с `search`/`check_product`, плюс утилиты — fingerprinting User-Agent, dedup, нормализация цвета/размера, `summarize_variant_rows` (главный choke-point канонизации). |
| Families | `inventory/v2/adapters/families/shopify_support.py` (615), `bigcommerce_support.py` (662) | Семейные базовые реализации для Shopify (`/search/suggest.json`, `/products.json`, `.js`) и BigCommerce (HTML scraping + product attribute payloads). |
| Stores | `inventory/v2/adapters/stores/*.py` | 20 живых магазинов + 1 dead (`basspro.py` — не в registry). Большинство — тонкие наследники family-классов (`one_shot.py`, `gohunt.py`, `kevins.py` ≈ 5–10 строк). Тяжёлые — `rogers.py` (768), `eurooptic.py` (1700+), `franks.py` (713), `scheels.py` (900+), `als.py` (390), `outdoor_insiders.py` (490), `amazon.py` (220 + Apify), `ebay.py` (143 + Apify). |
| Catalog | `inventory/v2/catalog/sitka_canon.py` | Brand-knowledge: канонические имена Optifade patterns (Subalpine, Marsh, …) + размеров (S–4XL). |
| identity_coverage | `inventory/v2/adapters/identity_coverage.py` | Static-data: какие магазины какие identity-поля отдают (sku/variant_id/gtin). Не вызывается app'ом. |
| **Не используется приложением** | `inventory/v2/snapshot/*` (~12K LOC), `inventory/v2/catalog_sync/*` (~5K LOC), `inventory/v2/module_service.py`, `inventory/v2/module_api.py`, `inventory/*.py` legacy (~12K LOC), `inventory/v2/adapters/stores/basspro.py` | См. §5 находка F-DEAD-1. |

### Транзитивная связь runtime → snapshot

Несмотря на то что `module_service.py` (с `SnapshotStore`/`SnapshotReader`) не используется, `runtime/service.py:15` импортирует `from inventory.v2.snapshot.types import Governor` — этот импорт single-class Protocol-стаба формально вытягивает весь `snapshot/types.py` и его транзитивы (на практике безопасно, snapshot/types.py — pure-data). А `adapters/stores/eurooptic.py:20` импортирует `from inventory.v2.snapshot.proxy_pool import get_shared_pool` — это уже реальная функциональная зависимость с file-system I/O (см. F-EURO-1).

### Что возвращается

`StoreRunResult` (типы.py:107–122):
- `store`, `query`, `query_mode`, `status` (`ok|empty|blocked|failed`), `search_url`, `elapsed_ms`, `reason`.
- `items: tuple[ItemResult, ...]`, `similar_hits: tuple[SearchHit, ...]`.

`ItemResult` содержит обширные поля Phase E: `variant_cells`, `available_sizes`, `unavailable_sizes`, `available_colors`, `unavailable_colors`, `current_price`, `original_price`, `currency`, `stock_count`, `category_path`, `image_url`, `gender`, `is_on_sale`, `is_new`, `stock_tracking_level`. **Из них в наш `OfferCandidate` доходят только `title`, `url`, `status`, `price` (text), `price_usd` (derived).** Всё остальное — Phase E enrichment — обрезается в `app/routes/parsing.py:200–210`. См. F-WIRE-1.

### Куда уходит результат

`parsing.py:248–258` собирает `SourcingSearchResponse` → возвращает фронтенду. Никакого взаимодействия с Haskell core'ом нет — `/api/sourcing/search` живёт целиком в Python. Бизнес-решения (margin, RUB-quote) принимает Haskell core по запросу `POST /api/leads/:id/quotes` (см. CLAUDE.md → DM-flow).

---

## 3. Соответствие нашей архитектуре

### Correction 001 — domain decisions в integration layer

**Вердикт: в основном соблюдается, но есть утечка brand-knowledge.**

- `ItemResult.status` (`in_stock | out_of_stock | variant_not_found | unknown`) и `StoreRunResult.status` (`ok | empty | blocked | failed`) — это **факты о парсинге**, не бизнес-решения. Это нормально для integration layer.
- `inventory/v2/catalog/sitka_canon.py` содержит закрытый словарь брендовых Optifade-паттернов и размеров. Это **бренд-данные SITKA Gear**, не парсинг-механика. Они должны жить в Haskell core (или в специальной shared-таблице), но сейчас live'ят в parser-vendor. Если SITKA выпустит новый паттерн, мы будем править его в integration layer и надеяться что upstream re-vendor его подберёт. Это лёгкая, но реальная утечка.
- `inventory/v2/snapshot/pricing.py` (DealPrice, discount calculation в bps) — отдельная мини-модель цены, дублирующая `Engine.Pricing` (Haskell, Tier A). Но она dead в нашем сценарии — `SnapshotStore` не используется. То есть прямого нарушения нет, но при попытке вытащить snapshot/ из dead-кода это станет проблемой.
- `app/parsers/inventory_v2.py:25 build_query_from_deal` — определена, но **никогда не вызывается** (см. F-DEAD-2). Это бизнес-логика «как из Deal-полей собрать строку запроса», которая в текущем коде живёт в `app/routes/parsing.py:151 _build_query` параллельно. Дубликат шага сборки.

### Граница integration vs domain

- **Интеграция (Python services)** — да: aiohttp-fetch, парсинг HTML/JSON, retry-агностичный fan-out, fingerprint UA, нормализация цвета/размера.
- **Домен (Haskell core)** — quote-формула, margin, USD↔RUB, lead-pipeline, attribution — всё на месте, парсер их не трогает.
- **Серая зона**: brand-таксономия (паттерны Sitka), `query_mode` (broad vs target) — `parse_query` решает за пользователя интент. Это пограничный случай: для парсера он функционально оправдан (broad+target меняет жёсткость match'инга), для бизнеса это уже policy. Сейчас приемлемо.

### Архитектурные инварианты (architecture-invariants.md)

| Инвариант | Соответствие |
|-----------|--------------|
| I1. Layer import discipline (Haskell) | N/A — Python parser. |
| I3. ExchangeRate locked | N/A — парсер не считает RUB. |
| I4. Auth fail-closed | N/A для парсера; route `/api/sourcing/search` сидит за tier-1 auth по умолчанию (см. `app/main.py`). |
| P5. Scientific end-to-end | **Нарушено в snapshot/pricing.py** (использует `Decimal`, не Scientific), но это dead в нашем сценарии. Если когда-то заходим в snapshot/, надо перепроверить. |
| Operational data → Services (Correction 006) | Соблюдается — listings, search-cache, snapshot-store. Всё в Python, если бы snapshot/ использовался. |

### Risk tier

Файл `app/parsers/inventory_v2.py` и `app/routes/parsing.py` по `.claude/risk-tiers.md` относятся к **Tier B** (sitka-services/**/*.py). Сам vendor — отдельный субмодуль; формально его в tiers нет, но любое касание `adapters/families/*.py` или `runtime/service.py` имеет blast-radius на all-stores → де-факто Tier B.

---

## 4. Потенциальные проблемы по категориям

### 4.1 Производительность

| Параметр | Значение | Замечание |
|----------|----------|-----------|
| `_RUN_MANY_CONCURRENCY` | 2 | Жёстко зашит в `runtime/service.py:28`. При 20 магазинах sequential walk занимает ≈10 «волн». |
| `_RUN_STORE_TIMEOUT_SECONDS` | 35.0 | На больших стороннях (Klevu/Apify Amazon с timeout 180s в самом адаптере!) timeout-обёртка станет узким местом. `amazon.py:34 search_timeout_seconds = 180` — несовместим с runtime'овым 35s, фактически Amazon всегда отвалится по `store_timeout`, если Apify не вернётся за 35 секунд. См. F-PERF-1. |
| `_PRODUCT_CHECK_TIMEOUT_SECONDS` | 25.0 | На каждый product check. |
| `product_check_concurrency` | 4 default, 8 для Shopify/BigCommerce | Внутри одного магазина параллелится. |
| Retry policy | `_request_retry_max=0` | `set_request_policy` существует в `base.py:137`, но **никто его никогда не вызывает**. Все fetch'и one-shot. См. F-PERF-2. |
| Кэширование | Нет на runtime-уровне | `etag_cache` есть в `catalog_sync/`, но не подключен к live-парсеру. Snapshot-store (read-cache) тоже dead. Каждый POST `/api/sourcing/search` бьёт все магазины с нуля. |

### 4.2 Надёжность

- **Поставщик меняет HTML/API**: ни один адаптер не имеет fixture/golden-test (см. 4.5). Поломка ловится продакшеном.
- **Network flap**: нет retry → одиночная 5xx или TCP-reset сразу даёт `failed` со статусом для всего магазина.
- **API мёртв**: 401/403/429 → `blocked` (`base.py:208`). Reason text сохраняется, но в `OfferCandidate` он теряется (`StoreSearchSummary.reason` есть, но UI его не показывает). Оператор видит «0 предложений» без причины.
- **Logging**: в `runtime/` и `adapters/base.py` **нет ни одного `logger.warning/info`**. Eurooptic — единственное место с `_proxy_logger`. Если что-то ломается на проде, мы видим только финальный `StoreRunResult.status="failed"` + reason — без stack trace, без HTTP-кодов, без URL'ов. См. F-OBS-1.
- **Apify quota exhaustion**: обрабатывается явно (amazon.py:63, ebay.py:52), `ApifyAllTokensExhaustedError` → `blocked` + reason `apify_tokens_exhausted`. Это **лучшая часть кода** — единственный реально проверяемый failure-mode со специфическим reason'ом. См. также `app/parsers/avito_v2_adapter.py:148 _detect_apify_quota_exhaustion` — параллельная защита.

### 4.3 Безопасность

- **Credentials**: 
  - Apify tokens через env (`SITKA_APIFY_TOKEN(S)`) — ОК.
  - Klevu API key **захардкоден** в `rogers.py:29` (`_KLEVU_API_KEY = "klevu-166084263252815555"`). Это public-frontend ключ магазина, не наш секрет, утечки не страшно, но это пример «магической константы из upstream». Если магазин ротирует ключ — поломка. См. F-SEC-1.
  - eurooptic proxy state — `/srv/sitka-qa/config/proxies.txt` (proxy_pool.py:30). На наших VPS пути нет → fallback на прямой fetch. См. F-EURO-1.
- **Query-injection при построении URL**: `query_url` (base.py:189) использует `urllib.parse.quote_plus` — корректно. SQL-injection N/A (всё JSON/HTTP).
- **Headers**: random fingerprint из 5 захардкоженных вариантов (`base.py:26-52`). Низкое разнообразие, anti-fingerprint paranoid sites легко распознают.
- **`request_ssl = False`** на множестве адаптеров: `one_shot.py:11`, `rogers.py:208`, `gohunt.py`, `jootti.py`, `lennyshoe.py`, `kevins.py`, `phantom.py`, `franks.py`, `als.py`, `outdoor_insiders.py`, `eurooptic.py` и др. → отключается верификация TLS-сертификата у магазина. Это значит MITM-атакующий мог бы подменить ответ. На US-магазинах с валидными CA-сертами выключать SSL необязательно; оставлено как «починили дев-проблему, забыли вернуть». См. F-SEC-2.

### 4.4 Поддерживаемость

- **Добавление нового магазина**:
  - Если магазин на Shopify/BigCommerce — 5-10 строк в `adapters/stores/shopify_stores.py` или `bigcommerce_stores.py` + регистрация в `registry.py`.
  - Если custom — отдельный файл-наследник `BaseStoreAdapter`, 300-1700 строк (rogers, eurooptic, franks, scheels). Каждый — отдельный мир с regex-парсингом ad-hoc HTML/JSON.
- **Изоляция адаптеров**: высокая. Каждый custom-адаптер — самостоятельный кусок без shared state.
- **Дублирование**:
  - `_PRODUCT_LINK_RE` независимо определён в shopify_support, bigcommerce_support, rogers — три разных regex для «найди ссылку на /products/». Совместное `urllib.parse` обёртка отсутствует.
  - `parse_query` инстанцирован в amazon.py:22 и ebay.py:15 чтобы разобрать title (size/color) — те же помощники, что в runtime/, но используются на post-search обогащение. Корректно, но архитектурно скрытая связь — `amazon` использует sitka-vocabulary (через `parse_query`) для парсинга eBay/Amazon-листингов чужих продавцов.
- **Тесты vendor'а удалены** (UPSTREAM.md:13–17). При re-vendor'е мы не можем убедиться что upstream-логика осталась консистентной — наша единственная проверка это `app/tests/test_routes_http.py`, где `run_parser_search` мокается. См. 4.5.
- **Re-vendor процедура** документирована в UPSTREAM.md:71–93. Но это **manual rsync**. Если upstream рефакторит `inventory/v2/snapshot/` (например, ломает сигнатуру `Governor`), наш runtime сломается на импорте — не на функциональности.

### 4.5 Тесты

- **В vendor'е тестов нет** (excluded на vendor-time, см. UPSTREAM.md:13). 
- **На стороне `sitka-services/tests/`** — единственный покрывающий парсер файл `test_routes_http.py:159–283`. Он целиком **mock'ает `run_parser_search`**: 7 кейсов проверяют только route-level логику (404, 502, 503, нормализация stores, фильтрация по `max_offers`, fallback на mock Avito).
- **Никаких fixture-тестов адаптеров.** Никаких record-and-replay HTTP-тестов. Если завтра Rogers поменяет Klevu-схему ответа, мы узнаем об этом, когда оператор откроет UI «Парсер» и увидит 0 hits.
- **Никаких property-тестов** на `parse_query` (broad/target classifier), `summarize_variant_rows`, `dedupe_hits`. Эти функции — pure, идеальные кандидаты, но не покрыты.
- **`title_matches` (см. §5 F-PARSE-1)** — баг с двусловным запросом не ловится никаким тестом ни в vendor'е, ни у нас.

---

## 5. Конкретные находки

Координаты `file:line`. По каждой: что увидел, почему проблема, направление фикса (без кода).

### F-PARSE-1 (critical) — contiguous-phrase match ломает двусловные запросы

**Файл**: `inventory/v2/adapters/base.py:452–470`.
```
def title_matches(self, title, parsed_query):
    matched_tokens = self.matched_tokens(title, parsed_query)
    if len(matched_tokens) != len(parsed_query.search_tokens):
        return False
    if parsed_query.query_mode == "broad" or len(parsed_query.search_tokens) <= 1:
        return True
    search_phrase = normalize_text(parsed_query.search_text)
    normalized_title = normalize_text(title)
    if bool(search_phrase) and search_phrase in normalized_title:
        return True
    ...
    return False
```
**Проблема.** Для `query="Blizzard parka"`:
- `parse_query` → `size=""`, `color=""`, `search_tokens=("blizzard","parka")`, `len>1` → `query_mode="target"`.
- В `title_matches`: оба токена match'нулись (`matched_tokens==search_tokens`), но требуется чтобы подстрока `"blizzard parka"` дословно входила в normalized_title. Для title `"Sitka Men's Blizzard Bib Parka"` substring-check провалится — между «blizzard» и «parka» стоит «bib».
- Возврат `False` → `_product_hit` не добавляет hit ни в exact ни в similar (shopify_support.py:115–128 строго требует match через `title_matches` или через `_title_is_similar` который тоже опирается на `matched_tokens`). Hit теряется.
- Single-word query («parka») работает потому что попадает в `len(search_tokens) <= 1` ветку.

**Это и есть зафиксированный баг 2026-05-13.** Не починен.

**Направление.** Снять требование contiguous substring — оставить «все токены присутствуют» + heuristic похожести (например, расстояние Levenshtein между токенами в title не больше N слов). Сделать flag/feature, чтобы можно было откатить если приведёт к false-positives. Покрыть property-тестом.

### F-EURO-1 (high) — eurooptic transparent-fail без proxy

**Файл**: `inventory/v2/adapters/stores/eurooptic.py:640–680`, `inventory/v2/snapshot/proxy_pool.py:238–266`.
**Проблема.** Eurooptic adapter переопределяет `fetch_text` и сначала пытается через residential proxy:
```
proxy_pool = get_shared_pool()
if proxy_pool is None:
    return await super().fetch_text(...)  # direct fetch
```
`get_shared_pool()` пытается прочитать список прокси с `/srv/sitka-qa/config/proxies.txt` (захардкоженный путь из upstream-инфры). На нашем VPS такого файла нет → `pool.entries()` пуст → возврат None → fallback на прямой fetch с IP VPS. Из docstring (eurooptic.py:641): «The VPS egress IP is Vercel-blocked on eurooptic.com, so direct HTTP always returns 403/429». То есть eurooptic с очень высокой вероятностью **всегда `blocked`** в нашем деплое.

**Направление.** Либо явно подключить нашу proxy-инфру (env `SNAPSHOT_PROXY_LIST=…`, своя сетка), либо в `registry.py` исключить eurooptic из `DEFAULT_STORE_NAMES` пока нет прокси. Сейчас оператор ждёт 35 секунд timeout и получает `blocked` без подсказки почему. Минимум — добавить специальный reason `eurooptic_requires_proxy` и обработать его в маппере route'а как «магазин временно отключён».

### F-PERF-1 (high) — Amazon timeout заведомо превышает runtime cap

**Файл**: `inventory/v2/adapters/stores/amazon.py:34` (`search_timeout_seconds = 180`), `inventory/v2/runtime/service.py:29` (`_RUN_STORE_TIMEOUT_SECONDS = 35.0`).
**Проблема.** Внутри `AmazonAdapter.search` → `ApifyRunner.run_actor_sync(timeout_seconds=180)`. Снаружи `run_many` оборачивает `run_store` в `asyncio.wait_for(..., timeout=35.0)`. Apify junglee-actor сам по себе ~30s typical. С учётом холодного старта актора оператор получает `failed:store_timeout` ещё до того, как Apify ответит. **Amazon фактически не работает в текущей конфигурации.**

**Направление.** Поднять `_RUN_STORE_TIMEOUT_SECONDS` до 60–90s (Apify slow по природе), либо вычислять cap из per-adapter параметра `search_timeout_seconds`, либо вытащить Amazon/eBay в отдельный pipeline (background fetch + cache, не блокирующий sourcing UX). Похожее уже сделано для Avito в `avito_v2_adapter.py` через `asyncio.to_thread`.

### F-PERF-2 (medium) — нет retry даже на transient errors

**Файл**: `inventory/v2/adapters/base.py:131–139`. Knobs `_request_retry_max=0` и `set_request_policy` не вызываются ни одним кодом-путём (grep'ы по vendor'у и app'у нулевые).
**Проблема.** Одна 502/503/timeout от поставщика → магазин `failed`. На сетках с реальной flak это даёт false-negative «магазин блокирует», которое выглядит как F-EURO-1 даже когда поставщик работает.

**Направление.** Вызвать `set_request_policy(retry_max=2, backoff_cap_s=5)` при инстанцировании ParserService в `app/parsers/inventory_v2.py:21`. Реальная retry-логика в `base.py` сейчас закодирована, но не задействована потому что max=0. Перепроверить что путь живой.

### F-OBS-1 (medium) — нулевая обзорность runtime'а

**Файл**: весь `inventory/v2/runtime/` и `inventory/v2/adapters/base.py`.
**Проблема.** Нет `logger.info("running store=%s", store)`, нет `logger.warning("blocked")`. При проблеме на проде debug возможен только через stdout aiohttp'а (HTTP-уровень). `set_fetch_observer` (base.py:134) есть, но не подключён. Reason-text в `StoreRunResult` дроссельный (`shopify_rate_limited`, `apify_tokens_exhausted` etc.) — это лучшее что у нас есть.

**Направление.** Подключить `logger = logging.getLogger("inventory.v2.runtime.service")`. Логировать start/end каждого `run_store` с store, elapsed, status, reason. На уровне `_notify_fetch_observer` — структурированные события для будущей метрики. Это **не требует** правок vendor'а, можно сделать через monkey-patch в `app/parsers/inventory_v2.py:get_parser_service` (set_fetch_observer на каждый адаптер).

### F-WIRE-1 (medium) — Phase-E enrichment теряется на route-границе

**Файл**: `app/routes/parsing.py:195–210`.
**Проблема.** `ItemResult` несёт `variant_cells`, `available_sizes`, `unavailable_sizes`, `available_colors`, `unavailable_colors`, `image_url`, `category_path`, `original_price`, `currency`, `stock_count`, `is_on_sale`, `is_new` и т.д. — это всё что Phase E собирал. Маппер берёт только `title`, `url`, `status`, `price`. Phase-E enrichment вычисляется, но никогда не уходит в UI.

**Это не баг — это нереализованная возможность.** Цена кода (Phase E внутри адаптеров) платится без выгоды. Если бы мы показывали оператору `image_url` и `available_sizes`, выбор предложения был бы быстрее.

**Направление.** Либо расширить `OfferCandidate` и `OfferCandidatesList.tsx` чтобы рендерить миниатюры/доступные размеры (продуктовая задача), либо явно задокументировать «Phase E мы не используем», чтобы при следующем re-vendor не задавать вопрос «зачем оно».

### F-WIRE-2 (low) — `in_stock` коллапсирует три статуса в один

**Файл**: `app/routes/parsing.py:207` (`in_stock=item_payload.get("status") == "in_stock"`).
**Проблема.** `ItemResult.status` имеет 4 значения: `in_stock | out_of_stock | variant_not_found | unknown`. В `OfferCandidate.in_stock` остаётся булева. Оператор видит «out_of_stock» товары и «variant_not_found» как один и тот же «нет в наличии». Семантика разная: «out_of_stock» — точно такой же товар, но без размера; «variant_not_found» — товар есть, но не вашего размера/цвета (значит можно заказать другой вариант или просить заводить под заказ).

**Направление.** Прокинуть `status` enum как есть до фронта или ввести трёх-state `availability: in_stock | wrong_variant | out_of_stock` на route-уровне.

### F-DEAD-1 (low) — ~30K LOC dead из 40K vendored

**Файлы**: `inventory/v2/snapshot/*` (12K LOC), `inventory/v2/catalog_sync/*` (5K), `inventory/v2/module_service.py`, `inventory/v2/module_api.py`, legacy `inventory/*.py` (12K — `inventory_search.py`, `search_orchestrator.py`, `browser_truth_audit.py`, `snapshot_*.py`, `store_smoke.py` и т.д.), `inventory/v2/adapters/stores/basspro.py` (28K bytes, не в registry).
**Проблема.** Эти модули НЕ вызываются из `app/`. Транзитивно нужны только две вещи:
1. `inventory.v2.snapshot.types.Governor` (Protocol-стаб, безопасно).
2. `inventory.v2.snapshot.proxy_pool.get_shared_pool` (нужен eurooptic — реальная I/O).
   
Всё остальное — мёртвый багаж в Docker-образе. Увеличивает поверхность re-vendor'а, привлекает внимание агентов («это нужно понимать?»), запутывает grep'ы по кодовой базе. Кроме того, `snapshot/pricing.py` дублирует `Engine.Pricing` (Haskell, Tier A) — если кто-то решит «давайте использовать snapshot», получим конфликт двух pricing-моделей.

**Направление.** При следующем re-vendor — добавить эксклюды для `snapshot/` (кроме `snapshot/types.py` + `snapshot/proxy_pool.py`), `catalog_sync/`, `module_service.py`, `module_api.py`, legacy `inventory/*.py`. Либо вытащить eurooptic proxy pool в наш собственный код и удалить `snapshot/proxy_pool.py` тоже. Это сократит vendor в ~3 раза.

### F-DEAD-2 (low) — `build_query_from_deal` объявлена, не вызывается

**Файл**: `app/parsers/inventory_v2.py:25–37`.
**Проблема.** Функция определена, но никто её не зовёт (grep весь sitka-services пустой кроме определения). Параллельно `app/routes/parsing.py:151 _build_query` делает похожую сборку из `SourcingSearchRequest`. Это «вторая лестница» — кто-то когда-то писал помощник для будущего use case, который не материализовался.

**Направление.** Удалить или объединить — однострочный фикс при очередной правке файла.

### F-SEC-1 (low) — Klevu API key захардкожен

**Файл**: `inventory/v2/adapters/stores/rogers.py:28–29` (`_KLEVU_API_KEY = "klevu-166084263252815555"`).
**Проблема.** Это **public-facing** API key Rogers'а — его можно достать из любого браузерного DevTools на rogerssportinggoods.com. Утечки не страшно. Но: если Rogers сменит ключ (миграция SaaS-провайдера), наш Rogers-адаптер сломается без предупреждения. Похожая ситуация может быть у других магазинов через прозрачные SaaS-API (klevu, searchspring).

**Направление.** Не приоритет; при следующей поломке адаптера — задокументировать как «hardcoded SaaS public key, обновлять с upstream'а».

### F-SEC-2 (low) — `request_ssl = False` на ≥10 адаптерах

**Файлы**: `one_shot.py:11`, `rogers.py:208`, `gohunt.py` (через shopify_stores), `eurooptic.py`, `franks.py`, `als.py` (vtex), etc.
**Проблема.** Отключает TLS-верификацию для конкретного магазина. На US-магазинах с валидным CA — не нужно отключать. Скорее всего hangover из upstream dev-окружения (corporate-proxy, self-signed). На наших проде риск низкий (исходящий MITM маловероятен), но логически — анти-инвариант.

**Направление.** Аудит — на каких адаптерах реально нужен этот флаг (наверняка eurooptic-через-прокси). Остальные — вернуть `True` (по умолчанию ABC `BaseStoreAdapter.request_ssl = True`).

### F-CANON-1 (low) — бренд-таксономия в integration layer

**Файл**: `inventory/v2/catalog/sitka_canon.py:13–37, 59–75`.
**Проблема.** Закрытый словарь Optifade-паттернов («Subalpine», «Marsh», «Elevated II», ...) и канонических размеров (S, M, L, XL, MT, LT, …) живёт в Python integration layer. Это **бренд-данные SITKA Gear**, а не парсинг-механика. Если SITKA выпустит новый паттерн или новый размер, мы правим vendor (или ждём upstream). Кроме того, эти константы дублируются в `shared.product.sitka_catalog` (avito_parser, sister-vendor) — есть риск рассинхрона.

**Направление.** В долгосрочной перспективе — вытащить в shared single-source-of-truth (отдельный пакет или таблица в core). Сейчас приемлемо — бренд-таксономия меняется редко.

---

## 6. Приоритизированный backlog

### P0 — критично, влияет на оператора прямо сейчас

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| P0-1 | Починить `title_matches` contiguous-phrase bug (F-PARSE-1). Снять substring-check, оставить «все токены присутствуют» + property-test. | ~30 LOC + 50 LOC тестов | Двусловные запросы продолжают возвращать пусто — оператор ловит баг каждый раз заново и теряет доверие к парсеру. |
| P0-2 | Поднять `_RUN_STORE_TIMEOUT_SECONDS` или сделать его per-adapter (F-PERF-1). Сейчас Amazon де-факто не работает. | ~5 LOC в runtime + аудит других адаптеров с long-timeouts. | Amazon оптимизированный pipeline впустую, оператор не видит Amazon-результатов даже когда они есть. |

### P1 — важно, видно при детальном использовании

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| P1-1 | Включить retry policy в base.py через `set_request_policy(retry_max=2)` (F-PERF-2). Проверить что закодированная retry-логика реально работает. | ~5 LOC + дебаг внутри base.py | Single-flake убивает магазин с false-negative «blocked». Маскирует реальные проблемы. |
| P1-2 | Подключить logging в runtime/service.py через `logger.info`/`warning` (F-OBS-1). | ~20 LOC | На проде «магазин не работает» нечем дебажить без воспроизведения локально. |
| P1-3 | Решить вопрос с eurooptic (F-EURO-1) — либо подключить прокси, либо temporarily disable. | ~10 LOC в registry.py или env | Eurooptic присутствует в DEFAULT_STORE_NAMES, оператор каждый раз ждёт его 35-секундный timeout впустую. |
| P1-4 | Прокинуть `status` enum до фронта вместо булевого `in_stock` (F-WIRE-2). | ~30 LOC route+web | Operator UX: «нет в наличии» ≠ «не ваш размер», смешано в одно. |

### P2 — следует сделать при следующей крупной vendor-итерации

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| P2-1 | Эксклюды для re-vendor: убрать `snapshot/` (кроме types.py+proxy_pool.py), `catalog_sync/`, `module_*.py`, legacy `inventory/*.py`, `basspro.py` (F-DEAD-1). Обновить UPSTREAM.md. | 0 LOC product-кода, ~30 строк rsync эксклюдов | Re-vendor каждый раз — N часов на «что нового, что сломалось». При публикации overlay-репо снаружи это лишний шум. |
| P2-2 | Удалить `build_query_from_deal` или связать с `_build_query` (F-DEAD-2). | -13 LOC | Чисто шум. |
| P2-3 | Аудит `request_ssl=False` (F-SEC-2) — вернуть True где можно. | ~10 LOC | Низкий, но логический анти-инвариант. |
| P2-4 | Phase-E enrichment в UI (F-WIRE-1): либо использовать (image, available_sizes), либо документировать как «решили не использовать» в комментарии маппера. | 100–200 LOC web + route | Платим за то что не приносит ценности. Решение продуктовое. |

### Nice-to-have

| # | Что | Оценка LOC | Риск отложить |
|---|------|-----------|---------------|
| N-1 | Property-тесты на `parse_query`, `summarize_variant_rows`, `dedupe_hits`. | ~150 LOC тестов | Нулевая обзорность регрессий чистых функций. |
| N-2 | Record-and-replay (vcrpy / requests-mock) golden-тесты для 4-х основных адаптеров (1shot, rogers, eurooptic, amazon). | ~200 LOC тестов + ~500 KB фикстур | Поломка магазинов ловится только на проде. |
| N-3 | Bring `sitka_canon` PATTERNS/SIZES к единому источнику истины с avito_parser (F-CANON-1). | ~50 LOC + миграция | Низкий — бренд-таксономия меняется редко. |
| N-4 | Структурированные метрики через `set_fetch_observer` (success/blocked/failed counters per store) → Prometheus или хотя бы JSON-лог. | ~50 LOC | Долгосрочный fleet health. |

---

## 7. Рекомендация по работе дальше

**Fork'нуть и владеть.**

Обоснование:

1. **Объём правок уже не «vendor-точно из upstream»**. Запрос пользователя — починить двусловные запросы (F-PARSE-1), повысить timeout (F-PERF-1), включить retry (F-PERF-2), починить eurooptic (F-EURO-1), добавить логирование (F-OBS-1). Все эти правки делать в vendor'е через манкипатчинг неудобно; делать в форке — естественно.

2. **Upstream-связь уже слабая**. UPSTREAM.md фиксирует `commit a7dc558`, дата 2026-04-27 — то есть за 24 дня до сегодня (2026-05-21) не было ни одного re-vendor'а. При этом упомянут «следующий vendor-апдейт» в задаче — значит, upstream продолжает развиваться, но мы не подхватываем. Это уже частичный форк де-факто.

3. **30K LOC dead-кода — индикатор**. При vendor-модели приходится тянуть всё, потому что эксклюды требуют ручного rsync. При форке мы вырезаем `snapshot/`, `catalog_sync/`, legacy `inventory/*.py`, `module_service.py`, `basspro.py` — остаётся ~9.4K LOC, которое реально работает в наш продакшене. Кодовая база становится trackable одним человеком.

4. **Тесты надо писать в любом случае** (N-1, N-2 backlog). Vendor'а тестов нет, и не предвидится. Когда мы пишем тесты на форкнутый код — это естественная часть собственности. На vendor'ный — это «странная аномалия» (тестируем чужое).

5. **Riska для re-vendor от upstream'а ~ноль** при форке: мы целево забираем bugfix'ы и новые адаптеры из upstream через cherry-pick, а не через rsync. Это даже **снижает** риск (исключает ситуацию «upstream рефакторнул snapshot/, runtime/service.py не импортируется»).

Альтернативы (отвергнутые):

- **Оставить как vendored**: каждая наша правка превращается в «нельзя» или «manual patch который сотрётся при re-vendor». Уже сейчас P0-1 и P0-2 невозможно сделать чисто.
- **Переписать частично**: дороже чем форк (мы потеряем 22 рабочих адаптера ради переписывания 3-4 core-модулей). Adapters работают, основа парсера здравая.
- **Ничего не трогать пока работает**: F-PARSE-1 уже регистрировалась 2026-05-13 и продолжает воспроизводиться. F-PERF-1 ломает Amazon. «Работает» в текущем смысле слова — натяжка.

Что конкретно делать на форке:
- Перенести `sitka-services/vendor/inventory_parser/inventory/v2/` в `sitka-services/parser/` как первоклассный код.
- Эксклюды по P2-1.
- Tier-up в `.claude/risk-tiers.md` → весь `sitka-services/parser/` → Tier B по умолчанию, `parser/runtime/service.py` и `parser/adapters/base.py` → Tier A (касается всех адаптеров, влияет на оператора напрямую, бизнес-критично).
- UPSTREAM.md превращается в `UPSTREAM_HISTORY.md` («происхождение, последний sync, чем разошлись»).

Cost оценка: первичный форк + эксклюды + P0/P1 — рабочая неделя одного человека. Без этой работы каждое касание парсера — конфликт с vendor-моделью.
