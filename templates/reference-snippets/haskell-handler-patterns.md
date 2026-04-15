# Haskell Handler Patterns

## Fetch Or 404

```haskell
fetchOr404 :: (PersistEntity record, PersistEntityBackend record ~ SqlBackend, Show (Key record))
           => Key record
           -> ConnectionPool
           -> Handler record
fetchOr404 key pool = do
  mValue <- liftIO $ runSqlPool (get key) pool
  case mValue of
    Nothing -> throwError err404
    Just value -> pure value
```

## Transition Handler Shape

```haskell
transitionDealHandler :: ConnectionPool -> DealId -> TransitionRequest -> Handler DealResponse
transitionDealHandler pool dealId request = do
  deal <- fetchOr404 dealId pool
  let next = applyTransition request deal
  liftIO $ runSqlPool (save next) pool
  pure (toDealResponse next)
```

## Why this matters

Сниппеты нужны не для copy-paste ради copy-paste, а чтобы агент видел идиоматичную форму решения внутри typed core.
