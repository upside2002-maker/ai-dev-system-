# Aswath Damodaran — Session 5 (of 42): Valuation - The Basics

URL: https://www.youtube.com/watch?v=coS6TXtKfV0
Источник-тег: fundamental. Слайды: https://www.stern.nyu.edu/~adamodar/pdfiles/invphilslides25/session5.pdf

Тема: основы оценки (valuation) и ценообразования (pricing). Лекция из курса Investment Philosophies. Цель — заложить два фундамента: intrinsic value (DCF) и relative valuation (мультипликаторы), чтобы дальше противопоставлять value- и growth-инвестирование.

---

## 1. Стратегии / торговые и портфельные механики

Прямых торговых/портфельных стратегий (с входами, стопами, размером позиции) в видео **нет** — это методологическая лекция по оценке. Единственная «механика действия» — рычаги создания стоимости в активистском инвестировании (как изменить value компании), формализуема только как чек-лист, не как алгоритм трейдинга:

- **Рычаги увеличения стоимости (activist investing)** [16:14–17:15]: (1) больше денежного потока с существующих активов — резать издержки, повышать эффективность; (2) больше стоимости от роста — выше return on capital по проектам ИЛИ меньше реинвестировать в проекты с доходностью ниже cost of capital; (3) удлинить период роста — строить барьеры входа / конкурентные преимущества; (4) снизить cost of capital — менять микс debt/equity, использовать более дешёвый долг, снижать постоянные издержки, делать продукт менее дискреционным (less discretionary). Это и есть источник прироста стоимости от смены менеджмента.

---

## 2. Гипотезы / проверяемые тезисы

- **Price ≠ Value** [18:17]: рыночная цена определяется силами (demand/supply, mood, momentum, liquidity, group think, incremental information), отличными от тех, что определяют стоимость → цена может устойчиво расходиться со стоимостью. Проверяемо: дивергенция цены и DCF-оценки нормальна, не ошибка модели.
- **Цена реагирует на инкрементальную, а не на полную информацию** [18:17]: на отчёте о прибыли high-growth компании информации может быть минимум, но если результат «beats expectations» — цена реагирует. Проверяемый тезис о механике реакции цены на earnings surprise.
- **Рост может разрушать стоимость** [05:04, 11:11, 12:11]: если return on capital < cost of capital (или ROE < cost of equity), рост уничтожает стоимость; если равны — рост нейтрален; стоимость добавляет только тогда, когда доходность реинвестиций превышает стоимость капитала. Проверяемый критерий «качества» роста.
- **Закон убывающей отдачи масштаба** [11:11]: чем крупнее компания, тем труднее удерживать высокий reinvestment rate при высоком return on capital (реинвестировать 80% при ROC 30% легко для $1B компании, тяжело для $100B). Проверяемый эмпирический паттерн.
- **Темп роста не может вечно превышать рост экономики** [06:05–07:05]: иначе компания «станет экономикой». Поэтому terminal growth rate ≤ рост экономики (по сути ≤ risk-free rate как прокси номинального роста экономики), и обязательно < cost of capital.
- **Кейс Twitter (pre-IPO, 27.10.2013)** [14:13–16:14, 21:21–22:23]: авторская DCF дала ~$18/акция; цена открылась $45, дошла до $75, в итоге вернулась к ~$18. Тезис: рынок не обязан соглашаться с оценкой, но фундаментал в итоге может сработать (автор сам отмечает «mea culpa» — не считает совпадение «утешительным призом»). Pricing по EV/user при медиане ~$100/user и 237 млн пользователей дал ~$24 млрд EV — близко к рыночной цене на IPO.

---

## 3. Фундаментал / механика оценки (takeaways по существу)

### Два способа поставить число на инвестицию [00:00–01:01]
- **Valuation (intrinsic value)**: оценка по cash flows + growth + risk самого бизнеса. Инструмент — DCF.
- **Pricing**: число на основе demand/supply, mood, momentum — сколько платят за аналогичные активы (P/E + comparables). «Использовал P/E и comps → ты company *priced*, а не *valued*».

