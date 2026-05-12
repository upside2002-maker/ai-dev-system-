# Статус — Astro

Дата последнего обновления: 2026-05-12.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **2026-05-11/12 закрыты две связанные задачи: первый Tier A продукта (движок транзитов) + Tier C visual rebuild раздела «Транзиты»** по результатам обратки на свежий PDF Натальи.

### Tier A — движок транзитов

- **A.1 Quincunx revoke (только для транзитов):** включён 150° в `Domain.TransitCalendar.calendarAspects`. Natal/solar aspect engine, синтез, дирекции — не затронуты. Scope зафиксирован в `astro/.claude/corrections.md` (Correction 009).
- **A.2 Orb-window scanner:** замена exact-only zero-crossing на per-loop-pass orb-window. Engine эмитит `orb_enter_jd` / `orb_exit_jd` для каждого касания (loop pass 1/2/3). Аспекты-без-exact-касания (медленные планеты на отдалении 0.5°-1°) теперь видны.
- **A.3 Cross-year scan expansion:** Python sample-window расширен с 365d до 1445d (540d до и после солярного года). Engine видит ретроградные петли, начинающиеся до соляра или заканчивающиеся после.
- **Schema cascade (bright-line #8):** одним atomic коммитом — `solar-computed-facts.schema.json` + Haskell roundtrip-тест + Python contract-тест + TS-типы + 9 fixture regen + ruleset + corrections.
- **Per-planet orb calibration (после 2 TUNE-rounds):** Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn = 1.0°, Uranus = 1.0°, Neptune = 1.0°, Pluto = 1.25°. Эмпирически выведены из row-by-row сверки с Натальиным Marina PDF.

### Tier C — visual rebuild раздела «Транзиты» (PDF presentation)

- **Reason:** после Tier A engine cascade PDF начал печатать «engine dump» (большие raw-таблицы высших/социальных планет с периодами 2024-2028) вместо клиентского формата Марины. User REJECT 2026-05-12.
- **Что сделано (`9f47f45` rebuild + `dec0f5d` quincunx filter + `6894743` monthly mid-month):**
  - Удалены iter-1 raw-таблицы и блок «Какие транзиты особенно важны».
  - Monthly table «Транзиты планет по домам» — простые номера домов (без стрелок), cell-choice = планета на 15-е число месяца (95.6% совпадение с Маринин 50/52).
  - Трактовки по домам — flat list.
  - Календарь транзитных аспектов — Marina-style bullet-list коротких строк по месяцам, тон (благоприятный / напряжённый / сильный).
  - Фильтр квинконсов (presentation): orb 0.7° + transit-planet=outer & target=non-outer. Из десятка noise-quincunx в календаре остался один Marina-relevant: «Уран 150° Юпитер».
  - Engine math не тронут.
- **Iter-1 (Tier B raw outer/social tables, commit `7b8fd24`)** — формально отклонён, перенесён в архив как `rejected`, supersedeed by presentation rebuild.

### Совпадение с эталоном Марины (Натальин соляр 2025-2026_5.pdf)

- **Календарь транзитных аспектов (pp. 19-23):** 17/17 строк Марины присутствуют в нашем выводе, даты границ окон в пределах 1-2 дня. Лишних строк (за пределами Марининого списка) практически нет.
- **Monthly table (стр. 8):** 50/52 ячеек совпали. Остаточные 2 (Авг-25 Юпитер, Авг-26 Венера) — известные edge-случаи на границе солярного года (Маринина ручная редактура, недостижима детерминистическим правилом). Принято как известный остаток.
- **Структура раздела:** intro → monthly table → трактовки по домам → виды аспектов → золотое правило → календарь → how-to. Совпадает с Owner directive 1-6.

### Артефакты и тесты

- **Продуктовый repo:** 7 коммитов на `claude/dreamy-moore-46f5eb` worktree поверх `7b8fd24` (от main: 11 коммитов всего). Все push'нуты на `backup`.
  - `7b8fd24` iter-1 transit aspects tables (Tier B, теперь rejected/superseded)
  - `5f4fbc9` Tier A cascade
  - `3a12ed3` TUNE-1 orb tighten
  - `2e4c394` TUNE-2 per-planet calibration
  - `9f47f45` presentation rebuild Marina format
  - `dec0f5d` quincunx presentation filter
  - `6894743` monthly table mid-month cell choice
- **Тесты:** `cabal test` 242/242, `pytest` 85/85.
- **Артефакт для показа:** `/tmp/astro-natalya-monthstart-iter1.pdf` — финальный Натальин PDF.

## Ждёт твоего решения

1. **Merge ветки `claude/dreamy-moore-46f5eb` в `main`.** TL не делает это молча; нужен явный «ок». На ветке 7 коммитов (см. выше). После merge ветка может быть удалена.
2. **Когда показать Марине новую версию PDF.** После Tier A + Tier C цикл консультационного PDF радикально ближе к её эталону. Её следующая обратка определит приоритет дальнейших шагов.

## Срочные риски

(нет острых)

Архитектурный drift (фазы 0.1/0.2 prescribed vs реальный код в 0.5+) — без изменений с 2026-05-06. Не пожар.

## На очереди

Зависит от ответа Марины на новый PDF. Возможные направления:

- **Калибровка monthly table cell-choice на нескольких Marina cases** (если ей принципиально 52/52) — переход с single-case heuristic «mid-month» на более robust rule, требует ещё PDF.
- **Расширенная семантика «дома цели»** в календаре аспектов (сейчас — натальный дом target планеты; Marina pp. 20-22 показывает rulership-expanded set) — отдельный TASK.
- **Backlog (не запускать без её запроса):** `solar-nodes-lilith-retro-display`, `consultation-summary-matrix-rewrite`, `section-order-recon`.

## Не делаем сейчас

- **«Solar nodes / Lilith / retro display» без её явного запроса.** Tier A, не «давайте сделаем потому что глифы уже есть».
- **Публичный хостинг репозитория** (GitHub / GitLab / Gitea). Без отдельного «ок» не добавляем.
- **SaaS-направление и B2C-сайт.** Сняты после research'а, проект — внутренний инструмент.
- **Полная сверка архитектурного документа с фактическим кодом.** Откладывается.
- **Дальнейшая калибровка орбисов транзитного движка на одном Натальином case.** Per-planet значения (J/S/U/N = 1.0°, P = 1.25°) выведены эмпирически из её PDF; расширение калибровки требует ≥3-5 cases.
