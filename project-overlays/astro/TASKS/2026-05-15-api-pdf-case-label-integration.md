# TASK: api-pdf-case-label-integration

- Status: open
- Ready: no
- Date: 2026-05-15
- Project: astro
- Layer: services (API endpoint + DB schema + Python persistence + tests)
- Risk tier: C (presentation-layer + small DB migration; Reviewer optional but recommended)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Post-Phase-8 closure pre-send QA (2026-05-15) обнаружил API integration gap, **не Phase-8-related** (программа Recovery CLOSED). При попытке скачать PDF Натальи через UI:

- Endpoint `GET /api/v1/consultations/{id}/pdf` возвращает HTTP 200, 19-страничный PDF.
- **PDF без outer-cards секции** — нет 3 карточек «тр Уран в квадрате с нат Венерой / тр Нептун в квадрате с нат Юпитером / тр Нептун в квадрате с нат Нептуном» (Phase 4 deliverable).
- В то же время `render_case.py --case-id 08-natalya-2025-2026` производит 18-страничный PDF с **3 outer cards present** (`/tmp/08-natalya-2026-05-15-marina-send.pdf`, sidecar git_sha=59ec1773ccbd, debug=False).

### Root cause

Шаблон `services/api-python/app/pdf/templates/solar.html.j2:642-650`:

```jinja
{% set _case_id = (provenance_meta.extra.case_label
                    if provenance_meta and provenance_meta.extra
                    else None) %}
{% if _case_id %}
  {% set _outer_cards = outer_cards_for_case(
       _case_id,
       facts.annual_transit_table,
       person.birth_timezone) %}
```

Outer cards section требует `provenance_meta.extra.case_label` чтобы вытянуть allowlist `OUTER_CARD_ALLOWLIST[case_id]`.

- **`render_case.py`** строит `RenderProvenance` с `extra={"case_label": case_id}` → шаблон получает case_id → outer_cards_for_case fires → outer cards рендерятся.
- **API endpoint** (`app/main.py:469-474`):

  ```python
  write_solar_pdf(
      person=dict(person),
      consultation=dict(cons),
      facts=facts,
      output_path=output_path,
  )
  ```

  **Не передаёт provenance.** В template `provenance_meta = None`, `_case_id = None`, outer cards section пропускается. Результат — incomplete PDF.

### Дисциплинарный класс

Это **тот же spec-gap pattern что TASK 7b § B.4** (тесты Phase 8C ловили закрытыми; UI client path — нет). API path для PDF не покрыт acceptance tests, поэтому gap не surfaced до pre-send QA. Не Phase 8 regression — gap существует с момента Phase 1 (provenance design) + Phase 4 (template references provenance.extra.case_label). API path просто никогда не передавал case_label.

### Discovered context

- Phase 8 program CLOSED 2026-05-15 (overlay commit `a6b06f3` + framing memo `4d2412a`).
- Production HEAD `59ec177`; pytest 298/0/0; 104 enrolled boundaries 0 OOT.
- User pre-send QA Натальи через UI → 500 (stale uvicorn) → restart → 200 но без outer cards.

## Scope (Tier C)

### Stage 1 — Person.case_label model field

- Add `case_label: str | None` field to `services/api-python/app/models.py:Person` (or wherever Person Pydantic model is).
- DB migration: ADD COLUMN `case_label TEXT` to `persons` table; existing rows = NULL.
- Migration script in `services/api-python/app/db/migrations/` (или существующая migration pattern).

### Stage 2 — Person CRUD endpoints accept case_label

- `POST /api/v1/persons` body schema includes optional `case_label`.
- `PATCH /api/v1/persons/{id}` allows updating case_label.
- Return value in `GET /api/v1/persons/{id}` includes case_label.

### Stage 3 — API PDF endpoint builds provenance with case_label

`app/main.py:download_pdf` (line 399-478):

- Build `RenderProvenance` analogous to `render_case.py` (mode: `fixture-render` or `api-render`; case_label from `person.case_label`).
- Pass `provenance=...` to `write_solar_pdf`.
- If `person.case_label is None` → render without outer cards (current behaviour, no regression for unmapped persons).
- If `person.case_label` is set → outer cards render per allowlist (matching render_case.py output).

### Stage 4 — Backfill existing persons

- Manual SQL update for 2 existing persons:
  - id=1 Евгения → `case_label=?` (TBD — какой case_id у Евгении? Если она тестовый persona, может NULL; если будет показана Марине, нужен соответствующий case_id).
  - id=2 наташа → `case_label='08-natalya-2025-2026'`.
- Документировать в HANDOFF: какие persons маппятся на какие case_ids; какие остаются NULL и почему.

### Stage 5 — Tests

