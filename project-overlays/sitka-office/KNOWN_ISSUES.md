# Sitka Office — Known Issues

Дата: 2026-04-16 (после Phase 0)

## Открытые

### Issue #1: Smart constructors не реализованы

Конструкторы USD, RUB, Percent, ExchangeRate экспортируются открыто.
Percent может быть 999. USD может быть отрицательным.

**Файлы:** `src/Domain/Types.hs`
**Решение:** Не экспортировать конструкторы, добавить mkPercent, mkUSD, mkRUB, mkExchangeRate с валидацией.

### Issue #2: riskFlags хранится как Text

Сериализованный список в текстовом поле. Нет нормализации, нет queryability.

**Файл:** `src/Db/Schema.hs`
**Решение:** JSONB или junction table.

### Issue #3: eventType и actor в DealEvent — plain Text

Не ADT, нет compile-time проверки. Новый тип события добавляется без ошибки компиляции.

**Файл:** `src/Db/Schema.hs`, `src/Domain/Event.hs`
**Решение:** ADT EventType, ADT Actor, PersistField instances.

### Issue #4: Setting.valueNum — raw Double

Единственное место с raw Double. Конвертируется при загрузке в PricingParams, но в DB без типизации.

**Файл:** `src/Db/Schema.hs`

### Issue #5: Тесты для services не покрыты

Phase 0 поднял core до 202 тестов (domain + state machine + pricing + API + reasons + marketing + conversations + attribution).

Не покрыто:
- Telegram bot (Python)
- Notification system (Python)
- Service-side ConversationProvider (когда появится в Phase 2)

Frontend: 128 unit + 67 E2E (Playwright).

### Issue #6: Redis не используется

Сконфигурирован в docker-compose и config.py, но не подключён. Будет нужен для очередей/кеша.

### Issue #7: ApiSpec test harness использует runMigration напрямую

`sitka-core/test/ApiSpec.hs` в `setupPool` вызывает `runSqlPool (runMigration migrateAll) pool` для поднятия in-memory `sitka_test` БД. Production path теперь идёт через dbmate (Task 0.1), но тестовый harness обходит его. Это приемлемо пока — тесты не затрагивают production migration flow, — но test harness не валидирует сами миграции: если миграция вручную расходится с Schema.hs, тесты это не обнаружат.

**Файл:** `sitka-core/test/ApiSpec.hs`
**Решение:** Заменить `runMigration` на прогон dbmate против `sitka_test` БД в test fixture. Будет требовать dbmate в PATH на CI. Делать когда будет время рефакторить тестовую инфраструктуру.

### Issue #8: Conversations list без pagination (limit 200)

`GET /api/conversations` в Api/Conversations.hs возвращает до 200 тредов в одном ответе (фиксированный `LimitTo 200`). Для Phase 0 это приемлемо (треды только создаются по мере настройки). Для Phase 2 inbox, когда пойдёт реальный поток из Avito/TG/WA, 200 закончится быстро — потребуется cursor pagination.

**Файл:** `sitka-core/src/Api/Conversations.hs` (handler `listConversations`)
**Решение:** Добавить `?cursor=<timestamp>&limit=<N>` параметры, сортировка по `lastMessageAt DESC`, клиент продолжает подгружать от последнего timestamp. Также нужна pagination shape в API (next_cursor в ответе). Делать в рамках Phase 2 Inbox.

### Issue #9: Breaking — reason wire format в Task 0.3

Task 0.3 сменил JSON-формат `DisqualifyReason`, `RejectReason`, `CancelReason` с плоской строки (`"out_of_stock"`) на tagged union (`{"type": "out_of_stock"}` / `{"type": "other", "text": "..."}`). Legacy flat-string JSON теперь отвергается `FromJSON`. PersistField и HttpApiData (query params) остались flat — DB и query string неизменны.

**Влияние:** никакого на текущей стадии (нет production клиентов API). Frontend в Task 0.4/0.5 должен использовать новый формат.
**Запись-маркер** для истории — если в будущем придётся восстанавливать совместимость со старыми хранилищами.

### Issue #11: Domain records — dead code вне Engine.Marketing

