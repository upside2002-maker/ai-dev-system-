# HANDOFF: reviewer → tl — parser-quote-calculator

- Status: closed
- Date: 2026-05-12 21:23
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-12-parser-quote-calculator.md

## Summary

ACCEPT. Branch `feat/parser-quote-calculator` (commit `0be7b73`)
реализует все 9 acceptance bullets TASK, scope не превышен (тронуты
только два файла из modify-list), 17/17 unit-тестов зелёные, полный
vitest 178/178 зелёный, `npm run build` без ошибок. Четыре конфликта
из worker-HANDOFF (6 inputs vs 7, customs в РФ, exchange buffer
выкинут, inline-style override `.parser-calculator-submit`) — все
явно проговорены и приняты на TL-уровне; имплементация им
соответствует.

## Done

Что я проверил независимо (HANDOFF claims проверены, не приняты на
веру):

- **Diff scope:** `git diff master..feat/parser-quote-calculator
  --stat` — 2 файла, оба в modify-list. `client.ts` нетронут.
  `+816 / -121`.
- **Unit-тесты:** `npm test -- QuoteCalculator` → 17 passed (1 file,
  254 ms). Полный suite → 178/178 (18 файлов, 6.6 s).
- **Build:** `npm run build` → tsc-clean + vite production build
  чистый, 117 ms.
- **Численная корректность.** `compute()` (QuoteCalculator.tsx:430-447)
  совпадает с вручную пересчитанным примером из теста (priceUsd=200,
  US=12, intl=38, RU=600, rate=92.5, margin=20% → cost=23725,
  price=28470, margin=4745). Формула:
  ```
  itemRub      = priceUsd * usdRate
  shippingUS   = shippingUsUsd * usdRate
  shippingIntl = shippingIntlUsd * usdRate
  shippingRU   = shippingRuRub
  cost         = sum
  clientPrice  = cost * (1 + margin/100)
  margin       = clientPrice - cost
  ```
  Это упрощённая версия `Engine.Pricing.calculateCost`
  (sitka-core/src/Engine/Pricing.hs:35-60) без exchange buffer и без
  отдельной строки customs. Расхождение acknowledged в worker
  HANDOFF, conflicts #2 и #3, и принято TL-ом (см. JSDoc
  QuoteCalculator.tsx:19-34).
- **NaN/Infinity safety.** `parseInputs` (QuoteCalculator.tsx:386-417):
  пустые поля → `kind: 'empty'`, нечисловые / `1e400` → `Number.isFinite`
  ловит `Infinity`/`NaN`, отдаёт `kind: 'invalid'`. `usdRate <= 0`
  → отдельный `kind: 'rate-zero'`. Отрицательные значения у других
  полей пропускаются (комментарий line 402-406 объясняет: маржа в
  минус — легитимный диагностический ввод, конкретно НЕ NaN).
  `formatRub` (line 472-478) дополнительная защита: на `!isFinite`
  отдаёт `'—'`. Тест "compute: NaN/Infinity не появляются на
  разумных входах" (test:136-148) пробивает крайние входы.
- **Кнопка-копирование.** `copyToClipboard` (line 491-522):
  primary — `navigator.clipboard.writeText` в try/catch; fallback —
  `document.createElement('textarea') + document.execCommand('copy')`.
  Тест "копирование падает (отказ Clipboard API)" (test:275-303)
  отбивает оба пути и проверяет деградацию UI до текста «Не удалось
  — скопируй вручную» вместо краша. Текст для копирования —
  короткий operator-friendly («Лид #N», себестоимость, цена
  клиенту, маржа), не JSON-дамп (test:305-337 пинят формат).
- **Layout / компактность.** Сетка `.parser-calculator-grid`
  (workspace.css:3144-3148) — `grid-template-columns: repeat(auto-fit,
  minmax(180px, 1fr))`, gap 10 px, padding 16/18 px. Шесть полей
  адаптируются от 1 колонки на узкой sidebar до 6 на широкой.
  Compact, не разъезжается.
- **Acceptance walk-through.**
  1. Placeholder режим убран, кнопка живая на валидном вводе — ✓
     (line 105-109, line 184-206).
  2. 6 input полей + дефолты из `getPricingSettings()` — ✓
     (line 136-177, line 55-83). TASK исправлен пользователем с
     "семь" на "шесть", это совпадает с реализацией.
  3. 7-строчный breakdown — ✓ (line 247-283).
  4. Нет NaN/Infinity — ✓ (см. выше).
  5. Понятная валидация на пустых/битых полях — ✓ (line 449-460,
     line 226-233 рендерит описание).
  6. Кнопка copy работает — ✓ (line 207-224 + test:235-273).
  7. Компактный десктоп-layout — ✓ (см. выше про grid).
  8. `npm test -- QuoteCalculator` зелёный, тесты покрывают расчёт,
     пустые/битые поля, кнопки — ✓ (17 passed).
  9. `npm run build` без ошибок — ✓.
