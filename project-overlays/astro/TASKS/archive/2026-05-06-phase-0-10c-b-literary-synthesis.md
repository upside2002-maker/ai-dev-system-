# TASK: phase-0-10c-b-literary-synthesis

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: services
- Risk tier: B
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

PDF-отчёт на `astro:0abcf08` имеет:
- Wheel polished (Phase 0.10c-a).
- pytest baseline 70/70 green (after `golden-case-10-danila-fixture-regen`).
- Synthesis layer (`services/api-python/app/pdf/synthesis_themes.py`, 419 строк) — структурно работает, но **literary quality** остаётся terse / utilitarian:
  - `_summary_solar`: «акцент оси 1-7 (подсчёт: 4/12)» — fragment, не предложение
  - `_summary_progressions`: «Луна в Овне, в 5 доме.» — bare statement
  - `_summary_directions`: comma-joined formulas — list, not narrative
  - Per-theme blocks из `themed_synthesis` — соляр/прогрессии/дирекции/транзиты часто выводятся как dot-separated layer-reports, без соединительных фраз между layers
- Это «Phase 0.10c-b literary synthesis» из user roadmap: после wheel polish (visual) — текст в тематических блоках. Самый заметный остаточный gap для Marina.

Цель — улучшить **читаемость и narrative flow** synthesis-блоков **без** изменения:
- closed-dictionary frame (per `target-architecture.md § 6.1` — не LLM, не rules engine, не user-editable rules);
- selection logic (которые themes / windows / planets выбраны — это `PriorityWindows` / `HouseAxisAnalysis` в Haskell, не трогать);
- wire-format JSON keys;
- astrological math / domain types.

Это первый product-code Tier B TASK после новой graded role-isolation rule + Codex incident. Worker должен быть **отдельным subagent**, Reviewer — **отдельным subagent**. Same-session inline execution NOT accepted для этого Tier (per graded rule).

## Scope

### Что в scope (Worker правит)

- **`services/api-python/app/pdf/synthesis_themes.py`** — text-producing functions:
  - `_summary_solar(facts)` — terse fragment → complete narrative sentence(s)
  - `_summary_progressions(facts)` — bare statement → complete sentence with context
  - `_summary_directions(facts)` — formula list → narrative phrase
  - `_summary_transits(facts)` — list of statements → cohesive narrative
  - `summary_table(facts)` composition — text inside 4-column structure
  - `_theme_signals(...)`, `themed_synthesis(facts)` — per-theme paragraph builders, особенно соединительные фразы между layers (соляр → прогрессии → дирекции → транзиты)

- **Connecting language** между layers внутри theme block (примеры допустимых改ений):
  - «акцент оси 1-7» → «В этом году акцент падает на ось 1-7 (4 индекса из 12)»
  - «Луна в Овне, в 5 доме.» → «Прогрессивная Луна стоит в Овне, проходит через 5-й дом — тема творчества и детей акцентирована на психологическом уровне.»
  - List of directions «дир Юпитер △ MC, дир МС □ Меркурий, …» → «Среди активных дирекций — Юпитер тригоном к МС и МС квадратом к Меркурию: первая поддерживает статус, вторая требует пересмотра договорённостей.»
  - Layer transition: «Дирекции это поддерживают» / «Транзиты дополняют картину»  / «По прогрессивной Луне это совпадает с»

- **Punctuation polish**: complete sentences ending with period, consistent capitalization, replace fragmenting `;` with `.` или connector words («, причём», «; одновременно», «при этом»).

- Если необходимо — minimal расширение `LIFE_THEMES` description fields (не keys) для improved per-theme intro phrases. Но **keys / houses / priority_themes / caution_keywords mapping unchanged**.

### Strict boundaries (НЕ трогать)

#### Inviolate astrological & data layer

- `core/astrology-hs/**` — Haskell core untouched.
- `packages/contracts/**` — schemas untouched.
- `packages/test-fixtures/**` — fixtures untouched.
- `packages/rulesets/**` — rulesets untouched (особенно `daragan-orbs-v1.json`).

#### Inviolate Python projector neighbours

