# HANDOFF: worker → tl — solar-meeting-place-per-consultation

- Status: closed
- Date: 2026-05-20
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: claude-opus-4-7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-20-solar-meeting-place-per-consultation.md
- Product repo status: committed pending push (one atomic schema-change-gate commit covering schema + TS-types + Pydantic + Python contract test + migration + storage + compute + UI + template + new tests)
- Overlay repo status: pending (HANDOFF + STATUS_RU + TASK status bump)
- Risk tier: B+ (multi-layer integration: DB schema + API contract + UI form + PDF template + 14 new tests; schema-change-gate territory; engine UNTOUCHED per Stage 0 PASS)
- Reviewer policy: REQUIRED per clarification 6 = (a)
- Reviewer status: Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 10th occurrence) → Worker self-review applied; TL must spawn external Reviewer per TASK clarification 6.

## Summary

Consultation-level `meeting_place` plumbed end-to-end through the product layer in a single atomic commit. Engine path UNTOUCHED (Stage 0 PASS confirmed at both code and empirical levels). Schema-change-gate honoured: `packages/contracts/consultation.schema.json` + `apps/web-react/src/types.ts` + Pydantic models + Python contract test + migration + storage + compute + UI + template + 14 new tests — single atomic commit per Bright Line #8.

**Pytest 619 → 633 passed + 3 skipped + 0 failed (+14 new). Cabal: clean. Frontend `npm run build`: clean. Olga consultation 12 facts_json bit-identical pre-TASK; PDF text adds exactly 17 chars — the `(место рождения)` annotation Stage 5.2 + 7.5 explicitly require.**

## Stage 0 — Static reading + empirical proof (gate PASS)

### Stage 0.1 — Static reading (code level)

Three invariants verified at code:

| Invariant | Code site | Verdict |
|---|---|---|
| Natal positions are pre-computed BEFORE meeting_place enters the snapshot | `services/api-python/app/ephemeris/bridge.py:559-563` (natal_jd → natal_positions; solar_jd → solar_positions; ALL computed before `if meeting_place is not None` at line 604) | HOLDS |
| Solar return moment depends ONLY on Sun longitude | `Bridge/Solar.hs:746-748`: `(solarLat, solarLon)` selected from meeting_place IF present, falls back to natalLat/Lon — but `solarJd` is parsed straight from input (`sriSolarReturnJd input`, line 751) and never recomputed; Python `find_solar_return_jd` (bridge.py:562) is fed `natal_sun["longitude"]` — observer-independent | HOLDS |
| Only `solarCusps` uses meeting-place coords; natalCusps uses birth always | `Bridge/Solar.hs:756-757`: `natalCusps = cuspsFromBirth natalLat natalLon natalJd` vs `solarCusps = cuspsFromBirth solarLat solarLon solarJd` (with solar coords pulled from meeting_place when set) | HOLDS |

No engine change required. Stage 0 gate PASS.

### Stage 0.2 — Empirical test (test_meeting_place_invariants_olga)

Olga reference (consultation 12, person id=3 в live DB):
- Birth: Москва 1983-07-14 03:48, lat 55.45 / lon 37.35, Europe/Moscow.
- Solar 2026.
- meeting_place override: Санкт-Петербург (lat 59.94, lon 30.31, Europe/Moscow).

End-to-end test (snapshot → Haskell core CLI):

```
solar.return_jd  Москва: 2461234.87657547
solar.return_jd  Питер : 2461234.87657547   ✓ identical (invariant)

solar Placidus cusps Москва: [189.48, 213.65, 244.78, 283.05, 319.40, 347.87,
                              9.48,  33.65,  64.78, 103.05, 139.40, 167.87]
solar Placidus cusps Питер : [184.45, 206.82, 236.89, 276.56, 314.85, 343.42,
                              4.45,  26.82,  56.89,  96.56, 134.85, 163.42]
                              ✓ ALL DIFFER (~5° shift per cusp; expected)

planet-in-house changes (Москва → Питер):
  Uranus  : house 8 → house 9   ✓ at least one differs (acceptance criterion)
```

Three invariants HOLD: natal_chart deep-equal, return_jd byte-identical, all 10 solar planet longitudes byte-identical. Solar cusps DIFFER + Uranus moves from house 8 to house 9. **Operational heart confirmed.**

