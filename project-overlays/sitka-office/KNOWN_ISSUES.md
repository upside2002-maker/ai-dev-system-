# Sitka Office — Known Issues

Дата: 2026-04-15

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

### Issue #5: Минимальные тесты

12 тестов для core (SM + pricing). Нет тестов для:
- Risk engine
- API endpoints (integration)
- Edge cases pricing (нулевая цена, максимальный buffer)
- Telegram bot
- Notification system

### Issue #6: Redis не используется

Сконфигурирован в docker-compose и config.py, но не подключён. Будет нужен для очередей/кеша.

### Issue #7: ApiSpec test harness использует runMigration напрямую

`sitka-core/test/ApiSpec.hs` в `setupPool` вызывает `runSqlPool (runMigration migrateAll) pool` для поднятия in-memory `sitka_test` БД. Production path теперь идёт через dbmate (Task 0.1), но тестовый harness обходит его. Это приемлемо пока — тесты не затрагивают production migration flow, — но test harness не валидирует сами миграции: если миграция вручную расходится с Schema.hs, тесты это не обнаружат.

**Файл:** `sitka-core/test/ApiSpec.hs`
**Решение:** Заменить `runMigration` на прогон dbmate против `sitka_test` БД в test fixture. Будет требовать dbmate в PATH на CI. Делать когда будет время рефакторить тестовую инфраструктуру.

## Закрытые (решено)

- ~~PersistField instances для USD/RUB~~ → реализованы в Domain/Types.hs
- ~~fetchOr404 дублируется~~ → выделен в Api/AppM.hs
- ~~API Types используют raw Double~~ → используют newtypes
- ~~DB Schema хранит raw Double для денег~~ → хранит newtypes
- ~~Нет CI~~ → GitHub Actions
- ~~Нет auth~~ → bearer token
- ~~CLAUDE.md устарел~~ → обновлён 2026-04-15
