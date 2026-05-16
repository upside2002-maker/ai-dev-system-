# TASK: directions-show-all-active

- Status: done
- Ready: yes
- Date: 2026-05-16
- Project: astro
- Layer: services (Python presentation: Jinja template) + tests
- Risk tier: C trivial (template filter widening; Reviewer **optional**, TL inline-verify acceptable per user direction 2026-05-16)
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

PDF section «Дирекции» в client output (e.g. `/Users/ilya/Downloads/solar-10.pdf` для Ольги) фильтрует список активных дирекций слишком узко: только те, где `directed` или `target` ∈ {Asc, MC}.

Engine (`core/astrology-hs/src/Domain/Directions.hs`) calculates a broader set including:
- Asc / MC direct.
- 1st-house planet / element.
- Asc ruler.
- Planet-to-planet directions which later participate in formulas (`1+5`, `1+7`, `1+8`, etc.).

Concrete miss (verified 2026-05-16): `Дирекционный Сатурн 150° Марс` есть в `facts.analysis.directions.active`, но в client PDF не появляется в основной section.

Root cause: `services/api-python/app/pdf/templates/solar.html.j2` lines 450 + 453:

```jinja
| selectattr("directed", "in", ["Asc", "MC"])
| selectattr("target", "in", ["Asc", "MC"])
```

Эти `selectattr` отсекают всё кроме direct Asc/MC participation. Section intro обещает «touched on Asc, MC, 1st house elements, Asc ruler», но фильтр узкий.

## Scope (Tier C trivial)

### Stage 1 — Template fix

