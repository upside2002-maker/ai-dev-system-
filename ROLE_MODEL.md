# Role Model

Единый источник правды по ролям агентов в `ai-dev-system`.

Этот файл фиксирует кто что делает, кто кому передаёт результат, какие модели разрешены, как разрешаются конфликты. Старые `AGENT_ONBOARDING.md` и `AGENT_PLAYBOOK.md` перенесены в [`guides/archive/`](guides/archive/) (2026-04-28); `AGENT_OPERATING_MODEL.md` переименован в [`guides/LAYER_RESPONSIBILITIES.md`](guides/LAYER_RESPONSIBILITIES.md). Текущее состояние — см. секцию ["Что переходное"](#что-переходное) ниже.

## TL;DR

5 ролей. Project Tech Lead — оркестратор каждого проекта. Business Analyst и Reviewer выдают **выводы**, не задачи. Worker исполняет ТЗ от TL. AI Dev System Admin обслуживает сам репозиторий `ai-dev-system`.

```
Пользователь
   │
   ▼
Project Tech Lead          ← оркестратор проекта
   │
   ├──► Business Analyst   (продукт/рынок/юр; режим Research внутри)
   ├──► Reviewer / Red Team (независимая проверка)
   └──► Worker             (исполнение ТЗ; слой = специализация задачи)

AI Dev System Admin        ← обслуживает сам ai-dev-system, в проектную иерархию не входит
```

## Роли

### 1. Project Tech Lead

**Главный технический мозг проекта.**

| Параметр | Значение |
|----------|----------|
| Владеет | архитектура, технические решения, постановка TASKs воркерам, ревью handoff-ов, интеграция результата, арбитраж замечаний Reviewer, перевод BA-выводов в технический план |
| Не владеет | продуктовые решения (это BA → материал даёт BA, решение принимает TL); бизнес-trade-offs |
| Может писать код | patch **≤30 строк, ≤2 файла, не Tier A, без миграций**. Всё больше — через TASK → Worker. |
| Модели | **только Claude Code** (нужна harness/SDK интеграция: hooks, skills, file-ops с full context) |
| Типичный вход | пользователь зашёл с задачей; BA принёс product brief; Reviewer принёс findings |
| Типичный выход | TASK-документ для Worker; решение по Reviewer findings; обновление архитектурного раздела overlay |
| START | `START_<PROJECT>_TECH_LEAD.md` (создаётся в Фазе 2 миграции) |

### 2. Business Analyst

**Продуктовая, рыночная, юридическая, маркетинговая аналитика.**

| Параметр | Значение |
|----------|----------|
| Владеет | продукт, рынок, клиенты, юр/фин, оплаты, каналы, маркетинг, бизнес-trade-offs |
| Не владеет | технические решения, ТЗ воркерам, архитектура |
| Режимы | **(a) Research mode** — greenfield, закрытие блоков вопросов; **(b) Strategic mode** — продуктовые решения по работающему проекту |
| Модели | Claude Code или Codex/GPT (ротация ОК) |
| Типичный вход | пользователь принёс продуктовый/рыночный вопрос; TL отправил уточнить |
| Типичный выход | product brief по форме (см. ["BA-first flow"](#ba-first-flow) ниже) |
| START | `START_<PROJECT>_BUSINESS_ANALYST.md` (создаётся в Фазе 2 миграции) |

### 3. Reviewer / Red Team

**Независимая проверка планов, diff-ов, handoff-ов.**

| Параметр | Значение |
|----------|----------|
| Владеет | findings: ошибки, missing tests, edge cases, нарушения инвариантов, scope creep |
| Не владеет | постановка задач (через TL), ремонт замечаний (это Worker по ТЗ TL) |
| Модели | Claude Code (repo-grounded ревью в стиле проекта) или Codex/GPT (независимый second look / red-team). TL рекомендует, пользователь выбирает на задачу. Двойной ревью — только для рискованных задач. |
| Типичный вход | артефакт от TL/Worker (план, diff, handoff, PR) |
| Типичный выход | Reviewer report → **только TL**, не Worker |
| START | `START_<PROJECT>_REVIEWER.md` (создаётся в Фазе 2 миграции) |

### 4. Worker

**Исполнитель конкретного ТЗ от Tech Lead.**

| Параметр | Значение |
|----------|----------|
| Владеет | код, тесты, миграции по готовому ТЗ |
| Не владеет | продуктовые/архитектурные решения, изменение scope, реакция на Reviewer без подтверждения TL |
| Слои | Core / Services / Frontend — **специализации задачи**, фиксируются в TASK ("Слой: core"), не отдельные роли |
| Модели | Claude Code или Codex (с **isolation rule** — см. [Multi-model protocol](#multi-model-protocol)) |
| Типичный вход | TASK-документ от TL |
| Типичный выход | code commit + acceptance criteria check + handoff TL-у |
| START | `START_<PROJECT>_WORKER.md` (создаётся в Фазе 2 миграции) |

### 5. AI Dev System Admin

**Администратор самого репозитория `ai-dev-system`.**

| Параметр | Значение |
|----------|----------|
| Владеет | гигиена overlay, эволюция методологии (`CLAUDE_GLOBAL`, `ROLE_MODEL`, `AGENT_ONBOARDING`, `corrections`), новые роли, поддержка START-файлов, audit overlay vs реальность |
| Не владеет | продуктовые/архитектурные решения по sitka/astro (это BA + TL соответствующего проекта) |
| Модели | **только Claude Code** (harness control нужен) |
| Типичный вход | drift overlay vs repo; новая ситуация в методологии; пользовательский запрос аудита |
| Типичный выход | правки markdown в `ai-dev-system`, новые corrections, обновление ROLE_MODEL |
| START | [`starts/AI_DEV_ADMIN.md`](starts/AI_DEV_ADMIN.md) |

## TL operational discipline

Применяется к Project Tech Lead в любой проектной сессии. Концептуальные правила; конкретные команды и пороги — в `START_<PROJECT>_TECH_LEAD.md` соответствующего проекта.

### Drift check перед основной работой

Перед стартом задач TL сверяет overlay snapshot с реальным HEAD проекта (для sitka — `git log origin/master -10`; для других проектов — соответствующий main branch). Если drift > 3 коммитов — **первый TASK = refresh overlay** (CURRENT_STATE / OPERATING).

### Small patch rule

См. строку "Может писать код" в роли Project Tech Lead. Конкретные пороги (≤30 строк, ≤2 файла, не Tier A, без миграций) — единые для всех проектов.

### Session rotation triggers

TL стартует свежую сессию (или передаёт через HANDOFF), когда замечает за собой:
- длинные CI-style отчёты (текст ради текста);
- drive-by правки без озвученного плана;
- серия больших правок подряд;
- забываются договорённости из ранее в этой же сессии.

### Local environment ownership

Если TL поднимает окружение или меняет runtime state (миграции, фикстуры, локальные сервисы), фиксирует это в `OPERATING.md` соответствующего overlay или в отдельном runbook. Worker, заходящий после, должен видеть актуальное состояние окружения.

## Стартовые маршруты

Работа с проектом начинается одним из двух flow.

### TL-first flow

**Когда применять:**
- Известно что строить или чинить (баг, понятная фича, продолжение фазы).
- Проект уже активен, продуктовая рамка зафиксирована.
- Нужен только технический план + ТЗ воркеру.

**Поток:**
```
Пользователь → Tech Lead → TASK → Worker → (Reviewer опц.) → TL accept → done
```

**Артефакт TL:** `project-overlays/<slug>/TASKS/<id>.md` по шаблону (шаблон создаётся в Фазе 2).

### BA-first flow

**Когда применять:**
- Greenfield: непонятно что строить.
- Продуктовый вопрос: цены, каналы, юр.рамка, сегмент клиентов, бизнес-модель.
- Архитектурное решение зависит от продуктовой рамки которой ещё нет.

**Поток:**
```
Пользователь → Business Analyst → product brief → Tech Lead → TASK → Worker
```

**Артефакт BA для передачи TL** (обязательная форма):

```
PROBLEM:        что выясняли
CONTEXT:        что узнали (ФАКТ / ГИПОТЕЗА / ВЫВОД)
OPTIONS:        2–4 варианта с trade-offs
RECOMMENDED:    с обоснованием (если есть; "не выбираю" — допустимо)
OPEN QUESTIONS: что требует живого специалиста / решения пользователя
NOT DECIDED:    что специально оставлено TL-у
```

BA **не ставит** задачи воркеру и **не принимает** технических решений (стек, схема БД, API). Это уже работа TL.

### Когда сомневаешься

Начинай с TL: пользователь объясняет что хочет, TL либо берёт это в TASK, либо говорит "это вопрос продуктовый, нужен BA". TL имеет право развернуть пользователя в BA-сессию.

## Координация

1. **Задачи воркеру ставит только Tech Lead.** BA и Reviewer выдают выводы/замечания → TL принимает → TL формулирует ТЗ → Worker исполняет.
2. **Worker не реагирует на замечания Reviewer напрямую.** Только после подтверждения TL.
3. **BA не пишет в код.** Только markdown в overlay.
4. **Reviewer не пишет в код.** Только Reviewer report.
5. **AI Dev System Admin не пишет в проектные слои** (`sitka-*`, `astro/`) — только markdown в `ai-dev-system`.

## Арбитраж конфликтов

### TL × Reviewer

Reviewer **не выше** Tech Lead. Reviewer даёт findings, Tech Lead фильтрует и решает что принять в работу.

**По каждому finding TL фиксирует одно из трёх:**

- **ПРИНЯТЬ** — finding идёт в новый TASK или дополнение текущего.
- **ОТКЛОНИТЬ** — обязательно **остаточный риск явно** (что мы соглашаемся принять как риск).
- **ОТЛОЖИТЬ** — с указанием триггера, по которому вернёмся (после такого-то TASK / в следующей фазе / при таком-то условии).

Фиксация — в TASK, в отдельном arbitration-документе или в HANDOFF к воркеру. Тихое игнорирование finding запрещено.

Если TL и Reviewer расходятся по существенному finding — TL выносит пользователю (см. ниже).

### Пользователь — финальный арбитр

Пользователь подключается к решению, если:
- конфликт не технический, а продуктовый / рисковый;
- TL хочет отклонить существенное замечание Reviewer;
- Reviewer нашёл возможное нарушение инварианта;
- решение влияет на scope, деньги, сроки.

### TL × BA

BA даёт продуктовые выводы. TL **не должен молча игнорировать** BA. Если TL считает, что BA-вывод технически или практически не подходит, он фиксирует trade-off и **выносит решение пользователю**. Пользователь — финальный арбитр.

### Конфликт двух моделей одной роли (BA × BA, Reviewer × Reviewer)

Когда пользователь запросил параллельный ревью / аналитику и две модели разошлись — арбитр Tech Lead. TL читает оба вывода, фиксирует решение в TASK или отдельном арбитражном артефакте.

## Слой ≠ роль

Core / Services / Frontend — это **специализации задачи Worker**, не отдельные роли. Каждая Worker-задача имеет поле `Слой` в TASK-документе. Один Worker = один слой за раз (правило из `CLAUDE_GLOBAL.md`).

Полная карта слоёв и их ответственности — в [`guides/LAYER_RESPONSIBILITIES.md`](guides/LAYER_RESPONSIBILITIES.md).

## Multi-model protocol

### Разрешённые комбинации

| Роль | Claude Code | Codex/GPT |
|------|-------------|-----------|
| Project Tech Lead | ✓ | — |
| Business Analyst | ✓ | ✓ |
| Reviewer | ✓ | ✓ |
| Worker | ✓ | ✓ (с isolation rule) |
| AI Dev System Admin | ✓ | — |

### Дефолтные labels моделей

- **Claude Tech Lead / Admin:** Claude Opus
- **Codex / GPT side:** ChatGPT 5.5 / Codex

Если используется иная конкретная версия — указывать явно.

### Маркировка модели в HANDOFF

Каждый HANDOFF-документ обязан содержать в шапке:

```
Agent runtime: Claude Code | Codex | ChatGPT
Model:         Claude Opus | ChatGPT 5.5 | Codex <если точнее известно>
Role mode:     Tech Lead | Business Analyst | Reviewer | Worker | Admin
```

В commit messages маркировка модели **не обязательна**. Если commit уже содержит `Co-Authored-By` — ОК, но role model не зависит от commit trailers.

### Codex Worker isolation rule

Когда Codex пишет код:
- **отдельный TASK** (не общий с Claude Worker);
- **отдельный write-set** — список файлов явно зафиксирован в TASK-документе;
- **отдельная ветка / worktree.**

**Не параллельно** с Claude Worker по тем же файлам. Это снимает merge-конфликты и неотличимые stylistic divergences.

## Что переходное

Этот документ создан в Фазе 1 миграции на новую модель ролей. Состояние на 2026-04-28:

- **Sitka точки входа по новой модели созданы:** [`project-overlays/sitka-office/starts/{TECH_LEAD,BUSINESS_ANALYST,REVIEWER,WORKER}.md`](project-overlays/sitka-office/starts/).
- **Sitka legacy архивирован:** `START_SITKA_ANALYST.md`, `START_SITKA_CODER.md` → [`project-overlays/sitka-office/starts/archive/`](project-overlays/sitka-office/starts/archive/) с header "ARCHIVED ... ЗАМЕНЁН на ...".
- **Astro точки входа по новой модели ещё не созданы.** Legacy `START_ASTRO_RESEARCH.md` перенесён в [`project-overlays/astro/starts/archive/`](project-overlays/astro/starts/archive/) с header "LEGACY".
- **Старая онтология заархивирована:** [`guides/archive/AGENT_ONBOARDING.md`](guides/archive/AGENT_ONBOARDING.md), [`guides/archive/AGENT_PLAYBOOK.md`](guides/archive/AGENT_PLAYBOOK.md). Файлы фиксируют 5-ролевую модель (Research / Architect / Worker / Analyst / System Owner).
- **`AGENT_OPERATING_MODEL.md` переименован** в [`guides/LAYER_RESPONSIBILITIES.md`](guides/LAYER_RESPONSIBILITIES.md). "Core/Services/Frontend Agent" → "Core/Services/Frontend layer".
- **`START_AI_DEV_MAINTAINER.md` переименован** в [`starts/AI_DEV_ADMIN.md`](starts/AI_DEV_ADMIN.md).
- **`START_LEARNING.md` перенесён** в [`learning/START.md`](learning/START.md) (co-located с `learning/progress.md`).
- **Шаблоны TASKS/HANDOFFS созданы:** [`templates/TASKS_TEMPLATE.md`](templates/TASKS_TEMPLATE.md), [`templates/HANDOFFS_TEMPLATE.md`](templates/HANDOFFS_TEMPLATE.md).
- **Корень очищен:** в корне `ai-dev-system` остались только общесистемные entrypoints — [`README.md`](README.md), [`START_HERE.md`](START_HERE.md), [`CLAUDE_GLOBAL.md`](CLAUDE_GLOBAL.md), [`ROLE_MODEL.md`](ROLE_MODEL.md).

Полный план миграции (фазы 1–5, шаги с риском и порядком) — у текущего AI Dev System Admin в рабочей сессии. После выхода Фазы 1 план будет вынесен в отдельный файл `ROLE_MODEL_MIGRATION.md` или раздел этого документа (решение в Фазе 2).
