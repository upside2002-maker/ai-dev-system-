# HANDOFF: reviewer → tl — inventory-parser-fork-task-a2-extend-sitka-catalog

- Status: closed
- Date: 2026-05-28 17:23
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-28-inventory-parser-fork-task-a2-extend-sitka-catalog.md

## Summary

ACCEPT. Tier C механический refactor закрыт чисто: 10 файлов, 1 коммит
`8920fd6`, все 6 acceptance bullets выполнены. Empty-grep pass'нул (exit 1),
292 + 1 skipped зелёные, parity vs vendor — 0 mismatches на 38 case'ах,
network smoke `rogers=6 / 1shot=10` совпадает с HANDOFF. Worker'ская
открытая ноута по `canonical_product_title` уже принята TL (backlog #15),
не блокер. Никаких новых findings. Готово к push + PR.

## ARTIFACT

PR #(не запушено), branch `feat/inventory-parser-fork-task-a2-extend-sitka-catalog`,
single commit `8920fd6` "refactor(inventory): TASK A2 — extend
_sitka_catalog.py + rewrite 8 imports", 10 files / +601 / -26.

## FINDINGS

(severity таблица: critical / high / medium / low)

Не нашёл блокирующих findings. Перечисляю что проверил и почему пропускаю:

| # | Severity | Что проверил | Результат |
|---|---|---|---|
| F1 | — | Diff scope (10 файлов, в TASK Files.modify) | OK — ровно те 10 |
| F2 | — | Empty-grep contract `^from shared\.product\.sitka_catalog` в `sitka-services/app/inventory/` | OK — exit 1, пусто |
| F3 | — | `make services-test` (новый file 9/9, full suite 292 passed + 1 skipped, baseline 283 + 1, +9 from new file) | OK — counts совпадают с HANDOFF |
| F4 | — | Import-only edits в 8 файлах (`git diff` по каждому) | OK — ни одной функциональной правки, только импорт-строка |
| F5 | — | 16 публичных символов importable + 3 original-10 spot-check | OK |
| F6 | — | Parity check vs `vendor.shared.product.sitka_catalog`: 15 функций × 38 случаев | OK — 0 mismatches |
| F7 | — | Network smoke `blizzard` на `rogers + 1shot` (с `SITKA_APIFY_TOKENS=dummy`) | OK — `[('rogers','ok',6),('1shot','ok',10)]` совпадает с HANDOFF |
| F8 | — | Forbidden zones (vendor/avito_parser, query.py, adapters/base.py title_matches, runtime/service.py, sitka-core/, миграции, prod.yml, auto-deploy.sh, CI workflow) | OK — `git diff --name-only` чисто, ничто не тронуто |
| F9 | — | Pre-existing pytest-asyncio<0.27 pin в `.github/workflows/ci.yml:248` | OK — pin интактен (`"pytest-asyncio>=0.26,<0.27"`) |
| F10 | — | Bloat в `_sitka_catalog.py` — спрятанная dead machinery beyond уже принятого `canonical_product_title` кластера | Static-AST scan: 3 unused private helpers (`_title_color_label_from_tokens` L781, `_detect_family` L811, `_detect_qualifier` L820), но **все три — часть того же `canonical_product_title` title-path кластера**, который TL уже принял как dead (backlog #15). Не новый finding, в скоупе backlog #15. |
| F11 | — | Worker честно flag'нул свой простой shortcut в `_analyze_product_title_canonical` (упрощено до возврата строки вместо CanonicalTitle dataclass — risk пункт 3 в HANDOFF) | Решение Worker'a разумное: вендорский `analyze_product_title` сейчас никем не вызывается (только `canonical_product_title`). Откат стоит ~30 строк. Acceptable. |

## MISSING

Ничего критического. Replay-перепроверки:

- Тестовое покрытие 9 кейсов на 15 новых символов — sane (1-2 представительных
  случая на каждую функцию, плюс public-surface pin). Worker правильно решил
  не дублировать вендорский behaviour matrix — это уже покрыто
  upstream'ом и manual parity check'ом (33 кейса side-by-side перед коммитом).
- Property tests / edge cases на 15 новых функций — не нужны для Tier C
  механического copy/rewrite. Vendor behaviour parity (которую Worker
  прогнал руками, я подтвердил автоматизированно через python -c) — это
  правильный уровень доверия для refactor'а такого типа.
- Drive-by фикс не было — Worker явно отметил в HANDOFF Conflicts п.5. OK.

## SCOPE CREEP

Нет. Все 10 файлов в Files.modify по TASK; новый тест-файл явно разрешён
TASK'ом ("modify (optional): ... tests/test_inventory_sitka_catalog.py").

## NITS

- N1: `_analyze_product_title_canonical` (L831) комментарии говорят "Vendor
  also computes family / product_type / qualifier here, but
  canonical_product_title discards them. Skip to keep this slice lean."
  Однако `_detect_family` (L811) и `_detect_qualifier` (L820) всё-таки
  скопированы (но не вызываются). Это согласовано с Worker'ской позицией
  в HANDOFF («не удалил без подтверждения» — CLAUDE.md правило #4); часть
  backlog #15 cleanup. Не блокер.

- N2: import-rewrite в `adapters/stores/eurooptic.py:20-23` оставил
  `_proxy_logger = logging.getLogger(...)` между блоком `from app.inventory...`
  импортов и rewrite'нутым `from app.inventory._sitka_catalog import (...)`.
  Это pre-existing структура (так было до A2), но visually читается как
  «импорты разорваны логом». Косметика, не блокер. Если будет drive-by
  reformat — поднять `_proxy_logger` после всех импортов.

- N3: `tests/test_inventory_sitka_catalog.py:43-44` assert'ит и `callable`
  и `name in cat.__all__` в одном loop'е — это правильный double-check,
  но первая ошибка прячет вторую. Не критично для тестов такого scope.

## RECOMMEND

**ACCEPT.** Это образцовый Tier C mechanical refactor:

1. Acceptance bullets все 5 verified мной независимо (включая network
   smoke и empty-grep), Worker'ские числа совпадают до элемента.
2. Parity vs vendor подтверждена automated tool'ом (38 case'ов, 0
   mismatches) — стронгер чем Worker'ская manual 33-case проверка
   (overlapping coverage).
3. Forbidden zones чисто (10 файлов в diff, все из Files.modify).
4. Bloat — единственная dead machinery (`canonical_product_title` cluster
   ~150 LOC + 3 unused private helpers) уже принята TL как backlog #15.
   Других неоправданных pulls нет.
5. CI pin `pytest-asyncio<0.27` интактен (важно после прецедента flake'a
   в TASK A).
6. Worker честно flag'нул свои shortcut'ы (упрощение `_analyze_product_title_canonical`
   до строки, naming hygiene `_TITLE_*` / `_CANONICAL_*` префиксы) —
   transparency полная.

**Запретов на push нет.** TL может пушить ветку, открывать PR, ждать 8 lanes
CI зелёных, merge'ить.

Открытый вопрос от Worker'a по `canonical_product_title` cleanup уже
закрыт TL'ом (backlog #15, в этот PR не входит) — не дублировать в
review pass.

## Conflicts / risks

См. RECOMMEND — открытых risk'ов от Reviewer нет. Worker'ские пункты
1-5 в его HANDOFF уже отражены / приняты TL'ом.

## Next step

TL читает этот HANDOFF, поднимает status → closed через
`make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/2026-05-28-reviewer-to-tl-inventory-parser-fork-task-a2-extend-sitka-catalog.md`,
далее push branch + открыть PR + дождаться 8 CI lanes + merge.
