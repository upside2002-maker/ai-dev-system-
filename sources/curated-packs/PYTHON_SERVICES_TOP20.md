# Python Services Top 20

Этот файл описывает 20 паттернов для integration/service слоя.

Базовые источники для отбора:

- `fastapi/fastapi`
- `fastapi/full-stack-fastapi-template`
- `pydantic/pydantic`
- `pydantic/pydantic-ai`

## 1. Services как boundary layer

Когда использовать:

- всегда в integration-сервисах.

Хорошая форма:

- слой собирает, нормализует, оркестрирует и вызывает core.

Избегать:

- дублировать бизнес-решения core.

## 2. Pydantic на входе и выходе

Когда использовать:

- request/response models;
- parser payload normalization.

Хорошая форма:

- `BaseModel` на transport schemas;
- aliasing, validation, defaults.

Избегать:

- голых `dict[str, Any]` везде.

## 3. Явная нормализация строк и URL

Когда использовать:

- parsing;
- store names;
- dedupe keys.

Хорошая форма:

- отдельные helper functions;
- одинаковые normalization rules.

Избегать:

- нормализовать каждый раз по-разному в цикле.

## 4. Dedupe как first-class concern

Когда использовать:

- магазины;
- офферы;
- ссылки Avito;
- URL-кандидаты.

Хорошая форма:

- отдельный dedupe key;
- set-based dedupe.

Избегать:

- импортировать одно и то же в core несколько раз.

## 5. Core client как отдельный модуль

Когда использовать:

- любой HTTP вызов в core.

Хорошая форма:

- `core_client.py` или package;
- единый error type;
- единые timeout/retry conventions.

Избегать:

- разбросанных `httpx` вызовов по всем роутам.

## 6. Graceful degradation

Когда использовать:

- внешние парсеры;
- сайты магазинов;
- Avito;
- Playwright-dependent paths.

Хорошая форма:

- parser failure не валит весь сервис;
- частичная деградация явно видна.

Избегать:

- 500 на весь endpoint из-за одного магазина.

## 7. Mark mock as mock

Когда использовать:

- fallback на заглушки;
- mock Avito.

Хорошая форма:

- source/status/reason показывают, что данные не реальные.

Избегать:

- смешивать mock с real без маркировки.

## 8. Health endpoint с зависимостями

Когда использовать:

- всегда.

Хорошая форма:

- `status`;
- `service`;
- `version`;
- `dependencies`.

Избегать:

- health, который ничего реально не проверяет.

## 9. Перевод внешних ошибок в понятные HTTP-ошибки

Когда использовать:

- parser errors;
- core errors;
- unavailable services.

Хорошая форма:

- `HTTPException` с понятным detail;
- 502, если упал downstream.

Избегать:

- traceback наружу;
- generic `"error"`.

## 10. Тонкие роуты, жирные helpers

Когда использовать:

- во всех FastAPI routes.

Хорошая форма:

- route only coordinates request -> service -> response.

Избегать:

- 200 строк в одном route-функции.

## 11. Async там, где реально IO

Когда использовать:

- HTTP;
- browser automation;
- network parsing.

Хорошая форма:

- `async def` вокруг IO-bound flows.

Избегать:

- лишней асинхронности ради моды;
- смешанного хаоса sync/async без причины.

## 12. Parser result как отдельный transport object

Когда использовать:

- multi-store sourcing.

Хорошая форма:

- store summary;
- list of candidates;
- elapsed time;
- reason/status.

Избегать:

- неструктурированных списков и строк.

## 13. Create-deal только после pre-deal selection

Когда использовать:

- sourcing workflow.

Хорошая форма:

- сначала агрегированный result;
- потом импорт выбранного в core.

Избегать:

- создавать сделку слишком рано.

## 14. Вынесенные canonicalization helpers

Когда использовать:

- URL normalization;
- title cleanup;
- scalar cleanup.

Хорошая форма:

- `canonical_url`;
- `_normalize_scalar`;
- `_normalize_stores`.

Избегать:

- ad-hoc string cleanup everywhere.

## 15. Ограничение импортируемого объема

Когда использовать:

- при создании сделки из sourcing result.

Хорошая форма:

- `max_offers_to_import`;
- top-N discipline.

Избегать:

- безлимитный импорт всего найденного шума.

## 16. Четкая маркировка статуса кандидата

Когда использовать:

- offer candidate;
- store result;
- avito candidate.

Хорошая форма:

- `status`, `in_stock`, `skip_reason`, `availability`.

Избегать:

- неявных условий, которые понимает только код.

## 17. Слой services не знает final workflow meaning

Когда использовать:

- transitions, quotes, approval logic.

Хорошая форма:

- services сообщает факты;
- core определяет meaning.

Избегать:

- "если найдено 3 оффера, статус теперь sourcing_complete".

## 18. Подготовка к внешним API как отдельная зона

Когда использовать:

- Avito messaging;
- Telegram;
- любые outbound integrations.

Хорошая форма:

- отдельный модуль клиента;
- понятный transport contract;
- retries/timeouts.

Избегать:

- засовывать мессенджерную логику в parsing route.

## 19. Комментарии только там, где скрытая operational logic

Когда использовать:

- fallback;
- parser quirk;
- third-party oddity.

Хорошая форма:

- короткое пояснение "почему", а не "что делает строка".

Избегать:

- очевидных комментариев;
- отсутствия комментариев там, где workaround критичен.

## 20. Services должны быть удобны для локальной проверки

Когда использовать:

- всегда.

Хорошая форма:

- простой запуск;
- predictable ports;
- import smoke-test;
- health and one real endpoint for manual probing.

Избегать:

- магии, которую нельзя быстро проверить локально.

## Как использовать этот top-20

Перед задачей на services агенту давай:

1. project overlay
2. `SERVICE_INTEGRATION.md`
3. этот `Top 20`
4. один локальный endpoint-пример

Так агенту проще сохранить границу между orchestration и business logic.
