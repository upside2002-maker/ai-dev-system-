# 2026-04-29-dm7-c-frontend-ui-tab

- ID: `2026-04-29-dm7-c-frontend-ui-tab`
- Created by: Claude Tech Lead session, 2026-04-29 (post Phase C Core merge PR #72 + doc-sync PR #73)
- Worker model: Claude Code
- Worker branch: `feat/dm7-c-frontend-ui-tab` (новая ветка от свежего `origin/master = 51fd8ef`)
- Layer: frontend
- Risk tier: C (UI / sitka-web)
- Status: done (merged 2026-05-01 06:13Z, master sha `25b7fb4`)

## Задача

Реализовать Phase C Frontend UI половину DM-7 Cashbox: пятый таб «Прочие расходы» в `MarketingSettings` + форма «+ Расход» + CRUD категорий + API client/types для 4 endpoints из PR #72.

**БЕЗ widget breakdown в CashboxWidget** — это отдельная связка (см. секцию «Out of scope» и backlog в `OPERATING.md`). Backlog требует backend prereq (расширение `TransactionResp.trExpenseCategoryId`), потому что текущий wire shape не несёт FK на category — фронт не может сделать честный join `transactions × categories`. Установлено grep'ом 2026-04-29; Codex Reviewer вход. Без backend prereq разбивка по `kind` была бы либо fake, либо leak в Tier A в этом же TASK.

После accept этого TASK — Phase C Frontend UI частично закрыта (таб + форма + CRUD); widget breakdown идёт после backend prereq.

## Файлы

- `modify:`
  - `sitka-web/src/components/settings/MarketingSettings.tsx` — расширить `Tab` type, добавить tab button + conditional render.
  - `sitka-web/src/api/client.ts` — 4 новых API метода (listCategories / createCategory / updateCategory / createManualExpense).
  - `sitka-web/src/api/types.ts` — wire types: `CategoryResp`, `CreateExpenseCategoryReq`, `UpdateExpenseCategoryReq` (с tri-state `umeArchivedAt`), `CreateManualExpenseReq`, `ExpenseKind`.
- `new:`
  - `sitka-web/src/components/settings/OperationalExpenseManager.tsx` — root компонент 5-го таба (sub-секции «Расходы» + «Категории»).
  - `sitka-web/src/components/settings/OperationalExpenseForm.tsx` — форма «+ Расход» (modal или inline).
  - `sitka-web/src/components/settings/ExpenseCategoryManager.tsx` — CRUD категорий (list + add + edit + archive/unarchive).
  - vitest unit tests для каждого нового компонента (mock api, проверять render + interaction).
  - Playwright e2e spec для нового таба (happy path: navigate → create category → create expense → verify list).
- `delete:` —
- `migrations:` НЕТ.

## Не трогать

- `sitka-core/*` — backend готов в master (PR #72), не трогать ни строки.
- `sitka-services/*` — out of scope.
- `sitka-web/src/components/CashboxWidget.tsx` — widget breakdown это отдельный TASK после backend prereq. **Безусловный возврат в TL** при потребности расширить виджет.
- `sitka-web/src/components/AnalyticsDashboard.tsx` — не трогать.
- Прочие existing managers (`ChannelAccountManager`, `CampaignManager`, `ListingManager`, `SpendEntryForm`, `SpendList`) — образцы паттерна, читать но не править.
- Миграции — нет.
- `docs/`, `.claude/`, overlay в `ai-dev-system/` — нет.

Если по дороге заметишь что-то ещё, требующее правки за пределами scope — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. Tab structure (MarketingSettings.tsx)

A1. Расширить `Tab` type до `'spend' | 'accounts' | 'campaigns' | 'listings' | 'opex'`. Slug `'opex'` на усмотрение Worker'а — допустимо `'misc'` или `'expenses'` если читаемее, главное consistent с label «Прочие расходы».
A2. Default tab остаётся `'spend'` (most frequent task).
A3. Добавить tab button с label `«Прочие расходы»` рядом с существующими 4 кнопками. Стиль — копировать с существующих (cs-class, conditional active).
A4. Conditional render `<OperationalExpenseManager>` когда `tab === 'opex'` (или выбранный slug).
A5. Если новые data loads нужны (categories, expenses) — добавить в `loadAll` ИЛИ отдельным `loadOpex` callback по аналогии с `loadSpend` (уже есть в файле).

### B. OperationalExpenseManager — root компонент 5-го таба

B1. Header «Прочие расходы».
B2. Sub-секция 1: «Расходы» — list latest manual expenses (filter `txType=operational_expense`, limit 50-100), отдаваемых через `api.listTransactions`. Колонки: дата, категория (display_name из join по categoryId), amount, notes. Sortable by date desc.
B3. Кнопка «+ Расход» открывает `<OperationalExpenseForm>`.
B4. Sub-секция 2: «Категории» — `<ExpenseCategoryManager>` (см. D ниже).
B5. Loading state + error banner + refetch on action (стиль копировать с `MarketingSettings.banner`).

**Note:** На текущий момент `TransactionResp` не несёт `expenseCategoryId` (см. §Задача), поэтому колонка «категория» в B2 — это **визуальный пробел или плейсхолдер «—»**, не реальный join. Это явное ограничение этого TASK; backend prereq + widget TASK закроют дисплей категории как часть widget breakdown связки. **Не реализовывать fake mapping**.

### C. OperationalExpenseForm

C1. Modal или inline form (стиль на усмотрение Worker'а — посмотреть как сделан `SpendEntryForm.tsx`).
C2. Поля:
   - `amount: number` (RUB, positive). Client-side: `> 0`, иначе error "amount должен быть > 0".
   - `categoryId: number` (dropdown active categories — `archived_at IS NULL`, отсортированные by displayName). Required.
   - `notes: string` (optional).
   - `txDate: string` (date picker, default = today). Client-side: `<= today + 1 minute` (mirror server-side B7 skew tolerance), иначе error "дата не может быть в будущем".
C3. Submit → `api.createManualExpense({...})` → close form + refetch list.
C4. Errors:
   - 400 (amount/txDate) → in-form error.
   - 404 (categoryId) → banner, refetch categories.
   - 400 (archived category) → banner.
   - Network/500 → generic banner.

### D. ExpenseCategoryManager — CRUD категорий

D1. List active categories (default GET `?archived=false`), sortable by displayName ASC.
D2. Toggle «Показать архивные» → GET `?archived=true`, отображать оба статуса с visual indicator (e.g., greyed-out для archived).
D3. Inline edit `displayName` (click to edit, blur to save) → `PATCH {umeDisplayName: ...}`.
D4. Buttons:
   - Archive (на active row) → `PATCH {umeArchivedAt: <NOW ISO>}`.
   - Unarchive (на archived row) → `PATCH {umeArchivedAt: null}` — **explicit null**, не omit.
D5. Кнопка «+ Категория» → modal с полями:
   - `slug: string` (lowercase a-z 0-9 _, validation client-side).
   - `displayName: string`.
   - `kind: 'salary' | 'ops' | 'logistics' | 'misc'` (dropdown).
   Submit → `api.createExpenseCategory({...})`.
D6. 409 conflict on duplicate slug (включая archived row) → show error в modal с message backend'а («slug already exists: ...»). Hint оператору: для reactivation — найти archived row в «Показать архивные» + кнопка Unarchive.

### E. API client & types

E1. `sitka-web/src/api/types.ts` — добавить:
```typescript
export type ExpenseKind = 'salary' | 'ops' | 'logistics' | 'misc'

export type CategoryResp = {
  ecId: number
  ecSlug: string
  ecDisplayName: string
  ecKind: ExpenseKind
  ecArchivedAt: string | null
  ecCreatedAt: string
}

export type CreateExpenseCategoryReq = {
  ecrSlug: string
  ecrDisplayName: string
  ecrKind: ExpenseKind
}

export type UpdateExpenseCategoryReq = {
  umeDisplayName?: string  // omit = keep
  // umeArchivedAt: tri-state. См. секцию E3 ниже про сериализацию.
}

export type CreateManualExpenseReq = {
  cmeAmount: number
  cmeCategoryId: number
  cmeNotes?: string
  cmeTxDate: string  // ISO UTC
}
```

E2. `sitka-web/src/api/client.ts` — 4 метода:
- `listExpenseCategories(opts: { archived?: boolean }): Promise<CategoryResp[]>`
- `createExpenseCategory(req: CreateExpenseCategoryReq): Promise<CategoryResp>`
- `updateExpenseCategory(id: number, req: UpdateExpenseCategoryReq): Promise<CategoryResp>`
- `createManualExpense(req: CreateManualExpenseReq): Promise<Transaction>` — возвращает existing `Transaction` type из `types.ts`

E3. **Tri-state PATCH сериализация в TS** (новый паттерн в репе для frontend):

TypeScript native `Partial<{...}>` не даёт easy distinguish между «omit field» и «field = null». Backend ожидает:
- omit `umeArchivedAt` ключ → keep existing
- ключ = `null` → unarchive (set NULL)
- ключ = `<ISO UTC string>` → archive

Worker выбирает ОДИН подход:
- (i) **Two helper методы:** `archiveCategory(id)` (отправляет `{umeArchivedAt: NOW}`) и `unarchiveCategory(id)` (отправляет `{umeArchivedAt: null}`). `updateCategory(id, {umeDisplayName})` всегда omit-ит archivedAt. Чисто, но три метода API client вместо одного PATCH-метода.
- (ii) **Single `updateExpenseCategory(id, req)` + builder pattern:** request type определён как union `{omitArchivedAt: true} | {umeArchivedAt: string | null}` или подобный — Worker sees что хочет операция, формирует JSON через `JSON.stringify` с правильной шапкой.

Worker зафиксирует выбор в HANDOFF. **TL рекомендация: (i)** — три метода соответствует ровно трём admin actions (rename / archive / unarchive), не нужно scaffold tri-state в TS типах.

### F. Tests

F1. **Vitest unit** для каждого нового компонента:
- `OperationalExpenseManager`: render с empty list, render с данными, click «+ Расход» открывает форму.
- `OperationalExpenseForm`: validation amount=0 / amount<0 / txDate=future / submit happy path → `api.createManualExpense` called once. Mock `api`.
- `ExpenseCategoryManager`: render active list, toggle archived, edit displayName triggers PATCH, archive button triggers PATCH с timestamp, unarchive button triggers PATCH с null, 409 conflict displays error.

F2. **Playwright e2e** spec — `sitka-web/e2e/dm7-c-opex.spec.ts` (или близкий путь):
- Navigate to Settings → Marketing.
- Click tab «Прочие расходы».
- Click «+ Категория», заполнить slug + displayName + kind, save → новая category в list.
- Click «+ Расход», заполнить amount + категория + дата, save → новый расход в list, общий cashbox csTotalBalance уменьшился (если e2e имеет access to dashboard/cashbox snapshot — иначе пропустить эту проверку).
- Archive category → больше не виден в default view, виден после toggle archived.
- Unarchive → снова active.

F3. **Регрессии:** все existing 12 e2e specs зелёные. Existing vitest tests зелёные.

### G. Объём и форма

G1. Diff только в файлах из §Файлы (modify + new).
G2. НЕТ изменений в `sitka-core/`, `sitka-services/`, миграциях.
G3. `npm run typecheck` + `npm run test` (vitest) + `npm run e2e` (Playwright) — все зелёные. Регрессий 0.
G4. `git diff --shortstat` < 1500 строк добавленных + удалённых суммарно. Если ползёт выше — возврат в TL обсудить scope.
G5. Один PR. Worker может разбить на несколько коммитов в ветке для clarity (e.g., «client/types» → «category manager» → «expense form» → «tab integration» → «tests»), но один PR.
G6. CI 7 lanes должны быть зелёные: fourmolu (skipped — не Haskell), weeder (skipped), import-linter (skipped), drift-check (skipped), haskell-test (skipped), python-test (skipped), frontend-typecheck+E2E ✓.

### H. Out of scope (НЕ делать в этом TASK)

- **CashboxWidget breakdown по `expense_category.kind`** — backlog (см. OPERATING.md «Заметки»). Pre-requires backend extension `TransactionResp.trExpenseCategoryId`.
- **Filtering / pagination на списках** — basic ordering (date desc для expenses, name ASC для categories). No filter UI в этом TASK; YAGNI на 30 deals/month масштабе.
- **Bulk import / batch edit** — нет product требования.
- **Multi-currency expense** — out of DM-7.
- **Backend изменения** — безусловный возврат в TL.
- **AnalyticsDashboard / другие screens** — не трогать.

## Контекст

- Master HEAD: `51fd8ef` (post PR #71 doc smoke + #72 DM-7-C Core + #73 doc-sync).
- Backend endpoints (готовые в master):
  - `GET /api/treasury/categories?archived=<bool>` → `[CategoryResp]`
  - `POST /api/treasury/categories` → `CategoryResp` (409 on slug conflict including archived)
  - `PATCH /api/treasury/categories/:id` → `CategoryResp` (tri-state archivedAt)
  - `POST /api/treasury/expense` → `TransactionResp` (free-balance guard, currency RUB-only, 60s skew tolerance)
- Существующие managers — образцы паттерна:
  - `sitka-web/src/components/settings/ChannelAccountManager.tsx`
  - `sitka-web/src/components/settings/CampaignManager.tsx`
  - `sitka-web/src/components/settings/ListingManager.tsx`
  - `sitka-web/src/components/settings/SpendEntryForm.tsx`
  - `sitka-web/src/components/settings/SpendList.tsx`
- Tab pattern: `sitka-web/src/components/settings/MarketingSettings.tsx:16` (`type Tab = ...`), `:34` (`useState<Tab>`), `:99+` (render).
- `Transaction` TS type: `sitka-web/src/api/types.ts:50` (13 полей, без `expenseCategoryId` — см. §Задача и B2 caveat).
- `getCashboxSnapshot` existing API method: `sitka-web/src/api/client.ts:341`.
- Backend wire shapes (для свертки с TS типами): `sitka-core/src/Api/Types.hs:1046` (`TransactionResp`), и `Api.Treasury.hs` строки ~570+ для Phase C типов (`CategoryResp`, `Create*Req`, `Update*Req`, `CreateManualExpenseReq`).
- Admin merge паттерн репо: `gh pr merge <N> --squash --delete-branch --admin` (ruleset «Protect master — hard» в solo bypass'ed by admin).

## Reviewer

После HANDOFF — TL human review. **Codex round не запрашиваю** — Tier C UI, низкий blast radius (UI bug виден на первом use). Если HANDOFF поднимет неожиданный architectural issue — TL может запросить round retroактивно.

## Worker workflow

1. Прочитать TASK целиком.
2. Сменить Status: open → in-progress.
3. `git fetch origin && git checkout -b feat/dm7-c-frontend-ui-tab origin/master`.
4. Read existing settings managers (`ChannelAccountManager`, `CampaignManager`, etc.) — копировать паттерн стиля. Read `MarketingSettings.tsx` целиком для tab integration.
5. Реализация в порядке (рекомендация, не обязательно):
   - API client & types (E1, E2, E3).
   - `ExpenseCategoryManager` (D, простой CRUD, отдельная единица).
   - `OperationalExpenseForm` (C).
   - `OperationalExpenseManager` (B, integrates обе sub-секции).
   - Tab integration в `MarketingSettings.tsx` (A).
   - Vitest unit tests (F1).
   - Playwright e2e (F2).
6. Локально: `npm run typecheck && npm run test && npm run e2e`. Все три зелёные. `git diff --shortstat` < 1500.
7. Коммит(ы), push, PR в master с заголовком `feat(dm-7-c): frontend UI tab "Прочие расходы" + manual expense form + category CRUD`.
8. HANDOFF в `HANDOFFS/2026-04-29-claude-worker-to-claude-tl-dm7-c-frontend-ui-tab.md` по шаблону. Указать:
   - Acceptance check A-G (✓/✗ с деталями).
   - Tri-state PATCH choice — (i) или (ii) и почему.
   - «Замечено по дороге» если есть.
9. Status: in-progress → review.

## Условные возвраты в TL (через HANDOFF, без молчаливых правок)

- Любая необходимость core/services/migration изменений → стоп, безусловный возврат.
- `CashboxWidget` хочется тронуть → стоп (это backlog, отдельный TASK после backend prereq).
- Existing managers нужно рефакторить чтобы поделиться кодом → описать в HANDOFF, TL решит (отложить или новый refactor TASK).
- Tri-state PATCH (E3) — если ни (i) ни (ii) не выходят чисто на 50 строк → возврат в TL обсудить третий путь.
- Diff > 1500 строк → стоп, описать что разрослось.
- Регрессия в existing 12 e2e → стоп, не proxy'ить.
