# 2026-04-30-dm7-c-cashbox-tab-and-variant-b

- ID: `2026-04-30-dm7-c-cashbox-tab-and-variant-b`
- Created by: Claude Tech Lead session, 2026-04-30 (T3+T4 IA refactor + Variant B widget cells per OPERATING сводка)
- Worker model: Claude Code
- Worker branch: `feat/dm7-c-cashbox-tab-and-variant-b` (новая ветка от свежего `origin/master`, **после merge PR #74, PR #75, и `csTotalSpent` backend PR** — все три pre-req'а)
- Layer: web (frontend)
- Risk tier: C (UI / IA refactor; нет business-logic / money-flow)
- Status: done (merged 2026-05-01 21:44Z, PR #77, master sha `5bc9bec`)

> **DRAFT — awaits TL go-signal.** Pre-req'ы:
> 1. PR [#74](https://github.com/upside2002-maker/sitka-office/pull/74) merged (даёт `OperationalExpenseManager` / `ExpenseCategoryManager` / `OperationalExpenseForm` files и opex-tab в `MarketingSettings`).
> 2. PR [#75](https://github.com/upside2002-maker/sitka-office/pull/75) merged (даёт `useEventStream` в `CashboxWidget` — этот TASK не должен ломать live-refresh).
> 3. `csTotalSpent` backend TASK (`2026-04-30-dm7-c-cstotalspent-backend.md`) merged (даёт `csTotalSpent: number` в JSON wire — этот TASK добавляет TS type + UI cell).
>
> Worker НЕ начинает, пока все три не в master. Пользователь сообщает TL → TL передаёт промпт.

## Задача

Закрыть **T3+T4 IA refactor** для DM-7-C frontend:

**T3 (IA refactor — два слоя):** Касса = первичная сущность системы, **видна на двух уровнях одновременно**:

1. **Summary persistent на главной (Сделки tab → AnalyticsDashboard):** `<CashboxWidget />` **остаётся** в `AnalyticsDashboard.tsx:45` где он сейчас mounted. **НЕ удалять.** Variant B 5 cells (см. T4) применяются и к этому mount'у.

2. **Полноценный cashbox-раздел в новом top-tab «Касса»:** новый `CashboxScreen.tsx` mount'ит:
   - Тот же `<CashboxWidget />` сверху (2-й mount-site того же компонента — сводная информация всегда видна когда оператор зашёл в Касса).
   - `<OperationalExpenseManager />` снизу — список «прочие расходы» + nested `ExpenseCategoryManager` = базовая детализация.

Перенос из `MarketingSettings`: opex-tab выпадает (Маркетинг возвращается к 4 tab-ам: spend / accounts / campaigns / listings); компоненты `OperationalExpenseManager / ExpenseCategoryManager` остаются в `sitka-web/src/components/settings/` папке (импорт-only переезд, файлы не двигаются).

Position нового tab «Касса» в top-nav: **между «Сделки» и «Сообщения»** (Касса = 2-я, рядом с workspace; финансовая видимость соседствует с операционной). НЕ в конце после Маркетинга — Касса не вспомогательный раздел.

**T4 (Variant B widget cells + slug UX):**

**T4 details (Variant B widget + slug UX):**
- `CashboxWidget` cells layout = Variant B: `Всего / Свободно / В резерве / Потрачено / Прибыль закрытых сделок`. Применяется к **обоим** mount-сайтам (AnalyticsDashboard + CashboxScreen). **Drop** `Ожидаемая маржа` cell (`csExpectedMargin` остаётся в backend wire — просто не рендерится).
- TS type `CashboxSnapshot` (`sitka-web/src/api/types.ts`) расширить полем `csTotalSpent: number`. Поле `csExpectedMargin: number` **остаётся** (mirror backend wire — additive backwards-compat).
- 6 vitest mocks в `CashboxWidget.test.tsx` (строки 22, 67, 86, 111, 126, 140) — добавить `csTotalSpent: <число>` в каждый mock object.
- **Update obsolete comment** в `CashboxWidget.tsx:7-26` — сейчас описывает 5 cells включая Expected margin как «partial P&L for active deals minus their unused reservation slack» (Phase A формула, устарела с PR #70 + drop сейчас). Переписать под актуальные 5 cells Variant B.
- `ExpenseCategoryManager` slug UX: hide slug input field (lines ~165-170 в файле PR #74), auto-generate slug из displayName на submit (`displayName.toLowerCase().replace(/[^a-z0-9_-]+/g, '_').replace(/^_+|_+$/g, '')`). Slug column в table (строки ~213, 240) **остаётся видимой** (operator может сверяться). Если пустой результат после sanitize — показать ошибку «Название содержит только спец-символы — добавьте латиницу/цифры».

## Файлы

- `modify:`
  - `sitka-web/src/contexts/WorkspaceContext.tsx` — расширить `view` union (строка 57) и `setView` параметр (строка 99) добавлением `'cashbox'`. **Аккуратно**: `setView` сейчас принимает explicit union — обновить **обе** строки + `RedirectToMessages` setView signature в `AppLayout.tsx:151-159` (тоже принимает union, ему тоже нужен `cashbox`).
  - `sitka-web/src/components/AppLayout.tsx` — добавить новый top-nav button «Касса» **между «Сделки» и «Сообщения»** (Касса = 2-я кнопка); data-testid `view-switcher-cashbox`. Добавить render branch `{view === 'cashbox' && <CashboxScreen />}`. Update CSS hint в `workspace-shell` className composer если нужно (`workspace-shell--cashbox`). Update `RedirectToMessages` setView union.
  - `sitka-web/src/components/AnalyticsDashboard.tsx` — **НЕ ТРОГАТЬ.** `<CashboxWidget />` остаётся mounted на строке 45 — это первичный summary видимый в основном workspace (Сделки tab). Variant B cells (T4) автоматически применяются к этому mount'у потому что меняется сам `CashboxWidget.tsx`. Тесты AnalyticsDashboard проверяющие наличие cashbox cells — оставить (только если они пинят specific Expected margin label — adjust label).
  - `sitka-web/src/components/settings/MarketingSettings.tsx` — **удалить** `'opex'` из `Tab` union (строка 16 в PR #74 версии), **удалить** `['opex', 'Прочие расходы']` tuple из nav array, **удалить** `{tab === 'opex' && <OperationalExpenseManager .../>}` render branch, **удалить** import `OperationalExpenseManager` (строка 12 в PR #74 версии). Маркетинг возвращается к 4 tabs.
  - `sitka-web/src/components/CashboxWidget.tsx` — **drop** `csExpectedMargin` cell renderer (строки ~99-104). **Add** `csTotalSpent` cell с label `Потрачено`, variant **`'spent'`** (новый, отдельный — НЕ reuse `'negative'`). Test ID `cashbox-spent`. Position: **между** «В резерве» и «Прибыль (закрытые)» (per OPERATING Variant B order: `Всего / Свободно / В резерве / Потрачено / Прибыль закрытых сделок`). Update top-of-file Haddock-style комментарий (строки 7-26) под актуальные 5 cells. Обновить `CashboxCell` variant union (строка 113): **добавить** `'spent'`, **удалить** `'expected'` (с уходом Expected margin cell variant больше не используется). Финальный union: `'primary' | 'reserved' | 'positive' | 'negative' | 'spent'` (5 variants — net same count).
  - `sitka-web/src/components/CashboxWidget.test.tsx` — обновить все 6 mock objects (строки 22-25, 67-72, 86-90, 111-115, 126-131, 140-145) добавлением `csTotalSpent: <число>` (значение mirror'ит логику теста; для empty case `0`, для loaded case любое sensible число типа `45000`). Добавить **1 новый test case** «renders Потрачено cell with csTotalSpent value» mirror'ящий existing «renders Всего cell» pattern. Если existing test «5 cells rendered» имеет explicit count — обновить (теперь Total/Free/Reserved/**Spent**/Realized = всё ещё 5, просто Expected→Spent swap).
  - `sitka-web/src/api/types.ts` — расширить `CashboxSnapshot` type (строки 389-396) полем `csTotalSpent: number` после `csExpectedMargin`. Обновить top-of-block комментарий (строки 379-388) если он перечисляет cells.
  - `sitka-web/src/components/settings/ExpenseCategoryManager.tsx` — hide slug input (строки ~165-170 в PR #74 версии) **И** скрыть slug column в table (строки ~213 `<th>Slug</th>` + ~240 `<code>{c.ecSlug}</code>` cell). Slug — internal handle, оператор не должен его видеть в обычном flow. Replace handleCreate slug source: `const slug = sanitizeSlug(transliterate(trimmedName))`. Helpers:
    ```ts
    // RU Cyrillic → Latin transliteration (GOST 7.79 system B-style, simplified).
    // Single-letter map covers operator-typing reality; ё/й/щ/ъ/ы/ь/э/ю/я
    // expand to digraphs/empty per common UX convention.
    const TRANSLIT_MAP: Record<string, string> = {
      а:'a', б:'b', в:'v', г:'g', д:'d', е:'e', ё:'yo', ж:'zh', з:'z',
      и:'i', й:'y', к:'k', л:'l', м:'m', н:'n', о:'o', п:'p', р:'r',
      с:'s', т:'t', у:'u', ф:'f', х:'h', ц:'ts', ч:'ch', ш:'sh', щ:'sch',
      ъ:'', ы:'y', ь:'', э:'e', ю:'yu', я:'ya',
    }

    function transliterate(s: string): string {
      return s.toLowerCase().split('').map((ch) => TRANSLIT_MAP[ch] ?? ch).join('')
    }

    function sanitizeSlug(s: string): string {
      return s.toLowerCase().replace(/[^a-z0-9_-]+/g, '_').replace(/^_+|_+$/g, '')
    }
    ```
    Order: **transliterate first** (cyrillic → latin), then `sanitizeSlug` (collapse whitespace/punctuation → underscores). Example: `«Зарплата март Q1»` → transliterate → `«zarplata mart q1»` → sanitize → `«zarplata_mart_q1»`.

    Update create-form validation: replace «slug — только латиница…» error text с проверкой что `sanitizeSlug(transliterate(trimmedName)) !== ''` (не-empty post-translit-and-sanitize). Если empty — error «Название не может быть представлено как slug — добавьте латиницу/цифры или русские буквы». Удалить `slug` state (строка ~38) и SLUG_RE constant (строка ~28) если становятся unused. Update form `disabled` predicate (строка ~194): только `displayName.trim() === ''`.
  - `sitka-web/src/components/settings/ExpenseCategoryManager.test.tsx` — adjust tests: убрать те что филлят `opex-cat-slug` input (этого input больше нет); добавить test «slug is auto-generated from displayName» (фиксирует sanitization работает: `Зарплата март Q1` → backend POST с `ecrSlug: 'zarplata_mart_q1'` или похожее). Добавить test «displayName из чистых спец-символов отдаёт ошибку» если слаг = `''`.
  - `sitka-web/e2e/dm7-c-opex.spec.ts` — обновить spec под новую IA: navigation сначала кликает «Касса» (был «Маркетинг» → tab «Прочие расходы»). Если spec много на opex breakdown'е — full rewrite не нужен, только entry-point navigation. **Не путать** `view-switcher-marketing` и новый `view-switcher-cashbox`.
- `new:`
  - `sitka-web/src/components/CashboxScreen.tsx` — новый компонент. Mounts (двух-уровневая раскладка cashbox-раздела):
    - Top: `<CashboxWidget />` (re-imported, без изменений к API). Это **второй mount-site** того же компонента — полная Variant B сводка видна оператору сразу при заходе в Касса tab. Performance impact = 2 fetch + 2 SSE listeners (CashboxWidget использует `useEventStream` после PR #75); within tolerance до 4+ subscribers per OPERATING backlog (singleton refactor — отдельный mini-TASK когда понадобится).
    - Below: `<OperationalExpenseManager onError={setError} onSuccess={setSuccess} />` (re-imported из `settings/`). Это «прочие расходы + категории + базовая детализация» (latest 100 manual expenses table + nested `<ExpenseCategoryManager />`).
    - Banner state (success / error) для props `OperationalExpenseManager`'а — mirror `MarketingSettings` pattern с auto-dismiss через 3500ms.
    Total ~60-80 LOC. Не дублирует `MarketingSettings` логику; берёт only what's used.
  - `sitka-web/e2e/dm7-c-cashbox-tab.spec.ts` (опционально) — short spec проверяющий что Касса tab clickable, рендерит CashboxWidget + OperationalExpenseManager. Может быть уже покрыто обновлённым `dm7-c-opex.spec.ts` — Worker решит на месте, в HANDOFF отметит выбор.
- `delete:` —
- `migrations:` НЕТ.

## Не трогать

- `sitka-core/*` — backend нет изменений (`csTotalSpent` уже добавлен в pre-req TASK; `csExpectedMargin` остаётся в wire).
- `sitka-services/*` — Telegram bot / parser / cron нет изменений.
- `sitka-web/src/api/client.ts` — handlers `getCashboxSnapshot` / `listExpenseCategories` / `createExpenseCategory` / `createManualExpense` остаются. Если ExpenseCategoryManager auto-slug меняет signature `api.createExpenseCategory(...)` — НЕ менять, всё ещё передаёт `ecrSlug` (просто Worker computes its value client-side вместо user input).
- `sitka-web/src/components/CampaignManager.tsx`, `ChannelAccountManager.tsx`, `ListingManager.tsx`, `SpendList.tsx`, `SpendEntryForm.tsx` — Marketing внутренние tabs не трогать.
- `sitka-web/src/components/settings/OperationalExpenseManager.tsx` + `OperationalExpenseForm.tsx` — компоненты переезжают **по импорту** (CashboxScreen импортит из `./settings/`), сами файлы НЕ трогать. Если найдётся рефакторинг папок (`settings/` → `cashbox/`) — НЕ ДЕЛАТЬ молча, отметить в HANDOFF, оставить пути как есть.
- `sitka-web/src/styles/*.css` — если CashboxScreen потребует layout-обёртку (например wrapping `mk-root` flex), Worker может добавить новый класс `cashbox-screen` в существующий CSS файл; **не** создавать новый CSS-файл целиком.
- `docs/DM-7-cashbox.md` — TL doc-PR отдельно после accept этого + csTotalSpent backend (синхронный update обоих).
- Прочие markdown / `.claude/` / overlay в `ai-dev-system/` — нет.

Если по дороге заметишь что-то ещё, требующее правки — НЕ ПРАВИТЬ молча. Зафиксировать в HANDOFF секцией «Замечено по дороге, не правил».

## Критерии приёмки

### A. Top-tab «Касса» (AppLayout + WorkspaceContext)

A1. `WorkspaceContext.view` union (строка 57) и `setView` parameter union (строка 99) расширены `'cashbox'`.

A2. `AppLayout.tsx` — добавлена кнопка top-nav «Касса» с `data-testid="view-switcher-cashbox"` **между «Сделки» и «Сообщения»** (Касса = 2-я кнопка в навигации; primary financial entity рядом с workspace). Активный класс `view-switcher-btn--active` корректно работает.

A3. `AppLayout.tsx` — добавлен render branch `{view === 'cashbox' && <CashboxScreen />}` рядом с существующими.

A4. `RedirectToMessages` setView union обновлён `'cashbox'`.

### B. CashboxScreen (новый компонент)

B1. `CashboxScreen.tsx` создан, экспортит `CashboxScreen` функцию-компонент.

B2. Mount-tree (два слоя):
- Сверху: `<CashboxWidget />` — full Variant B summary (5 cells), это второй mount-site того же компонента (первый — в `AnalyticsDashboard.tsx:45`, остаётся).
- Ниже: `<OperationalExpenseManager onError={...} onSuccess={...} />` — list прочих расходов + nested ExpenseCategoryManager.

B3. Имеет own banner state (success / error) для props onError / onSuccess `OperationalExpenseManager`'а — mirror `MarketingSettings` pattern с auto-dismiss через 3500ms.

B4. Class `cashbox-screen` или reuse `mk-root` (на усмотрение Worker'а; consistent с другими screen'ами).

### C. AnalyticsDashboard — НЕ ТРОГАТЬ

C1. `<CashboxWidget />` mount в `AnalyticsDashboard.tsx:45` **сохраняется** — основной summary persistent на главной (Сделки tab → Analytics).

C2. Если existing AnalyticsDashboard test пинит specific cell label `Ожидаемая маржа` — adjust label (теперь `Потрачено`). Сам assert `<CashboxWidget />` в дереве — оставить.

### D. MarketingSettings cleanup

D1. `'opex'` removed: `Tab` union, nav array tuple, render branch, import `OperationalExpenseManager`.

D2. Маркетинг top-nav возвращается к 4 tabs: Расходы / Аккаунты / Кампании / Объявления.

D3. PR #74 e2e spec `dm7-c-opex.spec.ts` обновлён: entry navigation = «Касса» tab вместо «Маркетинг» → «Прочие расходы».

### E. CashboxWidget Variant B

E1. Cell renderer order (`<div className="cashbox-widget-grid">` строки 74-105):
1. `Всего` (csTotalBalance, variant `'primary'`)
2. `Свободно` (csFree, variant `'primary'`)
3. `В резерве` (csReserved, variant `'reserved'`)
4. **`Потрачено`** (csTotalSpent, variant **`'spent'`**) — **NEW**
5. `Прибыль (закрытые)` (csRealizedProfit, variant `'positive'` / `'negative'` conditional)

E2. **Removed**: `Ожидаемая маржа` cell + соответствующий `<CashboxCell .../>` block (строки ~99-104).

E3. Top-of-file Haddock-комментарий (строки 7-26) переписан: больше не упоминает «Expected margin», «partial P&L for active deals minus their unused reservation slack». Новое описание перечисляет 5 cells Variant B + describes csTotalSpent semantics («running total всех outgoing-tx; визуально = сколько уже потратили из ledger'а»).

E4. `csBackfillPending` banner логика (строки 63-72) **сохранена** — independent от Variant B.

E5. **Variant union update** в `CashboxCell` props (строка 113): итоговый union = `'primary' | 'reserved' | 'positive' | 'negative' | 'spent'`. Удалён `'expected'` (orphaned после drop Expected margin cell), добавлен `'spent'`.

E6. **CSS:** новый class `cashbox-cell--spent` определён в том же CSS-файле где `cashbox-cell--reserved / --positive / --negative / --primary` (Worker grep'нет `cashbox-cell--reserved` найдёт файл). Visual style — **distinguishable от `--negative`** (это не убыток, это нейтральное «уже потрачено»): рекомендация — приглушённый orange / amber (например `color: #c47a1d` или `color: var(--warning-muted)` если есть в палитре). Worker может выбрать конкретный hex/token consistent с существующей палитрой проекта; главное — НЕ red (negative reserved для убытков), НЕ green (positive — прибыль). Удалить orphaned class `cashbox-cell--expected` если он был определён.

### F. TS type + mocks

F1. `sitka-web/src/api/types.ts:389-396` `CashboxSnapshot` имеет 7 полей (добавлено `csTotalSpent: number` после `csExpectedMargin`). Existing 6 полей **не удалены** (включая `csExpectedMargin` — backend wire их сохранил).

F2. Top-of-block комментарий обновлён если он перечислял cells.

F3. 6 vitest mocks в `CashboxWidget.test.tsx` (строки 22, 67, 86, 111, 126, 140) расширены `csTotalSpent: <число>`. Числа sensible (не все zeros на loaded case, не nonsense на empty case).

F4. Тест «renders 5 cells» (если есть) обновлён под Variant B — Total/Free/Reserved/**Spent**/Realized.

F5. Новый тест pinning «csTotalSpent → cell text «Потрачено: <formatRub(value)>»» добавлен (1 case).

### G. ExpenseCategoryManager slug auto-gen + cyrillic transliteration

G1. Slug `<input>` (строки ~165-170 в PR #74 версии) **удалён** из формы создания категории.

G2. Slug **column в table** (строки ~213 `<th>Slug</th>` + ~240 `<code>{c.ecSlug}</code>` cell) **тоже удалена** — slug это internal handle, оператору не нужен в обычном flow. Если column-grid визуально ломается на 1 столбец меньше (например CSS grid-template-columns) — adjust в том же файле.

G3. `handleCreate` использует **transliterate then sanitize**:
```ts
const slug = sanitizeSlug(transliterate(trimmedName))
```
Helpers (~30 LOC inline в этом же файле, без npm-зависимостей):
```ts
// RU Cyrillic → Latin transliteration (упрощённый GOST-style, MVP).
// Single-letter map покрывает реальный operator-typing; ё/ж/ц/ч/ш/щ/ю/я
// раскрываются в digraphs; ъ/ь — в empty.
const TRANSLIT_MAP: Record<string, string> = {
  а:'a', б:'b', в:'v', г:'g', д:'d', е:'e', ё:'yo', ж:'zh', з:'z',
  и:'i', й:'y', к:'k', л:'l', м:'m', н:'n', о:'o', п:'p', р:'r',
  с:'s', т:'t', у:'u', ф:'f', х:'h', ц:'ts', ч:'ch', ш:'sh', щ:'sch',
  ъ:'', ы:'y', ь:'', э:'e', ю:'yu', я:'ya',
}

function transliterate(s: string): string {
  return s.toLowerCase().split('').map((ch) => TRANSLIT_MAP[ch] ?? ch).join('')
}

function sanitizeSlug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9_-]+/g, '_').replace(/^_+|_+$/g, '')
}
```
Order: **transliterate first** (cyrillic → latin), then `sanitizeSlug` (collapse whitespace/punctuation → underscores, trim).

G4. **Examples** (acceptance pin'ит хотя бы 3 в тестах G7):
- `Зарплата март Q1` → translit → `zarplata mart q1` → sanitize → `zarplata_mart_q1`
- `Логистика — Авто` → translit → `logistika — avto` → sanitize → `logistika_avto`
- `Salary 2026` (already latin) → translit (no-op) → sanitize → `salary_2026`

G5. Если `sanitizeSlug(transliterate(trimmedName)) === ''` (только пробелы / только ъь / только спец-символы которые translit съел и sanitize вычистил) — показать ошибку «Название не может быть представлено как slug — добавьте латиницу, цифры или русские буквы». Сохранить existing «Название не может быть пустым» для truly-empty case.

G6. `slug` state и `setSlug` (строка ~38) удалены. SLUG_RE constant (строка ~28) удалён. ESLint должен пройти. Update form `disabled` predicate (строка ~194): только `displayName.trim() === ''`.

G7. `ExpenseCategoryManager.test.tsx` обновлён:
- Тесты которые `userEvent.type(getByTestId('opex-cat-slug'), '...')` — удалены или переписаны без slug input.
- Тесты проверяющие наличие slug column в table — удалены / adjusted.
- **3 новых теста** на transliteration:
  - `Зарплата март` → POST с `ecrSlug: 'zarplata_mart'`.
  - `Логистика — Авто` → POST с `ecrSlug: 'logistika_avto'`.
  - `Salary 2026` → POST с `ecrSlug: 'salary_2026'`.
- **1 новый тест** на edge case: только спец-символы / только ъь → ошибка showed, POST не вызван.

G8. **Backend slug-conflict (409)** — translit детерминирован, конфликт возможен если оператор вводит два displayname приводящих к одному slug (например `Зарплата март` и `Зарплата_март`). Backend уже rejects per OPERATING (`slug-conflict 409 even on archived`). UI просто показывает body 409 как error message — без специальной обработки.

### H. E2E

H1. `sitka-web/e2e/dm7-c-opex.spec.ts` — entry navigation обновлён: `await page.getByTestId('view-switcher-cashbox').click()` вместо `view-switcher-marketing` + `mk-tab-opex`.

H2. **Опционально** новый `dm7-c-cashbox-tab.spec.ts` (~30-50 LOC):
- Click view-switcher-cashbox.
- Assert CashboxWidget visible (`data-testid="cashbox-widget"`).
- Assert 5 cells visible с правильными labels: Всего, Свободно, В резерве, Потрачено, Прибыль (закрытые).
- Assert OperationalExpenseManager visible (any data-testid от PR #74).

H3. `Playwright` тест-сьют локально passes (41+ tests от PR #74; новые добавляются).

### I. Объём и форма

I1. Diff только в файлах из §Файлы.
I2. НЕТ новых backend файлов / миграций / Domain types.
I3. `npm test` (vitest) + `tsc -b` + `npx playwright test` — все зелёные. `npm run lint` clean.
I4. Pre-commit hooks clean.
I5. `git diff --shortstat` за этот PR — менее **500 строк** added + removed суммарно. Breakdown ожидаемый:
- WorkspaceContext.tsx: ~5 LOC
- AppLayout.tsx: ~15 LOC
- AnalyticsDashboard.tsx: 0 LOC (НЕ трогается; max +1 если test label adjust)
- MarketingSettings.tsx: -10 LOC
- CashboxScreen.tsx: +60-80 LOC (новый файл)
- CashboxWidget.tsx: ~30 LOC (cell swap + comment rewrite)
- CashboxWidget.test.tsx: ~40 LOC (6 mocks × 1 line + 1-2 new tests)
- types.ts: ~3 LOC
- ExpenseCategoryManager.tsx: ~30 LOC (input remove + helper add + validation)
- ExpenseCategoryManager.test.tsx: ~30 LOC (test rewrite + new auto-gen test)
- e2e specs: ~20-50 LOC
**Total ~250-300 LOC**, верх диапазона 400 LOC — buffer на CSS / unforeseen.
I6. Один PR, заголовок `feat(dm-7-c): Касса tab + Variant B widget cells + slug auto-gen`.

### J. Out of scope (НЕ делать)

- Backend изменения — backend wire shape финален (PR #74 + PR #75 + csTotalSpent backend). Если Worker считает что нужно tweak backend — STOP, return в TL.
- **`csExpectedMargin` removal из backend** — поле остаётся в `Engine.Treasury` и в TS type. Просто не рендерится. Это явное decision (operator UX feedback + future planning widget reuse).
- **Удаление `<CashboxWidget />` из `AnalyticsDashboard.tsx`** — explicit anti-decision. Cashbox = первичная сущность, видна на Сделки экране постоянно. Worker НЕ удаляет.
- **Графики и аналитика по cashbox** в `CashboxScreen` (charts, time-series, breakdown по периодам) — backlog Phase D. Текущий scope T3+T4 = переезд existing компонентов + Variant B cells. Никаких новых chart-библиотек / ledger-viewer'ов / фильтров.
- Per-category breakdown в CashboxWidget (Phase D) — отдельный TASK после backend prereq `trExpenseCategoryId` (`2026-04-29-dm7-c-backend-widget-prereq.md`).
- Folder rename `settings/` → `cashbox/` для OperationalExpenseManager / ExpenseCategoryManager — структурный refactor отдельно. Worker импортит из existing `./settings/` пути.
- Reviewer round (Codex) — Tier C UI, изменения локализованы, TL human review достаточен. Если Worker поднимет неожиданную architectural / cross-layer / type-safety question — TL может запросить retroактивно.
- Live-refresh `OperationalExpenseManager` через `useEventStream` (currently не event-driven) — **отдельный** mini-TASK в backlog (`recordEvent` на manual_expense). НЕ делать здесь.
- CSS определение `.ws-financial-block` / `.ws-kv-line--muted` — **отдельный** mini-TASK в backlog.
- Messages layout bug fix — **отдельный** mini-TASK ждёт скрин.

## Контекст

- Master HEAD на момент draft: `51fd8ef`. Worker checkout-ит свежий post-merge HEAD (после #74 + #75 + csTotalSpent backend).
- `AppLayout.tsx` — top-tabs sit:
  - `sitka-web/src/components/AppLayout.tsx:50-114` (5 buttons currently; 6th = Касса).
  - `sitka-web/src/contexts/WorkspaceContext.tsx:57` view union.
- `CashboxWidget.tsx`:
  - Mounted в `AnalyticsDashboard.tsx:45`.
  - 5 cells сейчас (строки 74-105).
  - Comment строки 7-26 устарел.
- `MarketingSettings.tsx` (PR #74 версия):
  - Tab union строка 16 имеет `'opex'`.
  - `OperationalExpenseManager` import строка 12.
  - Tab nav array строка ~107 (5-th tuple `['opex', 'Прочие расходы']`).
  - Render branch с `tab === 'opex'`.
- `ExpenseCategoryManager.tsx` (PR #74 версия):
  - Slug input form: ~165-170.
  - Slug column в table: ~213, 240.
  - SLUG_RE validation: ~28.
  - State `slug / setSlug`: ~38.
- TS type `CashboxSnapshot`: `sitka-web/src/api/types.ts:389-396` (6 полей; добавится 7-е).
- Vitest mocks в `CashboxWidget.test.tsx`: lines 22, 67, 86, 111, 126, 140 (6 mock objects).

## Reviewer

**Не запрашивается.** Tier C UI / IA refactor, изменения локализованы во frontend, нет cross-layer impacts (backend wire shape финален). TL human review достаточен. Если Worker неожиданно поднимет architectural question (например: где живёт CashboxScreen state; почему Касса tab между БЗ и Маркетингом, не в конце; etc) — TL может запросить round retroактивно.

## Worker workflow

1. Прочитать TASK + OPERATING сводку + HANDOFF v1 от PR #75 (контекст `useEventStream` + `<DealFinancialBlock>`) + diff PR #74 (контекст `OperationalExpenseManager` / `ExpenseCategoryManager`).
2. Сменить Status: open → in-progress.
3. **Verify pre-req:** `git fetch origin && git log origin/master --oneline -5` — confirm все три pre-req'а в master:
   - PR #74 (frontend UI tab opex)
   - PR #75 (deal financials + cashbox refresh)
   - csTotalSpent backend (`feat(dm-7-c): add csTotalSpent to CashboxSnapshot for Variant B widget prereq`)
   Если что-то не merged — STOP, return в TL.
4. `git checkout -b feat/dm7-c-cashbox-tab-and-variant-b origin/master` (от свежего post-merge master).
5. Внести правки в порядке (suggested):
   1. `WorkspaceContext.tsx` — view union (механический setup).
   2. `CashboxScreen.tsx` (new) — empty shell сначала, затем mounts (CashboxWidget сверху + OperationalExpenseManager снизу).
   3. `AppLayout.tsx` — top-nav button **между Сделки и Сообщения** + render branch.
   4. `MarketingSettings.tsx` — drop opex tab.
   5. `types.ts` — csTotalSpent added.
   6. `CashboxWidget.tsx` — Variant B cells + comment rewrite (применится к ОБОИМ mount-сайтам автоматически).
   7. `CashboxWidget.test.tsx` — 6 mocks update + 1 new test.
   8. `ExpenseCategoryManager.tsx` — slug auto-gen.
   9. `ExpenseCategoryManager.test.tsx` — test rewrite.
   10. `e2e/dm7-c-opex.spec.ts` + optional new `dm7-c-cashbox-tab.spec.ts`.

   **NB:** `AnalyticsDashboard.tsx` НЕ в списке — он не трогается. CashboxWidget там остаётся mounted; Variant B labels применяются автоматически через изменение самого CashboxWidget.tsx.
6. Локально: `npm test && tsc -b && npx playwright test && npm run lint`. Все зелёные. `git diff --shortstat` ≤ 400 строк.
7. Smoke-проверка в браузере (vite dev): `npm run dev` →
   - **Сделки tab** (по умолчанию) → AnalyticsDashboard → assert CashboxWidget visible с Variant B cells (5 штук, новая ячейка «Потрачено» вместо «Ожидаемая маржа»).
   - **Касса tab** (новая, 2-я в nav) → CashboxScreen → assert CashboxWidget сверху (тот же 5-cell summary) + OperationalExpenseManager снизу (форма + список + категории).
   - **Маркетинг tab** → assert opex-tab отсутствует, осталось 4 tab-а (Расходы / Аккаунты / Кампании / Объявления).
   - **ExpenseCategoryManager** в Касса tab → assert slug input скрыт; create-form: ввести только displayName «Зарплата март», submit, assert category создана с auto-slug `zarplata_mart` (или табличная видимость подтверждает).
8. Коммит, push, PR в master с заголовком `feat(dm-7-c): Касса tab + Variant B widget cells + slug auto-gen`.
9. HANDOFF v1 в `HANDOFFS/2026-04-30-claude-worker-to-claude-tl-dm7-c-cashbox-tab-and-variant-b.md` с acceptance check A-J + «Замечено по дороге» если есть.
10. Status: in-progress → review.

## Условные возвраты в TL

- Один из трёх pre-req'ов не в master на момент checkout — STOP, return.
- `OperationalExpenseManager` или `ExpenseCategoryManager` имеет skull state / coupling который не позволяет их перенести без рефакторинга → описать, return.
- Diff > 400 строк → стоп, описать что разрослось.
- Любая необходимость touch backend / Domain types / migrations — безусловный возврат.
- Translit MAP не покрывает character который оператор реально использует (например украинская ї / казахская ә / французская é) — **не expanding молча**, описать в HANDOFF (current MAP — RU only). Если character не в MAP, `transliterate` оставит его как есть, `sanitizeSlug` затем заменит на `_` — окей для MVP, но flag для будущих расширений.
- CashboxWidget styling файл не найден / variant pattern не matches existing CSS — STOP, return в TL (не оставлять fallback на `'negative'` молча, теперь это явный отдельный variant).
