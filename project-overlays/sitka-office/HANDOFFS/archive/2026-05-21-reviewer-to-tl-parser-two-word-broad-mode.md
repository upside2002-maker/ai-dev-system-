# HANDOFF: reviewer → tl — parser-two-word-broad-mode

- Status: closed
- Date: 2026-05-21 19:38
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-21-parser-two-word-broad-mode.md

## Summary

**ACCEPT.** Двусловный fix парсера (`feat/parser-two-word-broad-mode`, commit `0a5e42c`) делает ровно то, что обещано в TASK: одна строка в `query.py:113`, новый unit-тест (7 кейсов), полный `make services-test` зелёный (241 passed, 1 skipped) на моём независимом прогоне. Логика подтверждена end-to-end: «blizzard parka» (broad) ловит реальные титулы Sitka/1shot, off-topic «marmot parka» не даёт спама, 3-токенные запросы остаются target. Scope чистый — только 2 файла из modify-list, никакого касания core / адаптеров / миграций / Avito.

## Done

Артефакт под ревью:

- branch `feat/parser-two-word-broad-mode` (от `master`)
- commit `0a5e42c` — "fix(parser): two-word queries enter broad mode (no substring drop)"
- 2 файла, +58 / −1:
  - `sitka-services/vendor/inventory_parser/inventory/v2/query.py` — одна строка (113), порог `<= 1` → `<= 2`
  - `sitka-services/tests/test_inventory_v2_query.py` — новый, 7 параметризованных кейсов

Что я проверил независимо (не на доверии к HANDOFF):

- **Diff scope.** `git diff master..feat/parser-two-word-broad-mode --name-only` → ровно 2 файла из modify-list TASK. Никакого `sitka-core/`, никаких `adapters/stores/*.py`, никаких миграций, никакого Avito.
- **Тесты — целевой файл.** `pytest tests/test_inventory_v2_query.py -v` → 7/7 passed in 0.90s. Все 7 кейсов (1-token broad, 2-token broad, 3-token target, 4× size/color force target) — зелёные.
- **Тесты — полный прогон.** `make services-test` → **241 passed, 1 skipped in 4.01s**. Соответствует утверждению HANDOFF.
- **Logical correctness через `BaseStoreAdapter.title_matches`** (читал `adapters/base.py:449-470` + `query.py:84-122` совместно):
  - `parse_query('blizzard parka')` → `mode=broad`, `tokens=('blizzard','parka')`.
    - vs «Sitka Blizzard Pro Parka» → **True** (главный fix работает)
    - vs «Blizzard AeroLite Parka» → **True** (второй реальный титул из precedent)
    - vs «Marmot Granite Jacket» → **False** (нет blizzard → matched=0, len mismatch → False)
  - `parse_query('marmot parka')` → `mode=broad`, `tokens=('marmot','parka')`.
    - vs «Sitka Blizzard Pro Parka» → **False** (marmot отсутствует — спама нет, гарантия из TASK подтверждена)
    - vs «Marmot Some Parka» → **True**
  - `parse_query('blizzard aerolite parka')` → `mode=target`, `tokens=('blizzard','aerolite','parka')`. Boundary preserved.
- **Sanity probes (no crash на edge):**
  - `parse_query('blizzard parka').query_mode` → `broad` ✔
  - `parse_query('').query_mode` → `broad`, tokens=`()` — не падает
  - `parse_query('sitka').query_mode` → `broad`, tokens=`()` (всё в stopwords) — не падает
- **Test quality.** Все 4 acceptance bullet'а из TASK покрыты. Замена 3-token примера `sitka stratus jacket` → `blizzard aerolite parka` корректно документирована комментарием в тесте (раздел "3-token target") — `sitka` в `_STOPWORDS` (`query.py:24-34`), без замены тест упал бы из-за фильтрации до 2 эффективных токенов. Reasoning Worker'а в HANDOFF Conflict #1 принят на уровне TL (видно по правке acceptance в TASK header) и в коде корректен.
- **Pre-commit hooks.** Worker сообщает all Passed; коммит на ветке существует.

Project repo status: committed (branch `feat/parser-two-word-broad-mode`, commit `0a5e42c`), не пушено.

