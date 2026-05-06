# Tech Lead Learning Plan — AI Agent Control

От пользователя без production-разработки до **компетентного арбитра AI-агентов** в проекте любой сложности.

**Цель:** научиться контролировать AI-разработку (читать TASK, верифицировать diff, ловить confabulation, арбитрировать findings) на **любом стеке**. Sitka — песочница тренировки; навыки переносимы на astro, чужие проекты, любые языки.

**Не цель:** стать senior dev, писать production-код, овладеть Haskell-теорией.

**Ритм:** 4 недели основной части + 2 опциональных. **4 обязательных дня в неделю + 1 optional/review** (catch-up, рефлексия или skip — по самочувствию). 30 минут в день. **Не 5 дней** — мозгу нужны паузы, иначе план срывается.

---

## Принцип: 4 универсальных навыка → 1 проектный

Эти **переносятся куда угодно** (любой язык, любой стек):

1. **Чтение diff с проверкой scope** — "что трогалось vs что обещалось"
2. **Anti-confabulation в чужих claims** — "AI сказал OK; проверим?"
3. **TASK clarity assessment** — "AI поймёт без вопросов?"
4. **Reviewer arbitration** — "ACCEPT / REJECT / DEFER каждое finding с обоснованием"

Эти **специфичны для языка, но принцип универсален**:

5. **5 red-flag categories** — money types / state machine / pure-impure разделение / exhaustive matching / API contracts. В любом языке свои инстансы, **принципы те же**:

```
Money types:
  Haskell:  newtype USD = USD Scientific
  TypeScript:  type USD = number & { __brand: "USD" }
  Python:   class USD(NewType("USD", Decimal))
  Rust:     struct Usd(Decimal)

Exhaustive matching:
  Haskell:  case x of A -> ... ; B -> ...   (compiler warns без всех cases)
  TypeScript:  switch с never-проверкой
  Rust:     match (compiler enforces)
  Python:   match + assert_never (3.10+)
```

Один **принцип**, разные **синтаксисы**. Учим принцип на Haskell, переносим везде.

---

## Неделя 1 — Process & AI literacy fundamentals

**Цель:** научиться ставить понятные TASK и **не доверять** claim'ам AI на слово.

| День | Что | Время |
|------|-----|-------|
| 1 | Открыть `project-overlays/sitka-office/TASKS/archive/` — прочитать **3 закрытых TASK целиком** (не diff, сами TASK документы). По каждому: что хорошо сформулировано, где Worker мог бы спросить уточнение? | 30 мин |
| 2 | Открыть соответствующие 3 HANDOFFs. По каждому: совпадает ли "Done" с "Acceptance criteria" из TASK? Найти один случай "Worker сказал OK, но §Acceptance не полностью покрыт". | 30 мин |
| 3 | **Verify claims без локального запуска** (в первую очередь). Открыть один HANDOFF с claim "tests 539/539 green". Проверить через GitHub PR checks (`gh pr checks <N>` или PR page → Checks tab) + HANDOFF Artifacts section (commit SHA, test counts из CI). Локальный `cabal test` **optional** если хочешь и среда настроена. Цель — понять что claim верифицируем, не угадывать. | 30–45 мин |
| 4 | Найти один Codex Reviewer report (`HANDOFFS/archive/2026-04-29-codex-reviewer-...`). Читать **только Reviewer findings** (прикрыть TL ответ). Какие из findings ты бы accept'ил, reject'ил, defer'ил — с обоснованием? | 30 мин |
| 5 *(optional)* | Написать **свой первый TASK** через `make new-task` для маленькой docs-задачи. Проверить — твой TASK clear для постороннего грамотного человека? Если он понял — AI понял. | 30 мин |

**Контроль конца недели:** одну строку в `progress.md` — что нового заметил про разрыв между "AI claim" и "реальность".

---

## Неделя 2 — Reading diff (universal)

**Цель:** видеть scope изменений в любом языке, не зная синтаксиса глубоко.

| День | Что | Время |
|------|-----|-------|
| 1 | GitHub PR / `git log --stat`: открыть последние 5 merged PR на sitka. Только список файлов в каждом. Совпадает с TASK §Files? | 30 мин |
| 2 | `git diff <merge-base>..<merge-commit> -- <file>` — открыть один PR полностью. Просто читать, не пытаясь понять Haskell-синтаксис. Найти **изменения вне scope** (если есть). | 45 мин |
| 3 | Universal scope-check pattern: `git diff --stat` показывает файлы. Сравнить с TASK §Files **строкой к строке**. Каждое расхождение — flag (или legitimate adjustment). | 30 мин |
| 4 | Lifecycle: запустить `make status`. Что active, что blocked, какой drift. Открыть один blocked TASK — почему `Ready: no`? Что нужно чтобы unblock? | 30 мин |
| 5 *(optional)* | Найти один Reviewer "scope creep" finding в archive HANDOFFs. Что было лишнее? Как это можно было поймать раньше — на этапе TASK formulation? | 30 мин |

