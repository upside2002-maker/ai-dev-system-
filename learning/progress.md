# Прогресс обучения

Дата начала: 2026-04-18
Дата пересборки плана: 2026-05-04

**Цель (после пересборки 2026-05-04):** AI agent control + light technical literacy. Уметь читать TASK / diff / claims / Reviewer findings и арбитрировать AI работу — на проектах любой сложности (любой стек, любой язык). Sitka — песочница тренировки. **Не цель:** становиться senior dev или senior Haskeller.

Полный план: [`/Users/ilya/Projects/ai-dev-system/learning/TECH_LEAD_PLAN.md`](TECH_LEAD_PLAN.md)

---

## Текущий статус

**Где я:** план перебран 2026-05-04 под новую цель (AI agent control, не Haskell-dev). Pre-week setup (GitHub Desktop + conventional commits + diff format) **уже сделан** в Дни 1-2 старого плана — это полезная база для Недели 2 нового плана (Reading diff).

**Следующий шаг:** Неделя 1, День 1 нового плана.

> Открыть `project-overlays/sitka-office/TASKS/archive/` — прочитать **3 закрытых TASK целиком** (не diff, сами TASK документы). По каждому: что хорошо сформулировано, где Worker мог бы спросить уточнение?

Время: 30 минут. Можно начать в любой день когда есть 30 минут.

---

## План (кратко) — после пересборки 2026-05-04

| Неделя | Тема | Статус |
|--------|------|--------|
| pre | GitHub Desktop + conventional commits + diff format (старый план Дни 1-2) | ✅ Закрыто 2026-04-24 |
| 1 | Process & AI literacy fundamentals (TASK / HANDOFF / claims verification / Reviewer findings) | ⬜ Следующая |
| 2 | Reading diff (universal scope check) | ⬜ |
| 3 | 5 universal red-flag categories (money / state / pure-impure / exhaustive / API contracts) | ⬜ |
| 4 | Practice arbitration (ACCEPT / REJECT / DEFER с обоснованием) | ⬜ |
| 5 *(opt)* | Cross-stack transfer на Python/TS (astro когда подключится, или open-source) | ⬜ |
| 6 *(opt)* | Самотест на проекте на незнакомом языке (Rust / Go / Elixir) | ⬜ |

Ритм: **4 обязательных дня в неделю + 1 optional/review.** 30 минут в день.

---

## Pre-week setup (закрыт)

### Установка GitHub Desktop ✅ (2026-04-18)

