# HANDOFF: reviewer → tl — parser-improvement-p0-3-env-paths

- Status: closed
- Date: 2026-06-02 19:26
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-3-env-paths.md

## Summary

**ACCEPT.** P0-3 закрывает задачу чисто: все три hardcoded `/srv/sitka-qa/...`
пути ушли за env-fallback с дев-дефолтами под `~/.cache/` и `~/.config/`.
Grep-контракт пуст, 11/11 целевых тестов + 320/1-skip всего services-suite,
smoke подтверждает ровно один warning на 5 подряд вызовов с отсутствующим
файлом proxies. Нет scope creep, не тронуты forbidden zones. Backwards-compat
legacy env vars (`SNAPSHOT_PROXY_LIST` / `SNAPSHOT_PROXY_STATE` /
`SCHEELS_SITKA_CACHE`) сохранены как top-priority override — корректно.
Прод-список env vars в Remaining HANDOFF'а точно совпадает с пре-чейндж
поведением. Один NIT по импорт-тайм резолверу в `scheels.py:57`,
без блока.

## Done

### Reviewer findings

`ARTIFACT:` `feat/parser-improvement-p0-3-env-paths` @ `b1c9107`
(против базы `feat/parser-improvement-p0-2-variant-level-stock`).

`FINDINGS:` (severity критериев нет — diff соответствует TASK acceptance)

Все 12 пунктов от TL чек-листа проверены лично. Результаты:

1. **Diff scope (3 файла)** — OK. Diff `feat/parser-improvement-p0-2-variant-level-stock..feat/parser-improvement-p0-3-env-paths --name-only` возвращает ровно:
   - `sitka-services/app/inventory/proxy_pool.py`
   - `sitka-services/app/inventory/adapters/stores/scheels.py`
   - `sitka-services/tests/test_inventory_env_paths.py`
   Никаких forbidden zones (см. пункт 8).

2. **Target тесты** — 11/11 green, 0.34s:
   ```
   tests/test_inventory_env_paths.py — 11 passed in 0.34s
   ```
   **Full services-test** — 320 passed, 1 skipped, 22.34s. P0-2 baseline был 309+1 → +11 кейсов из нового файла, нет регрессий, цифра матчится HANDOFF claim.

3. **Grep-контракт** — пусто (exit 1):
   ```
   $ grep -rE "/srv/sitka-qa" sitka-services/app/inventory/ --include="*.py"
   $ echo $?
   1
   ```
   Acceptance #1 закрыт.

4. **Env-fallback корректность** — OK для обоих файлов:
   - `proxy_pool.py:31-44` — `_default_artifacts_dir()`: `SITKA_PARSER_ARTIFACTS_DIR` → `~/.cache/sitka-parser/artifacts`.
   - `proxy_pool.py:47-60` — `_default_proxies_file()`: `SITKA_PARSER_PROXIES_FILE` → `~/.config/sitka-parser/proxies.txt`.
   - `scheels.py:35-54` — `_default_sitka_cache_path()`: precedence `SCHEELS_SITKA_CACHE` > `SITKA_PARSER_ARTIFACTS_DIR/scheels_sitka_index.json` > `~/.cache/sitka-parser/artifacts/scheels_sitka_index.json`. Документирована в docstring.
   - `mkdir(parents=True, exist_ok=True)` — на первом touch (proxy_pool.py:173 `_flush_state`, scheels.py:311 `_save_disk_cache`). Не на import-time → import не пишет на диск.
   - Имена env vars стабильные, `SITKA_PARSER_<KIND>_<PURPOSE>` шаблон выдержан.
   - Legacy env vars (`SNAPSHOT_PROXY_LIST`/`SNAPSHOT_PROXY_STATE` в `get_shared_pool` lines 292-300, `SCHEELS_SITKA_CACHE` в `_default_sitka_cache_path` line 45) проверяются ПЕРВЫМИ, до нового fallback. Backwards-compat корректно.

5. **Proxies-missing gracefulness** — OK. Smoke:
   ```
   $ SITKA_PARSER_PROXIES_FILE=/tmp/definitely_does_not_exist_xyz123 \
     python -c "<5x get_shared_pool calls>"
   call 1..5: ok
   WARNINGS EMITTED: 1
   "proxy_pool: no entries parsed from /tmp/definitely_does_not_exist_xyz123
    (set SITKA_PARSER_PROXIES_FILE or SNAPSHOT_PROXY_LIST;
     further calls will return None silently)"
   ```
   Реализация через module-level `_SHARED_NO_PROXIES: bool` флаг под
   `_SHARED_LOCK` (lines 274, 290-291, 322). После первой неудачи —
   `True`, далее `return None` без re-parse файла. Сообщение содержит
   подсказку какие env vars выставить.

6. **Качество тестов** — OK, 11 кейсов покрывают:
   - Default → `~/.cache/.../artifacts`, `~/.config/.../proxies.txt`, scheels cache (`test_artifacts_dir_default_*`, `test_proxies_file_default_*`, `test_scheels_cache_default_*`).
   - Env-override (`test_*_env_override`, `test_scheels_cache_*_override`).
   - `mkdir(parents=True, exist_ok=True)` first-touch (`test_proxy_pool_creates_state_dir_at_first_touch` — пре-условие `assert not deep_state.parent.exists()`).
   - Graceful `None` на missing proxies (`test_get_shared_pool_returns_none_when_proxies_missing`).
   - Warn-once-across-5-calls (`test_get_shared_pool_warns_only_once_when_proxies_missing`, использует `caplog` + `reset_shared_pool` для изоляции).
   - Hard-guarantee no-`/srv/sitka-qa` при `importlib.reload` (`test_module_import_does_not_touch_srv_sitka_qa`) — runtime mirror grep-контракта.
   - Изоляция: `monkeypatch.setenv` / `tmp_path` / `caplog` + `reset_shared_pool` в try/finally — без shared-state утечек между тестами.