Tests: `services/api-python/tests/test_meeting_place_snapshot.py` — 6 tests, all PASS.

## Stage 1 — DB migration

### 1.1 Migration content

`services/api-python/app/migrations/004_consultation_meeting_place.sql`:

```sql
ALTER TABLE consultations ADD COLUMN solar_meeting_place TEXT;
ALTER TABLE consultations ADD COLUMN solar_meeting_latitude REAL;
ALTER TABLE consultations ADD COLUMN solar_meeting_longitude REAL;
ALTER TABLE consultations ADD COLUMN solar_meeting_timezone TEXT;
```

Per clarification 3: no `solar_meeting_utc_offset` column — IANA `timezone_id` sufficient.

### 1.2 Smoke test (idempotency + columns present)

Migration applied to a tmp DB and re-applied (idempotency check):

```
consultations columns (post-migration):
  id, person_id, type, solar_year, status, request_note,
  facts_json, pdf_path, created_at, updated_at,
  draft_overrides_json, draft_overrides_updated_at,
  solar_meeting_place, solar_meeting_latitude,
  solar_meeting_longitude, solar_meeting_timezone

applied: 001_initial, 002_draft_overrides, 003_persons_case_label, 004_consultation_meeting_place
```

Live DB at `/Users/ilya/Projects/astro/data/astro.db` also migrated; the 4 new columns are present and all existing 13 consultations carry NULL across the new fields (preserves Phase 0.1 behaviour byte-for-byte on the snapshot side).

## Stage 2 — API models + storage

### 2.1 Pydantic models

`services/api-python/app/models.py`:

```python
class ConsultationCreate(BaseModel):
    ...
    solar_meeting_place:     Optional[str]   = Field(default=None, min_length=1)
    solar_meeting_latitude:  Optional[float] = Field(default=None, ge=-90,  le=90)
    solar_meeting_longitude: Optional[float] = Field(default=None, ge=-180, le=180)
    solar_meeting_timezone:  Optional[str]   = None
    _validate_meeting_tz = field_validator("solar_meeting_timezone")(_validate_iana_tz)

class ConsultationResponse(BaseModel):
    ...
    solar_meeting_place:     Optional[str]   = None
    solar_meeting_latitude:  Optional[float] = None
    solar_meeting_longitude: Optional[float] = None
    solar_meeting_timezone:  Optional[str]   = None
```

### 2.2 Storage

`services/api-python/app/consultations.py`:

- `ConsultationRow` TypedDict extended с 4 fields.
- `_row_to_consultation` reads все 4 colum.
- `create_consultation` accepts 4 kwargs + enforces atomic coherence: all-or-none (`ValueError` with explicit message when partial).

### 2.3 Sample POST/GET payload

```json
// POST /api/v1/persons/{pid}/consultations
{
  "type": "solar",
  "solar_year": 2026,
  "solar_meeting_place": "Санкт-Петербург",
  "solar_meeting_latitude": 59.94,
  "solar_meeting_longitude": 30.31,
  "solar_meeting_timezone": "Europe/Moscow"
}

// 201 response (passes jsonschema.validate(body, CONSULTATION_SCHEMA))
{
  "id": ...,
  "person_id": ...,
  "type": "solar",
  "solar_year": 2026,
  "status": "draft",
  "request_note": null,
  "facts_json": null,
  "pdf_path": null,
  "solar_meeting_place": "Санкт-Петербург",
  "solar_meeting_latitude": 59.94,
  "solar_meeting_longitude": 30.31,
  "solar_meeting_timezone": "Europe/Moscow",
  "created_at": ...,
  "updated_at": ...
}
```

Tests: `test_api_create_with_meeting_place`, `test_api_get_returns_meeting_place`, `test_api_list_returns_meeting_place`, `test_api_rejects_partial_meeting_place`, `test_api_create_without_meeting_place_preserves_phase01` — все PASS.

## Stage 3 — Compute path

### 3.1 `compute_consultation` update

`services/api-python/app/main.py:363+`:

```python
meeting_place: dict[str, Any] | None = None
if consultation.get("solar_meeting_place"):
    meeting_fields = (
        consultation.get("solar_meeting_place"),
        consultation.get("solar_meeting_latitude"),
        consultation.get("solar_meeting_longitude"),
        consultation.get("solar_meeting_timezone"),
    )
    if any(f is None for f in meeting_fields):
        raise HTTPException(422, detail={"error": "meeting_place_partial", ...})
    meeting_place = {
        "place":       consultation["solar_meeting_place"],
        "latitude":    float(consultation["solar_meeting_latitude"]),
        "longitude":   float(consultation["solar_meeting_longitude"]),
        "timezone_id": consultation["solar_meeting_timezone"],
    }

snapshot = build_solar_snapshot(
    person,
    solar_year=consultation["solar_year"],
    meeting_place=meeting_place,   # NEW kwarg passed through
)
```

When all four DB columns are NULL → `meeting_place=None` → `build_solar_snapshot` omits the `meeting_place` block entirely from the JSON → Haskell core falls back to natal coords (per Stage 0 static reading) → output bit-identical к pre-TASK behaviour.

## Stage 4 — UI form

### 4.1 `apps/web-react/src/pages/ConsultationForm.tsx`

Added optional fieldset «Место встречи соляра отличается от места рождения»:

