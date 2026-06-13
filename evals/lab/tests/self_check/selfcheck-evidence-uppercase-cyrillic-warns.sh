#!/usr/bin/env bash
# RED* (И-5, лазейка регистра): ПОЛНОСТЬЮ-ЗАГЛАВНАЯ кириллица рядом с датой —
# 'ВЫКАТ НА ПРОД 2026-06-10' — обязана триггерить правило evidence. До фикса
# §A `grep -i` в пустой локали (env -i LC_ALL=C) не складывал регистр кириллицы
# и заглавный «ВЫКАТ» проскальзывал мимо ключа «выкат» — заявка о выкате без
# хеша молча. Чинено locale-независимым python3 .lower(). Прогон под C-локалью.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-uppercase-cyrillic-warns RED* ЗАГЛАВНЫЙ ВЫКАТ -> WARN"

WORK="$(make_selfcheck_repo)"
trap 'rm -rf "$WORK"' EXIT

F="$(write_handoff_fixture "$WORK" \
  'ВЫКАТ НА ПРОД 2026-06-10')"

OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?

rc=0
assert_exit 0 "$RC"                                                || rc=1
assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || rc=1
exit "$rc"
