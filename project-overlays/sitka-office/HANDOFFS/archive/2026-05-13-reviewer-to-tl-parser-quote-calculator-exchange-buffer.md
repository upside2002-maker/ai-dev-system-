# HANDOFF: reviewer → tl — parser-quote-calculator-exchange-buffer

- Status: closed
- Date: 2026-05-13 20:25
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-13-parser-quote-calculator-exchange-buffer.md

## ARTIFACT

- HANDOFF под ревью: `project-overlays/sitka-office/HANDOFFS/2026-05-13-worker-to-tl-parser-quote-calculator-exchange-buffer.md`
- TASK: `project-overlays/sitka-office/TASKS/2026-05-13-parser-quote-calculator-exchange-buffer.md`
- Ветка: `feat/parser-quote-calculator-exchange-buffer`, commit `4970a01` (от master `936ccdb`)
- Worktree, в котором прогонял проверки: `/Users/bond/Desktop/vibe_coding/Sitka-office/.claude/worktrees/infallible-hodgkin-69feb3/`
- Файлы в diff: `sitka-web/src/components/parser/QuoteCalculator.tsx`, `sitka-web/src/components/parser/QuoteCalculator.test.tsx` (+156 / −33 строки, ровно 2 файла — соответствует TASK Files и Do-not-touch).

## SUMMARY

Recommendation: **ACCEPT** (готово к открытию PR).

Числовая корректность подтверждена: эталон #1 (буфер 5%) пересчитан в JS-семантике до копейки — `effectiveRate=97.125`, `cost=24881.25`, `price=29857.5`, `margin=4976.25`. `Math.round(29857.5)=29858` (JS round-half-up, не banker's; banker's применяется только к `toFixed`/`toLocaleString` с `roundingMode`, тут используется голый `Math.round`). UI-форматирование после `Math.round` + `ru-RU`: `24 881 / 29 858 / 4 976` — это и проверяет тест `formatForClipboard` через регексы. Эталон #2 (буфер 0%) совпадает со старым PR #83 в каждой строке: `cost=23725`, `price=28470`, `margin=4745`. `compute()` нигде не использует `v.usdRate` напрямую на USD-поля — только через `effectiveRate`. Scope строгий (2 файла), `package-lock.json` действительно не в коммите, `make -C ~/Projects/ai-dev-system check` зелёный, полный vitest 182/182, build чистый (gzip 94.69 kB совпадает с заявленным).

Главный реальный риск задачи — числовая корректность — закрыт. Остаётся остаточный риск визуального layout'а на 7 колонок (см. NITS), но он не блокирующий: математически `auto-fit minmax(180px, 1fr)` корректно переходит на 2 ряда при недостатке ширины, и регрессии относительно PR #83 здесь нет.

## FINDINGS

Critical / high / medium — нет.

### low — F1. Дубль тест-моков `getPricingSettings` в beforeEach и переопределение в трёх тестах

Файл: `sitka-web/src/components/parser/QuoteCalculator.test.tsx:17-28` + `:232`, `:249`, `:257`.

`beforeEach` ставит дефолтный мок `psExchangeBuffer: 5`. Три компонент-теста («кнопка неактивна», «пустые поля показывают валидацию», «мусорный ввод») переопределяют его на `mockRejectedValue(new Error('no settings'))`, чтобы стартовать с пустых полей. Это работает, но создаёт неочевидную семантику: новый агент, читающий тест, может пропустить mock rejection в одной строке и счесть, что поле буфера всё-таки подтянулось из дефолта. Это не баг, а читаемость — fix не требуется в этом PR. Зафиксируй на будущее: завести helper `mockNoDefaults()` и `mockWithDefaults({...})` если ещё раз появится тест в этом духе.

### low — F2. `parser-calc-rate` placeholder = «например, 92.5», `parser-calc-buffer` placeholder = «например, 5»

Файл: `sitka-web/src/components/parser/QuoteCalculator.tsx:169` и `:189`.

Placeholder'ы оба «например, X» — мелкая стилистическая мелочь. Не блокирует.

## MISSING

Ничего блокирующего по TASK Acceptance.

Что Reviewer **не смог** проверить из своего сидения (явно отмечаю, не fail):

1. **Визуальный layout 7-польной сетки** — `headless` режим тестов через jsdom не рендерит CSS grid математически; формально `auto-fit minmax(180px, 1fr)` обязан адаптироваться, но «не разъезжается ли визуально на стандартной ширине sidebar parser-экрана» подтверждается только глазами в браузере. TL: запустить `npm run dev` в `sitka-web` и глазами посмотреть `/parser`, либо принять risk и открыть PR — фрагмент UI закроется live при первом использовании. У меня нет UI-tools в Reviewer-сессии.

2. **Дефолт `psExchangeBuffer` из реального API** (а не из мока) — pricing-settings endpoint в core отдаёт `5.0` дефолтом (TASK Context, проверяется не в Reviewer-проходе по фронту, а в backend-тесте `Api.PricingSettings`). Worker сослался на это утверждение, я его не верифицировал на backend.

