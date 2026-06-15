#!/usr/bin/env bash
# CONTRACT (жёсткое условие Owner): НЕТ возврата к парсингу свободного текста и
# НЕТ модели-судьи. Структурно по исходнику диспетчера:
#  (а) вход — JSON-конверт (json.loads на stdin/файле), а не сырой текст модели;
#  (б) поле text НЕ интерпретируется как сырьё классификации — диспетчер его лишь
#      переносит наружу (render_outward), не разбирает на «факт/совет/…»;
#  (в) нет вызова внешней модели/LLM как судьи (нет http/openai/anthropic/llm/
#      classify речи) — вердикт выносит влитой КОД против trusted sources.
# Грубый сторож свободного текста (ОТКЛОНЁН ранее) здесь НЕ воскрешён.
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST claim-14-no-freetext-parser-contract CONTRACT нет парсера речи / нет модели-судьи"

SRC="${REPO_ROOT}/scripts/aida_claim.py"
rc=0
assert_file_exists "$SRC" || { exit 1; }

# (в) нет модели-судьи: никаких сетевых/LLM вызовов в диспетчере.
for bad in "import requests" "urllib.request" "http://" "https://" \
           "openai" "anthropic" "claude" "llm" "model_judge" "ask_model"; do
  if grep -qi "$bad" "$SRC"; then
    echo "    запрещённый признак модели-судьи/сети в диспетчере: $bad"; rc=1
  fi
done

# (а)+(б) нет авто-классификации свободного текста: диспетчер не разбирает text
# регулярками/ключевыми словами. Грубо: нет re.search/re.match по text, нет
# словесных эвристик «если в тексте слово ...». Проверяем отсутствие импорта re
# и отсутствие чтения claim["text"] как условия маршрута.
if grep -qE "^import re$|^import re " "$SRC"; then
  echo "    диспетчер импортирует re — риск парсера речи"; rc=1
fi
# Маршрут выбирается по claim['kind'], НЕ по тексту: убедимся, что ROUTES
# индексируется kind, а text встречается только в переносе наружу/в inner.
if ! grep -q "ROUTES\[claim\[.kind.\]\]" "$SRC"; then
  echo "    маршрут не по kind — контракт нарушен"; rc=1
fi

# Поведенчески: один и тот же текст с РАЗНЫМ kind даёт РАЗНЫЙ маршрут — значит
# решает kind, а не текст (текст одинаков, исход разный).
LED="$(make_tmp_ledger)"; ERRF="$(mktemp)"; trap 'rm -rf "$LED" "$ERRF"' EXIT; rm -f "$ERRF"
SAME="любой свободный текст, одинаковый в обеих заявках"
A="$(printf '{"kind":"fact_claim","text":"%s"}' "$SAME" | run_aida_claim eval "$LED" "$ERRF")"
B="$(printf '{"kind":"done_report","text":"%s","mode":"world"}' "$SAME" | run_aida_claim eval "$LED" "$ERRF")"
# fact_claim без источника → unverified; done_report mode=world (пусто) → passed.
assert_out_has "UNVERIFIED_NO_SOURCE" "$A" || rc=1
assert_out_has "OK_WORLD_RECONCILED" "$B"  || rc=1
exit "$rc"
