# HANDOFF — DM-7-C treasury manual expenses (Worker → TL, BLOCKED)

- Date: 2026-04-28 16:30
- From: Claude Worker (no branch created — stopped before code)
- To: Claude Tech Lead (sitka-office)
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: [`project-overlays/sitka-office/TASKS/2026-04-28-dm7-c-treasury-manual-expenses.md`](../TASKS/2026-04-28-dm7-c-treasury-manual-expenses.md)
- Status: closed

## TL;DR

Возврат в TL до начала кодинга. TASK §"Файлы" указывает `sitka-core/test/TreasurySpec.hs` как место для ~20 integration tests с HTTP кодами / JSON-парсингом, но этот файл — pure engine tests без DB harness. Существующий integration-харнес (`setupPool`, `cleanDb`, `withApp`, `getJ/postJ/patchJ`) живёт в `sitka-core/test/ApiSpec.hs`, и все Treasury HTTP integration tests предыдущих фаз DM-5/B-1/B-2/B-3 уже там. Это case "Условные возвраты в TL" → "Test infrastructure не позволяет integration test через существующий harness в TreasurySpec — стоп, описать".

Кода нет. Ветка не создана. PR не открыт. Status TASK = `in-progress` (не флипал в `review`, работа не закрыта).

## Что сделано

- Прочитал TASK целиком, сменил `Status: open` → `Status: in-progress`.
- Locale grounding по 8 reading-order пунктам (ROLE_MODEL, CLAUDE_GLOBAL, global-corrections, TASK, CLAUDE.md, architecture-invariants, risk-tiers, corrections).
- Прочитал реальный код по локальному grounding-листу из шапки сессии:
  - `sitka-core/src/Api/Treasury.hs` (430 строк) — образец routes + handlers + helpers (`requireLead/Deal/Spend`, `validateSourceLinks`, `toTransactionResp`).
  - `sitka-core/src/Api/Marketing.hs` — `createSpendEntry` (340–389) mirror-Transaction pattern, `updateCampaign` (215–243) `<|>` PATCH pattern, `updateChannelAccount/Listing` тоже `<|>`.
  - `sitka-core/src/Api/Types.hs` — стиль `CreateXReq` / `UpdateXReq` / `XResp` через `deriving anyclass (FromJSON, ToJSON)` (без префикс-mangling в JSON), `CreateTransactionReq`/`TransactionResp` (1043–1081).
  - `sitka-core/src/Api/AppM.hs` — `runDb`, `fetchOr404`, `validateOr400`, `recordEvent`. PATCH-конфликта-с-генериком нет: aeson-генерик не настроен на drop-prefix mangling, ключи матчатся буквально (`{ "ucpName": ... }`), что согласуется с request полями `ucp*`.
  - `sitka-core/src/Domain/ExpenseCategory.hs` — `ExpenseKind` ADT + JSON / PersistField готовы.
  - `sitka-core/src/Domain/Transaction.hs` — `SourceManual` готов.
  - `sitka-core/src/Db/Schema.hs` строки 410, 437–443 — `ExpenseCategory` Persistent entity + `UniqueExpenseCategorySlug` + `transaction.expense_category_id` поле — всё на месте.
  - `sitka-core/test/TreasurySpec.hs` (555 строк) — целиком pure engine tests на `currentBalance / cashflow / cashboxSnapshot` etc. Никаких `setupPool` / DB / `Wai.Test`.
  - `sitka-core/test/ApiSpec.hs` (2774 строки) — здесь живёт integration-харнес: `setupPool` (62), `testConnStr`, `cleanDb` (90+ строк, в частности TRUNCATE уже включает `expense_category` строкой 98), `withApp` (404), `getJ/postJ/patchJ` (124–186), seeders. И существующие Treasury HTTP describe-блоки: `Treasury — DM-5 ledger` (1915), `Treasury — DM-7-B-1 legacy prepayment backfill` (2235), `Treasury — DM-7-B-2 confirm-purchase` (2371), `Treasury — DM-7-B-3 shipping-expense + reservation lifecycle` (2497).
  - `sitka-core/test/Spec.hs` — `apiSpec` подключён последним блоком, `treasurySpec` идёт раньше.
