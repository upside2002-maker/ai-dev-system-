# HANDOFF: reviewer → tl — sitka-perimeter-close

- Status: closed
- Date: 2026-05-10 19:39
- Project: sitka-office
- From: reviewer
- To: tl
- Agent runtime: Claude Code
- Model: Opus 4.7 (1M context)
- Role mode: Reviewer / Red Team
- TASK: project-overlays/sitka-office/TASKS/2026-05-10-sitka-perimeter-close.md

## Summary

**REQUEST CHANGES.** 7/7 acceptance criteria green по букве TASK, реализация в рамках scope, безопасность писем — OK. Но один блокер на пути к зелёному prod-deploy: `web` healthcheck в `docker-compose.yml:110` бьёт `wget -qO- http://localhost/`, а Worker добавил `auth_basic` на `location /` в `nginx-prod.conf` → healthcheck вернёт 401, web container никогда не пройдёт healthy → `depends_on: service_healthy` сломает поднятие стека после деплоя. Worker обозначил это в Conflicts #3 как «решение оставить без auth — наименее рискованное», но healthcheck `web`-сервиса не закрыл. Нужен либо exempt path для healthcheck, либо `--no-deps` workaround в DEPLOY.md, либо смена healthcheck команды. Остальное — два medium и пара nits.

## ARTIFACT

- TASK contract: `project-overlays/sitka-office/TASKS/2026-05-10-sitka-perimeter-close.md` (Risk tier A, Mode strict, Layer infra).
- Worker HANDOFF: `project-overlays/sitka-office/HANDOFFS/2026-05-10-worker-to-tl-sitka-perimeter-close.md`.
- Working-tree changes (uncommitted) в `/Users/ilya/Projects/sitka-office/`:
  - modified: `docker-compose.prod.yml` (+18, добавлены `ports: !override` для core+services).
  - modified: `deploy/nginx-prod.conf` (+19/-1, `auth_basic` на 3 location'ах).
  - modified: `DEPLOY.md` (+96, новая секция «6. Защита периметра»).
  - new (untracked): `deploy/htpasswd.example` (975 байт, dummy hash).

## Done (что reviewer проверил)

### Acceptance criteria — поштучно verified

- [✓] AC1 — `docker-compose.prod.yml` core: `ports: !override - "127.0.0.1:8080:8080"` (строки 26-27 в актуальной версии). Подтверждено `git diff docker-compose.prod.yml` + `docker compose ... config` показывает `host_ip: 127.0.0.1, target: 8080, published: "8080"` для `core`.
- [✓] AC2 — `docker-compose.prod.yml` services: `ports: !override - "127.0.0.1:8081:8081"` (строки 42-43). `docker compose config` показывает `host_ip: 127.0.0.1, target: 8081`. Дубликата от dev `0.0.0.0:8081` нет — `!override` сработал.
- [✓] AC3 — `deploy/nginx-prod.conf`: `grep -n auth_basic` показывает 3 пары `auth_basic "SITKA"` + `auth_basic_user_file /etc/nginx/htpasswd;` на location `/`, `/api/`, `/services/` (строки 92-93, 99-100, 111-112). Existing `proxy_pass`, `limit_req`, `proxy_set_header` директивы не изменены — verified построчно.
- [✓] AC4 — `deploy/htpasswd.example` существует (975 байт), hash явно dummy: `sitka-ops:$2y$05$DUMMY.EXAMPLE.HASH.NEVER.USE.THIS.IN.PRODUCTION.PLACEHOLDERaaaaa`. Два маркера: header `THIS IS A DUMMY EXAMPLE — DO NOT USE IN PRODUCTION` + слово `DUMMY` внутри hash'а. Hash bcrypt-формата ($2y$05$) но точно не валидный bcrypt от любого осмысленного пароля.
- [✓] AC5 — `DEPLOY.md`: новая секция «6. Защита периметра» (строки 112-207 после правки), содержит все 5 подпунктов: a) генерация htpasswd, b) монтирование в web, c) curl-тесты, d) ремарка про `CORE_AUTH`. Добавлен полезный preamble про perimeter как единственную линию защиты.
- [✓] AC6 — `make -C /Users/ilya/Projects/ai-dev-system check` — exit 0. Только WARN про working-tree dirty (4 файла + .claude/agents и пр. untracked) — это ожидаемо, write-set TASK'а в working tree per «не коммить без go от TL».
- [✓] AC7 — `POSTGRES_PASSWORD=dummy CORE_API_TOKEN=dummy docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile app config` — exit 0. Слитый ports у core: один маппинг с `host_ip: 127.0.0.1` (нет дубля от dev). У services: аналогично. У web: `80, 443` без host_ip (frontend публичный, по плану). У postgres: `5432:5432` без host_ip — dev compose, не наш scope.
- [✓] AC8 — Worker HANDOFF (`2026-05-10-worker-to-tl-sitka-perimeter-close.md`) заполнен полностью (Summary, Done with poштучно AC, Remaining, Artifacts, Conflicts/risks, Next step). Status `open`. `Product repo status: intentionally uncommitted (Tier C docs+infra)` явно отмечен с обоснованием.

