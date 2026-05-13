# TASK: parser-quote-calculator-exchange-buffer

- Status: open
- Ready: yes
- Date: 2026-05-13
- Project: sitka-office
- Layer: web
- Risk tier: B
- Owner: Project Tech Lead
- Created by: bondvit@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Калькулятор парсера (`sitka-web/src/components/parser/QuoteCalculator.tsx`, закрыт PR #83) сейчас принимает один «курс ₽/$» и использует его буквально во всех USD→RUB пересчётах. По факту реальный курс конвертации обычно ~5% выше банковского, и в pricing settings уже хранится отдельное поле `psExchangeBuffer` (дефолт 5.0 в БД, см. `sitka-core/src/Api/PricingSettings.hs:95`). В текущем фронте этот буфер выкинут из расчёта — оператор обязан в момент горящего клиента самостоятельно накидывать надбавку поверх банковского курса; если забудет, цена клиенту окажется ниже себестоимости. Reviewer PR #83 явно зафиксировал риск числово (см. Context, residual #2).

Добавляем во фронт седьмое поле «Буфер курса, %» с дефолтом из `psExchangeBuffer`. Эффективный курс = введённый курс × (1 + буфер/100); все USD→RUB пересчёты в `compute()` используют именно эффективный. Сам ввод «Курс ₽/$» остаётся банковским — оператор больше не должен мысленно умножать. Текст для копирования клиенту НЕ упоминает буфер (внутренняя кухня).

Только фронт. Backend (`Api.PricingSettings`, `Engine.Pricing`) уже знает про буфер — ничего там не трогаем. Если выяснится, что фронт-только подхода недостаточно и нужно тащить буфер через API в новый endpoint — это уже отдельная TASK с подписью TL, не делать молча в этой.

## Files

- new:    (нет)
- modify: sitka-web/src/components/parser/QuoteCalculator.tsx
- modify: sitka-web/src/components/parser/QuoteCalculator.test.tsx
- delete: (нет)

Если в ходе работы Worker обнаружит, что нужно тронуть что-то ещё (например, `sitka-web/src/api/client.ts` или `sitka-web/src/api/types.ts`) — он возвращается через HANDOFF, не делает молча. На сегодня этого не должно потребоваться: `PricingSettings` тип уже содержит `psExchangeBuffer: number` (`sitka-web/src/api/types.ts:339`), а `api.getPricingSettings()` уже отдаёт его в существующем `useEffect`.

## Do not touch

- `sitka-core/` целиком, включая `Api/PricingSettings.hs`, `Engine/Pricing.hs`, `Db/Schema.hs` — буфер там уже есть, scope не расширяем.
- `sitka-services/`.
- Миграции БД (`sitka-core/db/migrations/`).
- `sitka-web/src/api/client.ts`, `sitka-web/src/api/types.ts` — не нужно: тип уже содержит поле.
- CSS файлы (`sitka-web/src/workspace.css` и др.) — `.parser-calculator-grid` это `auto-fit minmax(180px, 1fr)`, седьмое поле сядет без правки сетки. Если на десктопе при 7 полях разъезжается визуально — вернуть в HANDOFF, не трогать стили молча.

## Acceptance

- [ ] В UI калькулятора видно седьмое поле «Буфер курса, %», `data-testid="parser-calc-buffer"`. Размещение — между «Курс ₽/$» и «Маржа, %» в той же сетке `.parser-calculator-grid`.
- [ ] Дефолт буфера подтягивается из `s.psExchangeBuffer` в существующем `useEffect` (только если поле пустое, как и для остальных дефолтов). Если API недоступен — поле остаётся пустым, валидация ловит так же, как остальные пустые поля.
- [ ] Hint-текст обновлён одной фразой: «Курс задаётся как банковский, надбавка — отдельным полем». Упоминание про таможню в РФ — сохраняем.
- [ ] Формула в `compute()`:
  ```
  effectiveRate    = usdRate * (1 + bufferPct / 100)
  itemRub          = priceUsd        * effectiveRate
  shippingUsRub    = shippingUsUsd   * effectiveRate
  shippingIntlRub  = shippingIntlUsd * effectiveRate
  shippingRuRub    = shippingRuRub
  totalCostRub     = itemRub + shippingUsRub + shippingIntlRub + shippingRuRub
  clientPriceRub   = totalCostRub * (1 + marginPct / 100)
  marginRub        = clientPriceRub - totalCostRub
  ```
  `usdRate` сам по себе нигде в `compute()` больше не умножается на USD-поля напрямую — только через `effectiveRate`.
- [ ] Числовой эталон #1 (с буфером 5%, типовой кейс).
  Вход: `priceUsd=200, shippingUsUsd=12, shippingIntlUsd=38, shippingRuRub=600, usdRate=92.5, bufferPct=5, marginPct=20`.
  Ожидаемо: `effectiveRate=97.125`, `itemRub=19425`, `shippingUsRub=1165.5`, `shippingIntlRub=3690.75`, `shippingRuRub=600`, `totalCostRub=24881.25`, `clientPriceRub=29857.5`, `marginRub=4976.25`. В UI после округления: себестоимость `24 881 ₽`, цена клиенту `29 858 ₽`, маржа `4 976 ₽`.
- [ ] Числовой эталон #2 (регрессия PR #83 — буфер 0%).
  При том же входе с `bufferPct=0` расчёт должен совпасть со старым тестом из закрытой PR #83: `totalCostRub=23725`, `clientPriceRub=28470`, `marginRub=4745`. Тест на это явно добавлен в `QuoteCalculator.test.tsx`.
- [ ] Валидация: пустой / нечисловой буфер ловится теми же ветками `kind: 'empty'` / `kind: 'invalid'`, что и остальные поля; в `FIELD_LABELS` добавлен label «буфер курса». Отрицательный буфер допускается — поведение симметрично марже в минус (см. комментарий в `parseInputs` lines 402–406).
- [ ] Кнопка «Скопировать итог» (`formatForClipboard`) НЕ упоминает ни буфер, ни эффективный курс — формат остаётся как был: «Лид #N / Себестоимость / Цена клиенту / Маржа». Существующий тест формата (`QuoteCalculator.test.tsx`) обновлён под новые числа из эталона #1, но структуру четырёх строк сохраняет.
- [ ] `npm test -- QuoteCalculator` зелёный. Существующие 17 тестов обновлены под 7 inputs / новые ожидаемые числа; добавлено минимум три новых:
  (а) расчёт с буфером 5% на эталоне #1;
  (б) расчёт с буфером 0% совпадает со старым эталоном (#2);
  (в) `parseInputs` отдаёт `kind: 'empty'` с `'буфер курса'` в `missing`, когда поле пустое, и `kind: 'invalid'` при `'abc'`.
- [ ] Полный `npm test` зелёный (178+ тестов; ожидаем небольшое прибавление за счёт новых, не уменьшение).
- [ ] `npm run build` без ошибок.
- [ ] `make -C ~/Projects/ai-dev-system check` остаётся зелёным.

## Context

- Reviewer-HANDOFF по PR #83: `project-overlays/sitka-office/HANDOFFS/archive/2026-05-12-reviewer-to-tl-parser-quote-calculator.md`, секция «Conflicts / risks» residual #2 — «exchange buffer полностью выкинут из расчёта». Числовая оценка эффекта (`23 125 → 24 881 ₽` на 5%) — оттуда же. Эта TASK закрывает именно этот риск, обходясь фронтом.
- Закрытая TASK с базовой реализацией калькулятора: `project-overlays/sitka-office/TASKS/archive/2026-05-12-parser-quote-calculator.md` — та же планка процесса (Tier B / Mode normal / Reviewer обязателен).
- Backend `Api.PricingSettings`: `sitka-core/src/Api/PricingSettings.hs:95` хранит дефолт буфера в БД (5.0), отдаёт через `psExchangeBuffer` (`sitka-core/src/Api/Types.hs:347`). Фронт-тип уже содержит соответствующее поле — расширение API не требуется.
- TL-решения, зафиксированные пользователем 2026-05-13:
  1. Курс банковский, буфер отдельным полем — не объединять в «эффективный курс» в UI, оператор должен видеть оба числа.
  2. Текст для копирования клиенту — без буфера и без эффективного курса (внутренняя кухня).
  3. Только фронт; расширение API под буфер — отдельная Tier A backend задача, не сейчас.
  4. Reviewer обязателен (числовая корректность критична, как и в PR #83). Worker model — Claude Code.