- **Tier / архитектура.** Файл — Tier C (`sitka-web/**/*` per
  `.claude/risk-tiers.md`), bar = normal review. `client.ts`,
  миграции, Engine, Api/Quotes — все нетронуты.
- **Корреspondence с pricing settings shape.** `PricingSettings`
  type (sitka-web/src/api/types.ts:337-344) экспортирует все 6
  полей с префиксом `ps`, которые используются в `useEffect`
  (line 63-75). Совпадает.

## Remaining

Ничего блокирующего. Несколько nit-замечаний — см. ниже, не блокеры,
не требуют доработки в этой задаче.

## Artifacts

- branch:               feat/parser-quote-calculator (от master 934934b)
- commit(s):            0be7b73 — feat(parser): рабочий QuoteCalculator
- PR:                   (нет, TL пушит после ACCEPT)
- tests:                17/17 в QuoteCalculator.test.tsx; полный
                        vitest 178/178 зелёный; `npm run build`
                        clean
- Product repo status:  committed

## Conflicts / risks

**Все четыре конфликта из worker HANDOFF (раздел "Conflicts /
risks") уже приняты TL-ом per ваши инструкции — не релитигирую.
Подтверждаю только что имплементация им соответствует.**

Сверх того — два residual риска уровня "следить, но не блокер":

1. **Отрицательный курс (`usdRate < 0`) пропускается.** `parseInputs`
   ловит `usdRate <= 0` только как `=== 0` через `kind: 'rate-zero'`
   на line 414. Если оператор вобьёт `-92.5`, `parseInputs` отдаст
   `ok`, и `compute()` посчитает все RUB-поля отрицательными. Это
   *не нарушение acceptance* (числа finite, не NaN, не Infinity),
   но даст бессмысленный результат. У оператора скорее всего
   наглядно видно «-18 500 ₽», поэтому риск низкий. Если хотим
   защитить — `if (values.usdRate <= 0)` (line 414) уже работает
   для `0`, можно расширить до `<= 0` без изменения сигнатуры,
   проверка одной строкой.

2. **Exchange buffer полностью выкинут из расчёта.** Это conflict #3
   из worker HANDOFF, accepted; здесь дополнительно отмечу
   numerically: на типичном `buffer=5%` отсутствие буфера
   = расчёт занижает себестоимость на ~5% от USD-компонентов.
   На примере из теста `(200+12+38)*92.5 = 23 125 ₽` USD-часть,
   итоговая «истинная» себестоимость с буфером была бы
   `23 125 * 1.05 + 600 = 24 881 ₽`, не `23 725 ₽`. Если калькулятор
   используется как «сообщить клиенту цену» — это важная цифра,
   которая будет систематически меньше реальной. Tech Lead принял
   что оператор вбивает «эффективный» курс уже с буфером — окей,
   но это поведение стоит проговорить с пользователем (или явно
   подсказать в hint-тексте «введи курс уже с буфером», сейчас
   hint только говорит про «таможню в РФ»).

## Nits (не блокирующие)

- Hint-текст (line 131-134) объясняет где спряталась таможня, но
  не говорит про exchange buffer. После принятия TL-решения
  «оператор вбивает effective rate» — стоит дописать одну фразу
  «курс задан как «банковский + buffer», поправь под текущий», или
  оставить как follow-up.
- `offerSavedCount` prop не используется в логике (line 11-15
  JSDoc явно говорит). Это уже pinned в worker HANDOFF #5 как
  follow-up. Не трогаем здесь, но в отдельной чистке стоит.
- Inline-style override `.parser-calculator-submit` (line 195-203)
  — pragmatic фикс из-за того что класс был под вечный `disabled`.
  Рефакторинг workspace.css в отдельной задаче — окей. Не блокер.
- `eslint-disable react-refresh/only-export-components` annotations
  на line 385/429/480 — стандартный workaround для colocated
  pure helpers + components, документированы inline. ок.

## Scope creep

Нет. Изменены ровно два файла из modify-list. Backend, миграции,
client.ts, types.ts — нетронуты. Pricing engine — нетронут.

## Recommendation

ACCEPT, мерджить.

Опционально для TL — два follow-up TASK кандидата (НЕ блокируют
этот мердж):
- (а) защитить `usdRate < 0` в `parseInputs` одной строкой;
- (б) clean-up workspace.css `.parser-calculator-submit` чтобы
  класс работал в обоих режимах (живая / disabled), убрать
  inline-style override + убрать неиспользуемый
  `offerSavedCount` prop из ParserScreen.

Если пользователь поднимет вопрос про exchange buffer — это
третий, отдельный TASK (расширение формулы калькулятора), уже не
nit.

## Next step

TL фильтрует findings, принимает решение по follow-up'ам, пушит
ветку, открывает PR, мерджит. После мерджа — обновить
`OPERATING.md` Sitka «Заметки» и `STATUS_RU.md` Sitka «Сейчас»
(прописано в TASK Context). Reviewer-сессия закрыта.