- Проверил latest migration: `0020_drop_deal_actuals.sql` (PR #65). `0019_cashbox_phase_a.sql` — фундамент Phase A. Новые миграции не нужны, схема уже готова.
- Master HEAD: `4ce5694` — совпадает с TASK §Контекст.

Кода в Api.Treasury / Api.Types / TreasurySpec / других файлах **не написал ни строки**.

## Возврат в TL — Test infrastructure conflict

### Симптомы

TASK §A-D описывает 4 HTTP endpoint-а с реакциями 200/400/404/409 и JSON request/response. TASK §E1–E5 описывает **integration-тесты**:

> E1. `POST /categories {slug=…} → 200, returns CategoryResp`
> E2. `POST` дубликата slug → 409
> E3. `POST /expense {amount=12345.67, …} → 200, TransactionResp с amount=-12345.67`
> E4. `categoryId = <archived_id>` → 400 "category is archived"

Это HTTP-уровень: статусы, JSON-парсинг, error bodies. Невозможно протестировать pure-функцией.

TASK §"Файлы" указывает `sitka-core/test/TreasurySpec.hs` как единственное место для тестов и говорит "существующий test harness в TreasurySpec.hs (см. как написаны Phase A tests на `cashboxSnapshot`)". Но Phase A tests на `cashboxSnapshot` (TreasurySpec строки 376–561) — это **pure unit tests** на функцию `cashboxSnapshot :: [Transaction] -> [Reservation] -> [...] -> CashboxSnapshot` с конструируемыми входами и `shouldBe` на результат. Нет ни `setupPool`, ни `runSqlPool`, ни `Wai.Test`, ни вообще импорта `Db.Schema`.

Существующий integration-харнес целиком инкапсулирован в `sitka-core/test/ApiSpec.hs`:
- `setupPool / testConnStr / cleanDb` (62–98) — pool + миграции + TRUNCATE; список таблиц для truncate уже включает `expense_category`.
- `getJ / postJ / patchJ` (124–186), `jf / jfI / jArr / sc` (193–208) — тестовые helpers.
- `withApp` (404) — `cleanDb >> runSession s (app [] Nothing pool)`.
- Все Treasury HTTP describe-блоки предыдущих фаз DM-5/B-1/B-2/B-3 (строки 1915–2606+) лежат там же. Естественное место для DM-7-C: новый `describe "Treasury — DM-7-C manual expenses"` после строки ~2606 в ApiSpec.hs.

ApiSpec.hs **не упомянут** ни в TASK §Файлы (modify), ни в §"Не трогать". Молча его править нельзя — Worker discipline ("если требуется выйти за 'Файлы' / 'Не трогать' — возвращаю в TL, не правлю молча").

### Опции (на решение TL)

Все три обсуждались мной перед эскалацией. Перечисляю с trade-offs, без выбора победителя — TL виднее.

**Option 1. Расширить §Файлы добавлением `sitka-core/test/ApiSpec.hs`.** Новые ~20 integration tests + property test → describe-блок `Treasury — DM-7-C manual expenses` около строки 2606+ ApiSpec.hs, аналогично существующим DM-5/B-1/B-2/B-3 блокам.
  - Плюсы: следует существующему паттерну; нулевая duplication; `cleanDb` уже включает `expense_category` в TRUNCATE; все integration-helpers (`postJ`, `jf`, `sc` etc.) переиспользуются; TL может удалить `TreasurySpec.hs` из §Файлы (там нечего модифицировать на Phase C — все engine-функции для `OperationalExpense` уже работают через `cashboxSnapshot`).
  - Минусы: scope expansion в API-тестовый файл (Tier C по `file-tier.sh`, но всё-таки тестовый supporting code для Tier A handlers).
  - Diff будет ~+400–600 строк в ApiSpec.hs (тесты), <100 в Api.Treasury, ~50 в Api.Types — суммарно <1500 (F5 удержим).

**Option 2. Вынести harness в новый shared `sitka-core/test/TestSupport.hs` + reuse из ApiSpec и TreasurySpec.** Refactor `setupPool / cleanDb / withApp / getJ / postJ / patchJ` в новый модуль; и ApiSpec.hs, и TreasurySpec.hs импортируют оттуда; новые tests кладутся в TreasurySpec.hs как просили.
  - Плюсы: устраняет приватность харнеса, открывает дорогу будущим integration test файлам (Persons, Conversations и т.д. со временем тоже могут захотеть отдельные spec-файлы).
  - Минусы: нужно создать новый файл (`new:` в TASK сейчас пуст); ApiSpec.hs всё равно надо тронуть, чтобы поменять импорты; cabal file тоже (other-modules в test-suite); diff больше, риск дотронуться до того, что прямо не относится к C.
  - Это ближе к "правильно", но тяжелее по ходу. Если TL планирует ещё и Phase D / следующие фазы — окупится. Для одной только Phase C — overkill.

**Option 3. Дублировать harness внутрь `TreasurySpec.hs` (~110 строк) + написать там же ~20 integration tests.** Сохраняет TASK §Файлы буквально.
  - Плюсы: scope не расширяется ни на один файл.
  - Минусы: ~110 строк копипаста (`setupPool / testConnStr / cleanDb / withApp / postJ / patchJ / getJ / jf / sc`); TreasurySpec из pure-engine файла превращается в смешанный pure + integration; future drift между двумя копиями harness; вопрос "почему две копии" повиснет на следующего ревьювера; `cleanDb` придётся продублировать с тем же списком таблиц, иначе тесты поломаются при добавлении новой таблицы в один из файлов и не в другой.
  - Технически возможно, но эстетически плохо. Я бы не выбрал самостоятельно.

### Моя рекомендация (без принятия решения)

Если TL не планирует dm-7-d / dm-8-* в обозримом будущем — **Option 1**. Минимальная scope expansion: одна новая запись в §Файлы (`modify: sitka-core/test/ApiSpec.hs`); существующий паттерн; естественное соседство с DM-5/B-1/B-2/B-3 блоками.

Если TL уверен, что в ближайшие 2–3 фазы появятся отдельные integration-spec файлы — **Option 2** заплатит за себя, но это решение TL.

**Option 3** — последний выбор, только если TL не хочет вообще трогать ApiSpec.hs и не готов вводить TestSupport.hs. Тогда я кладу harness duplication в TreasurySpec.hs с явной пометкой "// duplicated from ApiSpec.hs by TASK directive — see DM-7-C TASK".

### Что нужно от TL для разблокировки

1. Решение по Option 1 / 2 / 3.
2. Если Option 1 или 2 — обновить TASK §Файлы (добавить ApiSpec.hs или новый TestSupport.hs) и при необходимости §"Не трогать".
3. Я не флипаю TASK status в `review`. Status сейчас = `in-progress`, остаётся таким до решения. После решения — продолжаю с этой же ветки (которой ещё нет), либо TL пересоздаёт TASK с уточнённым §Файлы.

## Артефакты

- Ветки нет (не создавал, чтобы не оставлять незакоммиченных artifacts на ровном месте).
- Коммитов нет.
- PR нет.
- Изменённых файлов в worktree нет (TASK markdown в overlay — единственное, тронуто только поле `Status:` в начале).

## Замечено по дороге, не правил

- В `sitka-core/test/ApiSpec.hs` строка 98 уже содержит `expense_category` в TRUNCATE-листе. Кто-то заранее (Phase A?) добавил, чтобы Phase C tests не падали на FK violations. Хорошее решение, не моё.
- `scripts/file-tier.sh sitka-core/src/Api/Treasury.hs` возвращает `C`, но `.claude/risk-tiers.md` явно перечисляет `Api/Treasury.hs` в Tier A list. Похоже на баг скрипта (неполный matcher). Не связано с TASK, не трогал. TL может оформить как отдельный TASK для AI Dev System Admin / sitka-office maintainer.
- `Api.Treasury.createTransaction` (строки 119–173) уже валидирует FK через monomorphic helpers `requireLead/Deal/Spend`. Для DM-7-C `POST /expense` нужен `requireExpenseCategory` (или общий helper). Имеет смысл писать монотонный `requireExpenseCategory :: Int64 -> AppM Db.ExpenseCategoryId` рядом с `requireLead` etc. — это естественное расширение, не drive-by.

## Конфликты / открытые вопросы

Один блокирующий, см. "Возврат в TL" выше.

Open question (не блокирующий, для контекста): C1 vs C2 развилка по PATCH semantics. До решения по test-infra ещё не оценивал boilerplate tri-state Aeson instance. Когда вернёмся к coding — оценю и зафиксирую выбор в HANDOFF v2.

## Следующий шаг

TL: ответить на блокирующий вопрос (Option 1 / 2 / 3) + опционально обновить TASK §Файлы. Потом я возвращаюсь в той же сессии (или новой по `docs/agent-session-start.md`), создаю ветку, пишу код, пишу HANDOFF v2 с полным acceptance check A–G и выбором C1/C2.
