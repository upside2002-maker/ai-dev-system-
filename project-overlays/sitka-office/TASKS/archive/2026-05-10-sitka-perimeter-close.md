# TASK: sitka-perimeter-close

- Status: done
- Ready: yes
- Date: 2026-05-10
- Project: sitka-office
- Layer: infra
- Risk tier: A
- Owner: Project Tech Lead
- Worker model: Claude Code (Sitka Worker subagent)
- Mode: strict

## Problem

P1 perimeter gap из аудита Codex (2026-05-06): порты `8080` (Haskell-ядро) и `8081` (Python-сервисы) на проде `94.72.112.106` экспонированы на `0.0.0.0` через `docker-proxy`. Verified руками 2026-05-06: `curl http://94.72.112.106:8080/api/treasury/cashbox` без авторизации возвращает живой JSON кассы (`CORE_AUTH=disabled` на сервере). Любой со знанием IP может читать/писать в API в обход web nginx прокси на `8088`. Закрываем периметр в репо: (1) bind `8080`/`8081` к loopback в `docker-compose.prod.yml`; (2) добавить Basic Auth на nginx-прокси `8088`; (3) обновить документацию (DEPLOY.md новая секция «Защита периметра»). Деплой на сервер — отдельный шаг **после** accept этой задачи, не часть TASK.

## Files

- new:
  - `deploy/htpasswd.example` — пример формата (один user, dummy hash, чисто как ссылка для оператора). Реальный `htpasswd` создаётся TL'ом отдельно и хранится **только** server-only (не в репо).
- modify:
  - `docker-compose.prod.yml` — bind core/services portов к loopback: было `"8080:8080"` / `"8081:8081"`, станет `"127.0.0.1:8080:8080"` / `"127.0.0.1:8081:8081"`. Web остаётся как есть (его override на `8088:80` сделан в server-only `docker-compose.override.yml`, не часть этой задачи).
  - `deploy/nginx-prod.conf` — добавить `auth_basic "SITKA"` + `auth_basic_user_file /etc/nginx/htpasswd;` на `location /` (SPA fallback) и `location /api/`, `location /services/`. Использовать одну realm, один `htpasswd` файл. **Не trog'ать** existing `proxy_pass`, `limit_req`, `proxy_set_header` директивы.
  - `DEPLOY.md` — новая секция «Защита периметра» (между текущими «SSL/TLS» phase 5 и «Ongoing operations»): (a) объяснение что app-level auth НЕ готова, perimeter — единственная линия защиты; (b) команды для генерации htpasswd на сервере (`apt-get install apache2-utils`, `htpasswd -c /etc/sitka-htpasswd <user>`); (c) куда положить файл и как смонтировать в web container (через `docker-compose.override.yml` server-only или volume); (d) как тестировать (`curl -u user:pass`); (e) одна короткая ремарка что `CORE_AUTH=disabled` допустим только внутри закрытого perimeter, не публично.
- delete: —

## Do not touch

- App-уровень bearer auth: Python `CoreClient` (`sitka-services/app/core_client/client.py`), Web `client.ts` (`sitka-web/src/api/client.ts`), nginx Authorization injection — **отдельная задача класса B на потом** (~50-100 LOC), сейчас не делаем.
- `CORE_AUTH` env: остаётся `disabled` (не менять на `required`). App-auth не реализован, оставляем `disabled` внутри закрытого perimeter.
- `docker-compose.yml` (dev): не трогать. Dev продолжает binding `0.0.0.0` для local hot-reload — local dev не за nginx Basic Auth.
- `docker-compose.override.yml` server-only — он не в git, на сервере, отдельно. Эта задача меняет только то что в репо.
- API роуты, domain logic, миграции, тесты в product repo — нет.
- HTTPS / Let's Encrypt / DNS — отдельная задача, не сейчас.
- Замена nginx на Caddy / Traefik / другое — нет.

## Acceptance

- [ ] `docker-compose.prod.yml` — `core` сервис имеет `ports: ["127.0.0.1:8080:8080"]` (явно loopback, не `"8080:8080"` и не `"0.0.0.0:8080:8080"`).
- [ ] `docker-compose.prod.yml` — `services` сервис имеет `ports: ["127.0.0.1:8081:8081"]` аналогично.
- [ ] `deploy/nginx-prod.conf` — `auth_basic "SITKA"` + `auth_basic_user_file /etc/nginx/htpasswd;` присутствуют на `location /`, `location /api/`, `location /services/`. Existing `proxy_pass` и прочие директивы не изменены.
- [ ] `deploy/htpasswd.example` существует, содержит **dummy** hash (явно помечен как пример), НЕ реальный пароль.
- [ ] `DEPLOY.md` имеет новую секцию «Защита периметра» с инструкциями для оператора (генерация htpasswd, монтирование, тестирование, замечание про `CORE_AUTH=disabled`).
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный.
- [ ] Локальная docker-compose валидация: `docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile app config` — без ошибок (валидный YAML, ports парсятся).
- [ ] HANDOFF от Worker создан через `make new-handoff`, заполнен (Summary, Done, Remaining, Artifacts, Conflicts/risks, Next step), `make submit-task` переведён → Status: review.

## Context

Источники:
- Codex audit 2026-05-06 (закрыт через arbitration `TASKS/archive/2026-05-06-codex-prod-audit-arbitration.md`, коммит `47af386` 2026-05-10).
- Action plan для P1 — в `OPERATING/backlog.md` секция «Production / security», зафиксирован 2026-05-09 (b44ac5d).
- User decision 2026-05-10: способ защиты = **Basic Auth nginx** (не VPN, не IP allowlist). Один общий пароль (не персонализированный). Реальный пароль генерирует TL отдельно (`openssl rand -base64 24`), htpasswd создаётся на сервере отдельно, в репо только `htpasswd.example` без реальных кредов.
- Mode: strict обязателен (Risk tier A, default per `policies/MODES.md`). Lifecycle через subagents: Worker (cold-start, sitka-worker) → make submit-task → Reviewer (cold-start, sitka-reviewer) → ACCEPT → TL accept-handoff (обе) + accept-task.
- Деплой на сервер — **не часть** этой задачи. После merge: TL отдельно подключится к серверу, обновит `docker-compose.override.yml`, положит реальный htpasswd, `docker compose up -d --force-recreate web core services`, проверит `curl`'ом acceptance criteria снаружи.
