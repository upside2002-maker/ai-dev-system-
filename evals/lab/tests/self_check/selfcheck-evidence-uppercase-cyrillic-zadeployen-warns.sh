#!/usr/bin/env bash
# RED* (§A, регистр): другие git-слова ПОЛНОСТЬЮ ЗАГЛАВНЫМИ рядом с датой —
# 'ЗАДЕПЛОЕН 2026-06-10', 'СМЕРЖЕН 2026-06-10' — тоже триггерят evidence.
# Покрывает класс лазейки сверх одного слова: фикс §A складывает регистр у
# любого ключа, не только у «выкат». Прогон под env -i LC_ALL=C.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST selfcheck-evidence-uppercase-cyrillic-zadeployen-warns RED* ЗАГЛАВНЫЕ ЗАДЕПЛОЕН/СМЕРЖЕН -> WARN"

rc=0

for WORD in 'ЗАДЕПЛОЕН' 'СМЕРЖЕН'; do
  WORK="$(make_selfcheck_repo)"
  F="$(write_handoff_fixture "$WORK" "${WORD} 2026-06-10")"
  OUT="$(env -i LC_ALL=C LANG=C PATH="$PATH" bash "$WORK/scripts/self-check-handoff.sh" "$F" 2>&1)"; RC=$?
  assert_exit 0 "$RC"                                                || { echo "    (слово: ${WORD})"; rc=1; }
  assert_out_has "упоминание PR/даты без git short hash рядом" "$OUT" || { echo "    (слово: ${WORD})"; rc=1; }
  rm -rf "$WORK"
done

exit "$rc"