- `services/api-python/app/pdf/transit_themes.py` — НЕ трогать. Это «{планета} в {доме}» (84 entries), отдельная категория. Если Worker считает что transit_themes тоже нуждается в polish — отдельный TASK, не amendment.
- `services/api-python/app/pdf/direction_themes.py` — НЕ трогать. Direction text. Same rule.
- `services/api-python/app/pdf/house_pair_themes.py` — НЕ трогать. 144-cell Solar/Natal pairs. Same rule.
- `services/api-python/app/pdf/wheel.py` — НЕ трогать (только-что polished).
- `services/api-python/app/pdf/builder.py` — НЕ трогать (orchestration, не content).
- `services/api-python/app/pdf/templates/solar.html.j2` — НЕ трогать unless absolutely required for content polish (e.g., adding a `<p>` wrapper). Если template touch потребуется — escalate в TL для approval отдельно. По default: pure-Python edits.

#### Inviolate selection / data structure

- `LIFE_THEMES` dict **keys**, **houses**, **priority_themes**, **caution_keywords** — unchanged. Если Worker считает что mapping flawed — отдельный TASK / discussion с TL.
- `_jd_to_date`, `_jd_to_short_date_str`, `_jd_to_long_date_str` function bodies — unchanged (date math, не литература).
- `_formula_houses`, `_direction_touches_houses`, `_direction_target_label_ru` function bodies — unchanged (selection logic, не текст).

#### Inviolate process

- НЕ trigger'ить `cabal build` (synthesis_themes — Python only, no Haskell dependency).
- НЕ менять `.overlay-maturity`.
- НЕ менять frontend (`apps/`).
- НЕ менять storage / migrations / API endpoints.
- НЕ создавать `CURRENT_STATE.md` etc.
- НЕ трогать overlay (`project-overlays/astro/**`).

### Forbidden patterns (closed-dictionary preservation)

Worker НЕ должен ввести:
- LLM API calls (`openai`, `anthropic`, `requests` to chat APIs, etc.)
- Dynamic text generation от runtime data (e.g., concatenating user input with templates that result in новый phrase)
- Database-driven phrase tables (`SELECT phrase FROM …`)
- User-editable rules engine (e.g., reading from a `rules.yaml` at runtime)
- `eval()`, `exec()`, любую dynamic code execution
- Random / non-deterministic output

Все phrases остаются в **static Python tables / f-strings inside the module's source**. Open-source rule, closed-dictionary frame.

### Один атомарный commit (preferred ≤ 3)

Worker делает **1 commit** в идеале (всё в одном файле). Если разбивает на этапы (e.g., `_summary_*` отдельно, `themed_synthesis` отдельно) — допустимо до 3 commits, но каждый должен быть green pytest + render-OK + meaningful step.

После последнего commit'а — `git push backup main`.

### Worker subagent отдельный — owns full lifecycle (per graded rule + Codex incident lesson)

Per TL graded role-isolation rule (2026-05-06): Tier B logic-touching product code → **отдельный Worker subagent обязателен**. После Codex incident'а discipline tightened: для этого TASK Worker запускается через `Agent` tool (general-purpose subagent) с self-contained prompt — fresh memory, нет TL session context.

**Worker subagent сам владеет полным lifecycle'ом** (TL не «пересказывает» subagent'а):
- Reads TASK file at given path.
- Executes per Scope (правки в `synthesis_themes.py`, function-body guard, closed-dictionary check, pytest, render BEFORE/AFTER PDF).
- `git add` + `git commit` + `git push backup main`.
- **Сам создаёт HANDOFF через `make new-handoff SLUG=astro TASK=… FROM=worker TO=tl`**.
- **Сам заполняет HANDOFF** body (Summary / Done / Remaining / Artifacts / Conflicts / Next step) — Worker знает что он сделал, TL не знает и не должен writing-to-claim.
- **Сам вызывает `make submit-task FILE=…`** — bumps Status open → review.
- Returns control to TL только после submit-task; return value summarises facts (commit hash, backup parity, key counters) для TL'я что прочитать в HANDOFF.