### Intrinsic value = 3 компонента [01:01–02:02]
Ожидаемые cash flows + рост этих cash flows + неопределённость их получения (риск). DCF = (1) оценить ожидаемые CF, (2) оценить discount rate под риск, (3) взять present value.

### Две фазы / два способа учёта риска в DCF [02:02–03:03]
- **Способ 1 (обычный)**: expected cash flows в числителе, дисконт по risk-adjusted discount rate.
- **Способ 2 (certainty equivalents)**: берём «гарантированные» CF (certain equivalents), дисконтируем по risk-free rate. Автор: «I have never seen a good valuation using the second approach» — требует слишком много «плясок» вокруг оценок.

### Equity vs Firm valuation [03:03–04:03]
- **FCFE (cash flow to equity)**: CF после всех (включая кредиторов) → дисконт по **cost of equity** → value of equity.
- **FCFF (cash flow to the firm)**: pre-debt CF всем claim holders → дисконт по **cost of capital** (WACC = взвешенная cost of equity + after-tax cost of debt) → value всего бизнеса; затем вычесть долг → equity value. Стоимость фирмы = assets in place + growth assets.

### Четыре вопроса для любой intrinsic valuation [04:03–07:05]
1. Какие CF от **существующих** инвестиций (assets in place)? (pre-debt firm CF или after-debt equity CF).
2. Какую стоимость добавит **рост** (growth assets)? Может быть положительной, нейтральной или **отрицательной**.
3. Насколько **рискованны** эти CF? (риск equity через CAPM/APM/proxy ИЛИ риск всей фирмы / операций).
4. Когда фирма станет **mature** (зрелой)? Mature firm = растёт ≤ темпа роста экономики. Нужно, чтобы поставить **closure** → terminal value (бесконечный ряд при постоянном росте, решён математиками 200 лет назад).

### Как 4 вопроса ложатся в уравнение DCF [07:05–08:07]
- CF от существующих активов = базовый (base year) уровень.
- Стоимость роста проявляется дважды: (а) growth rate, наращивающий revenues/CF; (б) **reinvestment**, необходимый для этого роста. Чистый эффект решает, добавляет ли рост стоимость.
- Риск → через discount rate.
- Зрелость → terminal value (стоимость в perpetuity).

### Расчёт FCFF (cash flow to the firm) [08:07–09:08]
Нельзя стартовать с **net income** (он после процентов). Старт — с **operating income** = revenues × operating margins (прогнозируй margins, если они меняются). Минус налоги — но не фактически уплаченные, а те, что были бы **на operating income** (чтобы не двойно учитывать налоговую выгоду долга — она уже сидит в after-tax cost of debt). Минус **reinvestment** (заводы или intangibles у non-manufacturing). = **FCFF**.
FCFE = ещё на шаг: вычесть процентные платежи и погашение основного долга, прибавить новые заимствования.

### Discount rates [09:08–10:10]
- Cost of equity: CAPM (beta как мера риска + equity risk premium + risk-free rate); альтернативы — APM, multifactor, proxy models. На выходе — expected return на рисковый equity.
- Cost of capital (WACC) = weighted average cost of equity и after-tax cost of debt. After-tax cost of borrowing = ставка займа net налоговой выгоды.

### Драйверы роста: сколько реинвестируешь × насколько хорошо [10:10–12:11]
Чтобы расти — надо реинвестировать **и реинвестировать хорошо**.
- **Equity-уровень**: сколько = retention ratio (нераспределённая прибыль, 1 − payout); качество = **ROE**.
- **Firm-уровень**: сколько = **reinvestment rate** = (net capex + Δ working capital) / after-tax operating income; качество = **return on capital (ROC)**.
- Quality growth = редкая компания, способная реинвестировать **много И хорошо** одновременно.
- Масштаб усложняет удержание (см. раздел 2).
- Рост разрушает стоимость, если ROC < cost of capital / ROE < cost of equity.

### Terminal value [12:11–13:11]
Условие: только для mature firm (g ≤ рост экономики ⇒ g < cost of capital, поэтому знаменатель никогда не схлопывается).
Формула (firm): берём **after-tax operating income в год ПОСЛЕ терминального** (для TV в год 10 — earnings года 11, т.к. PV-уравнения требуют CF на год вперёд). Реинвестиция в perpetuity зависит от g и ROC:
**reinvestment rate = g / ROC** (пример: ROC 20%, g 3% → реинвестировать 15%).
CF = earnings × (1 − g/ROC). TV = CF / (cost of capital − g).