7. **Tier-mismatch** — OK, judgement-call TL подтверждается:
   `scripts/file-tier.sh sitka-services/app/inventory/proxy_pool.py` → `B`,
   `scripts/file-tier.sh sitka-services/app/inventory/adapters/stores/scheels.py` → `B`.
   Изменение тем не менее чисто механическое: env-fallback резолверы +
   warning rate-limit флаг. Никакой business/domain логики, contract API
   не меняется, money/auth/migration impact нулевой. Tier C для review-bar
   адекватно.

8. **Forbidden zones** — все intact:
   - Нет `runtime/service.py`, `routes/parsing.py`, `variant_match.py`, `query.py`, `adapters/base.py`, других store файлов, `_sitka_catalog.py`, frontend, sitka-core, `prod.yml`, `auto-deploy.sh`, CI workflow, `vendor/avito_parser/`.

9. **Архитектурные инварианты** — OK:
   - Correction 001 (no domain leak в integration layer) — env-driven пути это
     pure infrastructure config, никаких business decisions не вводят.
   - Нет money/типов/ADT/persistence (это вообще Python tier-B файл, Haskell-specific corrections не применимы).

10. **Прод env-var список** — accuracy подтверждена:
    Пре-чейндж `proxy_pool.py:30-31` (read из P0-2 base):
    ```
    DEFAULT_LIST_PATH = Path("/srv/sitka-qa/config/proxies.txt")
    DEFAULT_STATE_PATH = Path("/srv/sitka-qa/artifacts/proxy_state.json")
    ```
    Пре-чейндж `scheels.py:33-34` (read из P0-2 base):
    ```
    _DISK_CACHE_PATH = Path(
        os.environ.get("SCHEELS_SITKA_CACHE", "/srv/sitka-qa/artifacts/scheels_sitka_index.json")
    )
    ```
    HANDOFF Remaining prod env vars:
    ```
    SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts
    SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt
    ```
    Резолверы дают:
    - `SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts` →
      `proxy_state.json` под `/srv/sitka-qa/artifacts/proxy_state.json` ✓
    - `SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts` →
      `scheels_sitka_index.json` под `/srv/sitka-qa/artifacts/scheels_sitka_index.json` ✓
    - `SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt` ✓
    Поведение байт-в-байт идентичное пре-чейнджу.

11. **pytest-asyncio pin** — intact:
    `.github/workflows/ci.yml:248`: `pip install "pytest>=8,<9" "pytest-asyncio>=0.26,<0.27"`.
    Не тронут.

12. **No PR opened** — confirmed:
    `gh pr list --search "head:feat/parser-improvement-p0-3"` → пусто. Owner-directive о заморозке GitHub Actions соблюдена.

## Remaining

`MISSING:` ничего блокирующего. Worker'у указывать нечего — это
финальное review.

## Artifacts

- branch:               `feat/parser-improvement-p0-3-env-paths` (cascading
                        от `feat/parser-improvement-p0-2-variant-level-stock`)
- commit(s):            `b1c9107` (`fix(parser): env-driven paths for proxies + artifacts (TASK P0-3)`)
- PR:                   нет (Owner directive 2026-06-02 — GitHub Actions заморожены).
                        Branch pushed в `origin` для backup.
- tests:                target 11/11 green (новый файл `tests/test_inventory_env_paths.py`); full `make services-test` — 320 passed, 1 skipped, 22.34s. P0-2 baseline 309+1 → дельта +11 матчится.
- Product repo status:  intentionally uncommitted (Tier C review) — Reviewer
                        ничего не коммитит в product repo.

## Conflicts / risks

`SCOPE CREEP:` ничего за пределы TASK. Diff ограничен 3 файлами.

`NIT:` (без блока, info-уровень)

- **`scheels.py:57` — `_DISK_CACHE_PATH = _default_sitka_cache_path()` резолвится at module-import time**, не lazy. Это значит env vars должны быть установлены ДО первого `import app.inventory.adapters.stores.scheels` (через registry init). В прод: `.env` грузится docker-compose до старта Python — безопасно. В тестах: `importlib.reload` нужен (тест `test_module_import_does_not_touch_srv_sitka_qa` это и делает). Идентичный pattern существовал до коммита (`_DISK_CACHE_PATH = Path(os.environ.get(...))` тоже на module-level) — это сохранение существующей семантики, не регрессия. Если когда-нибудь захочется конвертировать в lazy резолвер (по аналогии с `proxy_pool` где default берётся per-call), это упростит test fixture setup и уберёт необходимость `reload`. Но это улучшение, а не дефект. Не блок.

## Next step

`RECOMMEND:` TL принимает HANDOFF: `make accept-handoff
FILE=project-overlays/sitka-office/HANDOFFS/2026-06-02-reviewer-to-tl-parser-improvement-p0-3-env-paths.md`,
затем `make accept-task FILE=project-overlays/sitka-office/TASKS/2026-06-02-parser-improvement-p0-3-env-paths.md`.

После разморозки GitHub Actions — открыть PR'ы в порядке
P0-1 → P0-2 → P0-3 (cascading).

На auto-deploy: добавить в server `.env`:
```
SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts
SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt
```
Иначе прод переедет на `~/.cache/sitka-parser/...` и потеряет
текущий sitka index cache до следующего refresh.

После закрытия серии — короткая запись в `to-admin.md` о P0-1 → P0-2 → P0-3.
