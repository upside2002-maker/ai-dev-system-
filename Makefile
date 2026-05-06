.PHONY: check check-structure check-sitka-overlay check-astro-overlay status accept-handoff accept-task reject-task new-task new-handoff

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
# Usage: make new-task SLUG=sitka-office TASK_SLUG=dm7-d-widget-copy LAYER=web TIER=C
#   LAYER ∈ {docs, core, services, web, infra, mixed}
#   TIER  ∈ {A, B, C}
new-task:
	@bash scripts/new-task.sh "$(SLUG)" "$(TASK_SLUG)" "$(LAYER)" "$(TIER)"

# Scaffold a new HANDOFF file linked to a TASK.
# Usage: make new-handoff SLUG=sitka-office TASK=path/to/<file>.md FROM=worker TO=tl
#   FROM/TO ∈ {tl, worker, reviewer, ba, admin}
#   defaults: FROM=worker, TO=tl
new-handoff:
	@bash scripts/new-handoff.sh "$(SLUG)" "$(TASK)" "$(FROM)" "$(TO)"
