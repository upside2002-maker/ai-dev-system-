# TASK: api-pdf-endpoint-end-to-end

- Status: done
- Ready: yes
- Date: 2026-05-15
- Project: astro
- Layer: services (API endpoint + DB schema + PDF persistence + tests) + manual UI smoke
- Risk tier: C (presentation-layer + small DB migration + integration trace); **Reviewer subagent REQUIRED** per user direction 2026-05-15
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Post-Phase-8 closure pre-send QA (2026-05-15) обнаружил **API integration neglect**: client path `GET /api/v1/consultations/{id}/pdf` не покрыт acceptance tests, и реальный flow «Marina UI → клик "Скачать PDF" → клиентский файл» сейчас **продуцирует incomplete PDF** даже после успешного `/compute`.

Это **не Phase 8 regression** — Recovery program CLOSED, верификация Phase 8 шла через `render_case.py` canonical script path. API endpoint существует с Phase 1 (Single Source of Truth design), но он **никогда не был end-to-end протестирован против Marina-show contract**. Это тот же класс gap'а что TASK 7b § B.4: тесты compute path зелёные, реальный client path не покрыт.

### Симптомы (две независимые проблемы)

**Симптом 1 — case_label gap (outer cards section absent):**

- Endpoint возвращает HTTP 200, 19-страничный PDF.
- **Но 3 outer cards** (тр Уран кв Венера, тр Нептун кв Юпитер, тр Нептун кв Нептун) **не рендерятся**.
- `render_case.py` для того же кейса 08 выдаёт 18 страниц с 3 outer cards present (`/tmp/08-natalya-2026-05-15-marina-send.pdf`).

Root cause: `solar.html.j2:642` читает `provenance_meta.extra.case_label` чтобы вызвать `outer_cards_for_case(case_id, ...)`. API endpoint `main.py:469-474` вызывает `write_solar_pdf(...)` **без provenance argument** → шаблон получает `_case_id=None` → outer cards секция пропускается.

**Симптом 2 — broader save/return path неизвестно надёжен:**

Pre-send QA только что прошла случайно (после рестарта uvicorn). Worker должен проверить, что весь end-to-end путь работает:
- API computes facts (через core CLI).
- Renders PDF (через `write_solar_pdf`).
- Saves PDF на диск в `PDF_OUTPUT_DIR` (или configured location).
- Updates `consultations.pdf_path` в БД.
- Returns `FileResponse` клиенту.

Если есть скрытые баги в save или return — они должны быть выявлены и зафикшены **в этом же TASK**, не сидеть как timebomb до следующего pre-send QA.

### Discovery context

- Phase 8 program CLOSED 2026-05-15 (overlay commit `a6b06f3` + framing memo `4d2412a`).
- Production HEAD `59ec177`; pytest 298/0/0; 104 enrolled boundaries 0 OOT.
- User pre-send QA Натальи через UI → 500 (stale uvicorn) → restart → 200 но без outer cards.
- Uvicorn process до рестарта работал с 2026-05-04 (за 11 дней до Phase 1), что объясняет stale code; но даже после рестарта Marina-show contract нарушен (no outer cards).

## Worker framing

> **Не просто передай `case_label`. Добей API PDF endpoint end-to-end: calculate → render → save → return. Сейчас расчёт работает; падения / неполноты на render / save / return — тоже must-fix в этом же TASK.**

## Stages

### Stage 0 — Save/return path trace (НОВЫЙ блок per user direction 2026-05-15)

Перед любым кодовым изменением Worker трассирует текущий PDF write/save/return path:
- Где API сохраняет PDF на диск? (`PDF_OUTPUT_DIR` env var, default `./data/pdf` per `_resolve_pdf_output_dir`)
- Какой filename pattern? (`consultation-{id}.pdf` per `output_dir / f"consultation-{consultation_id}.pdf"`)
- Какой `pdf_path` пишется в `consultations` row? (через `update_consultation_pdf`)
- Что возвращается клиенту? (`FileResponse(str(output_path), media_type="application/pdf", filename=filename)`)
- Edge cases:
  - `output_dir.mkdir(parents=True, exist_ok=True)` падает (permissions)?
  - Кэшированный `pdf_path` указывает на удалённый файл?
  - `write_solar_pdf` бросает middle-write (частичный файл на диске)?
  - Race condition между Save и Return?