TL после Worker'а:
- Reads Worker HANDOFF (the artifact Worker'а wrote, не TL pre-fill).
- Spawns Reviewer subagent (см. ниже).

### Reviewer subagent отдельный — owns own HANDOFF

После Worker submit-task, **mandatory Reviewer pass** (per graded rule for Tier B + visual correctness easily missed by self):

**Reviewer subagent сам владеет своим HANDOFF'ом**:
- Reviewer = отдельный Agent tool subagent (general-purpose), fresh memory.
- Reviewer reads TASK file + Worker HANDOFF (path provided) + git diff `0abcf08..HEAD` + before/after PDF rendered output.
- Reviewer независимо повторяет 6 verifications (R-a..R-f per § Acceptance).
- **Сам создаёт HANDOFF через `make new-handoff SLUG=astro TASK=… FROM=reviewer TO=tl`**.
- **Сам заполняет** Summary / findings / verdict / artifacts / next step. Verdict в Summary одной строкой: **ACCEPT** / **REQUEST CHANGES** / **REJECT**.
- HANDOFF в files (через `make new-handoff`), не stdout-only.
- Returns control to TL только после Reviewer HANDOFF written; return value summarises verdict + key check results.

TL после Reviewer'а:
- Reads Reviewer HANDOFF (artifact Reviewer'а wrote, не TL pre-fill).
- Если verdict = ACCEPT: TL запускает `make accept-handoff` (для Reviewer HANDOFF, потом для Worker HANDOFF) + `make accept-task`. Это TL action — accept-helpers.
- Если verdict = REQUEST CHANGES / REJECT: TL **не accept'ит**, открывает fix-TASK или revert per Reviewer recommendation.

### Process flow итог (chain-of-custody)

```
TL (this session):
  - flip Ready: no → yes (single-field manual edit, allowed for TL)
  - spawn Agent(Worker subagent) с self-contained prompt

Worker subagent (separate session, fresh memory):
  - read TASK
  - apply scope, run guards, commit, push backup
  - make new-handoff FROM=worker TO=tl     ← Worker creates HANDOFF file
  - fill HANDOFF body                       ← Worker writes own narrative
  - make submit-task FILE=…                 ← Worker bumps status
  - return brief summary to TL

TL:
  - read Worker HANDOFF (file Worker created and filled)
  - spawn Agent(Reviewer subagent) с self-contained prompt + Worker HANDOFF path

Reviewer subagent (separate session, fresh memory):
  - read TASK + Worker HANDOFF + diff + render PDFs
  - run 6 independent verifications
  - make new-handoff FROM=reviewer TO=tl    ← Reviewer creates HANDOFF file
  - fill verdict + findings                  ← Reviewer writes own narrative
  - return verdict to TL

TL:
  - read Reviewer HANDOFF
  - if verdict = ACCEPT:
      make accept-handoff (Reviewer)
      make accept-handoff (Worker)
      make accept-task
      run final gates
  - if verdict = REQUEST CHANGES / REJECT:
      do not accept; coordinate fix-TASK or revert per recommendation
```

**TL никогда не writes / не fills Worker HANDOFF body. TL никогда не writes / не fills Reviewer HANDOFF body.** TL только spawns subagents, reads their HANDOFFs, и runs accept/reject helpers (which are mechanical lifecycle scripts, not narrative writing).

## Files

- new:    —
- modify:
  - `services/api-python/app/pdf/synthesis_themes.py` (text-producing functions; selection logic + LIFE_THEMES keys/houses/themes UNCHANGED)
- delete: —

If template (`solar.html.j2`) requires touch (например, adding `<p>` wrapper around new multi-sentence output) — Worker escalates to TL **before** making the change; TL approval triggers separate `modify` entry. By default: pure-Python edits.

Before/after PDF artifacts — **не commit'ить** в product repo. Worker сохраняет в `/tmp/`, paths указываются в HANDOFF body для Reviewer.

## Do not touch

См. § Scope «Strict boundaries» — детальный список выше.

Дополнительно zero-tolerance:
- Closed-dictionary violation (LLM call, dynamic generation, DB phrases, eval/exec, randomness) → **automatic REJECT** by Reviewer без обсуждения.
- Wire-format JSON key change → automatic REJECT.
- Selection logic touch (`LIFE_THEMES.houses` / `.priority_themes` / `.caution_keywords`) → automatic REJECT.

## Acceptance criteria

### Behavioural invariants (objective, через тесты)

- [ ] **pytest 70 passed / 0 failed** в `services/api-python/` после правок. synthesis_themes.py — Python-only projector; не должно сломать ни Haskell golden cases, ни Python contract tests.
- [ ] **No new dependencies** в `services/api-python/pyproject.toml`. Worker НЕ добавляет `openai` / `anthropic` / `requests` / любые phrase-engine deps.
- [ ] **Closed-dictionary check**: `git diff 0abcf08..HEAD -- services/api-python/app/pdf/synthesis_themes.py | grep -E '^[+-].*(openai|anthropic|eval\\(|exec\\(|random\\.|requests\\.|sqlite|yaml\\.load)' ` → **0 matches**. Worker не ввёл LLM / dynamic / DB / random patterns.
- [ ] **LIFE_THEMES selection unchanged**: `git diff 0abcf08..HEAD -- services/api-python/app/pdf/synthesis_themes.py | grep -E '^[+-].*"(houses|priority_themes|caution_keywords)":' ` → **0 matches**. Worker не тронул theme→houses mapping.

### Visual quality (subjective, Reviewer-judged через PDF render)

- [ ] Worker сохраняет 2 PDF case 05: `/tmp/synthesis-before.pdf` (rendering на `0abcf08` baseline) и `/tmp/synthesis-after.pdf` (после правок). Paths в HANDOFF.
- [ ] Reviewer rendering pages где находится «Итоги консультации» секция в PNG (likely последние pages PDF, Worker фиксирует точные номера).
- [ ] Reviewer judgment in HANDOFF (verdict + bullets):
  - **Improvement bullets**: что стало читать лучше — connector phrases между layers, complete sentences, period at end, narrative flow внутри theme block'ов.
  - **Invariant bullets**: которые themes выбраны / в каком порядке (selection logic UNCHANGED); names of themes idential; data values (даты, проценты, planet names) идентичны between before/after.
- [ ] Reviewer проверяет: ни один theme name не «поплыл» (например, «ФИНАНСЫ» осталось «ФИНАНСЫ», не превратилось в «деньги и финансы»). Theme keys = part of selection logic, frozen.

### Function-body guards (objective, automated check)

Worker запускает (и Reviewer независимо повторяет):

```python
# Function-body guard for synthesis_themes.py
import subprocess, re, hashlib
WHEEL = 'services/api-python/app/pdf/synthesis_themes.py'

def extract_body(src, fn):
    lines = src.split('\n')
    start = next((i for i, l in enumerate(lines) if re.match(rf'^def {fn}\b', l)), None)
    if start is None:
        raise RuntimeError(f"{fn} not found")
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if re.match(r'^(def|class) [A-Za-z_]', lines[i]):
            end = i
            break
    return '\n'.join(lines[start:end]).rstrip()

baseline = subprocess.check_output(['git', 'show', f'0abcf08:{WHEEL}'], text=True)
current = open(WHEEL).read()

# These functions ARE selection / data logic — bodies must remain identical:
for fn in ('_jd_to_date', '_jd_to_short_date_str', '_jd_to_long_date_str',
          '_formula_houses', '_direction_touches_houses', '_direction_target_label_ru'):
    b, c = extract_body(baseline, fn), extract_body(current, fn)
    if b == c:
        print(f"OK: {fn} body identical")
    else:
        print(f"FAIL: {fn} body differs"); raise SystemExit(1)

# LIFE_THEMES dict — keys + houses + priority_themes + caution_keywords mapping unchanged.
# (Reviewer manually inspects via git diff на этом dict block.)
```

- [ ] Все 6 helper functions sha-identical to `0abcf08` baseline. **Automatic REJECT** if any FAIL.

### Process invariants

- [ ] Worker делает ≤ 3 product commits. 1 preferred. Каждый commit — green pytest + render OK.
- [ ] **`git status --short`** clean перед каждым commit (per Correction 008).
- [ ] `git push backup main` успешен; `git ls-remote backup main` == local HEAD.
- [ ] `git log --oneline 0abcf08..HEAD` — только commits этого TASK.
- [ ] `git show --stat HEAD~N..HEAD` — все touched files в `services/api-python/app/pdf/synthesis_themes.py` (1 file). Никаких other paths.
- [ ] **`make -C /Users/ilya/Projects/ai-dev-system check`** зелёный.

### Worker = separate subagent с full HANDOFF ownership (TL graded rule, Tier B)

- [ ] Worker subagent fresh memory: prompt self-contained, includes paths/baseline/scope. Не наследует TL session context.
- [ ] Worker subagent **сам** запускает `make new-handoff` для создания HANDOFF file.
- [ ] Worker subagent **сам** заполняет HANDOFF body (TL не writes на Worker'а).
- [ ] Worker HANDOFF header указывает: `Agent runtime: Claude Code (Worker subagent, separate from TL session)`. **Без** этого marker'а — TL NOT accepts (process violation).
- [ ] Worker subagent **сам** запускает `make submit-task` (bump Status open → review).

### Reviewer mandatory + separate subagent с full HANDOFF ownership

- [ ] Reviewer запускается через отдельный Agent tool subagent после Worker submit-task.
- [ ] Reviewer subagent fresh memory: prompt self-contained, includes paths + Worker HANDOFF path + baseline.
- [ ] Reviewer subagent **сам** запускает `make new-handoff FROM=reviewer TO=tl` — Reviewer HANDOFF scaffold.
- [ ] Reviewer subagent **сам** заполняет HANDOFF body + verdict (TL не writes на Reviewer'а).
- [ ] Reviewer HANDOFF header: `Agent runtime: Claude Code (Reviewer subagent, separate from Worker and TL)`.
- [ ] Reviewer независимо verifies:
  - (a) pytest 70/70 (re-run, no Worker trust).
  - (b) Function-body guard (sha hashes for 6 helper functions match baseline).
  - (c) Closed-dictionary check (grep forbidden patterns = 0).
  - (d) LIFE_THEMES selection UNCHANGED (manual diff inspection).
  - (e) PDF render before/after — visual judgment of "Итоги консультации" section, plus PNG render of synthesis pages, paths in HANDOFF.
  - (f) Commit hygiene + backup parity.
- [ ] Reviewer verdict: **ACCEPT** / **REQUEST CHANGES** / **REJECT** в HANDOFF Summary, в собственном написанном тексте.
- [ ] **TL accepts TASK only at Reviewer ACCEPT.** TL accept-helpers (`accept-handoff`, `accept-task`) — это mechanical lifecycle scripts, не narrative writing.

## Test commands

```bash
# 0. Pre-flight: PDF render mechanism (uses existing /tmp/render_case5_wheel_polish.py from
# wheel-polish session; if missing, recreate per § Test commands of that TASK).
ls /tmp/render_case5_wheel_polish.py || echo "STOP: render script missing; recreate before continuing"

# 1. Render BEFORE PDF (Worker запускает ДО правок):
cd /Users/ilya/Projects/astro/services/api-python && source .venv/bin/activate
python3 /tmp/render_case5_wheel_polish.py /tmp/synthesis-before.pdf

# 2. Baseline pytest (must be 70/70 green per `0abcf08`):
pytest 2>&1 | tail -3

# 3. Apply changes (synthesis_themes.py).

# 4. Function-body guard (must PASS):
cd /Users/ilya/Projects/astro
python3 - <<'PYEOF'
import subprocess, re, hashlib
WHEEL = 'services/api-python/app/pdf/synthesis_themes.py'

def extract_body(src, fn):
    lines = src.split('\n')
    start = next((i for i, l in enumerate(lines) if re.match(rf'^def {fn}\b', l)), None)
    if start is None: raise RuntimeError(f"{fn} not found")
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if re.match(r'^(def|class) [A-Za-z_]', lines[i]): end = i; break
    return '\n'.join(lines[start:end]).rstrip()

baseline = subprocess.check_output(['git', 'show', f'0abcf08:{WHEEL}'], text=True)
current = open(WHEEL).read()
ok = True
for fn in ('_jd_to_date', '_jd_to_short_date_str', '_jd_to_long_date_str',
          '_formula_houses', '_direction_touches_houses', '_direction_target_label_ru'):
    b, c = extract_body(baseline, fn), extract_body(current, fn)
    bh = hashlib.sha256(b.encode()).hexdigest()[:12]
    ch = hashlib.sha256(c.encode()).hexdigest()[:12]
    print(f"{'OK' if b == c else 'FAIL'}: {fn} (baseline={bh}, current={ch})")
    if b != c: ok = False
import sys; sys.exit(0 if ok else 1)
PYEOF

# 5. Closed-dictionary forbidden-patterns check (must show 0 matches):
git diff 0abcf08..HEAD -- services/api-python/app/pdf/synthesis_themes.py \
  | grep -cE '^\+.*(openai|anthropic|eval\(|exec\(|random\.|requests\.|sqlite|yaml\.load)' || echo 0

# 6. LIFE_THEMES selection UNCHANGED:
git diff 0abcf08..HEAD -- services/api-python/app/pdf/synthesis_themes.py \
  | grep -cE '^[+-].*"(houses|priority_themes|caution_keywords)":' || echo 0

# 7. pytest after (must be 70/70):
cd services/api-python && pytest 2>&1 | tail -3

# 8. Render AFTER PDF:
python3 /tmp/render_case5_wheel_polish.py /tmp/synthesis-after.pdf

# 9. Visual compare — Worker eyeballs «Итоги консультации» section.

# 10. Commit hygiene per Correction 008:
cd /Users/ilya/Projects/astro
git status --short --branch
git add services/api-python/app/pdf/synthesis_themes.py
git status --short --branch
git diff --stat
git commit -m "<multi-line per template>"
git log --oneline 0abcf08..HEAD
git show --stat HEAD
git push backup main
git ls-remote backup main

# 11. Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Commit message template

```
fix(pdf): polish synthesis-themes literary flow (Phase 0.10c-b)

- _summary_solar / _summary_progressions / _summary_directions / _summary_transits:
  fragmented utility text → complete narrative sentences.
- summary_table composition: connector phrases between прогностические layers
  (соляр / прогрессии / дирекции / транзиты) внутри 4-column structure.
- _theme_signals + themed_synthesis: per-theme block reads as paragraph,
  не dot-separated layer-reports. Layer transitions linked by Russian
  connector words («причём», «при этом», «по прогрессии это совпадает с»).
- Punctuation polish: complete sentences, period at end, consistent capitalisation.

Closed-dictionary frame preserved:
- No LLM / API calls / dynamic generation.
- All phrases remain in static Python tables / f-strings inside the module.
- LIFE_THEMES keys / houses / priority_themes / caution_keywords UNCHANGED
  (selection logic frozen).

No astrological math changes:
- 6 helper-function bodies (_jd_to_*, _formula_houses, _direction_*) sha-identical
  to 0abcf08 baseline.
- Wire-format JSON keys unchanged (Python projector layer only).

Tests: pytest 70/70 green (was 70/70 at 0abcf08 baseline).
Visual evidence: /tmp/synthesis-{before,after}.pdf for case 05.

Refs: target-architecture.md §6.1 (closed-dictionary discipline),
      Correction 008 (git add -A before commit),
      TL graded rule 2026-05-06 (Tier B → separate Worker + Reviewer).
```

## Rollback plan

1 commit preferred (≤ 3 max). Если что-то пойдёт не так:

| Точка отказа | Действие |
|---|---|
| pytest red после правок (working tree, до commit) | `git restore .` → working tree = `0abcf08`. Worker → TL. |
| Function-body guard FAIL | **STOP** не commit'ить. Worker нарушил inviolate boundary; revert через `git restore`. Возврат в TL с описанием. |
| Closed-dictionary check FAIL | Same: STOP, revert. Worker ввёл LLM / dynamic / DB pattern. Automatic REJECT. |
| LIFE_THEMES selection touch | Same: STOP, revert. Worker нарушил selection-logic boundary. |
| Reviewer REJECT после commit (но до push backup) | Если поправимо — patch commit поверх; если не — `git reset --hard 0abcf08`. |
| После push backup, Reviewer REJECT | `git revert HEAD` + push (NOT amend / NOT history rewrite). |
| Catastrophic regression | `git reset --hard 0abcf08` + force-push backup (требует TL go). Backup baseline `0abcf08` сохранён. |

## Handoff requirements

### Worker HANDOFF — Worker subagent создаёт и submit'ит САМ

Worker subagent (отдельный, fresh memory):
1. Запускает `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-b-literary-synthesis.md FROM=worker TO=tl` — это создаёт scaffold HANDOFF file.
2. **Сам заполняет** body файла (через Read + Edit / Write). TL не пишет body.
3. Header HANDOFF (Worker заполняет вручную после `make new-handoff`):

   ```
   Agent runtime: Claude Code (Worker subagent, separate from TL session)
   Model: Claude Opus
   Role mode: Worker (subagent isolation per TL graded rule 2026-05-06)
   ```

4. Body обязательно содержит:
   - список изменённых файлов (1: synthesis_themes.py) с `git diff --stat`;
   - function-body guard output (6 ✅ или fail signal);
   - closed-dictionary check output (must = 0);
   - LIFE_THEMES selection check (must = 0);
   - pytest до и после (counts);
   - before/after PDF paths;
   - commit hash + backup parity check;
   - evidence-rule подтверждение (Worker применил Correction 008).

5. **Сам вызывает** `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-b-literary-synthesis.md`. Это bumps TASK Status `open → review`.

6. Возвращает control в TL с brief return summary (commit hash, parity OK, HANDOFF path).

**TL никогда не writes Worker HANDOFF body. TL никогда не submit'ит за Worker.**

### Reviewer HANDOFF — Reviewer subagent создаёт и заполняет САМ

После Worker submit-task, TL spawns Reviewer subagent.

Reviewer subagent (отдельный, fresh memory):
1. Reads TASK file + Worker HANDOFF (path provided in TL prompt) + git diff `0abcf08..HEAD` + before/after PDFs.
2. Independently runs 6 verifications (R-a..R-f per § Acceptance).
3. Запускает `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-phase-0-10c-b-literary-synthesis.md FROM=reviewer TO=tl` — scaffolds Reviewer HANDOFF file.
4. **Сам заполняет** body. TL не пишет body. Header:

   ```
   Agent runtime: Claude Code (Reviewer subagent, separate from Worker and TL)
   Model: Claude Opus
   Role mode: Reviewer / Red Team
   ```

5. Body обязательно содержит:
   - § Summary с одной explicit строкой: **Verdict: ACCEPT** / **REQUEST CHANGES** / **REJECT**;
   - 6 independent re-verifications с конкретными результатами;
   - visual judgment of «Итоги консультации» section (PNG-rendered pages, paths приложены);
   - если REJECT: detailed reasoning + recommended next steps;
   - если REQUEST CHANGES: что именно изменить.

6. Возвращает control в TL с verdict + brief summary.

**TL никогда не writes Reviewer HANDOFF body. Reviewer = source of truth verdict'а.**

### TL accept rules

После Reviewer HANDOFF written:
- TL reads Reviewer HANDOFF (artifact Reviewer'а wrote).
- **Если verdict = ACCEPT:**
  - `make accept-handoff FILE=<reviewer-handoff-path>`
  - `make accept-handoff FILE=<worker-handoff-path>`
  - `make accept-task FILE=<task-path>`
  - Final gates: `make check`, `make status SLUG=astro`.
- **Если verdict = REQUEST CHANGES:**
  - TL читает recommendation, открывает follow-up patch TASK, не accept'ит.
- **Если verdict = REJECT:**
  - TL координирует revert (`git revert HEAD` + push backup, или `git reset --hard 0abcf08` + force-push backup с TL go).

TL accept-helpers (`accept-handoff`, `accept-task`) — это **mechanical lifecycle scripts**, не narrative writing. Это допустимая TL действия.

## Контекст

- `astro:0abcf08` — baseline (pytest 70/70 green; wheel polished; fixture regen'd; audit trail clean).
- `target-architecture.md § 6.1` — Closed-dictionary interpretations НЕ rules engine. Critical preservation point.
- `astro/.claude/corrections.md` Correction 007 (path-based SVG glyphs) — не релевантно этому TASK, но Worker должен прочитать перед стартом.
- `astro/.claude/corrections.md` Correction 008 (`git add -A` before commit) — Worker применяет на самом себе.
- TL graded role-isolation rule (2026-05-06): Tier B → отдельный Worker + Reviewer subagents. Same-session inline NOT accepted.
- `golden-case-10-danila-fixture-regen` HANDOFF (`archive/2026-05-06-worker-to-tl-golden-case-10-danila-fixture-regen.md`) — пример honesty marker'ов в audit trail (если у Worker'а возникнет inadvertent помощь от другого agent — same disclosure pattern).
- `phase-0-10c-wheel-polish` HANDOFF — пример Tier B same-session execution с Reviewer pass; Worker может read для structure reference, но **этот TASK** требует **separate** subagents.

**Ready: no** — TASK существует в open state, Worker НЕ стартует без явного TL go. После TL go: TL flips `Ready: yes` (single-field edit, mechanical) и spawns Worker через Agent tool (general-purpose subagent_type), self-contained prompt. **Worker subagent сам владеет полным lifecycle'ом**: read TASK → execute → commit → push → `make new-handoff` → fill HANDOFF body → `make submit-task` → return brief summary к TL. **TL не writes Worker HANDOFF и не submit'ит за Worker'а.** То же самое для Reviewer (см. § Handoff requirements).
