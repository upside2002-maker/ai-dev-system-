# HANDOFF: worker → tl — inventory-parser-fork-task-a2-extend-sitka-catalog

- Status: closed
- Date: 2026-05-28 17:17
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-05-28-inventory-parser-fork-task-a2-extend-sitka-catalog.md

## Summary

Расширил `app/inventory/_sitka_catalog.py` до полного набора нужных
символов (10 уже было + 15 добавлено = 25 публичных + минимальная
private machinery из `vendor/avito_parser/.../sitka_catalog/{canonical,facts}.py`).
Переписал 8 импортов в alive адаптерах с `shared.product.sitka_catalog`
на `app.inventory._sitka_catalog`. `grep -rE "^from shared\.product\.sitka_catalog"
sitka-services/app/inventory/` теперь возвращает пусто (exit 1).
Один коммит `8920fd6` на ветке `feat/inventory-parser-fork-task-a2-extend-sitka-catalog`.
Full suite зелёный (292 passed + 1 skipped, +9 vs master baseline 283 + 1).
Network smoke (rogers + 1shot, query `blizzard`) — 6 + 10 items.

## Done

**Commit `8920fd6`** — `refactor(inventory): TASK A2 — extend _sitka_catalog.py + rewrite 8 imports`.

**`app/inventory/_sitka_catalog.py`** (+475 / -1):

- Public surface: было 10 символов (TASK A), стало **25**.
- 15 новых публичных функций:
  - axis predicates: `is_size_axis_label`, `is_color_axis_label`,
    `is_size_aux_axis_label`
  - size string helpers: `combine_size_label`, `compact_size_length_label`
  - color/size relocation: `move_tall_marker_from_color`
  - text inference: `infer_color_label_from_text`, `infer_size_label_from_text`
  - franks color/label path: `repair_color_label`, `label_match_candidates`,
    `contains_label_candidate`, `match_segment_label`
  - token classification: `significant_product_tokens`
  - title canonicalisation: `canonical_product_title`
  - extra alias: `normalize_text` (canonical.py public name; матчит уже
    существующий `normalize_match_text` — обе указывают на один
    `_normalize_text`)
- Catalog facts добавлены: `COLOR_REPAIRS`, `PRODUCT_TYPE_TOKENS`.
- Private machinery (canonical.py-сторона):
  - `_TITLE_COLOR_NOISE` (отдельно от matching.py `_COLOR_NOISE` —
    разные сеты: canonical.py НЕ содержит "sitka", чтобы названия
    типа "Sitka Black" не теряли color при инференсе)
  - `_TITLE_TOKEN_RE`, `_TITLE_MARKERS`, `_QUALIFIER_TOKENS`,
    `_DISPLAY_TOKEN`, `_PRODUCT_TOKEN_NORMALIZE`, `_SIZE_DISPLAY`,
    `_INSIGNIFICANT_PRODUCT_TOKENS`
  - `_canonical_normalize_for_match`, `_canonical_normalize_axis_token`
  - `_CANONICAL_COLOR_ALIAS_LOOKUP`, `_CANONICAL_SIZE_ALIAS_LOOKUP`
    (другая форма / контент от matching.py-сторон `_COLOR_ALIAS_LOOKUP`
    / `_SIZE_ALIAS_LOOKUP` — отсюда префиксы)
  - `_SIZE_TEXT_TERMS`
  - `_is_variant_number`, `_display_token`, `_display_phrase`
  - `_canonical_size_label`, `_canonical_title_tokens`,
    `_title_color_label_from_tokens`, `_strip_color_tokens`,
    `_detect_family`, `_detect_qualifier`
  - `_analyze_product_title_canonical` — inline title-only вариант
    вендорского `analyze_product_title`. Вендорский возвращает
    `CanonicalTitle` dataclass с 7 полями, но публичный
    `canonical_product_title` использует только `canonical_title`.
    Чтобы не тащить dataclass и неиспользуемые ветки, упростил до
    возврата строки. Поведение покрыто smoke-тестом.
- Файл вырос с 537 до 994 строк (+~457). Большая часть — title path
  (~150 строк) под `canonical_product_title`.
- Документация: docstring переписан (полный список 25 символов;
  заметка про naming hygiene `_TITLE_*` / `_canonical_*` префиксов).
