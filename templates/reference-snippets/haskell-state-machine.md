# Haskell State Machine — Reference

Эталонный пример чистого state machine из sitka-core.

## Почему это хороший пример

1. **Полностью pure** — нет IO, переходы определяются чистыми функциями.
2. **Exhaustive pattern matching** — нет wildcards на DealStatus или Transition.
3. **Отдельный модуль** — state machine не размазан по handlers.
4. **Три уровня API**: `canTransition` (проверка), `transition` (применение), `allowedTransitions` (что доступно).

## Ключевые паттерны

### ADT для статусов и переходов

```haskell
data DealStatus = New | Sourcing | Quoted | Approved | Purchased
                | InTransit | Delivered | Completed | Rejected | Cancelled
  deriving stock (Show, Read, Eq, Ord, Enum, Bounded)

data Transition = StartSourcing | SendQuote | ApproveQuote | RejectQuote
                | MakePurchase | ShipDeal | DeliverDeal | CompleteDeal
                | CancelDeal
  deriving stock (Show, Read, Eq, Ord, Enum, Bounded)
```

Добавление нового статуса ломает компиляцию везде где `DealStatus` используется в pattern match.

### Чистая проверка перехода

```haskell
canTransition :: DealStatus -> Transition -> Bool
canTransition New StartSourcing = True
canTransition Sourcing SendQuote = True
canTransition Quoted ApproveQuote = True
canTransition Quoted RejectQuote = True
-- exhaustive: все остальные комбинации → False
canTransition _ _ = False  -- ← единственное место где wildcard допустим
```

### Список доступных переходов

```haskell
allowedTransitions :: DealStatus -> [Transition]
allowedTransitions status =
  filter (canTransition status) [minBound .. maxBound]
```

Использует `Bounded` + `Enum` для перебора всех значений.

### Terminal states

```haskell
isTerminal :: DealStatus -> Bool
isTerminal Completed = True
isTerminal Rejected  = True
isTerminal Cancelled = True
isTerminal _         = False
```

## Когда использовать как образец

- При добавлении новых workflow (ShipmentStatus, PaymentStatus).
- При ревью: state machine должен жить в отдельном pure модуле.
- Handlers только вызывают `transition` и сохраняют результат.
