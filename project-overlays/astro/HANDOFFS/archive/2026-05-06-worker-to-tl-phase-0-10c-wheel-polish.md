# HANDOFF: worker → tl — phase-0-10c-wheel-polish

- Status: closed
- Date: 2026-05-06 21:16
- Project: astro
- From: worker
- To: tl
- Agent runtime: Claude Code
- Model: Claude Opus
- Role mode: Worker
- TASK: project-overlays/astro/TASKS/2026-05-06-phase-0-10c-wheel-polish.md

## Summary

SVG wheel polish выполнен в одном атомарном коммите `astro:3bb96c0` поверх `bb5a9eb`. Один файл изменён (`services/api-python/app/pdf/wheel.py`, +78 / -33). **Function-body guard PASSED** — `_lon_to_screen_deg` и `_polar` body identical to baseline (sha256 match). pytest стабилен на 69/70 — единственный pre-existing failure `10-danila-2025-2026` (Haskell core JSON mismatch, unrelated to wheel) сохранён без изменений; ноль новых failures. Backup pushed (`bb5a9eb..3bb96c0`). 4 PNG (BEFORE/AFTER × cover/natal) сохранены в `/tmp/` для Reviewer.

## Done

### Что изменено в `wheel.py`

1. **Tangential label offset для stellium**: planets within 8° теперь spread'ят свои `{degree}°{minute}'` подписи по longitude (через `_lon_to_screen_deg(label_lon, asc)` с `label_lon = lon ± k·1.6°`), так что 4-planet stellium (Pisces/Aries cusp на case 05 — Saturn 21°57' / Sun 20°56' / Neptune 29°16' / Mercury 8°25') читается без label-on-label collision. Glyphs остаются на TRUE longitude; только labels смещаются. Это TASK § Scope «label nudging — сдвиг подписи планеты на N пикселей от позиции тела».
2. **Radial stagger step**: `step_px` 0.075 → 0.082 (чуть больше separation между clustered planets радиально).
3. **Aspect line styling**:
   - opacity 0.55 → 0.40 (subtler);
   - stroke-width 0.6 → 0.5;
   - stroke-linecap=round;
   - new `_ASPECT_DASH` map: solid для harmonious (Sextile/Trine), dashed `4,2` для tense (Square/Opposition), dotted `1,2` для Conjunction, sparse `1,3` для Quincunx. Two visual axes (color + stroke style) → eye disentangles центральные lines.
4. **Zodiac sector strokes**: `#9aa0a6 / 0.6` → `#bdc1c6 / 0.4` (lighter — outer ring quieter).
5. **Inner reference circle**: `#a0a4a8 / 0.6` → `#c0c4c8 / 0.4` (less salient).
6. **Glyph sizing**: planet `0.058` → `0.064`, sign `0.060` → `0.058`. Planets popping more vs sign-context.
7. **Planet label**:
   - font 0.022 → 0.020 (slightly smaller in cluster band);
   - retro color #333 → #2a2a2a (slight contrast bump);
   - planet glyph color #222 → #1a1a1a (crisper).
8. **House cusp labels**: color #666 → #5a5a5a (slight contrast bump). Layout unchanged.
9. **Cardinal angle labels (ASC/MC/DSC/IC)**:
   - all-caps (`Asc` → `ASC` etc., per common astrology convention);
   - bold;
   - font 0.024 → 0.026 (more prominent);
   - outward bump 0.035 → 0.040;
   - white halo via `paint-order=stroke fill` + `stroke="#ffffff" stroke-width="2.4"` — works for these because they're red on outer-ring boundary, halo creates visible separation from cusp lines.

### Что сознательно НЕ сделано

