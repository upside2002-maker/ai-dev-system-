# Sitka Office — Next Actions

Дата: 2026-05-19
Snapshot commit: `7b069a7`

Ближайшие практические шаги после общего аудита 2026-05-19/20.
DM-7 Phase A/B/C — закрыты целиком (master `7b069a7`), production
живой с 2026-05-02 на `94.72.112.106:8088`, perimeter close
2026-05-11, auto-deploy включён 2026-05-14.

Текущие mini-tasks и drive-by — в `OPERATING/backlog.md`. Полные
TASK — в `TASKS/`.

## Приоритет 0 — overlay в синхроне с repo

Это постоянный процесс, не разовая задача:

- после каждого заметного milestone обновлять `CURRENT_STATE.md`,
  `NEXT_ACTIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_MAP.md`.
- фиксировать snapshot commit в overlay.
- `check-overlay-consistency.sh` зелёный — обязательное условие
  принятия TASK.

## Приоритет 1 — закрыть оставшийся production-safety backlog

Из общего аудита 2026-05-19 — что осталось после немедленных
фиксов того же дня:

1. **Restore drill из бэкапа.** Контейнер бэкапов запущен 2026-05-19,
   первый дамп лёг. Гипотеза «дамп рабочий» — не проверена.
   Нужен прогон: поднять чистый postgres, накатить последний дамп,
   убедиться что core стартует. ~30 минут + чек-лист в `DEPLOY.md`.
2. **HTTPS + домен.** Frontend bearer auth flow тоже завязан на
   эту работу — без HTTPS он не имеет смысла. Решение:
   договориться с FounderOS об едином nginx 80/443 + наш
   subdomain, либо отдельный Let's Encrypt на 8088 с собственным
   доменом. Класс задачи Tier C ~100-200 LOC + конфигурация на
   сервере.
3. **Audit trail вне `deal_event`** — отдельный append-only event
   stream для операций которые не связаны со сделкой (manual
   expenses, settings changes, channel-account ops). Tier B
   backend, нужен дизайн перед стартом.
4. **Contract / golden tests для всех API endpoint'ов** — сейчас
   они есть выборочно (PR #76 для cashbox snapshot). Прогон по
   списку: что покрыто vs что нет, добавить недостающее.

## Приоритет 2 — Phase D DM-7 (когда триггер от оператора)

Phase D content (widget breakdown по `expense_category.kind`,
графики/аналитика по cashbox, transactions ledger viewer) — без
явного operator UX триггера не приоритет. Backend prerequisite
(`TASKS/2026-04-29-dm7-c-backend-widget-prereq.md`) — DRAFT,
помечен `Mode: strict / Tier A`.

Запускать когда оператор реально захочет breakdown, не раньше.

## Приоритет 3 — мелкие хвосты из backlog

Не блокеры, но видны:

- **Парсер: 2-словные запросы режут валидные товары** (`OPERATING/backlog.md`,
  оператор наткнулся 2026-05-13). Tier C, ~1-3 LOC. Самое
  быстрое улучшение DX парсера.
- **Avito cursor cold-start race** (Codex audit 2026-05-06).
  Tier A backend, ~10-15 LOC. Не теряет данных систематически,
  максимум окно ~60s раз в холодном старте.
- **`recordEvent` на `manual_expense` insert.** Без него
  CashboxWidget не получает event-driven refresh после ручного
  расхода (оператор должен ручками F5). Tier A backend ~10-15 LOC.
- **Frontend localhost build default** в `client.ts:78-80` (Codex
  audit 2026-05-06). Tier C ~3-5 LOC.
- **Парсер калькулятор cleanup** — защита `usdRate < 0`,
  `.parser-calculator-submit` CSS cleanup, неиспользуемый
  `offerSavedCount` prop. Tier C ~25 LOC suite.

## Приоритет 4 — знания и операторские ассистенты

После стабилизации message loop можно безопасно двигать:

- база знаний по моделям (уже seed'нута 2026-05-02 — 284 модели),
- внутренний помощник для оператора,
- структурированная product knowledge,
- инструменты поиска по CRM + knowledge base.

Это следующий слой, не основная задача.

## Не делать

- не возвращать Client-first flow;
- не плодить новые большие подсистемы до стабилизации message loop;
- не тащить knowledge / assistant прямо в runtime core без ясной
  границы;
- не считать старые Phase 0/1 документы текущим roadmap'ом
  (отсутствуют в overlay, для истории — git log);
- не публиковать порты сервисов на 0.0.0.0 без слоя auth (после
  инцидента 2026-05-13/14 это закреплено как инвариант).
