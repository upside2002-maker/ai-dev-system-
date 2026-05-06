# HANDOFF v1 — DM-7-C csTotalSpent backend prereq (Worker → TL, REVIEW)

- Date: 2026-04-30 16:30
- From: Claude Worker, branch `feat/dm7-c-cstotalspent-backend`
- To: Claude Tech Lead (sitka-office)
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: [`project-overlays/sitka-office/TASKS/2026-04-30-dm7-c-cstotalspent-backend.md`](../TASKS/2026-04-30-dm7-c-cstotalspent-backend.md)
- Status: closed

## TL;DR

PR [#76](https://github.com/upside2002-maker/sitka-office/pull/76) — `feat(dm-7-c): add csTotalSpent to CashboxSnapshot for Variant B widget prereq`. 3 файла, **46 insertions** (под 80-line cap). cabal **539/539** зелёные (538 baseline + 1 новый E6), `cabal build -Werror` clean, fourmolu clean, pre-commit clean. Pre-req подтверждён (master = `788f6b0` post-#74 + #75). Status TASK: `in-progress` → `review`.

## Acceptance check (TASK §A–D)

### A. Engine update ✓

| A | Check | Result |
|---|-------|--------|
| A1 | `csTotalSpent :: RUB` в `CashboxSnapshot`, после `csExpectedMargin`, до `csBackfillPending` | ✓ Точная позиция per spec; 7 полей в record. |
| A2 | `cashboxSnapshot` builder включает `totalSpent = negateRub (sumAmounts (filter (amountIs (< 0)) txs))` | ✓ Локальный `let`-binding рядом с `total / reserved / free`. Финальный record собирает `csTotalSpent = totalSpent`. |
| A3 | Haddock-комментарий с описанием `csTotalSpent` | ✓ 5 строк после `csExpectedMargin`-блока, mirrors стиль соседей. Указано: формула, scope, sign convention, UI label. |
| A4 | Никаких новых helpers / exports | ✓ Reuse `negateRub / sumAmounts / amountIs`. `CashboxSnapshot (..)` re-export tnh же. |

### B. TreasurySpec literals ✓

| B | Check | Result |
|---|-------|--------|
| B1 | 9 explicit `CashboxSnapshot {...}` literals расширены `csTotalSpent = <expected>` | ✓ Все 9 фикстур на строках 380, 398, 423, 443, 462, 488, 514, 532, 548 (pre-edit) обновлены. Expected values вручную посчитаны из inputs:<br>• 7 фикстур: `RUB 0` (только positive incoming tx).<br>• Completed-deal fixture: `RUB 62300` (55000 PurchaseUS + 7300 ShippingExpense).<br>• Two-deal fixture: `RUB 80000` (70000 PurchaseUS + 10000 Shipping deal #51). |
| B2 | Property test (lines ~566–580) — НЕ trogal | ✓ Использует `csTotalBalance snap1 === expected` + `csTotalBalance snap1 === csTotalBalance snap2` — single field assertions, не enumeration. Новое поле автоматически покрыто `Eq CashboxSnapshot` derivation, проп тест перекомпилирован и зелёный (`+++ OK, passed 100 tests; 148 discarded`). |
| B3 | Опциональный property test на инвариант `csTotalSpent ≥ 0` | Не добавлял (TASK §B3 "не обязан"). Инвариант trivial-derived из `negate (sum negatives)` ⇒ всегда ≥ 0; добавление property test ради этого был бы make-work. |
| B4 | Регрессии 0 в existing 538 tests | ✓ `cabal test` 539/539 зелёные (538 baseline + 1 новый E6). |

### C. ApiSpec E6 ✓

| C | Check | Result |
|---|-------|--------|
| C1 | Новый test в `Treasury — DM-7-C manual expenses` после E5 | ✓ `it "E6: csTotalSpent reflects sum of outgoing transactions on the cashbox snapshot"`. Использует existing helpers `seedBalance / freshCat / expenseJ / jf / postJ / getJ`, ровно как остальные DM-7-C cases. |
| C2 | Pin'ы (a) outgoing contribute, (b) sign convention round-trip, (c) wire shape `Double` | ✓ Все три явно покрыты:<br>• `mapM_` 3 expenses → assertion `csTotalSpent == 15000` (5000 + 7000 + 3000) — outgoing contribute.<br>• Backend handler signs `cmeAmount` to negative; engine re-negates summed negatives back в positive: assert на 15000 (positive), не на -15000.<br>• `jf snap "csTotalSpent" \`shouldBe\` Just (15000.0 :: Double)` — wire carries как JSON Double. |
| C3 | Owner deposit НЕ контаминирует csTotalSpent | ✓ После `seedBalance 100000` (positive incoming через generic `/transactions`) до создания expenses — explicit assertion `jf baseSnap "csTotalSpent" \`shouldBe\` Just (0.0 :: Double)`. Это пинит filter `amountIs (< 0)` корректно отбрасывает positive incoming. |

### D. Объём и форма ✓

| D | Check | Result |
|---|-------|--------|
| D1 | Diff в файлах из §Файлы | ✓ 3 modify (Engine.Treasury, TreasurySpec, ApiSpec). |
| D2 | НЕТ миграций / новых helpers | ✓ |
| D3 | `cabal build -Werror` + `cabal test` + `fourmolu --mode check` зелёные, 0 регрессий | ✓ 539/539 cabal test, build/format clean. |
| D4 | Pre-commit hooks clean | ✓ gitleaks / EOF / trailing-ws / mixed-line-endings / merge-conflicts / import-linter — все Passed. |
| D5 | `git diff --shortstat` < 80 | ✓ **46 insertions(+)**. Breakdown: Engine.Treasury +13 (record field +1, builder +5, Haddock +6, white-space +1); TreasurySpec +10 (9 fixture lines + 1 для completed-deal комментарий); ApiSpec +23 (новый E6 case + describe-comment). |
| D6 | Один PR с правильным заголовком | ✓ #76. |

### E. Out of scope ✓

Не trogal: frontend (TS type / vitest mocks / widget cell renderer), `csExpectedMargin` (остался как был), per-period scope, per-category breakdown, `CashflowReport`, миграции, `Domain/*`, `Db.Schema`, `Api/Treasury` handler, `docs/DM-7-cashbox.md`, `Api/Server.hs`.

## Pre-req verification

```
$ git fetch origin && git log origin/master --oneline -3
788f6b0 fix(dm-7-c): unified deal financial block + cashbox live refresh + shipping-expense status gating (#75)
25b7fb4 feat(dm-7-c): frontend UI tab "Прочие расходы" + manual expense form + category CRUD (#74)
51fd8ef docs(dm-7): sync DM-7-C Core closure (PR #72) into design doc (#73)
```

✓ Master на `788f6b0` post-#74-#75 HEAD per TASK requirement. Безопасно branch'иться от свежего origin/master.

## Замечено по дороге, не правил

Нет drive-by замечаний. Изменение строго локальное (1 поле + 9 fixture updates + 1 integration test); никаких неожиданных архитектурных вопросов не всплыло.

## Конфликты / открытые вопросы

Нет.

## Артефакты

- Branch: `feat/dm7-c-cstotalspent-backend` (от `origin/master = 788f6b0`).
- Commit: `b9a06a4` — `feat(dm-7-c): add csTotalSpent to CashboxSnapshot for Variant B widget prereq`.
- PR: [#76](https://github.com/upside2002-maker/sitka-office/pull/76).
- Файлы (modified):
  - `sitka-core/src/Engine/Treasury.hs` — `+13` (field + builder + Haddock).
  - `sitka-core/test/TreasurySpec.hs` — `+10` (9 fixture-line additions + 1 new comment for completed-deal).
  - `sitka-core/test/ApiSpec.hs` — `+23` (new E6 integration test + describe-section comment).

## Следующий шаг

TL: ревью PR #76. CI снова red от GitHub Actions billing block (по информации из этой сессии — issue не решён); local pass = фактический gate. После accept + merge → T3+T4 frontend TASK (TS type extension + UI cell renderer + 6 vitest mocks) разблокирован.

Worker роль закрыта.
