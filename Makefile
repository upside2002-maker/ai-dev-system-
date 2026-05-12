.PHONY: check check-structure check-sitka-overlay check-astro-overlay status context submit-task accept-handoff accept-task reject-task new-task new-handoff take-shift release-shift

check: check-structure check-sitka-overlay check-astro-overlay

check-structure:
	bash scripts/check-system-structure.sh

check-sitka-overlay:
	bash scripts/check-overlay-consistency.sh sitka-office

# Astro overlay currently at maturity=pre-phase0 — only README required.
# When astro completes Phase 0 (T-F.4 per its README), bump
# project-overlays/astro/.overlay-maturity to 'active' and the same script
# will start enforcing CURRENT_STATE / KNOWN_ISSUES / NEXT_ACTIONS /
# PROJECT_MAP + snapshot match automatically.
check-astro-overlay:
	bash scripts/check-overlay-consistency.sh astro

# Mechanical view of operational state (active TASKs, open HANDOFFs, drift).
# Informational only — does not fail on drift. Use `make check` for invariants.
# Override project: make status SLUG=astro
SLUG ?= sitka-office
status:
	@bash scripts/status.sh $(SLUG)

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