### Scope discipline — verified

- Worker НЕ trog'ал `docker-compose.yml` (dev), `sitka-services/app/core_client/client.py`, `sitka-web/src/api/client.ts`, server-only `docker-compose.override.yml`, API роуты, миграции, тесты — verified `git diff` точно по 4 файлам из §Files.
- Drive-by наблюдения в Conflicts (deprecated `listen 443 ssl http2;`, false-positive `nginx -t` без resolver) — Worker правильно НЕ правил молча, отметил для backlog. Соответствует CLAUDE.md §2 «drive-by фиксы — проговорить явно».
- `CORE_AUTH=required` в `docker-compose.prod.yml` Worker НЕ менял — это вне scope.

### Security smell test — verified

- `htpasswd.example`: dummy hash 21-байтная строка с буквой DUMMY внутри + 2 явных warning маркера в шапке. Случайно использовать в проде — невозможно (nginx этот формат примет, но матч пароля никогда не пройдёт). Real-credential leak не вижу.
- `auth_basic` на `/`, `/api/`, `/services/` — основные user-facing endpoints закрыты. `/health` сознательно exempt — по комментарию для docker healthcheck core. Других proxy_pass'ов в SSL server'е нет (verified построчно nginx-prod.conf).
- Loopback binding надёжен: `127.0.0.1:` префикс явный в обоих ports. `docker compose config` подтверждает `host_ip: 127.0.0.1`.

### Worker'овы flagged conflicts — независимая оценка

