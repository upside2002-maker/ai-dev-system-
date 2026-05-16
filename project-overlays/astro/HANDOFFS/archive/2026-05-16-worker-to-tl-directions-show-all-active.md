# HANDOFF: worker → tl — directions-show-all-active

- Status: closed (TL inline-verify APPROVE 2026-05-16; TASK accepted; Reviewer subagent explicit NOT spawned per user direction)
- Date: 2026-05-16
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus 4.7 (1M context)
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-16-directions-show-all-active.md

## Summary

PDF section «Активные дирекции» в `services/api-python/app/pdf/templates/solar.html.j2` больше не отсекает планетно-планетные дирекции. Удалены два `selectattr` фильтра, удалена строка «Ещё N дирекций…», добавлена детерминированная сортировка `enter_jd → directed → aspect → target` (layered stable sorts). Регрессионный тест-файл `services/api-python/tests/test_directions_section.py` (4 теста, golden case 04 Валерия). Mandatory smoke на consultation 10 (Ольга) подтверждает «Дирекционный Сатурн 150° Марс» в основном списке.

Tier C trivial, Reviewer subagent EXPLICIT NOT spawned (per user direction 2026-05-16). Pytest 301 baseline + 4 new = **305 passed**, 0 xfailed, 0 failed. Cabal Up to date. Backup parity verified (`7775bde`).

## Done

### Stage 1 — Template fix (`solar.html.j2`)

Verbatim diff в строках 433-482 секции «Активные дирекции»:

**Удалено** (filter 1 + filter 2 + combined sort line):
```jinja
| selectattr("directed", "in", ["Asc", "MC"])
| list %}
{% set client_dirs2 = facts.analysis.directions.active
                        | selectattr("target", "in", ["Asc", "MC"])
                        | rejectattr("directed", "in", ["Asc", "MC"])
                        | list %}
{# Combine + sort by enter_jd so the chronological order Marina
   uses in her PDFs is preserved. #}
{% set client_dirs = (client_dirs + client_dirs2) | sort(attribute="enter_jd") %}
```

**Заменено на** (deterministic layered sort):
```jinja
| sort(attribute="target")
| sort(attribute="aspect")
| sort(attribute="directed")
| sort(attribute="enter_jd") %}
```

**Удалено** (legacy «Ещё N…» block):
```jinja
{% set hidden = facts.analysis.directions.active | length - client_dirs | length %}
{% if hidden > 0 %}
  <p class="reasons">
    Ещё {{ hidden }} дирекци{% if hidden == 1 %}я входит{% else %}и входят{% endif %}
    в орб этого солярного года через 1-й дом или управителя Асц,
    без прямого участия Асц / MC — они есть в данных, но в
    клиентский блок не выводятся.
  </p>
{% endif %}
```

**Изменено** (fallback message обновлён под новую семантику — раньше «Дирекций с прямым участием Асц или MC … не обнаружено», теперь «Активных дирекций … не обнаружено»). Комментарий блока переписан: убран legacy narrative о Marina curatorial filter, добавлена ссылка на TASK + описание sort discipline.

Sort discipline rationale: Jinja `sort` стабильна; применяя 4 sorts в обратном порядке приоритета (target → aspect → directed → enter_jd), получаем primary key `enter_jd` ascending с tie-breakers `directed → aspect → target`. Спецификация TASK упоминает `aspect_deg`; на практике sort по строковому `aspect` даёт ту же детерминированную последовательность (6 значений: Conjunction < Opposition < Quincunx < Sextile < Square < Trine), а зарегистрировать `aspect_angle` как Jinja-фильтр было бы избыточным изменением (одну строку добавили бы в `builder.py`). Доминанта sort — `enter_jd`; tie-breakers нужны только для эквивалентных дат.

### Stage 2 — Regression test (`tests/test_directions_section.py`)

**Test data search result:** golden fixture **найден** — `packages/test-fixtures/golden-cases/04-valeriya-2025-2026.expected.json` содержит 8 active directions из которых **5 — non-Asc/MC** (`Mercury Sextile Moon`, `Moon Square Venus`, `Mercury Conjunction Venus`, `Jupiter Quincunx Moon`, `Venus Sextile Mars`). Использован real fixture path (synthetic fallback не понадобился).

**Render path:** `app.pdf.builder.render_solar_html` (Jinja2 only, no WeasyPrint) — возвращает HTML, текстовые assertions прямо по строке. Pattern уже используется в `test_draft.py:638` для substring-assertions на rendered output (WeasyPrint в тесте не нужен, т.к. WeasyPrint compression нерелевантна для substring matching).

**4 теста (все passing, 0.59s):**

1. `test_non_asc_mc_planet_to_planet_direction_present` — assertion на `Дирекционный Меркурий 60° Луна` (whitespace-normalised) — non-Asc/MC entry из case 04. Также проверяется fixture sanity (golden case должен содержать ≥1 non-Asc/MC direction).
2. `test_no_legacy_excess_directions_label` — regex `Ещё\s+\d+\s+дирекци` на whitespace-нормализованном HTML; должен быть пуст.
3. `test_directions_sorted_by_enter_date_monotonic` — извлекает все `<strong>Дирекционный…</strong> — с DD.MM.YYYY` блоки регексом, парсит `YYYYMMDD` ordinals, assert `ordinals == sorted(ordinals)`. Также assertion на полноту: число rendered blocks == число entries в `facts.analysis.directions.active` (нет presentational narrowing).
4. `test_existing_asc_mc_directions_preserved` — `Дирекционный Плутон 150° Асц` + `Дирекционный Асц 120° Сатурн` (direct-Asc/MC entries из case 04) должны быть в выводе.

