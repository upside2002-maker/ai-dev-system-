.PHONY: check check-structure check-sitka-overlay check-astro-overlay ledger-check lab status snapshot context submit-task accept-handoff accept-task reject-task new-task new-handoff take-shift release-shift approve-critical self-check-handoff new-audit-task install-hooks

check: check-structure check-sitka-overlay check-astro-overlay ledger-check lab

check-structure:
	bash scripts/check-system-structure.sh

check-sitka-overlay:
	bash scripts/check-overlay-consistency.sh sitka-office
	bash scripts/check-status-hygiene.sh sitka-office

# Astro overlay currently at maturity=pre-phase0 — only README required.
# When astro completes Phase 0 (T-F.4 per its README), bump
# project-overlays/astro/.overlay-maturity to 'active' and the same script
# will start enforcing CURRENT_STATE / KNOWN_ISSUES / NEXT_ACTIONS /
# PROJECT_MAP + snapshot match automatically.
check-astro-overlay:
	bash scripts/check-overlay-consistency.sh astro
	bash scripts/check-status-hygiene.sh astro

# Валидатор реестра фактов/решений (ledger/*.jsonl): каждая строка — валидный
# JSON, обязательные поля и enum'ы на месте, id уникален в файле, у каждого
# факта есть источник (И-5), ссылки supersedes/origin/a-b-working/promoted_to
# существуют, working противоречия = a|b. Протухшие факты (И-13) — предупреждение
# списком, открытые противоречия — информация; ошибки → exit 1 с номерами строк.
# Пустые/отсутствующие файлы реестра — норма (система только заводится).
ledger-check:
	bash scripts/aida check

# Лаборатория проверок ворот (evals/lab/**): красные тесты доказывают, что
# программные ворота реально блокируют нарушение инварианта; pass-тесты ловят
# ложные срабатывания; контракт-тесты проверяют, что упомянутые в методологии
# пути существуют (нет фантомных ссылок). Все мутирующие тесты работают на
# временных копиях (mktemp -d) — живой репозиторий не трогается.
# Только bash + python3 stdlib + git. Подробности — evals/lab/run.sh.
# Usage: make lab
lab:
	bash evals/lab/run.sh

# Mechanical view of operational state (active TASKs, open HANDOFFs, drift).
# Informational only — does not fail on drift. Use `make check` for invariants.
# Override project: make status SLUG=astro
SLUG ?= sitka-office
status:
	@bash scripts/status.sh $(SLUG)

# Канонический снимок продуктового репо из источника (git): короткий HEAD,
# ветка, дата-время, чистота дерева, последний коммит. Только печать — файлы
# не правит. Замена строкам снимков, написанным по памяти (дрейф состояния).
# Путь к репо — как в check-overlay-consistency.sh ($HOME/Projects/<slug>),
# переопределяется через REPO_PATH. Работает и для maturity=pre-phase0.
# Usage: make snapshot SLUG=sitka-office
#        make snapshot SLUG=astro REPO_PATH=/путь/к/репо
snapshot:
	@bash scripts/snapshot.sh $(SLUG) $(REPO_PATH)

# Compact context pack on stdout: STATUS_RU + dashboard + last 5 commits +
# corrections headings + (active) NEXT_ACTIONS head. Polymorphic by overlay
# `.overlay-maturity` (active vs pre-phase0). First read for new TL session
# instead of crawling reading-order manually. Length cap ~300 lines.
# Usage: make context SLUG=sitka-office
#        make context SLUG=astro
context:
	@bash scripts/context-pack.sh $(SLUG)

# Submit a TASK for review: bump Status: open|in-progress → review.
# Worker (or whichever role finished execution) calls this AFTER writing
# the HANDOFF file and BEFORE TL runs accept-task. Replaces the manual
# "TL edits Status by hand" step that v0.1 smoke surfaced as a gap.
# Usage: make submit-task FILE=project-overlays/sitka-office/TASKS/<file>.md
submit-task:
	@bash scripts/submit-task.sh $(FILE)

# Accept a HANDOFF: bump Status: closed + move to archive/. Atomic, defensive.
# Usage: make accept-handoff FILE=project-overlays/sitka-office/HANDOFFS/<file>.md
accept-handoff:
	@bash scripts/accept-handoff.sh $(FILE)

# Accept a TASK: bump Status: done + move to archive/. Atomic, defensive.
# Usage: make accept-task FILE=project-overlays/sitka-office/TASKS/<file>.md
# For rejected tasks — use `make reject-task`, not this helper.
accept-task:
	@bash scripts/accept-task.sh $(FILE)

