# Global Corrections

Повторяющиеся ошибки агентной разработки. Не project-specific мелочи, а паттерны, которые встречаются в разных проектах и сессиях.

---

## Correction 001: Не тащить domain decisions в integration layer

**BAD:**
- Python/FastAPI сам решает финальный статус сделки;
- parser service назначает business meaning найденным данным.

**GOOD:**
- Integration layer только собирает, нормализует и отправляет данные в core;
- финальный смысл, статус и валидность определяет core.

**WHY:** Иначе инварианты расползаются и система становится непредсказуемой.

---

## Correction 002: Не строить UI вокруг внутренней архитектуры

**BAD:**
- Пользователь должен понимать, что такое `quoted`, `sourcing`, `in_stock`;
- на экране одновременно много равноправных блоков без главного действия.

**GOOD:**
- Интерфейс показывает stage, next action и outcome;
- технические термины спрятаны или переведены в операторский язык.

**WHY:** Операционный UI должен сокращать время до действия, а не демонстрировать устройство системы.

---

## Correction 003: Не путать pre-deal и active deal

**BAD:**
- Сделка создаётся слишком рано, ещё до отбора результатов;
- pre-deal sourcing и active deal workflow смешаны в одной сущности.

**GOOD:**
- Сначала собираем варианты (pre-deal sourcing);
- потом создаём сделку на основе выбранных данных;
- сделка начинается когда есть осмысленный пакет входных данных.

**WHY:** Так проще менеджеру и чище модели данных.

---

## Correction 004: Type safety теряется на границах

**BAD:**
- Domain model использует newtypes (USD, RUB, DealStatus), но DB schema и API types используют raw Double и Text;
- типы "сильные" внутри, но "слабые" на входе и выходе.

**GOOD:**
- PersistField instances для каждого domain newtype;
- JSON instances для transport types с domain newtypes;
- type safety end-to-end: domain → DB → API → client.

**WHY:** Если типы теряются на границах, newtype wrapper — просто лишний код. Баг "перепутал USD и RUB" скомпилируется и молча испортит данные.

---

## Correction 005: Не сравнивать метрики разных каналов как одну цифру

**BAD:**
- "Потратили 101K₽ на Avito, заработали 69K₽ на Avito → убыток 32K₽";
- сравнение расходов на lead gen с доходами от другого канала продаж.

**GOOD:**
- Расходы на Avito = стоимость лидогенерации (101K₽ → 182 контакта = 559₽/лид);
- доход от заказов = отдельная метрика (прямые переводы, не через Avito);
- ROI считается по полному циклу: лиды → заказы → выручка.

**WHY:** Ложный вывод "бизнес убыточен" ведёт к неправильным решениям. Avito — канал привлечения, не канал продаж.

---

## Correction 006: Не тащить операционные данные в Core

**BAD:**
- Note (заметки), Decision (решения), ConversationMessage (тело сообщений) описаны как Haskell entity в Core с PersistField и tagged JSON;
- "положу в Core потому что это бизнес-важно" / "там надёжнее";
- catalog of products, listings inventory, message logs — всё в Haskell core.

**GOOD:**
- Operational data → Services (Python + Postgres):
  - Note, Decision, ConversationMessage, raw payloads, message attachments, search indices;
  - всё что часто меняется, не имеет инвариантов, накапливается логом.
- Core хранит только references и audit markers:
  - `NoteAdded` event type в EventType ADT — да;
  - `Note` entity с body+tags+author — нет, это в Services.
- Аналогия: ConversationThread (метаданные с FK к Deal) → Core; ConversationMessage (тело) → Services. Точно так же: Note attachment к Deal → ссылка/event в Core, само тело Note → Services.

**WHY:**
- У operational data нет бизнес-инвариантов, которые надо охранять типами.
- Type safety на уровне Haskell не даёт ценности для плоского текста с автором и тегами.
- Каждое поле в Core требует миграции, ADT, PersistField, JSON instance, тестов. Для логов и заметок это лишние 100+ строк кода без бизнес-выгоды.
- Свобода добавлять поля (теги, attachments, summary, FTS) без касания Core.
- Поиск/индексация настраиваются в Services специализированными инструментами (Postgres FTS, Elasticsearch).