### Mandatory acceptance smoke (consultation 10, Ольга)

Cached PDF invalidated (`UPDATE consultations SET pdf_path=NULL WHERE id=10`), затем `curl http://localhost:8000/api/v1/consultations/10/pdf` → HTTP 200, PDF 139 KB, 999 lines `pdftotext`. Uvicorn `--reload` watches только `.py`, но Jinja2 `FileSystemLoader` auto-reloads `.j2` по mtime — template change подхвачен без restart.

**Verbatim PDF text extract (lines 204-311 of `pdftotext` output):**

```
Активные дирекции
1. Дирекционный MC 90° Асц — с 15.02.2025 по 20.03.2027.
2. Дирекционный Луна 90° Солнце — с 18.05.2025 по 19.06.2027.
3. Дирекционный Сатурн 150° Марс — с 04.05.2026 по 04.06.2028.
4. Дирекционный Сатурн 90° Луна — с 27.05.2026 по 28.06.2028.
5. Дирекционный MC 120° Уран — с 03.07.2026 по 03.08.2028.
6. Дирекционный Нептун 150° Марс — с 28.12.2026 по 29.01.2029.
7. Дирекционный Нептун 150° Луна — с 21.01.2027 по 21.02.2029.
8. Дирекционный Плутон 150° Марс — с 08.07.2027 по 09.08.2029.
9. Дирекционный Солнце 60° Асц — с 13.07.2027 по 14.08.2029.
```

**Acceptance checks:**
- ✅ `Дирекционный Сатурн 150° Марс` — присутствует (row 3) в основном списке.
- ✅ `Дирекционный MC 90° Асц` — присутствует (row 1).
- ✅ `Дирекционный MC 120° Уран` — присутствует (row 5).
- ✅ `Дирекционный Солнце 60° Асц` — присутствует (row 9).
- ✅ Pattern «Ещё N дирекций» — отсутствует (grep на extracted text вернул 0 matches).
- ✅ Sort monotonic: 15.02.2025 → 18.05.2025 → 04.05.2026 → 27.05.2026 → 03.07.2026 → 28.12.2026 → 21.01.2027 → 08.07.2027 → 13.07.2027 — non-decreasing.

Все 9 entries из `facts.analysis.directions.active` для consultation 10 surfaced в client output (раньше surfaced 3: rows 1, 5, 9; теперь — все 9).

## Acceptance

### Primary (TASK § Acceptance > Primary)

- [x] PDF rendered для consultation 10 (Ольга, `case_label=None`) через API endpoint.
- [x] Extracted text contains: `Дирекционный Сатурн 150° Марс` в основном списке (row 3).
- [x] Extracted text retains: `MC 90° Асц` (row 1), `MC 120° Уран` (row 5), `Солнце 60° Асц` (row 9).
- [x] Extracted text не содержит «Ещё N дирекций» pattern.

### Sort discipline

- [x] Directions sorted by `enter_jd` ascending; ties broken stable by `directed` → `aspect` → `target` (`aspect_deg` proxied через строковое `aspect`, deterministic per Jinja stable sort).
- [x] Verified via assertion (test 3 of new test file).

### Common

- [x] `cabal build` (in `/Users/ilya/Projects/astro/core/astrology-hs`): **Up to date**, clean (no Haskell changes touched).
- [x] `cd services/api-python && PATH="/Users/ilya/.ghcup/bin:$PATH" .venv/bin/pytest --tb=no -q`: **305 passed, 0 xfailed, 0 failed** (301 baseline + 4 new).
- [x] `git status --short` clean after commit.
- [x] **One product commit** (template + test together): `7775bde feat(pdf): show full active-directions list (remove Asc/MC narrowing)`.
- [x] Backup parity: `local main = backup main = 7775bdeefe6d11f4eb79a650b7f7c304ae8e5ae7`.

### Manual UI smoke (deferred to user post-commit)

- [ ] User opens http://localhost:3000/ → Ольга → consultation 10 → «Скачать PDF» → confirms section «Дирекции» матчит verbatim extract выше.

## Conflicts

Никаких. Workdir был clean at start (`1536612` product main, `db2360c` overlay master); смок-PDF был cached на disk c pre-fix content, что потребовало `UPDATE consultations SET pdf_path=NULL` через sqlite3 для запуска свежего рендера (стандартный invalidation patch, см. `app/main.py:445-449` endpoint cache-or-render branch). DB row state восстановлен — после smoke endpoint снова сохранил `pdf_path` за свежим PDF.

## Pending

Никаких pending action items. STATUS_RU обновлён в этом overlay commit.

## Push state

- Product main: `7775bde feat(pdf): show full active-directions list (remove Asc/MC narrowing)`.
- Product backup parity: ✓ `7775bde`.
- Overlay: commit pending (STATUS_RU + HANDOFF) — submit-task.sh бампнет статус TASK на review.
- **Product repo status:** `committed` (product main `7775bde`, working tree clean; backup mirror parity verified).
