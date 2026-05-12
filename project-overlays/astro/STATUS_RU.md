# Статус — Astro

Дата последнего обновления: 2026-05-12.

## Сейчас

Внутренний инструмент Марины для подготовки соляр-консультаций. **2026-05-11/12 закрыт первый Tier A продукта** — пересборка движка транзитных аспектов под Маринин эталон, по результатам её обратки на PDF Натальи (iter-1 outer/social tables landed 2026-05-11).

Что сделано в Tier A cascade:

- **A.1 Quincunx revoke (только для транзитов):** включён 150° в `Domain.TransitCalendar.calendarAspects`. Natal/solar aspect engine, синтез, дирекции — не затронуты. Scope зафиксирован в `astro/.claude/corrections.md` (Correction 009).
- **A.2 Orb-window scanner:** замена exact-only zero-crossing на per-loop-pass orb-window. Engine эмитит `orb_enter_jd` / `orb_exit_jd` для каждого касания (loop pass 1/2/3). Аспекты-без-exact-касания (medленные планеты на отдалении 0.5°-1°) теперь видны.
- **A.3 Cross-year scan expansion:** Python sample-window расширен с 365d до 1445d (540d до и после солярного года). Engine видит ретроградные петли, начинающиеся до соляра или заканчивающиеся после.
- **Schema cascade (bright-line #8):** одним atomic коммитом — `solar-computed-facts.schema.json` + Haskell roundtrip-тест + Python contract-тест + TS-типы + 9 fixture regen + ruleset + corrections.
- **Per-planet orb calibration (после 2 TUNE-rounds):** финальные значения Sun/Moon/Mercury/Venus/Mars/Jupiter/Saturn = 1.0°, Uranus = 1.0°, Neptune = 1.0°, Pluto = 1.25°. Эмпирически выведены из row-by-row сверки с Натальиным Marina PDF.

Результат против эталона Марины (Натальин соляр 2025-2026_5.pdf, pp. 19-23, «Календарь транзитных аспектов»):

- **17/17 строк присутствуют** в engine output.
- **16/17 содержательно overlap** с Marina-окнами; #1 Jupiter Sextile Asc — pedantic near-miss (Marina single-day point внутри engine ~10-day окна).
- **Средний drift 7 дней, медиана 1 день.** 11/17 combos с drift ≤ 2d.
- Quincunx (Уран 150° Юпитер) теперь detected (был zero hits).
- Cross-year coverage: 340 hits после солярного года + 369 до = ретроградные петли захватываются полностью.

Последний коммит продуктового репо — `2e4c394` (2026-05-12, ветка `claude/dreamy-moore-46f5eb`, worktree). Push'нут на backup. Тесты: `cabal test` 242/242 зелёный (+18 новых тестов), `pytest` 82/82 зелёный (+12 новых).

Артефакт для показа Марине: PDF Натальи на новом коммите, `/tmp/astro-natalya-marina-match-iter1.pdf`.

## Ждёт твоего решения

- **Merge ветки `claude/dreamy-moore-46f5eb` в `main`.** Ветка содержит 4 коммита поверх главной: iter-1 transit aspects tables (Tier B, `7b8fd24`), Tier A cascade (`5f4fbc9`), TUNE-1 (`3a12ed3`), TUNE-2 (`2e4c394`). Изменения git topology в продуктовом репо требуют отдельного «ок» — TL не делает merge молча. Когда скажешь — мержим.
- **Когда показать Марине новую версию PDF.** После Tier A cascade'а PDF Натальи содержит существенно более полный transit-блок, чем iter-1. Стоит дать ей посмотреть. Её ответ определит следующие приоритеты.

## Срочные риски

(нет острых)

Один технический не-блокер вытащил Reviewer #2 в качестве кандидата на отдельную небольшую задачу — engine эмитит больше «слабых» transit-passes, чем Марина показывает (она фильтрует своими правилами). Это требует фильтр на стороне презентации (`transit_aspects_table` в Python), отдельная Tier C задача. Без неё PDF корректен, но местами содержит «лишние» строки относительно Марининого формата. Запускать по её комментарию или явному «давай».

Архитектурный drift (фазы 0.1/0.2 prescribed vs реальный код ушёл в 0.5+) — без изменений с 2026-05-10. Не пожар.

## На очереди

Зависит от ответа Марины на новый PDF. Возможные направления (после её feedback'а):

- **Тонкий фильтр transit-passes в презентации** (Tier C, ~30 строк Python) — если Марина скажет «вижу лишние строки».
- **`solar-nodes-lilith-retro-display`** — Tier A, Planet ADT extension + schema cascade. Триггер — её явная просьба видеть эти точки.
- **`consultation-summary-matrix-rewrite`** — переработка матрицы повтора домов.
- **`section-order-recon`** — page-by-page diff с её эталоном для финальной структурной сверки.

Приоритет — её следующая обратка.

## Не делаем сейчас

- **«Solar nodes / Lilith / retro display» без явного запроса от Марины.** Tier A, не «давайте сделаем потому что глифы уже есть».
- **Публичный хостинг репозитория** (GitHub / GitLab / Gitea). Без твоего отдельного «ок» не добавляем.
- **SaaS-направление и B2C-сайт.** Сняты после research'а, проект зафиксирован как внутренний инструмент Марины.
- **Полная сверка архитектурного документа с фактическим кодом.** Откладывается до явного «давай разберёмся».
- **Per-planet калибровка orb'ов на нескольких Marina cases.** Сейчас откалибровано на одном эталоне (Натальин). Расширение калибровки потребует ещё PDF — не приоритет до явного запроса.