Worker reports trace results в HANDOFF. **Если выявляется реальный баг save/return path** (помимо case_label gap) — фиксится в Stage 3+, **не остаётся как timebomb**.

### Stage 1 — Person.case_label model field + DB migration

- Add `case_label: str | None` field to `services/api-python/app/models.py:Person` (or wherever Person model lives).
- DB migration: `ALTER TABLE persons ADD COLUMN case_label TEXT` (existing rows = NULL).
- Migration follows existing project convention (Worker inspects `services/api-python/app/db/`).
- **Migration acceptance:** existing DB после applying migration:
  - persons table read'able (`SELECT id, full_name, case_label FROM persons` returns rows; case_label = NULL для backfill rows).
  - Other tables unchanged (consultations, etc.).
  - DB integrity check passes (PRAGMA integrity_check).
  - **Наташа (id=2) получает `case_label='08-natalya-2025-2026'`** в результате Stage 4 backfill.

### Stage 2 — Person CRUD endpoints accept/return case_label

- `POST /api/v1/persons` body schema includes optional `case_label`.
- `PATCH /api/v1/persons/{id}` (or PUT, per существующая convention) allows updating case_label.
- `GET /api/v1/persons/{id}` returns case_label.

### Stage 3 — API PDF endpoint: provenance + save/return repair

`app/main.py:download_pdf`:
- Build `RenderProvenance` analogous to `render_case.py` design:
  - mode: `"api-render"` (или другой identifier; Worker decides — должен быть distinguishable от `fixture-render` в sidecar).
  - extra: `{"case_label": person.case_label}` if not None, else `{}`.
- Pass `provenance=...` to `write_solar_pdf`.
- If `person.case_label is None` → no outer cards (**graceful degradation**, no crash).
- If `person.case_label is set` → outer cards render per allowlist.
- **Если Stage 0 trace выявил save/return path issues** — пофиксить их здесь же (один атомарный commit вместо двух).

### Stage 4 — Backfill existing persons

- Person id=2 наташа: `case_label='08-natalya-2025-2026'`.
- Person id=1 Евгения: **`case_label=NULL` по умолчанию (NOT STOP)**. Worker документирует в HANDOFF: «id=1 Evgenia left NULL — no canonical case_id mapping yet». **Не гадать**, не STOP.

### Stage 5 — Tests (extracted-text parity, NOT byte-identity)

Per user direction 2026-05-15: byte diff PDF нестабилен (timestamps/metadata). Требовать **semantic checks**, не byte-identical.

New API integration test file (or extend existing test_api_endpoints / test_main.py / etc.):

- **Test 1 — API PDF endpoint with `person.case_label='08-natalya-2025-2026'`:**
  - HTTP 200.
  - Response body non-zero size.
  - Saved PDF file exists на диске в `PDF_OUTPUT_DIR` (verify via `pathlib.Path.exists()`).
  - File opens via PyPDF (no corrupt PDF).
  - Page count expected (Наташа — ~18 pages; tolerance ±1).
  - Extracted text contains 3 outer card titles: «в квадрате» + «Венерой» + «Юпитером» + «Нептуном» (Worker строит assertion правильно).
  - Calendar clipping per Phase 3: no «2024» / «2027» / «2028» в per-house section.
  - **No debug footer leak:** no «DEBUG» / «provenance_meta» в text.
  - DB `consultations.pdf_path` updated к saved file location.

- **Test 2 — API PDF endpoint with `person.case_label=None`:**
  - HTTP 200, PDF generated successfully (**graceful degradation, no crash**).
  - No outer cards section в text (acceptable — case not mapped).
  - File still persists на диске.

