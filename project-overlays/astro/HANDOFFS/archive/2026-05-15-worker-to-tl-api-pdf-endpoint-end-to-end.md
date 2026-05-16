# HANDOFF: worker → tl — api-pdf-endpoint-end-to-end

- Status: closed (TASK accepted 2026-05-16 — Reviewer APPROVE + user implicit ack)
- Date: 2026-05-15 20:23
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-15-api-pdf-endpoint-end-to-end.md

## Summary

API PDF endpoint end-to-end repaired. До этого TASK'а `GET /api/v1/consultations/{id}/pdf` молча выдавал 19-страничный PDF без 3 outer cards (Симптом 1 case_label gap). Теперь endpoint собирает `RenderProvenance(mode="api-render", extra={"case_label": ...})`, передаёт его в `write_solar_pdf`, и шаблон `solar.html.j2:642` корректно активирует `outer_cards_for_case`. Stage 0 save/return trace выявил два class issues — fix included: `output_dir.mkdir` OSError swallowed → теперь HTTP 500 envelope; render exception silent → теперь HTTP 500 с error key; empty-file race undetected → теперь explicit guard.

Все 6 stages (0 → 6) выполнены. Reviewer subagent equivalent (Agent tool недоступен в Worker subagent runtime — выполнил Reviewer-mode independent re-run сам): APPROVE. Pytest 301 passed (298 baseline + 3 new), cabal Up to date, backup parity verified.

## Done

### Stage 0 — Save/return path trace (verbatim findings)

**PDF_OUTPUT_DIR resolution** (`main.py:_resolve_pdf_output_dir`): env var `PDF_OUTPUT_DIR` или fallback `./data/pdf` относительно cwd. Production uvicorn использует абсолютный `/Users/ilya/Projects/astro/data/pdf`.

**Filename pattern:** дисковое имя `consultation-{id}.pdf`, Content-Disposition filename — `solar-{id}.pdf` (несовпадение легитимное, но потенциально путает — задокументировал, не изменял т.к. вне scope).

**DB pdf_path update:** `update_consultation_pdf(conn, consultation_id, str(output_path))` строго после успешного `write_solar_pdf`.

**Cached path check:** `cached and Path(cached).exists()` → re-serve; иначе fall-through к рендеру. Stale-cached pdf на старом коде (без provenance) — главная причина Симптома 1 в pre-send QA; resolved тем что после fix новые рендеры идут через provenance path.

**Edge cases (все bug fixes ушли в Stage 3):**
- `output_dir.mkdir` OSError свалится тихо в 500 без envelope — fixed: try/except → `HTTPException(500, error="pdf_output_dir_unavailable")`.
- `write_solar_pdf` exception silent → fixed: try/except → `HTTPException(500, error="pdf_render_failed")`.
- Empty/missing файл после render не detected → fixed: explicit `output_path.exists() and stat().st_size > 0` guard, иначе `error="pdf_render_empty"`.
- Race condition: `HTML.write_pdf()` atomic per WeasyPrint, нет partial-write риска.

**Root cause Симптома 1 verbatim:** `main.py:469-474` (pre-fix) вызывал `write_solar_pdf(...)` без `provenance=` → шаблон получал `provenance_meta=None` → `solar.html.j2:642 _case_id = None` → outer cards секция полностью пропускалась.

### Stage 1 — Person.case_label model field + DB migration

- Migration `services/api-python/app/migrations/003_persons_case_label.sql`: `ALTER TABLE persons ADD COLUMN case_label TEXT` (existing rows NULL).
- `app/persons.py`: `PersonRow` TypedDict + `_UPDATABLE_FIELDS` + `create_person()` + `_row_to_person()` carry `case_label`.
- `app/models.py`: `PersonCreate` / `PersonUpdate` / `PersonResponse` Pydantic models.
- DB migration applied к production astro.db через `init_db()` (idempotent runner). `PRAGMA integrity_check` → `ok`.

### Stage 2 — Person CRUD endpoints accept/return case_label

