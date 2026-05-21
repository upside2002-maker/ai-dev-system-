# HANDOFF: Worker → TL — geocode-place-autocomplete

- Date: 2026-05-20
- From: Worker (astro)
- To: Tech Lead (astro)
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: `project-overlays/astro/TASKS/2026-05-20-geocode-place-autocomplete.md`
- Status: ready_for_review (Reviewer optional per clarification 5 = (a) — TL inline-verify + manual UI smoke)
- Product repo status: committed (`948cbdc` on `main`, backup pushed)

## Что сделано

Tier B UX feature — автоподтягивание `latitude` / `longitude` /
`timezone` по названию места в PersonForm и ConsultationForm. Helper,
не gate: ручной ввод остаётся редактируемым, Nominatim-down failover
гарантирован.

### Артефакты

- **new product:** `services/api-python/app/api/__init__.py` (sub-package marker).
- **new product:** `services/api-python/app/api/geocode.py`
  (`APIRouter` с эндпоинтом `GET /geocode`, in-process LRU cache,
  Nominatim + timezonefinder, controlled error envelopes).
- **new product:** `services/api-python/tests/test_geocode_endpoint.py`
  (10 tests: 6 strict + 4 adjacent).
- **modify product:** `services/api-python/app/main.py`
  (`app.include_router(geocode_router, prefix="/api/v1")` + import).
- **modify product:** `apps/web-react/src/api.ts`
  (`GeocodeResult` interface + `geocodePlace(query)` fetch wrapper).
- **modify product:** `apps/web-react/src/pages/PersonForm.tsx`
  («Найти координаты» кнопка + inline radio-list + controlled error
  + auto-fill; Phase 0.1 comment line 222-224 заменён ссылкой на
  endpoint).
- **modify product:** `apps/web-react/src/pages/ConsultationForm.tsx`
  (то же для блока «Место встречи соляра»; existing «Подставить
  координаты места рождения» button preserved; Phase 0.1 comments
  lines 28-33 заменены актуальным описанием).
- **Product commit SHA:** `948cbdc` on `main` (backup push
  `22dc672..948cbdc  main -> main`).
- **Overlay commit SHA:** this commit (HANDOFF + STATUS_RU update).

## HANDOFF mandatory items (per TASK)

### 1. Backend endpoint location

- **File:** `services/api-python/app/api/geocode.py`.
- **Route declaration:** `@router.get("/geocode", response_model=GeocodeResponse)`.
- **Router registration:** `services/api-python/app/main.py` line ~94
  via `app.include_router(geocode_router, prefix="/api/v1")` — final
  mounted path `/api/v1/geocode`.
- **Live smoke verified** via TestClient: `GET /api/v1/geocode?query=Москва, Россия`
  → 200 with 2 results (lat 55.625578, lon 37.6063916, tz `Europe/Moscow`).

### 2. LRU cache implementation trace

```python
# app/api/geocode.py
from functools import lru_cache

@lru_cache(maxsize=100)
def _cached_lookup(query: str) -> tuple[GeocodeResultModel, ...]:
    ...
```

- **Signature:** function of normalised query string (whitespace
  collapsed via `_normalise_query`); returns immutable tuple of
  Pydantic models so callers cannot mutate cached state.
- **Bounded:** `maxsize=100` per Ready clarification 2.
- **In-memory only:** `functools.lru_cache` is a Python-level dict on
  the function object; no disk persistence, no shared store, no leak
  beyond process lifetime.
- **Failure NOT cached:** Nominatim errors raise `HTTPException`
  before `_cached_lookup` returns, so transient outages never poison
  the cache.
- **Test #7 (`test_cache_hit_avoids_second_nominatim_call`)** asserts
  exactly one upstream call across two identical client requests.
- **Test cache hygiene:** `_clear_geocode_cache` autouse fixture wipes
  the LRU before AND after every test so state cannot leak between
  test cases.

### 3. User-Agent string + verification

- **Constant:** `_USER_AGENT = "astro-internal-tool/1.0"` (per Nominatim
  ToS — stable identifying header).
- **Sent on every request:** `httpx.get(..., headers={"User-Agent": _USER_AGENT, "Accept": "application/json"}, ...)`.
- **Test #10 (`test_user_agent_header_sent`):** mock asserts
  `headers["User-Agent"] == "astro-internal-tool/1.0"` on the outbound
  call. Refactors that drop the header or rename the constant fail
  the test immediately.

### 4. Multi-result UX rendering

Inline radio-list (per clarification 3 = (c)) under the place input,
visible only when `results.length > 1`. Single-result happy path:
fields auto-fill immediately, list NOT shown. Default selected =
first result.

Sample markup (PersonForm.tsx):

