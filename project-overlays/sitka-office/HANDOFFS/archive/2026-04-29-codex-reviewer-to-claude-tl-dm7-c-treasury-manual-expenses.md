# HANDOFF — DM-7-C Reviewer report (Codex Reviewer → Claude TL)

- Date: 2026-04-29
- From: Codex Reviewer (ChatGPT, ad-hoc red-team session, prompt сформулирован Claude TL 2026-04-28)
- To: Claude Tech Lead (sitka-office)
- Agent runtime: ChatGPT
- Model: ChatGPT (Codex review mode)
- Role mode: Reviewer / Red Team
- Артефакт под ревью: PR [#72](https://github.com/upside2002-maker/sitka-office/pull/72) — `feat(dm-7-c): treasury manual expenses CRUD + expense POST handler`
- Связанные:
  - TASK [`2026-04-27-dm7-c-treasury-manual-expenses.md`](../TASKS/2026-04-27-dm7-c-treasury-manual-expenses.md) (TASK-1, Status: review)
  - HANDOFF v2 от Worker: [`2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses-v2.md`](2026-04-28-claude-worker-to-claude-tl-dm7-c-treasury-manual-expenses-v2.md)
- Status: closed (TL прочитал, перевёл findings в action — TASK-2 follow-up)

## Reviewer report (raw, как пришло от Codex)

### ARTIFACT

PR #72 — `feat(dm-7-c): treasury manual expenses CRUD + expense POST handler`. 4 файла, +689/-5. CI 8/8 SUCCESS. Mergeable. 532/532 tests green.

### FINDINGS

**[P1, confidence 0.96] Manual expense write path can overspend reserved or nonexistent cash**
- File: `sitka-core/src/Api/Treasury.hs:411-444`
- `createManualExpense` inserts a negative `OperationalExpense` directly after amount/date/category validation, but unlike `confirmPurchase` and `shippingExpense` it never runs a `guardFreeBalanceAfterOutgoing`-style check. A single POST can therefore push `csFree` below zero (spending another deal's reservation) or even drive `csTotalBalance` negative. That breaks the DM-7 invariant the rest of the cashbox flow is trying to enforce for outgoing writes.

**[P1, confidence 0.94] Generic /treasury/transactions still bypasses Phase C expense invariants**
- File: `sitka-core/src/Api/Treasury.hs:119-173`
- Phase C introduces `/api/treasury/expense` so manual operational costs are categorized, archived-category aware, and skew-checked. But the older `POST /api/treasury/transactions` route still accepts `SourceManual` + `OperationalExpense` and always writes `transactionExpenseCategoryId = Nothing`, with none of the new category/archive/future-date rules. So uncategorized manual expenses can still enter the ledger through the public API, which means the new invariants are not actually enforced globally and Phase D category reporting can be silently poisoned.

### NIT / NOT A PROBLEM

- `Maybe (Maybe UTCTime)` в `UpdateExpenseCategoryReq` — корректно; tri-state omit/null/value реализован честно.
- `txDate <= now + 60s` сам по себе не критический баг. Семантически терпимый skew-buffer, если `txDate` — business date, не strict server timestamp. Главный риск тут не в 60 секундах, а в том что generic /transactions может это правило обойти.

### RECOMMEND

Перед merge:
1. Закрыть generic `/transactions` для `OperationalExpense + SourceManual` (reject, redirect to dedicated endpoint), ИЛИ
2. Заставить generic проходить ТЕ ЖЕ category/archive/skew/balance проверки.
3. Добавить balance/free-balance guard в `createManualExpense`.

## TL вердикты по findings

**Finding #1 (free-balance guard в `createManualExpense`)** → **ПРИНЯТЬ**.

- Severity P1 valid. Это нарушение фундаментального DM-7 инварианта «`free_balance ≥ 0` после insert outgoing» (`docs/DM-7-cashbox.md` секция «Инварианты для Phase B», таблица `free_balance ≥ 0 после insert outgoing | handler | 400`).
- Phase C не отсылал к этому в acceptance — это упущение TL при написании TASK-1, не Worker. Worker корректно следовал TASK буквально.
- Remediation: новый TASK Worker'у на добавление `guardFreeBalanceAfterOutgoing` в `createManualExpense`. Helper уже существует в `Api.Deals.hs:1331-...`, используется 4 раза в Phase B handlers (lines 1080, 1216, 1284, 1395).
- PR #72 НЕ merge до закрытия finding.

**Finding #2 (generic /transactions bypass)** → **ПРИНЯТЬ**.

- Severity P1 valid. Leak в инвариант «manual operational expenses always categorized + balance-guarded».
- Решение по форме: Codex Option (1) — closing generic для конкретной комбинации `OperationalExpense + SourceManual` через `validateOr400`. Прецедент в репо: `Api.Deals.hs:419-421` (DM-7-B-2 reject `confirm_purchase` в generic `transitionDeal`).
- Codex Option (2) — duplicate logic, плохой DRY. Отвергнуто.
- Объединяю в один TASK с Finding #1: та же зона (Api.Treasury.hs), та же ветка `feat/dm7-c-treasury-manual-expenses`, тот же PR #72 расширяется через follow-up commit.

**Не приняли (NIT):** 60s skew tolerance — Codex согласен что не критично. Оставляем как есть.

## Action

1. Этот HANDOFF создан как audit trail (Status: closed по факту прочтения и принятия решения).
2. Создан TASK-2: `TASKS/2026-04-29-dm7-c-balance-guard-and-generic-reject.md`. Worker берёт ту же ветку `feat/dm7-c-treasury-manual-expenses`, добавляет коммит, PR #72 расширяется.
3. OPERATING.md обновлена: TASK-2 в Active, запись в Заметки про Reviewer round closed + decisions.
4. PR #72 НЕ merge до закрытия HANDOFF v3 от Worker по TASK-2.

## Следующий шаг

Worker: прочитать TASK-2 + HANDOFF v2 + этот HANDOFF. Чек-точки в TASK-2 §A-E. Возврат через HANDOFF v3.