- [x] Скачать [desktop.github.com](https://desktop.github.com/)
- [x] Войти своим GitHub аккаунтом
- [x] File → Add Local Repository → выбрать `/Users/ilya/Projects/sitka-office`
- [x] Проверить что видны ветки и история

### Смотрим старые коммиты ✅ (2026-04-24)

- [x] Открыть вкладку History в GitHub Desktop
- [x] Посмотреть 10 последних коммитов
- [x] Прочитать названия, понять префиксы (feat/fix/chore/test)
- [x] Открыть коммит `db4f541` (alias /help), прочитать описание, увидеть diff
- [x] Сформулировать своими словами **зачем** агент это сделал

**Что усвоил:**
- Conventional commit prefixes: feat / fix / chore / test / refactor / docs
- Формат diff: `@@ -111,6 +111,12 @@` = координаты изменения; `+` = добавлено, `-` = удалено
- Хороший признак: переиспользование функции вместо копипаста
- Хороший признак: комментарий-предупреждение для следующего агента
- Хороший признак: маленький коммит (1 файл, 6 строк) ревьюить легче

**Замечание про репо:** в последних 30 коммитах 17 fix vs 7 feat. Стоит когда-нибудь посмотреть — это нормальная поддержка или одни и те же области ломаются повторно.

> Этот навык **используется в Неделе 2** нового плана (Reading diff). Не теряется.

---

## Неделя 1 — Process & AI literacy fundamentals

**Цель:** научиться ставить понятные TASK и не доверять claim'ам AI на слово.

### День 1 ⬜ — TASK как документ

- [ ] Открыть `/Users/ilya/Projects/ai-dev-system/project-overlays/sitka-office/TASKS/archive/`
- [ ] Прочитать **3 закрытых TASK целиком** (выбрать любые)
- [ ] По каждому: что хорошо сформулировано, где Worker мог бы спросить уточнение?

**Результат:** одна строка в журнале (см. ниже) — что увидел про разницу между чёткими и размытыми TASK.

### День 2 ⬜ — Совпадение Done с Acceptance

- [ ] Для тех же 3 TASK открыть соответствующие HANDOFFs в `HANDOFFS/archive/`
- [ ] По каждому: Done совпадает с Acceptance criteria из TASK?
- [ ] Найти один случай "Worker сказал OK, но §Acceptance не полностью покрыт"

### День 3 ⬜ — Verify claims (без локального запуска)

- [ ] Открыть один HANDOFF с claim "tests N/N green"
- [ ] Проверить через **GitHub PR checks** (`gh pr checks <N>` или PR page → Checks tab) + **HANDOFF Artifacts section** (commit SHA, test counts из CI)
- [ ] Локальный `cabal test` — **optional** (если хочешь и среда настроена)

**Результат:** понимание что claim верифицируем, не на доверии.

### День 4 ⬜ — Reviewer findings без TL ответа

- [ ] Открыть `HANDOFFS/archive/2026-04-29-codex-reviewer-to-claude-tl-dm7-c-treasury-manual-expenses.md`
- [ ] Прочитать **только Reviewer findings** (прикрыть TL ответ)
- [ ] По каждому finding: ACCEPT / REJECT / DEFER с обоснованием

### День 5 ⬜ *(optional)* — Свой первый TASK

- [ ] Написать TASK через `make new-task` для маленькой docs-задачи
- [ ] Проверить — твой TASK clear для постороннего грамотного человека?

---

## Неделя 2 — Reading diff (universal)

*(Расписание появится когда дойдёшь — оставлено placeholder'ом, чтобы не overplanned заранее)*

⬜ Не начата.

---

## Неделя 3 — 5 universal red-flag categories

⬜ Не начата.

---

## Неделя 4 — Practice arbitration

⬜ Не начата.

---

## Опциональные Недели 5-6 — Cross-stack transfer

⬜ Не начата.

---

## Daily ritual (15 минут)

Утром:
1. Один раздел из любого archive HANDOFF/TASK (5 мин)
2. Одна строка в журнале ниже — что заметил (2 мин)

Вечером (если работал с AI сегодня):
3. Что AI сделал, что я бы скорректировал? Одна строка (5 мин)

---

## Журнал (одна строка в день, не больше)

_(Здесь записывать ежедневные наблюдения. Можно использовать формат: `YYYY-MM-DD: <что заметил>`)_

_Пока пусто._

---

## Вопросы на потом

(Сюда — что непонятно по ходу. Разберём когда соберётся.)

_Пока пусто._

---

## Заметки о себе

(Что заметил о своём процессе обучения)

_Пока пусто._

---

## История сессий

- **2026-04-18** — сессия 1 (старт). Объяснил зачем GitHub Desktop, дал шаги установки, проверка на коммите из History. Время: ~5 мин.
- **2026-04-24** — сессия 2. Закрыли Дни 1-2 Недели 1 старого плана. Установка GitHub Desktop, разбор conventional commits, разбор diff коммита `db4f541` построчно. Понял формат diff и 3 признака хорошего коммита (переиспользование, комментарий-предупреждение, маленький размер).
- **2026-05-04** — сессия 3 (пересборка плана). Старый план "стать архитектором в Haskell-проекте за 12 недель" заменён на новый "AI agent control + light tech literacy за 4-6 недель, навыки переносимы на любой стек". Pre-week setup (GitHub Desktop из Дней 1-2) сохранён как полезная база для Недели 2 нового плана. Следующий шаг — День 1 Недели 1: чтение TASK документов из archive.
- **2026-05-06** — AI Dev System milestone. Phase B smoke baseline зафиксирован как tag `ai-dev-system-v0.1-smoke` (commit `449a29a`). System-fix PR закрыл Corrections 008/009/010: добавил `make submit-task`, reviewer persistence, evidence rule (git short hash для PR/commit/tag), и обязательное поле `Product repo status` в HANDOFF Artifacts (commit `d4dc7b2`). Следующий retry агентного chain — TASK `2026-05-06-ai-dev-system-progress-log-v01-smoke` (этот entry — артефакт того retry).
