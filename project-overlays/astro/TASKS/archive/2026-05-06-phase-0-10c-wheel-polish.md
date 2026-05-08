# TASK: phase-0-10c-wheel-polish

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

PDF-отчёт на `astro:bb5a9eb` содержит SVG натальное и солярное колесо (`services/api-python/app/pdf/wheel.py`, 497 строк), внедрённое в Phase 0.5–0.10b как conscious deviation (зафиксировано в `target-architecture.md` § 6 после `target-architecture-conscious-deviations-sync`). Wheel рендерится через path-based глифы (per Correction 007), но визуальное качество остаётся первой вещью, которую Марина / клиент видит на cover-странице PDF — и это самый заметный остаточный внешний дефект. Текстовые блоки (`*_themes.py`) на нормальном уровне; smyslovой баг 709 закрыт; `Итоги консультации` готовы. Полировка wheel — следующий разумный шаг, **до** literary synthesis 0.10c-b.

Цель — улучшить читаемость wheel'а **не меняя астрологические расчёты** (longitude → wheel angle math, ASC/MC positioning, house cusp formula, aspect geometry — всё остаётся идентичным). Это product-code Tier B TASK, второй после `astro-core-naming-drift-cleanup` (`b7774cf`); Reviewer pass обязателен по ТЗ TL'я (visual correctness легко сломать незаметно).

## Scope

### В scope (Worker может править):

