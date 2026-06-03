# HANDOFF: worker → tl — parser-improvement-p0-3-env-paths

- Status: closed
- Date: 2026-06-02 19:21
- Project: sitka-office
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-3-env-paths.md

## Summary

P0-3 закрыт. Все hardcoded `/srv/sitka-qa/...` пути в
`sitka-services/app/inventory/` переписаны на env-driven резолверы
с `~/.cache/sitka-parser/` / `~/.config/sitka-parser/` дефолтом.
Spam "no entries parsed" в `get_shared_pool()` исправлен — теперь
warning один раз за процесс, далее silent None. Branch on top of
`feat/parser-improvement-p0-2-variant-level-stock` per cascading
strategy. Без PR (Owner: GitHub Actions заморожены 2026-06-02).

## Done

- **Grounding grep**: `grep -rn "/srv/sitka-qa" sitka-services/app/inventory/ --include="*.py"`
  — нашёл ровно 3 hardcoded места в 2 файлах (`proxy_pool.py:30,31`
  + `scheels.py:34`). Других мест в `app/inventory/` не было.
- **`sitka-services/app/inventory/proxy_pool.py`**: добавлены
  `_default_artifacts_dir()` (читает `SITKA_PARSER_ARTIFACTS_DIR`,
  fallback `~/.cache/sitka-parser/artifacts`) и
  `_default_proxies_file()` (читает `SITKA_PARSER_PROXIES_FILE`,
  fallback `~/.config/sitka-parser/proxies.txt`). `DEFAULT_LIST_PATH`
  / `DEFAULT_STATE_PATH` константы удалены (заменены резолверами).
  `ProxyPool.__init__` дефолтит через резолверы при `None` аргументе.
  `get_shared_pool()` сохраняет legacy env vars
  (`SNAPSHOT_PROXY_LIST` / `SNAPSHOT_PROXY_STATE`) как
  per-call override, но fallback теперь через новые резолверы.
  `mkdir(parents=True, exist_ok=True)` уже был на первом
  touch в `_flush_state` (строка 138) — не трогал.
- **Spam fix**: модуль теперь хранит `_SHARED_NO_PROXIES: bool`
  флаг. После первого `get_shared_pool()` без entries — warning
  выпускается ровно один раз, далее silent `None`. Warning текст
  расширен: подсказка какой env var выставить. Добавлен
  `reset_shared_pool()` helper для тестов (test-only, не для
  production-кода).
- **`sitka-services/app/inventory/adapters/stores/scheels.py`**:
  добавлена `_default_sitka_cache_path()` с приоритетом
  `SCHEELS_SITKA_CACHE` (per-file override) → `SITKA_PARSER_ARTIFACTS_DIR/scheels_sitka_index.json`
  → `~/.cache/sitka-parser/artifacts/scheels_sitka_index.json`.
  `mkdir(parents=True, exist_ok=True)` уже был на первом touch в
  `_save_disk_cache` (строка 289) — не трогал.
- **`sitka-services/tests/test_inventory_env_paths.py`** (новый):
  11 тестов через `monkeypatch.setenv` / `tmp_path` / `caplog` —
  default paths, env override, mkdir parents-on-first-touch,
  graceful None on missing proxies file, warn-only-once,
  hard-guarantee что reload модуля не резолвит `/srv/sitka-qa`.

## Remaining

- **Prod env vars** — TL должен добавить в server `.env` (или
  `docker-compose.override.yml`) при следующем auto-deploy:
  ```
  SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts
  SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt
  ```
  Без них прод будет писать в `~/.cache/sitka-parser/...` —
  работать будет, но артефакты переедут в новую директорию (и
  потеряется существующий sitka index cache до следующего
  `_save_disk_cache`). С env vars — поведение байт-в-байт как было
  до коммита.
- Legacy `SNAPSHOT_PROXY_LIST` / `SNAPSHOT_PROXY_STATE` /
  `SCHEELS_SITKA_CACHE` env vars **продолжают работать** как
  более-приоритетный override (если кто-то их уже выставлял в
  деплое). Не ломаются.

## Artifacts

- branch:               `feat/parser-improvement-p0-3-env-paths`
  (ветка cascading от `feat/parser-improvement-p0-2-variant-level-stock`)
