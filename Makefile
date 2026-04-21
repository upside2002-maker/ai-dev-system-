.PHONY: check check-structure check-sitka-overlay

check: check-structure check-sitka-overlay

check-structure:
	bash scripts/check-system-structure.sh

check-sitka-overlay:
	bash scripts/check-overlay-consistency.sh sitka-office