**Тест себя:** "У этой entity есть бизнес-инвариант который должен быть проверен на компиляции?" Если нет — операционные данные → Services.

---

## Correction 007: Внешние правки overlay требуют контекста

**BAD:**
- Коммит "refresh sitka overlay" удаляет нумерованные issues.
- В commit message не объяснено что это рефакторинг и какие issues закрыты / устарели / переформулированы.
- Следующий аудит-агент видит "потерю данных" и предлагает откат.

**GOOD:**
- Commit message кратко объясняет что и почему изменилось.
- Если issues закрыты — пометить какие и почему.
- Если переформулированы — указать что объединено.
- Audit-агенты могут доверять рефакторингу, а не реконструировать намерение.

**WHY:** Overlay читают много агентов. Без контекста изменений каждый новый агент тратит время на "это потеря или намерение?". Дешевле один раз объяснить в commit, чем N раз отвечать "это намеренно".

---

## Correction 008: Worker не двигает Status TASK после HANDOFF

**BAD:**
- Worker subagent заканчивает работу: пишет HANDOFF файл через `make new-handoff`, заполняет body (Summary/Done/Remaining/Artifacts/Conflicts/Next step), но **не трогает Status в TASK файле**.
- TASK остаётся `Status: open` (или `in-progress`).
- TL пытается `make accept-task` — Phase A lifecycle gate refuses (`Status must be 'review'`).
- TL вынужден ручным edit'ом перевести Status: open → review перед accept-task.

**GOOD:**
- Worker, закончив работу и записав HANDOFF, **сам же** делает финальный edit TASK: `Status: in-progress` → `Status: review`.
- Либо есть отдельный helper `scripts/submit-task.sh` который Worker вызывает в конце (`make submit-task FILE=...`) — bumps Status и оставляет HANDOFF open.
- TL после accept-handoff делает только `make accept-task` без preceding manual edit.

**WHY:** Lifecycle gate в `accept-task.sh` требует Status=review. Пока Worker этого не делает, каждый accept требует ручного шага TL — это шум, скрывающий реальные ошибки. Либо Worker инструкции должны явно требовать bump, либо helper'ы должны взять это на себя.

---

## Correction 009: Reviewer возвращает отчёт через stdout, не через файл

**BAD:**
- Reviewer subagent (`.claude/agents/sitka-reviewer.md`) проверяет diff и возвращает отчёт **через subagent return value** (текстом в stdout).
- Никакого файла `HANDOFFS/<date>-reviewer-to-tl-*.md` не создаётся.
- TL видит отчёт только в текущей сессии; через час/день/новую сессию — нет следа что review произошёл.
- Audit history теряется. Невозможно ответить "а кто и когда review'ил TASK X?".

**GOOD:**
- Reviewer subagent в конце работы создаёт HANDOFF файл через `make new-handoff` с From: reviewer / To: tl, заполняет body отчётом (verdict / findings / blockers / recommendations).
- Stdout-возврат — короткое summary с ссылкой на созданный файл.
- TL `make accept-handoff` закрывает review-handoff явно.

**WHY:** HANDOFF — единственный механизм audit trail между ролями. Stdout исчезает с концом сессии. Без файла Reviewer pass — это invisible step, который проблематично доказать постфактум при конфликте/ретроспективе.

---

## Correction 010: PR/commit даты — только из git log, никогда из памяти

**BAD:**
- Worker (или любой агент) в HANDOFF / docs пишет даты PR'ов "по памяти" из контекста сессии: `PR #74–#78 (2026-04-29 → 2026-05-04)`.
- Реальные merge-даты другие: `git log --grep='#74\|#78'` показывает 2026-05-01 → 2026-05-02.
- Ошибка проползает в design doc / status file / public docs. Со временем становится "канон" — другие агенты доверяют доку, drift накапливается.

