# 2026-04-29-dm7-c-balance-guard-and-generic-reject

- ID: `2026-04-29-dm7-c-balance-guard-and-generic-reject`
- Created by: Claude Tech Lead session, 2026-04-29 (post Codex Reviewer round on PR #72)
- Worker model: Claude Code
- Worker branch: `feat/dm7-c-treasury-manual-expenses` (та же что для TASK-1; этот TASK добавляет коммит в существующий PR #72, НЕ новая ветка)
- Layer: core
- Risk tier: A (Api.Treasury, Api.Deals, money-flow invariants)
- Status: done

## Задача

Закрыть два P1 finding из Codex Reviewer round по PR #72 (см. [`HANDOFFS/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md`](../HANDOFFS/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md)):

**F1.** `createManualExpense` (`sitka-core/src/Api/Treasury.hs:411-444`) не имеет free-balance guard. Один POST может загнать `csFree < 0` (съесть резерв другой сделки) или `csTotalBalance < 0`. Нарушение DM-7 invariant «free_balance ≥ 0 после insert outgoing» (`docs/DM-7-cashbox.md` секция «Инварианты для Phase B»).

**F2.** Generic `POST /api/treasury/transactions` (`Api.Treasury.createTransaction:119-173`) принимает `OperationalExpense + SourceManual` без новых Phase C проверок (category required, archived check, skew, balance). Leak в invariant «manual operational expenses always categorized». Phase D category reports могут поставлять uncategorized rows.

Это **follow-up commit к PR #72** (та же ветка `feat/dm7-c-treasury-manual-expenses`). НЕ новая ветка / новый PR. После accept этого TASK + Worker push → PR #72 mergeable, TL финальный merge.

## Файлы

- `modify:`
  - `sitka-core/src/Api/Treasury.hs` — (a) добавить `guardFreeBalanceAfterOutgoing` call в `createManualExpense` перед insert; (b) добавить reject в `createTransaction` для `txType=OperationalExpense AND sourceType=SourceManual`. Возможно — перенести `guardFreeBalanceAfterOutgoing` (+ companion `guardFreeBalanceAfter`) из `Api.Deals` в `Api.Treasury` (см. секцию «Архитектурное решение»).
  - `sitka-core/src/Api/Deals.hs` — обновить импорт `guardFreeBalanceAfterOutgoing` ЕСЛИ выбран рефакторинг (a) из «Архитектурного решения». Иначе НЕ трогать.
  - `sitka-core/test/ApiSpec.hs` — добавить ~6-8 новых тестов в существующий describe `Treasury — DM-7-C manual expenses` (см. секцию C ниже).
- `new:` —
- `delete:` —
- `migrations:` НЕТ.

## Архитектурное решение (выбор Worker'а с TL рекомендацией)

`guardFreeBalanceAfterOutgoing :: RUB -> AppM ()` сейчас в `Api.Deals.hs:1331-...`, signature reads cashbox snapshot и throws 400 при `csFree - addAmount < 0`. Используется 4 раза в Phase B handlers (`Api.Deals.hs:1080`, `1216`, `1284`, `1395`). Phase C даёт 5-е использование в `Api.Treasury.createManualExpense`.

**Опции для Worker'а** (выбери ОДНУ, зафиксируй в HANDOFF v3):

(a) **Перенести `guardFreeBalanceAfterOutgoing` (и companion `guardFreeBalanceAfter`) в `Api.Treasury`**, экспортировать оттуда, обновить импорт в `Api.Deals`. Чище архитектурно — guard принадлежит treasury layer, не deals layer. Условие: проверь grep'ом что `Api.Treasury` НЕ импортирует из `Api.Deals` (в DM-7-B-3 импорт идёт обратно — `Api.Deals` использует `toDomainTransaction`/`toDomainReservation` из `Api.Treasury`). Если import direction подтверждён — refactor чистый, нет cyclic.

(b) **Оставить guard в `Api.Deals`, импортировать из `Api.Treasury.createManualExpense` через `import Api.Deals (guardFreeBalanceAfterOutgoing)`**. Fallback если (a) даёт cyclic. Less clean, но functional.

(c) Дублировать guard в `Api.Treasury` — отвергнут TL как DRY violation (CLAUDE.md «Repeated patterns → helpers, not copy-paste»).

**TL рекомендация: (a)**. Если cyclic подтверждён — (b). Принять решение и зафиксировать в HANDOFF v3.

## Не трогать

- `sitka-core/migrations/*` — НЕТ миграций. Безусловный возврат при потребности.
- `sitka-core/src/Domain/*`, `sitka-core/src/Engine/*` — типы и engine готовы.
- `sitka-core/src/Db/Schema.hs` — НЕТ.
- `sitka-core/src/Api/Server.hs` — НЕТ.
- `sitka-services/`, `sitka-web/` — out of scope.
- `sitka-core/test/TreasurySpec.hs` — НЕТ (E6 property test покрывает property; новые tests строго integration в ApiSpec).
- Прочие блоки `ApiSpec.hs` (всё кроме `Treasury — DM-7-C manual expenses` describe) — НЕТ.
- `docs/DM-7-cashbox.md` — НЕТ. Если Worker считает что секция «Инварианты для Phase B» должна быть обновлена под Phase C — упомянуть в HANDOFF, не править. TL сделает doc-PR отдельно.

Если по дороге заметишь что-то ещё, требующее правки за пределами scope — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. Free-balance guard в `createManualExpense`

A1. `createManualExpense` после category lookup и archived check, ДО `runDb (insert entity)`, вызывает `guardFreeBalanceAfterOutgoing amtPositive` (или эквивалент через путь (a)/(b) из «Архитектурного решения»).
A2. При `csFree - amtPositive < 0` → 400 с осмысленным `errBody` (стиль копируется с existing usage в `Api.Deals.hs:1331+`). Ledger row не вставляется.
A3. При `csFree - amtPositive >= 0` → 200, ledger row вставляется, snapshot обновляется корректно.
A4. Race-condition mitigation (advisory lock) — НЕ требуется. Accepted residual risk на solo сетапе (`docs/DM-7-cashbox.md` «Риски Phase B» п. 1).

### B. Generic /transactions reject для `OperationalExpense + SourceManual`

B1. `createTransaction` (`Api.Treasury.hs:119-173`) после существующих validation checks (currency, amount sign, source-type-vs-FK), ДО insert, добавляет проверку:
```haskell
validateOr400
  (ctrTxType == OperationalExpense && ctrSourceType == SourceManual)
  "manual operational expense must use POST /api/treasury/expense (category required + balance guard)"
```
Точная формулировка `errBody` на усмотрение Worker'а — главное чтобы (i) указывала на dedicated endpoint, (ii) объясняла что обязательны category + balance guard.

B2. Прецедент стиля: `Api.Deals.hs:419-421` (DM-7-B-2 reject `confirm_purchase` в generic transitionDeal с redirect message «use POST /api/deals/:id/confirm-purchase»). Копировать стиль и расположение проверки (после general validation, перед insert).

B3. Все остальные комбинации `(txType, sourceType)` через generic /transactions работают как раньше — НЕ regression. В частности:
- `OperationalExpense + SourceLead/Deal/SpendEntry/BankImport` → 200 (другие источники для OpEx допустимы через generic).
- `ClientPrepayment + SourceManual` → 200 (Manual + non-OpEx — generic accepts).
- Все B-1/B-2/B-3 auto-mirrored Transactions через handler-specific endpoints — не задействуют generic, не regress.

### C. Tests (~6-8 новых cases в существующем describe `Treasury — DM-7-C manual expenses` в `ApiSpec.hs`)

C1. **`E_balance_guard_block`**: setup — фиксированный baseline cashbox (например seeded OwnerDeposit или existing E1 setup). POST /expense с `amount > csFree` → ожидается 400. После этого: GET /transactions фильтр `type=operational_expense` НЕ показывает новую row (insert не произошёл); GET /cashbox `csTotalBalance` равен baseline.

C2. **`E_balance_guard_pass`**: setup как C1. POST /expense с `amount` существенно меньше `csFree` (например 100 RUB) → 200, TransactionResp в ответе. После: GET /cashbox `csFree` уменьшился ровно на amount, `csTotalBalance` тоже уменьшился на amount.

C3. **`E_generic_reject_OpEx_Manual`**: POST /transactions с body `{txType="operational_expense", sourceType="manual", amount=-100, txDate=<now>, currency="rub"}` → 400 с message containing "POST /api/treasury/expense" или эквивалент per B1.

C4. **`E_generic_other_OpEx_kinds`**: один representative тест, что `OperationalExpense` через generic с другим sourceType (например `SourceSpendEntry` с seeded spendEntryId) проходит как 200. Worker выбирает один представитель из {SourceLead, SourceDeal, SourceSpendEntry, SourceBankImport}.

C5. **`E_generic_other_kinds_Manual`**: POST /transactions {txType="client_prepayment", sourceType="manual", amount=+1000, ...} → 200 (Manual + non-OpEx — generic accepts, не reject). Подтверждает что reject специфичен для `OperationalExpense + SourceManual`, не разрушает existing flow.

C6. **(опц.)** `E_balance_guard_after_archived_block`: чтобы убедиться что guard пересекается корректно с archived check — POST /expense на archived category с amount > csFree → 400 от первой проверки (B9 archived), не от balance. Worker может пропустить если избыточно.

Использовать `runIO getCurrentTime`, non-round amounts, follow стиль existing `Treasury — DM-7-C manual expenses` блока (Worker сам выбирает helpers `categoryJ`, `expenseJ`, `freshCat` уже в файле от TASK-1).

### D. Объём и форма

D1. Diff только в файлах из §Файлы.
D2. НЕТ новых миграций.
D3. `cabal build -Werror` + `cabal test` (включая старые DM-7-C E1-E6 + 22 integration tests от TASK-1) + `fourmolu --mode check` — все зелёные. **Ноль регрессий** в существующих 532 tests.
D4. Pre-commit hooks (gitleaks, EOF, trailing ws, import-linter, etc.) clean.
D5. `git diff --shortstat` за follow-up commit (от текущего HEAD ветки `feat/dm7-c-treasury-manual-expenses` = `03ae50d`) — менее **400 строк** added + removed суммарно.
D6. Push в существующую ветку `feat/dm7-c-treasury-manual-expenses` через `git push`. PR #72 автоматически расширяется. CI прогон.
D7. Один новый commit на ветке (или 2 если refactor (a) логически отделим: первый — refactor, второй — guard + reject + tests). На усмотрение Worker'а.

### E. Out of scope (НЕ делать)

- Race condition mitigation (advisory lock / serializable isolation) на guard — accepted residual.
- Refactor existing 4 Phase B uses of guard в `Api.Deals` — вне scope, кроме обновления import path если выбран путь (a).
- Обновление `docs/DM-7-cashbox.md` — TL doc-PR отдельно после merge.
- `validateSourceLinks` вычисление в `createManualExpense` — handler controls invariant через hardcoded values (TASK-1 §D, accepted).
- 60s skew tolerance изменения — Codex признал не критическим, не трогаем.

## Контекст

- HEAD master: `4ce5694`. Ветка `feat/dm7-c-treasury-manual-expenses` от master, последний commit `03ae50d` (Worker TASK-1).
- TASK-1: `TASKS/2026-04-27-dm7-c-treasury-manual-expenses.md` (Status: review, ждёт finalmerge после этого TASK-2).
- HANDOFF v2 (TASK-1): `HANDOFFS/2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses-v2.md`.
- Reviewer report (Codex): `HANDOFFS/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md` — содержит детали обоих P1, raw report.
- `guardFreeBalanceAfterOutgoing` definition: `sitka-core/src/Api/Deals.hs:1331-...`. Signature `RUB -> AppM ()`. Computes snapshot через `Api.Treasury.cashboxSnapshot` (Worker grep подтвердит) и throws 400 при `csFree - addAmount < 0`.
- Existing usages: `Api.Deals.hs:1080` (ConfirmPrepayment через `guardFreeBalanceAfter`), `1216` (legacy-prepayment), `1284` (ConfirmPurchase), `1395` (ShippingExpense).
- Existing reject pattern: `Api.Deals.hs:419-421` — copy formulation для B2.
- Existing test helpers в `Treasury — DM-7-C manual expenses` describe (`ApiSpec.hs` ~строка 2774+): `categoryJ`, `patchCategoryJ`, `expenseJ`, `freshCat`, `collectIds`, `driveToCompleted`. Reuse.

## Reviewer

После HANDOFF v3 — TL human review. **Без второго Codex round-а** — изменения локализованы (guard call + reject + tests), оба finding'а P1 защищены явно, Codex'у нечего проверять второй раз.

## Worker workflow

1. Прочитать этот TASK + HANDOFF v2 (контекст PR #72) + Reviewer HANDOFF (детали обоих P1).
2. Сменить Status: open → in-progress.
3. `git fetch origin && git checkout feat/dm7-c-treasury-manual-expenses` (НЕ создавать новую ветку).
4. Grep на `guardFreeBalanceAfterOutgoing` в `Api.Deals.hs`. Проверить cycle — `Api.Treasury` НЕ должен импортировать из `Api.Deals` (в B-3 направление обратное). Выбрать (a) или (b).
5. Внести правки:
   - (a) (если выбран) перенести guards в `Api.Treasury`, экспортировать, обновить импорт в `Api.Deals`.
   - Treasury.hs: вызвать guard в `createManualExpense`, reject в `createTransaction`.
   - ApiSpec.hs: 5-6 (опц. 7) новых tests в `Treasury — DM-7-C manual expenses` блоке (или сразу за ним).
6. Локально: `cabal build -Werror && cabal test && fourmolu --mode check` — все зелёные. `git diff --shortstat` за этот commit < 400 строк.
7. Коммит на ветку с заголовком `fix(dm-7-c): free-balance guard for manual expense + reject OpEx+Manual in generic /transactions`. Push в `origin feat/dm7-c-treasury-manual-expenses`.
8. PR #72 автоматически обновляется. CI прогон. Дождаться зелёного.
9. Написать HANDOFF v3 в `HANDOFFS/2026-04-29-claude-worker-to-claude-tl-dm7-c-balance-guard-and-generic-reject.md` по шаблону. В HANDOFF указать:
   - Acceptance check по A-D (✓/✗ с деталями).
   - Какой путь (a/b) выбран в «Архитектурном решении» и почему.
   - "Замечено по дороге" если есть.
   - Ссылка на новый commit hash и обновлённый PR #72 status.
10. Сменить Status в этом TASK: in-progress → review.
11. Вернуть управление TL.

## Условные возвраты в TL (через HANDOFF, без молчаливых правок)

- Cyclic import при (a) → переключиться на (b), зафиксировать в HANDOFF v3.
- `guardFreeBalanceAfterOutgoing` зависит от Deals-specific things (вряд ли — он работает с general cashbox snapshot, но проверь grep'ом definitions) → возврат в TL.
- Diff > 400 строк → стоп, описать что разрослось.
- Любая необходимость touch миграций / Domain types / Engine.Treasury — безусловный возврат.
- Тесты регрессии в существующих 532 (любая red lane) — стоп, не проксировать.
