# HANDOFF: reviewer → tl — sitka-perimeter-close (iter2)

- Status: closed
- Date: 2026-05-10 20:05
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-10-sitka-perimeter-close.md
- Iteration: 2 (post-Worker iter2 fixes)
- Iter1 reviewer HANDOFF: project-overlays/sitka-office/HANDOFFS/2026-05-10-reviewer-to-tl-sitka-perimeter-close.md

## Summary

**ACCEPT.** Iter2 закрыл оба must-fix item'а из iter1 — FINDING #1 (web healthcheck) и MISSING #1 (Compose version pre-check) — точно по предложенным вариантам, без регрессий. `docker compose config` подтверждает merged web healthcheck `wget /health` со всеми 4 timing-полями (interval 15s, timeout 3s, retries 3, start_period 10s) — никаких compose-defaults не подменилось. Iter1 acceptance criteria 1-7 все остались зелёными — Worker не трогал ничего вне двух заявленных файлов (`docker-compose.prod.yml`, `DEPLOY.md`); `docker-compose.yml` (dev), `nginx-prod.conf`, `htpasswd.example` диф'ы пустые. Scope discipline iter2 — clean. Iter1 deferred findings (#2 tier mismatch, #3 override.yml fragility, NITS) остаются open per TL classification, не блокеры для accept.

## Done (что reviewer iter2 проверил)

### FINDING #1 fix — web healthcheck override (high → resolved)

Worker реализовал Reviewer-предложенный вариант (a) — `wget -qO- http://localhost/health` через override healthcheck в `docker-compose.prod.yml` web service.

- `git diff docker-compose.prod.yml` строки 56-72 показывают новый блок `healthcheck` под web service:
  - `test: ["CMD-SHELL", "wget -qO- http://localhost/health >/dev/null 2>&1 || exit 1"]` — `/health` exempt от auth_basic в `nginx-prod.conf:122-126`, поэтому wget без креденшелов получит 200.
  - `interval: 15s`, `timeout: 3s`, `retries: 3`, `start_period: 10s` — **все 4 timing-поля скопированы** из dev `docker-compose.yml:109-114`. Это критично: compose merge для `healthcheck` — dict-style (полная замена), без переноса полей prod бы взял compose-defaults.
- Compose merge verified: `POSTGRES_PASSWORD=dummy CORE_API_TOKEN=dummy docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile app config` — exit 0. Web service показывает:
  ```
  test:
    - CMD-SHELL
    - wget -qO- http://localhost/health >/dev/null 2>&1 || exit 1
  timeout: 3s
  interval: 15s
  retries: 3
  start_period: 10s
  ```
  Все 4 поля сохранились. Дефолты compose не подменились.
- Комментарий в файле (строки 56-66) объясняет: (a) почему override (после auth_basic дефолтный wget на `/` получит 401), (b) почему `/health` правильный target (proxy_pass через nginx → core, web depends_on core: service_healthy уже было — нет нового race), (c) почему дублируем timings (dict-merge, не list-merge).
- `docker-compose.yml` (dev) — `git diff docker-compose.yml` пусто. Dev healthcheck не тронут.

### MISSING #1 fix — Compose version pre-check в DEPLOY.md (must-fix → resolved)

Worker добавил подсекцию `#### 6.0) Pre-deploy check — версия Docker Compose` **первым** под секцией «6. Защита периметра», до всех htpasswd инструкций.

- `git diff DEPLOY.md` строки 132-156 показывают новый подраздел:
  - Заголовок `#### 6.0)` идёт перед `#### a) Сгенерировать htpasswd на сервере` (строка 158). Verified `grep -n "^####" DEPLOY.md`: порядок 6.0 → a → b → c → d.
  - Команда проверки: `docker compose version` с ожиданием `v2.20.0+`.
  - Команды апгрейда: `apt-get install --only-upgrade docker-compose-plugin` или полное `apt-get upgrade docker-ce docker-ce-cli containerd.io docker-compose-plugin`.
  - **Failure mode объяснён явно**: "Без этого pre-check `docker compose ... up -d` не упадёт громко, а тихо оставит порты `8080`/`8081` открытыми наружу — perimeter close будет иллюзией." Это и есть silent-broken-deploy риск, который Worker идентифицировал в iter1 Conflict #1 и Reviewer iter1 в MISSING #1.

### Acceptance criteria iter1 — re-verified без регрессий

- **AC1** (`core` ports loopback) — `docker-compose.prod.yml:26-27` без изменений: `ports: !override - "127.0.0.1:8080:8080"`. Compose merge показывает `host_ip: 127.0.0.1, target: 8080`.
- **AC2** (`services` ports loopback) — `docker-compose.prod.yml:42-43` без изменений: `ports: !override - "127.0.0.1:8081:8081"`. Compose merge показывает `host_ip: 127.0.0.1, target: 8081`.
- **AC3** (`auth_basic` на 3 location'ах nginx) — `git diff deploy/nginx-prod.conf` НЕ показывает изменений в iter2 (только iter1 +19/-1 уже принят). `grep auth_basic deploy/nginx-prod.conf` всё ещё 3 пары на `/`, `/api/`, `/services/`.
- **AC4** (`htpasswd.example` dummy) — файл untracked, без изменений в iter2.
- **AC5** (DEPLOY.md секция 6 структура) — оригинальная иерархия 6.a/b/c/d на месте. Новый 6.0 добавлен **внутри** секции 6, не сломал остальную структуру. `grep -nE "^### [0-9]" DEPLOY.md` показывает корректное расположение секции 6 между «5. SSL/TLS» (строка 104) и следующей H2.
- **AC6** (`make check` exit 0) — `make -C /Users/ilya/Projects/ai-dev-system check` exit 0, только WARN про working-tree dirty (write-set TASK'а в working tree — ожидаемо per «не коммить без go от TL»).
- **AC7** (`docker compose config` exit 0) — verified выше в FINDING #1 секции, exit 0.

### Scope discipline iter2 — clean

- `git status --short` показывает только iter2 ожидаемые файлы:
  ```
   M DEPLOY.md
   M deploy/nginx-prod.conf       (iter1 changes только, iter2 пусто)
   M docker-compose.prod.yml
  ?? deploy/htpasswd.example      (iter1, untracked)
  ```
- Worker НЕ трогал в iter2: `docker-compose.yml` (dev — diff пусто), `deploy/nginx-prod.conf` (iter1 changes сохранены, iter2 пусто), `deploy/htpasswd.example` (iter1, untracked, без iter2 правок). Это точно в рамках TL classification iter2 scope.
- Server-only `docker-compose.override.yml`, App-уровень bearer auth (`sitka-services/app/core_client/client.py`, `sitka-web/src/api/client.ts`), CORE_AUTH env, API роуты, миграции, тесты — не тронуты, как и в iter1.

### HANDOFF body update — verified

Iter2 секция «Iteration 2 (post-Reviewer feedback)» в Worker HANDOFF (`HANDOFFS/2026-05-10-worker-to-tl-sitka-perimeter-close.md`) строки 214-308 содержит:
- (a) Что поменял — два пункта явно описаны: web healthcheck override + DEPLOY.md 6.0 подсекция.
- (b) Acceptance ре-verified — compose merge подтверждение, make check, AC1-AC8 не регрессировали.
- (c) Ответ на Reviewer callouts — explicit addressed: FINDING #1 (по варианту (a), tl approved), MISSING #1 (новая подсекция 6.0). FINDING #2/#3 + NITS — отмечены как "отложено TL'ом", Worker не трогал.
- Iter2 evidence — TASK Status flow (review → in-progress → review через submit-task), Iter1 Reviewer HANDOFF прочитан.

### Iter2 risks / observations (не findings)

- **Iter1 deferred findings open**: FINDING #2 (risk-tier mismatch — TASK Tier A vs `scripts/file-tier.sh` C для всех 4 файлов), FINDING #3 (DEPLOY.md (b) override.yml инструкция fragile), NITS — TL classified как defer iter1, остаются open. Это не блокирует iter2 ACCEPT. Если TL хочет закрыть до merge — отдельный TASK. Если оставить open — задокументировать в OPERATING/backlog.md (например).
- **Iter1 MISSING #2 (smoke-test шаг для healthcheck) и MISSING #3 (rollback план)** — не упомянуты Worker'ом в iter2 как addressed. Они тоже defer per TL classification (только #1 был must-fix). Если TL хочет — отдельный TASK; если оставить — fine, deploy team увидит unhealthy в `docker compose ps`, разберётся.
- **`!override` Compose ≥ 2.20 dependency** теперь явно покрыт через DEPLOY.md 6.0. Worker iter1 Conflict #1 закрыт через документацию. Хорошо.

## Remaining

Ничего по этой задаче с моей стороны. Ход TL:

1. `make accept-handoff` обоих:
   - `project-overlays/sitka-office/HANDOFFS/2026-05-10-worker-to-tl-sitka-perimeter-close.md` (iter1 + iter2 в одном файле, как сделал Worker).
   - `project-overlays/sitka-office/HANDOFFS/2026-05-10-reviewer-to-tl-sitka-perimeter-close.md` (iter1 reviewer HANDOFF — на закрытие).
   - `project-overlays/sitka-office/HANDOFFS/2026-05-10-reviewer-to-tl-sitka-perimeter-close-iter2.md` (этот файл).
2. `make accept-task FILE=project-overlays/sitka-office/TASKS/2026-05-10-sitka-perimeter-close.md` — переводит Status `review → done`.
3. PR/коммит в `/Users/ilya/Projects/sitka-office/` (4 файла: `docker-compose.prod.yml`, `deploy/nginx-prod.conf`, `DEPLOY.md`, `deploy/htpasswd.example`) — за TL, поскольку Worker ничего не коммитил per TASK strict mode.
4. После merge — отдельный шаг деплоя на сервер (вне scope этой задачи): обновить server-only `docker-compose.override.yml`, проверить `docker compose version` ≥ v2.20 (теперь есть в DEPLOY.md 6.0), сгенерировать htpasswd, `up -d --force-recreate web core services`, проверить acceptance curl'ом.
5. (Опционально, deferred backlog): создать отдельные TASK'и для iter1 FINDING #2 (risk-tier process), iter1 FINDING #3 (DEPLOY.md (b) override.yml docs), iter1 MISSING #2/#3 (smoke-test + rollback plan), iter1 NITS — все некритичны для prod safety.

## Artifacts

- branch:               `master` (working tree, не закоммичено) в product repo `/Users/ilya/Projects/sitka-office/`. Reviewer worktree (для агентского окружения): `claude/funny-agnesi-9eb4a0` в ai-dev-system, не в product repo.
- commit(s):            нет (Worker iter1+iter2 — только working tree, TL коммитит на ACCEPT).
- PR:                   нет, TBD после accept TL.
- tests:                test suite не запускал — write-set чисто infra/docs (compose YAML override, DEPLOY.md secci); существующие cabal/pytest/playwright не релевантны. Smoke-валидации iter2: (a) `docker compose ... config` exit 0 + web healthcheck merged корректно (test + 4 timing); (b) `make -C ai-dev-system check` exit 0 (WARN про dirty working tree ожидаем). Реальный smoke на работу Basic Auth + healthcheck в proде — после деплоя на сервер (вне scope).
- Product repo status:  `dirty (см. Conflicts/risks)` — 3 modified + 1 untracked file в working tree, без коммитов per Worker'овой стратегии «не коммить без go от TL» (Tier C docs+infra). TL коммитит на ACCEPT.

Evidence (iter2-specific):
- `git diff docker-compose.prod.yml` → +18 строк web healthcheck override блок (test + 4 timing + 11 строк комментария).
- `git diff DEPLOY.md` → +24 строк подсекция 6.0 (заголовок + объяснение + команды проверки + команды апгрейда + failure mode).
- `git diff docker-compose.yml` → пусто (dev compose не тронут).
- `git diff deploy/nginx-prod.conf` → пусто в iter2 (iter1 +19/-1 сохранены).
- `grep -n "^####" DEPLOY.md` → 6.0 идёт перед a/b/c/d. Структура корректна.
- Compose merge web healthcheck (из `docker compose config`):
  ```
  test: [CMD-SHELL, wget -qO- http://localhost/health >/dev/null 2>&1 || exit 1]
  timeout: 3s, interval: 15s, retries: 3, start_period: 10s
  ```
- `make -C /Users/ilya/Projects/ai-dev-system check` exit 0 (WARN про dirty working tree).

## Conflicts / risks (reviewer-side iter2)

Никаких **новых** блокеров. Iter1 deferred items (FINDING #2/#3, MISSING #2/#3, NITS) остаются open per TL classification — не блокеры, но видимы в backlog.

Один observation о merge / accept lifecycle:
- HANDOFF iter1 Worker'а (`2026-05-10-worker-to-tl-sitka-perimeter-close.md`) содержит iter1 + iter2 секции в одном файле — это нормальный подход (одна задача, одна работа Worker'а). При `make accept-handoff` принимается всё содержимое одним actom. Iter1 Reviewer HANDOFF тоже принимается отдельно (он закрыт на момент TL classification).

## Next step

1. **TL читает этот HANDOFF** — verdict ACCEPT. Iter2 closed.
2. **TL accept lifecycle** — `make accept-handoff` (iter1 worker + iter1 reviewer + iter2 reviewer = три HANDOFF файла) + `make accept-task` для TASK.
3. **TL коммитит в `/Users/ilya/Projects/sitka-office/`** — 4 файла, желательно один коммит с осмысленным message (например: «infra: close production perimeter — loopback core/services + nginx Basic Auth + web healthcheck override + DEPLOY.md section 6»).
4. **Перед первым деплоем на сервер** — TL следует DEPLOY.md секция 6 (включая 6.0 pre-check), генерирует реальный htpasswd, обновляет server-only `docker-compose.override.yml`. Деплой — вне scope этого TASK.
5. (Опционально) — Deferred items в backlog:
   - iter1 FINDING #2 (risk-tier mismatch) → обновление `risk-tiers.md` либо процессное решение orthogonal axis.
   - iter1 FINDING #3 (DEPLOY.md (b) override.yml fragility) → дополнить fail-mode warning в DEPLOY.md (b).
   - iter1 MISSING #2/#3 (smoke-test + rollback) → опциональные дополнения DEPLOY.md.
   - iter1 NITS → косметика, по желанию.

Reviewer iter2 работа закрыта.