### Pricing / relative valuation [17:15–22:23]
Алгоритм:
1. **Standardize price** — нельзя сравнивать цену за акцию (сплит 2-в-1 делит цену пополам, дешевле не делает). Делим цену на scalar.
   - Числитель: market value of equity (market cap) ИЛИ market value всей фирмы ИЛИ **enterprise value** (market value фирмы net of cash).
   - Знаменатель (scalar): revenues, earnings (equity или firm), cash flows (equity или firm), book value. Грубый CF = operating income + depreciation/amortization = EBITDA.
2. **Pick comparable firms** — тот же бизнес/география. Больше критериев → меньше peer group; строгий выбор → малая выборка, гибкий → большая.
3. **Tell your story** — если company P/E = 15, а peers = 20, выглядит дёшево, но спросить: дёшево или есть причина (выше риск / ниже рост / рост не добавляет стоимости)? «Equity research reports don’t value companies. They price them».

### Кейс Twitter pricing [21:21–22:23]
P/E не сработал (убыток), P/B не сработал (отрицательный book value equity). EV/sales, EBITDA-мультипликаторы — много «NA». Сработал нестандартный мультипликатор **EV / number of users**: медиана ~$100/user × 237 млн users ≈ $24 млрд EV ≈ рыночной цене на IPO. «Pricing is what the market is using» — логичность не обязательна.

---

## 4. Риск-менеджмент / числа

- В видео нет позиционного риск-менеджмента; «риск» = discount rate.
- Twitter DCF [14:13–16:14]: маржа улучшается до **25%** (по здоровым online-ad игрокам); реинвестиция **$1.50 выручки на $1 капитала**; FCF сначала большие отрицательные (норма для high-growth с амбициями), потом положительные; mature после года 10; высокий стартовый cost of capital (high beta, мало долга) → снижается к среднему **8%**; в stable growth ROC > cost of capital, рост **2.5%**.
- Twitter оценка: **~$18/акция**; рынок: открытие $45 → пик $75 → возврат к $18.

---

## 5. Ошибки / антипаттерны / разоблачение нарративов

- **Старт FCFF с net income** [08:07] — ошибка: он уже после процентов; нужен operating income.
- **Двойной учёт налоговой выгоды долга** [08:07–09:08] — если в CF берёшь фактические налоги И используешь after-tax cost of debt. Бери гипотетические налоги на operating income.
- **«Рост всегда добавляет стоимость»** [11:11] — ложь: легко расти (много реинвестировать / делать acquisitions), но при низком ROC/ROE это уничтожает стоимость.
- **Рост быстрее экономики вечно** [06:05] — невозможно.
- **Несовместимость числителя и знаменателя мультипликатора** [22:23] — нельзя делить enterprise value на net income; EV → только на operating income / EBITDA / revenues. Market cap → на net income / book equity. «Be consistent».
- **Неявные допущения в pricing** [23:25] — если молча считаешь, что у твоей компании выше рост и ниже риск, ты обманываешь себя. Делай допущения явными.
- **Pricing без контроля различий = storytelling** [23:25].
- **Путать valuation и pricing** [01:01] — P/E + comps = pricing, не valuation.
- **Ожидать, что рынок согласится с оценкой** [16:14] — не жди; demand/supply, mood, momentum дадут другой ответ.

## 6. Источники данных / инструменты / упомянутые работы и авторы

- Автор: **Aswath Damodaran** (NYU Stern), курс Investment Philosophies (42 сессии).
- Слайды Session 5, post-class test + solution (см. описание видео).
- Модели/фреймворки: **DCF**, FCFE/FCFF, **CAPM**, Arbitrage Pricing Model (APM), multifactor models, proxy models, WACC (cost of capital).
- Мультипликаторы: P/E, P/B, EV/Sales, EV/EBITDA, **EV/number of users** (нестандартный).
- Кейс: **Twitter pre-IPO valuation** (27.10.2013).
- «Play Moneyball» [23:25] — привлекать статистику, чтобы понять, почему одни компании дёшевы, другие дороги.
- Упоминание: ChatGPT [14:13] — иронично, что нет универсального шаблона оценки, иначе «ChatGPT мог бы это делать».