## Remaining

Это handoff Reviewer → TL — мой шаг закрыт. TL принимает решение по verdict, затем стандартный lifecycle:

- push ветки + open PR (если ACCEPT принят без дополнительных правок)
- merge → deploy через `bash deploy/auto-deploy.sh` (scope=services, регламент 2026-05-14)
- закрыть пункт в `OPERATING/backlog.md` про двусловные запросы 2026-05-13
- записка в `MAILBOX/to-admin.md` с PR-номером + ссылкой на тест
- архивирование TASK / HANDOFFs

## Artifacts

- branch:               `feat/parser-two-word-broad-mode`
- commit(s):            `0a5e42c` (single)
- PR:                   нет (ждёт TL push после verdict)
- tests:                `pytest tests/test_inventory_v2_query.py -v` → 7/7 passed (мой прогон, 2026-05-21 19:39); `make services-test` → 241 passed, 1 skipped (мой прогон, тот же)
- Product repo status:  committed

## Conflicts / risks

Findings по REVIEWER.md шаблону.

### FINDINGS

Severity-классифицированный список. **Critical/high — нет.**

- **(low / NIT) Tier downgrade B → C** — `scripts/file-tier.sh sitka-services/vendor/inventory_parser/inventory/v2/query.py` возвращает `B` (по правилу `sitka-services/**/*.py` в `.claude/risk-tiers.md:88`), TASK header вручную понижен до `C` с письменным обоснованием.

  Моя позиция: **rationale принимаю**. Аргументы за downgrade конкретные и проверяемые:
  - одна строка в чистой функции без I/O,
  - нет изменений API/auth/shape/migrations,
  - unit-тест на 4 акцептанс-кейса pin'ит регрессию,
  - post-deploy smoke probe (`parse_query('blizzard parka').query_mode == 'broad'`) даёт wire-level подтверждение де-факто,
  - blast radius при баге — оператор сразу видит `no_hits` на проверочном запросе (это и был precedent 2026-05-13).

  Замечание для аудита, не блокер: формально Tier B требует integration test через `routes_http` (`/api/sourcing/search`); его в этом PR нет. Tier C downgrade и есть «явное согласие, что 4 unit'а + ручной smoke = достаточно». Если хочешь страховку — отдельной задачей добавить параметризованный кейс в `tests/test_routes_http.py` который бьёт `/api/sourcing/search` с `q="blizzard parka"` через мокнутые адаптеры и проверяет, что `query_mode=broad` доходит до них. Не в этот PR.

### MISSING

- **Empty/all-stopword query coverage в тестах.** Я проверил вручную в probe (`parse_query('')`, `parse_query('sitka')` — не падают, оба broad с пустыми tokens), unit-теста на это нет. Не блокер: фикс не трогает эту ветку логики, поведение не изменилось. Если когда-нибудь будет рефакторинг `parse_query`, защитный тест на «empty/all-stopword не крашит парсер» был бы полезен — но это nice-to-have, отдельный backlog.

### SCOPE CREEP

Нет. Worker строго следовал modify-list TASK. Pre-commit hooks не нагенерили побочных правок.

### NIT

- В новом тесте `import pytest` присутствует, но прямо не используется (только декоратор `@pytest.mark.parametrize`). Это идиоматично и не нуждается в правке — отмечаю просто для полноты.

### RECOMMEND

- Принять PR как есть.
- TL — обновить `OPERATING.md` записью о tier downgrade судебном решении (audit trail на случай, если завтра кто-то ещё будет понижать B→C по похожему vendored-fix аргументу).
- Опциональный follow-up TASK (на усмотрение TL): integration test через `/api/sourcing/search` с моком store-адаптеров, который пин'ит «broad-mode reaches adapter для двусловного запроса». Низкий приоритет.

## Next step

TL принимает verdict (ожидаемо ACCEPT по моему ревью), пушит ветку + открывает PR, мержит после CI, deploy через `bash deploy/auto-deploy.sh` (scope=services). После merge — заметка в `OPERATING.md` (включая фиксацию tier downgrade rationale) и записка в `MAILBOX/to-admin.md` с PR-номером + ссылкой на `sitka-services/tests/test_inventory_v2_query.py`.