- **`!override` совместимость (Worker Conflict #1)** — реально важно. Локально verified `Docker Compose v5.1.1` принимает. Без `!override` дубль `0.0.0.0:8080 + 127.0.0.1:8080` от list-merge — Worker правильно диагностировал. Прод-сервер должен иметь Compose ≥ 2.20 (стандартный bundle с Docker Engine 24+ — обычно ≥ 2.21). Перед деплоем `ssh server 'docker compose version'` — обязательно. Это не блокирует accept TASK'а в репо, но **должно быть в DEPLOY.md как pre-deploy check**.
- **TASK Problem statement vs `CORE_AUTH=required` в репо (Worker Conflict #2)** — verified: `docker-compose.prod.yml:35: CORE_AUTH: "required"`. TASK Problem statement писал «`CORE_AUTH=disabled` на сервере». Это либо documentation drift в TASK (правильнее: «на сервере фактически disabled через server-only override»), либо реально server-side `docker-compose.override.yml` перезаписывает. Не блокер для accept этой задачи (она про perimeter, не про CORE_AUTH), но TL должен **отдельно проверить server-side override** и явно решить — оставлять `required` (сейчас в репо) или возвращать `disabled` за perimeter защитой. Worker правильно отметил.
- **`/health` без auth (Worker Conflict #3)** — частично OK, частично источник блокера ниже. `/health` действительно нужен docker healthcheck'у core (внутри compose сети, через service DNS). Эндпоинт возвращает только `{"status":"ok"}` — не leak. Однако см. FINDING #1 — web healthcheck бьёт **не** `/health`.
- **Drive-by `listen 443 ssl http2;` deprecated (Worker Conflict #4)** — OK как scope discipline, отдельный backlog item типа Tier C nginx cleanup.

## FINDINGS

### FINDING #1 — high — web container healthcheck сломается после деплоя

**Файл:** `/Users/ilya/Projects/sitka-office/docker-compose.yml:109-114`
**Проблема:**
```yaml
web:
  healthcheck:
    test: ["CMD-SHELL", "wget -qO- http://localhost/ >/dev/null 2>&1 || exit 1"]
```
После применения `auth_basic` на `location /` в nginx-prod.conf этот wget без креденшелов получит **401 Unauthorized**. wget с дефолтными опциями вернёт exit code != 0 → healthcheck never `healthy` → web container навсегда `starting → unhealthy` → `depends_on: web (если был бы)` сломается. Что хуже: `docker compose ... up -d` сразу после деплоя будет показывать unhealthy web в `docker compose ps`, у оператора будет ложное впечатление что nginx не запустился.

**Почему это блокер для production deploy (а не только nit):** TASK §Acceptance не покрывает живой smoke на сервере, но цель TASK'а — **закрыть периметр на проде**. Если после merge + деплоя `docker compose up -d` оставит web в unhealthy, оператор откатит изменение или начнёт диагностировать nginx (которое работает). Risk tier A = эта задача про prod safety, и broken healthcheck — production-affecting bug.

**Worker частично это видел** (Conflict #3): «Web nginx healthcheck сейчас просто `wget -qO- http://localhost/` — упадёт 401, healthy не вернётся.» Но позиционировал как «решение оставить без auth наименее рискованное» — относилось к `/health`. На web healthcheck сам решение не предложил и в DEPLOY.md fix не зашил.

**Возможные фиксы (на выбор TL — это для нового TASK'а от TL, не reviewer'у диктовать как чинить):**
- (a) Сменить web healthcheck на `wget -qO- http://localhost/health`. Уже есть proxy_pass на core, no auth — сработает. Минус: web healthy зависит от core healthy (transitive через nginx → core), хотя core уже в depends_on web → может быть startup race не страшен.
- (b) Сменить на `wget --user=$HEALTH_USER --password=$HEALTH_PASS ...` через ENV. Пробрасывать креденшел в healthcheck — ugly.
- (c) Добавить exempt-path в nginx-prod.conf для healthcheck (отдельный location типа `/_internal_healthcheck` без auth, с return 200) — clean, но новая поверхность.
- (d) Сменить healthcheck на просто проверку что nginx процесс жив (`pgrep nginx`). Самое простое, но не end-to-end.

### FINDING #2 — medium — risk-tier mismatch: TASK заявлен Tier A, но `scripts/file-tier.sh` для всех 4 файлов возвращает `C`

**Файлы:** все 4 модифицированных.
**Проблема:** `risk-tiers.md` не классифицирует `docker-compose.prod.yml` / `deploy/*` / `*.md` иначе чем Tier C («low-risk surface — bug visible on first interaction»). TASK явно ставит `Risk tier: A`. Это обоснованно с точки зрения **business impact** (perimeter security = data exposure), но `risk-tiers.md` определяет tier по blast radius **типа кода** (money / state machine / attribution для A), а не по фичи.

**Почему medium а не nit:** mode `strict` (Risk tier A → mandatory per `policies/MODES.md`) предполагает property tests + human review. Здесь property tests не применимы (infra), human review — этим занимаюсь я. Если TL примет TASK с tier A но scripts говорят C, **либо** надо обновить `risk-tiers.md` с явным правилом «infra файлы продакшена → Tier A когда меняют exposure surface», **либо** допустить что для infra TASK risk tier — orthogonal axis (по бизнес-impact). Сейчас это inconsistency которая всплывёт у следующего агента.

**Не блокер.** Это процессное противоречие, не code bug. Решение TL.

### FINDING #3 — medium — DEPLOY.md инструкция (b) монтирует overrides через путь который TASK §Do not touch упоминает только косвенно

**Файл:** `DEPLOY.md` строки ~155-170 (секция 6.b).
**Что Worker написал:** инструкция оператору добавить в server-only `docker-compose.override.yml`:
```yaml
services:
  web:
    volumes:
      - /etc/sitka-htpasswd:/etc/nginx/htpasswd:ro
    ports:
      - "8088:80"
```
**Проблема:** `docker-compose.override.yml` Worker'ом не правится (он server-only, не в git — TASK §Do not touch). Но DEPLOY.md теперь предполагает его существование с конкретной структурой. Если у оператора текущий override не имеет секции `web:`, инструкция работает. Если уже что-то есть — оператор должен мерджить вручную. Никаких failure-mode warnings нет.

**Почему medium:** не блокер для accept'а сейчас (DEPLOY.md — документация, оператор увидит проблему при копи-пасте). Но риск что после merge + деплоя реальный override на сервере не сольётся как ожидалось → web без htpasswd volume → nginx стартует, на запросе к `/etc/nginx/htpasswd` возвращает 500 (file not found) → перимтер фактически блокирует **вообще всё**, не только не-аутентифицированных.

**Дополнение:** в DEPLOY.md (b) command показан с явным `-f docker-compose.override.yml` флагом. Это ОК если оператор использует override через явный флаг. Стандартная docker compose поведение — auto-merge `docker-compose.override.yml` если он рядом, без `-f`. TL может захотеть пояснить какой mode оператор использует.

## MISSING

- **Pre-deploy check для Compose version в DEPLOY.md.** Worker Conflict #1 правильно идентифицировал что `!override` требует Compose ≥ 2.20. В DEPLOY.md нет шага «`docker compose version` → должно быть ≥ 2.20» перед apply. Это однострочный fix, но критично для предотвращения silent broken deploy.
- **Smoke-test шаг для проверки healthcheck после деплоя.** В DEPLOY.md (c) есть curl-тесты `:8088` (401 без auth, 200 с auth, `:8080`/`:8081` external — refused). Нет проверки `docker compose ps --format ...` что web `healthy`. Если FINDING #1 не решён до merge, эта проверка упадёт.
- **rollback план если что-то сломалось на сервере.** `git revert` упомянуть? Force-down? Сейчас в DEPLOY.md «Защита периметра» только forward path.

## SCOPE CREEP

Не вижу. Worker строго в рамках §Files (4 файла), §Do not touch соблюдён. Drive-by наблюдения в Conflicts (deprecated `listen 443 ssl http2;`, false-positive `nginx -t`) **не** проникли в коммит — Worker не правил молча. Это правильное поведение per CLAUDE.md §2.

## NITS

- `nginx-prod.conf` — порядок директив в `auth_basic` блоках (auth_basic, auth_basic_user_file) одинаков на всех 3 location'ах — хорошо для grep-консистентности. Минор: можно вынести в `http {` контекст глобально (`auth_basic "SITKA";` на http уровне), и потом `auth_basic off;` на `/health`. Меньше дублирования, но рискованнее для readability. Текущее решение нормальное.
- `htpasswd.example` — комментарий упоминает `https://<host>/api/health`, но `/health` (а не `/api/health`) сейчас exempt от auth. Минор расхождение в текстовом примере.
- DEPLOY.md (a) — `htpasswd -B -c /etc/sitka-htpasswd sitka-ops` — фиксированное имя пользователя `sitka-ops`. Если оператор хочет другое имя, надо менять и в htpasswd, и в curl-тестах. Минор: можно сделать переменной в инструкции.
- HANDOFF Worker'а — поле `Model: Opus 4.7 (1M context)` явно указано. Молодец. Reviewer тоже use Opus 4.7.

## RECOMMEND

**Моё мнение для TL:**

1. **MUST FIX перед merge / деплоем** — FINDING #1 (web healthcheck). Один из вариантов (a-d). TL создаёт **новый TASK** для Worker'а с конкретным выбором фикса, либо коммитит оба change'а сам (Tier C-ish: docker-compose.yml change тривиален, но изменяет healthcheck).
2. **MUST FIX перед merge** — MISSING #1 (Compose version pre-deploy check в DEPLOY.md). Однострочное добавление в секцию 6.a.
3. **SHOULD ADDRESS** — FINDING #3 (DEPLOY.md инструкция (b) могла бы упомянуть проверку что override.yml корректно слился). Не блокер.
4. **DEFER** — FINDING #2 (tier mismatch). Это процессный issue, обновляется отдельно — либо `risk-tiers.md` правят чтобы покрыть infra/security, либо решают что для нек-ры classes TASK risk tier orthogonal от file tier.
5. **DEFER** — все NITS, Worker conflicts #1/#2/#4 (Worker сам правильно отметил, действий по этому TASK не требуется).

**Если FINDING #1 принять как ACCEPT-with-followup-TASK** (т.е. эта задача merge'ится как есть, а FINDING #1 закрывается отдельно ДО первого деплоя на сервер) — это допустимо при условии что TL гарантирует что между merge и деплоем будет followup. Иначе риск broken stack на проде.

**Если решено фиксить здесь** — REQUEST CHANGES, новый TASK от TL для Worker'а с одним из вариантов (a-d) фикса healthcheck + Compose version check в DEPLOY.md.

## Done (что reviewer проверил — short list для TL)

- 7/7 acceptance criteria green по букве (см. Done выше — поштучно).
- Scope discipline — clean.
- Security smell — clean (dummy hash настоящий dummy, loopback правильно, auth coverage правильная).
- Worker'овы flagged conflicts — 3 из 4 валидны, 4-й (deprecated nginx) — корректно как backlog.
- Найдено: 1 high (web healthcheck блокер), 2 medium (tier mismatch process, override.yml инструкция fragility), 2 missing (Compose version check, healthcheck smoke), 0 scope creep, ~3 nits.

## Remaining (что Worker / TL должны сделать если REQUEST CHANGES)

Если TL принимает мой verdict «REQUEST CHANGES»:

1. Новый TASK от TL для Worker'а: фикс web healthcheck (один из вариантов a-d). Я бы рекомендовал (a) — `wget -qO- http://localhost/health` — minimum surface change, зависимость web→core через service health уже есть в depends_on.
2. Tot же или связанный TASK: добавить в DEPLOY.md секция 6 preamble step «Pre-deploy: убедиться `docker compose version` ≥ 2.20 на сервере».
3. (Опционально): в DEPLOY.md (b) упомянуть что `-f docker-compose.override.yml` явный флаг и проверку через `docker compose -f ... -f ... -f ... config | grep -A2 'web:' | grep volumes` что volume mount проявился.

Если TL принимает как ACCEPT с followup — TASK для followup создаётся **до** первого деплоя, deploy ход TL'а откладывается до closure followup'а.

## Artifacts

- branch:               `master` (working tree, не закоммичено) в product repo `/Users/ilya/Projects/sitka-office/`. Reviewer worktree (для агентского окружения): `claude/funny-agnesi-9eb4a0` в ai-dev-system, не в product repo.
- commit(s):            нет (по Worker design — только working tree, TL коммитит на ACCEPT).
- PR:                   нет, TBD.
- tests:                test suite не запускал по тем же причинам что Worker — write-set чисто infra/docs, существующие cabal/pytest/playwright не релевантны. `make -C ai-dev-system check` — exit 0 (только WARN про dirty working tree, ожидаемо). `docker compose ... config` — exit 0, ports merge corrupt, host_ip: 127.0.0.1 проявился у core/services.
- Product repo status:  dirty (см. Conflicts/risks) — 4 файла working tree (3 modified + 1 untracked), без коммитов per Worker'овой стратегии «не коммить без go от TL».

Evidence:
- Worker HANDOFF был создан корректно через `make new-handoff`, body заполнен. Reviewer HANDOFF (этот файл) — тоже через `make new-handoff` SLUG=sitka-office TASK=... FROM=reviewer TO=tl.
- Diff'ы verified: `cd /Users/ilya/Projects/sitka-office && git diff --stat docker-compose.prod.yml deploy/nginx-prod.conf DEPLOY.md` → `3 files changed, 132 insertions(+), 1 deletion(-)`. Untracked `deploy/htpasswd.example` (975 байт).

## Conflicts / risks (reviewer-side)

1. **FINDING #1 (web healthcheck) — блокер production deploy.** Описание выше. Без фикса `docker compose ps` после деплоя покажет web `unhealthy` навсегда.
2. **`!override` Compose version dependency** (Worker Conflict #1, я подтверждаю) — на проде нужен Compose ≥ 2.20, в DEPLOY.md этого pre-check нет. Должно быть добавлено.
3. **CORE_AUTH inconsistency между TASK Problem statement и репо** (Worker Conflict #2, я подтверждаю) — TL должен явно проверить server-side `docker-compose.override.yml` и решить, оставлять `required` или возвращать `disabled`.
4. **risk-tier process mismatch** — TASK Tier A vs `scripts/file-tier.sh` C. Не блокер, но всплывёт у следующего агента.
5. **DEPLOY.md (b) override.yml инструкция** — fragile к существующему override на сервере, нет fail-mode warning.

## Next step

1. **TL читает этот HANDOFF**, классифицирует findings (особенно FINDING #1 — он определяет ACCEPT vs REQUEST CHANGES).
2. **Если TL примет вердикт REQUEST CHANGES** (рекомендация): новый TASK от TL для Worker'а — фикс web healthcheck + Compose version pre-check. Я бы предпочёл fix-in-this-PR чем accept-with-followup.
3. **Если TL примет ACCEPT с followup** (приемлемая альтернатива): TL `make accept-handoff` обоих (Worker'а + этого), `make accept-task`, делает PR/коммит, **до первого деплоя на сервер** создаёт followup TASK для Worker'а на FINDING #1 + MISSING #1.
4. **Если TL примет ACCEPT без followup** (не рекомендую): риск broken web container в проде. TL берёт остаточный риск на себя.

Reviewer работа закрыта — `make accept-handoff` на этот HANDOFF выполняет TL после прочтения.