In `services/api-python/app/pdf/templates/solar.html.j2`:
- **Remove** both `selectattr` filters at lines 450, 453.
- **Render all** `facts.analysis.directions.active` (engine already emits relevant set; presentation just shouldn't re-filter).
- **Sort by `enter_jd`**, stable fallback by `directed`, then `aspect_deg`, then `target` (deterministic ordering for any tie-breaking).
- **Remove «Ещё N дирекций»** строчку completely (per user direction: «Если список длинный — всё равно показывать весь список»).

### Stage 2 — Regression test

Add test `services/api-python/tests/test_directions_section.py` (или extend существующий):
- Given facts payload with directions including a non-Asc/MC entry (e.g. `Сатурн 150° Марс` или synthetic equivalent).
- Render PDF via `write_solar_pdf` or template directly.
- Assert extracted text contains the non-Asc/MC direction title in main directions list.
- Assert no «Ещё N дирекций» string в output.
- Assert directions sorted by `enter_jd` (extract dates, verify monotonic).

For Ольга / consultation 10 (user's `solar-10.pdf` test case):
- Render PDF via API or `write_solar_pdf` для existing fixture.
- Extract text → contains «Дирекционный Сатурн 150° Марс» в основном списке.

## Files

- modify:
  - `services/api-python/app/pdf/templates/solar.html.j2` — remove 2 selectattr filters + remove «Ещё N…» line + add sort.
  - `services/api-python/tests/test_directions_section.py` (new или extend existing test_main.py / test_api_pdf_endpoint.py — Worker decides).
  - `project-overlays/astro/STATUS_RU.md`.

- new: (only if test file is genuinely new) `services/api-python/tests/test_directions_section.py`.

- delete: —

## Do not touch

- Engine `core/astrology-hs/src/Domain/Directions.hs` (already emits correct set; gap фиксится в presentation only).
- Schema, fixtures, Haskell core.
- `outer_cards.py`, `transit_themes.py`, `rulership_houses.py` etc. (вне scope).
- `test_natalya_transits_acceptance.py` Phase 4b overrides.
- Phase 8 archived TASKs.
- API endpoint (`download_pdf`) — TASK уже закрыт, не нужно re-engineering для этого fix'а.

## Acceptance

### Primary

- [ ] Render PDF для consultation 10 (Ольга, `case_label=None`) через API endpoint OR `write_solar_pdf` direct.
- [ ] Extracted text contains: `Дирекционный Сатурн 150° Марс` в основном списке активных дирекций.
- [ ] Extracted text retains existing direct Asc/MC directions: `MC 90° Асц`, `MC 120° Уран`, `Солнце 60° Асц`.
- [ ] Extracted text does NOT contain «Ещё N дирекций» pattern.

### Sort discipline

- [ ] Directions sorted by `enter_jd` ascending; ties broken stable by `directed` → `aspect_deg` → `target`.
- [ ] Verified via test assertion (extract dates from PDF, check monotonic non-decreasing).

### Common

- [ ] `cabal --project-dir core/astrology-hs build` clean (no Haskell changes).
- [ ] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: `(301 baseline) + N new tests passed + 0 xfailed + 0 failed`.
- [ ] `git status --short` clean.
- [ ] One product commit ideal (template + test); justify split в HANDOFF if needed.
- [ ] Overlay commit (STATUS_RU + HANDOFF).
- [ ] Push backup, parity verified.

### Manual UI smoke (after Worker commits)

- [ ] Open http://localhost:3000/ → Ольга → consultation 10 → «Скачать PDF».
- [ ] PDF section «Дирекции» contains `Дирекционный Сатурн 150° Марс` в основном списке.
- [ ] PDF не содержит «Ещё N дирекций».

## Reviewer subagent — OPTIONAL (Tier C trivial, per user direction 2026-05-16)

Reviewer **not required**. TL inline-verify acceptable: confirm template diff is minimal (only 2 selectattr removals + sort + «Ещё N…» removal); confirm test asserts non-Asc/MC direction present; smoke render verifies.

If Worker prefers Reviewer pass — может spawn'нуть, не блокер.

## STOP triggers

- Need to touch Haskell engine — STOP, scope mismatch (presentation only).
- Removing filters breaks existing direct-Asc/MC tests — STOP, investigate why existing tests assume narrow filter.
- Sort order breaks existing assertions about direction order — STOP, escalation, может потребоваться более продуманный stable sort.
- Worker tempted to add «curated cap» or hide directions — STOP, per user direction «всё равно показывать весь список».
- `Дирекционный Сатурн 150° Марс` не появляется после fix → root cause not in selectattr; STOP, escalation memo.

## Context

**Mode normal + Tier C trivial.** Reviewer optional. Single template change + test addition.

**Baseline:**
- Product main @ `1536612` (post api-pdf-endpoint TASK closure).
- Overlay master @ `ef4b93b` (api-pdf-endpoint cascade closure landed).
- Pytest baseline: `301 passed + 0 xfailed + 0 failed`.
- Cabal: clean.

**STOP triggers:** see above.

**Not in scope (explicit):**
- Engine breadth change (already correct).
- Categorization «по формулам 1+...» как отдельный subsection — per user direction 2026-05-16: «Отдельный блок "по формулам" не делаем в этой задаче. Если позже понадобится — отдельный presentation TASK.»
- Curated cap / hidden directions (user explicit: no hiding).
- Outer cards generic fallback (TASK B scope).
- House interpretations parity with monthly table (TASK B scope).

**Ready: yes** — flipped 2026-05-16 after user ack + 4 clarifications:

1. **Scope clean** — нет расширений; только 2 selectattr removals + sort + «Ещё N…» removal + 1 regression test.
2. **Reviewer EXPLICIT NOT spawned** — TL inline-verify only. Если Worker предложит spawn — Worker должен НЕ spawn (per user direction explicit).
3. **Sort discipline:** `enter_jd → directed → aspect_deg → target` — deterministic, independent of JSON input order.
4. **Test data:** сначала искать existing fixture с non-Asc/MC active direction; synthetic minimal fixture OK fallback. Acceptance для Ольги (consultation 10) обязательный: `Дирекционный Сатурн 150° Марс` в PDF.

## Closure (2026-05-16)

**Worker delivered + TL inline-verify APPROVE.** Reviewer subagent explicit NOT spawned per user direction 2026-05-16 («Tier C trivial; TL inline-verify only»).

- **Product commit:** `7775bde` (single commit: template + test bundled per spec). 52 deletions / 222 insertions (template 32 lines net; test file 202 lines new).
- **Overlay commit:** `ccb6bf6` (HANDOFF + STATUS_RU + Status review bump).
- **Pytest:** 301 → **305** (4 new tests passed). 0 xfailed, 0 failed.

### Stage results

- **Stage 1 (template fix):** 2 `selectattr` filters removed at lines 450, 453; «Ещё N дирекций…» line removed; layered stable sort `enter_jd → directed → aspect → target` (deterministic, JSON-input-order independent; `aspect_deg` proxied via 6-value `aspect` string — no Jinja filter registration needed). Worker noted auxiliary `client_dirs2` rejectattr block also removed (legacy of narrower filter).
- **Stage 2 (regression test):** real fixture used (`04-valeriya-2025-2026.expected.json` — 8 active directions, 5 non-Asc/MC). Test file `test_directions_section.py` (4 tests): non-Asc/MC entry present, no «Ещё N…», monotonic enter_jd sort, Asc/MC entries preserved.

### Mandatory smoke (consultation 10 Ольга) — TL independent run

After force-clear cached PDF + curl, pdftotext extraction shows:

```
Активные дирекции

1. Дирекционный MC 90° Асц — с 15.02.2025 по 20.03.2027.
2. Дирекционный Луна 90° Солнце — с 18.05.2025 по 19.06.2027.
3. Дирекционный Сатурн 150° Марс — с 04.05.2026 по 04.06.2028.
4. Дирекционный Сатурн 90° Луна — с 27.05.2026 по 28.06.2028.
5. Дирекционный MC 120° Уран — с 03.07.2026 по 03.08.2028.
...
9. Дирекционный Солнце 60° Асц — с 13.07.2027 по 14.08.2029.
```

All Primary acceptance criteria met:
- `Дирекционный Сатурн 150° Марс` присутствует в основном списке (row 3).
- `MC 90° Асц`, `MC 120° Уран`, `Солнце 60° Асц` сохранены (rows 1, 5, 9).
- «Ещё N дирекций» substring отсутствует.
- Sort monotonic by enter_jd (15.02.2025 → 18.05.2025 → 04.05.2026 → 27.05.2026 → 03.07.2026 → ...).

### Reviewer informational notes (TL-side; non-blocking)

1. **Worker'ский `aspect` proxy для sort** (вместо `aspect_deg`): 6 deterministic aspect string values (0/60/90/120/150/180), sort effectively equivalent. Trade-off: no Jinja filter registration overhead. Acceptable.
2. **Auxiliary `client_dirs2` rejectattr block removed** as legacy artefact. Not in original spec but logically part of filter widening; Worker's call appropriate.
3. **Bonus rendering:** «Формулы: 1+5 1+7 1+8 1+9 1+10» вывод для Сатурн 150° Марс — exactly user's mentioned formulas. Engine + presentation now correctly surfaces formula-relevant directions in main list (no separate subsection needed per user direction).

### Status: done

Archive to `project-overlays/astro/TASKS/archive/`. HANDOFF archive to `HANDOFFS/archive/`. Next: TASK B `transit-section-generic-output` (Ready: no; ack required before Worker launch).