## SCOPE CREEP

Нет.

`git diff master..feat/parser-quote-calculator-exchange-buffer --stat` показывает ровно 2 файла, оба — modify из TASK Files. `Do not touch` соблюдён: `sitka-core/`, `sitka-services/`, миграции, `sitka-web/src/api/client.ts`, `sitka-web/src/api/types.ts`, CSS не тронуты. `package-lock.json` Worker откатил — diff пуст.

## NITS

- N1 (`QuoteCalculator.tsx:189`): placeholder «например, 5» в поле «Буфер курса, %» — можно сделать более информативным («банковский +5%»), но не критично.
- N2 (`QuoteCalculator.tsx:194-205`): inline-style override для `.parser-calculator-submit` (фикс «вечно-disabled» CSS из workspace.css) сохранён без изменений — это residual из PR #83 «(б) clean-up», не данной TASK. Worker корректно отметил в Remaining.
- N3 (`QuoteCalculator.tsx:13-15`): unused `offerSavedCount` prop сохранён, чтобы не править `ParserScreen.tsx` (вне scope). Тоже residual из PR #83.
- N4 (`QuoteCalculator.test.tsx:407-409`): регексы вида `/^Себестоимость:.*24\s881/` — `\s` матчит любой whitespace (включая non-breaking space U+00A0, который `ru-RU` `toLocaleString` иногда возвращает в зависимости от ICU). Это корректный паттерн (`\s` шире ` `), а не баг. Просто отмечаю — если когда-нибудь захочется ужесточить до ` ` (NBSP) для документирования формата, это будет дополнительная задача.
- N5 (`QuoteCalculator.test.tsx:278`): название теста «после клика «Рассчитать» показывает все семь строк breakdown» — формально breakdown остался 7 RUB-рядов (товар, US, intl, RU, cost, price, margin), как и в PR #83. Поле буфера не добавляет строки в breakdown — оно вход, а не выход. Тест корректный.

## RECOMMEND

**ACCEPT и открывай PR.**

Что обязательно принять:
- Числовая корректность обеих эталонов — это и был единственный реальный риск задачи, она закрыта.
- Scope strict, package-lock не в коммите, do-not-touch соблюдён.

Что отложить (новые TASK'и, не блокируют этот PR; уже в Worker Remaining):
- (а) защитить `usdRate < 0` в `parseInputs`;
- (б) clean-up `.parser-calculator-submit` CSS + неиспользуемый `offerSavedCount` prop в `ParserScreen.tsx`;
- (в) опционально — helper'ы `mockNoDefaults()` / `mockWithDefaults({...})` в тест-файле (F1), если в `sitka-web` появится третий компонент с похожим шаблоном.

Что отклонить как acceptable:
- Двусмысленность placeholder'а «например, 5» (F2 / N1) — оператор увидит подсказку «Курс задаётся как банковский, надбавка — отдельным полем» рядом, понятно.
- Inline-style override (N2) и `offerSavedCount` (N3) — residual из PR #83, не входит в эту TASK по TL-договорённости.

После твоего ACCEPT-решения: `gh pr create` → Reviewer уже сделал свой проход, второй раз не нужен → merge → `make accept-task` для TASK → `make accept-handoff` для worker'ского HANDOFF → `make accept-handoff` для этого reviewer'ского HANDOFF.

## Verification trail

- `git log master..feat/parser-quote-calculator-exchange-buffer --oneline` → `4970a01 feat(parser): exchange buffer в QuoteCalculator`
- `git diff master..feat/... --stat` → 2 файла (QuoteCalculator.tsx +64/-33-частей, QuoteCalculator.test.tsx +125/-...), `package-lock.json` не в diff.
- `git diff master..feat/... -- sitka-web/package-lock.json` → пусто.
- Ручной пересчёт эталона #1 в JS (`node -e ...`) → `effRate=97.125, item=19425, sus=1165.5, sint=3690.75, total=24881.25, price=29857.5, margin=4976.25`. `Math.round(29857.5)=29858`. `toLocaleString('ru-RU')` → `24 881 / 29 858 / 4 976`. Соответствует HANDOFF.
- Ручной пересчёт эталона #2 (buffer=0) → `total=23725, price=28470, margin=4745`. Совпадает с PR #83.
- `git show feat/... -- QuoteCalculator.tsx` `compute()` функция → нет прямого `v.usdRate` на USD-поля, только через `effectiveRate`.
- `npm test -- QuoteCalculator --run` в worktree → 21/21 passed.
- `npm test --run` (полный vitest) → 18 файлов, 182/182 passed, 73.31 s.
- `npm run build` → tsc + vite чистые, gzip 94.69 kB (совпадает с заявленным).
- `make -C ~/Projects/ai-dev-system check` → OK на all три check-скрипта.
- Hint-текст в `QuoteCalculator.tsx:148-150` содержит обе фразы: «Таможня учтена в строке «Доставка РФ»» (сохранена) + «Курс задаётся как банковский, надбавка — отдельным полем» (новая) — соответствует TASK Acceptance.
