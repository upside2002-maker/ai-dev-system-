# HANDOFF: worker → tl — parser-quote-calculator-exchange-buffer

- Status: closed
- Date: 2026-05-13 20:16
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-13-parser-quote-calculator-exchange-buffer.md

## Summary

Готово. Добавлено седьмое поле «Буфер курса, %» (`data-testid="parser-calc-buffer"`)
между «Курс ₽/$» и «Маржа, %». Формула в `compute()` переписана через
`effectiveRate = usdRate * (1 + bufferPct/100)`; все USD→RUB конверсии
идут через эффективный курс. `formatForClipboard` остался 4-строчным,
без упоминания буфера / эффективного курса. Оба числовых эталона
из Acceptance совпадают с TASK до копейки. 21/21 в QuoteCalculator,
182/182 полный vitest, `npm run build` чистый, `make check` ОК. Scope
строго в двух файлах из modify-list. Ветка `feat/parser-quote-calculator-exchange-buffer`
запушена (commit `4970a01`), PR не открыт — ждёт TL + Reviewer.

## Done

- **Состояние формы:** добавлен `useState<string>('')` для `bufferPct`
  (`QuoteCalculator.tsx:45`).
- **Дефолт из API:** в существующем `useEffect` подтягивается
  `s.psExchangeBuffer` (только если поле пустое, симметрично остальным —
  `QuoteCalculator.tsx:64–66`). API не расширялся: `PricingSettings` тип
  уже содержит `psExchangeBuffer: number`, mock в тестах его уже отдавал.
- **Передача в parseInputs:** `useMemo` зависит от `bufferPct`, передаёт
  его в parseInputs седьмым полем (`QuoteCalculator.tsx:90–105`).
- **Hint-текст:** дописана фраза «Курс задаётся как банковский, надбавка
  — отдельным полем» (`QuoteCalculator.tsx:135–139`). Старое упоминание
  про таможню в РФ сохранено.
- **UI-поле:** `<NumberField label="Буфер курса, %" testId="parser-calc-buffer" />`
  между «Курс ₽/$» и «Маржа, %» в той же сетке `.parser-calculator-grid`
  (`QuoteCalculator.tsx:175–181`). CSS не трогал — `auto-fit minmax(180px, 1fr)`
  сам адаптируется к 7 полям.
- **FIELD_LABELS:** добавлен ключ `bufferPct: 'буфер курса'`
  (`QuoteCalculator.tsx:394`). Валидация empty/invalid веток работает
  единообразно с остальными полями. Отрицательный буфер допускается
  (симметрично марже в минус, как и сказано в комментарии `parseInputs`).
- **RawInputs / ParsedInputs / FIELD_LABELS:** расширены полем
  `bufferPct` (`QuoteCalculator.tsx:362–397`).
- **compute() формула** (`QuoteCalculator.tsx:441–462`):
  ```
  effectiveRate    = usdRate * (1 + bufferPct / 100)
  itemRub          = priceUsd        * effectiveRate
  shippingUsRub    = shippingUsUsd   * effectiveRate
  shippingIntlRub  = shippingIntlUsd * effectiveRate
  shippingRuRub    = shippingRuRub        // не трогаем — уже в RUB
  totalCostRub     = itemRub + shippingUsRub + shippingIntlRub + shippingRuRub
  clientPriceRub   = totalCostRub * (1 + marginPct / 100)
  marginRub        = clientPriceRub - totalCostRub
  ```
  `usdRate` напрямую на USD-поля больше не умножается — только через
  `effectiveRate`. Buffer-документация добавлена inline-комментарием.
- **JSDoc** обновлён (`QuoteCalculator.tsx:18–34`): убрано упоминание
  «без exchange buffer», добавлено объяснение `effectiveRate`.