- **Test 3 (parity proxy) — API PDF ≈ render_case.py PDF for same case_id:**
  - Same page count ±1 (provenance footer может добавить).
  - Same set of outer card titles (3 titles match).
  - Same monthly transit table rows (13 row labels Натальи).
  - Same calendar entry count ±2 (clipping boundary noise).
  - Provenance sidecar (если API emits) carries case_label correctly.

### Stage 6 — Manual UI smoke test (in acceptance)

After Stage 1-5 land и uvicorn restarted with migration applied:
- User opens UI http://localhost:3000/.
- Navigates Наташа → consultation → клик «Скачать PDF».
- PDF downloads; opens в default viewer.
- Contains 3 outer cards; no debug footer; no «Сатурн в 6 доме».
- PDF file persisted на диске в `PDF_OUTPUT_DIR` (verifiable via `ls -lh /Users/ilya/Projects/astro/data/pdf`).

## Primary acceptance (per user direction 2026-05-15)

> **API endpoint must not crash. It must return HTTP 200 and produce a persisted PDF file under `PDF_OUTPUT_DIR` (or configured output path), with non-zero size, readable by `pdfinfo`/`pdftotext`.**

### Verification commands (Worker runs + reports output в HANDOFF)

```bash
curl -v -o /tmp/api-natalya-after-fix.pdf http://localhost:8000/api/v1/consultations/9/pdf
pdfinfo /tmp/api-natalya-after-fix.pdf
pdftotext -layout /tmp/api-natalya-after-fix.pdf -
ls -lh /Users/ilya/Projects/astro/data/pdf/
```

Expected outputs:
- `curl` exits 0; HTTP 200; non-zero `Content-Length`.
- `pdfinfo` reports valid PDF metadata: PDF version, page count (~18-19), encrypted=No.
- `pdftotext` produces readable text (Russian Cyrillic preserved); contains 3 outer card titles; no debug leak.
- `ls -lh` shows `consultation-9.pdf` (или analog) persisted с reasonable size (~140 KB based on prior render_case.py output для Наташи).

## Acceptance summary

- [ ] **Primary:** HTTP 200 + persisted PDF + non-zero size + `pdfinfo`/`pdftotext` readable.
- [ ] PDF реально сохранён в `PDF_OUTPUT_DIR` (`ls -lh` verifies presence).
- [ ] Скачанный PDF открывается viewer'ом.
- [ ] Contains 3 outer cards (Уран кв Венера, Нептун кв Юпитер, Нептун кв Нептун).
- [ ] Не содержит «Сатурн в 6 доме» (Phase 3 guard).
- [ ] Side effects / logs: no traceback в `/tmp/uvicorn.log` после endpoint call.
- [ ] DB migration applied; persons table integrity preserved; Наташа `case_label='08-natalya-2025-2026'`.
- [ ] Person id=1 Евгения case_label NULL (documented в HANDOFF, **not STOP**).
- [ ] Tests: 3 API PDF endpoint tests added (case_label set / null / parity proxy); `(298 baseline) + 3 new tests passed + 0 xfailed + 0 failed`.
- [ ] Stage 0 trace results в HANDOFF: PDF_OUTPUT_DIR, filename pattern, DB pdf_path update logic, return mechanism, edge cases discovered (если есть).

## Files

- modify:
  - `services/api-python/app/models.py` (or Pydantic Person location).
  - `services/api-python/app/persons.py` (CRUD).
  - `services/api-python/app/main.py:download_pdf` (provenance + save/return repair if needed).
  - DB migration file (location per existing convention; Worker discovers in Stage 0).
  - `services/api-python/tests/test_api_endpoints.py` (or new test file).
  - `project-overlays/astro/STATUS_RU.md`.

- new:
  - DB migration file для `case_label` column.

- delete: —

## Do not touch

