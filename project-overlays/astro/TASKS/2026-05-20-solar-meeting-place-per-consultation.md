# TASK: solar-meeting-place-per-consultation

- Status: open
- Ready: yes
- Date: 2026-05-20
- Project: astro
- Layer: services + frontend integration (DB migration + Python models/API + UI form + PDF template; engine UNTOUCHED if Stage 0 PASS)
- Risk tier: B+ (multi-layer integration: DB schema + API contract + UI form + template + tests; schema-change-gate territory per Bright Line #8; engine already supports meeting_place per Stage 0)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User Marina-show preparation audit 2026-05-20 identified real product gap: **`meeting_place` per consultation отсутствует в product layer, хотя core engine уже его поддерживает.**

Astrological semantics: solar return moment computes для birth place (Sun returns to natal ecliptic longitude), но **место наблюдения соляра (где клиент будет встречать год) определяет ASC/MC/houses соляра.** Если клиент родился в Москве и встречает соляр в Питере — houses соляра должны быть посчитаны для Питера, а планеты в этих домах распределены по их Питерским кустам.

**Stage 0 prelim verification (user code review 2026-05-20):**
- `services/api-python/app/ephemeris/bridge.py:509` принимает `meeting_place` (optional dict с place/latitude/longitude/timezone_id).
- `core/astrology-hs/src/Bridge/Solar.hs:115` parses `meeting_place` field из input JSON.
- `core/astrology-hs/src/Bridge/Solar.hs:745+` строит `solarCusps` через `meeting_place` (если задан) OR fallback на birth coordinates.
- `packages/contracts/solar-resolved-input.schema.json` уже содержит `meeting_place` field в input contract.

**Gap (product layer):**
- `services/api-python/app/models.py:117` (`ConsultationCreate` / `ConsultationResponse`) НЕ содержит meeting place fields.
- `services/api-python/app/consultations.py:34` (`create_consultation`) не persist'ит meeting place.
- `services/api-python/app/migrations/001_initial.sql:24` (consultations table) не имеет meeting columns.
- `services/api-python/app/main.py:364` (`compute_consultation`) вызывает `build_solar_snapshot(person, solar_year=...)` без `meeting_place` → engine falls back to birth → solar houses computed for birth place.
- `services/api-python/app/pdf/templates/solar.html.j2:214` пишет «Место встречи» как `person.birth_place` (фактически место рождения подаётся как место встречи — **factually incorrect** для клиента, который встречает соляр в другом городе).

**Programme classification:** multi-layer product gap. Core engine ready; presentation/storage/UI/template need to plumb meeting_place through. Schema-change-gate territory (consultation contract change).

## Worker framing (verbatim user direction 2026-05-20)

> «Натал строится по месту рождения. Солярный момент и положения планет не меняются. Меняются только дома/углы соляра: ASC/MC/куспиды/планеты по домам соляра.»

> «Без этого соляр может быть построен на неправильные дома. Это надо делать следующим нормальным TASK'ом.»

> «**Engine changes запрещены unless Stage 0 proves core path broken.**»

## Scope (Tier B+ multi-layer integration)

### Stage 0 — Trace existing core support (gate prerequisite)

Worker verifies (per user direction):

**0.1 — `meeting_place` in JSON schema:**
- Read `packages/contracts/solar-resolved-input.schema.json` — confirm `meeting_place` field optional с required sub-fields (place / latitude / longitude / timezone_id).

**0.2 — Python bridge:**
- Read `services/api-python/app/ephemeris/bridge.py:509-630` — confirm `meeting_place` parameter signature, validation logic, passthrough to subprocess.

**0.3 — Haskell bridge:**
- Read `core/astrology-hs/src/Bridge/Solar.hs:110-150` (parsing) + `:745-790` (solar cusps logic).
- **Critical verification:** prove `meeting_place` affects ONLY `solarCusps` (Placidus houses), NOT:
  - `natalCusps` (natal chart unchanged).
  - `solarReturnJd` (solar return moment unchanged — depends on Sun longitude, not observation place).
  - `solarPos` planet longitudes (planet positions at SR moment unchanged).
  
- **`bscPlacements` (planet-in-house mapping for solar) DOES change** (because Placidus cusps shift), but planet longitudes themselves remain identical.

**0.4 — Stage 0 gate criterion (per user clarification 1 = (c) both static + empirical):**

Worker must complete **both** (Phase 9.x meta-lesson strict Stage 0 pattern):

- (a) **Static code reading** verifying all 3 invariants above (natal unchanged, SR_jd unchanged, planet longitudes unchanged).
- (b) **Empirical test:** construct synthetic facts с meeting_place=Санкт-Петербург vs meeting_place=None для same Olga input; verify:
  - `natalCusps`, `solarReturnJd`, `solarPos.longitudes` bit-identical (3 invariants HOLD).
  - `solarCusps`, `solarPos.house_placidus` (planet-in-house) DIFFER (expected change).

**Critical (per user emphasis 2026-05-20): «Acceptance должен обязательно доказать инвариант: `solar_return_jd` + solar planet longitudes unchanged, а solar cusps/Asc/MC changed. Тут вся суть.»**

Empirical test становится permanent acceptance test (Stage 7.4) — not just Stage 0 gate.

**If any invariant violated → STOP, escalate Tier A.** Engine changes only allowed после user authorization.

### Stage 1 — DB migration

**1.1 — New migration `004_consultation_meeting_place.sql` (per user clarification 2 = (a) single atomic):**

```sql
-- Add solar meeting place fields to consultations table.
-- Existing rows: NULL → engine fallback to person's birth coordinates.
ALTER TABLE consultations ADD COLUMN solar_meeting_place TEXT;
ALTER TABLE consultations ADD COLUMN solar_meeting_latitude REAL;
ALTER TABLE consultations ADD COLUMN solar_meeting_longitude REAL;
ALTER TABLE consultations ADD COLUMN solar_meeting_timezone TEXT;
```

**Per user clarification 3 = (b):** `solar_meeting_utc_offset` field NOT included. `timezone_id` (IANA) sufficient — engine resolves UTC offset через pytz/zoneinfo. Avoid duplication.

4 columns atomic — all logically belong vmeste (one meeting place tuple). Standard ALTER TABLE pattern (precedent: `003_persons_case_label.sql`).

**1.2 — Migration runner:** update `app/db.py` migration list if explicit registry; OR ensure auto-discovery picks up new file.

**1.3 — Idempotency:** verify migration is safe to re-run (skip if columns exist) — standard pattern для SQLite ADD COLUMN.

### Stage 2 — API models/storage

**2.1 — `ConsultationCreate` Pydantic model:**

```python
class ConsultationCreate(BaseModel):
    person_id: int
    type: Literal["solar"]
    solar_year: int
    request_note: str | None = None
    # NEW:
    solar_meeting_place: str | None = None
    solar_meeting_latitude: float | None = None
    solar_meeting_longitude: float | None = None
    solar_meeting_timezone: str | None = None
```

**2.2 — `ConsultationResponse` model:**

Same 4 fields surfaced in GET/list endpoints.

**2.3 — `create_consultation` storage:**

INSERT statement extended с 4 new columns; NULL когда не задано.

**2.4 — Persist atomic:** consultation_id allocated only после successful INSERT.

### Stage 3 — Compute path

**3.1 — In `compute_consultation` (`main.py`):**

```python
# Existing:
person = get_person(conn, consultation["person_id"])

# NEW:
meeting_place = None
if consultation.get("solar_meeting_place"):
    meeting_place = {
        "place": consultation["solar_meeting_place"],
        "latitude": consultation["solar_meeting_latitude"],
        "longitude": consultation["solar_meeting_longitude"],
        "timezone_id": consultation["solar_meeting_timezone"],
    }

# Existing call updated:
facts = build_solar_snapshot(
    person,
    solar_year=consultation["solar_year"],
    meeting_place=meeting_place,  # NEW kwarg
)
```

**3.2 — Backward compat:** consultations без meeting fields (legacy + new-with-empty) pass `meeting_place=None` → engine falls back to birth coordinates → output bit-identical к pre-TASK behavior.

### Stage 4 — UI

**4.1 — Consultation creation form** в `apps/web-react/`:

Optional block «Место встречи соляра» с fields:
- `solar_meeting_place` (text input + geocode button).
- `solar_meeting_latitude` (read-only if geocoded; editable manual).
- `solar_meeting_longitude` (same).
- `solar_meeting_timezone` (auto-resolved или manual IANA).

Default empty → engine uses birth place fallback.

**4.2 — Geocoding (per user clarification 4 = (a) reuse existing + manual fallback allowed):**

Reuse existing person birth-place geocode flow (Nominatim + timezonefinder pipeline). UI calls same геокод endpoint that birth_place uses; result fills lat/long/timezone fields.

**Manual override fallback** (per user direction 2026-05-20): if geocode fails OR user prefers manual entry, allow direct typing of lat/long/timezone_id. UX detail: geocode button → on success populate fields; on failure show error + allow manual entry.

**4.3 — Consultation page display:** show saved meeting place + indicator «(место рождения)» если не задан.

### Stage 5 — PDF template fix

**5.1 — `solar.html.j2:214` template:**

Current (buggy):
```html
<!-- Currently prints person.birth_place as "Место встречи" -->
```

Fixed:
```html
{% if consultation.solar_meeting_place %}
  <p>Место встречи соляра: {{ consultation.solar_meeting_place }}</p>
{% else %}
  <p>Место встречи соляра: {{ person.birth_place }} (место рождения)</p>
{% endif %}
```

**5.2 — Display semantics:**
- «Место рождения» always shows `person.birth_place`.
- «Место встречи соляра» shows `consultation.solar_meeting_place` if set; else falls back с annotation «(место рождения)».
- Never silently print birth place as meeting place.

### Stage 6 — Schema-change-gate compliance (Bright Line #8, per user clarification 5 = (c) Worker verifies)

Per CLAUDE.md Bright Line #8: «Any change of `packages/contracts/*.schema.json` — one commit with all related changes (fixtures + Haskell roundtrip-test + Python contract-test + TS-types).»

User direction 2026-05-20 verbatim: «Если `consultation.schema.json` является API/UI contract, обновлять атомарно.»

Worker investigates first:
1. Read `packages/contracts/consultation.schema.json` — is it API-UI contract (Consultation entity for frontend type-safety) OR engine I/O (no, only `solar-resolved-input` is engine I/O).
2. If `consultation.schema.json` is API-UI contract → meeting fields MUST be added + atomic commit across:
   - `packages/contracts/consultation.schema.json` (add 4 fields).
   - `apps/web-react/src/types.ts` (`Consultation` interface).
   - Pydantic models в `app/models.py`.
   - Python contract-test if exists.
   - Atomic single commit per Bright Line #8.
3. If `consultation.schema.json` is NOT API-UI contract (e.g. only internal Python schema) → document в HANDOFF why no contract update needed.

Worker reports schema-change-gate decision + rationale в HANDOFF.

### Stage 7 — Tests

**7.1 — Legacy backward compat:**

```python
def test_consultation_without_meeting_place_unchanged():
    """Existing consultations (NULL meeting fields) produce same output as pre-TASK."""
    # Render consultation 12 (Olga) WITHOUT meeting fields → 
    # output bit-identical к pre-TASK baseline.
```

**7.2 — API create/get/list:**

```python
def test_api_create_with_meeting_place():
    response = client.post("/api/v1/consultations", json={
        "person_id": ..., "type": "solar", "solar_year": 2026,
        "solar_meeting_place": "Санкт-Петербург",
        "solar_meeting_latitude": 59.94, "solar_meeting_longitude": 30.31,
        "solar_meeting_timezone": "Europe/Moscow",
    })
    assert response.status_code == 201
    assert response.json()["solar_meeting_place"] == "Санкт-Петербург"
```

**7.3 — Snapshot integration:**

```python
def test_snapshot_includes_meeting_place():
    facts = build_solar_snapshot(person, solar_year=2026, meeting_place={
        "place": "Санкт-Петербург", "latitude": 59.94,
        "longitude": 30.31, "timezone_id": "Europe/Moscow",
    })
    assert "meeting_place" in facts["solar_resolved_input"]
```

**7.4 — Different meeting place invariants (Stage 0 empirical guards):**

```python
def test_meeting_place_changes_solar_cusps_only():
    """Different meeting place changes solar ASC/MC/cusps; everything else unchanged."""
    facts_birth = build_solar_snapshot(olga, solar_year=2026)
    facts_spb = build_solar_snapshot(olga, solar_year=2026, meeting_place={
        "place": "Санкт-Петербург", ...
    })
    # Natal unchanged
    assert facts_birth["natal_chart"] == facts_spb["natal_chart"]
    # SR_jd unchanged
    assert facts_birth["solar_chart"]["return_jd"] == facts_spb["solar_chart"]["return_jd"]
    # Planet longitudes unchanged
    for p_birth, p_spb in zip(facts_birth["solar_chart"]["positions"], facts_spb["solar_chart"]["positions"]):
        assert p_birth["longitude"] == p_spb["longitude"]
    # Solar cusps DIFFER
    assert facts_birth["solar_chart"]["asc_sign"] != facts_spb["solar_chart"]["asc_sign"] OR
           facts_birth["solar_chart"]["positions"][i]["house_placidus"] != facts_spb["solar_chart"]["positions"][i]["house_placidus"]
```

**7.5 — PDF text shows correct meeting place:**

```python
def test_pdf_displays_meeting_place_when_set():
    facts = render_with_meeting_place("Санкт-Петербург", ...)
    pdf_text = extract_pdf_text(facts)
    assert "Санкт-Петербург" in pdf_text
    assert "Место встречи соляра" in pdf_text

def test_pdf_falls_back_to_birth_when_no_meeting_place():
    facts = render_without_meeting_place()
    pdf_text = extract_pdf_text(facts)
    assert "(место рождения)" in pdf_text  # explicit fallback annotation
```

## Files

- modify:
  - `services/api-python/app/migrations/` — new file `004_consultation_meeting_place.sql`.
  - `services/api-python/app/models.py` — `ConsultationCreate` / `ConsultationResponse` + 4 fields.
  - `services/api-python/app/consultations.py` — `create_consultation` persist + getters.
  - `services/api-python/app/main.py` — `compute_consultation` plumbing + `download_pdf` provenance.
  - `services/api-python/app/pdf/templates/solar.html.j2` — meeting place display fix (line 214 region).
  - `apps/web-react/src/` — consultation creation form + display.
  - `apps/web-react/src/types.ts` — `Consultation` interface (schema-change-gate atomic per Bright Line #8).
  - `packages/contracts/consultation.schema.json` — IF needed per § Ready clarification 5.
  - `services/api-python/tests/test_api_consultations.py` (или новый файл) — API tests.
  - `services/api-python/tests/test_meeting_place_snapshot.py` (new) — snapshot integration tests.
  - `services/api-python/tests/test_solar_pdf_render.py` (или существующий) — PDF text tests.
  - `project-overlays/astro/STATUS_RU.md`.

- new: migration file + maybe test files per Worker discretion.

- delete: —

## Do not touch

- **Engine: Haskell core, schema, fixtures** — IF Stage 0 PASS (which prelim review confirms). If Stage 0 FAIL → escalate Tier A для engine work.
- `core/astrology-hs/src/Bridge/Solar.hs` — already supports meeting_place; do not modify.
- `packages/contracts/solar-resolved-input.schema.json` — already has meeting_place; do not modify.
- `services/api-python/app/ephemeris/bridge.py` — already accepts meeting_place parameter; verify pass-through, no modify.
- Phase 4/7/8 calibrated allowlist / `_OUTER_CARD_FACTS`.
- Phase 9.x artifacts.
- `_legacy_compose_theme_prose` orphan.
- Person.case_label / Phase 4b structured overrides.
- **DO NOT store meeting_place on Person.** Per user direction: different solar years can be met в different cities; meeting_place belongs to consultation level only.
- **DO NOT change natal_chart computation** in response to meeting_place.
- **DO NOT change solar_return_jd** in response to meeting_place.
- **DO NOT change planet longitudes** at SR moment.
- **DO NOT introduce new engine dependencies.**

## Acceptance

### Stage 0 gate (prerequisite)

- [ ] Static code reading confirms 3 invariants (natal / SR_jd / planet longitudes unchanged).
- [ ] Empirical test PASSES (Olga + synthetic meeting_place Питер) — 3 invariants hold, only solar cusps + planet-in-house differ.
- [ ] If Stage 0 FAIL → STOP, escalate.

### Functional acceptance

- [ ] DB migration `004_consultation_meeting_place.sql` applies cleanly (idempotent).
- [ ] `ConsultationCreate` accepts meeting fields (POST endpoint).
- [ ] `ConsultationResponse` returns meeting fields (GET/list endpoints).
- [ ] `compute_consultation` passes meeting_place to `build_solar_snapshot`.
- [ ] UI consultation creation form has optional meeting place block.
- [ ] PDF template shows correct meeting place (set / fallback annotation).
- [ ] All 7.x tests pass.

### Backward compatibility

- [ ] Legacy consultations (NULL meeting fields) render bit-identical к pre-TASK baseline.
- [ ] Olga consultation 12 (no meeting_place set) — same PDF output as pre-TASK.
- [ ] Calibrated allowlist cases unchanged.

### Schema-change-gate (Bright Line #8)

- [ ] If `packages/contracts/consultation.schema.json` modified → atomic commit с TS-types + Pydantic + Python contract test + fixtures (per Bright Line #8).
- [ ] If no contract change needed → document why в HANDOFF.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 619 + N`. 0 failed, 0 xfailed.
- [ ] Frontend `npm run build` clean (TS types check).
- [ ] `git status --short` clean for intended changes.
- [ ] Single atomic commit if schema-change-gate triggered; OR separate commits product/overlay if not.
- [ ] Push backup, parity verified.
- [ ] Reviewer pass per § Ready clarification 6.

### Discipline

- [ ] NO engine modifications (Stage 0 PASS preserves engine path).
- [ ] NO meeting_place on Person model.
- [ ] NO change к natal / SR_jd / planet longitudes.
- [ ] NO LLM.
- [ ] All tests use existing facts data; no fixture regeneration без justification.
- [ ] Atomic schema-change-gate если contracts touched.

## STOP triggers

- Stage 0 verification reveals engine breakage → STOP, escalate Tier A (engine change forbidden without user authorization).
- Worker stores meeting_place on Person model → STOP per user direction.
- Worker changes natal chart computation → STOP, invariant violation.
- Worker changes `solar_return_jd` → STOP, invariant violation.
- Worker changes solar planet longitudes → STOP, invariant violation.
- Template continues to print birth place as meeting place when meeting set → STOP, bug not fixed.
- Worker regenerates fixtures без justification → STOP, hidden regression risk.
- Schema-change-gate violated (contracts modified but TS-types or fixtures not in same commit) → STOP per Bright Line #8.
- Worker tempted to modify `solar-resolved-input.schema.json` — STOP, already has meeting_place; out of scope.
- Worker tempted to modify Haskell — STOP unless Stage 0 FAIL.

## Reviewer subagent — REQUIRED (per user clarification 6 = (a))

External Reviewer pass REQUIRED после Worker self-submit. Parallel к Tier B+ predecessor pattern (Human-Readable / Specificity / Generic Psychology / Current-Year all used REQUIRED). If Agent tool unavailable в Worker runtime (recurring Phase 8/9 precedent), Worker self-review + TL spawns external Reviewer post-submission.

**Reviewer criteria:**
- **Stage 0 invariants verified:** static code reading + empirical test pass (Phase 9.x meta-lesson strict).
- **Critical invariant proof:** acceptance test demonstrates `solar_return_jd` + solar planet longitudes IDENTICAL для meeting_place=Питер vs None; solar cusps/Asc/MC DIFFER. **«Тут вся суть»** per user direction 2026-05-20.
- DB migration applies cleanly (idempotent).
- API contract: `ConsultationCreate/Response` accept/return meeting fields.
- Compute path correctly passes meeting_place through `build_solar_snapshot`.
- UI form has optional block + reuses geocode flow + manual fallback.
- PDF template correctly shows meeting place (set / fallback annotation); NEVER prints birth as meeting silently.
- Schema-change-gate compliance verified per user clarification 5 = (c): Worker investigated `consultation.schema.json` role; если API-UI contract → atomic commit; если не — documented why.
- Backward compat: legacy consultations (NULL meeting fields) produce bit-identical output к pre-TASK baseline.
- Meeting_place stored ONLY on consultation, NEVER on Person.
- 0 STOP triggers fired.

## Context

**Mode normal + Tier B+ (Reviewer REQUIRED per user clarification 6).** Worker mode: normal.

## Critical invariant emphasis (per user direction 2026-05-20, verbatim)

> «Главное уточнение к Worker: место встречи **consultation-level**, не person-level. И acceptance должен обязательно доказать инвариант: `solar_return_jd` + solar planet longitudes unchanged, а solar cusps/Asc/MC changed. **Тут вся суть.**»

This is the **operational heart** of the TASK. Acceptance test (Stage 7.4 `test_meeting_place_changes_solar_cusps_only`) must explicitly assert:
- `natal_chart` deep-equal between two renders (meeting_place set vs not).
- `solar_chart.return_jd` byte-identical.
- `solar_chart.positions[*].longitude` byte-identical для all planets.
- AT LEAST ONE of: `solar_chart.asc_sign` differs OR `solar_chart.mc_sign` differs OR any planet's `house_placidus` differs.

If invariants don't hold → STOP, escalate. Engine path broken либо product path broken; investigate.

**Baseline:**
- Product main @ `9c800e7` (current-year filter + specific psychology closed).
- Overlay master @ `c20f7e1` (latest closure).
- Pytest baseline: `619 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- Existing core support: `core/astrology-hs/src/Bridge/Solar.hs:110-150,745-790`.
- Existing Python bridge: `services/api-python/app/ephemeris/bridge.py:509-630`.
- Existing input contract: `packages/contracts/solar-resolved-input.schema.json` (has `meeting_place`).
- Buggy template: `services/api-python/app/pdf/templates/solar.html.j2:214` (prints birth_place as meeting).
- Schema-change-gate reference: CLAUDE.md Bright Line #8.
- Migration pattern: `services/api-python/app/migrations/003_persons_case_label.sql` (Phase API endpoint reference).

**Not in scope (explicit):**
- Engine modifications (Stage 0 PASS preserves).
- Person model changes.
- Calibrated allowlist / `_OUTER_CARD_FACTS`.
- Phase 9.x artifacts.
- Synthesis pipeline (synthesis_themes.py).
- Other outer_cards.py logic.

**Ready: yes** — 6 clarifications applied 2026-05-20 + invariant emphasis reinforced:

1. **Stage 0 = (c) static + empirical.** Phase 9.x meta-lesson strict pattern. Empirical test becomes permanent acceptance test 7.4. Applied Stage 0.4.

2. **DB migration = (a) single** `004_consultation_meeting_place.sql` — 4 columns atomic. Standard ALTER pattern. Applied Stage 1.1.

3. **`utc_offset` = (b) omit.** IANA `timezone_id` sufficient. Engine resolves UTC через pytz/zoneinfo. Avoid duplication. Applied Stage 1.1.

4. **UI geocoding = (a) reuse** existing birth-place flow (Nominatim + timezonefinder) + manual override fallback allowed. Applied Stage 4.2.

5. **Schema gate = (c) Worker verifies.** If `consultation.schema.json` is API-UI contract → atomic commit per Bright Line #8 (Pydantic + TS-types + schema + Python contract test). If not API-UI contract → document why в HANDOFF. Applied Stage 6.

6. **Reviewer = (a) REQUIRED.** External pass after Worker submit. Applied Reviewer section.

**Critical invariant emphasis (per user direction 2026-05-20, verbatim):**

> «Acceptance должен обязательно доказать инвариант: `solar_return_jd` + solar planet longitudes unchanged, а solar cusps/Asc/MC changed. Тут вся суть.»

This is the operational heart. Empirical Stage 0 test becomes permanent acceptance test 7.4 — must assert 3 invariants HOLD + ≥1 cusp/Asc/MC/house DIFFERS. Applied across Stage 0.4 + Stage 7.4 + Reviewer criteria + Critical invariant emphasis section + STOP triggers.

**Consultation-level storage (per user direction reinforced):** meeting_place lives on consultation row ONLY, never on Person. Different solar years can be met в different cities.
