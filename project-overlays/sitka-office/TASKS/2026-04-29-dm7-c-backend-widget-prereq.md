# TASK: dm7-c-backend-widget-prereq

- Status: open
- Ready: no
- Mode: strict
- Date: 2026-04-29
- Project: sitka-office
- Layer: core
- Risk tier: A
- Owner: Project Tech Lead
- Worker model: Claude Code

> **DRAFT — awaits billing reset.** GitHub Actions billing на репо exhausted (PR #74 CI заблокирован до ~2026-04-30 reset). Worker НЕ стартует до явного TL go-сигнала. Когда billing reset → пользователь сообщает TL → TL передаёт промпт Worker'у. Этот TASK можно делать **параллельно** с финализацией PR #74 (independent file scope; нет конфликта).

## Задача

Расширить wire shape `Api.TransactionResp` полем `trExpenseCategoryId :: Maybe Int64` для будущего frontend widget breakdown по `expense_category.kind`. Текущий wire shape (`sitka-core/src/Api/Types.hs:1046-1060`) не несёт FK на category — фронт не может сделать честный join `transactions × categories` (см. backlog в `OPERATING.md`, grep verified Codex Reviewer hint 2026-04-29).

Это **prerequisite TASK** для Frontend Widget TASK (последняя связка DM-7-C). После accept этого TASK — фронт получит грунтованные данные для widget breakdown.

Mirror existing FK pattern в `TransactionResp`: `trLeadId / trDealId / trSpendEntryId` — все `Maybe Int64`. Добавляем 4-е такое поле для category linkage.

## Файлы

- `modify:`
  - `sitka-core/src/Api/Types.hs` — добавить `trExpenseCategoryId :: Maybe Int64` в `TransactionResp` record (после `trSpendEntryId`, до `trBankRef` — сохранить FK поля группой).
  - `sitka-core/src/Api/Treasury.hs` — расширить `toTransactionResp` (строка 647-663): добавить mapping `trExpenseCategoryId = fromSqlKey <$> transactionExpenseCategoryId`.
  - `sitka-core/test/ApiSpec.hs` — добавить 2 новых test cases в существующий `Treasury — DM-7-C manual expenses` describe (после ~строки 2774+ блока), pinning что:
    - manual expense через `POST /api/treasury/expense` отдаёт `trExpenseCategoryId = Just <categoryId>` в `TransactionResp`;
    - auto-mirrored Transaction (например через `Api.Marketing.createSpendEntry` или существующий `POST /api/treasury/transactions`) отдаёт `trExpenseCategoryId = Nothing`.
- `new:` —
- `delete:` —
- `migrations:` НЕТ (схема готова в 0019, поле `transaction.expense_category_id` уже добавлено).

## Не трогать

- `sitka-core/migrations/*` — НЕТ миграций.
- `sitka-core/src/Domain/*` — `Domain.Transaction.transactionExpenseCategoryId :: Maybe Int64` уже существует (Phase A). Не трогать.
- `sitka-core/src/Engine/*` — Engine layer не зависит от wire shape.
- `sitka-core/src/Db/Schema.hs` — `transaction.expenseCategoryId` поле уже в Persistent entity (Phase A).
- `sitka-core/src/Api/Server.hs` — нет.
- `sitka-services/`, `sitka-web/` — out of scope. Frontend `Transaction` TS type получит `trExpenseCategoryId` в **отдельном** Frontend Widget TASK (последняя связка), не здесь. JSON wire — backwards-compatible; existing TS consumers не ломаются (TS просто игнорит лишние JSON поля).
- `docs/DM-7-cashbox.md` — TL doc-PR отдельно. Если Worker считает что Resolved invariants пункт 8 нужно расширить — упомянуть в HANDOFF.
- Прочие markdown / `.claude/` / overlay в `ai-dev-system/` — нет.

Если по дороге заметишь что-то ещё, требующее правки — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. Wire shape (Api/Types.hs)

A1. В `TransactionResp` (строка ~1046) добавить ровно одно новое поле `trExpenseCategoryId :: Maybe Int64`. Позиция: **после `trSpendEntryId`**, **до `trBankRef`** — чтобы FK поля (`trLeadId / trDealId / trSpendEntryId / trExpenseCategoryId`) шли группой, что упрощает чтение и aligns с порядком `Db.Transaction` Persistent entity.

A2. Никаких других полей в `TransactionResp` не менять. Никаких других wire types не трогать.

A3. JSON encoding — generic `deriving anyclass (FromJSON, ToJSON)` (как сейчас). Поле сериализуется как `"trExpenseCategoryId": <Int64 | null>`.

### B. Mapping (Api/Treasury.hs)

B1. В `toTransactionResp` (строка ~647-663) добавить ровно одну новую строку:
```haskell
, trExpenseCategoryId = fromSqlKey <$> transactionExpenseCategoryId
```
Позиция: после `trSpendEntryId = fromSqlKey <$> transactionSpendEntryId`, до `trBankRef = transactionBankRef`. Зеркалит порядок поля в record (A1) и существующий FK mapping pattern.

B2. Никаких других изменений в `toTransactionResp` или соседних helpers (`toDomainTransaction`, `toDomainReservation` — не трогать).

B3. **Никаких новых helpers** (например `requireExpenseCategoryFK` — нет такой потребности, mapping тривиален). YAGNI.

### C. Tests (ApiSpec.hs дополнить)

C1. **Test 1: manual expense → `trExpenseCategoryId = Just <id>`.**

В существующем `Treasury — DM-7-C manual expenses` describe (Worker найдёт grep'ом `"Treasury — DM-7-C"`, строка ~2774+ или близко после merge PR #74) добавить:

```
it "POST /expense returns TransactionResp with trExpenseCategoryId pointing at the chosen category" $ do
  -- setup: одна active category + balance enough to pass guard
  category <- ... (POST /categories)
  _ <- ... (seedBalance N)
  -- exercise: POST /expense
  resp <- ... (POST /expense {amount=100, categoryId=<category.ecId>, ...})
  -- assert: respJSON has trExpenseCategoryId = Just category.ecId
  jfI resp "trExpenseCategoryId" `shouldBe` Just (fromIntegral category.ecId)
```

(Точная формулировка — Worker по контексту существующих helpers `categoryJ / expenseJ / freshCat / seedBalance` от TASK-1. JSON-helper `jfI` для `Maybe Int64` — Worker найдёт ближайший pattern.)

C2. **Test 2: auto-mirrored Transaction (через generic /transactions с не-OpEx или через MarketingSpend) → `trExpenseCategoryId = Nothing`.**

Параллельный test pinning что non-Phase-C transactions имеют `trExpenseCategoryId = null` в JSON. Один representative case (на усмотрение Worker'а):
- (a) `POST /transactions {txType=client_prepayment, sourceType=manual, ...}` через generic.
- (b) Или через `Api.Marketing.createSpendEntry` (auto-mirrors MarketingSpend Transaction); проверка через `GET /transactions?type=marketing_spend` и assert на shape.

(a) проще; Worker выбирает.

```
it "auto-mirrored Transaction has trExpenseCategoryId=null in TransactionResp" $ do
  resp <- ... (POST /transactions {non-OpEx-Manual case})
  jArr resp "trExpenseCategoryId" `shouldBe` Null  -- или: jf resp "trExpenseCategoryId" `shouldBe` Nothing
```

C3. **Регрессии:** existing 538 tests + 24+ DM-7-C tests от PR #72 — все зелёные. Никакие existing JSON-assertions на `TransactionResp` не сломаются (новое поле добавляется, не удаляется/переименовывается). Если Worker найдёт failing existing test — это значит старый assert использует **точное JSON shape**, и его нужно расширить (это фактически product-correct adjustment, не регрессия). Worker зафиксирует в HANDOFF.

C4. **Property-based test НЕ требуется** — расширение wire shape не меняет engine semantics. Existing property tests `cashboxSnapshot` от Phase A покрывают это.

### D. Объём и форма

D1. Diff только в файлах из §Файлы.
D2. НЕТ новых миграций.
D3. `cabal build -Werror` + `cabal test` (538 + 2 новых = 540 минимум) + `fourmolu --mode check` — все зелёные. Регрессий 0.
D4. Pre-commit hooks (gitleaks / EOF / trailing ws / mixed line endings / merge conflicts / import-linter) clean.
D5. `git diff --shortstat` за этот PR — менее **150 строк** added + removed суммарно (это очень маленькое изменение: +1 поле + 1 строка mapping + 2 tests с setup и assert).
D6. Один PR, заголовок `feat(dm-7-c): expose trExpenseCategoryId on TransactionResp for widget breakdown prereq`.

### E. Out of scope (НЕ делать)

- Frontend изменения (TS type / API client / widget) — отдельный TASK после accept этого.
- Расширение `Domain.Transaction` или `Db.Schema` — поле уже есть.
- Новые миграции — поле существует с Phase A.
- Refactor существующих `TransactionResp` consumers — wire shape backwards-compatible (новое поле, не breaking).
- Property tests / red-team Reviewer round — изменение слишком локализованное (~30 LOC, mirror existing pattern), TL human review достаточен.
- Обновление `docs/DM-7-cashbox.md` Resolved invariants — TL doc-PR отдельно после Frontend Widget TASK закроется (последний штрих в Phase C).

## Контекст

- Master HEAD на момент draft: `51fd8ef` (post PR #71/#72/#73). На момент Worker start — может быть подвинут после merge PR #74; Worker checkout-ит свежий `origin/master`.
- Frontend UI tab PR #74 (parallel TASK) НЕ трогает backend файлы — нет конфликта merge.
- `Db.Transaction.transactionExpenseCategoryId` уже существует в Persistent entity (`sitka-core/src/Db/Schema.hs:410` — Phase A).
- `Domain.Transaction.transactionExpenseCategoryId :: Maybe Int64` уже существует (`sitka-core/src/Domain/Transaction.hs:335`).
- `toDomainTransaction` уже мapит это поле (`sitka-core/src/Api/Treasury.hs:697`) — для Engine layer. Только wire shape `TransactionResp` его не несёт.
- Existing FK pattern в `TransactionResp` (что мирор-ит):
  - `trLeadId :: Maybe Int64` (Api/Types.hs:1053)
  - `trDealId :: Maybe Int64` (Api/Types.hs:1054)
  - `trSpendEntryId :: Maybe Int64` (Api/Types.hs:1055)
- Existing FK mapping pattern в `toTransactionResp` (что мирор-ит):
  - `trLeadId = fromSqlKey <$> transactionLeadId` (Api/Treasury.hs:656)
  - `trDealId = fromSqlKey <$> transactionDealId` (Api/Treasury.hs:657)
  - `trSpendEntryId = fromSqlKey <$> transactionSpendEntryId` (Api/Treasury.hs:658)
- Reviewer report (Codex) причинивший этот TASK: [`HANDOFFS/archive/2026-04-29-codex-reviewer-...`](../HANDOFFS/archive/) — был про PR #72, но идентифицировал API contract gap для widget breakdown.

## Reviewer

**Не запрашивается.** Tier A, но изменение строго mirror'ит existing pattern (4-е поле в FK группе, тривиальный mapping, 2 pinning tests). TL human review достаточен. Если Worker неожиданно поднимет architectural question в HANDOFF — TL может запросить round retroактивно.

## Worker workflow

1. Прочитать TASK + Reviewer report (audit) + HANDOFF v2 от TASK-1 (контекст PR #72).
2. Сменить Status: open → in-progress.
3. `git fetch origin && git checkout -b feat/dm7-c-backend-widget-prereq origin/master` (от свежего master, не от PR #74 ветки).
4. Внести правки:
   - `Api/Types.hs` — добавить поле в record.
   - `Api/Treasury.hs` — добавить строку в `toTransactionResp`.
   - `ApiSpec.hs` — 2 новых test cases в DM-7-C describe.
5. Локально: `cabal build -Werror && cabal test && fourmolu --mode check`. Все зелёные. `git diff --shortstat` < 150 строк.
6. Коммит, push, PR в master с заголовком `feat(dm-7-c): expose trExpenseCategoryId on TransactionResp for widget breakdown prereq`.
7. HANDOFF v1 в `HANDOFFS/2026-04-29-claude-worker-to-claude-tl-dm7-c-backend-widget-prereq.md` с acceptance check A-D + «Замечено по дороге» если есть.
8. Status: in-progress → review.

## Условные возвраты в TL

- Existing test ломается на новом JSON shape (вероятно: golden-style assertion с exact shape) → описать какой test, Worker может расширить assertion в том же PR (это accept'able adjustment, не scope expansion); если test расширен — отметить в HANDOFF.
- `transactionExpenseCategoryId` поле в `Db.Transaction` отсутствует или не Maybe (вряд ли, но если grep'ом покажет иначе) → стоп, безусловный возврат.
- Diff > 150 строк → стоп, описать что разрослось.
- Любая необходимость touch миграций / Domain types / Engine — безусловный возврат.
