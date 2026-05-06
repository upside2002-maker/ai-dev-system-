# 2026-04-28-dm7-c-treasury-manual-expenses

- ID: `2026-04-28-dm7-c-treasury-manual-expenses`
- Created by: Claude Tech Lead session, 2026-04-28
- Worker model: Claude Code
- Worker branch: `feat/dm7-c-treasury-manual-expenses` (или близкий вариант)
- Layer: core
- Risk tier: A (Api.Treasury, money-flow handlers, OperationalExpense write path)
- Status: done

## Задача

Реализовать backend Phase C цикла DM-7 Cashbox: 4 новых endpoint-а в `Api.Treasury` для CRUD категорий ручных расходов (`expense_category`) и записи manual expense (Transaction `OperationalExpense` + `SourceManual` + `expense_category_id`). Migration 0019 в Phase A уже создала таблицу + seed 4 категорий; `Domain.ExpenseCategory` + поле `transaction.expense_category_id` готовы. Эта задача — handler-ы + Servant API types + tests. **БЕЗ миграций.**

Frontend UI («Прочие расходы» таб + разбивка outgoing по `kind` в дашборде) — отдельный следующий TASK после accept этого.

## Файлы

- `modify:`
  - `sitka-core/src/Api/Treasury.hs` — расширить `TreasuryAPI` type (4 новых route) + 4 handler-а в `treasuryServerT`. Разрешено добавить monomorphic helper `requireExpenseCategory :: Int64 -> AppM Db.ExpenseCategoryId` рядом с существующими `requireLead/Deal/Spend` (естественное расширение паттерна, drive-by замечание Worker'а из HANDOFF v1).
  - `sitka-core/src/Api/Types.hs` — добавить request/response types: `CategoryResp`, `CreateExpenseCategoryReq`, `UpdateExpenseCategoryReq`, `CreateManualExpenseReq`. Маппинг `Db.ExpenseCategory → CategoryResp`.
  - `sitka-core/test/ApiSpec.hs` — добавить **integration tests** (E1–E5 из секции E ниже): новый describe-блок `Treasury — DM-7-C manual expenses` около строки 2606+ после существующих DM-5/B-1/B-2/B-3 блоков. Использовать существующий harness (`setupPool`, `cleanDb`, `withApp`, `postJ/patchJ/getJ/jf/jArr/sc`). **Добавлено по запросу TL 2026-04-28 (HANDOFF v1) — выбран Option 1 из развилки Worker'а (минимальное расширение, продолжение паттерна DM-5/B-1/B-2/B-3 Treasury integration tests).**
  - `sitka-core/test/TreasurySpec.hs` — добавить **property test** (E6 из секции E ниже) в существующий describe-блок с `cashboxSnapshot` тестами Phase A. Pure unit pattern как у соседей, без HTTP/DB.
- `new:` —
- `delete:` —
- `migrations:` — НЕТ (схема готова)

## Не трогать

- `sitka-core/migrations/*` — миграции готовы (`0019_cashbox_phase_a.sql` в master). НИКАКИХ новых миграций. Если возникает потребность — безусловный возврат в TL.
- `sitka-core/src/Domain/ExpenseCategory.hs`, `sitka-core/src/Domain/Transaction.hs` — типы готовы (`ExpenseKind`, `TransactionType.OperationalExpense`, `TransactionSourceType.SourceManual`, `Domain.Transaction.transactionExpenseCategoryId :: Maybe Int64`). Если ОБНАРУЖИШЬ что чего-то не хватает — возврат в TL, не пытаться "досделать" доменные типы.
- `sitka-core/src/Db/Schema.hs` — Persistent entity `ExpenseCategory` (строки ~437-443), `UniqueExpenseCategorySlug` constraint, `transaction.expenseCategoryId` поле (строка ~410) уже есть. Не трогать.
- `sitka-core/src/Engine/Treasury.hs` — `cashboxSnapshot` корректно агрегирует `OperationalExpense` через знак `amount` (PR #63). Не трогать.
- `sitka-core/src/Api/Server.hs` — `TreasuryAPI` уже подключён (`:<|> TreasuryAPI` на строке ~44), `treasuryServerT` уже в server. Расширения внутри `TreasuryAPI` type подхватятся автоматически. Не трогать.
- `sitka-services/`, `sitka-web/` — Phase C frontend = следующий TASK. Не трогать.
- Прочие markdown / `docs/` / `.claude/` / overlay в `ai-dev-system/` — не трогать.

Если по дороге заметишь что-то ещё, требующее правки за пределами scope — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией "Замечено по дороге, не правил".

## Критерии приёмки

Все секции (A–G) обязательны. Tier A → mandatory property tests + integration tests + human review (TL после HANDOFF, потенциально + Reviewer round, см. секцию Reviewer).

### A. API contract — Servant types в `Api.Treasury.TreasuryAPI`

Добавить 4 новых route в `TreasuryAPI` после существующих 5 (cashbox snapshot — последний на сегодня):

A1. `GET /api/treasury/categories?archived=<true|false>` (default `false`) → `[CategoryResp]`. Сортировка `displayName ASC`. `archived=false` → фильтр `archivedAt IS NULL`; `archived=true` → без фильтра (все, включая архивные). Параметра `archivedOnly=true` НЕ вводить.

A2. `POST /api/treasury/categories` body `CreateExpenseCategoryReq {ecrSlug, ecrDisplayName, ecrKind}` → 200 + `CategoryResp`. (Servant + `Post '[JSON]` возвращает 200, не 201 — следовать стилю repo, не вводить custom 201.)

A3. `PATCH /api/treasury/categories/:id` body `UpdateExpenseCategoryReq` → 200 + `CategoryResp`. Семантика fields см. секцию C.

A4. `POST /api/treasury/expense` body `CreateManualExpenseReq {cmeAmount, cmeCategoryId, cmeNotes?, cmeTxDate}` → 200 + `TransactionResp`. Создаёт ровно ОДНУ Transaction row (детали — секция D). Currency hardcoded RUB (поле в request НЕ принимать; rationale — `Api.Treasury.createTransaction` line ~124, MVP guard на non-RUB).

Префиксы JSON-полей в request types (`ecr*`, `ume*`, `cme*`) — следовать стилю существующих `CreateTransactionReq` / `UpdateCampaignReq`. JSON-имена через `aeson` GenericOptions если используется в репо, или explicit `FromJSON` instance — Worker по контексту.

### B. Validation (handler-уровень)

Все ошибки → 400 (или специфический код) с осмысленным `errBody` через `validateOr400` (или эквивалент в `Api.AppM`). Сообщения короткие, оператор-понятные.

B1. `POST /categories.slug` — non-empty после strip whitespace; иначе 400 "slug must be non-empty".
B2. `POST /categories.displayName` — non-empty после strip whitespace; иначе 400 "displayName must be non-empty".
B3. `POST /categories.kind` — парсится из JSON через существующий `FromJSON ExpenseKind` (некорректное значение → Servant parse error 400, не нужно дополнительной валидации).
B4. `POST /categories` slug-conflict (включая случай когда совпадает с **archived** row) → **409** с `errBody = "slug already exists: <slug>"`. Авто-reactivation НЕ делается (решение TL подтверждено пользователем 2026-04-28); оператор должен явно `PATCH archivedAt=null` на найденной archived строке.
B5. `PATCH /categories/:id` — 404 если id не существует. Если оба поля омитнуты (`displayName=Nothing AND archivedAt не передано`) → 400 "no fields to update".
B6. `POST /expense.amount` (RUB на входе как positive) — `> 0`; иначе 400 "amount must be > 0". Insert амount в БД — negative (signed expense, см. D2).
B7. `POST /expense.txDate` — `txDate <= NOW + 60s` (skew tolerance 60 секунд для clock drift); иначе 400 "txDate must not be in the future". Прошлые даты разрешены безоговорочно (use-case "забыли записать аренду 1 марта" — решение TL подтверждено пользователем 2026-04-28).
B8. `POST /expense.categoryId` — 404 если id не существует.
B9. `POST /expense.categoryId` — если `archivedAt IS NOT NULL` → 400 "category is archived; pick an active category or PATCH unarchive". Защита от случайной записи на removed категорию.

### C. PATCH semantics (`UpdateExpenseCategoryReq` — развилка)

`displayName` — обычный `Maybe Text` (omitted = keep existing; `null` или пустая строка → 400 B2). Используй паттерн `<|>` как в `Api.Marketing.updateCampaign` line ~219-231.

`archivedAt` — нужен **tri-state** (omit / null / value), потому что unarchive (`archivedAt = null`) — реальный admin use-case. Существующий `<|>` паттерн в репо это НЕ покрывает (omit и null трактуются одинаково).

**Развилка для Worker'а — выбери ОДИН из двух подходов:**

C1. **Tri-state Aeson pattern** (новый в репе). `umeArchivedAt :: Maybe (Maybe UTCTime)` через explicit `FromJSON` instance, который различает три состояния:
- ключ отсутствует в JSON → `Nothing` (не обновлять)
- ключ = `null` → `Just Nothing` (set NULL = unarchive)
- ключ = `<UTCTime>` → `Just (Just t)` (set timestamp = archive)

Если этот путь даёт **≤50 строк boilerplate** (один `instance FromJSON UpdateExpenseCategoryReq` где-то ~20 строк + использование в handler) — **используй его**. Это правильный REST PATCH способ.

C2. **Fallback на два endpoint-а** (если tri-state выходит >50 строк или конфликтует с генериком в репо).

В этом случае:
- `PATCH /api/treasury/categories/:id` принимает только `displayName?` (через `<|>`)
- Дополнительно: `POST /api/treasury/categories/:id/archive` (set `archivedAt = NOW`) и `POST /api/treasury/categories/:id/unarchive` (set `archivedAt = NULL`)

ВАЖНО: если выбираешь C2 — это отступление от дизайна в `docs/DM-7-cashbox.md` (там написан один PATCH). Зафиксировать в HANDOFF секцией "Возврат в TL для синхронизации DM-7-cashbox.md", чтобы TL обновил документ. Frontend TASK тогда учтёт два endpoint-а вместо одного.

C1 предпочтительнее. C2 — escape hatch если C1 не выходит чисто.

### D. Database write — `POST /expense` handler

D1. Validate (B6, B7, B8, B9). Lookup category через `fetchOr404 (toSqlKey cmeCategoryId :: Db.ExpenseCategoryId)`, проверить `expenseCategoryArchivedAt == Nothing`.

D2. Insert Transaction:

```haskell
now <- liftIO getCurrentTime
let RUB amtPositive = cmeAmount
    signedAmount = RUB (negate amtPositive)
    entity =
      Db.Transaction
        { Db.transactionAmount = signedAmount
        , Db.transactionCurrency = CurrencyRub
        , Db.transactionTxType = OperationalExpense
        , Db.transactionTxDate = cmeTxDate
        , Db.transactionSourceType = SourceManual
        , Db.transactionLeadId = Nothing
        , Db.transactionDealId = Nothing
        , Db.transactionSpendEntryId = Nothing
        , Db.transactionBankRef = Nothing
        , Db.transactionExternalRef = Nothing
        , Db.transactionNotes = cmeNotes  -- as-is, no "auto:" prefix
        , Db.transactionCreatedAt = now
        , Db.transactionExpenseCategoryId = Just (toSqlKey cmeCategoryId)
        }
key <- runDb (insert entity)
pure (toTransactionResp key entity)
```

Validate sign-vs-tx_type через `isIncoming` НЕ требуется — handler формирует запись сам (controlled invariant), не из user-input sign.

Никаких mirror-инсертов в другие таблицы — это самостоятельная expense, не зеркало `MarketingSpend`.

### E. Tests — разделение по файлам (обновлено 2026-04-28 после HANDOFF v1)

**E1–E5 → `sitka-core/test/ApiSpec.hs`** новый describe-блок `Treasury — DM-7-C manual expenses` около строки 2606+. Integration через существующий harness (`setupPool`, `cleanDb` уже включает `expense_category` строкой 98, `withApp`, `postJ/patchJ/getJ/jf/jArr/sc`). Стиль — копия паттерна существующего `Treasury — DM-7-B-3 shipping-expense + reservation lifecycle` блока (~строка 2497). Использовать `runIO getCurrentTime` для realistic UTC; **non-round numbers** в amount-ах (NEXT_ACTIONS P1.3 — встраивается сюда явно).

**E6 (property test) → `sitka-core/test/TreasurySpec.hs`** в существующий describe-блок с `cashboxSnapshot` тестами Phase A (~строка 376). Pure unit pattern как у соседей — без HTTP/DB; QuickCheck `Gen RUB` / `Gen UTCTime` для tx_dates в прошлом, фиксированный список 4 seed-категорий как `[1..4] :: [Int64]` (или соответствующие сконструированные `Reservation` / `Transaction` доменные типы — Worker по контексту существующих тестов). Property: ∀ N (1 ≤ N ≤ 20), insert N manual expenses (amounts random non-zero positive RUB) → `cashboxSnapshot.csTotalBalance == baseline - SUM(amounts)`. Permutation-invariant: shuffle insert order не меняет финальный balance.

E1. **Categories CRUD happy path** (один большой test или 3-5 мелких — на усмотрение Worker):
- `POST /categories {slug="salary_q1_freelance", displayName="ФЛ Q1", kind="salary"}` → 200, returns `CategoryResp`.
- `GET /categories?archived=false` → contains 4 seed + new = 5 rows, sorted by `displayName ASC`.
- `PATCH /:id {displayName="Фрилансер Q1"}` → 200, displayName updated, archivedAt unchanged.
- `PATCH /:id {archivedAt=<now>}` (или `POST /:id/archive` если C2) → archived. `GET ?archived=false` не показывает; `?archived=true` показывает.
- `PATCH /:id {archivedAt=null}` (или `POST /:id/unarchive` если C2) → unarchive. `GET ?archived=false` снова показывает.

E2. **Conflict / validation cases**:
- `POST` дубликата slug на active row → 409.
- `POST` дубликата slug на archived row → 409 (НЕ auto-reactivate).
- `PATCH /:id` без полей (`{}`) → 400 "no fields to update".
- `POST {slug="", displayName="x", kind="ops"}` → 400 (B1).
- `POST {slug="x", displayName="   ", kind="ops"}` → 400 (B2, после strip).
- `POST {slug="x", displayName="X", kind="invalid_kind"}` → 400 (B3, Servant parse error).
- `PATCH /:id` где `:id = 999999` → 404.

E3. **Manual expense happy path**:
- `POST /expense {amount=12345.67, categoryId=<seed_ops_id>, notes="rent march", txDate=<2 days ago>}` → 200, `TransactionResp` с `txType="operational_expense"`, `sourceType="manual"`, `amount=-12345.67`, `expenseCategoryId=<id>`.
- `GET /transactions?type=operational_expense` → contains новая (filter работает).
- `GET /cashbox` → `csTotalBalance` уменьшается на 12345.67 относительно baseline (cashboxSnapshot интеграция).

E4. **Manual expense edge cases**:
- `amount = 0` → 400 (B6).
- `amount = -50` (negative input) → 400 (B6).
- `txDate = NOW + 5min` → 400 (B7, future).
- `txDate = NOW + 30s` (within skew tolerance) → 200.
- `txDate = NOW - 365d` (год назад) → 200 (backfill use-case).
- `categoryId = 999999` (no exist) → 404 (B8).
- `categoryId = <archived_id>` → 400 "category is archived" (B9).
- `notes` отсутствует в body → 200, `transaction.notes = NULL`.

E5. **Realistic fixture coverage** (NEXT_ACTIONS P1.3):
- В happy-path использовать non-round RUB amounts: 12345.67, 7800.50, 2999.99, 145000.0123.
- Slug-и с цифрами/подчёркиваниями: `salary_q1_freelance`, `ops_aws_2026`, `logistics_fwdr_us`.
- Один тест на «late-arriving manual expense after Deal Completed»: создаёт Deal → переводит в Completed (через State Machine helpers, аналогично существующим тестам) → POST /expense без deal_id (manual = НЕ deal-attributed) → проверка что `cashboxSnapshot.csRealizedProfit` НЕ меняется (manual expense это op cost, не per-deal cost; `revenuePerDeal` / `costPerDeal` для этого Deal остаются как до expense). `csTotalBalance` уменьшается на amount. Это property — manual expenses disjoint от per-deal P&L.

E6. **Property-based (mandatory для Tier A)**: один QuickCheck-property test:
- ∀ N (где 1 ≤ N ≤ 20), insert N manual expenses (random amounts через `Gen RUB`, random tx dates в прошлом, random category из seed) → `cashboxSnapshot.csTotalBalance == baseline - SUM(amounts)`. Permutation-invariant: shuffle insert order не меняет финальный balance.

### F. Объём и форма

F1. Diff только в файлах из секции "Файлы". Никаких других модификаций.
F2. Никаких новых миграций. Если возникает потребность — безусловный возврат в TL.
F3. `cabal build -Werror` чистый. `cabal test` все зелёные (новые + регрессия). `fourmolu --mode check` чистый.
F4. Pre-commit hooks (включая `weeder`, `import-linter`, `migration-drift`) clean.
F5. `git diff --stat` за PR — **менее 1500 строк** added + removed суммарно. Если ползёт сильно выше — возврат в TL, описать что разрослось.
F6. Один PR, один заход. Не дробить на mini-PR.

### G. Out of scope (НЕ делать в этом TASK)

- Frontend UI «Прочие расходы» — следующий TASK после accept этого.
- Разбивка outgoing по `expense_category.kind` в cashbox-виджете — Phase C Frontend / Phase D widgets.
- Per-currency expense (USD) — multi-currency out of scope DM-7.
- Bank import / reconciliation — out of scope DM-7.
- Auto-reactivate slug conflict — отвергнуто решением TL (B4).
- Reviewer round — TL запросит после HANDOFF; Worker не делает self-review.
- Обновление `docs/DM-7-cashbox.md` — TL сделает отдельным doc-PR (если выбран путь C2 в развилке) или оставит как есть (если C1).

## Контекст

- HEAD master: `4ce5694` (post merge PR #71).
- Phase A фундамент в master: PR #63 (миграция 0019, Domain types, `cashboxSnapshot`).
- Phase B: B-1 #64, B-2 #65, B-3 #66, post-fix #70 (`csExpectedMargin` plan-based).
- Дизайн: `docs/DM-7-cashbox.md` строки 269-283 (Phase C scope), 285-292 (Phase D), 314-330 (что хранить vs вычислять).
- Образец handler с auto-insert Transaction: `Api.Marketing.createSpendEntry` строки 340-389 (mirror Transaction в `runDb` после insert главного entity). НО: в Phase C `POST /expense` Transaction — главный insert, других нет.
- Образец generic transaction handler (validation, FK lookup, source-type discriminator): `Api.Treasury.createTransaction` строки 119-173. Phase C `POST /expense` — упрощённый специализированный case (currency=RUB hardcoded, sourceType=SourceManual hardcoded, FK Lead/Deal/Spend все=Nothing).
- Образец PATCH с `<|>` паттерном: `Api.Marketing.updateCampaign` строки 215-243.
- Существующие helper'ы в `Api.AppM`: `runDb`, `validateOr400`. `fetchOr404` — в `Api.AppM` или `Api.Helpers` (Worker найдёт grep'ом).
- `Domain.Transaction.SourceType` варианты: `SourceManual`, `SourceLead`, `SourceDeal`, `SourceSpendEntry`, `SourceBankImport` (строки 257-264). Использовать `SourceManual` для Phase C expense.
- Pre-сlug-conflict check pattern: `selectFirst [Db.ExpenseCategorySlug ==. slug] []` → если `Just _` — 409. Case-sensitive (`unique_expense_category_slug` constraint case-sensitive по умолчанию в Postgres).
- Decision audit (TL ↔ user 2026-04-28):
  - Один TASK, не дробить (подтверждено).
  - `tx_date`: прошлые ОК, будущее запрещено (NOW + 60s skew) (подтверждено).
  - Slug-конфликт: 409 always, no auto-reactivate (подтверждено).
  - Tri-state PATCH (C1) предпочтительнее, fallback на 2 endpoint-а (C2) разрешён если boilerplate >50 строк (TL решил единолично, не product-критично).
  - Currency RUB only в `POST /expense` (TL решил единолично, MVP-инвариант существующего кода).
  - Test-infra split (TL 2026-04-28 после HANDOFF v1, Option 1 из развилки Worker'а): E1-E5 integration → `ApiSpec.hs`, E6 property → `TreasurySpec.hs`. Не выносить shared `TestSupport.hs` в этом TASK.
- Test-infra factual basis (из Worker grounding HANDOFF v1):
  - `sitka-core/test/ApiSpec.hs:62-98` — `setupPool` + `cleanDb` (TRUNCATE list уже включает `expense_category` строкой 98, заготовка с Phase A).
  - `sitka-core/test/ApiSpec.hs:124-186` — HTTP helpers (`getJ/postJ/patchJ`), `jf/jArr/sc` JSON helpers (193-208).
  - `sitka-core/test/ApiSpec.hs:404` — `withApp = cleanDb >> runSession s (app [] Nothing pool)`.
  - `sitka-core/test/ApiSpec.hs:1915 / 2235 / 2371 / 2497` — DM-5 / B-1 / B-2 / B-3 Treasury describe-блоки. DM-7-C блок идёт после ~2606.
  - `sitka-core/test/TreasurySpec.hs:376-561` — Phase A `cashboxSnapshot` describe-блок (pure unit pattern). E6 property test встаёт туда же.

## Reviewer

После HANDOFF — TL запросит Reviewer round (Tier A money-flow handler требует human review за пределами self-check Worker'а). Модель и фокус решит TL глядя на diff. Вероятный план:
- **Codex red-team** на edge cases B4-B9 + tri-state PATCH semantics из C + `cashboxSnapshot` корректность (E5 invariant).
- ИЛИ **Claude repo-grounded** на стиль handler-ов и тесты vs существующий Treasury/Marketing.

Worker не делает self-review. Если Reviewer прислал findings — TL фильтрует, делает новый TASK или дополнение, Worker не реагирует напрямую.

## Worker workflow

1. Прочитать TASK целиком, сменить `Status: open` → `Status: in-progress`.
2. Создать ветку `feat/dm7-c-treasury-manual-expenses` (или близкий вариант), внести правки в файлах из "Файлы".
3. Локально: `cabal build -Werror && cabal test && fourmolu --mode check`. Все три зелёные.
4. Локально проверить F1-F6 (diff stat, нет миграций, нет touched files за scope).
5. Открыть PR в master с заголовком `feat(dm-7-c): treasury manual expenses CRUD + expense POST handler`.
6. Написать HANDOFF в `project-overlays/sitka-office/HANDOFFS/2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses.md` по шаблону `templates/HANDOFFS_TEMPLATE.md`. В HANDOFF:
   - Acceptance check по 7 группам A–G (отметка ✓/✗ с подробностью на ✗).
   - Артефакты: ветка, commit hash, PR URL.
   - "Замечено по дороге, не правил" если есть.
   - Какой путь в C развилке выбран (C1 tri-state или C2 два endpoint-а), с объяснением.
   - Открытые вопросы для TL (если есть).
7. Сменить `Status: in-progress` → `Status: review`.
8. Вернуть управление TL.

## Условные возвраты в TL (через HANDOFF секцией "Возврат в TL", без молчаливых правок)

- Domain types (Domain.ExpenseCategory / Transaction) недостаточны — стоп, описать чего не хватает.
- Tri-state PATCH (C1) даёт >50 строк boilerplate ИЛИ конфликтует с aeson генериком в репе — переключиться на C2 и зафиксировать в HANDOFF (это разрешённый fallback, не возврат, но **обязательно** упомянуть в HANDOFF чтобы TL обновил `docs/DM-7-cashbox.md`).
- Diff ползёт за 1500 строк — стоп, описать что разрослось (вероятно tests).
- Test infrastructure не позволяет integration test через существующий harness в TreasurySpec — стоп, описать.
- Любая необходимость добавить миграцию — стоп, безусловный возврат.
- `Engine.Treasury.cashboxSnapshot` некорректно агрегирует new OperationalExpense rows (для E5/E6 property tests) — стоп, это означает баг в Phase A engine, требует отдельного TASK на core engine.
