# TASK: golden-case-10-danila-recon

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`pytest` baseline на `astro:3bb96c0` (как и на родителях `bb5a9eb`, `b7774cf`, `4937c00`) — `69 passed / 1 failed`. Единственный pre-existing failure: `tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]`.

Failure mode: `assert actual == expected` падает на `analysis.consultation_skeleton` — Haskell core CLI выдаёт JSON, отличный от committed `10-danila-2025-2026.expected.json`. И input.json и expected.json и core code были захвачены в `4937c00` initial import — failing с baseline (это **не** regression от любого из 3 последующих коммитов wheel-polish / corrections / naming-cleanup; verified три раза в последних HANDOFF'ах).

Это «known broken test» уже стало нормой в отчётах за 4 TASK'а подряд. Перед `0.10c-b literary synthesis` нужно понять, что именно сломано:

1. **Stale fixture hypothesis (most likely):** `expected.json` для case 10 был сгенерирован до последней правки в `Domain.ConsultationSkeleton` / `Domain.PriorityWindows` (или связанных модулей), и фактически устарел. Чинится регенерацией fixture отдельным TASK после accept'а этого recon'а.
2. **Real core regression hypothesis:** Haskell core содержит баг, проявляющийся ТОЛЬКО на специфике case 10 (например, particular configuration of weak planets / priority windows / directions, не покрытая case 1-9). Чинится отдельным core TASK.
3. **Hybrid:** часть несовпадений — stale fixture, часть — реальный bug.

Цель recon'а — точно идентифицировать первопричину и дать **одну** explicit рекомендацию (regenerate fixture / fix core / accept known drift) с evidence. Не чинить ни fixture, ни core в рамках этого TASK.

## Scope

Входит — только diagnostic чтение и написание recon-документа:

### Step 1 — Захват точного diff'а

- Запустить `pytest tests/test_golden_cases.py -k '10-danila' -vv 2>&1` (с `-vv` для полного diff'а, не truncated). Сохранить вывод. Identify конкретные fields где `actual` != `expected`.
- Альтернатива (если pytest -vv даёт не структурированный diff): запустить core CLI напрямую с `10-danila-2025-2026.input.json` (per `tests/test_golden_cases.py:_resolve_core_cli` mechanism), сохранить stdout как `/tmp/case-10-actual.json`, и сделать `diff` (или `jq`-based deep compare) против `expected.json`. Worker выбирает что точнее.
- **Важно**: `actual` и `expected` оба — большие JSON (5447+ lines each). Worker делает **structured diff** — не raw line-diff. Подсказка: `python3 -c "..."` snippet с `deepdiff` (если доступен) или ручным dict walk; альтернатива — `jq -S 'paths(scalars)' | sort` на обоих и diff path-sets.

### Step 2 — Локализация изменения

- По diff identify какие top-level fields различаются. Worker гипотеза: только `analysis.consultation_skeleton` (per pytest output prefix); подтвердить.
- Внутри `consultation_skeleton`: какие подпункты различаются? `opening` / `psychological_setting` / `key_periods` / `extended_themes` / `cautions` — каждый отдельно verify.
- Если различия в **порядке** elements (например key_periods sorted differently): отдельно зафиксировать как «order-only diff» (lower-impact чем content diff).
- Если различия в **content** (text strings, numeric values): зафиксировать конкретно — какой field, какое значение в `actual`, какое в `expected`.

### Step 3 — Identify плодородную причину

Cross-reference diff с историей кода. Worker может read-only посмотреть:
- `core/astrology-hs/src/Domain/SolarReportSkeleton.hs` (renamed from ConsultationSkeleton 2026-05-06 in `b7774cf`; same content).
- `core/astrology-hs/src/Domain/PriorityWindows.hs` — driver для `key_periods`.
- `core/astrology-hs/src/Domain/HouseAxisAnalysis.hs` — для `opening`.
- `core/astrology-hs/src/Domain/Progressions.hs` — для `psychological_setting`.
- Comments в этих файлах могут содержать «Phase 0.5 / 0.7 / 0.10 / 0.10b» pointers — указывают когда модуль последний раз правился.
- `astro/.claude/corrections.md` — особенно Correction 006-pre («исторический разбор drift'а перед Phase 0.5») и Correction 006 («Phase 0.5 — Solar Arc как primary direction mode») — оба могут содержать релевантные namings/timing'и.

Worker формулирует **hypothesis**: какой именно code change **скорее всего** опережает текущий expected.json fixture для case 10.

### Step 4 — Recommended fix (одно предложение)

Worker выдаёт **ОДНУ** explicit рекомендацию из 3 вариантов:

(a) **Regenerate `10-danila-2025-2026.expected.json`** — если diff локализован как stale fixture (большинство likely scenario). Описать команду, которая бы это сделала (но **не запускать** в этом TASK).

(b) **Fix Haskell core** — если diff identify'ит конкретный bug. Описать какая именно function где и как ведёт к divergence; если stripped-down minimal repro возможен — приложить.

(c) **Accept as known drift** — если различие не критично для астрологической корректности (e.g., два semantically-equivalent stringification'а; или ordering, который compactly не меняет user-visible meaning). Описать обоснование и предложить добавить `pytest.mark.xfail` reason'ом, либо `_KNOWN_DIVERGENCES` whitelist в test'е.

Combination'ы (например «50% stale fixture, 50% real bug») — допустимы, но Worker выдаёт **по одной recommendation на каждую категорию**.

### Step 5 — Recon-документ

Worker создаёт `project-overlays/astro/ARCHITECTURE/golden-case-10-danila-recon.md` со следующими 5 секциями:

1. **Baseline и метод** (по аналогии с `architecture-drift-recon.md § 1`): какой commit, какие файлы сравниваются, метод evidence (commands, не «по памяти»).
2. **Diff inventory** — точный список fields, которые различаются между `actual` и `expected`. Каждый — короткая цитата (≤ 15 слов) of differing values + path JSON-указатель (например `analysis.consultation_skeleton.cautions[2]`).
3. **Hypothesis tree** — 2-3 кандидата first-cause'а (stale fixture, real bug, hybrid) с briefing on каждый.
4. **Recommended fix (одно предложение)** — единственная explicit рекомендация per Step 4.
5. **Evidence appendix** — 5-8 reproducible commands (`pytest -vv -k`, `jq`, `git show`) с фрагментами вывода.

### Не входит

- любая модификация product code в `/Users/ilya/Projects/astro/`;
- регенерация любого fixture в `packages/test-fixtures/`;
- любая модификация Haskell core (`core/astrology-hs/**`);
- любая модификация PDF/wheel visual layer;
- любая git-операция в продуктовом repo кроме read-only (`git ls-tree`, `git show`, `git log`, `git status`);
- bump `.overlay-maturity`;
- создание `CURRENT_STATE.md` etc.;
- любая правка `target-architecture.md`, `migration-plan.md`, `PHASE_0_TASKS.md`, `architecture-drift-recon.md` (только цитировать через ссылку).

## Files

- new:    `project-overlays/astro/ARCHITECTURE/golden-case-10-danila-recon.md`
- modify: —
- delete: —

Worker может save scratch JSON / diff артефакты в `/tmp/` для собственного workflow'а — **не commit'ить** в repo.

## Do not touch

- `/Users/ilya/Projects/astro/**` — никаких write операций (read-only `git`/`cat`/`jq`/`pytest` only).
- `/Users/ilya/Backups/**` — не трогать.
- `project-overlays/astro/.overlay-maturity` — `pre-phase0`.
- `project-overlays/astro/ARCHITECTURE/{target-architecture,migration-plan,PHASE_0_TASKS,architecture-drift-recon,current-mvp-review,git-bootstrap-{plan,execution}}.md` — только цитировать.
- `project-overlays/astro/{starts,RESEARCH,archive}/`, `TASKS/archive/`, `HANDOFFS/archive/`, `README.md` — не трогать.
- Существующие 29 status-аннотаций в `PHASE_0_TASKS.md` — не трогать.

## Acceptance criteria

- [ ] Создан `project-overlays/astro/ARCHITECTURE/golden-case-10-danila-recon.md` с **ровно 5 секциями** в порядке Scope § Step 5.
- [ ] Section 2 (Diff inventory) перечисляет конкретные differing JSON paths (e.g., `analysis.consultation_skeleton.cautions[2].text`) с фрагментами actual/expected ≤ 15 слов каждый.
- [ ] Section 3 (Hypothesis tree) содержит **минимум 2** explicit hypotheses с обоснованиями.
- [ ] Section 4 (Recommended fix) содержит **ровно одно** конкретное предложение (стержневая рекомендация). Если Worker считает что нужны 2 действия (e.g., regenerate + add xfail) — формулировать как **одно** связанное предложение.
- [ ] Section 5 (Evidence appendix) содержит ≥ 5 reproducible commands с фрагментами вывода.
- [ ] Diff inventory ссылается на **конкретные fields**, не общие категории. Bad: «cautions differ». Good: «cautions[2] actual='Чувствительный период 17.01.2026-14.02.2026: ...' vs expected='Чувствительный период 17.01.2026-14.02.2026: ...' (where exact differing chars/values noted)».
- [ ] Worker НЕ выполнил ни одной write-операции в `/Users/ilya/Projects/astro/`. В HANDOFF — explicit фраза подтверждения.
- [ ] Worker НЕ запустил `cabal build` как big-rebuild шаг. **Read-only `cabal run` / `cabal list-bin` / `pytest` разрешены** (per TL refinement 2026-05-06). Если direct CLI rerun требует нового build или модифицирует `dist-newstyle/` — Worker **останавливается** и эскалирует в TL вместо разворачивания большого build'а. Альтернатива в этом случае: использовать только pytest output для diagnostic'а или прочитать committed `expected.json` без regen actual'а.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system check` зелёный.
- [ ] `make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro` показывает TASK как `Active TASKS` (до submit) либо `RECENTLY ARCHIVED` (после accept).
- [ ] Product repo state неизменён: `git -C /Users/ilya/Projects/astro status --short --branch` остаётся `## main` (clean / commit:3bb96c0).

## Test commands

```bash
# Read-only: показать диагностический output:
cd /Users/ilya/Projects/astro/services/api-python && source .venv/bin/activate
pytest tests/test_golden_cases.py -k '10-danila' -vv 2>&1 | head -100   # full diff
pytest tests/test_golden_cases.py -k '10-danila' -vv 2>&1 | tail -50

# Direct CLI rerun (matches what test does):
cd /Users/ilya/Projects/astro
EXPECTED=packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json
INPUT=packages/test-fixtures/golden-cases/10-danila-2025-2026.input.json
ACTUAL=/tmp/case-10-actual.json
# Resolve CLI (test_golden_cases pattern):
CORE_CLI=$(cd core/astrology-hs && cabal list-bin astrology-core-cli 2>/dev/null)
test -x "$CORE_CLI" || { echo "core CLI not built"; exit 1; }
# Strip _meta_source like the test does, run, save actual:
python3 -c "
import json, subprocess, sys
inp = json.load(open('$INPUT'))
inp.pop('_meta_source', None)
proc = subprocess.run(['$CORE_CLI'], input=json.dumps(inp).encode(), capture_output=True, timeout=60)
json.dump(json.loads(proc.stdout), open('$ACTUAL', 'w'), ensure_ascii=False, indent=2)
"

# Structured diff (deep, JSON-aware). One option:
python3 -c "
import json
a = json.load(open('$ACTUAL'))
e = json.load(open('$EXPECTED'))
# Walk both, identify diverging paths.
def walk(prefix, va, ve, out):
    if isinstance(va, dict) and isinstance(ve, dict):
        keys = set(va) | set(ve)
        for k in sorted(keys):
            if k not in va: out.append((prefix+f'.{k}', '<missing>', repr(ve[k])[:60])); continue
            if k not in ve: out.append((prefix+f'.{k}', repr(va[k])[:60], '<missing>')); continue
            walk(prefix+f'.{k}', va[k], ve[k], out)
    elif isinstance(va, list) and isinstance(ve, list):
        for i in range(max(len(va), len(ve))):
            if i >= len(va): out.append((prefix+f'[{i}]', '<short>', repr(ve[i])[:60])); continue
            if i >= len(ve): out.append((prefix+f'[{i}]', repr(va[i])[:60], '<extra>')); continue
            walk(prefix+f'[{i}]', va[i], ve[i], out)
    else:
        if va != ve:
            out.append((prefix, repr(va)[:60], repr(ve)[:60]))
out = []
walk('', a, e, out)
for p, av, ev in out[:80]:
    print(f'PATH: {p}')
    print(f'  actual:   {av}')
    print(f'  expected: {ev}')
print(f'TOTAL diverging leaves: {len(out)}')
"

# Cross-reference потенциальных code culprits:
git log --oneline 4937c00 -- core/astrology-hs/src/Domain/ | head -5
git show 4937c00:core/astrology-hs/src/Domain/PriorityWindows.hs | head -25  # для context'а

# Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-golden-case-10-danila-recon.md FROM=worker TO=tl`.

В теле обязательно:
- список созданных файлов (один — `golden-case-10-danila-recon.md`, с `wc -l`);
- summary diff'а: TOTAL diverging leaves count + top-3 most-impactful paths;
- explicit recommendation цитатой (1 предложение из § 4);
- результат `make check` и `make status SLUG=astro`;
- `Product repo status:` — `clean / commit:3bb96c0` (Worker делает только read-only operations);
- evidence-rule подтверждение: «Worker выполнял в `/Users/ilya/Projects/astro/` только read-only команды (`pytest`, `git show`, `cat`, `python3` reading JSON); ни одной write-операции в продуктовый repo не было; нет коммита в продуктовом repo за этот TASK».

После HANDOFF — `make submit-task FILE=project-overlays/astro/TASKS/2026-05-06-golden-case-10-danila-recon.md`. **TL не делает manual edit `Status:`**.

Reviewer: optional (Tier C docs-only diagnostic). TL может accept без Reviewer'а; если Reviewer запрашивается — его задача проверить (a) что diagnostic точный (повторить diff command), (b) что recommendation одно и аргументировано, (c) что нет out-of-scope writes в продуктовый repo.

## Контекст

- `architecture-drift-recon.md` § 5.2 (real drift) — упоминает Test.Golden как leftover; здесь другой test (test_golden_cases.py — Python-side), не путать.
- `astro:3bb96c0` — текущий HEAD (после `phase-0-10c-wheel-polish` accept). 3 commits since baseline `4937c00`. Failure pre-existed на baseline.
- `astro:bb5a9eb` HANDOFF (`audit-trail-after-b7774cf` Worker) — first reported failure existed pre-`b7774cf`.
- `astro:b7774cf` HANDOFF (`astro-core-naming-drift-cleanup` Worker) — first noticed `1 failed` in pytest at start of work.
- `astro:3bb96c0` HANDOFF (`phase-0-10c-wheel-polish` Worker и Reviewer) — confirmed identical 69/1 status before и after wheel polish. Therefore failure root in **fixture или core code at `4937c00` baseline**, **не** в любом из 3 commit'ов после.
- Случай 10: `10-danila-2025-2026` — Danila, solar 2025-2026. Files в `packages/test-fixtures/golden-cases/`.
- 8 других golden cases (1-5 + 7-9) проходят зелёным — изолирует problem ровно к case 10.

**Ready: yes** — TL flipped 2026-05-06 после go от пользователя с одним refinement: read-only `cabal run` / `cabal list-bin` / `pytest` разрешены; **`cabal build`** как big-rebuild шаг запрещён — если direct CLI rerun требует нового build или modifies `dist-newstyle/`, Worker останавливается и эскалирует в TL. Reviewer pass **не** mandatory (Tier C recon-only). Worker стартует. Status остаётся `open` до Worker bump'а через `make submit-task`.
