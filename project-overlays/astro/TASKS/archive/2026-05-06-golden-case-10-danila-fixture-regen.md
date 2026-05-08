# TASK: golden-case-10-danila-fixture-regen

- Status: done
- Ready: yes
- Date: 2026-05-06
- Project: astro
- Layer: services
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code

## Problem

`tests/test_golden_cases.py::test_golden_case_reproduces_expected[10-danila-2025-2026]` падает на baseline `astro:3bb96c0`. Recon (`project-overlays/astro/ARCHITECTURE/golden-case-10-danila-recon.md`, accepted 2026-05-06) с high confidence идентифицировал first-cause: **stale fixture**. Cases 1-9 PASS green, top-5 priority windows IDENTICAL для case 10, drift только в rank-6+ windows и derived cautions[5..9]. Root: pre-bootstrap PriorityWindows scoring refinement; разработчик регенерировал 8/9 fixtures, case 10 пропустил.

Recon § 4 recommendation (одно предложение):

> Регенерировать `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json` через текущий built `astrology-core-cli` … отдельным мини-TASK Tier C с Reviewer optional.

Это тот TASK. Mechanical fixture refresh: feed input → built CLI → save stdout как новый `expected.json`. Не logic change, не schema change, не миграция, не fix core. После accept'а — pytest baseline становится 70/70 green, и можно открывать `0.10c-b literary synthesis`.

## Scope

### Граниченный mechanical change

- Один файл modified: `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`
- Один atomic commit в `/Users/ilya/Projects/astro` поверх `3bb96c0`
- `git push backup main` после commit'а

### Mechanism (одно команда + verify)

```bash
cd /Users/ilya/Projects/astro
CORE_CLI=$(cd core/astrology-hs && cabal list-bin astrology-core-cli)
test -x "$CORE_CLI" || { echo "STOP: CLI not built; escalate to TL"; exit 1; }

INPUT=packages/test-fixtures/golden-cases/10-danila-2025-2026.input.json
EXPECTED=packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json

python3 -c "
import json, subprocess
inp = json.load(open('$INPUT'))
inp.pop('_meta_source', None)   # mirrors test_golden_cases.py:90
proc = subprocess.run(['$CORE_CLI'], input=json.dumps(inp, ensure_ascii=False).encode(),
                      capture_output=True, timeout=60)
assert proc.returncode == 0, proc.stderr.decode(errors='replace')
# Pretty-print to match other golden-case fixtures' formatting:
out = json.loads(proc.stdout)
with open('$EXPECTED', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write('\n')   # trailing newline like other fixtures
print('OK: regenerated', '$EXPECTED')
"
```

### Same-session execution разрешён (graded TL rule 2026-05-06)

Per TL graded role-isolation rule (2026-05-06):
- **Tier A** (schema/migration/wire contract) — отдельный Worker + Reviewer mandatory.
- **Tier B** (logic-touching product code) — отдельный Worker + Reviewer desirable; same-session = weaker isolation, mark explicitly.
- **Tier C mechanical** product changes (≤ 1-2 files, no logic/schema/migration, clear acceptance) — same-session execution **accepted** with honest marker in HANDOFF.
- **Docs/recon** — same-session OK без специальной разметки.

Этот TASK **попадает в Tier C mechanical** category:
- ≤ 1 file modify (one fixture JSON)
- no logic / schema / migration / wire contract change (only data refresh)
- Acceptance criteria определены чётко (pytest 70/70 green; backup parity)
- Diff shows pure data delta, no algorithmic surprise

Therefore **same-session execution allowed**. Worker HANDOFF обязан содержать explicit фразу:

> Execution isolation: same-session TL inline accepted (Tier C mechanical). Reason: one fixture JSON, no logic/schema/migration, pytest 70/70 acceptance.

### Boundaries (НЕ трогать)