- Engine code, schema, fixtures, Haskell core.
- `outer_cards.py` (allowlist data; Phase 8D entries stay).
- `render_case.py` (canonical reference, stays as-is).
- `solar.html.j2` template (**gap фиксится в API endpoint, НЕ в template**).
- Phase 4b structured overrides (`test_natalya_transits_acceptance.py`).
- Phase 8 archived TASKs (8.0, 8A, 8B, 8C, 8D, 8E).
- Marina framing memo.
- UI edit-form для case_label (backfill через SQL OK, UI form **out of scope**).
- 12 future-work items audit § A.2.1.D (Pluto, single-window alignment, case 03 P-Mars typo, Анастасия TYPE-D).

## Reviewer subagent (REQUIRED per user direction 2026-05-15)

After Stage 0-6 work, spawn Reviewer subagent (`general-purpose`). Reviewer scope:

1. Verify DB migration didn't break existing rows (PRAGMA integrity_check + SELECT persons works + case_label backfilled correctly).
2. Verify `download_pdf` builds provenance correctly; passes to `write_solar_pdf`; outer cards render iff case_label set.
3. Verify Stage 0 save/return trace results documented в HANDOFF; any bug found has been fixed.
4. Run **Primary acceptance smoke commands independently** (`curl` + `pdfinfo` + `pdftotext` + `ls -lh`); report outputs verbatim.
5. Run pytest independently; confirm `(298 baseline) + 3 new` passed, 0 xfailed, 0 failed.
6. Spot-check API PDF text content vs `render_case.py` PDF для Наташи: same 3 outer card titles, same calendar clipping signature, same monthly table.

Reviewer reports APPROVE / REQUEST CHANGES / ESCALATE.

## Context

**Mode normal + Tier C** (presentation + small DB migration + integration trace). Reviewer subagent **REQUIRED** per user direction 2026-05-15 (analogous discipline upgrade to TASK 7b § B.4 spec-gap pattern; integration paths not covered by tests previously).

**Baseline:**
- Product main @ `59ec177` (Phase 8 closed).
- Overlay master @ `febd4d8` (this TASK file first draft landed; renamed `api-pdf-case-label-integration.md` → `api-pdf-endpoint-end-to-end.md` to reflect broader scope per user direction 2026-05-15).
- Pytest baseline: `298 passed + 0 xfailed + 0 failed`.
- Cabal build: clean.
- Running services: uvicorn (PID 56097/56100, --reload, DB_PATH=/Users/ilya/Projects/astro/data/astro.db, PDF_OUTPUT_DIR=/Users/ilya/Projects/astro/data/pdf) + vite dev (PID 86927).

**STOP triggers:**
- Migration breaks existing DB rows → STOP, revert, escalate.
- API endpoint cannot be fixed without touching template / outer_cards.py / engine → STOP, reread scope (gap должен фиксится в API).
- Stage 0 trace revelations требуют schema-cascade или engine touch → STOP, Tier escalation.
- Save/return path bug found but unclear root cause → STOP, escalation memo + diagnostic dump.
- Reviewer escalates.