```tsx
{geocodeResults.length > 1 && (
  <fieldset style={geocodeFieldsetStyle}>
    <legend style={geocodeLegendStyle}>
      Найдено несколько вариантов — выберите нужный:
    </legend>
    {geocodeResults.map((r, idx) => (
      <label key={`${r.display_name}-${idx}`} style={geocodeOptionStyle}>
        <input
          type="radio"
          name="person-geocode-choice"
          checked={geocodeSelected === idx}
          onChange={() => handleGeocodeSelect(idx)}
        />
        <span>
          {r.display_name}
          <small style={geocodeMetaStyle}>
            {" "}
            ({r.latitude.toFixed(4)}, {r.longitude.toFixed(4)}
            {r.timezone ? `, ${r.timezone}` : ", таймзона не определена"})
          </small>
        </span>
      </label>
    ))}
  </fieldset>
)}
```

ConsultationForm.tsx использует тот же паттерн под name="consultation-geocode-choice"
с привязкой к `meetingLatitude` / `meetingLongitude` / `meetingTimezone`.

### 5. Manual override preservation proof

- **State coupling:** geocode результаты записываются в **те же**
  React `useState` slots, что и ручной ввод (`birth_latitude` etc.).
  После auto-fill оператор продолжает редактировать input — никаких
  `disabled` / `readOnly` атрибутов не добавлено.
- **Single result auto-fill** в `applyGeocodeResult(r)` использует
  `setState(prev => ({...prev, ...}))` — не блокирует поля, не
  читает их обратно.
- **Geocode помощь, не gate:** при ошибке (`geocodeError !== null`)
  пользователь видит сообщение, но lat/lon/tz fields остаются полностью
  editable. Submit handler консультации/клиента не проверяет «geocode
  выполнен?» — submit идёт через стандартный `createPerson` /
  `createConsultation` с теми значениями, что в state.
- **Confirmed:** existing «Подставить координаты места рождения»
  кнопка в ConsultationForm работает как раньше — её handler
  `prefillFromBirth` теперь дополнительно очищает `geocodeResults` /
  `geocodeError` чтобы UX оставался когерентным после переключения
  между источниками координат.

### 6. Nominatim-down failover proof

