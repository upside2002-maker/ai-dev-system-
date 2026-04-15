# Sitka Office — Known Issues

Дата: 2026-04-14

Найденные при аудите проблемы, которые нужно решить.
Упорядочены по критичности для type safety и code quality.

## BLOCKING: Type Safety Gaps

### Issue #1: Raw Double в DB Schema

**Файл**: `sitka-core/src/Db/Schema.hs`

DB хранит денежные поля как `Double`, хотя domain model использует `USD`/`RUB` newtypes:
```
Deal
  maxPriceRub Double        -- должно быть RUB
  plannedCost Double        -- должно быть USD
  quotedPrice Double        -- должно быть USD
  actualCost Double         -- должно быть USD
  actualRevenue Double      -- должно быть RUB
  plannedMargin Double      -- должно быть USD
  actualMargin Double       -- должно быть USD
```

**Решение**: PersistField instances для USD и RUB. См. `.claude/corrections.md` Correction #1.

### Issue #2: ADT как Text в DB

**Файл**: `sitka-core/src/Db/Schema.hs`

```
Deal
  status Text               -- должно быть DealStatus
  riskFlags Text            -- должно быть [RiskFlag]

DealEvent
  eventType Text            -- должно быть EventType
```

**Решение**: PersistField instances с exhaustive pattern matching. См. `.claude/corrections.md` Correction #2.

### Issue #3: Raw Double в API Types

**Файл**: `sitka-core/src/Api/Types.hs`

Transport types используют `Double` вместо `USD`/`RUB`:
```haskell
data CreateDealReq = CreateDealReq
  { cdrMaxPriceRub :: Maybe Double  -- должно быть Maybe RUB
  , ...
  }
```

**Решение**: Использовать domain newtypes + JSON instances.

## WARNING: Code Quality

### Issue #4: Дублированный fetch-or-404

**Файлы**: `Api/Clients.hs`, `Api/Deals.hs` (минимум 2 места)

Паттерн `get key >>= maybe (throwError err404) pure` повторяется.

**Решение**: Выделить `fetchOr404` в `Api/Helpers.hs`. См. `.claude/corrections.md` Correction #3.

### Issue #5: Минимальные тесты

**Файл**: `sitka-core/test/Spec.hs`

Тесты существуют, но покрытие минимальное. Pricing engine и state machine — чистые функции, тестировать тривиально.

### Issue #6: Event sourcing не подключён

Таблица `DealEvent` есть в schema, но handlers не пишут events. Инфраструктура готова, wiring отсутствует.

## NOT AN ISSUE (уже хорошо)

- State machine полностью pure ✓
- Pricing engine полностью pure ✓
- Servant API composition на уровне типов ✓
- Transport types отделены от domain types ✓
- Services не принимают бизнес-решений ✓
- Health endpoint проверяет зависимости ✓
- Mock отделён от реального парсера ✓