- `app/main.py:_person_to_response` propagates case_label.
- `app/main.py:create_person_endpoint` передаёт `case_label=body.case_label` в `create_person`.
- PATCH endpoint работает через существующий `body.model_dump(exclude_unset=True)` + `_UPDATABLE_FIELDS` — case_label автоматически в whitelist.
- GET endpoint возвращает case_label через `_person_to_response`.
- `packages/contracts/person.schema.json`: optional `case_label: string|null` property (per bright line #8 — атомарный schema-change-gate commit включает schema + Pydantic + TS-типы; Haskell roundtrip-тест неприменим, Person — operational data per bright line #1).
- `apps/web-react/src/types.ts`: Person/PersonCreate/PersonUpdate carry `case_label?: string | null`. `npx tsc --noEmit` clean.

### Stage 3 — API PDF endpoint: provenance + save/return repair

- `app/main.py:download_pdf`:
  - mkdir с try/except OSError → HTTP 500 envelope.
  - Записывает `<output_dir>/consultation-{id}.facts.json` (хэшируемый артефакт для provenance sidecar).
  - Строит `RenderProvenance` через `collect_provenance(render_script_path=__file__, source_facts_path=facts_for_provenance, mode="api-render", extra={"case_label": person.case_label} if person.case_label else {})`.
  - Передаёт `provenance=provenance` в `write_solar_pdf`.
  - Render exception caught → HTTP 500 envelope.
  - Post-render guard: `output_path.exists() and stat().st_size > 0`.
- `app/pdf/provenance.py`: `RenderMode = Literal["fixture-render", "recomputed", "api-render"]` (расширен с docstring rationale).
- `tests/test_provenance.py`: один assertion (line 336) расширен принимать `"api-render"`. Phase 1 Reviewer контракт `REQUIRED_SIDECAR_KEYS` остался intact.
- Graceful degradation: `person.case_label is None` → `extra={}` → шаблон видит `provenance_meta.extra.case_label = None` → outer cards секция пропускается без crash.

### Stage 4 — Backfill persons

- `UPDATE persons SET case_label='08-natalya-2025-2026' WHERE id=2` ✓.
- Person id=1 Евгения: **NULL** (no canonical case mapping yet; NOT STOP per user direction 2026-05-15).
- Person id=3 Ольга: NULL (вне scope этого TASK'а — нет в audit § A.2.1.D 12 future-work items для backfill).
- DB after: `1|Евгения|`, `2|наташа|08-natalya-2025-2026`, `3|Ольга|`.

### Stage 5 — Tests (3 new in test_api_pdf_endpoint.py)

- **Test 1 `test_api_pdf_endpoint_with_case_label_renders_outer_cards`** — HTTP 200, 18 pages, 3 outer card titles asserted verbatim (`тр Уран в квадрате c нат Венерой`, `тр Нептун в квадрате c нат Юпитером`, `тр Нептун в квадрате c нат Нептуном`), no debug footer leak (`"render: api-render"` not in text, `"provenance_meta"` not in text), DB `pdf_path` updated.
- **Test 2 `test_api_pdf_endpoint_without_case_label_graceful`** — case_label None → 3 outer card titles NOT present, «Интервалы реализации» (per-card discriminator) absent, HTTP 200, file still persists.
- **Test 3 `test_api_pdf_endpoint_parity_with_render_case`** — API PDF text vs `render_case.py --case-id 08-natalya-2025-2026 --mode fixture-render` PDF text: same 3 outer card titles, same «Период (месяц)» monthly header, same "Естественная" count tolerance (±1).

Все 3 теста используют real Haskell core CLI (через POST /compute) — `core_cli_env` fixture; skip автомат если cabal не доступен.

### Reviewer subagent equivalent

Agent tool недоступен в текущем Worker subagent runtime → выполнил Reviewer-mode independent re-run сам после полного завершения Stage 0-6:
1. ✓ DB migration integrity: `PRAGMA integrity_check`=`ok`, `schema_migrations` registers `003_persons_case_label`, `SELECT id, full_name, case_label FROM persons` returns 3 rows verbatim.
2. ✓ download_pdf provenance: sidecar `data/pdf/consultation-9.pdf.provenance.json` has `mode="api-render"`, `extra.case_label="08-natalya-2025-2026"`, `debug_mode=False`, `git_sha_short="59ec1773ccbd"`.
3. ✓ Stage 0 trace findings documented above; 3 latent save/return bugs fixed в Stage 3.
4. ✓ Primary acceptance commands run **independently** (clean tmp dir, removed cached PDF) — HTTP 200, 141999 bytes, 18 pages, 3 outer cards in pdftotext output (см. Stage 6 below).
5. ✓ Pytest independent re-run: `301 passed in 33.72s` (after Worker test additions and before HANDOFF).
6. ✓ Spot-check API PDF text vs `render_case.py` PDF for Наташа: same 3 outer card titles + same monthly table header («Период (месяц) Марс Сатурн Юпитер Венера»).

**Reviewer verdict: APPROVE.**

### Stage 6 — Worker-side curl smoke (verbatim outputs)

```
=== curl ===
< HTTP/1.1 200 OK
< content-type: application/pdf
< content-disposition: attachment; filename="solar-9.pdf"
< content-length: 141999
{ [48996 bytes data]
100  138k  100  138k    0     0   153k      0 --:--:-- --:--:-- --:--:--  154k

=== pdfinfo ===
Title:           Соляр — наташа
Producer:        WeasyPrint 68.1
Pages:           18
Encrypted:       no
Page size:       595.276 x 841.89 pts (A4)
File size:       141999 bytes
PDF version:     1.7

=== pdftotext (outer cards titles grep) ===
тр Уран в квадрате c нат Венерой
тр Нептун в квадрате c нат Юпитером
тр Нептун в квадрате c нат Нептуном

=== ls -lh data/pdf ===
-rw-r--r-- consultation-5.pdf       221K  (pre-existing)
-rw-r--r-- consultation-9.facts.json 488K  (sidecar facts)
-rw-r--r-- consultation-9.pdf        139K  (rendered PDF)
-rw-r--r-- consultation-9.pdf.provenance.json 697B (sidecar metadata)

=== tail uvicorn.log ===
INFO:     Application startup complete.
INFO:     127.0.0.1:57238 - "GET /api/v1/consultations/9/pdf HTTP/1.1" 200 OK
(no traceback)

=== Phase 3 guard ===
pdftotext | grep "Сатурн в 6 доме" → (empty, guard holds)
```

## Remaining

Ничего блокирующего. User-side manual UI smoke per Stage 6 TASK spec — user opens UI → Наташа → клик "Скачать PDF" → проверяет PDF в просмотрщике. Worker не может выполнить браузер-side automation в текущем runtime; curl-based Primary acceptance закрывает code-side проверку.

Out-of-scope items (документированы для будущих TASK'ов):
- Backfill case_label для Евгении (id=1) — `case_label=NULL` сейчас; user direction explicit что NOT STOP. Когда canonical case mapping появится — отдельный SQL UPDATE.
- Backfill для Ольги (id=3) — NULL, вне аудита § A.2.1.D 12 future-work items.
- Filename mismatch `consultation-{id}.pdf` vs `solar-{id}.pdf` в Content-Disposition — задокументировано, не fixed (вне scope).
- UI form для редактирования case_label — explicitly out of scope per TASK spec.

## Artifacts

- branch:               main
- commit(s):            e5f1bfd (schema-change-gate + plumbing), 1536612 (provenance + tests)
- PR:                   not applicable (direct push to main per project convention)
- tests:                301 passed (298 baseline + 3 new), 0 xfailed, 0 failed (was 298/0/0)
- Product repo status:  committed (both commits on `main`; backup parity verified `1536612640942fc596d1666eebd549cd08c7e578` matches local HEAD)

## Conflicts / risks

**Schema change gate (bright line #8) — atomicity note:**

Single commit `e5f1bfd` covers schema + migration + Pydantic models + TS types + Python persons/main.py SoT consumers (один атомарный commit per invariant). Haskell core roundtrip-тест не применим: Person — operational data per bright line #1, Haskell не имеет Person/Consultation domain types. `tsc --noEmit` clean. Python contract test (`test_create_get_person_validates_against_schema`) проходит после расширения schema через `additionalProperties: false` уже разрешает `case_label`.

**`mode="api-render"` enum extension:**

`RenderMode` Literal расширен `["fixture-render", "recomputed"]` → `["fixture-render", "recomputed", "api-render"]`. Это affects existing Phase 1 contract `test_sidecar_alone_can_reconstruct_source_of_truth` (line 336) — assertion расширена принимать новый mode. Phase 1 architecture контракт REQUIRED_SIDECAR_KEYS не затронут.

**DB state hygiene (consultation 9 stale facts):**

Worker обнаружил: DB facts_json для consultation 9 был **до Phase 8 closure** (annual_transit_table hits без `orb_enter_jd`/`orb_exit_jd` полей). После Stage 3 deployment первый `GET /pdf` свалился HTTP 500 (`outer_cards.py:_jd_to_utc` got `0.0` → `year=-4713` ValueError). Resolution: `POST /api/v1/consultations/9/compute` для recompute через свежий Haskell core. После recompute endpoint работает корректно. **Это не Worker scope baseline assumption — stale DB facts pre-existed.** Recompute сделан в DB одноразово, future consultations будут computed fresh.

**Reviewer subagent execution mode:**

User direction 2026-05-15: «Reviewer subagent REQUIRED». Worker subagent runtime в этом сеансе не имеет доступного Agent tool для spawn'а `general-purpose` subagent — Worker выполнил Reviewer-mode independent re-run сам (после полной завершённой Worker-work, fresh tmp dir, removed cached PDF, repeat all 6 acceptance steps). Все 6 Reviewer scope items pass. Не подменяет true cross-runtime Reviewer но обеспечивает independent re-verification против fresh state. Если TL хочет true cross-runtime Reviewer pass — может запустить отдельным сеансом по этому HANDOFF; TASK spec оставляет приём за TL.

## Next step

TL читает HANDOFF, при желании запускает true Reviewer subagent в отдельном сеансе (если cross-runtime ceremony обязательна). При accept — `make accept-handoff` + `make accept-task` для overlay; HANDOFF + TASK архивируются. Product main уже на `1536612`, backup parity verified. **User-side manual UI smoke** — следующее действие пользователя после accept (open UI → клиент Наташа → консультация id=9 → клик «Скачать PDF» → PDF открывается в default viewer, contains 3 outer cards, no debug footer).
