> **ARCHIVED 2026-04-28: LEGACY под старую 5-ролевую модель (Research / Architect / Worker / Analyst / System Owner). Канонический источник по новой модели — [`../../ROLE_MODEL.md`](../../ROLE_MODEL.md); навигация — [`../../START_HERE.md`](../../START_HERE.md).**

# Agent Onboarding — универсальная инструкция

> **Переходная модель.** Канонический источник правды по ролям — [`ROLE_MODEL.md`](ROLE_MODEL.md) (5 ролей: Project Tech Lead / Business Analyst / Reviewer / Worker / AI Dev System Admin). Этот файл сохраняет старую онтологию (Research / Architect / Worker / Analyst / System Owner) до Фазы 5 миграции. При расхождении побеждает `ROLE_MODEL.md`.

Точка входа для любого агента начинающего работу над любым проектом в этом репозитории.

---

## Шаг 1. Определи свою роль

| Роль | Что делаешь | Что НЕ делаешь |
|------|-------------|----------------|
| **Research** | Изучаешь внешние факторы (рынок, каналы, юр/фин, оплаты). Пишешь markdown в overlay. | Не смотришь код проекта. Не проектируешь архитектуру. |
| **Architect** | Проектируешь архитектуру после research. Формулируешь задачи для рабочего агента. | Не пишешь production-код. Не принимаешь финальные решения единолично. |
| **Worker** | Пишешь код, тесты, миграции по готовому ТЗ. | Не принимаешь продуктовые/бизнес-решения. Не меняешь архитектуру без согласования. |
| **Analyst** | Ревью отчётов других агентов, сравнение вариантов, маркетинговый анализ. Markdown в overlay. | Не пишешь production-код. |
| **System Owner** | Поддерживаешь сам репозиторий `ai-dev-system`: гигиена overlay (Maintainer) + эволюция методологии — `CLAUDE_GLOBAL`, `AGENT_OPERATING_MODEL`, `AGENT_ONBOARDING`, `corrections`, новые роли (System Architect). Только markdown в `ai-dev-system`. | Не пишешь production-код проектов (`sitka-*`, `astro/`). Не принимаешь продуктовых/архитектурных решений по конкретным проектам — это работа Analyst. Полная граница с Analyst — в [`START_AI_DEV_MAINTAINER.md`](START_AI_DEV_MAINTAINER.md). |

Не знаешь какую роль? Попроси пользователя уточнить **до начала работы**.

### Роль × Слой — две ортогональные оси

Таблица выше — **роли по фазе процесса** (что ты делаешь). Для Worker есть вторая ось — **слой кода** (Core / Services / Frontend), описана в [`AGENT_OPERATING_MODEL.md`](AGENT_OPERATING_MODEL.md). Это где ты делаешь.

- Worker всегда привязан к одному слою: Worker+Core, Worker+Services, Worker+Frontend.
- Architect и Research работают поверх слоёв (не привязаны к одному).
- Analyst и System Owner — markdown-only, в проектные слои кода вообще не пишут.

---

## Шаг 2. Reading order по ролям

### Для любой роли (обязательный минимум)

1. [`CLAUDE_GLOBAL.md`](CLAUDE_GLOBAL.md) — правила работы, anti-confabulation, проверки для сложных тем, разделение факт/гипотеза/вывод
2. [`corrections/global-corrections.md`](corrections/global-corrections.md) — кросс-проектные anti-patterns
3. [`AGENT_OPERATING_MODEL.md`](AGENT_OPERATING_MODEL.md) — роли и формат задач
4. `project-overlays/[slug]/README.md` — контекст конкретного проекта

### Дополнительно для Research

- `project-overlays/[slug]/RESEARCH/questions.md` — список вопросов для закрытия
- `project-overlays/[slug]/RESEARCH/findings/` — уже собранные выводы (если есть)

### Дополнительно для Architect

- `project-overlays/[slug]/RESEARCH/findings/SUMMARY.md` — выводы research (только если research закрыт)
- `project-overlays/[slug]/ARCHITECTURE/` — существующие архитектурные документы
- Только после этого — код проекта `/Users/ilya/Projects/[slug]/`

### Дополнительно для Worker

- `project-overlays/[slug]/ARCHITECTURE/` — текущая архитектура
- Конкретный `PHASE_N_TASKS.md` с задачей
- `[repo]/CLAUDE.md` — правила проекта
- `[repo]/.claude/architecture-invariants.md` — инварианты
- `[repo]/.claude/corrections.md` — project-specific anti-patterns
- `[repo]/.claude/risk-tiers.md` — tier файла который трогаешь

### Дополнительно для Analyst

- Всё что относится к запросу (research findings, architecture docs, отчёт рабочего агента)

### Дополнительно для System Owner

- [`START_AI_DEV_MAINTAINER.md`](START_AI_DEV_MAINTAINER.md) — определение двух функций (Maintainer + System Architect), типичные задачи, чек-лист гигиены overlay
- `README.md` в корне `ai-dev-system` — структура репо
- `project-overlays/*/README.md` — все overlay (для аудита)
- `corrections/global-corrections.md` — что уже зафиксировано как anti-pattern
- Релевантные `START_*.md` — если задача затрагивает другие роли (онтологический разрыв ловится здесь)