- Haskell core (`core/astrology-hs/**`) — особенно НЕ запускать `cabal build`. Если `cabal list-bin astrology-core-cli` не resolved или binary не executable — **STOP**, escalate в TL (per TL refinement of `golden-case-10-danila-recon` TASK).
- Other test fixtures (`packages/test-fixtures/golden-cases/01-*` … `09-*` + `06-*.stub.json`) — НЕ трогать.
- `packages/test-fixtures/solar-{input,facts}-sample.json` — НЕ трогать.
- JSON Schema (`packages/contracts/*.schema.json`) — НЕ трогать.
- Rulesets (`packages/rulesets/*.json`) — НЕ трогать.
- `services/api-python/**` (включая tests/test_golden_cases.py) — НЕ трогать.
- `apps/**`, `infra/**`, `data/**`, `astro/.claude/**`, `CLAUDE.md`, `docs/**`, `run-local.sh`, `docker-compose.yml` — НЕ трогать.
- Overlay (`project-overlays/astro/**`) — НЕ трогать.
- `.gitignore` — НЕ трогать.

### Не входит

- Update других fixtures (даже если они выглядели бы кандидатами) — отдельные TASKи, не amendments.
- Логические изменения в `Domain.PriorityWindows.hs` или связанных модулях — это recon Hypothesis B/C eliminated, не в scope.
- Update overlay `golden-case-10-danila-recon.md` — recon-документ закрыт; refresh recon не нужен после регенерации.
- `git push --force`, `git rebase`, history rewrite — запрещено.

## Files

- new:    —
- modify: `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`
- delete: —

## Do not touch

См. § Scope «Boundaries» выше.

Дополнительно: ни одна функция / модуль / схема НЕ должны быть touched в `core/`, `services/`, `apps/`, `packages/contracts/`, `packages/rulesets/`. **Ровно один JSON file** меняется.

## Acceptance criteria

- [ ] **pytest 70 passed / 0 failed** на `services/api-python` после regen. Подтверждается:
      `cd services/api-python && source .venv/bin/activate && pytest 2>&1 | tail -3` показывает `70 passed`.
- [ ] **Diff scope**: `git -C /Users/ilya/Projects/astro show --stat HEAD` показывает **ровно 1 файл** — `packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`.
- [ ] **One atomic commit** поверх `3bb96c0`: `git -C /Users/ilya/Projects/astro log --oneline 3bb96c0..HEAD` показывает 1 строку.
- [ ] **Commit message** соответствует template:
      ```
      chore(fixtures): regenerate case-10 expected.json to match current PriorityWindows scoring

      Closes pre-existing pytest failure documented in
      project-overlays/astro/ARCHITECTURE/golden-case-10-danila-recon.md.

      Diagnosis: stale fixture (case 10 was missed when 8/9 sibling fixtures
      were regenerated during pre-bootstrap PriorityWindows scoring refinement).
      Top-5 priority windows + key_periods + cautions[0..4] were already
      identical between baseline and current core; drift only in rank-6+ windows.

      Regeneration mechanism (per recon §5.2):
        feed 10-danila-2025-2026.input.json (minus _meta_source) →
        astrology-core-cli (already built, no rebuild) →
        json.dump(stdout, indent=2, ensure_ascii=False).

      pytest after: 70 passed / 0 failed (was 69/1 at 3bb96c0 baseline).

      Refs: golden-case-10-danila-recon.md §4 recommendation.
      ```
- [ ] **`git status` clean** в продуктовом repo после commit.
- [ ] **Backup parity**: `git -C /Users/ilya/Projects/astro ls-remote backup main` == local HEAD.
- [ ] **No rebuild triggered**: `cabal build` НЕ запускался; `dist-newstyle/` mtime неизменён (verify через `ls -la core/astrology-hs/dist-newstyle/build/aarch64-osx/ghc-9.6.6/astrology-core-1.0.0/x/astrology-core-cli/build/astrology-core-cli/`).
- [ ] **Other 9 cases still pass**: `pytest tests/test_golden_cases.py -v 2>&1 | grep -E '(PASSED|FAILED)' | wc -l` показывает 10 (по 1 на case + slot-6 + schema-validates), все PASSED. Ни один не сломался от regen case-10.
- [ ] **Diff sanity check**: `git diff 3bb96c0..HEAD -- packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json | wc -l` ≥ 100 lines (substantial regen, не tiny tweak — это ожидается per recon § 2.1: 394 diverging leaves).
- [ ] **`make -C /Users/ilya/Projects/ai-dev-system check`** зелёный.
- [ ] **`make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro`** показывает TASK как `RECENTLY ARCHIVED` после accept.
- [ ] Worker применил Correction 008 — `git status --short` checked перед commit'ом.

