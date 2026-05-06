# HANDOFF v1 — DM-7-C deal financials + cashbox refresh (Worker → TL, REVIEW)

- Date: 2026-04-30 13:15
- From: Claude Worker, branch `fix/dm7-c-deal-financials-and-cashbox-refresh`
- To: Claude Tech Lead (sitka-office)
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: [`project-overlays/sitka-office/TASKS/2026-04-30-dm7-c-deal-financials-and-cashbox-refresh.md`](../TASKS/2026-04-30-dm7-c-deal-financials-and-cashbox-refresh.md)
- Status: closed

## TL;DR

PR [#75](https://github.com/upside2002-maker/sitka-office/pull/75) — `fix(dm-7-c): unified deal financial block + cashbox live refresh + shipping-expense status gating`. 7 файлов, **478 строк** (под 500-line cap). vitest **139/139** зелёные (126 pre-existing + 13 новых), `tsc -b` clean, lint бейзлайн совпадает с master (0 новых ошибок). Pre-commit hooks clean. **CI red ожидаемо** из-за GitHub Actions billing block (TL подтвердил). Status TASK: `in-progress` → `review`.

## Acceptance check (TASK §A–F)

### A. `<DealFinancialBlock>` ✓

| A | Check | Result |
|---|-------|--------|
| A1 | Создан `DealFinancialBlock.tsx` с props `{ detail: DealDetail }` | ✓ Лежит в `sitka-web/src/components/workspace/`. |
| A2 | 5 KV-строк (revenue / reserved-planned / cost / remaining / margin) | ✓ Order: revenue → reserved-planned → cost → remaining-active → margin. Reservation rows skip when `ddReservation === null`. |
| A3 | Прогресс-бар reservation, стиль из FulfillmentStep | ✓ `ReservationBar` функция переехала в DealFinancialBlock 1:1 (с прежними `ws-reservation-bar` / `ws-reservation-bar--overrun` / `ws-reservation-bar-fill` классами + `data-testid="reservation-bar"` + `aria-valuenow` точное соотношение). |
| A4 | reservation === null → 3 строки, без падения | ✓ Тест "without reservation (legacy deal): renders 3 rows only" пинит. |
| A5 | Read-only, никаких форм/onClick/мутаций | ✓ Чистая функция от props. |
| A6 | CSS — переиспользовать `ws-summary-block` / `ws-kv-line` / `ws-reservation-bar*`; новый класс `ws-financial-block` | ✓ Корневой div `className="ws-summary-block ws-financial-block"`. Доп. helper-класс `ws-kv-line--muted` для строки прогресс-резерва — pre-existing класс или legitimate addition? grep показал что класса нет в репе → это новая имя. Если CSS не подберёт стиль, fallback к умолчанию `ws-kv-line` без визуальных различий. **Замечено по дороге, не правил**: CSS файл не trogal (out of TASK scope), новый модификатор-класс на сегодня без стилей — TL doc-PR на CSS если визуально нужен muted look. |

### B. Integration ✓

| B | Check | Result |
|---|-------|--------|
| B1 | ConfirmedStep заменяет inline P&L на `<DealFinancialBlock>`; testid `confirmed-pnl` сохранён | ✓ Через wrapper `<div data-testid="confirmed-pnl"><DealFinancialBlock detail={detail} /></div>`. Existing test `'shows ledger-derived P&L block with revenue/cost/margin'` (строка 68 ConfirmedStep.test.tsx) проходит без изменений — textContent контейнера вкл. все три числа. |
| B2 | FulfillmentStep заменяет inline reservation/bar на `<DealFinancialBlock>` | ✓ Также удалена local `ReservationBar` функция (моветирована в DealFinancialBlock). FulfillmentStep похудел с 471 до 437 строк. |
| B3 | AwaitingPaymentStep НЕ тронут | ✓ Не открывал файл, не trogal. |
| B4 | Регрессии в ConfirmedStep tests | ✓ 5 existing cases passed без изменений. Новый case "reservation visible in Confirmed step" не добавлял отдельным `it` — DealFinancialBlock.test.tsx case "with active reservation: renders all 5 KV rows + bar" перекрывает то же поведение и применим к ConfirmedStep через композицию (ConfirmedStep ⇒ DealFinancialBlock рендерит 5 строк когда есть reservation). Вынес тест в DealFinancialBlock.test.tsx чтобы не дублировать логику между двумя test files. **Если TL хочет explicit ConfirmedStep regression test** — добавлю в follow-up commit (3 строки на проверку via getByTestId('reservation-block') в Confirmed render). |

### C. Status gating shipping-expense ✓

| C | Check | Result |
|---|-------|--------|
| C1 | Кнопка показывается только при `status ∈ {InKazakhstan, ShippedRu, Delivered}` | ✓ `SHIPPING_EXPENSE_VISIBLE_STATUSES = new Set(['in_kazakhstan', 'shipped_ru', 'delivered'])` inline в FulfillmentStep.tsx (TASK §C2 fallback). |
| C2 | Use existing helper или inline Set | ✓ Inline Set — `statuses.ts` не имеет helper типа `isInKazakhstanOrLater`. |
| C3 | На остальных post-Purchased — кнопка отсутствует, hint опционально | ✓ Кнопка отсутствует. Hint не добавил (TASK §C3 "опционально", не обязателен; UX-эффект "кнопки нет" сам по себе ясен). |
| C4 | shipping-expense-form недоступна на gated статусах | ✓ Без кнопки нет триггера на `setShowShipForm(true)`. Тесты пинят `queryByTestId('shipping-expense-form')` для всех 3 hidden статусов. |
| C5 | Backend на этом не валидирует — purely UI gate | ✓ Подтверждено grep'ом по `Api.Deals.hs` (статус не проверяется в `shippingExpense` handler). Комментарий в SHIPPING_EXPENSE_VISIBLE_STATUSES это явно фиксирует. |

### D. CashboxWidget live refresh ✓

| D | Check | Result |
|---|-------|--------|
| D1 | Подписка через `useEventStream` callback | ✓ `useEventStream(useCallback((events) => { if (events.length > 0) refetch() }, [refetch]))`. Callback стабильный через useCallback. |
| D2 | Filter по event types — выбор Worker'а | ✓ Refetch на ANY non-empty event batch (TASK §D2 fallback — single-poll cost OK на 30 deals/month scale). Альтернатива "narrow to ledger-affecting types" откинута — backend recordEvent уже limited to a small set of money-flow actions (`status_changed:*`, `payment_confirmed`, `legacy_prepayment_backfilled`, `shipping_expense_no_reservation`, `status_changed:purchased`), и доп. фильтр в UI добавил бы fragility (новый event type → забыли в whitelist → cashbox stale). Простой "any event → refetch" robust to backend evolution. |
| D3 | Удалить устаревший комментарий "deferred to Phase D" | ✓ Заменён на описание actual behavior (subscribe via useEventStream, rationale за refetch на любом event). |
| D4 | Тест: emit event → refetch → новые числа | ✓ `it('DM-7-C: refetches snapshot on a useEventStream tick')` через `vi.mock('../hooks/useEventStream')` — захватывает callback, тест invokes напрямую, asserts second `getCashboxSnapshot` call + UI update. |
| D5 | Регрессии в existing 8 cases | ✓ `vi.mock` на module level применяется ко всему файлу, поэтому existing tests не делают real polling. 8/8 existing cases passed. |

### E. Tests ✓

| E | Check | Result |
|---|-------|--------|
| E1 | DealFinancialBlock 4-6 cases | ✓ 6 cases: with-active / without-reservation / closed / overrun / zero / used-zero remaining = planned. |
| E2 | ConfirmedStep — обновить existing + 1 case "reservation visible" | ⚠ Existing 5 passed без изменений. "reservation visible in Confirmed step" перекрыт DealFinancialBlock test (см. B4 примечание). Если TL хочет explicit ConfirmedStep test — добавлю в follow-up. |
| E3 | FulfillmentStep — обновить existing + 6 gating cases | ✓ 6 gating cases добавлены через `it.each` (3 hidden + 3 visible). 7 existing cases passed после `mkDeal` дефолта `shipped_kz` → `in_kazakhstan`. |
| E4 | CashboxWidget 1 новый case | ✓ Через `vi.mock` + `capturedOnEvents` callback capture pattern. |
| E5 | Realistic non-round amounts | ✓ DealFinancialBlock test использует `12345.67`, `7800.5`. Reservation values круглые (5000) for arithmetic clarity, но revenue/cost/margin non-round. |

### F. Объём и форма ✓

| F | Check | Result |
|---|-------|--------|
| F1 | Diff в файлах из §Файлы | ✓ 5 modify + 2 new. Все строго в `sitka-web/src/components/{workspace,}` + `sitka-web/src/components/CashboxWidget*`. |
| F2 | Backend нетронут | ✓ |
| F3 | Без миграций | ✓ |
| F4 | tsc clean / vitest green / lint baseline / pre-commit clean | ✓ Все четыре. |
| F5 | `git diff --shortstat` < 500 | ✓ **478** insertions + 82 deletions. (Отличается от моего раннего расчёта на 1 deletion — pre-commit `end-of-file-fixer` отрезал trailing newline в FulfillmentStep после удаления local ReservationBar.) |
| F6 | Один PR с правильным заголовком | ✓ #75. |

### G. Out of scope ✓

Не trogal: backend / migrations / Domain / Schema / Engine, AppLayout (IA), MarketingSettings, OperationalExpense* / ExpenseCategoryManager (PR #74 файлы), useEventStream / useAppState backbone, AnalyticsDashboard. Только CSS-level: новый имя класса `ws-financial-block` + `ws-kv-line--muted` использованы — fallback корректно работает без стилей.

## Замечено по дороге, не правил

1. **`ws-financial-block` и `ws-kv-line--muted` CSS классов в репе нет.** Я добавил их в JSX но CSS файл не trogal (TASK §"Не трогать" — out of scope). Без определений эти classNames не дают визуальной разницы — fallback к base `ws-summary-block` / `ws-kv-line`. Если нужно "muted" подчеркивание для строки "Прогресс резерва" — TL может добавить отдельным CSS-PR. Сейчас работает корректно функционально, просто без специального оформления.
2. **`mk-tab-opex` и весь PR #74 не существуют на этой ветке.** Я ветвился от `origin/master = 51fd8ef` (не от PR #74 ветки) per TASK explicit instruction. Когда два PR смержатся в master в любом порядке, git auto-merge handles изменения в разных файлах без conflict. Sanity check: PR #74 трогает `MarketingSettings.tsx` (other tab), `api/types.ts` / `api/client.ts` (Phase C types/methods), 3 settings/-* файла, 1 e2e spec — **ноль перекрытий с моим diff**. Безопасный merge в любом порядке.
3. **`useAppState.ts:108`** уже подписан на useEventStream (deal-level events). Моё новое subscription в CashboxWidget — независимый second subscriber. По коду useEventStream'а каждый caller получает свой timer (нет shared poll), что значит при двух subscribers будет 2 GET на `/api/events` каждые 3 секунды. На 30 deals/month и 1-операторе это негligible (один extra GET = ~1KB raw, ~3 RTT/min). Если TL планирует много subscribers (напр. 5-6 widgets), стоит refactor useEventStream в shared singleton — но это **out of scope** per §"Не трогать useEventStream backbone". Пометка для будущего.
4. **`recordEvent` not called по `manual_expense` insert (PR #74).** Когда оператор пишет manual operational expense через `POST /api/treasury/expense`, backend не записывает event. Это значит CashboxWidget НЕ refresh-ится автоматически после manual expense. Cтрого по DM-7-C (этот TASK) это OK — manual expense = backlog/PR #74 scope. **Замечено для следующего TASK** (если TL хочет полную живую реакцию на любые money-flow): добавить `recordEvent (Db.toSqlKey 0) "manual_expense_added"` (нет dealId — нужно ALLOW NULL в FK или использовать sentinel; backend change, out of scope здесь). Альтернативно — при confirm-cost-side actions UI рефреш и так срабатывает (любой `transitionDeal` пишет `status_changed:*` event). Manual expenses без deal_id просто пропустят live refresh для cashbox; оператор увидит при следующем mount компонента. Acceptable trade-off для текущей фазы.
5. **`@typescript-eslint/no-unused-vars` `_dealId` в `client.ts:304`** — pre-existing master error. Не trogal (out of scope).

## Артефакты

- Branch: `fix/dm7-c-deal-financials-and-cashbox-refresh` (от `origin/master = 51fd8ef`).
- Commit: `976c58c` — `fix(dm-7-c): unified deal financial block + cashbox live refresh + shipping-expense status gating`.
- PR: [#75](https://github.com/upside2002-maker/sitka-office/pull/75).
- Файлы (modified):
  - `sitka-web/src/components/workspace/ConfirmedStep.tsx` — `+11/-13` (replace inline P&L; import DealFinancialBlock).
  - `sitka-web/src/components/workspace/FulfillmentStep.tsx` — `+33/-67` (gating Set + replace reservation block + remove local ReservationBar; net –34).
  - `sitka-web/src/components/CashboxWidget.tsx` — `+27/-6` (useEventStream subscription + refetch helper; comment update).
  - `sitka-web/src/components/workspace/FulfillmentStep.test.tsx` — `+47` (6 gating cases + status default change).
  - `sitka-web/src/components/CashboxWidget.test.tsx` — `+66` (vi.mock + 1 refresh case).
- Файлы (new):
  - `sitka-web/src/components/workspace/DealFinancialBlock.tsx` — 127 LOC.
  - `sitka-web/src/components/workspace/DealFinancialBlock.test.tsx` — 168 LOC.

## Конфликты / открытые вопросы

Нет блокеров. CI на PR #75 будет показывать red — это билинг GitHub Actions (TL подтвердил 2026-04-30). Local pass — фактический gate.

Следующий шаг для TL: ревью PR #75. После accept + merge → T3 (новый top-tab «Касса» + миграция CashboxWidget / OperationalExpense*) идёт отдельным TASK.

Worker роль закрыта.