- **Typography**: размеры шрифта для подписей планет / знаков / домов; weight; вертикальное / горизонтальное центрирование text внутри ячейки; межстрочные интервалы.
- **SVG styling**: stroke-width / stroke-color для линий аспектов и куспид; fill / opacity для секторов знаков и домов; цветовая схема (если применимо); консистентность hairline'ов.
- **Glyph rendering polish** (`_emit_glyph_defs`, `_glyph_use`): уточнения path-based глифов; если глиф мутный — переработка path; добавление `<defs>`-элементов; изменение размеров глифов.
- **Layout / placement**: positions подписей чтобы не налезали (label nudging — сдвиг подписи планеты на N пикселей от позиции тела для избежания overlap'а); радиус glyph relative to body position; sign-ring vs house-ring визуальная иерархия.
- **Aspect line clarity**: линии аспектов в центре wheel'а — толщина / dash pattern / альфа / cap'ы; различение harmonious/tense визуально; clipping (если несколько линий пересекаются в одной точке — упорядочить).
- **Constants / radii numerics**: значения `inner_r`, `outer_r`, `glyph_size`, `font_pt` и подобные константы — **OK для коррекции**, при условии что НЕ меняется формула placement'а (см. boundary ниже).
- **Жинджи2-связь**: `services/api-python/app/pdf/templates/solar.html.j2` (884 строки) — wheel embedded через macro `render_chart_wheel(facts.<chart>, size=460)` на cover-page (line 201) и на natal-page (line 234). Можно править: размер `size=`, обрамление wheel (margins, page-break, captions), CSS print-rules вокруг.

### Strict boundaries (НЕ трогать без отдельного TL escalation):

- **Astrological math**:
  - `_lon_to_screen_deg(lon, asc)` — формула преобразования longitude → screen angle. Это «coordinate mapping longitudes→wheel» из ТЗ.
  - `_polar(angle_deg, radius, cx, cy)` — generic polar→cartesian helper, не трогать.
  - **House cusp placement**: значения cusps приходят из `facts.<chart>.house_systems.Placidus.cusps` уже посчитанные в Haskell core; Worker НЕ пересчитывает их и НЕ трогает порядок / нумерацию.
  - **ASC/MC marker positioning**: ASC всегда слева на 9-часовой позиции; MC — на верху; формула «ASC на 180° по horizontal axis» — invariant.
  - **Aspect geometry**: что считается аспектом, какой orb, как aspect line проходит через центр — invariant.
- **Astrological data sources**:
  - Haskell core (`core/astrology-hs/**`) — НЕ трогать.
  - JSON Schema (`packages/contracts/*.schema.json`) — НЕ трогать.
  - Test fixtures (`packages/test-fixtures/**`, включая golden cases) — НЕ трогать.
  - `priority_windows`, `synthesis_themes`, `direction_themes`, `house_pair_themes`, `transit_themes` (Python `*_themes.py`) — НЕ трогать.
  - Selection rules (что показывается, что не показывается, что считается «king of aspects», какие планеты в `ImportantTransitPlanets`) — НЕ трогать.
- **Schema/wire format**:
  - НЕ менять `consultation_skeleton` или любые wire-format keys в JSON output.
  - НЕ менять `BridgeAnalysis` поля.
- **Out-of-PDF logic**:
  - FastAPI endpoints (`main.py`) — НЕ трогать.
  - Storage (`db.py`, `persons.py`, `consultations.py`, `draft.py`, миграции) — НЕ трогать.
  - Frontend (`apps/web-react/**`) — НЕ трогать.

### Escalation triggers

Если Worker во время работы обнаружит, что polish **требует** изменения coordinate math (`_lon_to_screen_deg`, `_polar`), house-ring placement formula, ASC/MC anchoring, или aspect geometry — **остановить работу**, вернуться в TL с описанием what/why/scope estimate. TL решает: либо escalate Tier C → Tier B (если был Tier C), либо approve в рамках текущего Tier B; либо split на несколько TASK.

В текущей формулировке TASK сразу Tier B (с mandatory Reviewer), поскольку scope ambiguity между «pure styling» и «coordinate math touch» trace-able только в реальной правке. Tier B покрывает оба варианта.

### Один атомарный commit (или 2-3 если оправдано)

Worker делает ≤ **3 git commits** в продуктовом repo:
1. (Required) **Wheel polish** — основной коммит с правками в `wheel.py` + `solar.html.j2`.
2. (Optional) **Snapshot evidence** — если Worker сохраняет before/after PDF в repo для будущего reference (НЕ обязательно — `data/` gitignored, а сохранение PDF в repo — отдельное решение; обычно Worker оставляет PDF снаружи repo и ссылается на путь в HANDOFF).
3. (Optional) **CSS/template tweaks** — если template-changes отделимы от wheel-internal'а.

Один commit — preferred. После commit'а — `git push backup main`.

## Files

- new:    —
- modify:
  - `services/api-python/app/pdf/wheel.py` (visual polish; coordinate math UNCHANGED)
  - `services/api-python/app/pdf/templates/solar.html.j2` (wheel embedding tweaks; CSS print-rules around wheel блоки)
  - (potentially other CSS/print files если они существуют отдельно от template — Worker checks)
- delete: —

Before/after PDF artifacts — **не commit'ить** в product repo. Worker сохраняет их в `/tmp/`, `~/Downloads/`, или `data/scratch/` (последнее gitignored), и указывает абсолютные paths в HANDOFF body для Reviewer.

## Do not touch

- `core/astrology-hs/**` — Haskell core inviolate.
- `services/api-python/app/pdf/{builder,direction_themes,house_pair_themes,synthesis_themes,transit_themes}.py` — content/projection logic, не визуал.
- `services/api-python/app/{main,db,persons,consultations,draft,core_client,models}.py` — orchestration / storage.
- `services/api-python/app/ephemeris/**` — ephemeris bridge.
- `services/api-python/app/migrations/**` — DB migrations.
- `apps/**` — frontend.
- `packages/contracts/**` — JSON Schema.
- `packages/test-fixtures/**` — golden cases.
- `packages/rulesets/**` — rulesets (включая daragan-orbs).
- `infra/**`, `docker-compose.yml`, `run-local.sh` — infra.
- `data/**` — PII БД, ephemeris files.
- `astro/.claude/**`, `CLAUDE.md` — продуктовые правила.
- `docs/**` — документация продукта.
- `/Users/ilya/Backups/**` — backup mirror (push-only через `git push backup main`).
- `project-overlays/astro/**` — overlay не трогать (этот TASK product-only). Если результат потребует обновления `target-architecture.md § 6` (например, переименовать «SVG натал-колесо» в более точный термин) — отдельный docs-only follow-up TASK, НЕ в этом TASK.

В рамках `wheel.py`:
- Функцию `_lon_to_screen_deg(lon, asc)` — **не трогать body**. Можно вызывать, но не менять.
- Функцию `_polar(angle_deg, radius, cx, cy)` — **не трогать body**. Можно вызывать, но не менять.

## Acceptance criteria

### Visual quality (subjective, Reviewer-judged)

- [ ] Натальное и солярное колесо **читаются лучше** на before/after compare:
  - меньше визуального шума;
  - подписи планет / знаков / домов не налезают друг на друга;
  - глифы планет, домов, знаков выглядят аккуратно (не мутно, не мелко, не размыто);
  - линии аспектов в центре не превращают центральную область в «кашу».
- [ ] Worker сохраняет 2 PDF: `<scratch>/wheel-polish-before.pdf` (rendering до правок) и `<scratch>/wheel-polish-after.pdf` (после), оба для **case 05** (`packages/test-fixtures/golden-cases/05-ekaterina-2025-2026.input.json`). Paths указаны в HANDOFF body.

### Visual invariants (objective, both Worker и Reviewer verify)

- [ ] **ASC слева** на natal и solar wheel визуально (около 9-часовой позиции, ±2° tolerance — Reviewer глазом).
- [ ] **MC сверху** визуально (около 12-часовой позиции, ±2° tolerance).
- [ ] **Houses 1-12 пронумерованы корректно** идущие против часовой стрелки от ASC.
- [ ] **Planet glyphs visible на корректных longitudes** (sanity check: spot-check 3-5 планет в before vs after — позиции тех же градусов в кольце).
- [ ] **Aspect lines** — те же связи между planets visible в before и after (не больше, не меньше; visual count match).

### Behavioural invariants (objective, через тесты)

- [ ] `pytest` в `services/api-python/` — **зелёный**, тот же набор тестов проходит. Подтверждается count + все ✓.
- [ ] `tests/test_golden_cases.py` — **зелёный** (если он рендерит wheel'ы — это main protection against silent breakage).
- [ ] Если Worker нашёл / создал unit-тесты непосредственно для `wheel.py` — все green. (Сейчас `grep -lE 'wheel\|svg' tests/*.py` пустой; Worker может добавить минимальные unit-тесты на `_emit_glyph_defs`, `render_chart_wheel_svg` если уместно — это в scope.)
- [ ] **Planet longitudes в `facts` не меняются** — verified via `test_golden_cases.py` (parses fixture → runs full pipeline → compares against `*.expected.json` byte-by-byte либо within tolerance). Если этот тест падает — planet math сломан, **НЕ commit'ить**, escalate в TL.

### Function-body guard (objective, добавлено TL'ом 2026-05-06)

Вместо слабого grep по имени функции — **строгое сравнение body** функций `_lon_to_screen_deg` и `_polar` между `bb5a9eb` (baseline) и Worker'овским HEAD. Worker обязан:

- [ ] Запустить функцию-body guard (helper inline в § Test commands ниже) и зафиксировать вывод в HANDOFF. **Оба тела должны быть идентичны** baseline'у.
- [ ] Если guard FAIL — **НЕ commit'ить**, остановить работу, escalate в TL. Это означает что Worker невольно затронул coordinate math, что выходит за scope без отдельного TL approve.
- [ ] Reviewer независимо повторяет тот же guard на Worker'овском HEAD и фиксирует результат в Reviewer HANDOFF. Если guard у Reviewer'а fail — **automatic REJECT verdict** без дальнейшего обсуждения; TL открывает revert-TASK.

### Visual review через rendered wheel pages (objective, добавлено TL'ом 2026-05-06)

Reviewer **не** просто «открывает PDF на глаз». Reviewer обязан **извлечь конкретные wheel-страницы** PDF в PNG и приложить пути к HANDOFF. Конкретно:

- [ ] Worker в HANDOFF указывает **номера страниц** PDF, на которых рендерятся solar wheel и natal wheel (например, `cover page = 1`, `natal page = N` — где N зависит от структуры PDF; Worker фиксирует точные номера).
- [ ] Reviewer запускает `pdftoppm -png -r 150` (или эквивалент) на before/after PDF + указанных страницах, получает 4 PNG: `wheel-{before,after}-{cover,natal}.png`.
- [ ] Reviewer прикладывает 4 absolute paths в HANDOFF body — TL открывает PNG для финального verdict'а.
- [ ] Reviewer в HANDOFF body **перечисляет** что изменилось visually (improvement bullets) и **что осталось invariant** (ASC/MC/houses/glyphs positions).
- [ ] Если PNG показывают visual regression (ASC сдвинулся, glyph пропал, дома перенумерованы) — **REJECT verdict**, независимо от pytest.

### Process invariants

- [ ] Worker делает ≤ 3 commits в `/Users/ilya/Projects/astro` (preferred = 1).
- [ ] **`git status --short` чист** перед каждым commit'ом (per Correction 008).
- [ ] `git push backup main` отработал; `git ls-remote backup main` == local HEAD.
- [ ] `git log --oneline bb5a9eb..HEAD` показывает только commits от этого TASK.
- [ ] `git show --stat HEAD~N..HEAD` (где N = число commits) — все touched files в `/services/api-python/app/pdf/` (wheel.py, solar.html.j2, optionally CSS file). Никаких out-of-scope path'ов.
- [ ] Worker НЕ трогал `core/astrology-hs/`, `apps/`, `packages/`, `infra/`, `data/`, `.claude/`, `docs/`, миграции, prefix `services/api-python/app/{main,db,persons,...}.py`.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный.

### Reviewer mandatory

- [ ] Reviewer pass через файл HANDOFF (не stdout). Reviewer проверяет:
  - (a) before/after PDF visually — improvement есть, regression нет (ASC/MC/houses correct, glyphs not lost, no overlap regressions);
  - (b) `pytest` green at HEAD (re-run independently);
  - (c) planet longitudes invariant (test_golden_cases at HEAD, ничего не падает);
  - (d) `_lon_to_screen_deg` body не модифицирован (`git diff bb5a9eb HEAD -- services/api-python/app/pdf/wheel.py` показывает только non-coordinate-math changes; Reviewer reads diff);
  - (e) commit message соответствует TASK template;
  - (f) backup parity.
- [ ] Reviewer verdict: ACCEPT / REQUEST CHANGES / REJECT — записан в HANDOFF Summary.
- [ ] **TL accept'ит TASK только если Reviewer verdict = ACCEPT.**

## Test commands

```bash
# 1. Render before-state PDF (Worker запускает ДО правок):
cd /Users/ilya/Projects/astro
# Worker идентифицирует механизм рендеринга:
#   - либо через pytest test_golden_cases.py (если он выводит PDF);
#   - либо через api endpoint POST /api/v1/consultations/{id}/pdf (если case 05 уже в SQLite);
#   - либо через python script запуск wheel/builder напрямую с case-5 fixture.
# Сохранить PDF в /tmp/wheel-polish-before.pdf (или ~/Downloads/).
# Worker фиксирует точный command в HANDOFF.

# 2. Run baseline tests (must be green ДО изменений):
cd services/api-python
pytest -v 2>&1 | tail -10

# 3. Apply changes (wheel.py + solar.html.j2; possibly CSS).

# 4. Re-run tests (must be green ПОСЛЕ изменений, same count):
pytest -v 2>&1 | tail -10
pytest tests/test_golden_cases.py -v 2>&1 | tail -10

# 5. Render after-state PDF (same command as #1, save to /tmp/wheel-polish-after.pdf).

# 6. Visual compare (Worker eyeballs):
# open /tmp/wheel-polish-before.pdf /tmp/wheel-polish-after.pdf
# (manual check — readability up, ASC/MC/houses still correct, no glyphs lost)

# 7. Function-body guard (Worker + Reviewer запускают, MUST be OK x2):
python3 - <<'PYEOF' || exit 1
import subprocess, re, sys, hashlib

def extract_body(src: str, fn: str) -> str:
    """Extract a top-level def's body from def-line through line before next top-level def/class or EOF."""
    lines = src.split('\n')
    start = None
    for i, line in enumerate(lines):
        if re.match(rf'^def {fn}\(', line):
            start = i
            break
    if start is None:
        sys.exit(f"FAIL: function `{fn}` not found in source")
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if re.match(r'^(def|class) [A-Za-z_]', lines[i]):
            end = i
            break
    return '\n'.join(lines[start:end]).rstrip()

WHEEL = 'services/api-python/app/pdf/wheel.py'
baseline_src = subprocess.check_output(
    ['git', 'show', f'bb5a9eb:{WHEEL}'], text=True)
current_src = open(WHEEL).read()

ok = True
for fn in ('_lon_to_screen_deg', '_polar'):
    b = extract_body(baseline_src, fn)
    c = extract_body(current_src, fn)
    bh = hashlib.sha256(b.encode()).hexdigest()[:12]
    ch = hashlib.sha256(c.encode()).hexdigest()[:12]
    if b == c:
        print(f"OK: {fn} body identical to bb5a9eb (sha256[:12]={bh})")
    else:
        print(f"FAIL: {fn} body differs from bb5a9eb (baseline={bh}, current={ch})")
        ok = False

sys.exit(0 if ok else 1)
PYEOF

# 8. Commit hygiene + push (per Correction 008):
cd /Users/ilya/Projects/astro
git status --short --branch                    # MUST verify before commit
git add services/api-python/app/pdf/...        # explicit stage
git status --short --branch                    # re-verify
git diff --cached --stat
git commit -m "<multi-line message per § Commit message below>"
git log --oneline bb5a9eb..HEAD                # ≤ 3 commits
git show --stat HEAD                           # paths only in services/api-python/app/pdf/
git push backup main
git ls-remote backup main                      # == local HEAD

# 9. Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Commit message template

```
fix(pdf): polish natal/solar SVG wheel typography + layout

- Improve label placement (planet/house/sign labels no longer overlap).
- Refine path-based glyph rendering (sharper, consistent sizes).
- Tighten aspect line styling (lower visual noise in chart center).
- (other concrete bullets reflecting actual changes)

No astrological math changes:
- _lon_to_screen_deg + _polar function bodies unchanged.
- ASC/MC anchoring + house numbering unchanged.
- Planet longitudes in facts unchanged (verified via test_golden_cases.py).

Tests: pytest <N>/<N> green (was <N>/<N> at bb5a9eb).
Visual evidence: /tmp/wheel-polish-{before,after}.pdf for case 05 (Ekaterina 2025-2026).

Refs: target-architecture.md §6 PDF layout (block 2 «Натал-карта (визуальная)»),
      Correction 007 (path-based SVG glyphs).
```

## Rollback plan

Атомарность: ≤ 3 commits. Если что-то пойдёт не так:

| Точка отказа | Действие |
|---|---|
| pytest red после правок (working tree, до commit) | `git restore .` восстанавливает working tree до `bb5a9eb`. Worker → TL с описанием проблемы. |
| pytest red после первого commit, до push | `git reset --hard bb5a9eb` отбрасывает new commit(s). Worker → TL. |
| Reviewer находит блокер после commit + push backup | Если поправимо: новый patch commit поверх (NOT amend; не rewrite history после push). Если не поправимо: `git revert <commit>` создаёт revert-commit, push backup. |
| Catastrophic regression (например planet longitudes сломались) | `git reset --hard bb5a9eb` локально + `git push backup main --force-with-lease` (требует TL go; force-push в backup допустим только на этот случай). Альтернатива: revert-commit. Reviewer должен поймать ДО push backup, чтобы force-push не понадобился. |

Early-warning гейты: (a) `pytest test_golden_cases.py` зелёный → planet math intact; (b) Worker before/after PDF visual check → ASC/MC/houses positions visible.

Backup: `bb5a9eb` сохранён в `/Users/ilya/Backups/astro.git`. Catastrophic recovery: `git clone /Users/ilya/Backups/astro.git /Users/ilya/Projects/astro-restored`.

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-wheel-polish.md FROM=worker TO=tl`.

В теле обязательно:

- список изменённых файлов с per-file `git diff --stat`;
- список конкретных правок (typography, glyph polish, layout, aspect line styling, …);
- список **explicitly NOT touched** функций / зон (`_lon_to_screen_deg` body, `_polar` body, ASC/MC anchoring, house cusp formula, aspect geometry);
- результаты `pytest` до и после (counts + ✓ all);
- результат `pytest test_golden_cases.py` отдельно (planet longitude invariant gate);
- абсолютные paths к `wheel-polish-before.pdf` и `wheel-polish-after.pdf` для case 05 — Reviewer должен иметь доступ;
- список того что Worker заметил «as worth doing» но не сделал (out-of-scope ideas) — для будущего TASK, не в этом;
- результат `make check` и `make status SLUG=astro`;
- **`Product repo status:` `committed (commit:<short>)`** с новым SHA (или несколькими, если 2-3 commits) поверх `bb5a9eb`;
- backup sync confirmation: `git ls-remote backup main` showing HEAD;
- evidence-rule подтверждение: «Worker применил Correction 008 — `git status --short` checked перед каждым commit».

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-wheel-polish.md`.

### Reviewer (mandatory)

После Worker HANDOFF + submit, **обязательно**:

1. TL запускает `make new-handoff SLUG=astro TASK=... FROM=reviewer TO=tl`.
2. Reviewer независимо verифицирует:
   - (a) `pytest` green at Worker's HEAD (re-run без trust);
   - (b) `pytest test_golden_cases.py` green;
   - (c) **PNG-rendered wheel pages** before/after compare — readability improvement есть, ASC/MC/houses на месте, planet glyphs corresponded longitudes. Reviewer extract'ит конкретные wheel-страницы (cover + natal page) из обоих PDF в PNG через `pdftoppm -png -r 150`, прикладывает 4 absolute paths (`wheel-before-cover.png`, `wheel-after-cover.png`, `wheel-before-natal.png`, `wheel-after-natal.png`) в HANDOFF body.
   - (d) **Function-body guard** — Reviewer повторяет inline-script из § Test commands (Step 7) на Worker'овском HEAD, body of `_lon_to_screen_deg` и `_polar` MUST be identical to `bb5a9eb` baseline (sha256[:12] match). Fail → automatic REJECT.
   - (e) commit message(s) соответствует TASK template;
   - (f) `git ls-remote backup main` == local HEAD.
3. Reviewer записывает findings **в файл HANDOFF** (не stdout-only).
4. Reviewer verdict: **ACCEPT** / **REQUEST CHANGES** / **REJECT** — в § Summary HANDOFF, явно.
5. TL accept TASK **только если verdict = ACCEPT**. При REQUEST CHANGES — открывается follow-up TASK; при REJECT — может потребоваться revert.

## Контекст

- `astro:bb5a9eb` — текущий HEAD (после `audit-trail-after-b7774cf`). 2 commits since baseline `4937c00`.
- `target-architecture.md § 6` блок 2 «Натал-карта (визуальная)» — где SVG wheel зафиксирован как Phase 0.
- `astro/.claude/corrections.md` Correction 007 — path-based SVG глифы (rationale за path-based vs `<text>`).
- `astro/.claude/corrections.md` Correction 008 — git mv + Edit-tool require `git add -A`; Worker применяет на самом себе.
- `services/api-python/app/pdf/wheel.py` — 497 строк; entry-point `render_chart_wheel_svg`.
- `services/api-python/app/pdf/templates/solar.html.j2` — 884 строки; macro `render_chart_wheel(facts.<chart>, size=460)` на cover (line 201) и natal page (line 234).
- Test setup: `services/api-python/tests/test_*.py` (api, bridge, contracts, draft, golden_cases, storage); нет direct wheel/svg тестов; `test_golden_cases.py` — protect-from-regression главный gate.
- Case 05 (Ekaterina 2025-2026): `packages/test-fixtures/golden-cases/05-ekaterina-2025-2026.{input,expected}.json` (335KB input + 144KB expected).

**Ready: yes** — TL flipped 2026-05-06 после go от пользователя с двумя refinements: (1) function-body guard через inline-script в § Test commands (sha256-based, не grep), (2) Reviewer обязан рендерить PNG-страницы wheel'а (не «open PDF на глаз»). Worker стартует. Status остаётся `open` до Worker bump'а через `make submit-task`.