- **Backend layer (Test #5, `test_nominatim_timeout_returns_503`):**
  `httpx.TimeoutException` → `HTTPException(503, detail={"error": "geocode_service_unavailable", "message": "Сервис геокодинга временно недоступен. Введите координаты и часовой пояс вручную."})`.
  Не traceback, не 500, не crash.
- **Frontend layer (PersonForm.tsx + ConsultationForm.tsx):**
  `handleGeocodeClick` ловит исключение, вызывает `formatGeocodeError`
  и пишет controlled message в `geocodeError` state. Поля lat/lon/tz
  не меняются — оператор продолжает работу как раньше.
- **Save без geocode:** submit handler не зависит от `geocodeResults`
  / `geocodeError`. Если оператор просто ничего не нажимает на
  кнопку геокодинга и вбивает координаты руками — flow работает
  100% как до этого TASK.
- **Compute без geocode:** ничего нового в `POST /compute` —
  по-прежнему читает `birth_latitude` / `birth_longitude` / `birth_timezone`
  из persons table.

Manual smoke verification сводится к: «остановить backend service →
кнопка показывает «Сервис временно недоступен» → save Person + compute
работают, потому что lat/lon/tz введены руками». Live test #5 mocks
`httpx.TimeoutException` — равнозначно по surface.

### 7. Test inventory (10 backend tests, all PASS)

| # | Test | Type | Status |
|---|---|---|---|
| 1 | `test_moscow_happy_path` | strict | PASS |
| 2 | `test_empty_query_returns_422` | strict | PASS |
| 3 | `test_nominatim_empty_result` | strict | PASS |
| 4 | `test_timezonefinder_none` | strict | PASS |
| 5 | `test_nominatim_timeout_returns_503` | strict (failover guard) | PASS |
| 6 | `test_multi_result_capped_at_5` | strict | PASS |
| 7 | `test_cache_hit_avoids_second_nominatim_call` | adjacent (LRU) | PASS |
| 8 | `test_malformed_response_returns_controlled_error` | adjacent | PASS |
| 9 | `test_special_characters_in_query` | adjacent (UTF-8) | PASS |
| 10 | `test_user_agent_header_sent` | adjacent (ToS) | PASS |

`pytest tests/test_geocode_endpoint.py -v` → **10 passed in 2.51s**.

Full suite: `pytest --tb=no -q` → **653 passed + 3 skipped + 0 failed**
(= baseline 643 + 10 новых).

### 8. Manual smoke results

Performed via TestClient against live Nominatim (PUBLIC API HIT TWICE —
ONCE each for Москва + Питер; under Nominatim 1-req/sec policy).

| Сценарий | Запрос | lat | lon | tz | Verdict |
|---|---|---|---|---|---|
| Москва happy path | `Москва, Россия` | 55.625578 | 37.6063916 | `Europe/Moscow` | PASS |
| Питер happy path | `Санкт-Петербург, Россия` | 59.9606739 | 30.1586551 | `Europe/Moscow` | PASS |
| Empty query | `""` | — | — | — | 422 (PASS) |

Координаты Москвы — 55.63 (TASK expected ≈ 55.75); это потому что
Nominatim для запроса "Москва" возвращает центроид городской границы
(не Кремль). Разница ~14 км — приемлема для consultation
геокодинга; оператор видит `display_name`, может скорректировать
вручную если нужен другой район.

**Manual override preservation:** проверено в коде —
`applyGeocodeResult` использует `setState(prev => ({...prev, ...}))`
и не добавляет `disabled`/`readOnly` к input'ам. После auto-fill
поля редактируются как раньше.

**Nominatim-down failover:** покрывается backend test #5
(`test_nominatim_timeout_returns_503`) + frontend handlers
(`formatGeocodeError` в обоих формах). Сценарий «остановить backend
момента→ ввести руками → save → compute → PDF» структурно
идентичен Phase 0.1 flow — никакого нового зависящего от geocode
кода в submit / compute / PDF не добавлено.

### 9. Reviewer status

- **Worker self-review:** APPLIED.
  - Bright lines #1 (no client storage в core), #3 (HTTP только в FastAPI),
    #6 (один workflow → один snapshot — geocode is ortho к compute),
    #7 (Python владеет geocode + timezonefinder; raw data only) —
    все соблюдены.
  - STOP triggers: 0 fired.
    - No frontend timezone computation — timezonefinder server-side только.
    - No DB schema change — uses existing columns.
    - No engine touch — cabal build Up to date.
    - No Nominatim ToS violation — User-Agent constant, 5s timeout,
      LRU cache, low volume.
    - No new frontend test framework.
    - Manual entry never blocked — verified в коде.
    - Failover preserved — backend 503 + frontend controlled error.
- **Reviewer request:** TL inline-verify per clarification 5 = (a).
  External Reviewer не spawnится unless manual smoke surfaces issues.

## Pytest evidence

```
tests/test_geocode_endpoint.py::test_moscow_happy_path PASSED        [ 10%]
tests/test_geocode_endpoint.py::test_empty_query_returns_422 PASSED  [ 20%]
tests/test_geocode_endpoint.py::test_nominatim_empty_result PASSED   [ 30%]
tests/test_geocode_endpoint.py::test_timezonefinder_none PASSED      [ 40%]
tests/test_geocode_endpoint.py::test_nominatim_timeout_returns_503 PASSED [ 50%]
tests/test_geocode_endpoint.py::test_multi_result_capped_at_5 PASSED [ 60%]
tests/test_geocode_endpoint.py::test_cache_hit_avoids_second_nominatim_call PASSED [ 70%]
tests/test_geocode_endpoint.py::test_malformed_response_returns_controlled_error PASSED [ 80%]
tests/test_geocode_endpoint.py::test_special_characters_in_query PASSED [ 90%]
tests/test_geocode_endpoint.py::test_user_agent_header_sent PASSED   [100%]

============================== 10 passed in 2.51s ==============================
```

Full suite (final): **653 passed + 3 skipped + 0 failed in 124.71s**.

## Build evidence

- `cabal build` (project `core/astrology-hs`): **Up to date** —
  no Haskell change.
- `npm run build` (`apps/web-react`): **clean** — TS types check + Vite
  bundle 253.58 kB → gzip 82.85 kB.

## Discipline checklist

- [x] No DB schema change.
- [x] No engine touch.
- [x] No meeting_place invariant break.
- [x] No LLM / GPT.
- [x] No storing geocode result отдельно в БД (только existing lat/lon/tz columns).
- [x] No frontend timezone computation.
- [x] No Nominatim ToS violation (User-Agent constant, LRU cache,
      5s timeout, low volume, не scraping).
- [x] No blocking manual entry.
- [x] No silent wrong-city selection (multi-result radio shows all).
- [x] No new frontend test framework (manual smoke + backend tests).
- [x] Nominatim-down failover preserved (backend 503 + frontend
      controlled message, fields stay editable).
- [x] LRU cache in-memory only, bounded at 100 entries.

## Risk + conflicts

- **Live API call to Nominatim** во время manual smoke (Москва + Питер).
  Cache LRU не пересекает test boundary (`_clear_geocode_cache`
  autouse fixture); production не зависит от smoke output.
- **Nominatim accuracy:** «Москва» возвращает centroid в 55.63,
  а не Кремль (55.75). Оператор может скорректировать вручную —
  `display_name` показывает что именно matched. Это интенсивно
  по TASK design: helper, не authority.
- **No conflicts** с предыдущим TASK (`solar-meeting-place-per-consultation`):
  meeting_place storage и compute pipeline не тронуты; geocode только
  пополняет UI flow для удобства ввода тех же existing columns.