- `import html` добавлен в top-level (нужен для unescape в
  `repair_color_label` / `label_match_candidates` / etc.).

**8 import rewrite — чистый search-and-replace, никаких других
изменений (даже комментариев) в этих файлах:**

| Файл | Импортируемые символы | Aliases |
|---|---|---|
| `adapters/stores/eurooptic.py` | infer_color_label_from_text, infer_size_label_from_text, is_color_axis_label, is_size_axis_label | — |
| `adapters/stores/franks.py` | contains_label_candidate, label_match_candidates, match_segment_label, normalize_text, repair_color_label, significant_product_tokens | `normalize_text as catalog_normalize_text` сохранён |
| `adapters/stores/outdoor_insiders.py` | normalize_text | — |
| `adapters/stores/als.py` | compact_size_length_label, is_color_axis_label, is_size_aux_axis_label, is_size_axis_label | — |
| `adapters/stores/shopify_stores.py` | canonical_color_key | — (этот символ уже был в TASK A) |
| `adapters/families/shopify_support.py` | is_color_axis_label, is_size_axis_label, move_tall_marker_from_color | `move_tall_marker_from_color as _shared_move_tall_marker_from_color` сохранён |
| `adapters/families/bigcommerce_support.py` | combine_size_label, is_color_axis_label, is_size_aux_axis_label, is_size_axis_label | — |
| `catalog/sitka_canon.py` | canonical_product_title | — |

**Тесты:**

- `tests/test_inventory_sitka_catalog.py` (новый, 100 строк) —
  **9 кейсов**: public surface check (16 имён importable + в `__all__`),
  axis predicates, size string helpers, move_tall_marker_from_color,
  franks color/label path (repair / label_match_candidates /
  contains_label_candidate / match_segment_label),
  significant_product_tokens, infer_color/size_label_from_text,
  canonical_product_title, normalize_text alias parity.
- `.venv/bin/python -m pytest tests/`: **292 passed + 1 skipped**.
  Baseline на master (02df502) перед TASK A2: 283 passed + 1 skipped.
  Прирост = +9 (новый файл).
- Pre-commit hooks: все Passed (gitleaks, EOF, trailing whitespace,
  case conflicts, etc.). Import-boundary linter не сработал
  (no-files-to-check) — он проверяет только Haskell, не Python.

**Behaviour parity (manual smoke перед коммитом — не в pytest):**

Прогнал 33 кейса side-by-side `local._sitka_catalog.<fn>(*args)` vs
`vendor.shared.product.sitka_catalog.<fn>(*args)` для всех 15 новых
символов + `normalize_text`. 0 несовпадений. Включал:

- axis predicates × 8 (Size, Color, Style, Length, Inseam, etc.)
- size helpers × 5 (combine_size_label, compact_size_length_label)
- move_tall_marker_from_color × 2
- repair_color_label × 2
- label_match_candidates × 3 (включая XXL/2XL — спец-форму с `Nx` суффиксом)
- contains_label_candidate × 2
- match_segment_label × 1
- significant_product_tokens × 1
- infer_color_label_from_text × 2 (Black + Open Country)
- infer_size_label_from_text × 1
- canonical_product_title × 2 (mens / womens path)
- normalize_text × 4 (whitespace, typo alias eleveted, ampersand,
  smart-quote — но `down—pour` оставлен как есть, em-dash не часть
  типо-алиаса)

**Smoke acceptance (network):**

```
SITKA_APIFY_TOKENS=dummy-not-real-token \
  .venv/bin/python -c "
    import asyncio
    from app.parsers.inventory_v2 import run_parser_search
    r = asyncio.run(run_parser_search('blizzard', ['rogers', '1shot']))
    print([(s.store, s.status, len(s.items)) for s in r])
  "
→ [('rogers', 'ok', 6), ('1shot', 'ok', 10)]
```

Почему нужен `SITKA_APIFY_TOKENS=dummy`: `ParserService.__init__` →
`build_registry()` строит все 20 адаптеров включая `AmazonAdapter()`
которая в конструкторе делает `ApifyRunner()` и падает без токена.
Это **pre-existing condition** — воспроизводится на master, не
регрессия из TASK A2 (проверил через стэш-чекаут на master, та же
ошибка). С dummy-токеном smoke проходит, цифры rogers/1shot
совпадают с TASK A HANDOFF (там было «6 на rogers», теперь
дополнительно 10 на 1shot — он ещё не запускался в TASK A smoke).