**GOOD:**
- Любая дата PR / commit / merge в HANDOFF, design docs, overlay status — выводится **только** через `git log --oneline --grep='#NN' --pretty=format:'%h %ad' --date=short` или `gh pr view NN --json mergedAt`.
- Если у агента нет доступа к git/gh — пишет "TBD" / "see git log" вместо угадывания.
- TL/Reviewer при проверке HANDOFF spot-check'ает даты против `git log`.

**WHY:** Даты — facts, а не opinions. Confabulated даты ломают audit trail и хуже того — становятся source-of-truth в design docs, заражая будущие сессии. Стоимость проверки одной даты `git log --grep` — 1 секунда. Стоимость найти и поправить drift через месяц — часы.

---

## Correction 011: Same-session role switching for product-code tasks weakens isolation

**BAD:**
- TL пишет TASK для Tier B/A product-code, и **в той же сессии** играет Worker'а: читает grounding, делает edit'ы, гоняет тесты, оформляет HANDOFF.
- В той же сессии (или следующим turn'ом, не из cold-start) играет Reviewer'а: "проверяет" свой же diff и подтверждает что всё хорошо.
- HANDOFF выглядит правильно, lifecycle gates прошли, audit trail формально есть. Но independent second look отсутствует — это была одна и та же модель, в одном контексте, с одинаковыми anchoring biases.
- Регрессия в core/math/visual invariants проползает в commit, потому что reviewer-self не увидел того, что worker-self не учёл.

**GOOD:**
- Tier B (с core/math/visual/user-facing invariants) и Tier A — **отдельный Worker subagent по умолчанию** (cold-start, без session memory). TL отправляет subagent'у TASK файл и role definition; subagent работает не зная контекста TL-сессии.
- Tier A — **дополнительно отдельный Reviewer subagent** в отдельной сессии. Reviewer видит только финальный артефакт (TASK + diff + HANDOFF), не промежуточные мысли Worker'а.
- Tier C mechanical product write — same-session разрешён, но TASK содержит body-marker `Execution isolation: same-session TL inline accepted (Tier C mechanical)`, чтобы выбор был зафиксирован, а не молчаливо принят.
- docs-only / recon — same-session по умолчанию OK.
- Если TL не может обеспечить требуемую изоляцию (нет харнеса для subagent'а, нет модели для Reviewer'а) — **останавливается и спрашивает пользователя**. Не тихо понижает tier "чтобы сделать сейчас".

**WHY:** Multi-role модель имеет смысл только если роли действительно независимы. Same-session switching ломает три механизма одновременно: anchoring (Worker уже принял решения, reviewer-self их инстинктивно защищает), pattern-completion (та же модель рекомбинирует те же образцы, без свежего взгляда), audit trail (HANDOFF внутри одной сессии — запись, не передача; ошибки "у обоих" одновременно). Cost spawn'а subagent'а — секунды; cost регрессии в Tier A — часы или сутки. Default policy — изоляция, см. [`ROLE_MODEL.md` § Role isolation by risk tier](../ROLE_MODEL.md).

---

## Correction 012: Mode misuse — выбор для удобства, не по риску

**BAD:**
- `Mode: light` ставится на задаче класса B потому что хочется закрыть её быстрее — без отдельного Worker subagent'а, без Reviewer'а, в одной сессии TL.
- `Mode: strict` ставится на тривиальной docs-правке (например обновление `STATUS_RU.md` после accept'а) "из перестраховки" — поднимается отдельный Worker subagent + отдельный Reviewer subagent ради двух строк изменения.
- Mode не указывается, в шапке вместо явного значения — `TBD` или пустое поле; решение что считать «мерой ceremony» откладывается на момент выполнения и принимается тихо.

**GOOD:**
- Mode выбирается по таблице соответствия из [`policies/MODES.md`](../policies/MODES.md): C → `light`, B → `normal`, A → `strict`, ad-hoc разведка → `preview`.
- Отклонение от default'а допустимо, но фиксируется в самой задаче в разделе «Контекст» с одним предложением обоснования (например: «формально B, но trogает только legacy fixture без runtime-эффекта — light»). Без обоснования — это либо подгонка под скорость, либо страх.
- Tier A без `Mode: strict` — отказ `accept-task` гейтом, не вопрос дисциплины. Понизить tier "чтобы взять в light" запрещено отдельно (см. также Correction 011).

**WHY:** Режим имеет смысл только когда выбран по риску. Если он выбирается ради удобства (вниз) — маскирует риск; если из перестраховки (вверх) — маскирует затраты. Обе крайности убивают саму ось: исчезает сигнал "эта задача требует больше внимания, чем обычно" и сигнал "эта мелкая, не тратьте на неё час". Режим без обоснованного выбора превращается в декоративное поле в шапке и через две недели игнорируется. См. [`policies/MODES.md`](../policies/MODES.md) — таблица соответствия и описание четырёх режимов.

---

## Correction 013: Operator-facing messages must not expose internal agent jargon

**BAD:**

- TL пишет пользователю: «Code-side: ACCEPT. pytest 80/80. Render clean. Verdict? ACCEPT / TUNE / REJECT».
- Сессия деплоя выдаёт оператору: «curl -i http://94.72.112.106:8088/ → 401 Unauthorized. healthcheck overrid'нут на /health. docker compose up -d --force-recreate web core services».
- Worker / Reviewer пишет напрямую пользователю с тегами `acknowledged`, `accepted`, `Status: review`, ссылками на `HANDOFFS/<id>.md`.
- TL пересказывает пользователю отчёт проверяющего «как есть» — со словами `blocker`, `Tier B`, `fixture`, `golden case` без перевода.
- Промпт для downstream-сессии не запрещает явно жаргон в адрес пользователя — внутренние термины проникают через downstream обратно к оператору.

**GOOD:**

- TL: «Кодовая проверка прошла. PDF собрался без сбоев. Сейчас нужно только посмотреть глазами: устраивает ли вид таблицы на странице 10?»
- Сессия деплоя: «Касса теперь под паролем. Перепроверил три вещи: без пароля не пускает, с паролем пускает, внутренние входы снаружи больше не открываются.»
- Worker / Reviewer пишет техлиду на внутреннем языке, TL переводит для пользователя.
- TL формулирует выбор пользователю как человеческий вопрос: «устраивает или нет?», «перезапускаем кассу или нет?», «показываем Марине эту версию или ещё доработать?».
- Промпт для downstream-сессии содержит явный блок «как разговаривать с пользователем» с перечислением запрещённых терминов и BAD/GOOD парами.

**WHY:** Пользователь управляет продуктом, не внутренней агентной машиной. Англо-техническая смесь ломает доверие, увеличивает когнитивную нагрузку и превращает систему в шум — оператор видит «какую-то еболу» и теряет управление. Внутренний язык должен оставаться внутри `TASKS/`, `HANDOFFS/`, commit messages и технических отчётов между агентами. Наружу выходит понятный русский пульт управления — что делается, какой риск, что нужно от пользователя, получилось или нет. Полный закон и таблица переводов — в [`CLAUDE_GLOBAL.md` → «Главный закон общения с пользователем»](../CLAUDE_GLOBAL.md). См. также Correction 007 (внешние правки overlay требуют контекста) — отдельный случай той же дисциплины: объяснять «зачем», а не дампить «что».

---

## Как добавлять новые записи

Формат:
```
## Correction NNN: Краткое описание

**BAD:** Что агент сделал неправильно
**GOOD:** Как должно быть
**WHY:** Почему это важно
```

Добавлять когда:
- Ошибка повторилась в разных сессиях или проектах.
- Ошибка не ловится lint/compile — только human review.
- Паттерн достаточно общий чтобы встретиться снова.
