# TASK: geocode-place-autocomplete

- Status: done
- Ready: yes
- Date: 2026-05-20
- Project: astro
- Layer: services + frontend (new backend API endpoint + frontend API client + UI integration в PersonForm + ConsultationForm)
- Risk tier: B (product UX feature; new API endpoint + frontend integration; backend tests; manual smoke; no DB schema change; no engine touch)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

User UX audit 2026-05-20 после Solar Meeting Place closure: автоподтягивания координат и таймзоны по городу **нет**. В обоих формах оператор вручную вводит:
- широту;
- долготу;
- IANA timezone.

Подтверждено в коде:
- `apps/web-react/src/pages/PersonForm.tsx:223` — explicit comment «Phase 0.1 без авто-геокодера»
- `apps/web-react/src/pages/ConsultationForm.tsx:28-33` — references «Phase 0.1 has no auto-geocoder»

Это UX-блокер: оператор должен либо знать координаты наизусть, либо отдельно гуглить, либо использовать GIS-софт. После `meeting_place` plumbing (closed 2026-05-20 product `5070ea0`) этот gap — следующий обязательный UX-фокус.

**Зависимости уже есть в `services/api-python/pyproject.toml`:**
- `httpx>=0.27.0`
- `timezonefinder>=6.0`
- `tzdata>=2024.1`

Backend geocode endpoint реализуется без новых dependencies.

**Frontend test infra:** отсутствует (no vitest / jest / test scripts в package.json). Per user direction «если frontend tests отсутствуют — не вводить новый test framework только ради этого TASK» — frontend tests out of scope; manual smoke only.

## Worker framing (verbatim user direction 2026-05-20)

> «Цель: чтобы в вебморде оператор вводил только место (Москва, Россия / Санкт-Петербург, Россия / Лима, Перу / Париж, Франция), а софт сам подтягивал широту, долготу, IANA timezone. Это нужно в двух местах: карточка клиента (место рождения), создание соляр-консультации (место встречи соляра).»

> «Manual fallback: поля широта/долгота/timezone оставить редактируемыми руками. То есть автогеокодер помогает, но не блокирует ручной override.»

## Scope (Tier B feature)

### Stage 1 — Backend geocode endpoint

**1.1 — Route:** `GET /api/v1/geocode?query=Москва,%20Россия`

**1.2 — Response shape:**

```json
{
  "results": [
    {
      "display_name": "Москва, Центральный федеральный округ, Россия",
      "latitude": 55.7558,
      "longitude": 37.6173,
      "timezone": "Europe/Moscow",
      "source": "nominatim"
    }
  ]
}
```

**1.3 — Backend logic:**

1. Use Nominatim через `httpx` (no new dependency).
2. Endpoint principles:
   - принимать строку `query`;
   - reject пустую строку (HTTP 422 per FastAPI convention);
   - делать запрос в Nominatim search API;
   - брать `lat` / `lon` from response;
   - через `timezonefinder` определять IANA timezone;
   - валидировать timezone через `zoneinfo.ZoneInfo`.
3. Return максимум 5 results.
4. Если timezone не найден:
   - вернуть результат с `timezone: null`;
   - frontend должен показать что timezone надо ввести руками.
5. Timeout 5 seconds.
6. User-Agent строка нормальная (per Nominatim ToS — identify app), e.g. `astro-internal-tool/1.0` per § Ready clarification 2.

**1.4 — Endpoint location (per user clarification 1 = (a) new file + router):**

Worker creates `services/api-python/app/api/geocode.py` с FastAPI router (`APIRouter()`). Регистрация router в `services/api-python/app/main.py` через `app.include_router(geocode_router, prefix="/api/v1")`. Cleaner architecture: `main.py` уже довольно крупный; geocode logic — отдельная concern.

**1.5 — Rate limiting / caching (per user clarification 2 = (b) UA + LRU cache):**

Nominatim ToS: User-Agent compliance mandatory. For low-volume internal tool (single operator) rate-limiter complexity не оправдана.