- **Тесты** (`QuoteCalculator.test.tsx`):
  - **(а) Эталон #1 (с буфером 5%):** новый тест `compute: эталон #1 — буфер
    5% даёт эффективный курс 97.125, cost=24881.25`. Проверяет ВСЕ семь
    выходных полей до копейки.
  - **(б) Эталон #2 (буфер 0% = регрессия PR #83 (master `936ccdb`)):** новый тест
    `compute: эталон #2 — буфер 0% совпадает со старой формулой PR #83 (master `936ccdb`)`.
    Числа cost=23725 / price=28470 / margin=4745 идентичны.
  - **(в) Валидация buffer:**
    - `parseInputs: буфер пустой → empty со словом «буфер курса» в missing`
      — проверяет ветку `kind: 'empty'`.
    - `parseInputs: мусорный буфер → invalid c «буфер курса» в bad` —
      проверяет ветку `kind: 'invalid'` (вход `'abc'`).
    - `parseInputs: отрицательный буфер допускается → ok` — фиксирует
      что отдельной ветки `kind: 'buffer-negative'` НЕТ.
  - **Существующий формат-тест обновлён** под числа эталона #1: первая
    строка `Лид #42`, далее три строки `Себестоимость: 24 881 ₽`,
    `Цена клиенту: 29 858 ₽`, `Маржа: 4 976 ₽` (после Math.round и
    `ru-RU` форматирования). Дополнительно `expect(text).not.toMatch(/буфер|эффективн/i)`
    — буфер в clipboard-тексте отсутствует.
  - **Существующий "после клика «Рассчитать» — 7 строк breakdown"** работает
    без правки — buffer подтягивается из дефолтов pricing settings.
  - **`parseInputs: пустые поля → empty`** обновлён: `'буфер курса'` теперь
    среди ожидаемых полей в `missing`.
  - **Component-тесты с UI**: добавлен `fillNumber('parser-calc-buffer', '5')`
    в "кнопка «Рассчитать» неактивна пока не введены валидные числа" и
    "мусорный ввод даёт сообщение про некорректные значения".

### Числовые эталоны — фактически полученные числа

- **Эталон #1 (buffer=5%):**
  - effectiveRate = 92.5 × 1.05 = **97.125** ✓
  - itemRub = 200 × 97.125 = **19425** ✓
  - shippingUsRub = 12 × 97.125 = **1165.5** ✓
  - shippingIntlRub = 38 × 97.125 = **3690.75** ✓
  - shippingRuRub = **600** ✓
  - totalCostRub = 19425 + 1165.5 + 3690.75 + 600 = **24881.25** ✓
  - clientPriceRub = 24881.25 × 1.2 = **29857.5** ✓
  - marginRub = 29857.5 − 24881.25 = **4976.25** ✓
  - UI после Math.round + ru-RU: cost = `24 881 ₽`, client = `29 858 ₽`
    (29857.5 → Math.round даёт 29858), margin = `4 976 ₽` ✓
- **Эталон #2 (buffer=0%):**
  - effectiveRate = 92.5 × 1.0 = **92.5** (= банковский) ✓
  - cost = **23725**, clientPrice = **28470**, marginRub = **4745** ✓
  - Идентично результату PR #83 (master `936ccdb`) — регрессия защищена.

### Acceptance walk-through

- [x] В UI — седьмое поле «Буфер курса, %» с `data-testid="parser-calc-buffer"`
      между «Курс ₽/$» и «Маржа, %» в `.parser-calculator-grid`. done
- [x] Дефолт буфера из `s.psExchangeBuffer` в существующем `useEffect`,
      только в пустое поле. done
- [x] Hint-текст обновлён, упоминание про таможню сохранено. done
- [x] Формула в `compute()` соответствует TASK дословно. `usdRate`
      напрямую на USD-поля больше не умножается. done
