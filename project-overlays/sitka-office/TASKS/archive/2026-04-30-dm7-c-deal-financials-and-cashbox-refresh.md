# 2026-04-30-dm7-c-deal-financials-and-cashbox-refresh

- ID: `2026-04-30-dm7-c-deal-financials-and-cashbox-refresh`
- Created by: Claude Tech Lead session, 2026-04-30 (post operator UX feedback на PR #74 manual smoke)
- Worker model: Claude Code
- Worker branch: `fix/dm7-c-deal-financials-and-cashbox-refresh` (новая, от свежего `origin/master = 51fd8ef`; **независимо** от PR #74 ветки `feat/dm7-c-frontend-ui-tab`)
- Layer: frontend
- Risk tier: C (UI / sitka-web)
- Status: done (merged 2026-05-01 06:24Z после rebase на master, sha `788f6b0`)

## Задача

Закрыть две связки UX/integration проблем, найденных оператором при manual smoke на PR #74:

**T1 (UX — финансовый блок в карточке сделки + правильный этап для "+ Расход"):**
- Фактическое финансовое состояние сделки (получено / резерв / потрачено / остаток / маржа) сейчас разбросано по разным workspace-шагам и **не показано в Confirmed step** (после `confirm-payment` оператор ввёл резерв, но в UI его не видно).
- Кнопка «+ Расход на доставку» сейчас доступна на ВСЕХ post-Purchased статусах (включая `Purchased`, `AtUsWarehouse`, `ShippedKz`), что нелогично по бизнесу: фактический расход возникает только когда товар **прибыл в Казахстан** (status `InKazakhstan` и далее).

**T2 (integration bug — cashbox не реагирует на действия):**
- `CashboxWidget` сейчас явно с комментарием «refreshes once on mount, live updates deferred to Phase D» (`CashboxWidget.tsx:24-25`). После любого action (`confirm-payment` / `confirm-purchase` / `shipping-expense` / `manual-expense`) widget показывает stale данные до hard reload. Backend пишет всё корректно (ledger transaction + reservation update + snapshot пересчитывается на каждый запрос), просто widget не subscribes к event stream. Infrastructure для live updates **есть** (`useEventStream` polls `/api/events?since=` каждые 3s в `useAppState`).

Один TASK, один PR, ~150-220 LOC product + ~80-120 LOC tests. **БЕЗ backend changes.**

## Файлы

- `modify:`
  - `sitka-web/src/components/workspace/ConfirmedStep.tsx` — заменить inline P&L render (строки ~128-142) на `<DealFinancialBlock detail={detail} />`. Это автоматически добавит reservation block (закроет UX дыру #2 из feedback).
  - `sitka-web/src/components/workspace/FulfillmentStep.tsx` — (a) заменить inline reservation/cost render на `<DealFinancialBlock detail={detail} />`; (b) gating кнопки «+ Расход на доставку» (testid `shipping-expense-button`) по `status >= InKazakhstan` — см. секцию C ниже.
  - `sitka-web/src/components/CashboxWidget.tsx` — подписаться на `useEventStream`, refetch `getCashboxSnapshot()` на relevant events. Удалить deferred-to-Phase-D коммент (или заменить на actual behaviour).
  - existing tests: `ConfirmedStep.test.tsx`, `FulfillmentStep.test.tsx`, `CashboxWidget.test.tsx` — обновить если новая структура поломала assertions (вероятно нужно — DealFinancialBlock меняет DOM).
- `new:`
  - `sitka-web/src/components/workspace/DealFinancialBlock.tsx` — новый компонент, 5 KV-строк по `DealDetail` + опциональный reservation block с прогресс-баром.
  - `sitka-web/src/components/workspace/DealFinancialBlock.test.tsx` — vitest unit tests (render with reservation / без / completed deal / overrun).
- `delete:` —
- `migrations:` НЕТ.

## Не трогать

- `sitka-core/*` — backend готов, изменений не требуется.
- `sitka-services/*` — out of scope.
- `sitka-web/src/components/AppLayout.tsx` — IA refactor (новый top-tab «Касса») = T3+T4 в следующем TASK, не здесь.
- `sitka-web/src/components/settings/MarketingSettings.tsx`, `OperationalExpense*.tsx`, `ExpenseCategoryManager.tsx` — это код PR #74, переезжает в «Касса» в T3, **здесь не трогать**.
- `sitka-web/src/hooks/useEventStream.ts`, `useAppState.ts` — не трогать (используем существующий `onEvents` callback).
- `sitka-web/src/components/AnalyticsDashboard.tsx` — не трогать (CashboxWidget на дашборде, location не меняется в T1+T2; переезд в «Касса» = T3).
- `docs/`, `.claude/`, overlay в `ai-dev-system/` — нет.

Если по дороге заметишь что-то ещё, требующее правки за пределами scope — **НЕ ПРАВИТЬ молча**. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. `<DealFinancialBlock>` — единый компонент

A1. Создать `sitka-web/src/components/workspace/DealFinancialBlock.tsx` с props:
```typescript
interface DealFinancialBlockProps {
  detail: DealDetail
}
```

A2. Рендерит 5 KV-строк (или 4 если reservation отсутствует — см. A4):
- **«Получено от клиента»** → `formatRub(detail.ddRevenue)`
- **«Зарезервировано на доставку»** → `formatRub(reservation.rrPlannedRub)` если `detail.ddReservation !== null`, иначе skip строку
- **«Потрачено по сделке»** → `formatRub(detail.ddCost)`
- **«Остаток в резерве»** → `formatRub(reservation.rrPlannedRub - reservation.rrUsedRub)` если reservation есть и `rrStatus === 'active'`. На closed/overrun — пропустить или показать `0`. Skip строку если reservation нет.
- **«Текущая маржа»** → `formatRub(detail.ddMargin)`

A3. Опционально — компактный прогресс-бар reservation (`used / planned`), стиль скопировать с существующего `FulfillmentStep` `ws-reservation-bar` (line ~456 в `FulfillmentStep.tsx`). Бар видим только когда reservation active.

A4. Если reservation === null (legacy сделка без B-1 backfill) — компонент рендерит 3 строки (получено / потрачено / маржа). Не падает, не делает sequential null checks.

A5. Read-only. Никаких форм, никаких onClick, никаких mutations.

A6. CSS — переиспользовать существующие классы `ws-summary-block` / `ws-kv-line` / `ws-reservation-bar*`. Новый класс при необходимости — `ws-financial-block`.

### B. Integration в Confirmed + Fulfillment

B1. `ConfirmedStep.tsx`: заменить existing P&L render (line ~128-142, `data-testid="confirmed-pnl"`) на `<DealFinancialBlock detail={detail} />`. testid `confirmed-pnl` оставить (как wrapper или внутри DealFinancialBlock — Worker сам решит для test continuity).

B2. `FulfillmentStep.tsx`: заменить existing inline reservation render (line ~228-244) на `<DealFinancialBlock detail={detail} />`. Подсекция reservation внутри FulfillmentStep была reservation+бар; новый блок включает оба + revenue/cost/margin.

B3. **AwaitingPaymentStep НЕ трогать.** На `awaiting_payment` revenue=0, cost=0, reservation отсутствует — финансовый блок не имеет смысла. Существующая UI остаётся.

B4. Регрессии: `ConfirmedStep.test.tsx` ожидает `confirmed-pnl` block с revenue/cost/margin numbers. Убедиться что после рефакторинга все existing assertions продолжают работать (DealFinancialBlock рендерит те же `formatRub` значения для тех же data-testid'ов — это compat layer).

### C. Status gating «+ Расход на доставку»

C1. В `FulfillmentStep.tsx` кнопка `data-testid="shipping-expense-button"` (line ~257) показывается **только когда `deal.drStatus` ∈ `{InKazakhstan, ShippedRu, Delivered}`**.

C2. Используй `statuses.ts` или эквивалент для проверки membership. Worker найдёт grep'ом `'in_kazakhstan'`/`'shipped_ru'`/`'delivered'` строки в репе. Если есть существующий helper типа `isInKazakhstanOrLater(status)` — использовать; иначе создать inline `Set<DealStatus>` с тремя значениями.

C3. На остальных post-Purchased статусах (`Purchased`, `AtUsWarehouse`, `ShippedKz`) — кнопка **отсутствует**. Hint-сообщение опционально, не обязательно (если делаешь — короткое: «Расход на доставку появится, когда товар прибудет в Казахстан»; стиль тонкий, не CTA).

C4. **`shipping-expense-form` modal на gated статусах должен быть недоступен** — проверка через UI (нет кнопки → форма не открывается). E2E или vitest test pinning для каждого из 3 видимых + 3 скрытых статусов.

C5. Backend ничего не валидирует на этом — `POST /api/deals/:id/shipping-expense` принимает на любом status (см. `Api.Deals.hs`). Это purely UI gating per business logic.

### D. CashboxWidget live refresh

D1. В `CashboxWidget.tsx` подписаться на `useEventStream` через callback. Структура (примерно):
```typescript
import { useEventStream } from '../hooks/useEventStream'

export function CashboxWidget() {
  const [data, setData] = useState<CashboxSnapshot | null>(null)
  // ... existing fetch on mount ...
  useEventStream((events) => {
    if (events.some(e => /* relevant event types */)) {
      api.getCashboxSnapshot().then(setData).catch(() => setError(true))
    }
  })
  // ... rest
}
```

D2. **Relevant event types** — Worker grep'ом проверит какие event types backend пишет (см. `sitka-core/src/Domain/Lead/Event.hs` или эквивалент `recordEvent` в `Api.Deals` / `Api.Treasury`). Минимально:
- любые события связанные с `transaction` (insert)
- любые `deal_*` события на которых меняется reservation или ledger
Если конкретные имена event types не зафиксированы single source — фильтровать **none** (refetch на любое событие; cost — лишний request раз в 3s, который проходит только если есть события). Это приемлемый trade-off для simplicity. Зафиксировать выбор в HANDOFF.

D3. Удалить или обновить коммент `CashboxWidget.tsx:24-25` («Read-only, refreshes once on mount. Live updates via the event stream are deferred to Phase D.»). Заменить на actual behaviour.

D4. Тест: mock `useEventStream` (или создать test-helper для emit) → widget вызывает `getCashboxSnapshot` второй раз → новые числа отрисованы.

D5. Регрессии: existing `CashboxWidget.test.tsx` (8 cases) не сломать. mock-ы api.getCashboxSnapshot могут потребовать adjustment если test helper subscribes to useEventStream — Worker проверит.

### E. Tests

Все тесты — **vitest unit** (Tier C UI, не нужны Playwright e2e — изменения чисто компонентные, без новых routes/forms).

E1. **`DealFinancialBlock.test.tsx`** — 4-6 cases:
- render with active reservation → 5 строк visible.
- render without reservation (legacy deal) → 3 строки visible (revenue/cost/margin).
- render with closed reservation → reservation block либо hidden либо показывает «закрыт».
- render with overrun reservation → bar/pill «перерасход» (если показываем бар).
- ddRevenue=0, ddCost=0 (awaiting/confirmed без оплаты) → корректно (не упасть на 0).

E2. **`ConfirmedStep.test.tsx`** — обновить existing 5-7 cases чтобы pass с новым DealFinancialBlock. Добавить 1 case: «reservation visible in Confirmed step» (regression test для UX feedback #2).

E3. **`FulfillmentStep.test.tsx`** — обновить existing 5+ cases. Добавить **6 cases для status gating**:
- Purchased → нет shipping-expense-button.
- AtUsWarehouse → нет.
- ShippedKz → нет.
- InKazakhstan → есть.
- ShippedRu → есть.
- Delivered → есть.

E4. **`CashboxWidget.test.tsx`** — 1 новый case: emit event через useEventStream mock → widget refetches и обновляет numbers.

E5. **Realistic fixture coverage** — non-round amounts (e.g. `12345.67`, `7800.50`), используется `runIO getCurrentTime` или близкий pattern если нужен.

### F. Объём и форма

F1. Diff только в файлах из §Файлы.
F2. НЕТ backend changes (никаких изменений в `sitka-core/*` / `sitka-services/*`).
F3. НЕТ миграций.
F4. `tsc -b` clean. `npm run test` (vitest) зелёный, ноль регрессий. `npm run lint` (если есть в репе — Worker проверит) clean. Pre-commit hooks clean.
F5. `git diff --shortstat` — менее **500 строк** (200-300 product + 100-200 tests = ~300-500). Если ползёт сильно выше — возврат в TL.
F6. Один PR, заголовок `fix(dm-7-c): unified deal financial block + cashbox live refresh + shipping-expense status gating`.

### G. Out of scope (НЕ делать)

- IA refactor (новый top-tab «Касса») — следующий TASK T3+T4.
- slug hide / auto-gen — T4 (следующий TASK).
- CashboxWidget переезд с дашборда в «Касса» — T3.
- Backend prereq на `trExpenseCategoryId` для widget breakdown — отдельный draft TASK (`2026-04-29-dm7-c-backend-widget-prereq.md`), не активен пока.
- Изменения state machine / endpoints / валидаций — НЕТ, gating чисто UI.
- E2E Playwright spec — Tier C UI, vitest достаточен.

## Контекст

- HEAD master: `51fd8ef` (post PR #71/72/73). PR #74 параллельно открыт, не блокирует этот TASK (разные файлы).
- Operator UX feedback: см. сессионную историю (5 пунктов: IA / reservation visibility / shipping-expense timing / cashbox stale / slug техничка). T1+T2 закрывает пункты 2, 3, 4. T3+T4 закроет 1 и 5.
- State machine (`sitka-core/src/Domain/Deal.hs:38-110`):
  - Post-Purchased chain: `Purchased → AtUsWarehouse → ShippedKz → InKazakhstan → ShippedRu → Delivered → Completed`.
  - «Товар прибыл в Казахстан» = `InKazakhstan` (line 69 — «Arrived in Kazakhstan»).
- DealDetail wire shape (`sitka-web/src/api/types.ts:195-208`): `ddRevenue`, `ddCost`, `ddMargin`, `ddReservation: Reservation | null`. Reservation: `rrPlannedRub`, `rrUsedRub`, `rrStatus: 'active' | 'closed' | 'overrun'`.
- Existing reservation render в FulfillmentStep: `sitka-web/src/components/workspace/FulfillmentStep.tsx:228-244`. Прогресс-бар style — line ~456+.
- Existing P&L render в ConfirmedStep: `ConfirmedStep.tsx:128-142`. testid `confirmed-pnl`.
- CashboxWidget current behaviour: `CashboxWidget.tsx:31-39` — single fetch on mount.
- useEventStream: `sitka-web/src/hooks/useEventStream.ts:9-31` — polls `/api/events?since=` каждые 3s, calls `onEvents([...])`.
- useAppState уже subscribed (`useAppState.ts:108`), но обрабатывает только deal-level events. Виджет subscribes отдельно, не через useAppState.
- `formatRub` helper: `sitka-web/src/constants/formatters.ts`.

## Reviewer

**Не запрашивается.** Tier C frontend, изменения локализованы (3 modify + 1 new + 4 test файла), mirror existing patterns (FulfillmentStep reservation block переезжает в DealFinancialBlock 1:1; CashboxWidget event subscription — стандартный React pattern). TL human review достаточен.

## Worker workflow

1. Прочитать TASK + последние коммиты в worktree (особенно для FulfillmentStep структуры).
2. Сменить Status: open → in-progress.
3. `git fetch origin && git checkout -b fix/dm7-c-deal-financials-and-cashbox-refresh origin/master` (НЕ от PR #74 ветки).
4. Внести правки в порядке:
   - Создать `DealFinancialBlock.tsx` + test.
   - Интегрировать в `ConfirmedStep.tsx` (replace inline P&L block).
   - Интегрировать в `FulfillmentStep.tsx` (replace inline reservation; gating shipping-expense-button по status).
   - Подписать `CashboxWidget.tsx` на useEventStream.
   - Update existing tests (ConfirmedStep, FulfillmentStep, CashboxWidget) для compat с новым DOM.
5. Локально: `npm run typecheck && npm run test && fourmolu-equivalent (если есть)`. Все зелёные. `git diff --shortstat` < 500.
6. Открыть PR в master с заголовком `fix(dm-7-c): unified deal financial block + cashbox live refresh + shipping-expense status gating`.
7. HANDOFF v1 в `HANDOFFS/2026-04-30-claude-worker-to-claude-tl-dm7-c-deal-financials-and-cashbox-refresh.md` с acceptance check A-F + «Замечено по дороге» если есть.
8. Status: in-progress → review.

## Условные возвраты в TL (через HANDOFF, без молчаливых правок)

- `useEventStream` API не позволяет multi-subscriber (если useAppState уже захватил callback exclusively) → стоп, описать. Worker НЕ модифицирует useEventStream — это backbone.
- Status gating требует доступа к `Set<DealStatus>` из shared module которого нет → создать inline в FulfillmentStep, отметить в HANDOFF (это accept'able adjustment).
- Существующие tests в FulfillmentStep активно используют `getByText` / `getByRole` которые сломались на новом DOM → расширить assertions, не сужать. Worker может recompose existing test names.
- Diff > 500 строк → стоп, описать что разрослось (вероятно tests).
- Любая необходимость touch backend / migrations / Domain / Schema — безусловный возврат.
- Если найден ещё один UX баг в процессе работы (например AwaitingPaymentStep тоже хочет финансовый блок) — НЕ implementировать, фиксировать в HANDOFF. TL решит.