- Extend `test_api_endpoints.py` (или существующий API test file):
  - Test: API PDF endpoint with `person.case_label='08-natalya-2025-2026'` produces PDF with outer cards.
  - Test: API PDF endpoint with `person.case_label=None` produces PDF without outer cards (no regression).
  - Test: API PDF and `render_case.py` for same case_id produce **byte-identical PDF outputs** (modulo timestamps в provenance) — locking parity.
- Stage 4 backfill verification via integration test.

## Files

- modify:
  - `services/api-python/app/models.py` (или Pydantic Person model location).
  - `services/api-python/app/persons.py` (CRUD).
  - `services/api-python/app/main.py:download_pdf` (provenance construction).
  - `services/api-python/app/db.py` (migration).
  - `services/api-python/app/db/migrations/00NN_add_case_label.sql` (new SQL migration).
  - `services/api-python/tests/test_api_endpoints.py` (или analog).
  - `apps/web-react/src/...` (UI form для редактирования case_label у Person — optional, can be backlog).
  - `project-overlays/astro/STATUS_RU.md`.

- new:
  - `services/api-python/app/db/migrations/00NN_add_case_label.sql`.

- delete: —

## Do not touch

- Engine code, schema, fixtures, Haskell core.
- `outer_cards.py` (allowlist data; не trogать существующие entries).
- `render_case.py` (canonical script path — стайт reference implementation).
- `solar.html.j2` template (логика остаётся как есть; gap фиксится в API, не в template).
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs (8.0, 8A, 8B, 8C, 8D, 8E).
- Marina framing memo (отдельный artifact, не часть этого TASK).

## Acceptance

### Stage 1-3 — Code

- [ ] Person model has `case_label: str | None`.
- [ ] DB migration applied; `persons` table has `case_label` column.
- [ ] POST/PATCH/GET persons endpoints accept/return case_label.
- [ ] API PDF endpoint builds provenance with `extra={"case_label": person.case_label}` if not None.

### Stage 4 — Backfill

- [ ] Person id=2 наташа: `case_label='08-natalya-2025-2026'` (or appropriate mapping).
- [ ] Person id=1 Евгения: case_label set or explicit NULL with rationale.
- [ ] HANDOFF documents mapping decisions.

### Stage 5 — Tests

- [ ] New API test: PDF endpoint with case_label produces outer cards.
- [ ] New API test: PDF endpoint without case_label = no outer cards (current behaviour preserved).
- [ ] Parity test: API PDF == render_case.py PDF (byte-identical content modulo provenance timestamps).
- [ ] Pytest `(298 baseline) + N new tests passed + 0 xfailed + 0 failed`.

### Common

- [ ] `cabal --project-dir core/astrology-hs build`: clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: green.
- [ ] `git status --short` clean.
- [ ] Product commit(s) ≤ 2 (migration + code+tests). Justify split в HANDOFF.
- [ ] Overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.

### UI smoke test (manual)

- [ ] User restarts uvicorn (with new code + migration applied).
- [ ] User opens UI http://localhost:3000/, clicks Наталья → consultation → «Скачать PDF».
- [ ] PDF contains 3 outer cards (тр Уран кв Венера, тр Нептун кв Юпитер, тр Нептун кв Нептун).
- [ ] PDF byte-identical (modulo provenance timestamps) to `/tmp/08-natalya-2026-05-15-marina-send.pdf` from `render_case.py`.

## Context

**Mode normal + Tier C** (presentation + small DB migration). Reviewer subagent optional (not required by Tier C); TL inline-verify acceptable.

**Baseline:**
- Product main @ `59ec177` (Phase 8 closed).
- Overlay master @ `4d2412a` (framing memo landed).
- Pytest baseline: `298 passed + 0 xfailed + 0 failed`.
- Cabal build: clean.
- Running services: uvicorn (PID 56097/56100, --reload, DB_PATH set) + vite dev (PID 86927).

**STOP triggers:**
- Migration breaks existing DB data → STOP, revert, escalate.
- API-rendered PDF differs from render_case.py beyond provenance timestamps → root cause другой gap; STOP, investigate.
- Need to touch template logic, outer_cards.py allowlist, или engine code → STOP, scope creep.

**Not in scope (explicit):**
- UI form для editing case_label (если нужно — отдельный sub-task; пока backfill через SQL OK).
- Person id=1 Евгения case_id mapping (если она тест-persona — NULL acceptable; если будет показ Марине — пользователь решает в Stage 4).
- 12 future-work items audit § A.2.1.D (Pluto display rule, single-window alignment, case 03 P-Mars typo, Анастасия TYPE-D) — отдельные backlog items, не часть этого TASK.

**Ready: no** — TL flips after user ack + any refinements.
