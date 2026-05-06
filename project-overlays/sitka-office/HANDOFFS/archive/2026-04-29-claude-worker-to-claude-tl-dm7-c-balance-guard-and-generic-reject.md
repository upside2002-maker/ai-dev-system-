# HANDOFF v3 — DM-7-C balance guard + generic reject (Worker → TL, REVIEW)

- Date: 2026-04-29 18:30
- From: Claude Worker, branch `feat/dm7-c-treasury-manual-expenses` (follow-up commit on top of TASK-1 work)
- To: Claude Tech Lead (sitka-office)
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: [`project-overlays/sitka-office/TASKS/2026-04-29-dm7-c-balance-guard-and-generic-reject.md`](../TASKS/2026-04-29-dm7-c-balance-guard-and-generic-reject.md)
- Predecessors:
  - [HANDOFF v1 (test-infra unblock, TASK-1)](2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses.md) — closed
  - [HANDOFF v2 (TASK-1 implementation)](2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses-v2.md) — closed by Codex Reviewer round
  - [Codex Reviewer report (P1×2 findings)](2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md) — closed by TL
- Status: closed

## TL;DR

Готов. Follow-up commit `3c30caf` на ветке `feat/dm7-c-treasury-manual-expenses` (PR [#72](https://github.com/upside2002-maker/sitka-office/pull/72) расширен до 2 коммитов). 3 файла, 234/65 = 299 строк diff (под 400). Полный test suite зелёный (538/538: 532 pre-existing + 6 новых C1–C6). **(a) — refactor выбран** (cycle clean). Status TASK-2: `in-progress` → `review`.

## Acceptance check (TASK-2 §A–D)

### A. Free-balance guard в createManualExpense ✓

A1. ✓ Вызов `guardFreeBalanceAfterOutgoing cmeAmount` в `Api.Treasury.createManualExpense` после category lookup и archived check, перед `runDb (insert entity)`. Точное место — между B9 archived check и `let signedAmount = ...`. Виден в diff [`sitka-core/src/Api/Treasury.hs`](../../../../sitka-office/sitka-core/src/Api/Treasury.hs) около строки 506.

A2. ✓ При `csFree - amtPositive < 0` → 400 с `errBody = "operation would push cashbox free below 0 (purchase exceeds free balance)"` (стиль скопирован из существующего сообщения guard'а). Ledger row не вставляется — guard throws до insert. Тест C1 это пинит явно: после 400 ответа `GET /transactions?type=operational_expense` возвращает 0 rows и `csTotalBalance` остаётся 0.

A3. ✓ При `csFree - amtPositive >= 0` → 200, ledger row вставляется, snapshot обновляется. Тест C2 пинит: после 200 `csFree` уменьшается ровно на amount, `csTotalBalance` тоже уменьшается на amount.

A4. ✓ Race-condition mitigation не реализована — accepted residual (`docs/DM-7-cashbox.md` "Риски Phase B" п. 1, 1-operator scale).

### B. Generic /transactions reject для OperationalExpense + SourceManual ✓

B1. ✓ В `Api.Treasury.createTransaction` после `validateSourceLinks` и перед FK validation добавлен:

```haskell
validateOr400
  (ctrTxType == OperationalExpense && ctrSourceType == SourceManual)
  "manual operational expenses must use POST /api/treasury/expense \
  \(category required + balance guard)"
```

errBody (i) указывает на dedicated endpoint (`POST /api/treasury/expense`), (ii) объясняет требования (category + balance guard).

B2. ✓ Стиль и расположение — после general validation, перед FK lookup и insert. Позиция аналогична `Api.Deals.transitionDeal` reject `confirm_purchase` (DM-7-B-2, строка ~419 в `Api.Deals.hs`).

B3. ✓ Все остальные комбинации работают. Non-regression тесты:
- C4: `OperationalExpense + SourceBankImport` → 200 (representative другого sourceType для OpEx).
- C5: `ClientPrepayment + SourceManual` → 200 (Manual + non-OpEx — generic accepts).
- 22 Treasury B-1/B-2/B-3 integration tests предыдущих фаз — все 22/22 зелёные после моего изменения.
- Регрессии: 0 (538/538 full suite).

### C. Tests — 6 новых cases в существующем describe ✓

Все 6 в существующем `describe "Treasury — DM-7-C manual expenses"` block в `sitka-core/test/ApiSpec.hs`. Использован существующий harness + helpers `categoryJ`, `expenseJ`, `freshCat`, `patchCategoryJ` от TASK-1. Новые helpers `generictxJ` и `seedBalance` добавлены в тот же top let-block (а НЕ в отдельный второй let-block, чтобы они были visible legacy E3/E4 тестам — см. §"Замечено по дороге, скорректировал").

| # | Test | Status |
|---|------|--------|
| C1 | POST /expense rejected when amount > csFree (no insert, balance unchanged) | ✓ |
| C2 | POST /expense passes when amount < csFree, csFree decreases by amount | ✓ |
| C3 | POST /transactions rejects OpEx+Manual with redirect message | ✓ |
| C4 | POST /transactions accepts OpEx+BankImport (non-regression) | ✓ |
| C5 | POST /transactions accepts ClientPrepayment+Manual (non-regression) | ✓ |
| C6 | archived check fires before balance guard (order-pin) | ✓ |

C6 — опциональный из TASK §C6, реализован: проверяет что при одновременном нарушении B9 (archived) и DM-7-C P1 guard (csFree=0, amount=9999), errBody содержит `"category is archived"`, не balance message. Future refactor, переставляющий guard выше archived check, провалит C6 — protective pin.

### D. Объём и форма ✓

| D | Check | Result |
|---|-------|--------|
| D1 | Diff только в файлах из §Файлы | 3 файла: `Api/Treasury.hs`, `Api/Deals.hs`, `test/ApiSpec.hs` ✓ |
| D2 | НЕТ новых миграций | Нет touched в `sitka-core/migrations/*` ✓ |
| D3 | `cabal build -Werror` + `cabal test` + `fourmolu --mode check` зелёные, 0 регрессий | Library + executables + test-suite build clean. Suite 538/538 (532 pre-existing + 6 новых). fourmolu clean ✓ |
| D4 | Pre-commit hooks (gitleaks, EOF, trailing ws, mixed line endings, merge conflicts, import-linter) | Все 13 passed (3 hookа skipped: yaml/toml/json/actionlint — нет соответствующих файлов в diff). Weeder/migration-drift — CI-only ✓ |
| D5 | `git diff --shortstat` от `03ae50d` < 400 строк | `3 files changed, 234 insertions(+), 65 deletions(-)` = 299 строк ✓ |
| D6 | Push в существующую ветку, PR #72 расширяется | Pushed `3c30caf`, PR #72 показывает 2 commits (`03ae50d`, `3c30caf`) ✓ |
| D7 | Один новый commit (или 2 если refactor отделим) | Сделал ОДИН commit. Объяснение: refactor (a) tightly coupled с guard call в createManualExpense — по сути одно атомарное изменение invariant'а. Разбивать на "refactor" + "use" дало бы две CI-зелёные точки на одной ветке без merge value. ✓ |

### E. Out of scope (НЕ делал) ✓

Подтверждаю: не реализовал advisory lock / serializable isolation на guards. Не рефакторил остальные 4 Phase B uses (только обновил импорты на `Treasury.guard*`). Не обновлял `docs/DM-7-cashbox.md`. Не трогал миграции / Domain / Engine / Schema / Api.Server / sitka-services / sitka-web.

## Архитектурное решение — выбран (a)

**Cycle-check** (TASK §"Архитектурное решение"): проверил grep'ом — `Api.Treasury` НЕ импортирует из `Api.Deals` ни до, ни после моего commit'а. Direction was Deals→Treasury (DM-7-B-3 для `toDomainTransaction`/`toDomainReservation`). Безопасно перенести guard в Treasury.

**Что переехало**: оба guard'а (`guardFreeBalanceAfter :: RUB -> RUB -> AppM ()` и `guardFreeBalanceAfterOutgoing :: RUB -> AppM ()`) с doc-комментариями. Definitions буква в букву идентичны — только module + export changed.

**Api.Deals call sites** (4 штуки): обновлены на qualified-call `Treasury.guard*`. Поскольку `Api.Deals` уже импортирует `Api.Treasury qualified as Treasury` (строка 27), новых import lines не понадобилось — только rename вызовов. Diff `Api/Deals.hs`: −60 (удалённые definitions + doc-блоки) / +5 (qualified prefixes на 4 call sites + 1 fix отступа).

**Doc-комментарии** в `Api.Deals` (lines ~1244, ~1247) ссылаются на guard'ы по unqualified names в Haddock. Не правил — Haddock identifier-references не валидируются компилятором, а перепись ссылок на `Treasury.guard*` была бы over-scope (TASK §Out of scope explicitly запрещает refactor existing Phase B uses).

**Обоснование выбора (a) vs (b)**:

1. Architectural cleanliness: guard читает global cashbox state (transactions + reservations). Не depend от Deal-specific logic. Treasury layer естественно владеет cashbox aggregates — это уже там живёт `cashboxSnapshot`, `currentBalance`, `cashflow`. Guards — последовательное расширение этого ownership.
2. Eliminates accidental coupling: при (b) `Api.Treasury.createManualExpense` импортирует из `Api.Deals` — это даёт reverse-direction edge которой раньше не было. Будущий разработчик может прочитать import и предположить что Treasury depends on Deals в более глубоком смысле, чем simple helper reuse.
3. CLAUDE.md "Repeated patterns → helpers, not copy-paste": один helper в правильном месте, не два копии и не reverse-import.
4. Cycle ✓: проверено. Future maintainability +.

(b) и (c) отвергнуты per TL рекомендации в TASK.

## Артефакты

- Branch: `feat/dm7-c-treasury-manual-expenses` (origin tracking up).
- Commits в этом TASK:
  - `3c30caf` — `fix(dm-7-c): free-balance guard for manual expense + reject OpEx+Manual in generic /transactions`
- PR: [#72](https://github.com/upside2002-maker/sitka-office/pull/72) — 2 commits (`03ae50d` TASK-1 + `3c30caf` TASK-2). CI прогон на новый push.
- Изменённые файлы:
  - [`sitka-core/src/Api/Treasury.hs`](../../../../sitka-office/sitka-core/src/Api/Treasury.hs) — +95/-3 (2 новых export, 2 guard definitions, 1 guard call в createManualExpense, 1 reject в createTransaction, import update для `ReservationStatus (..)`).
  - [`sitka-core/src/Api/Deals.hs`](../../../../sitka-office/sitka-core/src/Api/Deals.hs) — +5/-60 (4 call sites → `Treasury.guard*`, удалены 2 local definitions с doc-комментариями).
  - [`sitka-core/test/ApiSpec.hs`](../../../../sitka-office/sitka-core/test/ApiSpec.hs) — +134/-2 (6 новых tests C1–C6, 2 helpers `generictxJ`/`seedBalance` в top let-block, 4 `seedBalance` calls в legacy E3/E4 tests, 1 amount fix для C2 floating-point).

## Замечено по дороге, скорректировал (in-scope adjustments)

Эти правки были вынужденными побочными эффектами введения guard'а; все в файлах из §Файлы (`sitka-core/test/ApiSpec.hs`), не вышли за scope. Перечисляю явно для аудита.

1. **Helpers `generictxJ` + `seedBalance` подняты в top let-block describe-блока**, а не положены в отдельный второй let рядом с C1-C6. Причина: legacy E3/E4 тесты, которым теперь нужен seedBalance (см. п. 2), идут в файле раньше C1-C6. Let-binding visibility в do-блоке монотонна по позиции — поздний let не виден ранним it'ам. Unified top let-block — единственный способ дать helpers всем 28 тестам describe'а без дублирования.

2. **E3 / E4.d / E4.e / E4.h из TASK-1 теперь начинаются с `seedBalance N`**. Без этого guard блочит — test DB создаётся через Persistent `migrateAll`, который НЕ запускает SQL миграцию `0010_treasury_seed.sql` где `OwnerDeposit 5000 RUB` сидится. Дефолтный csFree = 0, любая попытка expense > 0 → 400 от guard'а. seedBalance заранее вкладывает положительный баланс через generic `POST /transactions` с `owner_deposit` (incoming, поэтому не тригерит мой новый OpEx+Manual reject). Это подтверждает контракт "guard срабатывает корректно когда csFree недостаточно", а не отрицает его. **Не считаю это регрессией** — это adaptation tests к новому invariant'у, как и положено при добавлении preconditions.

3. **E3 amount изменён `12345.67` → `12345.5`** (3 occurrences). Причина: `12345.67` не имеет точного представления в Double (`12345.669999999998…`); subtraction `baseTotal - newTotal` через JSON↔Scientific↔Double теряет precision на ~2e-13. После seedBalance (см. п. 2) сравнение `(50000 - 37654.33) === 12345.67` falses через float drift. `12345.5` round-trips точно (0.5 = 2^-1 — exact в IEEE 754). Тест по-прежнему non-round (не круглая тысяча), но Double-clean.

4. **C2 amount тоже `1234.5`** (не `1234.56`) по той же причине — выбрал заранее, не пришлось фиксить пост-фактум.

## Замечено по дороге, не правил

- В `Api.Deals.hs` doc-комментарии guards (которые я удалил) ссылались на сами себя через unqualified Haddock-references (`'guardFreeBalanceAfterOutgoing'`, `'guardFreeBalanceAfter'`) в комментариях `confirmPurchase` (строка ~1244, 1247). После моего рефактора эти ссылки указывают на функции, которые теперь живут в `Api.Treasury`. Haddock build, скорее всего, разрешит их через имя в любом случае, но семантически правильно было бы `'Treasury.guardFreeBalanceAfterOutgoing'`. Не правил — TASK §"Out of scope" запрещает refactor existing Phase B uses, и Haddock identifier-resolution всё равно не валидируется CI gate'ом (CI lanes: fourmolu, weeder, import-linter, drift-check, haskell-test, python-test, frontend-typecheck — нет haddock-build). Если TL хочет почистить — отдельный 5-минутный doc-PR.
- `docs/DM-7-cashbox.md` секция "Инварианты для Phase B" (таблица "free_balance ≥ 0 после insert outgoing") теперь покрывает и Phase C handler `createManualExpense`. Документ прямо это не говорит. TL §Не трогать explicitly запрещает править docs — упоминаю для doc-PR (TASK §Out of scope §3 уже планирует TL doc-PR после merge).
- `cabal test` в начале сессии не запускался: brew postgres был остановлен (`brew services list` показал `postgresql@16 none`). Поднял `brew services start postgresql@16`, потом обнаружил что `sitka_test` была создана от пользователя `ilya`, а тесты подключаются как `sitka` — `setupPool` падал на `ALTER TABLE deal DROP COLUMN actual_*` с `must be owner of table deal`. Решение: `DROP DATABASE sitka_test` от ilya, `CREATE DATABASE sitka_test OWNER sitka`. После этого test suite зашёл чисто. Это локальное env issue, не код проекта; не оформляю отдельным TASK, но фиксирую сюда чтобы следующий Worker, столкнувшийся с тем же, не тратил время. Возможно кандидат для `Makefile` target `db-test-reset`, но over-scope.

## Конфликты / открытые вопросы

Нет открытых блокеров. CI должен прогнать зелёным — fourmolu / weeder / import-linter / drift-check / haskell-test / python-test / frontend-typecheck. Migration-drift зелёный (миграции не тронуты).

Reviewer round per TASK §Reviewer: **не запрашивается**. TL human review достаточен — изменения локализованы (1 guard call + 1 reject + 6 тестов + чистый refactor), оба P1 finding'а явно покрыты тестами C1/C2/C3, Codex'у нечего проверять второй раз.

## Следующий шаг

TL: финальное ревью PR #72 (теперь 2 коммита). После accept TASK-2 + merge:
- TASK-1 (Status: review) тоже автоматически закрывается через merge PR #72.
- Doc-PR от TL для `docs/DM-7-cashbox.md` (см. §Замечено по дороге выше).
- Frontend Phase C task: «Прочие расходы» таб + разбивка outgoing по `kind` в дашборде (упомянут в TASK-1 как next step).

Worker роль закрыта.