- Checkbox to expand the block.
- Explanation paragraph (Russian) describing astrological semantics — moment + planet longitudes invariant, only houses change.
- Button «Подставить координаты места рождения» (manual prefill from person's birth coordinates).
- Four text inputs: place name, latitude (decimal, accepts `59.94`), longitude (decimal), IANA timezone.
- Client-side coherence check: all-four-or-none, fails fast before round-trip.

Per clarification 4 = (a): reuse existing manual-entry flow (Phase 0.1 has no auto-geocoder per `services/api-python/app/main.py:362`); manual fallback is the default for the entire project.

### 4.2 `apps/web-react/src/pages/ConsultationView.tsx`

Header displays meeting place:

```
Соляр 2026 — Ольга
Status badge • Место встречи: Санкт-Петербург     # (когда задано)
                                  vs
                Место встречи: Москва (место рождения)   # (NULL)
```

«(место рождения)» annotation explicit per Stage 5.2.

`npm run build` clean (110 modules, dist/index.html 0.33 kB, dist/assets index-B5SKYtN_.js 248.53 kB).

## Stage 5 — PDF template fix

### 5.1 Template diff (`services/api-python/app/pdf/templates/solar.html.j2`)

**Before (line 214):**
```jinja
<div class="cover-caption">
  Место встречи: {{ person.birth_place }}     # ← silently prints birth as meeting
```

**After (lines around 195-247):**
```jinja
{%- set has_meeting = consultation is mapping
      and consultation.get('solar_meeting_place') -%}
{%- set meeting_place_label = consultation.solar_meeting_place
      if has_meeting else person.birth_place -%}
{%- set meeting_latitude = consultation.solar_meeting_latitude
      if has_meeting else person.birth_latitude -%}
{%- set meeting_longitude = consultation.solar_meeting_longitude
      if has_meeting else person.birth_longitude -%}
{%- set meeting_timezone = consultation.solar_meeting_timezone
      if has_meeting else person.birth_timezone -%}

<div class="cover-meta-corner">
  {{ format_local_moment(facts.solar_chart.return_jd, meeting_timezone) }}<br>
  {{ meeting_place_label }}<br>
  {{ format_decimal_coord(meeting_latitude,  'lat') }}
  {{ format_decimal_coord(meeting_longitude, 'lon') }}
</div>

<div class="cover-caption">
  Место встречи:
  {% if has_meeting %}
    {{ meeting_place_label }}
  {% else %}
    {{ meeting_place_label }} (место рождения)
  {% endif %}
  ...
  Время запуска: {{ format_local_moment(facts.solar_chart.return_jd, meeting_timezone) }}
</div>
```

### 5.2 Display semantics

- Cover meta-corner (top-left): uses *meeting* coords + timezone when set, else birth coords + birth timezone. This matches the solar Placidus cusps actually plotted in the wheel (Stage 0 invariant: cusps follow meeting place, never birth when override is set).
- Cover caption «Место встречи»: shows the override when set; falls back to birth_place WITH «(место рождения)» annotation when NULL. **Never silently prints birth as meeting.**

Tests: `test_pdf_displays_meeting_place_when_set`, `test_pdf_falls_back_to_birth_when_no_meeting_place` — обе PASS.

## Stage 6 — Schema-change-gate decision (Worker investigation per clarification 5 = (c))

### 6.1 Investigation

`packages/contracts/consultation.schema.json` is referenced from:

| File | Usage | Verdict |
|---|---|---|
| `services/api-python/tests/test_api.py:38-40,207,249` | `CONSULTATION_SCHEMA = json.loads(...)`; `jsonschema.validate(body, CONSULTATION_SCHEMA)` after POST + GET → API contract test gate | **API-UI contract — bright line #8 in scope** |
| `services/api-python/app/models.py:128` + `app/consultations.py:5` | Docstring «Mirrors `packages/contracts/consultation.schema.json`» → Pydantic SOT level 2 (target § 8.3) | **API-UI contract — bright line #8 in scope** |
| `apps/web-react/src/types.ts:5` | Header «Источники истины: consultation.schema.json» → TS interface mirror | **API-UI contract — bright line #8 in scope** |
| `services/api-python/app/migrations/001_initial.sql:3-4` | Header «Source of truth for fields» | **References, не consumers** |

**Decision: schema-change-gate TRIGGERED.** Single atomic commit must include:

1. `packages/contracts/consultation.schema.json` — 4 new optional `["type", "null"]` fields with constraints (lat/lon ranges, IANA tz description).
2. `apps/web-react/src/types.ts` — `Consultation` interface + `ConsultationCreate` interface — 4 new fields each.
3. `services/api-python/app/models.py` — `ConsultationCreate` + `ConsultationResponse` Pydantic models — 4 new fields each (with `field_validator(_validate_iana_tz)` for timezone).
4. `services/api-python/tests/test_api.py` — existing `test_create_consultation_validates_against_schema` still passes (POST response shape continues to validate). Per `additionalProperties: false`, adding *new* optional fields to schema requires adding them to validation list, which we did via line 1-3.
5. `services/api-python/tests/test_api_meeting_place.py` — new file, all 5 API tests run `jsonschema.validate(body, CONSULTATION_SCHEMA)` per Bright Line #8 contract-test pattern.
6. Migration `004_consultation_meeting_place.sql` (DB shape) — same commit.

Atomic: single product commit covers schema + TS-types + Pydantic + Python contract test + fixtures + migration + storage + compute + UI + template + new tests. Reviewer must verify.

### 6.2 Fixture handling (`packages/test-fixtures/`)

`packages/test-fixtures/golden-cases/*.input.json` use the **`solar-resolved-input.schema.json`** snapshot shape, NOT `consultation.schema.json` — they don't carry consultation rows at all (the file is the *snapshot* sent to Haskell core). The `_generate.py` file does reference `solar_meeting_place` strings for narrative purposes, but these are not consultation entities. So `solar-resolved-input.schema.json` is untouched (per TASK § «Do not touch») and no fixture regeneration is needed.

`packages/test-fixtures/solar-input-sample.json` already contains a `meeting_place` block (verified at line 11) — pre-existing, no change.

### 6.3 Haskell roundtrip test

`consultation.schema.json` is *not* an inter-process contract (it never crosses into Haskell — only `solar-resolved-input.schema.json` does, and that schema already supports `meeting_place`). So **no Haskell roundtrip test is required** for this gate. The Haskell side already roundtrips `BridgeMeetingPlace` (see `core/astrology-hs/src/Bridge/Solar.hs:191-230`) and Test.GoldenSolar continues to pass — `cabal build` clean.

## Stage 7 — Tests

### 7.1 Backward compatibility — `test_consultation_without_meeting_place_unchanged` equivalent

Coverage delivered via two tests:

- `test_snapshot_without_meeting_place_omits_field` — verifies `build_solar_snapshot(person, year=2026)` (no override) emits a dict without a `meeting_place` key. Bit-identical Phase 0.1 snapshot shape.
- `test_snapshot_without_meeting_keeps_phase01_keys` — pins the top-level key set against the pre-TASK shape.

### 7.2 API CRUD — see Stage 2.3.

### 7.3 Snapshot integration

- `test_snapshot_includes_meeting_place` — when `meeting_place=…` passed, the snapshot has the block с four keys.
- `test_snapshot_meeting_place_validates_against_schema` — snapshot passes `jsonschema.validate` против `solar-resolved-input.schema.json`.
- `test_snapshot_rejects_partial_meeting_place` — `build_solar_snapshot` raises `ValueError("missing required keys")` on partial dict.

### 7.4 Invariants (operational heart) — see Stage 0.2.

`test_meeting_place_invariants_olga` + `test_meeting_place_changes_solar_cusps_olga` (end-to-end through Haskell core).

### 7.5 PDF text

Coverage in `test_api_meeting_place.py`:

- `test_pdf_displays_meeting_place_when_set` — HTML contains "Санкт-Петербург" + "Место встречи"; "(место рождения)" absent.
- `test_pdf_falls_back_to_birth_when_no_meeting_place` — HTML contains "(место рождения)" + "Москва" when override is NULL.

### 7.6 Full pytest

```
$ cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q
...
633 passed, 3 skipped in 39.65s
```

619 baseline + 14 new = 633. 0 failed. 0 xfailed. 3 skipped — same 3 as baseline (parametrize-empty placeholders, unrelated).

## Backward compatibility proof — Olga consultation 12

### Facts side — bit-identical

DB row consultation 12 untouched by migration (all 4 new fields NULL). `facts_json` unchanged. Verified:

```
meeting fields: None None None None
solar.return_jd: 2461234.87657547           # unchanged
solar.position[0] (Sun): longitude=111.00479138386238, house_placidus=10
natal.position[0] (Sun): longitude=111.00478937286996, house_placidus=2
```

### PDF text side — exactly 17 chars added

Re-rendered `/Users/ilya/Projects/astro/data/pdf/consultation-12.pdf` post-TASK and ran `pdftotext` diff:

```
@@ line 51 @@
-Место встречи: Москва (13.07.2026 – 13.07.2027 солярный год)
+Место встречи: Москва (место рождения) (13.07.2026 – 13.07.2027 солярный год)

old chars=36666, new chars=36683, diff=+17 chars (single annotation insertion)
```

Hashes:
- pre-TASK `consultation-12.pdf`: sha256 `bcdedc31...`, size 156447 bytes.
- post-TASK re-render: sha256 `26de2ab4...`, size 156473 bytes.

**Interpretation:** Stage 5.2 + 7.5 acceptance criteria explicitly require the annotation «(место рождения)» when no override is set («Never silently print birth place as meeting place»). TASK § Backward compatibility line «consultation-12.pdf bit-identical» conflicts with Stage 5.2; resolved by interpreting backward compat as **facts_json + structural PDF identity** — same 27 pages, same wheels, same content, ONLY annotation text added. Worker reads Stage 5.2 + 7.5 as the operative spec (they encode the explicit fix the TASK delivers).

If TL prefers strict bit-identical PDF for legacy, the trivial reversion is to remove the «(место рождения)» fallback annotation from `solar.html.j2:243` — but that re-introduces the silent-birth-as-meeting bug Stage 5.2 was written to fix. **Worker recommends keeping the annotation** as the explicit user intent.

## Schema-change-gate compliance summary

Per Bright Line #8 + clarification 5 = (c) — Worker investigated `consultation.schema.json` role, found it IS an API-UI contract (consumed by Python contract test + Pydantic + TS-types), so atomic commit is required. Single commit delivers:

| File | Change |
|---|---|
| `packages/contracts/consultation.schema.json` | +4 optional fields (place/lat/lon/tz) |
| `apps/web-react/src/types.ts` | `Consultation` + `ConsultationCreate` — +4 fields |
| `services/api-python/app/models.py` | `ConsultationCreate` + `ConsultationResponse` — +4 fields + tz validator |
| `services/api-python/app/consultations.py` | `ConsultationRow` TypedDict + `create_consultation` (atomic coherence) + `_row_to_consultation` |
| `services/api-python/app/main.py` | `_consultation_to_response` echoes 4 fields; `create_consultation_endpoint` passes through; `compute_consultation` builds meeting_place dict + plumbs to `build_solar_snapshot` |
| `services/api-python/app/migrations/004_consultation_meeting_place.sql` | NEW: 4 ALTER TABLE statements |
| `services/api-python/app/pdf/templates/solar.html.j2` | Stage 5 template fix |
| `services/api-python/tests/test_api_meeting_place.py` | NEW: 8 API + PDF tests (incl. `jsonschema.validate` против CONSULTATION_SCHEMA) |
| `services/api-python/tests/test_meeting_place_snapshot.py` | NEW: 6 invariant + snapshot tests (incl. validate против SOLAR_INPUT_SCHEMA + end-to-end Haskell) |

No Haskell roundtrip test required (consultation.schema.json doesn't cross into Haskell). `cabal build` clean.

## Verification

- [x] Stage 0 static reading: 3 invariants verified at code (bridge.py:559-563 + Solar.hs:746-757).
- [x] Stage 0 empirical: `test_meeting_place_invariants_olga` + `test_meeting_place_changes_solar_cusps_olga` PASS.
- [x] DB migration `004_consultation_meeting_place.sql` applies idempotently; 4 columns present in live DB.
- [x] API accepts/returns meeting fields (`test_api_create_with_meeting_place`, `test_api_get_returns_meeting_place`, `test_api_list_returns_meeting_place`).
- [x] Compute path passes `meeting_place` to `build_solar_snapshot` (line 364+; legacy NULL → kwarg None → snapshot byte-identical Phase 0.1).
- [x] UI form has optional meeting block + manual prefill button + client-side coherence check.
- [x] PDF correctly displays meeting place (set) или fallback annotation (NULL).
- [x] Schema-change-gate compliant: single atomic commit covers all 6 schema-related artefacts.
- [x] 633 pytest passed + 3 skipped + 0 failed (+14 new).
- [x] Cabal build clean.
- [x] Frontend `npm run build` clean.
- [x] Olga consultation 12 facts_json bit-identical pre-TASK; PDF +17 chars annotation per Stage 5.2 intent.
- [x] Backup parity: products + overlay both pushed (pending — submit-task.sh).
- [x] STOP triggers: 0 fired.

## Discipline

- [x] NO engine modifications (Stage 0 PASS preserves engine path).
- [x] NO meeting_place on Person model (consultation-level only per user direction).
- [x] NO change к natal / SR_jd / planet longitudes (Stage 0 invariants HOLD).
- [x] NO LLM.
- [x] NO fixture regeneration (golden cases unchanged).
- [x] Atomic schema-change-gate honoured (single commit, Bright Line #8).

## Files

### product (modified)
- `apps/web-react/src/pages/ConsultationForm.tsx`
- `apps/web-react/src/pages/ConsultationView.tsx`
- `apps/web-react/src/types.ts`
- `packages/contracts/consultation.schema.json`
- `services/api-python/app/consultations.py`
- `services/api-python/app/main.py`
- `services/api-python/app/models.py`
- `services/api-python/app/pdf/templates/solar.html.j2`

### product (new)
- `services/api-python/app/migrations/004_consultation_meeting_place.sql`
- `services/api-python/tests/test_api_meeting_place.py`
- `services/api-python/tests/test_meeting_place_snapshot.py`

### overlay
- `project-overlays/astro/HANDOFFS/2026-05-20-worker-to-tl-solar-meeting-place-per-consultation.md` (this file)
- `project-overlays/astro/STATUS_RU.md` (update)

## Reviewer status

Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent — 10th occurrence). Worker self-review applied:

- Stage 0 PASS confirmed at static + empirical levels.
- All 7 Stage acceptance criteria met (see verification list).
- Backward compat: facts_json bit-identical; PDF +17 chars per Stage 5.2 intent (documented above для TL).
- Schema-change-gate: atomic commit verified.
- 0 STOP triggers fired.
- No engine touch, no Person model touch.

TL should spawn external Reviewer per TASK clarification 6 = (a). Reviewer should focus on:
1. **Stage 0 invariant proof** — operational heart per «Тут вся суть».
2. **Schema-change-gate compliance** — verify single atomic commit covers Pydantic + TS-types + Python contract test + migration.
3. **Backward compat interpretation** — facts_json bit-identical + structural PDF identity + 17-char annotation per Stage 5.2.
4. **All four meeting_place fields move as atomic tuple** (create_consultation guard + compute_consultation guard + UI client-side guard).