- [x] Числовой эталон #1 — совпадает до копейки, see numbers above. done
- [x] Числовой эталон #2 — совпадает с PR #83 (master `936ccdb`) при buffer=0. done
- [x] Валидация empty/invalid + `FIELD_LABELS['bufferPct'] = 'буфер курса'`.
      Отрицательный буфер допускается без отдельной ветки. done
- [x] `formatForClipboard` НЕ упоминает буфер / эффективный курс.
      Структура «Лид #N / Себестоимость / Цена клиенту / Маржа» сохранена.
      Числа обновлены под эталон #1. done
- [x] `npm test -- QuoteCalculator` зелёный: **21/21** (было 17 → удалил
      один объединённый `compute` тест + добавил два числовых эталона +
      три новых parseInputs-теста = 17 − 1 + 2 + 3 = 21). done
- [x] Полный `npm test` зелёный: **182/182** (было 178 → +4). done
- [x] `npm run build` без ошибок (vite production 2.31 s, gzip 94.69 kB). done
- [x] `make -C ~/Projects/ai-dev-system check` зелёный. done

## Remaining

Ничего блокирующего. Открытые follow-up'ы (НЕ блокируют этот мердж,
оставлены TL на усмотрение, перенесены из Reviewer-HANDOFF PR #83 (master `936ccdb`)):
- (а) защитить `usdRate < 0` в `parseInputs` одной строкой;
- (б) clean-up workspace.css `.parser-calculator-submit` (inline-style
  override) + неиспользуемый `offerSavedCount` prop в ParserScreen.

## Artifacts

- branch:               feat/parser-quote-calculator-exchange-buffer
                        (от master 936ccdb)
- commit(s):            4970a01 — feat(parser): exchange buffer в QuoteCalculator
- PR:                   нет (TL открывает после Reviewer pass)
- tests:                21/21 в QuoteCalculator.test.tsx; полный vitest
                        182/182 (18 файлов, 45.8 s); `npm run build`
                        чистый (tsc -b + vite build, 2.31 s); `make check`
                        зелёный
- Product repo status:  committed

## Conflicts / risks

Нет open conflicts. Несколько служебных пометок:

1. **`npm install` побочно тронул `sitka-web/package-lock.json`** (удалил
   `libc` поля у нескольких optional native-binary entries — артефакт
   resolution на macOS Node 23.11). Откатил через `git checkout --`,
   в коммит не попал. Если на CI lockfile перепричешется обратно — это
   уже отдельный housekeeping вопрос (несовпадение Node-версий с
   `engines` в package.json), не входит в эту TASK.

2. **Layout-проверка визуально не делал** — нет браузерного preview в
   worker-flow, проверка через test + build. CSS-сетка `.parser-calculator-grid`
   `auto-fit minmax(180px, 1fr)` математически адаптируется к 7 полям
   (на широкой sidebar 7 колонок по ~180 px, на узкой переходит на
   меньшее количество строк). Если на десктопе при 7 полях разъезжается
   визуально — это TL/Reviewer ловит в браузере и возвращает; CSS я не
   трогал per TASK Do-not-touch.

3. **`expect(...).toBe(19425)` vs `toBeCloseTo(19425, 5)`** в новых тестах:
   везде использую `toBeCloseTo(..., 5)` для безопасности с FP-арифметикой,
   даже там где формально результат точный (200 × 97.125 = 19425 без
   хвоста в double). Это согласуется со стилем существующих тестов
   `compute` (`toBeCloseTo` для clientPriceRub / marginRub в обоих эталонах).

## Next step

TL читает HANDOFF, принимает решение → если ACCEPT, делегирует Reviewer-у
ветку `feat/parser-quote-calculator-exchange-buffer` (commit `4970a01`)
по числовой корректности + scope-respect (как для PR #83 (master `936ccdb`)). После
Reviewer pass TL открывает PR, мерджит, потом `make accept-task` для
TASK + `make accept-handoff` для этого HANDOFF + обновление `STATUS_RU.md`
/ `OPERATING.md` Sitka.
