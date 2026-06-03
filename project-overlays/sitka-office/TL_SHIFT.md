# Ведение проекта — sitka-office

- Released: no
- Holder: upside2002@gmail.com
- Started: 2026-06-02 21:35:59
- Expires: бессрочно
- Scope: поднять полный локальный стек на ветке P0-3 (Variant A)
- Active TASK: (нет)

## Notes

### 2026-06-02 19:54:18 — upside2002@gmail.com

- Зона ведения: локальный smoke улучшенного парсера на ветке P0-3 (директива Admin 2026-06-02 вечер)
- Начало:       2026-06-02 19:50:14
- Заметки:      локальный smoke на ветке P0-3 прошёл (Equinox Lead 36R live → variant_not_found/out_of_stock, как ТЗ ожидает); 4 записки в archive; ящик пуст до разморозки CI

### 2026-06-02 19:30:13 — upside2002@gmail.com

- Зона ведения: Avito Option 1 (UPSTREAM.md + CI test_market hookup) → потом декомпозиция ТЗ парсера
- Начало:       2026-06-02 17:48:20
- Заметки:      parser-improvement P0-1/P0-2/P0-3 серия закрыта локально; Avito Option 1 PR #96 ждёт CI; всё ждёт разморозки GitHub Actions (неоплаченный счёт Visa 0181)

### 2026-05-28 17:49:22 — upside2002@gmail.com

- Зона ведения: TASK A2 (расширение _sitka_catalog) + AVITO architecture audit параллельно
- Начало:       2026-05-28 16:59:46
- Заметки:      TASK A2 закрыт; серия inventory fork (A→B→C→D→A2) полностью завершена; AVITO audit готов; Sitka в стабильном состоянии — ждём Owner'ского решения по avito Option 1/2/3

### 2026-05-28 13:37:55 — upside2002@gmail.com

- Зона ведения: TASK C inventory_parser fork — P0-2 Amazon timeout collision + audit других адаптеров
- Начало:       2026-05-27 17:00:58
- Заметки:      серия inventory_parser fork (A→B→C→D) полностью закрыта; -31482 LOC; Amazon работает первый раз с vendoring; обе P0 из аудита закрыты; recurring CORE_AUTH drift root-caused и закрыт; финальный summary в to-admin.md

### 2026-05-24 15:40:15 — upside2002@gmail.com

- Зона ведения: инцидент: касса не пускает с правильным паролем
- Начало:       2026-05-24 15:33:40
- Заметки:      инцидент CORE_AUTH drift закрыт: ядро пересоздано, касса пускает с паролем, retro-вопрос в backlog (auto-deploy scope=services не подхватывает .env при recreate core)

### 2026-05-13 21:23:45 — upside2002@gmail.com

- Зона ведения: инцидент: парсер магазинов не видит товары, которые реально есть на сайтах — глубокая диагностика
- Начало:       2026-05-13 20:35:52
- Заметки:      2-словный фильтр парсера: диагностика записана в backlog (Tier C, ~1-3 LOC), workaround оператору — вводить одно ключевое слово

### 2026-05-13 20:32:10 — upside2002@gmail.com

- Зона ведения: инцидент: парсер магазинов возвращает 0 позиций по всем источникам — диагностика
- Начало:       2026-05-13 20:29:02
- Заметки:      инцидент-разбор: парсер исправен; запрос Blizzard parka действительно не находится у Rogers/1shot/ALS/Lancaster, проверено на эталонном Sitka Jetstream (Rogers вернул 20 позиций)

### 2026-05-13 21:31:17 — bondvit@gmail.com

- Зона ведения: первая TL-сессия после онбординга
- Начало:       2026-05-13 19:49:31
- Заметки:      Первая TL-сессия Bond завершена. Закрыт PR #84 (буфер курса в калькуляторе парсера) — седьмое поле «Буфер курса, %» с дефолтом из psExchangeBuffer, эффективный курс = банковский × (1 + буфер/100), все USD→RUB конверсии через эффективный. Lifecycle (TASK + 2 HANDOFF) через make accept-*, ветка feat/parser-quote-calculator-exchange-buffer удалена (origin + local). Master sitka-office 19ddeef (PR #85 codeowners — мерджил Илья). Открытых HANDOFFs / Reviewer findings нет. В backlog остаются два follow-up из PR #83 (защита usdRate<0, cleanup .parser-calculator-submit + offerSavedCount) — не срочные. Ничего не висит на reaction.

### 2026-05-12 21:47:32 — upside2002@gmail.com

- Зона ведения: калькулятор парсера — превратить заглушку в рабочий инструмент
- Начало:       2026-05-12 21:05:43
- Заметки:      калькулятор парсера закрыт, тесты зелёные, готов к показу