**Empty grep confirmation:**

```
$ grep -rE "^from shared\.product\.sitka_catalog" sitka-services/app/inventory/ --include="*.py"
$ echo "exit=$?"
exit=1
```

Acceptance п.3 удовлетворён.

## Remaining

Ничего, что нужно делать в рамках TASK A2. Acceptance:

- [x] `app/inventory/_sitka_catalog.py` содержит все 25 публичных
      символов (10 + 15 новых).
- [x] Все 8 файлов в Files.modify имеют импорт `from
      app.inventory._sitka_catalog`.
- [x] `grep -rE "^from shared\.product\.sitka_catalog"
      sitka-services/app/inventory/` пусто (exit 1).
- [x] `make services-test` зелёный — 292/292 + 1 skipped, baseline
      283 + 1.
- [x] Smoke `rogers` + `1shot` для `blizzard` — 6 + 10 items.
- [ ] CI зелёный (8 lanes) — TL пушит и смотрит.

## Artifacts

- branch:               `feat/inventory-parser-fork-task-a2-extend-sitka-catalog` (не запушена; ждёт review + push от TL)
- commit(s):            `8920fd6`
- PR:                   нет (push делает TL после Reviewer ACCEPT)
- tests:                новый файл `tests/test_inventory_sitka_catalog.py` 9/9 passed; full `.venv/bin/python -m pytest tests/` 292 passed + 1 skipped (+9 vs master baseline 283 + 1)
- Product repo status:  committed
- LOC delta (git diff --stat master..HEAD): 10 files changed, +601, -26 (net +575 LOC; +475 net в `_sitka_catalog.py`, +100 в новом тестовом файле, по 1-6 LOC в каждом из 8 rewrite-файлов)

## Conflicts / risks

1. **`canonical_product_title` — currently dead в inventory.**

   Прогрепал по всему `sitka-services/`:

   ```
   $ grep -rn "canonical_product_title\|normalize_title" \
        sitka-services/app/inventory/ sitka-services/app/parsers/ \
        sitka-services/tests/ --include="*.py"
   sitka-services/app/inventory/catalog/sitka_canon.py:10:  from shared.product.sitka_catalog import canonical_product_title
   sitka-services/app/inventory/catalog/sitka_canon.py:106: def normalize_title(...)
   sitka-services/app/inventory/catalog/sitka_canon.py:114:    return canonical_product_title(value)
   sitka-services/app/inventory/catalog/sitka_canon.py:125: "normalize_title",
   ```

   `canonical_product_title` импортируется в `sitka_canon.py` →
   используется в `normalize_title()` → экспортируется в `__all__`.
   **Но `normalize_title` нигде в codebase не вызывается** (только
   `normalize_color` и `normalize_size` из этого же модуля
   импортируются в `adapters/base.py`).

   То есть весь title-path в `_sitka_catalog.py` (`_analyze_product_title_canonical`,
   `_canonical_title_tokens`, `_title_color_label_from_tokens`,
   `_strip_color_tokens`, `_detect_family`, `_detect_qualifier`,
   `_display_token`, `_display_phrase`, `_is_variant_number`,
   плюс константы `_TITLE_MARKERS`, `_QUALIFIER_TOKENS`,
   `_DISPLAY_TOKEN`, `_PRODUCT_TOKEN_NORMALIZE`,
   `PRODUCT_TYPE_TOKENS`, и `_CANONICAL_COLOR_ALIAS_LOOKUP`) — это
   ~150 строк машинери под одну dead функцию.

   **Что я выбрал:** скопировал по тексту TASK («все 25 символов
   доступны»), потому что переписать импорт без рабочей функции
   нельзя — sitka_canon.py всё равно должен импортировать
   `canonical_product_title`. Удаление dead-функции — отдельное
   решение (можно в этом же PR через drive-by, либо отдельным
   cleanup-TASK). См. правило #4 в CLAUDE.md Communication discipline:
   «перед удалением чего-либо неочевидно мёртвого — проверить, кто
   пользуется, что подменяет, и подтвердить с пользователем».
   `normalize_title` может быть «in waiting» для следующей фичи
   (DM-ish UI или service-стороны), не удалил без подтверждения.

   **Что нужно от TL:** решить — оставляем как есть (готовая
   capability на случай если кто-то начнёт нормализовать тайтлы),
   или drive-by удалить `normalize_title` + связанную machinery в
   следующем TASK (~150 строк удалится). Если оставляем — TASK A2
   ничего больше делать не нужно.

