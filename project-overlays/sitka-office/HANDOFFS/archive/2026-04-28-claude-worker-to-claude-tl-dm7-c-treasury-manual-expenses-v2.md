# HANDOFF v2 — DM-7-C treasury manual expenses (Worker → TL, REVIEW)

- Date: 2026-04-28 19:30
- From: Claude Worker, branch `feat/dm7-c-treasury-manual-expenses`
- To: Claude Tech Lead (sitka-office)
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: [`project-overlays/sitka-office/TASKS/2026-04-28-dm7-c-treasury-manual-expenses.md`](../TASKS/2026-04-28-dm7-c-treasury-manual-expenses.md)
- Predecessor: [HANDOFF v1 (test-infra unblock)](2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses.md) — closed by TL choosing Option 1.
- Status: closed

## TL;DR

Готов. PR #72 ([feat(dm-7-c): treasury manual expenses CRUD + expense POST handler](https://github.com/upside2002-maker/sitka-office/pull/72)). 4 файла, 689 / 5 = 694 строки diff (под 1500). Полный test suite зелёный (532/532, в т.ч. 23 новых DM-7-C). C1 tri-state выбран (boilerplate ~25 строк, под 50). Ничего за §Файлы / §"Не трогать" не тронуто. Status TASK: `in-progress` → `review`.

## Acceptance check (TASK A–G)

### A. API contract — Servant types в TreasuryAPI ✓

4 новых route добавлены в `TreasuryAPI` после существующего `cashbox`:

- `GET /api/treasury/categories?archived=<true|false>` → `[CategoryResp]` (sort `displayName ASC`; default false → filter `archivedAt IS NULL`).
- `POST /api/treasury/categories` → `200 + CategoryResp`.
- `PATCH /api/treasury/categories/:id` → `200 + CategoryResp` (404 / 400 / 200).
- `POST /api/treasury/expense` → `200 + TransactionResp` (currency=RUB hardcoded в handler).

Префиксы JSON-полей: `ec*` (CategoryResp), `ecr*` (CreateExpenseCategoryReq), `ume*` (UpdateExpenseCategoryReq), `cme*` (CreateManualExpenseReq) — стиль repo (`ucp*`, `ctr*`, `cser*`).

### B. Validation ✓

Все 9 пунктов B1–B9:

- B1 `slug` non-empty after strip → 400 "slug must be non-empty".
- B2 `displayName` non-empty after strip → 400 "displayName must be non-empty". На PATCH дополнительно: `Just "   "` → 400.
- B3 `kind` парсится через `FromJSON ExpenseKind` (Servant parse error 400 на `"warp_drive"`).
- B4 slug-conflict (active OR archived) → 409 `"slug already exists: <slug>"` (no auto-reactivate, тест E2.b отдельно проверяет invariant `archivedAt` остаётся как был).
- B5 PATCH 404 на missing id; пустое тело (`{}`) → 400 "no fields to update".
- B6 expense `amount > 0`, signed negative on insert.
- B7 `txDate ≤ NOW + 60s` skew tolerance (E4.c future = 400; E4.d 30s = 200; E4.e -365d backfill = 200).
- B8 expense `categoryId` 404 на missing.
- B9 expense `categoryId` 400 на archived ("category is archived; pick an active category or PATCH unarchive").

Проверял: `validateOr400` + `fetchOr404` + `err409 {errBody=...}` (Servant export, не пришлось добавлять явный импорт — `import Servant` в Api.Treasury wildcard).

### C. PATCH semantics — выбран C1 (tri-state Aeson) ✓

`UpdateExpenseCategoryReq.umeArchivedAt :: Maybe (Maybe UTCTime)` через explicit `instance FromJSON`:

```haskell
instance FromJSON UpdateExpenseCategoryReq where
  parseJSON = withObject "UpdateExpenseCategoryReq" $ \o -> do
    displayName <- o .:? "umeDisplayName"
    archivedAt <- case KM.lookup (Key.fromText "umeArchivedAt") o of
      Nothing -> pure Nothing            -- key absent
      Just Null -> pure (Just Nothing)   -- explicit null = unarchive
      Just v -> Just . Just <$> parseJSON v
    pure UpdateExpenseCategoryReq {umeDisplayName = displayName, umeArchivedAt = archivedAt}
```