Worker implements:
- **User-Agent header:** `astro-internal-tool/1.0` (или similar identifying string per Nominatim policy https://operations.osmfoundation.org/policies/nominatim/).
- **In-process LRU cache:** `functools.lru_cache(maxsize=100)` или `cachetools.LRUCache(100)` — identical queries (e.g. оператор перепечатывает «Москва, Россия») hit cache, не Nominatim. No persistence (in-memory только).
- **No rate limiter** — повторные запросы дешёвые через cache; new queries единичные.

User direction 2026-05-20 verbatim: «User-Agent + in-process LRU cache. Без тяжёлого rate limiter, но повторные запросы не должны долбить Nominatim.»

### Stage 2 — Frontend API client

В `apps/web-react/src/api.ts` добавить:

```ts
export interface GeocodeResult {
  display_name: string;
  latitude: number;
  longitude: number;
  timezone: string | null;
  source: string;
}

export async function geocodePlace(query: string): Promise<GeocodeResult[]>;
```

Standard fetch wrapper; error handling consistent с existing API client patterns.

### Stage 3 — PersonForm UX

В `apps/web-react/src/pages/PersonForm.tsx:223+`:

**3.1 — Workflow:**

Оператор вводит «Место рождения»: «Москва, Россия». Рядом кнопка «Найти координаты».

После клика:
- Loading state.
- Если 1 результат → автоматически заполнить `birth_latitude` / `birth_longitude` / `birth_timezone`.
- Если несколько → показать список вариантов (per § Ready clarification 3); оператор выбирает; поля заполняются.

**3.2 — Manual fallback preserved:**

Поля широта/долгота/timezone остаются редактируемыми руками. Автогеокодер помогает, не блокирует ручной override.

**3.3 — Remove «Phase 0.1 без авто-геокодера» comment** на line 223 (заменить на актуальную ссылку на endpoint).

### Stage 4 — ConsultationForm UX

В `apps/web-react/src/pages/ConsultationForm.tsx` для блока «Место встречи соляра» — то же самое:

- Оператор вводит город/страну.
- Нажимает «Найти координаты».
- Подтягиваются `solar_meeting_latitude` / `solar_meeting_longitude` / `solar_meeting_timezone`.

**4.1 — Preserved behavior:**

Existing «Подставить координаты места рождения» кнопка работает как сейчас (тестировалось на Solar Meeting Place TASK).

**4.2 — Remove Phase 0.1 comments** (lines 28-33).

### Stage 5 — Validation / error states

Frontend должен показывать понятные ошибки:
- «Место не найдено»
- «Не удалось определить часовой пояс»
- «Сервис геокодинга временно недоступен»
- «Найдено несколько вариантов — выберите нужный»

Не падать молча. Worker designs UX (toast / inline message / etc).

### Stage 6 — Multi-result UX (per user clarification 3 = (c) inline radio-list)

User direction 2026-05-20 verbatim: «Inline radio-list. Это лучше, чем dropdown: оператор видит, какой именно город выбрал.»

Worker implements inline radio button list под полем места:

```tsx
{results.length > 1 && (
  <fieldset>
    <legend>Найдено несколько вариантов — выберите нужный:</legend>
    {results.map((r, idx) => (
      <label key={idx}>
        <input type="radio" name="geocode-choice"
          checked={selected === idx}
          onChange={() => handleSelect(r)} />
        {r.display_name}
      </label>
    ))}
  </fieldset>
)}
```

После клика на radio → заполняются `latitude` / `longitude` / `timezone` соответствующего result. Default selected = first result (one-result happy path). Single-result case: радио список не показывается, fields auto-fill immediately.

### Stage 7 — Tests

**7.1 — Backend tests** в `services/api-python/tests/test_geocode_endpoint.py` (per user clarification 4 = (b) adjacents allowed):

С mocked `httpx` / monkeypatch:

1. `GET /api/v1/geocode?query=Москва, Россия` возвращает lat/lon/timezone.
2. Empty query → HTTP 422.
3. Nominatim empty result → response с `results: []`.
4. `timezonefinder` returns `None` → timezone null в result.
5. Nominatim timeout/error → controlled HTTP error (e.g. 503 / 504), не traceback.
6. Multi-result Nominatim → response с ≤5 results.
7. **(adjacent) Cache hit:** identical query within session не вызывает Nominatim повторно (mock counter assertion).
8. **(adjacent) Malformed Nominatim response:** missing `lat` / `lon` fields → controlled error.
9. **(adjacent) Special characters в query:** URL-encoding/escaping (e.g. quotes, apostrophes, non-Latin).
10. **(adjacent) User-Agent header verification:** mock asserts httpx request includes `User-Agent` matching expected pattern.

8-10 worker-added adjacents reinforce contract; не bloat.

**7.2 — Frontend tests:**

Per user direction 2026-05-20: «Если frontend tests отсутствуют — не вводить новый test framework только ради этого TASK. Достаточно ручного smoke + API tests.»

Frontend infrastructure verified absent (no vitest/jest в package.json) → **NO frontend tests added.** Manual smoke is acceptance path.

### Stage 8 — Manual smoke

**8.1 — Новый клиент:**

1. Open «Новый клиент».
2. Type `Москва, Россия` в место рождения.
3. Click «Найти координаты».
4. Verify auto-fill:
   - lat около `55.75`;
   - lon около `37.61`;
   - timezone `Europe/Moscow`.
5. Save client.
6. Compute consultation — без ручного ввода координат.

**8.2 — Новая соляр-консультация:**

1. Toggle «Место встречи отличается от места рождения».
2. Type `Санкт-Петербург, Россия`.
3. Click «Найти координаты».
4. Verify auto-fill:
   - lat около `59.93`;
   - lon около `30.31`;
   - timezone `Europe/Moscow`.
5. Create consultation, compute, PDF render.
6. Verify PDF shows meeting place correctly.

**8.3 — Manual override test:**

1. Type place.
2. Click «Найти».
3. Auto-fill happens.
4. Edit one field (e.g. latitude).
5. Save — manual override preserved.

## Files

- new:
  - `services/api-python/app/api/geocode.py` OR extend `main.py` per § Ready clarification 1.
  - `services/api-python/tests/test_geocode_endpoint.py` (6 backend tests).

- modify:
  - `services/api-python/app/main.py` — register router if new file (clarification 1 = (a)).
  - `apps/web-react/src/api.ts` — `geocodePlace` function + `GeocodeResult` interface.
  - `apps/web-react/src/pages/PersonForm.tsx` — geocode button + multi-result handling + remove Phase 0.1 comment.
  - `apps/web-react/src/pages/ConsultationForm.tsx` — same для meeting place + remove Phase 0.1 comments.
  - `apps/web-react/src/types.ts` — `GeocodeResult` interface if shared.
  - `project-overlays/astro/STATUS_RU.md`.

- delete: —

## Do not touch

- DB schemas (Person + Consultation models — no new columns; lat/lon/timezone columns уже есть).
- Engine: Haskell core, schema, fixtures.
- Astrology core (Bridge/Solar.hs, Domain.*).
- `meeting_place` invariant (don't break Solar Meeting Place TASK).
- Calibrated allowlist / `_OUTER_CARD_FACTS`.
- Phase 4b structured overrides.
- Phase 9.x artifacts.
- Synthesis pipeline (`synthesis_themes.py`).
- Outer cards (`outer_cards.py`).
- House meanings (`house_meanings.py`).
- PDF template / `builder.py`.
- **NO new test framework для frontend** (per user direction).
- **NO Nominatim ToS violation** (User-Agent compliance mandatory).
- **NO blocking manual entry** (geocode помогает, не блокирует).
- **NO silent wrong-city selection** (multi-result MUST show all options for operator choice).
- **NO storing geocode result в БД отдельно** (только lat/lon/timezone в existing columns).
- **NO frontend timezone computation** (timezone always derived backend-side via timezonefinder).

## Acceptance

### Primary

- [ ] Backend endpoint `GET /api/v1/geocode` функционален.
- [ ] Nominatim integration работает с timeout + User-Agent.
- [ ] Timezonefinder integration возвращает IANA или null.
- [ ] PersonForm has «Найти координаты» button.
- [ ] ConsultationForm has «Найти координаты» button.
- [ ] Auto-fill работает для single result.
- [ ] Multi-result UX работает (operator выбирает).
- [ ] Manual override preserved.
- [ ] Error states показывают понятные сообщения.
- [ ] Phase 0.1 comments removed from PersonForm + ConsultationForm.

### Manual smoke (per Stage 8)

- [ ] Москва, Россия → lat ≈ 55.75, lon ≈ 37.61, tz `Europe/Moscow`.
- [ ] Санкт-Петербург, Россия → lat ≈ 59.93, lon ≈ 30.31, tz `Europe/Moscow`.
- [ ] Manual override after auto-fill preserved.
- [ ] Compute consultation после geocode работает.
- [ ] PDF render корректный.

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell change).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q` passes `>= 643 + 6` (6 new backend tests). 0 failed, 0 xfailed.
- [ ] Frontend `npm run build` clean (TS types check).
- [ ] `git status --short` clean for intended changes.
- [ ] One product commit (backend + frontend + tests).
- [ ] One overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.
- [ ] Reviewer per § Ready clarification 5 (optional + TL inline-verify + manual smoke).

### Discipline

- [ ] NO DB schema change.
- [ ] NO engine touch.
- [ ] NO meeting_place invariant break.
- [ ] NO LLM / GPT.
- [ ] NO storing geocode result отдельно в БД (только existing lat/lon/timezone columns).
- [ ] NO frontend timezone computation (always backend-side).
- [ ] NO Nominatim ToS violation (User-Agent + reasonable rate).
- [ ] NO blocking manual entry.
- [ ] NO silent wrong-city selection.
- [ ] NO new frontend test framework.

## STOP triggers

- Worker tempted to compute timezone на frontend → STOP, always backend.
- Worker saves geocode result отдельно в БД → STOP, only lat/lon/tz в existing columns.
- Worker breaks manual coordinate entry → STOP, manual override preserved.
- Worker touches astrology core → STOP, scope is UX feature only.
- Worker makes geocode обязательным (blocks manual entry) → STOP, geocode помогает, не блокирует.
- Worker silently выбирает неправильный город → STOP, multi-result MUST show all options.
- Worker introduces new frontend test framework → STOP per user direction.
- Worker violates Nominatim ToS (missing User-Agent, excessive rate, scraping) → STOP.
- Worker modifies Person или Consultation schemas → STOP, schemas not in scope.
- Worker breaks Phase Solar Meeting Place invariant → STOP, regression.
- **Worker breaks Nominatim-down failover** (manual entry blocked when Nominatim unreachable) → STOP per critical guard 2026-05-20. Autogeocoder помощник, не единственный путь.
- LRU cache implementation persists на disk OR leaks beyond process lifetime → STOP, in-memory only.

## Reviewer subagent — OPTIONAL (per user clarification 5 = (a))

User direction 2026-05-20 verbatim: «Optional; TL inline-verify + manual UI smoke достаточно.»

Tier B feature; backend mocked-httpx tests strong; manual smoke на Москва + Питер catches integration issues. Worker self-review applied. TL spawns external Reviewer post-submission только если manual smoke surfaces concerns.

**TL inline-verify focus areas:**
- SHAs match + parity.
- Pytest >= 643 + N (new tests pass).
- Backend endpoint reachable.
- Manual smoke: Москва + Питер happy paths.
- Manual override preserved.
- Nominatim-down failover (per critical guard ниже) — manual entry still works.

## Context

**Mode normal + Tier B (Reviewer optional per user clarification 5).** Worker mode: normal.

## Critical Nominatim-down failover guard (per user direction 2026-05-20, verbatim)

> «Если Nominatim недоступен, ручной ввод должен остаться полностью рабочим. Автогеокодер — помощник, не единственный путь.»

**Operational requirement:**

Когда Nominatim unreachable / timeout / 5xx — UI MUST behave:
- Geocode button показывает понятную ошибку («Сервис геокодинга временно недоступен»).
- Поля `latitude` / `longitude` / `timezone` остаются **fully editable** для ручного ввода.
- Saving Person OR Consultation работает **без geocode** — оператор вводит координаты руками.
- Compute consultation работает **без geocode** — соляр строится по manually-entered coords.

**Verification (manual smoke):**

1. Mock Nominatim как unreachable (e.g. shut down service, или mock httpx to raise).
2. Open PersonForm.
3. Click «Найти координаты».
4. Verify error message shown (не traceback, не crash).
5. Manually enter latitude / longitude / timezone.
6. Save person — SUCCESS.
7. Create consultation, compute, render PDF — все работает.

**Backend test #5 (Nominatim timeout/error) covers this at API layer.** Manual smoke covers UI layer.

**STOP trigger:** если manual entry blocked when Nominatim down → STOP, fix.

**Baseline:**
- Product main @ `22dc672` (Unified House Meanings closed).
- Overlay master @ `d5fa074` (latest closure).
- Pytest baseline: `643 passed + 3 skipped + 0 failed`.
- Cabal: clean.

**Cross-references:**
- PersonForm Phase 0.1 comment: `apps/web-react/src/pages/PersonForm.tsx:223`.
- ConsultationForm Phase 0.1 comments: `apps/web-react/src/pages/ConsultationForm.tsx:28-33`.
- API client location: `apps/web-react/src/api.ts`.
- Backend dependencies already present: `services/api-python/pyproject.toml` (`httpx`, `timezonefinder`, `tzdata`).
- Solar Meeting Place predecessor closure: `5070ea0`.
- Nominatim ToS: https://operations.osmfoundation.org/policies/nominatim/.

**Not in scope (explicit):**
- DB schema changes (Person/Consultation models preserved).
- Astrology core.
- Meeting place invariant.
- Synthesis pipeline / outer cards / house meanings.
- LLM integration.
- Frontend test framework (no infra exists).
- PDF template changes.

**Ready: yes** — 5 clarifications applied 2026-05-20 + Nominatim-down failover guard:

1. **Endpoint = (a) new file** `services/api-python/app/api/geocode.py` + register router в `main.py`. Cleaner architecture; main.py уже крупный. Applied Stage 1.4.

2. **Rate/cache = (b) UA + LRU cache.** User-Agent compliant + `functools.lru_cache(maxsize=100)` или `cachetools.LRUCache(100)` in-process. No rate limiter (low-volume). Applied Stage 1.5.

3. **Multi-result UX = (c) inline radio-list.** Operator видит все варианты с display_name; выбирает кликом radio. Default selected = first result. Single-result case: no radio list, immediate auto-fill. Applied Stage 6.

4. **Tests = (b) adjacents allowed.** 6 strict + 4 adjacents (cache-hit / malformed response / special chars / User-Agent header verification). Applied Stage 7.1.

5. **Reviewer = (a) optional.** TL inline-verify + manual UI smoke достаточно. Applied Reviewer section.

**Critical Nominatim-down failover guard (verbatim user direction 2026-05-20):**

> «Если Nominatim недоступен, ручной ввод должен остаться полностью рабочим. Автогеокодер — помощник, не единственный путь.»

Applied across:
- Critical Nominatim-down failover guard dedicated section (UI requirements + manual smoke verification path).
- STOP triggers («Worker breaks Nominatim-down failover → STOP»).
- Manual smoke Stage 8 + Nominatim-down smoke variant.
- Backend test #5 (Nominatim timeout/error) covers API layer; manual smoke covers UI layer.
