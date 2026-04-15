# Haskell Pricing Engine — Reference

Эталонный пример чистого domain engine из sitka-core.
Показывает правильное использование typed newtypes для денег.

## Почему это хороший пример

1. **Все функции pure** — нет IO, нет DB, нет side effects.
2. **Newtypes используются end-to-end** — USD, RUB, Percent, ExchangeRate не разворачиваются в Double.
3. **RecordWildCards** для читабельности params.
4. **Разворачивание только для арифметики** — `unRUB` используется только внутри вычислений, результат сразу заворачивается обратно в `RUB`.
5. **Type signatures на всех функциях** включая внутреннюю `usdToRub`.
6. **Нет partial functions** — нет head, fromJust, или wildcard matches.

## Ключевые паттерны

### Конвертация валют через typed helper

```haskell
usdToRub :: ExchangeRate -> Percent -> USD -> RUB
usdToRub (ExchangeRate rate) (Percent buffer) (USD amount) =
  RUB $ amount * rate * (1 + buffer / 100)
```

Невозможно перепутать USD и RUB — типы не дадут.

### Параметры как record с typed полями

```haskell
data PricingParams = PricingParams
  { ppExchangeRate     :: ExchangeRate
  , ppExchangeBuffer   :: Percent
  , ppShippingUSUsd    :: USD
  , ppShippingIntlUsd  :: USD
  , ppCustomsRub       :: RUB
  , ppShippingRURub    :: RUB
  }
  deriving stock (Show, Eq)
```

Поле `ppShippingUSUsd :: USD` не может случайно принять значение в рублях.

### Чистый расчёт с полным breakdown

```haskell
calculateCost :: PricingParams -> USD -> CostBreakdown
calculateCost PricingParams{..} itemPriceUsd =
  let ...
  in CostBreakdown { ... }
```

Результат — структурированный breakdown, не одно число. Все промежуточные значения доступны.

### Margin через типы

```haskell
calculateMargin :: RUB -> RUB -> RUB
calculateMargin (RUB revenue) (RUB cost) = RUB (revenue - cost)
```

Нельзя вычесть USD из RUB — не скомпилируется.

## Когда использовать как образец

- При создании новых engine модулей (risk calculation, delivery estimation, tax calculation).
- При ревью: "этот модуль такой же чистый как Pricing.hs?"
- При обучении агента: "вот так выглядит правильный typed core module."