**Контроль:** возьми любой случайный merged PR в sitka. За 5 минут скажи: какие файлы тронуты, что обещалось в TASK, был ли scope creep. Не нужна точность Haskell — нужна точность **scope**.

---

## Неделя 3 — 5 universal red-flag categories

**Цель:** видеть категории проблем в чужом коде, не зная языка глубоко.

**Подход:** искать пример **нарушения** или **правильного применения**, и **если не уверен — записать как вопрос** (в `progress.md` секция "Вопросы"). Не охотиться на баги ради охоты — упражнение в распознавании паттернов.

| День | Категория | Что делать |
|------|-----------|------------|
| 1 | **Money types** | Прочитать `Domain/Types.hs` (5 строк). Понять что такое newtype USD. Дальше: открыть любой sitka файл с `Double` или `Scientific` и спросить "это деньги? тогда почему raw?" Найти пример (или зафиксировать что не нашёл — ОК). |
| 2 | **State machine** | Прочитать `Domain/Deal/StateMachine.hs` — список разрешённых transitions. Найти в commit messages "transition" — все ли через SM, или есть direct DB writes? |
| 3 | **Pure vs impure** | Открыть `Engine/Pricing.hs` — нет IO. Открыть `Api/Deals.hs` — IO везде. Принцип: вычисления в Engine, IO в Api. Если Engine получает IO — flag (или вопрос). |
| 4 | **Exhaustive matching** | `grep -E "case.*of" sitka-core/src/Domain/` — посмотреть, есть ли `_ -> ...` (wildcard). Все wildcards на ADT — **вопрос** "почему здесь catch-all?". Иногда это OK, иногда — bug в момент добавления нового конструктора. |
| 5 *(optional)* | **API contracts** | Открыть `Api/Types.hs` — DTOs (`*Req`, `*Resp`). Открыть `Domain/Deal.hs` — domain types. Они **разные**? Если в API использовалось бы Domain напрямую — flag. |

**Контроль:** для 3-х из 5 категорий ты можешь привести **один реальный пример** (нарушение или правильное применение) из sitka. Если не нашёл — это тоже валидный результат, фиксируется как "не нашёл, может быть в другом месте".

---

## Неделя 4 — Practice arbitration

**Цель:** перейти от "читаю/распознаю" к "решаю с обоснованием".

