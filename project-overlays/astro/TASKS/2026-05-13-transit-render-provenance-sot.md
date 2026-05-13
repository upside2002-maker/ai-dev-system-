# TASK: transit-render-provenance-sot

- Status: open
- Ready: yes
- Date: 2026-05-13
- Project: astro
- Layer: mixed
- Risk tier: C
- Owner: Project Tech Lead
- Created by: upside2002@gmail.com
- Worker model: Claude Code
- Mode: normal
- Critical approved by: (нет)

## Problem

Phase 1 программы Transit Section Recovery (`ARCHITECTURE/transit-section-program-2026-05-13.md` § 5 Phase 1, § 8 TASK 1). Цель — устранить root cause #1 из § 3 документа («Нет единого source of truth для рендера PDF»).

Сейчас рендер PDF Натальи может запускаться из main, из worktree `.claude/worktrees/dreamy-moore-46f5eb` или через временные harness scripts. Получаемый PDF не несёт информации о git SHA, root path, fixture provenance и mode (recomputed vs fixture-render). Это создаёт drift: исправление кода в одном дереве, проверка PDF из другого — отсюда ощущение «то шаг вперёд, то шаг назад» при последних трёх итерациях.

Задача — сделать каждый проверочный PDF **однозначно воспроизводимым** и закрепить **один канонический render path** для Натальи. После закрытия этой задачи открывается Phase 2 (hard acceptance assertions).

## Files

- new:
  - `services/api-python/app/pdf/provenance.py` — новый модуль, собирающий provenance metadata (git SHA, repo/worktree root, render script, source facts path, input fixture path, mode, core CLI path/version, timestamp). Worker сам определяет конкретный shape; рекомендация — dataclass/dict с фиксированным набором ключей из § 4.5 архитектурного документа.
  - `services/api-python/scripts/render_natalya.py` (или эквивалентное имя — Worker выбирает) — **канонический render script для Натальи**. Один точечный entry point: «прогнать `08-natalya-2025-2026.input.json` через CLI engine + render PDF + сохранить sidecar JSON с provenance». Эталон для всех проверочных запусков по Наталье до закрытия программы.

- modify:
  - `services/api-python/app/pdf/builder.py` — точка, где PDF собирается. Worker вызывает `provenance.collect()` в момент рендера, передаёт result в Jinja как опциональный `provenance_meta` (для debug-mode footer, **по умолчанию выключенный** на клиентских страницах) И сохраняет sidecar JSON `<output>.provenance.json` рядом с PDF.
  - `services/api-python/app/pdf/templates/solar.html.j2` — добавить opt-in debug footer (рендерится только если `provenance_meta.debug_mode == true`), показывающий git SHA + worktree root + fixture path + mode. На production-PDF этот блок не виден. Минимальный patch ≤ 20 строк.

- delete: —

**`/tmp` harness scripts policy:** Worker **не удаляет** `/tmp/render_*.py` или подобные ad hoc render scripts в рамках этого TASK'а. Они находятся вне repo, могут быть полезны как forensic-материал при разборе предыдущих итераций, удаление добавило бы лишний approval-cycle без пользы. Worker **перечисляет** в HANDOFF любые найденные `/tmp/render_*.py` и подобные scripts как `forensic/non-SoT artifacts` — для audit trail, не как cleanup item. Достаточно `git grep` по продуктовому repo, чтобы убедиться что внутри repo нет alternative render entry points (см. Acceptance ниже).

## Do not touch

- **Haskell core** (`core/astrology-hs/**`) — out of scope. Это infrastructure задача, не engine.
- **`packages/contracts/*.schema.json`**, **`packages/rulesets/`**, **`packages/test-fixtures/`** — не трогать.
- **Другие разделы PDF** — Натальная карта, Солярная карта, Прогрессии, Дирекции, Итоги — не трогать.
- **Существующие helpers `transit_themes.py`, `synthesis_themes.py`, `direction_themes.py`, `house_pair_themes.py`, `wheel.py`, `wheel_glyphs.py`** — не трогать (presentation работа — Phase 3+).
- **`apps/web-react/`** — out of scope.
- **`expected.json` fixtures** — категорически не перезаписывать. Запрет § 7 архитектурного документа.
- **Decision по merge `claude/dreamy-moore-46f5eb` → main** — Worker НЕ решает молча. Worker готовит chassis (canonical render path + provenance), фиксирует в HANDOFF текущий drift (main vs worktree), формулирует **рекомендацию** для TL/пользователя (merge / cherry-pick конкретных коммитов / discard) с обоснованием. **Решение принимает пользователь** через TL. Worker не делает `git merge`, `git cherry-pick`, `git push` в main без явного go.

## Acceptance

### Render provenance — minimum data

