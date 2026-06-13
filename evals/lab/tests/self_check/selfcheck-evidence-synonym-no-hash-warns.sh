#!/usr/bin/env bash
# RED* (И-5): синонимы git-работы вне прежнего allowlist (релиз/опубликовано/
# отгружено/слили/выложено/внедрено/интегрировано) тоже должны триггерить
# правило evidence. До фикса 'Релиз состоялся 2026-06-10' проскальзывал молча —
# заявка о выкате без хеша. Allowlist расширен этими синонимами.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-synonym-no-hash-warns RED* синоним выката -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'Релиз состоялся 2026-06-10 без хеша.')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                || rc=1
assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
exit "$rc"
