# HANDOFF: worker → tl — parser-quote-calculator

- Status: closed
- Date: 2026-05-12 21:16
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-12-parser-quote-calculator.md

## Summary

QuoteCalculator перестал быть placeholder'ом: 6 полей ввода, активная кнопка
«Рассчитать», 7-строчный breakdown, рабочая «Скопировать итог», дефолты из
pricing settings. 17 unit-тестов зелёные, build чистый. Готов к review.

## Done

- `sitka-web/src/components/parser/QuoteCalculator.tsx` — полная замена
  placeholder'а на рабочий калькулятор (~470 LOC: компонент + чистые
  helper'ы `parseInputs` / `compute` / `formatForClipboard` / `copyToClipboard`).
- `sitka-web/src/components/parser/QuoteCalculator.test.tsx` — 17 тестов:
  - parseInputs: пустые поля, мусор, курс=0, валидный набор
  - compute: формула из Engine.Pricing.calculateCost (priceUsd=200, US=12,
    intl=38, RU=600, rate=92.5, margin=20% → cost=23725, price=28470,
    margin=4745), нулевая маржа, отсутствие NaN/Infinity на крайних входах
  - submit-кнопка: disabled пока невалидно, активна на валидном вводе
  - валидация: empty / invalid дают понятный текст, не падают
  - breakdown: 7 строк после клика «Рассчитать»
  - дефолты: подтягиваются из `getPricingSettings()` в пустые поля
  - copy: вызывает `navigator.clipboard.writeText` с правильным текстом,
    показывает «Скопировано» / «Не удалось — скопируй вручную»
  - copy fallback: при отказе Clipboard API + execCommand UI деградирует мягко
  - formatForClipboard: префикс «Лид #N» только когда leadId != null

## Remaining

- Push в remote делает TL после Reviewer ACCEPT (см. WORKER.md).
- `OPERATING.md` Sitka «Заметки» и `STATUS_RU.md` Sitka «Сейчас»
  обновлять не стал — это TL-action из контекста TASK (строка 53–54).
- E2E (Playwright) для калькулятора не добавлял — TASK требовал только
  `npm test -- QuoteCalculator`. Если нужно — отдельная TASK.

## Artifacts

- branch:               feat/parser-quote-calculator (от master 934934b)
- commit(s):            0be7b73 feat(parser): рабочий QuoteCalculator с расчётом, валидацией и копированием итога
- PR:                   (нет, TL пушит после ACCEPT)
- tests:                178/178 vitest зелёные (17 — новые в QuoteCalculator.test.tsx); `npm run build` без ошибок; `npx eslint` на изменённых файлах — clean
- Product repo status:  committed

## Conflicts / risks

1. **Несовпадение «7 полей ввода» vs фактически 6.** TASK строка 17 пишет
   «Семь полей ввода: цена товара (USD), доставка по США (USD),
   международная доставка (USD), доставка по РФ (RUB), курс RUB/USD, маржа
   (%)» — это **6 пунктов в списке**, а не 7. Стуб содержал 4, прирастил
   до 6 (добавил intl USD + доставка РФ RUB). Breakdown — 7 строк
   (товар RUB, доставка США RUB, международная RUB, доставка РФ RUB,
   себестоимость RUB, цена клиенту RUB, маржа RUB) — это совпадает с
   TASK acceptance. **Решение:** реализовал 6 inputs / 7 breakdown lines
   как соответствие явному списку TASK. Возможные интерпретации
   пропавшего 7-го input'а: exchange buffer % (есть в pricing settings)
   или customs RUB отдельной строкой. Если TL имел в виду что-то
   конкретное — флаг, добавлю отдельной TASK.

2. **Таможня (customs) свёрнута в «доставку РФ».** Pricing settings
   возвращает `psCustomsRub` и `psShippingRuRub` отдельно. В дефолте
   калькулятора я их сложил в одно поле «Доставка РФ» (≈ оператор
   правит общую сумму). Это согласуется с breakdown'ом, где только
   4 RUB-компонента (товар/US/intl/РФ) без отдельной строки customs.
   Если хочется ровно соответствовать `Engine.Pricing` — нужна 7-я
   строка breakdown «Таможня, ₽» и 7-й input. Снова — флаг для TL.

3. **Exchange buffer пропущен из inputs.** В `Engine.Pricing.usdToRub`
   формула `RUB = USD * rate * (1 + buffer/100)`. В калькуляторе я
   принимаю что оператор вводит «эффективный» курс уже с буфером
   (либо подтянутый из settings — там тоже без буфера, оператор
   правит руками). Это соответствует UX выбора в TASK (упрощённый
   расчёт под клиента), но математически расхождение с Engine.

4. **CSS-стиль активной кнопки** — workspace.css `.parser-calculator-submit`
   был спроектирован под вечный `disabled` (cursor: not-allowed, muted
   цвет). Не трогал workspace.css (вне scope), подменил критичные
   CSS-свойства inline в TSX, класс оставил для продолжения
   паддингов/радиуса. Чистый CSS-рефактор — отдельная задача если
   будем чистить.

5. **Prop `offerSavedCount` больше не используется в логике.** Оставил
   в Props (вызов из ParserScreen.tsx вне scope), но не разбираю.
   JSDoc обновил. Если TL хочет — отдельной задачей убрать prop +
   обновить ParserScreen.

6. **`make check` падает на pre-existing overlay drift.** Проверил —
   падает и на чистом master (snapshot указывает на `470f48f`, master
   на `934934b`). Не моё изменение, не блокирует.

## Next step

TL запускает Reviewer отдельной сессией. После ACCEPT — push +
PR + merge.