## Test commands

```bash
# 0. Pre-flight: built CLI exists?
cd /Users/ilya/Projects/astro/core/astrology-hs
CORE_CLI=$(cabal list-bin astrology-core-cli 2>/dev/null)
test -n "$CORE_CLI" -a -x "$CORE_CLI" || {
  echo "STOP: built astrology-core-cli not found; escalate to TL"
  exit 1
}
echo "OK: CLI at $CORE_CLI"

# 1. Baseline pytest (must show 1 fail = case-10):
cd /Users/ilya/Projects/astro/services/api-python
source .venv/bin/activate
pytest 2>&1 | tail -3   # expect: 69 passed, 1 failed

# 2. Regenerate (per § Scope mechanism):
cd /Users/ilya/Projects/astro
INPUT=packages/test-fixtures/golden-cases/10-danila-2025-2026.input.json
EXPECTED=packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json
python3 -c "
import json, subprocess
inp = json.load(open('$INPUT'))
inp.pop('_meta_source', None)
proc = subprocess.run(['$CORE_CLI'], input=json.dumps(inp, ensure_ascii=False).encode(),
                      capture_output=True, timeout=60)
assert proc.returncode == 0, proc.stderr.decode(errors='replace')
out = json.loads(proc.stdout)
with open('$EXPECTED', 'w', encoding='utf-8') as f:
    json.dump(out, f, ensure_ascii=False, indent=2); f.write('\n')
print('OK: regenerated', '$EXPECTED')
"

# 3. Verify pytest 70/70:
cd services/api-python && pytest 2>&1 | tail -3
# Expect: 70 passed in N seconds

# 4. Sanity diff stat:
cd /Users/ilya/Projects/astro
git diff --stat                                        # one file, substantial delta
git diff -- $EXPECTED | head -20                       # spot-check — это валидный JSON

# 5. Other cases unaffected:
cd services/api-python && pytest tests/test_golden_cases.py -v 2>&1 | grep -E 'PASSED|FAILED'
# Expect: 10 PASSED, 0 FAILED

# 6. Commit hygiene per Correction 008:
cd /Users/ilya/Projects/astro
git status --short --branch                            # MUST verify before commit
git add packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json
git status --short --branch                            # re-verify (M = staged)
git diff --stat                                        # unstaged should be empty
git commit -m "<multi-line per § Acceptance criteria template>"
git log --oneline 3bb96c0..HEAD                        # → exactly 1 commit
git show --stat HEAD                                   # → only the one expected.json file
git push backup main
git ls-remote backup main                              # → == local HEAD

# 7. Workflow:
make -C /Users/ilya/Projects/ai-dev-system check
make -C /Users/ilya/Projects/ai-dev-system status SLUG=astro
```

## Rollback plan

Атомарность: 1 commit. Если что-то пойдёт не так:

| Точка отказа | Действие |
|---|---|
| Step 0 (CLI not found) | **STOP**, escalate в TL. НЕ запускать `cabal build`. TL решает: либо approve build, либо отложить TASK до момента когда CLI built. |
| Step 1 (baseline pytest показывает > 1 fail) | **STOP**, новые failures не были диагностированы recon'ом. Escalate в TL. |
| Step 2 (regenerate команда не работает) | Investigate, но не commit'ить. Сохранить `$EXPECTED.bak` если был перезаписан по ошибке (через `git checkout HEAD -- $EXPECTED`). |
| Step 3 (pytest red после regen) | Какой-то новый fail или case-10 всё ещё fails: **STOP** не commit'ить. `git checkout HEAD -- packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json` восстанавливает baseline. Escalate в TL. |
| Step 5 (другой case сломался) | **STOP**, regen затронул что-то shared. `git checkout HEAD -- $EXPECTED`. Escalate. |
| Step 6 (commit fail / push backup fail) | Fix issue (per error message). Если broken intermediate state — `git reset --hard 3bb96c0` восстанавливает. |
| После push backup, обнаружили проблему | Если поправимо: новый patch commit поверх (NOT amend; не rewrite history после push). Если не поправимо: `git revert HEAD` + push. |

