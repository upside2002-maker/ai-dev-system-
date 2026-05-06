# TASK: smoke-subagent-orchestration

- Status: done
- Date: 2026-05-04
- Project: sitka-office
- Layer: docs
- Risk tier: C
- Owner: Project Tech Lead
- Worker model: Claude Code (sitka-worker subagent)

## Problem

End-to-end smoke-test текущей Claude Code orchestration для проекта sitka-office. Цель — убедиться что цепочка `TL → /sitka-worker → subagent → HANDOFF → TL accept` работает на изолированном безопасном сценарии до того как пускать систему на real production work. Production code не трогается; тест на read+write одного нового docs-файла.

## Scope

В скоупе:
- Worker запускается через `/sitka-worker <этот task path>`
- Worker создаёт **новый** markdown-файл по пути из секции Files
- Worker создаёт HANDOFF через `make -C /Users/ilya/Projects/ai-dev-system new-handoff SLUG=sitka-office TASK=<этот task path> FROM=worker TO=tl`

Вне скоупа:
- Любой production code (sitka-core/, sitka-services/, sitka-web/)
- Любой существующий файл (worker создаёт только новый)
- Любые тесты / build / migrations
- OPERATING.md / CURRENT_STATE.md / KNOWN_ISSUES.md / NEXT_ACTIONS.md (TL обновит сам после accept)

## Files

- new:    `/Users/ilya/Projects/ai-dev-system/project-overlays/sitka-office/_smoke_subagent_proof.md`
- modify: (none)
- delete: (none)

## Do not touch

- `/Users/ilya/Projects/sitka-office/sitka-core/**`
- `/Users/ilya/Projects/sitka-office/sitka-services/**`
- `/Users/ilya/Projects/sitka-office/sitka-web/**`
- `/Users/ilya/Projects/sitka-office/migrations/**`
- Любой файл вне `Files` секции выше
- Любые `.claude/agents/` или `.claude/commands/` файлы
- Любые scripts/ или Makefile
- OPERATING.md (TL обновит руками после accept TASK + HANDOFF)

## Acceptance criteria

- [ ] Worker создал ровно один новый файл по пути `project-overlays/sitka-office/_smoke_subagent_proof.md` (не где-то ещё)
- [ ] Файл содержит как минимум 3 строки: заголовок `# Smoke test proof`, дата (`Date: 2026-05-04` или текущая), и одно предложение "Subagent delegation works."
- [ ] Никаких других файлов не изменено и не создано (verify через `git status` в repo `/Users/ilya/Projects/ai-dev-system/`)
- [ ] Worker создал HANDOFF через `make new-handoff` (не вручную копируя template)
- [ ] HANDOFF содержит ссылку на этот TASK + краткое Done

## Test commands

```bash
# В repo /Users/ilya/Projects/ai-dev-system:
cat project-overlays/sitka-office/_smoke_subagent_proof.md   # должен показать содержимое
git status --short                                            # должен показать только два untracked: _smoke_subagent_proof.md и новый HANDOFF
```

(Никакие cabal/pytest/npm не запускаются — это docs-only.)

## Handoff requirements

В HANDOFF Worker фиксирует:
- **Done:** путь к созданному файлу + одной строкой что записал
- **Artifacts:** branch (если делал отдельную; для docs Tier C можно работать прямо в working dir), commit SHA если коммитил
- **Conflicts/risks:** None expected — read+write одного нового файла
- **Next step:** TL читает HANDOFF, проверяет файл, запускает `make accept-task` + `make accept-handoff`, потом удаляет `_smoke_subagent_proof.md` (smoke fixture не нужен после теста)