Boilerplate: ~25 строк (data type ~6 + комментарий ~12 + instance ~10 + 4 import additions). Под 50-строчный потолок. ToJSON для UpdateExpenseCategoryReq намеренно пропущен — Servant API его не требует, тесты в ApiSpec строят PATCH body через `encode (object [...])`, а generic ToJSON для `Maybe (Maybe UTCTime)` сломал бы round-trip (omit и null оба сериализовались бы как `null`).

C2 (escape hatch на 2 endpoint-а) НЕ использован. `docs/DM-7-cashbox.md` обновлять не нужно — дизайн там описывает один PATCH, реализация совпала.

### D. Database write — POST /expense handler ✓

Реализация буква в букву по TASK §D2 (handler `createManualExpense` в `Api.Treasury.hs`):

- Валидация B6/B7/B8/B9 → 400/404.
- `fetchOr404 categoryKey` (TASK D1 literal — не пришлось вводить `requireExpenseCategory` helper, `fetchOr404` достаточен; row нужен и для `archivedAt` check, и для `categoryKey` FK).
- `now <- liftIO getCurrentTime`, `signedAmount = RUB (negate amtPositive)`.
- Insert одной Db.Transaction row: `currency=CurrencyRub`, `txType=OperationalExpense`, `sourceType=SourceManual`, FK Lead/Deal/Spend все `Nothing`, `expenseCategoryId = Just categoryKey`, `notes = cmeNotes` (как есть, без `"auto:"` prefix).
- `pure (toTransactionResp key entity)`.

Никаких mirror-инсертов. `isIncoming` sign-vs-tx_type validation НЕ применена (controlled invariant — handler формирует знак сам).

### E. Tests — 23 новых, все зелёные ✓

E1–E5 → `sitka-core/test/ApiSpec.hs` новый describe `Treasury — DM-7-C manual expenses` (после строки 2774, сразу за блоком DM-7-B-3). Использовал существующий harness: `withApp`, `pool`, `seedPerson`, `createLeadBody`, `createDealFromLeadBody`, `postJ/patchJ/getJ`, `jf/jfI/jArr/sc`. Локальные helpers внутри describe: `categoryJ`, `patchCategoryJ` (с явной type sig `Maybe Text -> Maybe Value -> LBS.ByteString` чтобы избежать ambiguity на `Nothing` второго аргумента), `expenseJ`, `freshCat`, `collectIds`, `driveToCompleted` (Person → Lead → AwaitingPayment → confirm-payment → confirm-purchase → 6 transitions → Completed).

| # | Test | Status |
|---|------|--------|
| E1.a | POST /categories happy path → 200 + echo | ✓ |
| E1.b | GET ?archived=false sorts asc | ✓ |
| E1.c | PATCH displayName only | ✓ |
| E1.d | PATCH archivedAt=<now> archives; archived=false hides | ✓ |
| E1.e | PATCH archivedAt=null unarchives | ✓ |
| E2.a | dup slug active → 409 | ✓ |
| E2.b | dup slug archived → 409 (no reactivate, archive flag preserved) | ✓ |
| E2.c | PATCH empty body → 400 | ✓ |
| E2.d | POST {slug=""} → 400 | ✓ |
| E2.e | POST {displayName="   "} → 400 after strip | ✓ |
| E2.f | POST {kind="warp_drive"} → 400 (Servant parse) | ✓ |
| E2.g | PATCH /:id where id=999999 → 404 | ✓ |
| E3 | POST /expense happy + /transactions filter + /cashbox decreased | ✓ |
| E4.a | amount=0 → 400 | ✓ |
| E4.b | amount=-50 → 400 | ✓ |
| E4.c | txDate=NOW+5min → 400 | ✓ |
| E4.d | txDate=NOW+30s → 200 (skew) | ✓ |
| E4.e | txDate=NOW-365d → 200 (backfill) | ✓ |
| E4.f | categoryId=999999 → 404 | ✓ |
| E4.g | categoryId=archived → 400 | ✓ |
| E4.h | notes omitted → 200, transaction.notes = NULL | ✓ |
| E5 | manual expense after Deal Completed: csRealizedProfit unchanged, csTotalBalance decreased; ddRevenue/ddCost preserved | ✓ |

