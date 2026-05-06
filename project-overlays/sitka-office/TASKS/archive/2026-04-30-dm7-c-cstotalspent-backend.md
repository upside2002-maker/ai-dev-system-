# 2026-04-30-dm7-c-cstotalspent-backend

- ID: `2026-04-30-dm7-c-cstotalspent-backend`
- Created by: Claude Tech Lead session, 2026-04-30 (pre-req для T3+T4 Variant B widget)
- Worker model: Claude Code
- Worker branch: `feat/dm7-c-cstotalspent-backend` (новая ветка от свежего `origin/master`, **после merge PR #74 и PR #75** — иначе CashboxSnapshot literals в TreasurySpec.hs мерж-конфликтнут с post-merge state)
- Layer: core
- Risk tier: A (CashboxSnapshot wire shape, money-flow snapshot)
- Status: done (merged 2026-05-01 14:50Z, PR #76, master sha `43ebf14`)

> **DRAFT — awaits TL go-signal.** GitHub Actions billing на репо exhausted (PR #74 + PR #75 CI заблокирован до billing reset). После reset → merge обоих PR → пользователь сообщает TL → TL передаёт промпт Worker'у. Этот TASK НЕ начинается, пока master не подвинут на post-#74-#75 HEAD.

## Задача

Расширить `Engine.Treasury.CashboxSnapshot` новым полем `csTotalSpent :: RUB` для будущего Variant B widget (T3+T4 IA refactor — отдельный frontend TASK). Поле представляет сумму всех outgoing-транзакций (negative-amount), отображается в UI как «Потрачено».

Формула:
```
csTotalSpent = negate (SUM (transaction.amount WHERE amount < 0))
```

Использует existing helpers `negateRub . sumAmounts . filter (amountIs (< 0))`. Per-period scope **не нужен** — это running-total всего ledger (mirror'ит `csTotalBalance` поведение). Frontend Variant B cell просто рендерит число.

Это **prerequisite TASK** для T3+T4 IA refactor. Frontend TS type / widget cell renderer / 6 vitest mocks → во втором TASK, не здесь (Option A: backend-only PR, additive JSON, backwards-compatible — current FE consumers просто игнорят новое поле).

## Файлы

- `modify:`
  - `sitka-core/src/Engine/Treasury.hs` — добавить `csTotalSpent :: RUB` в `CashboxSnapshot` record (позиция: **после `csExpectedMargin`**, **до `csBackfillPending`** — semantic order: balance → reserved → free → realized → expected → spent → backfill). Расширить `cashboxSnapshot` builder (строка ~428-435) одной строкой `csTotalSpent = totalSpent` где `totalSpent = negateRub (sumAmounts (filter (amountIs (< 0)) txs))`. Обновить Haddock-комментарий перед `data CashboxSnapshot` (строки 64-106) — добавить пункт `csTotalSpent` после `csExpectedMargin`.
  - `sitka-core/test/TreasurySpec.hs` — расширить **9 unit test cases** с explicit `CashboxSnapshot {...}` literal (строки 380, 398, 423, 443, 462, 488, 514, 532, 548) добавлением `, csTotalSpent = <expected RUB>` в каждый record. Property test (`cashboxSnapshot is permutation-invariant`, строка ~574-575) — расширить **только если он сравнивает с explicit `CashboxSnapshot` literal**; если нет (просто `snap1 == snap2`) — не трогать.
  - `sitka-core/test/ApiSpec.hs` — добавить **1 новый integration test** в существующий `Treasury — DM-7-C manual expenses` describe (после E5, строка ~3175+ — Worker найдёт grep'ом `"E5: manual expense"` и добавит **E6** или **E7** в зависимости от имеющейся нумерации после PR #72 merge) pinning что `csTotalSpent` правильно вычисляется через `GET /api/treasury/cashbox` после нескольких outgoing tx.
- `new:` —
- `delete:` —
- `migrations:` НЕТ (схема готова — `transaction.amount` существует с миграции 0010).

## Не трогать

- `sitka-core/migrations/*` — НЕТ миграций.
- `sitka-core/src/Domain/*` — `Domain.Transaction.transactionAmount :: RUB` уже существует. Не трогать.
- `sitka-core/src/Db/Schema.hs` — `transaction.amount` поле уже в Persistent entity.
- `sitka-core/src/Api/Server.hs` — нет.
- `sitka-core/src/Api/Treasury.hs` — нет (handler `getCashbox` строка 288 уже корректно вызывает `cashboxSnapshot` builder; добавление поля внутри builder не требует handler-изменений).
- `sitka-services/`, `sitka-web/` — out of scope. Frontend TS type `CashboxSnapshot` (`sitka-web/src/api/types.ts:389-396`), 6 vitest mocks в `CashboxWidget.test.tsx` (строки 22, 67, 86, 111, 126, 140), и UI cell renderer — всё **в отдельном** T3+T4 IA refactor TASK. JSON wire — backwards-compatible (новое поле, существующий FE TS-тип не сломается на лишнем поле в JSON).
- `docs/DM-7-cashbox.md` — TL doc-PR отдельно после accept этого + T3+T4 (синхронный update на оба change'а).
- Прочие markdown / `.claude/` / overlay в `ai-dev-system/` — нет.

Если по дороге заметишь что-то ещё, требующее правки — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. Engine update (Engine/Treasury.hs)

A1. В `CashboxSnapshot` record (строка 107-114) добавить ровно одно новое поле `csTotalSpent :: RUB`. Позиция: **после `csExpectedMargin`**, **до `csBackfillPending`**. Финальный record:
```haskell
data CashboxSnapshot = CashboxSnapshot
  { csTotalBalance :: RUB
  , csReserved :: RUB
  , csFree :: RUB
  , csRealizedProfit :: RUB
  , csExpectedMargin :: RUB
  , csTotalSpent :: RUB
  , csBackfillPending :: Int
  }
```

A2. В `cashboxSnapshot` builder (строка 379-435) добавить локальный `let`-binding и поле в финальный record:
```haskell
totalSpent = negateRub (sumAmounts (filter (amountIs (< 0)) txs))
...
in CashboxSnapshot
  { ...
  , csExpectedMargin = expected
  , csTotalSpent = totalSpent
  , csBackfillPending = backfillPendingCount
  }
```
Конкретное место `let totalSpent = ...` — рядом с другими `let`-bindings (`total`, `reserved`, `free`, `realized`, `expected`), на усмотрение Worker'а. Никаких новых helpers (всё существующие `negateRub / sumAmounts / amountIs` reuse).

A3. Расширить Haddock-комментарий перед `data CashboxSnapshot` (строки 64-106): добавить пункт `csTotalSpent` после описания `csExpectedMargin`. Текст ~5 строк, mirror'ит стиль existing полей. Минимум:
```
* 'csTotalSpent' = @negate (SUM (transaction.amount WHERE amount < 0))@.
  Running total всех outgoing-транзакций по ledger'у. Отображается
  в UI как «Потрачено» (DM-7-C Variant B widget cell). Sign convention:
  positive number — money already spent.
```

A4. Никаких других изменений в `Engine.Treasury` модуле. Никаких изменений в exports list (`csTotalSpent` доступен через `CashboxSnapshot (..)` re-export).

### B. Tests (TreasurySpec.hs)

B1. Расширить 9 existing `cashboxSnapshot` unit test cases в `TreasurySpec.hs` (строки 380, 398, 423, 443, 462, 488, 514, 532, 548) — каждый имеет explicit `CashboxSnapshot { ... } shouldBe`. В каждый добавить `csTotalSpent = <expected>` где `<expected>` Worker вычисляет вручную из input fixtures (negate-сумма negative transactions).

Канонический пример: empty input (строка 379-380):
```haskell
cashboxSnapshot [] [] [] [] 0
  `shouldBe` CashboxSnapshot
    { csTotalBalance = RUB 0
    , csReserved = RUB 0
    , csFree = RUB 0
    , csRealizedProfit = RUB 0
    , csExpectedMargin = RUB 0
    , csTotalSpent = RUB 0   -- ← добавляется
    , csBackfillPending = 0
    }
```

B2. Property test `cashboxSnapshot is permutation-invariant` (строка ~574+) — если test использует `snap1 `shouldBe` snap2` (без enumeration полей) — **НЕ трогать** (поле автоматически покрыто Eq derivation). Если есть отдельный property test с explicit field literal — расширить.

B3. **Если найдётся новый property test, который мог бы pin `csTotalSpent`** invariant (например: `csTotalSpent <= csTotalBalance` only when starting from zero — не общий invariant; или `csTotalSpent ≥ 0` always — это в общем верно потому что `negateRub` на negative tx даёт positive) — Worker может **опционально** добавить 1 property test, но не обязан. Если добавит — отметить в HANDOFF как drive-by accept.

B4. Существующие 538 tests + 24 DM-7-C tests от PR #72 — все зелёные. Никакие existing JSON-assertions на `CashboxSnapshot` shape (через `getJ "/api/treasury/cashbox"`) не сломаются — новое поле additive.

### C. Integration test (ApiSpec.hs)

C1. Добавить **1 новый test** в `Treasury — DM-7-C manual expenses` describe (после E5, строка ~3175+ post-#72 merge, точная позиция Worker grep'нет `"E5: manual expense after Deal Completed"` и поставит сразу за ним) с приблизительным телом:
```haskell
it "E6: csTotalSpent reflects sum of outgoing transactions in the cashbox snapshot" $
  withApp $ do
    -- setup: seed cashbox with positive balance + create N outgoing tx
    _ <- seedBalance 100000
    cat <- categoryJ <$> postJ "/api/treasury/categories" (mkCategoryReq "ops_test" "Ops test" "ops")
    -- exercise: 3 manual expenses через POST /expense (each amount > 0; backend negates)
    _ <- postJ "/api/treasury/expense" (mkExpenseReq cat 5000 "first")
    _ <- postJ "/api/treasury/expense" (mkExpenseReq cat 7000 "second")
    _ <- postJ "/api/treasury/expense" (mkExpenseReq cat 3000 "third")
    -- assert: csTotalSpent = 15000 (positive, как сумма потраченного)
    snap <- getJ "/api/treasury/cashbox"
    liftIO $
      jf snap "csTotalSpent" `shouldBe` Just (15000.0 :: Double)
```

(Точная формулировка — Worker по контексту existing helpers `categoryJ / expenseJ / freshCat / seedBalance / mkExpenseReq` от PR #72. JSON-helper `jf` для `Maybe Double` уже используется на строках 2161, 2287, 3062, 3095. Тестовый pattern зеркалит E3 строка 3053.)

C2. Test pin'ит что:
- (a) Pure outgoing tx contribute to `csTotalSpent`.
- (b) Sign convention right: backend negates `txAmount` before insert (Phase C `createManualExpense` invariant), engine `csTotalSpent` re-negates назад в positive.
- (c) Wire shape carries поле как `Double`.

C3. **OwnerDeposit / incoming tx** в test setup НЕ должны контаминировать `csTotalSpent` (они positive-amount, filter `amountIs (< 0)` их отбрасывает). Worker верифицирует это **assertion**'ом в test — например после `seedBalance 100000` (положительная tx), до создания expenses, `csTotalSpent` ещё `0`.

### D. Объём и форма

D1. Diff только в файлах из §Файлы.
D2. НЕТ новых миграций. НЕТ новых helpers (только существующие `negateRub / sumAmounts / amountIs`).
D3. `cabal build -Werror && cabal test && fourmolu --mode check` — все зелёные. Регрессий 0. Test count: 538 baseline + 1 новый = 539 минимум.
D4. Pre-commit hooks (gitleaks / EOF / trailing ws / mixed line endings / merge conflicts / import-linter) clean.
D5. `git diff --shortstat` за этот PR — менее **80 строк** added + removed суммарно (это маленькое изменение: +1 поле + ~3 строки computation + ~5 строк Haddock + 9×1 строк test updates + ~15 строк новый E6 test = ~33-50 LOC).
D6. Один PR, заголовок `feat(dm-7-c): add csTotalSpent to CashboxSnapshot for Variant B widget prereq`.

### E. Out of scope (НЕ делать)

- Frontend изменения (TS type / mocks / widget renderer / CashboxWidget cell layout) — следующий T3+T4 TASK.
- Drop `csExpectedMargin` из `CashboxSnapshot` — **НЕ трогать**. Поле остаётся в backend (может пригодиться для Phase D финансовых отчётов / planning widget). T3+T4 widget просто перестанет рендерить эту cell — backend wire shape unchanged за этот invariant.
- Per-period scoping `csTotalSpent` (например `csTotalSpentPeriod7d`) — YAGNI, текущий план не требует. Один running-total как `csTotalBalance`.
- Per-category breakdown (например `csSpentByKind :: Map ExpenseKind RUB`) — отдельный Phase D widget breakdown TASK (backlog).
- Расширение `CashflowReport` — он уже имеет `crOutgoing`. Не дублируем.
- Property tests / red-team Reviewer round — изменение слишком локализованное (~50 LOC, mirror existing pattern), TL human review достаточен.
- Обновление `docs/DM-7-cashbox.md` — TL doc-PR отдельно после accept этого + T3+T4 (синхронный update обоих).
- TS type update в `sitka-web/src/api/types.ts` — НЕ здесь, в T3+T4 TASK (атомарно с UI cell renderer и mocks).

## Контекст

- Master HEAD на момент draft: `51fd8ef` (post PR #71/#72/#73). Worker checkout-ит свежий `origin/master` после merge PR #74 + PR #75 (post-billing-reset).
- `Engine.Treasury.CashboxSnapshot` определён в `sitka-core/src/Engine/Treasury.hs:107-114` (6 полей).
- `cashboxSnapshot` builder: `sitka-core/src/Engine/Treasury.hs:379-435`.
- Wire shape derived через `deriving anyclass (FromJSON, ToJSON)` — нет separate `Api.Types` wrapper.
- Handler: `sitka-core/src/Api/Treasury.hs:288 getCashbox` — не трогается.
- Existing helpers reuse:
  - `negateRub :: RUB -> RUB` — `Engine/Treasury.hs:312-313`.
  - `sumAmounts :: [Transaction] -> RUB` — `Engine/Treasury.hs:298-299`.
  - `amountIs :: (RUB -> Bool) -> Transaction -> Bool` — `Engine/Treasury.hs:306-307`.
- Mirror'ит existing pattern (`outgoingByCategory` строка 176-180):
  ```haskell
  filter (\t -> inPeriod p t && amountIs (< 0) t)
  ```

## Reviewer

**Не запрашивается.** Tier A, но изменение строго additive в pure engine + existing helpers reuse. Сигнатуры handlers не меняются. JSON backwards-compatible. TL human review достаточен. Если Worker неожиданно поднимет architectural question в HANDOFF (например: где per-period scoping; почему running, не daily; etc) — TL может запросить round retroактивно.

## Worker workflow

1. Прочитать TASK + OPERATING сводку (раздел «Сводка для старта следующей TL сессии») + HANDOFF v2 от PR #72 (контекст Phase C Core).
2. Сменить Status: open → in-progress.
3. **Verify pre-req:** `git fetch origin && git log origin/master --oneline -3` — confirm PR #74 (`feat(dm-7-c): frontend UI tab ...`) и PR #75 (`fix(dm-7-c): unified deal financial block ...`) уже в master. Если нет — STOP, return в TL (пре-condition не выполнен).
4. `git checkout -b feat/dm7-c-cstotalspent-backend origin/master` (от свежего post-merge master).
5. Внести правки:
   - `Engine/Treasury.hs` — поле + computation + Haddock.
   - `TreasurySpec.hs` — 9 explicit literal updates.
   - `ApiSpec.hs` — 1 новый E6 integration test.
6. Локально: `cabal build -Werror && cabal test && fourmolu --mode check`. Все зелёные. `git diff --shortstat` < 80 строк.
7. Коммит, push, PR в master с заголовком `feat(dm-7-c): add csTotalSpent to CashboxSnapshot for Variant B widget prereq`.
8. HANDOFF v1 в `HANDOFFS/2026-04-30-claude-worker-to-claude-tl-dm7-c-cstotalspent-backend.md` с acceptance check A-D + «Замечено по дороге» если есть.
9. Status: in-progress → review.

## Условные возвраты в TL

- Property test (строка ~574+) использует enumeration полей `CashboxSnapshot` — описать в HANDOFF, Worker может расширить (это accept'able adjustment).
- Existing test (`getJ "/api/treasury/cashbox"`) ломается на новом JSON shape (вряд ли, но если golden-style assertion с exact shape) → описать какой test, Worker может расширить.
- Diff > 80 строк → стоп, описать что разрослось.
- Любая необходимость touch миграций / Domain types / Api/Treasury handler / Frontend файлов — безусловный возврат.
- PR #74 / PR #75 не merged на момент checkout — STOP, return.