2. **Naming hygiene — два набора private helpers с одинаковым
   именем в вендоре, переименованы здесь.**

   Вендорские `canonical.py` и `matching.py` оба определяют
   `_COLOR_NOISE` (но с разными сетами: matching.py включает
   "sitka", canonical.py нет), `_COLOR_ALIAS_LOOKUP` (разная
   структура: matching.py = `dict`, canonical.py = `tuple` отсортированных
   пар), `_SIZE_ALIAS_LOOKUP` (разные нормализаторы — matching.py
   `_normalize_size_for_lookup`, canonical.py `_normalize_axis_token`).

   В single-file slice я переименовал canonical-сторону:
   - `_COLOR_NOISE` → `_TITLE_COLOR_NOISE`
   - `_COLOR_ALIAS_LOOKUP` → `_CANONICAL_COLOR_ALIAS_LOOKUP`
   - `_SIZE_ALIAS_LOOKUP` → `_CANONICAL_SIZE_ALIAS_LOOKUP`
   - `_normalize_for_match` → `_canonical_normalize_for_match`
   - `_normalize_axis_token` → `_canonical_normalize_axis_token`

   Документировано в docstring. Не риск, информативная заметка для
   будущих читателей.

3. **`canonical_product_title` не возвращает `CanonicalTitle` dataclass,
   только title-строку.**

   Вендор: `canonical_product_title(value)` возвращает
   `analyze_product_title(value).canonical_title` — то есть один
   field из 7-полевого frozen dataclass. Из публичного API наружу
   попадает только строка. Я не копировал dataclass — `_analyze_product_title_canonical`
   возвращает строку напрямую.

   **Риск:** если в будущем кто-то решит использовать публичный
   `analyze_product_title` (в вендоре он public) — у нас его нет.
   **Митигация:** это решение можно откатить за 30 строк (добавить
   dataclass + переписать `_analyze_product_title_canonical` как
   `_analyze_product_title`). Я выбрал лёгкий вариант, потому что
   acceptance ничего про `analyze_product_title` не говорит, и
   `canonical_product_title` — единственный API, который любой
   адаптер сегодня использует.

4. **Smoke acceptance требует `SITKA_APIFY_TOKENS`, иначе
   `ParserService.__init__` падает (pre-existing).**

   Это не новое поведение TASK A2. Воспроизводится на master без
   изменений (проверил через стэш-чекаут). `build_registry()`
   строит `AmazonAdapter` без условий, а её конструктор тянет
   `ApifyRunner()` который не запускается без токена. Smoke
   command в prompt'е и в acceptance не учитывает это — на чистом
   локальном клонe без `SITKA_APIFY_TOKENS` он не запустится
   независимо от состояния `_sitka_catalog.py`.

   **Митигация:** в HANDOFF Done показал команду с `SITKA_APIFY_TOKENS=dummy-not-real-token`
   (значение неважно — Amazon не вызывается, только в registry build).

5. **Drive-by фикс не было.** Только 9 файлов из Files.modify в
   TASK A2 + 1 новый тестовый файл. Никаких косвенных правок
   несвязанных вещей.

## Next step

TL делает code review (diff небольшой по структуре: 1 big extension в
`_sitka_catalog.py` + 8 import rewrites + 1 новый тест-файл). Если
ACCEPT — спускает Reviewer subagent (Tier C, но изменение 994 LOC в
центральном модуле parser'а, второй pair of eyes не помешает). После
Reviewer ACCEPT — push ветки, PR, auto-deploy + CI smoke, merge.

Решение по dead-функции `normalize_title` (Conflicts п.1) — оставляем
или вычищаем — на усмотрение TL. Если вычищаем — отдельный TASK A3
или drive-by в этом же PR (предпочтительнее в этом же PR, потому что
после удаления `normalize_title` можно ещё ужать `_sitka_catalog.py`
на ~150 строк title-machinery).