- commit(s):            `b1c9107` (`fix(parser): env-driven paths for proxies + artifacts (TASK P0-3)`)
- PR:                   (нет — Owner directive 2026-06-02: GitHub
                         Actions заморожены, PR не открываем). Бранч
                         запушен в origin для backup
                         (`https://github.com/upside2002-maker/sitka-office/tree/feat/parser-improvement-p0-3-env-paths`).
- tests:                **target**: 11/11 green
                        (`tests/test_inventory_env_paths.py` —
                        новый файл, +11 кейсов).
                        **full**: 320 passed, 1 skipped — нет
                        регрессий (`make services-test`, 26.03s).
                        До коммита было 309 (или похожая цифра —
                        не проверял дельту через git stash, не
                        нужно для оценки).
- Product repo status:  committed
                        — закоммичено на branch
                        `feat/parser-improvement-p0-3-env-paths`,
                        SHA `b1c9107`. Pushed в origin как backup.
                        PR не открыт по директиве.

### Acceptance evidence

- ✅ `grep -rn "/srv/sitka-qa" sitka-services/app/inventory/ --include="*.py"`
  — exit 1 (пусто). Подтверждено после правки docstrings.
- ✅ Each path goes through `Path.home() / ".cache" / "sitka-parser" / ...`
  или `.config/sitka-parser/...` default + lazy `mkdir(parents=True, exist_ok=True)`
  при первом touch.
- ✅ Отсутствие файла proxies — один warning при init процесса,
  далее silent. Реализовано через `_SHARED_NO_PROXIES` флаг.
- ✅ `tests/test_inventory_env_paths.py` — 11/11 green.
- ✅ `make services-test` — 320 passed, 1 skipped.
- ✅ Smoke `SITKA_PARSER_PROXIES_FILE=/tmp/nonexistent_definitely python -c "from app.inventory.proxy_pool import get_shared_pool; pool = get_shared_pool(); print('ok' if pool is None or not pool.entries() else 'has-entries-unexpected')"`
  — печатает `ok`, без `FileNotFoundError` traceback. Smoke с 5
  подряд вызовами `get_shared_pool()` — ровно один warning,
  остальные silent.
- ✅ `tests/test_inventory_smoke.py` — 6/6 green (scheels через
  registry не падает).

## Conflicts / risks

- **Tier-mismatch (минорный)**: TASK заявляет Tier C, фактический
  тир для `proxy_pool.py` и `scheels.py` по
  `scripts/file-tier.sh` — Tier B. Изменение тем не менее
  чисто-механическое (env-fallback + warning-rate-limit), без
  domain/business логики. Не блокер для review.
- **Не трогал** `docs/PARSER_IMPROVEMENT_TZ.md` — был uncommitted в
  worktree до старта, не часть моего TASK (по WORKER правилам не
  выхожу за "Файлы"). TL: решить отдельно — либо submit как часть
  context, либо удалить, либо отдельным TASK.
- **Не трогал prod-side** — `docker-compose.prod.yml`, `deploy/*`,
  `auto-deploy.sh` явно out-of-scope per TASK. См. Remaining —
  prod env vars TL применит при разморозке CI.
- **`SNAPSHOT_PROXY_LIST` пересечение**: legacy env var
  продолжает быть top-priority override в `get_shared_pool`.
  Если на проде он уже выставлен — он выиграет над
  `SITKA_PARSER_PROXIES_FILE`. Это сознательно — backwards-compat
  без breaking change.
- **Async safety `_SHARED_NO_PROXIES`**: модульный bool под
  `_SHARED_LOCK` — thread-safe. Не атомарен между fork'ами, но
  это и был исходный pattern с `_SHARED`. OK для текущего
  scheduler (один процесс).

## Next step

- TL ревью этого HANDOFF + diff на ветке `feat/parser-improvement-p0-3-env-paths`.
- При acceptance — `make accept-task FILE=project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-3-env-paths.md`.
- TL держит ветку до разморозки GitHub Actions. После разморозки
  — открывает PR в порядке P0-1 → P0-2 → P0-3 (cascading).
- На auto-deploy после мерджа: добавить в server `.env`:
  ```
  SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts
  SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt
  ```
  чтобы прод сохранил текущие пути.
- После закрытия — TL пишет короткую запись в `to-admin.md` о
  закрытии серии P0-1 → P0-2 → P0-3.
