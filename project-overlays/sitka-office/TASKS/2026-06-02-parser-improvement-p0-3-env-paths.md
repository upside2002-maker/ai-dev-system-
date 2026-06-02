# TASK: parser-improvement-p0-3-env-paths

- Status: open
- Ready: yes (после P0-2 merged)
- Date: 2026-06-02
- Project: sitka-office
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Закрывает **P0-3** из `docs/PARSER_IMPROVEMENT_TZ.md` — «Hardcoded production path `/srv/sitka-qa/`».

Симптомы из ТЗ:
```
scheels: failed to persist sitka index cache
FileNotFoundError: '/srv/sitka-qa/artifacts'
OSError: [Errno 30] Read-only file system: '/srv'
proxy_pool: no entries parsed from /srv/sitka-qa/config/proxies.txt
```

Адаптеры `scheels.py`, `proxy_pool.py` модуль и др. хардкодят production-only пути. На локальной dev-машине — silent fail или error spam в логах.

**Точный root cause (TL grounding 2026-06-02):**
- `app/inventory/proxy_pool.py` — хардкодит `/srv/sitka-qa/config/proxies.txt` (см. TASK A HANDOFF Conflicts; уже отмечено как P1-3 в архитектурном аудите).
- `app/inventory/adapters/stores/scheels.py` — пытается persist sitka index cache в `/srv/sitka-qa/artifacts`.
- Возможны другие места — Worker делает grep `grep -rn "/srv/sitka-qa" app/inventory/` для полной инвентаризации.

**Цель TASK:** все пути через env-переменные с дефолтом на `~/.cache/sitka-parser/` / `~/.config/sitka-parser/`. При первом обращении — `mkdir(parents=True, exist_ok=True)`. Если файл proxies отсутствует — продолжать работу без прокси (не спамить ошибками каждый запрос).

## Решение

ТЗ предлагает:
```python
ARTIFACTS_DIR = Path(os.getenv(
    "SITKA_PARSER_ARTIFACTS_DIR",
    Path.home() / ".cache" / "sitka-parser" / "artifacts"
))
PROXIES_FILE = Path(os.getenv(
    "SITKA_PARSER_PROXIES_FILE",
    Path.home() / ".config" / "sitka-parser" / "proxies.txt"
))
```

Worker делает grounding pass (grep `/srv/sitka-qa`) → находит все hardcoded paths → переписывает каждое через env-fallback + `mkdir parents=True exist_ok=True` при первом обращении.

На проде `SITKA_PARSER_ARTIFACTS_DIR=/srv/sitka-qa/artifacts` и `SITKA_PARSER_PROXIES_FILE=/srv/sitka-qa/config/proxies.txt` через `.env` или `docker-compose.override.yml` (если уже там нет — Worker фиксирует в HANDOFF, TL применит к серверу при следующем auto-deploy).

## Files

- modify: `sitka-services/app/inventory/proxy_pool.py` — env-driven path.
- modify: `sitka-services/app/inventory/adapters/stores/scheels.py` — env-driven artifacts dir, graceful fallback если writeable пути нет.
- modify (если найдёт grep): другие файлы под `app/inventory/` с `/srv/sitka-qa`.
- new: `sitka-services/tests/test_inventory_env_paths.py` — unit-тесты: дефолт ведёт в `~/.cache/sitka-parser/`, env-override работает, mkdir при первом обращении создаёт parents.
- modify (optional): `.env.example` в корне репо или `docs/PARSER_IMPROVEMENT_TZ.md`-aligned doc — добавить пример env-переменных.

## Do not touch

- **P0-1 / P0-2** — отдельные TASKs.
- **TASK B/C изменения** — закрыты.
- **`vendor/avito_parser/`** — нет.
- **`sitka-core/`, миграции, prod.yml, auto-deploy.sh** — нет.

## Acceptance

- [ ] `grep -rn "/srv/sitka-qa" sitka-services/app/inventory/` возвращает пусто (все hardcoded paths переписаны на env-fallback).
- [ ] Каждое место имеет default через `Path.home() / ".cache" / "sitka-parser" / ...` или `.config/sitka-parser/...`, и `mkdir(parents=True, exist_ok=True)` при первом обращении.
- [ ] Отсутствие файла proxies — не spam ошибки в каждом запросе. Один warning при init, потом silent (или раз в N минут через rate-limited logging).
- [ ] `tests/test_inventory_env_paths.py` зелёный.
- [ ] Полный `make services-test` зелёный.
- [ ] Smoke: `SITKA_PARSER_PROXIES_FILE=/tmp/nonexistent .venv/bin/python -c "from app.inventory.proxy_pool import get_shared_pool; pool = get_shared_pool(); print('ok' if pool else 'no-proxy')"` — не падает с FileNotFoundError, печатает `no-proxy` без stacktrace spam.
- [ ] На dev-машине scheels более не пишет «failed to persist sitka index cache» при каждом run (проверить через `pytest tests/test_inventory_smoke.py -v` если scheels там).

## Context

- ТЗ от Owner'а: `/Users/ilya/Projects/sitka-office/docs/PARSER_IMPROVEMENT_TZ.md` § «P0-3. Hardcoded production path `/srv/sitka-qa/`».
- Архитектурный аудит 2026-05-21 — P1-3 (eurooptic proxy / hardcoded path) частично перекрывается с этим TASK.
- TASK A HANDOFF Conflicts — упоминал что `proxy_pool.py` хардкодит путь.
- Worker model — Claude Code. Tier C ~30-50 LOC.

**Branching context:** ветка `feat/parser-improvement-p0-3-env-paths` берётся **от ветки P0-2** (не от master), чтобы наследовать P0-1 + P0-2 изменения. После всех 3 TASKs закрыты — TL ждёт разморозки GitHub Actions, потом PR'ы в порядке P0-1 → P0-2 → P0-3.

После закрытия — TL отчитывается короткой запиской в `to-admin.md`.