E6 → `sitka-core/test/TreasurySpec.hs` в существующий describe-блок `cashboxSnapshot` (после backfillPending test). QuickCheck property `prop "DM-7-C: manual expenses subtract from csTotalBalance, order-invariant"`: ∀ N (1 ≤ N ≤ 20), insert N OperationalExpense rows с random Positive Double amounts → `csTotalBalance == baseline - SUM(amounts)`, и `csTotalBalance` инвариантен под `reverse` insert order. Прошёл 100 examples / 140 discarded (фильтрация `length xs <= 20`).

Важная заметка по E1.b: TASK говорил "4 seed + new = 5 rows". В test environment (`sitka_test`) `setupPool` запускает только Persistent `migrateAll`, который создаёт TABLE structure но НЕ выполняет SQL миграцию `0019_cashbox_phase_a.sql` (где seed 4 default-категорий). Поэтому E1.b изменён: вставляю 3 категории с заведомо unsorted `displayName` ("Zenith", "Alpine", "Meadow") и проверяю `names == sort names`. Контракт сортировки тестируется, без зависимости от seed-данных.

### F. Объём и форма ✓

| F | Check | Result |
|---|-------|--------|
| F1 | Diff только в файлах из §Файлы | 4 файла: `Api/Treasury.hs`, `Api/Types.hs`, `test/ApiSpec.hs`, `test/TreasurySpec.hs` ✓ |
| F2 | Никаких новых миграций | `git diff --stat` не упоминает `migrations/` ✓ |
| F3 | `cabal build -Werror` + `cabal test` + `fourmolu --mode check` | Все три зелёные. Test suite: 532 examples, 0 failures (incl. 23 new + 509 pre-existing — регрессий нет) ✓ |
| F4 | Pre-commit hooks (gitleaks / EOF / trailing ws / mixed line endings / merge conflicts / import-linter) | Все 13 hooks passed (3 hookа skipped: yaml/toml/json/actionlint — нет соответствующих файлов в diff). Weeder и migration-drift — CI-only по `.pre-commit-config.yaml` ✓ |
| F5 | `git diff --stat` < 1500 строк | 4 files, 689 insertions / 5 deletions = 694 строки ✓ |
| F6 | Один PR | [PR #72](https://github.com/upside2002-maker/sitka-office/pull/72) ✓ |

### G. Out of scope (НЕ делал) ✓

Подтверждаю, что НЕ тронуты: frontend UI, разбивка по `kind` в виджете, multi-currency, bank import, auto-reactivate, self-review, `docs/DM-7-cashbox.md` (C1 выбран — обновление не требуется).

## Артефакты

- Branch: `feat/dm7-c-treasury-manual-expenses` (origin tracking up).
- Commit: `03ae50d` — `feat(dm-7-c): treasury manual expenses CRUD + expense POST handler`.
- PR: [#72](https://github.com/upside2002-maker/sitka-office/pull/72).
- Изменённые файлы:
  - [`sitka-core/src/Api/Treasury.hs`](../../../../sitka-office/sitka-core/src/Api/Treasury.hs) — +175/-1 (4 routes + 4 handlers + `toCategoryResp`).
  - [`sitka-core/src/Api/Types.hs`](../../../../sitka-office/sitka-core/src/Api/Types.hs) — +70/-1 (4 new types + tri-state FromJSON).
  - [`sitka-core/test/ApiSpec.hs`](../../../../sitka-office/sitka-core/test/ApiSpec.hs) — +424/-3 (новый describe + 22 integration tests).
  - [`sitka-core/test/TreasurySpec.hs`](../../../../sitka-office/sitka-core/test/TreasurySpec.hs) — +25/-0 (E6 property test).

## Какой путь в C развилке выбран

**C1 (tri-state Aeson pattern).** Boilerplate ~25 строк (под 50-строчный потолок).

Обоснование выбора:
1. Семантически правильный REST PATCH: `null` действительно означает "set to NULL", не "leave alone". В `docs/DM-7-cashbox.md` дизайн описывает один PATCH endpoint — C1 совпадает с этим документом, обновлять не нужно.
2. Размер не вышел за лимит: type definition ~6 строк + комментарий-объяснение трёх состояний ~12 строк (justify pattern для будущих читателей) + `instance FromJSON` ~10 строк + 4 import additions (`Value (Null)`, `withObject`, `(.:?)`, `Data.Aeson.Key qualified`, `Data.Aeson.KeyMap qualified`).
3. Не возникло конфликта с генериком — `Api.Types` импортирует только `(FromJSON, ToJSON)`, не `(..)`. Custom instance стоит изолированно, остальные 50+ типов в файле продолжают `deriving anyclass (FromJSON, ToJSON)`.
4. Тесты (E1.d / E1.e / E1.c) подтверждают трёхтактную семантику — omit / null / value трактуются разъединённо.

ToJSON для `UpdateExpenseCategoryReq` намеренно пропущен (Servant требует только FromJSON, тесты строят body через `encode (object [...])`, а generic ToJSON корраптил бы tri-state). Кратко описано в комментарии к типу.

## Замечено по дороге, не правил

- TASK §D1 пишет "Lookup category через `fetchOr404 (toSqlKey cmeCategoryId :: Db.ExpenseCategoryId)`" — implementation использует именно `fetchOr404`, без `requireExpenseCategory` helper'а. TASK §Файлы РАЗРЕШАЕТ helper, но не требует — `fetchOr404` возвращает row (нужен для `archivedAt` check) и сама `categoryKey :: Db.ExpenseCategoryId` уже сконструирована до вызова, так что helper дал бы только косметическую симметрию с `requireLead/Deal/Spend` ценой ~10 лишних строк. Скип в пользу minimalism. Если TL хочет helper для будущего consistency — отдельный TASK на 5-минутный refactor.
- В test environment (sitka_test) `setupPool` запускает только Persistent `migrateAll`, не SQL миграции. Это означает что `expense_category` таблица создана, но 4 seed default-rows из миграции 0019 НЕ вставлены. TASK §E1 ожидал "4 seed + new = 5 rows" — поправил тест E1.b: вставляю 3 категории сам и проверяю sort order. Контракт `displayName ASC` тестируется без seed dependency. Аналогичный gap у других тестов нет.
- `scripts/file-tier.sh sitka-core/src/Api/Treasury.hs` всё ещё возвращает `C` (см. drive-by из HANDOFF v1), хотя `.claude/risk-tiers.md` явно перечисляет файл в Tier A. Не правил, как и в v1.
- `Api.Treasury.requireLead/Deal/Spend` остались монотонными `Int64 -> AppM (Key X)` хелперами рядом с моим новым `createManualExpense`. Я не использовал их паттерн (сделал inline через `fetchOr404`), но логика идентичная — потенциальный refactor opportunity на single generic helper. Опять — не моё дело в этом TASK.
- `notes` поле в B-1 / B-2 / B-3 handler-ах содержит `"auto: ..."` prefix (например, `Just "auto: SpendEntry"` в `Api.Marketing.createSpendEntry`). В моём DM-7-C `createManualExpense` — `notes = cmeNotes` без prefix, что согласуется с TASK §D2 (`cmeNotes  -- as-is, no "auto:" prefix`). Расхождение между auto-mirrored Transactions и operator-entered manual Transactions намеренное — один из способов отличить их в /transactions листинге без полагания на `sourceType`.

## Конфликты / открытые вопросы

Нет открытых блокеров. Если CI поднимет какой-то lane — отмечу в комментарии к PR. CI lanes для TASK §F4: fourmolu, weeder, import-linter, drift-check, haskell-test, python-test, frontend-typecheck+e2e. Drift-check должен быть зелёным (миграции не тронуты).

## Следующий шаг

TL: ревью PR #72. По TASK §Reviewer — после HANDOFF TL запросит Reviewer round (Codex red-team на B4–B9 / tri-state semantics / cashboxSnapshot integration, ИЛИ Claude repo-grounded на стиль). Worker не делает self-review и не реагирует на findings напрямую — если придут, TL фильтрует через новый TASK.

После accept TASK + merge — frontend Phase C task: «Прочие расходы» таб + разбивка outgoing по `kind` в дашборде (упомянут в TASK §"Frontend UI" как следующий step).