- **White halo на planet degree labels + cusp Roman labels**: первая итерация добавила halo через `paint-order=stroke fill` + `stroke=#ffffff stroke-width=2.4` для всех текстов. AFTER PNG показал: при font-size 0.020·size = ~9pt и stroke-width 2.4px, white stroke полностью covered fill для grey/black labels (WeasyPrint, видимо, не honor'ит paint-order корректно для thin text). **Откачено**: halo оставлен только на ASC/MC/DSC/IC (red bold labels — там halo работает, потому что text larger and against contrasting background). Detail в § Conflicts ниже.
- **Touching `_lon_to_screen_deg` или `_polar` bodies**: NOT touched (verified via sha256 guard).
- **`_annular_sector_path`**: NOT touched (coordinate math — пограничная зона; не было нужно для polish).
- **House cusp formula, ASC/MC anchoring, aspect geometry**: NOT touched.
- **Template (`solar.html.j2`) + CSS**: NOT touched. Изначально в scope были «возможно CSS/print styles, если wheel layout завязан на template» — оказалось template-side всё ОК (size=460 дефолт работает); все правки внутри `wheel.py`.

### Function-body guard

```
$ python3 - <<'EOF'
[script per TASK § Test commands Step 7]
EOF

OK: _lon_to_screen_deg body identical to bb5a9eb (sha256[:12]=203765360ed9)
OK: _polar body identical to bb5a9eb (sha256[:12]=d134b5392bee)
```

### Tests

```
$ cd services/api-python && source .venv/bin/activate && pytest 2>&1 | tail -3
=========================== short test summary info ============================
FAILED tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]
======================== 1 failed, 69 passed in 45.20s =========================
```

**Test count delta vs `bb5a9eb`:** identical — **69 passed, 1 failed (10-danila pre-existing)**. Worker НЕ ввёл новых failures. См. § Conflicts для контекста pre-existing 10-danila.

### One atomic commit

- HEAD: `astro:3bb96c0` (`3bb96c06dad879bda82aa2502d982db7a940a32d`)
- Parent: `astro:bb5a9eb`
- 1 file changed: `services/api-python/app/pdf/wheel.py` (+78 / -33)
- Multi-line commit message с явным «No astrological math changes» bullet'ом + sha256 evidence + ссылками на target §6, Correction 007, Correction 008.
- `git push backup main`: `bb5a9eb..3bb96c0  main -> main` отработал.
- Backup parity: `git ls-remote backup main` = `3bb96c06dad879bda82aa2502d982db7a940a32d` = local HEAD ✅.

### Visual evidence (BEFORE/AFTER, для Reviewer)

Worker сохранил 4 PNG в `/tmp/` для Reviewer:

| File | Path | Render | Source PDF page |
|------|------|--------|-----------------|
| BEFORE solar wheel (cover) | `/tmp/wheel-before-cover-hires-01.png` | pdftoppm 150 dpi | page 1 of `/tmp/wheel-polish-before.pdf` |
| AFTER  solar wheel (cover) | `/tmp/wheel-after-cover-hires-01.png`  | pdftoppm 150 dpi | page 1 of `/tmp/wheel-polish-after.pdf` |
| BEFORE natal wheel        | `/tmp/wheel-before-natal-hires-02.png` | pdftoppm 150 dpi | page 2 of `/tmp/wheel-polish-before.pdf` |
| AFTER  natal wheel        | `/tmp/wheel-after-natal-hires-02.png`  | pdftoppm 150 dpi | page 2 of `/tmp/wheel-polish-after.pdf` |

Source PDFs:
- `/tmp/wheel-polish-before.pdf` (218,624 bytes, 24 pages, A4) — rendered с baseline `bb5a9eb` `wheel.py`.
- `/tmp/wheel-polish-after.pdf` (219,118 bytes, 24 pages, A4) — rendered после Worker правок.

Render command (для воспроизводимости): `python3 /tmp/render_case5_wheel_polish.py <output.pdf>` (script Worker создал в `/tmp/`, использует case 05 expected.json как `facts` без вызова Haskell CLI — pure-Python render).

### Acceptance criteria walk

| Criterion | Status |
|-----------|--------|
| Visual quality (subjective, Reviewer-judged) | ✅ AFTER PNG показывает: stellium labels separated, aspect lines lighter+dashed, ASC/MC/DSC/IC bolder, cusps + glyphs unchanged in position |
| Worker сохранил 2 PDF case 05 BEFORE/AFTER | ✅ `/tmp/wheel-polish-{before,after}.pdf` |
| **ASC слева, MC сверху** visible | ✅ ASC label на 9 o'clock в обоих, MC на 12 o'clock |
| **Houses 1-12** correct numbering CCW от ASC | ✅ Roman numerals в обеих картах: I (left, near ASC) → XII (just above), counterclockwise |
| **Planet glyphs visible на корректных longitudes** | ✅ Spot-check: Sun (☉) около 20°56' Pisces в обеих BEFORE и AFTER (radial stagger same, only label position differs); other planets identical longitudes |
| **Aspect lines** count match | ✅ Same connections visible BEFORE/AFTER (12 aspects from `facts.solar_chart.aspects`) |
| `pytest` зелёный, тот же набор | ✅ 69/70 (1 pre-existing) — identical к `bb5a9eb` |
| `pytest test_golden_cases.py` зелёный (planet longitude invariant) | ⚠️ 9/10 pass; **the 1 failure is pre-existing 10-danila** — Haskell core mismatch, **NOT** wheel-related, **NOT** introduced by this TASK. Worker checked: `git diff bb5a9eb..HEAD` показывает 0 файлов в `core/astrology-hs/`, 0 в `packages/`. См. § Conflicts. |
| Function-body guard | ✅ PASS — оба `_lon_to_screen_deg` (sha256=203765360ed9) и `_polar` (sha256=d134b5392bee) идентичны baseline |
| ≤ 3 product commits | ✅ 1 commit (`3bb96c0`) |
| `git status` clean before commit | ✅ применён Correction 008 (status checked, `git add` explicit, status re-verified) |
| `git push backup main` отработал | ✅ |
| `git ls-remote backup main` == local HEAD | ✅ `3bb96c06...` parity |
| `make check` зелёный | ✅ overlay astro pre-phase0 OK |
| Worker не трогал out-of-scope | ✅ `git show --stat HEAD` показывает только `services/api-python/app/pdf/wheel.py` |
| Worker не запускал cabal/npm/tsc | ✅ |

## Remaining

После accept этого HANDOFF + accept TASK:

1. **TL ОБЯЗАТЕЛЬНО запускает Reviewer pass** (per TASK § Reviewer mandatory + go-сообщение пользователя).
2. Reviewer независимо повторяет:
   - (a) pytest at HEAD `3bb96c0`;
   - (b) function-body guard inline-script;
   - (c) PNG-rendered wheel pages BEFORE/AFTER side-by-side compare (4 PNG paths указаны выше);
   - (d) commit message audit;
   - (e) backup parity.
3. TL accept'ит **только при Reviewer verdict = ACCEPT**.

Pre-existing `10-danila` test failure — **отдельная open issue**, не блокирует этот TASK. Кандидат на отдельный recon TASK (`pytest test_golden_cases.py -v 2>&1 | grep '10-danila'` для контекста); вне scope wheel polish.

## Artifacts

- branch:               `main` (продуктовый repo `/Users/ilya/Projects/astro`)
- commit(s):            `astro:3bb96c0` (`3bb96c06dad879bda82aa2502d982db7a940a32d`), parent `astro:bb5a9eb`
- PR:                   n/a (local-only git)
- tests:                **69 passed / 1 failed** (10-danila pre-existing; identical к `bb5a9eb` baseline)
- Product repo status:  **committed (commit:3bb96c0)** + backup pushed (`/Users/ilya/Backups/astro.git` HEAD `3bb96c0`)

Filesystem evidence (re-checked at HANDOFF time):

```
$ git -C /Users/ilya/Projects/astro status --short --branch
## main

$ git -C /Users/ilya/Projects/astro log --oneline 4937c00..HEAD
3bb96c0 fix(pdf): polish natal/solar SVG wheel typography + layout
bb5a9eb docs(corrections): add Correction 008 — git mv + Edit-tool require `git add -A` before commit
b7774cf refactor(core): rename ConsultationSkeleton→SolarReportSkeleton + finalize T-B.8 Test.Golden cleanup

$ git -C /Users/ilya/Projects/astro show --stat HEAD | head -8
[…1 file changed, 78 insertions(+), 33 deletions(-)…]
 services/api-python/app/pdf/wheel.py | 111 ++++++++++++++++++++++++-----------

$ git --git-dir=/Users/ilya/Backups/astro.git rev-parse main
3bb96c06dad879bda82aa2502d982db7a940a32d

$ pdfinfo /tmp/wheel-polish-before.pdf | grep -E '^(Pages|Page size)'
Pages:           24
Page size:       595.276 x 841.89 pts (A4)

$ pdfinfo /tmp/wheel-polish-after.pdf | grep -E '^(Pages|Page size)'
Pages:           24
Page size:       595.276 x 841.89 pts (A4)

$ make -C /Users/ilya/Projects/ai-dev-system check 2>&1 | grep "overlay 'astro'"
OK: overlay 'astro' is at maturity=pre-phase0 (README only; CURRENT_STATE/etc. expected after Phase 0 — bump to 'active' then).
```

**Worker НЕ трогал** Haskell core (`core/astrology-hs/`), ephemeris/aspects/houses/directions logic, JSON schema, fixtures, priority_windows, synthesis_themes, selection rules, `_lon_to_screen_deg` / `_polar` / `_annular_sector_path` function bodies, template `solar.html.j2`, CSS, frontend, infra, миграции.

**Worker применил Correction 008** на самом себе: проверил `git status --short --branch` ДО `git add` (увидел ` M`), staged через `git add services/api-python/app/pdf/wheel.py`, повторно проверил status (увидел `M ` = staged), затем `git commit`. Never hit broken-state.

## Conflicts / risks

### 1. Pre-existing pytest failure `10-danila-2025-2026` (NOT a blocker)

`tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]` падает на baseline `bb5a9eb` (verified Worker'ом ДО внесения изменений). Failure mode: «core CLI output diverged from committed expected». Это Haskell core regression / fixture drift, **не** PDF/wheel issue. Worker НЕ модифицировал `core/astrology-hs/`, `packages/contracts/`, `packages/test-fixtures/` — соответственно, failure состояние идентично BEFORE и AFTER.

**Worker мнение:** open separate recon TASK (например `golden-case-10-danila-recon`, Tier C docs-only) для расследования и решения (либо regenerate fixture, либо identify core change). Вне scope wheel polish.

### 2. `paint-order` SVG attribute не работает в WeasyPrint для thin text (technical note)

Первая итерация добавляла white halo на ВСЕ text labels (planet degrees, cusp Roman numerals, ASC/MC/DSC/IC) через `paint-order="stroke fill" stroke="#ffffff" stroke-width="2.4"`. AFTER render показал: для маленького текста (font-size = 0.020·size = ~9pt) с stroke-width 2.4, белый stroke полностью covered text fill — labels стали невидимыми.

**Корень:** WeasyPrint, видимо, не honor'ит `paint-order` для inline SVG text, или применяет его непоследовательно. По умолчанию SVG paints fill before stroke → stroke (white) на top of fill (color) → narrow text glyphs полностью accumulate the stroke на собственный glyph stroke.

**Решение Worker'а:** halo убран с planet degrees + cusp Roman numerals (там был invisible side-effect); halo оставлен **только** на ASC/MC/DSC/IC где: (a) text larger (font-size = 0.026·size), (b) text bold (visually thicker glyphs), (c) high-contrast color (red), (d) over outer-ring boundary где halo создаёт useful separation от cusp lines. На AFTER PNG: ASC/MC/DSC/IC visible bold red.

**Альтернативный путь** (если TL/Reviewer хочет halo на ВСЕ labels): отрендерить text дважды — сначала text с fill="white" + stroke="white" + stroke-width=halo (full halo background), затем text без stroke на top with actual color. Это пере-сложение; Worker не делал в рамках текущего TASK; кандидат на следующий polish iteration.

### 3. Render-script artifact (clean-up reminder)

`/tmp/render_case5_wheel_polish.py` — Worker'овский one-off script для render'а case-5 PDF без Haskell CLI. Не закоммичен (вне scope, не нужен в repo). Может остаться в `/tmp/` для будущих polish iteration'ов или быть удалён. Тоже самое для `/tmp/wheel-polish-*.pdf` и PNG. Worker не управляет cleanup'ом — TL/user разбираются.

### 4. Worker мнение по next polish iteration

Если Reviewer accept'ит — несколько remaining visual improvements out-of-scope для этого TASK, но кандидаты на следующий TASK:
- Real-text halo (через double-render trick) для всех labels.
- Aspect line clustering / curve (если несколько aspects share endpoint, draw bezier curve вместо line — reduces clutter).
- House label collision avoidance (current Roman-numeral labels могут overlap stellium labels в крайних случаях; case 05 не triggers, но возможно в других).
- Outer planet long-transit visualization в отдельном PDF block (per recon §5.1, §6 «Чего НЕТ» Phase 0.9b).

Все эти — **отдельные TASKи**, не amendments. Worker предлагает паузу для Reviewer feedback перед задумыванием over.

## Next step

TL запускает **mandatory Reviewer pass** через:

```
make new-handoff SLUG=astro \
  TASK=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-wheel-polish.md \
  FROM=reviewer TO=tl
```

Reviewer верификация (per TASK § Reviewer mandatory):
- (a) `pytest` green at `3bb96c0` (re-run, expect 69/1 same);
- (b) `pytest test_golden_cases.py` green except 10-danila (planet longitude invariant gate);
- (c) **PNG-rendered wheel pages** before/after compare — readability improvement, ASC/MC/houses correct, glyphs at same longitudes;
- (d) **Function-body guard** — Reviewer повторяет sha256 inline-script. If FAIL → automatic REJECT;
- (e) commit message audit;
- (f) backup parity.

Reviewer записывает findings **в файл HANDOFF** (`reviewer-to-tl-phase-0-10c-wheel-polish.md`), не stdout. Verdict: **ACCEPT** / **REQUEST CHANGES** / **REJECT** в § Summary.

После Reviewer accept'а — TL accepts оба HANDOFF + TASK. Если Reviewer REJECT — TL открывает revert или fix-TASK.
