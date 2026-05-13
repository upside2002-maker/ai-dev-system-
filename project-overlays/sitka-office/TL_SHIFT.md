# Ведение проекта — sitka-office

- Released: yes
- Holder: (нет)
- Started: (нет)
- Expires: (нет)
- Scope: (нет)
- Active TASK: (нет)

## Notes

### 2026-05-13 21:31:17 — bondvit@gmail.com

- Зона ведения: первая TL-сессия после онбординга
- Начало:       2026-05-13 19:49:31
- Заметки:      Первая TL-сессия Bond завершена. Закрыт PR #84 (буфер курса в калькуляторе парсера) — седьмое поле «Буфер курса, %» с дефолтом из psExchangeBuffer, эффективный курс = банковский × (1 + буфер/100), все USD→RUB конверсии через эффективный. Lifecycle (TASK + 2 HANDOFF) через make accept-*, ветка feat/parser-quote-calculator-exchange-buffer удалена (origin + local). Master sitka-office 19ddeef (PR #85 codeowners — мерджил Илья). Открытых HANDOFFs / Reviewer findings нет. В backlog остаются два follow-up из PR #83 (защита usdRate<0, cleanup .parser-calculator-submit + offerSavedCount) — не срочные. Ничего не висит на reaction.

### 2026-05-12 21:47:32 — upside2002@gmail.com

- Зона ведения: калькулятор парсера — превратить заглушку в рабочий инструмент
- Начало:       2026-05-12 21:05:43
- Заметки:      калькулятор парсера закрыт, тесты зелёные, готов к показу