---

## Таблица «если X → Y» (формализуемые правила / причинности)

| Условие (X) | Следствие / действие (Y) | Таймкод |
|---|---|---|
| Считаешь intrinsic value | Нужны 3 входа: expected CF + growth + risk | 01:01 |
| Дисконтируешь FCFE | Используй cost of equity → получаешь value of equity | 03:03 |
| Дисконтируешь FCFF | Используй cost of capital (WACC) → value фирмы; минус долг → equity | 03:03–04:03 |
| Используешь expected (не certain) cash flows | Дисконтируй по risk-adjusted rate (способ 1) | 02:02 |
| Используешь certainty equivalents | Дисконтируй по risk-free rate (способ 2; на практике плохо работает) | 02:02–03:03 |
| ROC < cost of capital (или ROE < cost of equity) | Рост **разрушает** стоимость | 11:11–12:11 |
| ROC = cost of capital | Рост нейтрален (ничего не добавляет) | 11:11 |
| ROC > cost of capital + реинвестируешь хорошо | Рост **добавляет** стоимость (quality growth) | 11:11 |
| Компания становится крупнее | Труднее удерживать высокий reinvestment rate × высокий ROC | 11:11 |
| Хочешь terminal value | Прими mature firm: g ≤ рост экономики ⇒ g < cost of capital | 06:05, 12:11 |
| Нужна reinvestment rate в perpetuity | = g / ROC | 12:11 |
| Считаешь TV в год 10 | Бери earnings года 11 (CF на год вперёд) | 12:11 |
| Стартуешь FCFF | Старт с operating income (не net income); налоги — гипотетические на op. income | 08:07–09:08 |
| Считаешь after-tax cost of debt | = cost of borrowing × (1 − tax rate); налоговую выгоду не учитывать второй раз в CF | 08:07, 10:10 |
| Сравниваешь цены акций между компаниями | Сначала standardize (дели на earnings/book/revenue) — цена за акцию не сравнима | 18:17–19:19 |
| Числитель = market cap (equity) | Знаменатель = net income / book equity (equity-уровень) | 22:23 |
| Числитель = enterprise value (firm) | Знаменатель = operating income / EBITDA / revenues (НЕ net income) | 22:23 |
| Company P/E < peer P/E | Не «дёшево» автоматом — проверь: выше риск? ниже рост? рост без value? | 20:21–21:21 |
| Earnings отчёт beats expectations | Цена реагирует (на инкрементальную информацию), даже если данных мало | 18:17 |
| Делаешь pricing | Будь consistent (числитель↔знаменатель), играй Moneyball, делай допущения явными, контролируй различия | 22:23–23:25 |
| Не контролируешь различия в pricing | Остаётся только storytelling | 23:25 |

---

## Оговорки по качеству данных

- Транскрипт — английские автосабы; имена/термины восстановлены по контексту.
- «EIDA» в сабах = **EBITDA** (operating income + depreciation/amortization), исправлено по контексту [21:21, 22:23].
- «FU» в «cash flows to the FU» = **firm** [08:07].
- «pure group» в сабах = **peer group** [14:13, 20:21].
- «amotization» = amortization; «Mia Kalpa» = **mea culpa** [16:14].
- «chat JPT» / «chat GPT» = ChatGPT [14:13].
- «$150 of revenues for every dollar of capital» по контексту high-growth DCF — вероятно **$1.50** выручки на $1 капитала (sales-to-capital ratio), не $150 [14:13].
- Числа Twitter-кейса (маржа 25%, cost of capital 8%, рост 2.5%, оценка $18, цена $45/$75, EV $24 млрд, 237 млн users, $100/user) — со слов автора, на дату 27.10.2013.
- Формулы (reinvestment rate = g/ROC, TV = CF/(WACC − g)) переданы автором в словесной форме; записаны стандартной нотацией.