`Domain.Marketing.{ChannelAccount, Campaign, Listing}`, `Domain.Marketing.Spend.SpendEntry`, `Domain.Marketing.Attribution.SourceTouch`, `Domain.Conversation.ConversationThread`, `Domain.Deal.Deal` — **запись-типы** нигде не конструируются кроме `Engine.Marketing` и его тестов. Все API-хендлеры работают напрямую с `Db.*` Persistent-записями.

Это создаёт "mapper gap": Task 1.2 должен будет написать конвертеры `Db.X → Domain.X` (~100 строк plumbing) чтобы скормить Engine реальные данные. Engine был спроектирован агентом-аналитиком вокруг Domain-типов ради "чистоты слоёв"; pragmatic-ценность этой чистоты низка на текущем масштабе.

**Файлы:** `src/Domain/Marketing.hs`, `src/Domain/Marketing/*.hs`, `src/Domain/Conversation.hs`, `src/Domain/Deal.hs` (Deal record), `src/Engine/Marketing.hs`

**Опции:**
1. **Принять и написать мапперы в Task 1.2** (рекомендую — следует спецификации, чистая layering, ~60 строк)
2. Переписать Engine вокруг `Db.*` типов — проще, но Engine импортирует Persistent
3. Удалить Domain record-ы, в Engine определить свои "query shape" типы с нужным подмножеством полей

**Когда решать:** в начале Task 1.2. Рекомендация — Option 1.

### Issue #12: Conversations API — без consumer-а

5 endpoints (`POST/GET /api/conversations`, `link-deal`, `link-client`) добавлены в Task 0.3 как foundation для Phase 2 Inbox. Сейчас **никто** их не вызывает — ни фронт (нет Inbox UI), ни services (нет sync-job). Surface живёт только для интеграционных тестов.

**Риск:** shape DTO может разойтись с реальными требованиями Phase 2 Avito-sync. Но на сегодня compile-testable foundation лучше чем пустое место.

**Файлы:** `src/Api/Conversations.hs`, тесты в `ApiSpec.hs`

**Когда ревизить:** в начале Phase 2, после выбора Avito-провайдера (API / scraper / hybrid) — возможно нужно добавить поля для webhook signatures, message_id, pagination cursor.

### Issue #13: Funnel-аналитика не учитывает историю переходов

`Engine.Marketing.aggregateFunnel` смотрит только на `dealStatus` (текущий). Сделка прошедшая через `Approved` и отменённая в `Cancelled` не попадёт в `fbdApproved`, только в `fbdCancelled`. Это может недооценивать воронку при анализе "сколько доходило до одобрения".

Для правильной аналитики нужно join с `deal_event` table (события `status_changed:*`) и взять max(stage_index). Это требует передачи `[DealEvent]` в Engine или отдельного helper.

**Когда чинить:** когда первый пользователь аналитики спросит "почему в отчёте Q2 меньше approved-сделок чем я помню". Ориентировочно Phase 1.5 / Phase 2.

### Issue #10: Нет отдельного marketing-event stream

`spend_recorded`, `listing_created`, `campaign_created` сейчас **не** записываются в `deal_event` — они не привязаны к Deal. На Phase 0 это было осознанным решением (commit `5100d69`), чтобы не засорять `DealEvent` несвязанными событиями. В результате audit-trail для маркетинговых мутаций отсутствует.

**Когда чинить:** Phase 1 или Phase 2, если появится потребность в audit-аналитике "что и когда добавили в марк-иерархию" (например, для reconciliation с Avito API или для timeline изменений бюджета).
**Решение:** отдельная таблица `marketing_event` со своим event-type ADT (`SpendRecorded | ListingCreated | ListingArchived | CampaignCreated | BudgetChanged | ...`) + handler-инъекция в `Api/Marketing.hs`.

## Закрытые (решено)

- ~~PersistField instances для USD/RUB~~ → реализованы в Domain/Types.hs
- ~~fetchOr404 дублируется~~ → выделен в Api/AppM.hs
- ~~API Types используют raw Double~~ → используют newtypes
- ~~DB Schema хранит raw Double для денег~~ → хранит newtypes
- ~~Нет CI~~ → GitHub Actions
- ~~Нет auth~~ → bearer token
- ~~CLAUDE.md устарел~~ → обновлён 2026-04-15