| День | Что | Время |
|------|-----|-------|
| 1 | Открыть `archive/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md`. Прикрыть TL ответ. Прочитать только Reviewer findings. Классифицировать каждое: **ACCEPT / REJECT / DEFER**, с обоснованием для каждого. | 45 мин |
| 2 | Сравнить с реальным TL ответом. **Не считай "совпадения".** Цель — сравнить **аргументацию**. Где TL объяснил лучше, где ты увидел что-то чего он не упомянул, где разошлись — почему? | 30 мин |
| 3 | Открыть один merged PR за **последний месяц** (#76 / #77 / #78). Написать **свой Reviewer report** до того как смотреть реальный CI или existing review. Что бы ты flag'нул? | 60 мин |
| 4 | Сравнить с реальным CI / Reviewer review (если был). Что пропустил? Что false-positive? Что увидел сам что они пропустили? | 30 мин |
| 5 *(optional)* | Reflective: за месяц где ты чаще ошибался — в scope, в logic, в style? Это твоя **личная weakness**, на ней focus в дальнейшем. | 30 мин |

**Контроль конца недели 4:** возьми один merged PR на **любом языке** (open-source, github trending, что угодно). Прочитай. Можешь ли сказать: какие файлы трогает, что обещает (если есть PR description), какие могут быть scope issues? Если **да на любом языке** — навык transferable.

---

## Опциональные Недели 5–6 — Cross-stack transfer

Если хочешь reinforce.

| Неделя | Цель | Material |
|--------|------|----------|
| 5 | Same skills на Python (когда astro подключится к Phase 0) или на чужом open-source проекте на Python/TS. Применить universal red-flag categories к non-Haskell коду. | astro PRs или любой Python/TS проект |
| 6 | Самотест: возьми проект на 100% незнакомом языке (Rust, Go, Elixir). Можешь ли применить scope check + 5 categories? Если да — навык по-настоящему transferable. | github trending или твой выбор |

---

## Daily ritual (15 минут — сократил до минимума чтобы не срывалось)

Утром:
1. **Один раздел** из любого archive HANDOFF/TASK (не файл целиком, **раздел**). 5 минут.
2. **Одна строка в `journal.md`**: что заметил. 2 минуты.

Вечером (если работал с AI):
3. **Что AI сделал, что я бы скорректировал?** Одна строка. 5 минут.

Без weekend journals. Без длинных записей. Чем короче — тем выше шанс что не забросишь.

---

## Что НЕ делать

- **Не читать книги по Haskell.** Реально не нужно для контроля. Если хочешь Haskell как hobby — отдельная история, не часть этого плана.
- **Не учить категориальную теорию, monad transformers, type families, GADTs.** Это для написания, не для чтения.
- **Не пытаться писать sitka код сам.** Время лучше потратить на ревью.
- **Не заводить отдельную ADR-практику в первые 4 недели.** Важные решения фиксировать в `TASK` (что и почему), `HANDOFF` (что сделано и какие trade-offs), и в `DECISIONS` если когда-то заведём отдельный лог. Формальный ADR — это для команды разработчиков; у тебя AI-роли + ai-dev-system, своя equivalentная дисциплина уже работает.
- **Не пытаться делать всё каждый день.** 4 + 1 ритм — 1 день optional/review.
- **Не пытаться угадать TL.** Цель — научиться **аргументировать**, а не заматчить чужой ответ.

---

## Контрольные точки

| Через | Должен уметь |
|-------|--------------|
| 2 недели | Открыть случайный merged PR в sitka и за 5 минут сказать: scope ОК, scope creep, или какие файлы под подозрением |
| 4 недели | Прочитать пару TASK + HANDOFF и **до** реального TL ответа классифицировать findings ACCEPT/REJECT/DEFER **с обоснованием по каждому**. Сравнить **аргументацию** с реальным TL ответом — что вы оба увидели одинаково, что разошлось, что один из вас пропустил |
| 6 недель *(опционально)* | Применить те же навыки к проекту на незнакомом языке. Не понимать каждую строчку, но видеть scope, red-flag categories, AI claim verification |

---

## Перенос на проекты любой сложности

После 4 недель навыки **уже** transferable. На новом проекте (любой язык, любой стек):

1. **Scope check via diff** работает идентично — `git diff --stat` показывает file list, сравниваешь с TASK
2. **AI claim verification** работает идентично — CI badges, HANDOFF Artifacts, optional local run
3. **TASK clarity** оценивается одинаково — может ли посторонний грамотный человек понять scope?
4. **Reviewer arbitration** одинаково — ACCEPT / REJECT / DEFER с обоснованием
5. **5 red-flag categories** — нужно один раз посмотреть instances в новом языке (например `class USD(NewType("USD", Decimal))` в Python вместо Haskell newtype). Принцип не меняется.

Это твой **универсальный набор**. Sitka — где ты его натренировал. Astro / любой будущий проект — где ты его применяешь.

---

## Приложение: где взять real artifacts для упражнений

| Что | Где |
|-----|-----|
| Closed TASKs | `project-overlays/sitka-office/TASKS/archive/` — десяток штук, начни с самых поздних |
| Closed HANDOFFs | `project-overlays/sitka-office/HANDOFFS/archive/` — около 10, включая Codex Reviewer |
| Codex Reviewer report (для Week 4 День 1) | `archive/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md` |
| Recent merged PRs | `gh pr list -R upside2002-maker/sitka-office --state merged --limit 10` |
| Domain.Types.hs (Week 3 День 1) | `/Users/ilya/Projects/sitka-office/sitka-core/src/Domain/Types.hs` |
| StateMachine (Week 3 День 2) | `/Users/ilya/Projects/sitka-office/sitka-core/src/Domain/Deal/StateMachine.hs` |
| Engine.Pricing (Week 3 День 3) | `/Users/ilya/Projects/sitka-office/sitka-core/src/Engine/Pricing.hs` |
| Api.Deals (Week 3 День 3 контраст) | `/Users/ilya/Projects/sitka-office/sitka-core/src/Api/Deals.hs` |
| Api.Types (Week 3 День 5) | `/Users/ilya/Projects/sitka-office/sitka-core/src/Api/Types.hs` |

---

**Главное правило:** работай с **реальными артефактами** твоей системы (TASK / HANDOFF / diff / Reviewer report), не с абстрактными tutorial'ами. Каждый материал применяй к sitka сразу. Принципы и vocabulary, которые усвоишь — переносимы.