**Not in scope (explicit):**
- UI form для editing case_label (SQL backfill достаточно).
- Person id=1 Евгения case_label mapping (NULL по умолчанию; Worker не STOP'ит).
- 12 future-work items audit § A.2.1.D.
- Phase 4+ template logic.

**Ready: yes** — flipped 2026-05-15 after user ack + 5 refinements applied + scope expansion + Worker mental note: «if `curl` endpoint id `9` unstable after DB migration/backfill, Worker must first find actual consultation/person id via API (`GET /api/v1/persons/{id}/consultations`) or direct SQL, use that id in smoke commands. Не упасть на 'no such consultation'.»

## Closure (2026-05-16)

**Worker delivered + Reviewer APPROVE + user implicit closure ack (proceeded к новым findings, no blockers raised).**

- **Product commits:** `e5f1bfd` (schema-change-gate atomic — person.schema.json + Pydantic models + TS types + persons.py + main.py + migration 003) + `1536612` (provenance.py api-render mode + test_api_pdf_endpoint.py 3 tests + test_provenance.py adjustment). Bright Line #8 honoured.
- **Overlay commits:** `1297330` (HANDOFF + STATUS_RU initial submit) + `966db3c` (Status review bump).
- **Pytest:** 298 → **301** (3 new acceptance tests). 0 xfailed, 0 failed.
- **DB:** migration applied; PRAGMA integrity_check ok; Наташа backfilled `08-natalya-2025-2026`; Евгения + Ольга NULL (documented, not STOP).

### Stage results

- **Stage 0 (save/return trace):** Documented PDF_OUTPUT_DIR resolution, filename pattern, pdf_path DB update, FileResponse return. **3 latent edge-case bugs fixed** via `HTTPException(500, error=...)` envelopes: silent `mkdir(parents=True)` OSError, silent `write_solar_pdf` exception, undetected empty-file race.
- **Stage 1-2:** Person.case_label field + migration 003 + CRUD endpoints accept/return.
- **Stage 3:** API `download_pdf` builds `RenderProvenance(mode="api-render", extra={"case_label": person.case_label})` if not None, passes to `write_solar_pdf`. Graceful degradation case_label=None.
- **Stage 4:** Backfill Наташа `08-natalya-2025-2026`; Евгения id=1 + Ольга id=3 NULL по умолчанию (documented per user direction NOT STOP).
- **Stage 5:** 3 acceptance tests landed (case_label set / null / parity proxy).
- **Stage 6:** TL ran smoke commands; user delegated UI smoke к post-closure separately.

### External Reviewer subagent APPROVE (2026-05-16, 6 points)

All 6 verification items PASS empirically:
1. DB migration integrity (PRAGMA ok + 3 persons rows correct).
2. `download_pdf` provenance + 3 error envelopes verified в source.
3. Stage 0 trace documented + bugs fixed.
4. Primary acceptance smoke independent run (curl HTTP 200 / pdfinfo valid / pdftotext 3 outer cards + no «Сатурн в 6 доме» + no DEBUG / ls -lh persisted / sidecar git_sha matches HEAD).
5. Pytest 301/0/0 independent.
6. API PDF ≈ render_case.py parity (18 pages, 3 outer cards, monthly headers match; only delta «Москва» vs «Москва, Россия» = different SoT, benign).

**Reviewer informational notes (non-blocking):**
1. Filename mismatch on-disk `consultation-{id}.pdf` vs Content-Disposition `solar-{id}.pdf` — UX cosmetic, out-of-scope.
2. `birth_place` divergence API («Москва») vs canonical fixture («Москва, Россия») — benign, разные SoT (Person row vs input.birth.place).
3. DB state hygiene (consultation 9 had pre-Phase-8 facts) — one-shot recovery via /compute regeneration; not recurring.
4. Working tree clean post-commits; HEAD `1536612` matches sidecar git_sha exactly.

### User implicit closure ack

User moved on к новым findings (TASK A directions section + TASK B transit section generic) without explicit «ack closure», но и без blockers. Per TL discipline: Reviewer APPROVE + TL inline verify + no blockers raised → cascade-cleanup допускаемо отдельным commit. User explicit «procedure β» direction 2026-05-16 confirms: «Сначала отдельным commit закрыть `api-pdf-endpoint` lifecycle.»

### Production state at closure

- Product main = backup/main = `1536612`.
- Overlay master pre-closure-commit = `966db3c`.
- Pytest: 301 passed.
- Cabal: clean.
- uvicorn (PID 57424) serving fresh PDFs `mode=api-render`, `case_label`, `git_sha=1536612`.

### Status: done

Archive to `project-overlays/astro/TASKS/archive/`. HANDOFF archive to `HANDOFFS/archive/`. Next: TASK A directions filter (separate commit per user direction β); TASK B transit section generic (после TASK A closure).