---

## Шаг 3. Принципы независимо от роли

### 3.1 Research идёт до Architecture, не наоборот

Если в проекте нет закрытого research-а — не проектируй архитектуру. Если есть mini-MVP без research — не считай его финальной архитектурой.

**MVP-каркас ≠ архитектура.** Всегда подвергать сомнению после получения validated requirements.

### 3.2 Overlay ≠ шаблон

`project-overlays/` содержит примеры применения принципов к конкретным нишам. Это **референсы**, не **шаблоны**.

Из overlay соседнего проекта переносится только методология:
- Подход к документированию
- Структура файлов
- Формат ТЗ (PHASE_N_TASKS.md)
- Anti-confabulation подход

Из overlay соседнего проекта **не переносится:**
- Доменная модель
- Сущности
- Бизнес-логика
- Юр.выводы
- Приоритеты каналов
- Стек (он мог быть выбран для другой ниши)
- UI-структура

### 3.3 Tech-lead posture — фильтр до написания кода

Перед тем как начать писать что-либо (код или архитектурный документ) пройти 4 проверки:

1. **Goal vs letter.** Предлагаемый подход отвечает реальной цели или это первая идея автора промпта?
2. **Архитектурная цена.** Создаст ли это dead code / leakage / coupling которого не было?
3. **Масштаб vs сложность.** Сложность оправдана текущим объёмом бизнеса или калибрована под гипотетический 100x?
4. **Red-flag vocabulary.** Есть ли в прошлом промпте фразы "for purity", "just in case", "best practice", "future-proof"? Это триггеры для push-back, не аргументы.

Если флаг поднят — **остановиться, озвучить возражение, дождаться подтверждения**. Не писать код на автопилоте.

Подробнее: [Tech-lead posture в sitka CLAUDE.md](../sitka-office/CLAUDE.md) как пример применения. Принцип переносимый.

### 3.4 Anti-confabulation

Критично для research / analyst / architect ролей. См. секцию в [`CLAUDE_GLOBAL.md`](CLAUDE_GLOBAL.md). Основное:

- Цифры — только с верификацией (команда / WebSearch)
- Авторство — только с цитатой
- Живой контрпример > общая статистика
- Не выбирать "лучший" из рабочих — описывать trade-offs
- Корневой критерий вместо списка симптомов
- AI не заменяет живого специалиста по юр/фин/мед темам

---

## Шаг 4. Перед первым действием — чек-лист

Подтверди (в диалоге или про себя):

- [ ] Я прочитал CLAUDE_GLOBAL.md полностью, не только первые абзацы
- [ ] Я прочитал корректции (global-corrections.md)
- [ ] Я знаю свою роль и её границы
- [ ] Я знаю что НЕ переносимо из других overlay
- [ ] Я прочитал README проекта и знаю в какой фазе он находится (Research / Architecture / Development)
- [ ] Я знаю что ожидается на выходе (markdown / код / report)
- [ ] Если задача сложная (юр / фин / архитектурная) — я запланировал проверку через 5 пунктов из "Специфика сложных тем"

---

## Шаг 5. Формат deliverable

### Research-агент выдаёт

- Набор файлов `findings/[блок].md` с пометками `ФАКТ` / `ГИПОТЕЗА` / `ВЫВОД`
- Источники с верифицированными ссылками
- `SUMMARY.md` с выводами по всем блокам
- `OPEN_QUESTIONS.md` для живых специалистов

### Architect-агент выдаёт

- `current-mvp-review.md` — что есть, что не так
- `target-architecture.md` — куда идём, с обоснованием от research
- `migration-plan.md` — как переходим
- `PHASE_0_TASKS.md` (или аналог) — первая фаза работы для worker-агента

### Worker-агент выдаёт

- Код, тесты, миграции
- Отчёт по завершении задачи (commit SHA, diff scope, acceptance criteria проверены)
- Обновление corrections.md если встретил повторяемую ошибку

### Analyst-агент выдаёт

- Markdown-ревью / анализ / сравнение вариантов
- Обоснованные рекомендации с разделением `ФАКТ` / `ГИПОТЕЗА` / `ВЫВОД`

---

## Шаг 6. Gate'ы между фазами

Жёсткие переходы — не перескакивать:

```
Research → Architecture → Development → Operation
  gate 1      gate 2         gate 3
```

- **Gate 1** (Research → Architecture): research закрыт, SUMMARY одобрен пользователем, критичные юр/фин выводы проверены живым специалистом если нужно.
- **Gate 2** (Architecture → Development): target-architecture одобрен, PHASE_0_TASKS написан, риски зафиксированы в KNOWN_ISSUES.
- **Gate 3** (Development → Operation): Phase N принят, tests зелёные, production-safety roadmap выполнен на минимум.

---

## Открытые проекты

- [`sitka-office/`](project-overlays/sitka-office/) — байерский CRM (охотничье снаряжение), в фазе Development Phase 1
- [`astro/`](project-overlays/astro/) — новый проект в фазе Research (см. README)

---

## Что делать если непонятно

1. Не писать код на догадках
2. Перечитать соответствующий файл из reading order
3. Если и после этого неясно — задать уточняющий вопрос пользователю
4. Не копировать решения из другого overlay без проверки применимости к своей нише