- [ ] Каждый запуск canonical render script производит `<output>.pdf` + `<output>.provenance.json` (sidecar).
- [ ] Sidecar JSON содержит минимум:
  - `git_sha` (short + full);
  - `repo_root_path` (абсолютный путь — main или worktree, явно различимо);
  - `worktree_branch` (если worktree);
  - `render_script_path`;
  - `source_facts_path` (путь до `expected.json` или `solar-facts-sample.json`);
  - `source_facts_hash` (sha256 содержимого);
  - `input_fixture_path` (путь до `input.json` если recompute mode);
  - `input_fixture_hash` (sha256 если применимо);
  - `mode`: `"fixture-render"` (без recompute) или `"recomputed"` (запускался cabal CLI);
  - `core_cli_path` (если recomputed mode);
  - `core_cli_sha` или version string (если recomputed mode);
  - `timestamp_utc` (ISO 8601).

### Canonical render path

- [ ] Документирован один canonical entry point для Натальи (`services/api-python/scripts/render_natalya.py` или аналог) с явным README/docstring: «как запустить», «куда сохранит PDF», «куда сохранит provenance», «какие переменные окружения / args принимает (например `--mode=fixture-render` vs `--mode=recompute`)».
- [ ] Все остальные render-вызовы Натальи (test harness, ad hoc bash) либо переписаны на этот entry point, либо удалены.
- [ ] `git grep` по продуктовому repo не находит alternative render harness scripts вне documented canonical path.

### Worktree decision

- [ ] Worker в HANDOFF фиксирует текущее состояние drift между `/Users/ilya/Projects/astro` (main) и `/Users/ilya/Projects/astro/.claude/worktrees/dreamy-moore-46f5eb`: список коммитов на worktree поверх main, список расходящихся файлов, статус backup remote.
- [ ] Worker даёт **рекомендацию** для TL/пользователя: merge / cherry-pick / discard, с конкретными аргументами. Не выполняет.
- [ ] Решение по worktree остаётся за пользователем — Worker не делает git merge/push в main.

### Provenance verifiability

- [ ] По произведённому PDF + sidecar JSON можно однозначно восстановить:
  - какой repo/worktree был использован;
  - какой git SHA;
  - какие facts (path + hash);
  - был ли recompute или просто render;
  - какой render script использовался.
- [ ] Самопроверка Worker'а: смоделировать ситуацию «есть только PDF + sidecar, нет доступа к этой сессии — можно ли восстановить SoT?». Если да — провенанс достаточен.

### Tests + clean state

- [ ] `cd services/api-python && .venv/bin/pytest` — green (новые smoke-tests на provenance.py добавлены; existing 85+ остаются зелёные).
- [ ] `git status --short` чисто **для intended product changes** перед commit (Correction 008). **Pre-existing untracked `.claude/worktrees/` в `/Users/ilya/Projects/astro` разрешён** — Worker НЕ трогает worktree directory в рамках этого TASK'а и явно отмечает её наличие в HANDOFF (это известный артефакт от предыдущих сессий, не часть этого commit'а).
- [ ] Один commit (или ≤2 при чистой границе: `provenance.py + tests` отдельно от `canonical render script + builder integration`). 2 commit-варианта Worker обосновывает в HANDOFF.
- [ ] Push на backup, parity verified.

### Process

- [ ] Worker subagent — отдельная Agent-сессия (Mode normal Tier C, Worker рекомендуется для качества; inline не подходит — задача затрагивает несколько файлов и introducing new module).
- [ ] HANDOFF содержит: что сделано (per-file), provenance shape, рекомендация по worktree, path к примеру PDF + sidecar для верификации, ссылку на architecture document как SoT.

## Context

**Mode normal + Tier C** (infrastructure foundation работа). Worker subagent. Reviewer subagent **необязателен** per Tier C матрица — TL делает inline visual check артефактов после Worker'а.

**Baseline:** `2e4c394` (Tier A engine финальный) + presentation commits на worktree `claude/dreamy-moore-46f5eb` (последний `6894743`). Math engine стабилен, tests green.

**Architecture SoT:** `project-overlays/astro/ARCHITECTURE/transit-section-program-2026-05-13.md`.
- §1 для контекста gate.
- §3 root cause #1, #5 — обоснование задачи.
- §4.5 «Render provenance» — минимальный набор metadata.
- §5 Phase 1 — formal definition.
- §6 «Render provenance» assertions — acceptance criteria.
- §7 запреты — особенно «Не держать одновременно main и worktree как равноправные источники PDF» и «Не открывать Worker subagents на задачи Phase 3-7, пока Phase 1 и Phase 2 не закрыты».
- §8 TASK 1 — formal TASK spec (зеркальная с настоящей).

**После закрытия этого TASK'а:** TL открывает TASK 2 (`Hard acceptance assertions for Natalya transit section`). Phase 2.

**Worker НЕ открывает следующие TASK'и (Phase 3-7) — это TL обязанность.**

**Worker НЕ решает merge/discard worktree** — только готовит chassis и рекомендацию.

**Каждый последующий PDF в этой программе** должен генериться через canonical render path с provenance — иначе он не принимается как evidence для acceptance assertions.