Catastrophic recovery: `git reset --hard 3bb96c0` локально + `git push backup main --force-with-lease` (требует TL go). Backup baseline `3bb96c0` сохранён в `/Users/ilya/Backups/astro.git`.

## Handoff requirements

Worker оформляет HANDOFF через `make new-handoff SLUG=astro TASK=project-overlays/astro/TASKS/2026-05-06-golden-case-10-danila-fixture-regen.md FROM=worker TO=tl`.

В теле обязательно:

- **Same-session execution marker** (NEW per graded TL rule 2026-05-06):

  > Same-session execution accepted by TL graded rule (2026-05-06): Tier C mechanical fixture regen, one file, no logic, pytest 70/70 acceptance. Weaker process-isolation than full Worker-subagent split is intentional for this Tier C mechanical change.

  Этот marker — **обязательный** в § Summary or § Conflicts. TL без него NOT accept.

- список изменённых файлов: 1 (`packages/test-fixtures/golden-cases/10-danila-2025-2026.expected.json`), с `git diff --numstat` (substantial delta ожидается);
- pytest до и после с явными counts (`69 passed, 1 failed → 70 passed`);
- результат `cabal list-bin` (CLI path) — для evidence что rebuild не запускался;
- `make check` и `make status SLUG=astro` зелёные;
- `Product repo status:` `committed (commit:<short>)` с новым SHA поверх `3bb96c0`;
- backup sync: `git ls-remote backup main` == local HEAD;
- evidence-rule: «Worker применил Correction 008 — `git status --short` checked перед commit».

После HANDOFF — `make submit-task FILE=…`. **TL не делает manual edit `Status:`**.

### Reviewer

Optional. Tier C mechanical change. TL может accept без Reviewer'а; если запрашивается — Reviewer повторяет regen (independent run) и verifies pytest 70/70 + identical regenerated JSON. Reviewer пишет findings **в файл HANDOFF**, не stdout.

### TL re-verify обязательства (NEW per graded TL rule)

После Worker submit-task, **TL обязан** перед accept:
1. **`git diff bb5a9eb..HEAD`** — verify scope: только `expected.json`, no other files.
2. **`pytest`** re-run на TL стороне — confirm 70/70 green (independent of Worker's claim).
3. **`git log --oneline 3bb96c0..HEAD`** — verify ровно 1 commit, message matches template.
4. **`git ls-remote backup main` == local HEAD** — backup parity без trust к Worker'овому отчёту.

Эти 4 проверки — minimum required even при same-session execution. Если хоть одна fail → **NOT accept**, открывать revert / fix-TASK.

## Контекст

- `astro:3bb96c0` — текущий HEAD (после `phase-0-10c-wheel-polish`). 3 commits since baseline `4937c00`.
- `golden-case-10-danila-recon.md` § 4 recommendation — primary source этого TASK.
- `golden-case-10-danila-recon.md` § 5.2 — exact regeneration mechanism, тот же что использует `tests/test_golden_cases.py`.
- `golden-case-10-danila-recon.md` § 2.1 — 394 diverging leaves expected (substantial delta in regenerated file).
- `astro/.claude/corrections.md` Correction 008 — `git add -A` discipline; Worker применяет на самом себе.
- TL graded role-isolation rule (2026-05-06) — Tier C mechanical product change: same-session execution accepted with honest marker. TL re-verify обязателен.

**Ready: no** — TASK существует в open state, Worker НЕ стартует без явного TL go (после user approve). После TL go: bump `Ready: yes` (manual edit одного поля).