# Reject a TASK: bump Status: rejected + insert Rejected reason + move to archive/.
# Usage: make reject-task FILE=project-overlays/sitka-office/TASKS/<file>.md REASON="…"
# REASON is mandatory non-empty single-line.
reject-task:
	@bash scripts/reject-task.sh "$(FILE)" "$(REASON)"

# Scaffold a new TASK file from skeleton with validated header.
# Usage: make new-task SLUG=sitka-office TASK_SLUG=dm7-d-widget-copy LAYER=web TIER=C MODE=light
#   LAYER ∈ {docs, core, services, web, infra, mixed}
#   TIER  ∈ {A, B, C}
#   MODE  ∈ {light, normal, strict, preview}    — см. policies/MODES.md
new-task:
	@bash scripts/new-task.sh "$(SLUG)" "$(TASK_SLUG)" "$(LAYER)" "$(TIER)" "$(MODE)"

# Scaffold a new HANDOFF file linked to a TASK.
# Usage: make new-handoff SLUG=sitka-office TASK=path/to/<file>.md FROM=worker TO=tl
#   FROM/TO ∈ {tl, worker, reviewer, ba, admin}
#   defaults: FROM=worker, TO=tl
new-handoff:
	@bash scripts/new-handoff.sh "$(SLUG)" "$(TASK)" "$(FROM)" "$(TO)"

# Take a project shift lock: register caller as the active project lead for
# the given overlay. Pulls TL_SHIFT.md from backup first, refuses if shift
# is held by another user with non-expired Expires, writes new state, pushes.
# Default HOURS=8 (typical shift length). Полное описание — policies/SHIFTS.md.
# Usage: make take-shift SLUG=sitka-office SCOPE="разбор передачи"
#        make take-shift SLUG=sitka-office SCOPE="..." HOURS=4
#
# Экстренное прерывание (только для владельца с can_override: yes в
# policies/USERS.md). REASON обязательное — короткое объяснение, попадает
# в TL_SHIFT.md в раздел ## Override history как аудит-след.
# Usage: make take-shift SLUG=sitka-office SCOPE="hot fix" OVERRIDE=yes REASON="..."
take-shift:
	@OVERRIDE="$(OVERRIDE)" REASON="$(REASON)" bash scripts/take-shift.sh "$(SLUG)" "$(SCOPE)" "$(HOURS)"

# Release a project shift lock: caller must be current Holder, NOTES must be
# non-empty. Appends entry to ## Notes section, resets Holder fields, pushes.
# Usage: make release-shift SLUG=sitka-office NOTES="что сделано за смену"
release-shift:
	@bash scripts/release-shift.sh "$(SLUG)" "$(NOTES)"

# Sign a TASK as critical-approved by the owner. Required when the task
# touches paths from policies/CRITICAL_PATHS.md and Created by does not
# have can_approve_critical permission. Updates the `- Critical approved by:`
# line in TASK header to caller's email, commits, pushes to backup.
# Usage: make approve-critical FILE=project-overlays/sitka-office/TASKS/<file>.md
approve-critical:
	@bash scripts/approve-critical.sh "$(FILE)"

# Run self-check on a HANDOFF file: required header fields, Product repo
# status, evidence rule (warning), user-facing forbidden words (warning),
# length (warning). Used by submit-task before bumping Status to review;
# also runnable standalone for debugging. Exit 1 = errors (caller blocks).
# Usage: make self-check-handoff FILE=project-overlays/sitka-office/HANDOFFS/<f>.md
self-check-handoff:
	@bash scripts/self-check-handoff.sh "$(FILE)"

# Scaffold a periodic-audit TASK from templates/AUDIT_TASK_TEMPLATE.md.
# Owner-only: caller email must have can_approve_critical: yes in
# policies/USERS.md (same right as override-shift and approve-critical —
# единообразный флаг прав на операции контроля). См. policies/AUDIT.md
# для процедуры сверки.
# Usage: make new-audit-task SLUG=sitka-office
new-audit-task:
	@bash scripts/new-audit-task.sh "$(SLUG)"

# Установить git-хуки репозитория. Запустить один раз на клон.
# pre-push гоняет `make check` и не даёт отправить код при рассинхроне состояния
# (снимок CURRENT_STATE.md разъехался с реальным HEAD продукта) — замок на дрейф.
# Обойти осознанно: git push --no-verify. См. .githooks/pre-push.
install-hooks:
	@git config core.hooksPath .githooks
	@chmod +x .githooks/* 2>/dev/null || true
	@echo "хуки установлены: core.hooksPath=.githooks (pre-push гоняет make check на каждой отправке)"
