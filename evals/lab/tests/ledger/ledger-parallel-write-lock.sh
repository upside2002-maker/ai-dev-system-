#!/usr/bin/env bash
# PASS (анти-гонка, D-20260613-006): N параллельных писателей бьют в ОДИН реестр
# разом (голос+телефон+чаты пишут вместе). Под файловым замком (fcntl.flock в
# ledger_lock()) выдача id и дозапись сериализуются: все id уникальны, ни одна
# строка не потеряна, `aida check` чистый. БЕЗ замка тот же прогон ловил бы
# дубли id (два процесса читают один max → +1 → один id) и/или рваные строки.
#
# Операция идёт против ВРЕМЕННОГО каталога (AIDA_LEDGER_DIR) — живой ledger/ не
# задет. Драйвер писателей — отдельный python-файл (stdlib): запускает скопом
# subprocess'ы ЖИВОГО scripts/aida, ждёт всех, затем читает файлы реестра и
# проверяет уникальность id, сохранность строк и человекочитаемый формат id.
# (Heredoc внутри $() ненадёжен на bash 3.2 — потому драйвер вынесен в файл.)
set -uo pipefail
# shellcheck source=evals/lab/lib/harness.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/harness.sh"
echo "TEST ledger-parallel-write-lock PASS N писателей разом -> уникальные id, без потерь"

if ! has_python3; then echo "python3 недоступен"; exit 77; fi

LED="$(make_tmp_ledger)"
DRIVER="$(mktemp -t aida_parallel_driver.XXXXXX.py)"
trap 'rm -rf "$LED"; rm -f "$DRIVER"' EXIT

# Параметры нагрузки: WRITERS процессов, по PER_WRITER записей каждый (факт+inbox
# чередуя). Чем больше коротких вызовов вперехлёст за один день — тем шире окно
# гонки на max-id. >=5 писателей по требованию задачи; берём с запасом.
WRITERS=8
PER_WRITER=6

cat > "$DRIVER" <<'PYEOF'
import json
import os
import re
import subprocess
import sys

ledger_dir = os.environ["AIDA_LEDGER_DIR"]
repo_root = os.environ["REPO_ROOT"]
writers = int(os.environ["WRITERS"])
per_writer = int(os.environ["PER_WRITER"])
aida = os.path.join(repo_root, "scripts", "aida")

env = dict(os.environ)
env["AIDA_LEDGER_DIR"] = ledger_dir


def writer_cmds(w):
    """Команды одного писателя: чередуем факт/inbox — оба пути генерируют id."""
    cmds = []
    for i in range(per_writer):
        if i % 2 == 0:
            cmds.append([
                "bash", aida, "fact",
                "Параллельный факт w{} i{}.".format(w, i),
                "--scope", "system",
                "--source-kind", "file", "--source-ref", "lab/parallel",
            ])
        else:
            cmds.append([
                "bash", aida, "inbox",
                "Параллельная заметка w{} i{}.".format(w, i),
            ])
    return cmds


# Все команды от всех писателей запускаются скопом (Popen без ожидания), затем
# communicate() на каждый. Процессы стартуют до того, как первый дошёл до append,
# — реальная конкуренция N>=5 писателей за файловый замок.
all_cmds = []
for w in range(writers):
    all_cmds.extend(writer_cmds(w))

procs = [subprocess.Popen(cmd, env=env,
                          stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
         for cmd in all_cmds]

fail = False
for p in procs:
    _, err = p.communicate()
    if p.returncode != 0:
        fail = True
        sys.stderr.write("писатель упал rc={}: {}\n".format(
            p.returncode, err.decode("utf-8", "replace")[:200]))

expected_facts = sum(1 for w in range(writers) for i in range(per_writer) if i % 2 == 0)
expected_inbox = sum(1 for w in range(writers) for i in range(per_writer) if i % 2 == 1)


def read_ids(basename):
    path = os.path.join(ledger_dir, basename)
    ids, nlines = [], 0
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as fh:
            for line in fh:
                if not line.strip():
                    continue
                nlines += 1
                rec = json.loads(line)  # рваная строка (потеря/смесь) — упадёт тут
                ids.append(rec["id"])
    return ids, nlines


fact_ids, fact_lines = read_ids("facts.jsonl")
inbox_ids, inbox_lines = read_ids("inbox.jsonl")

problems = []
if fail:
    problems.append("PROBLEM: хотя бы один писатель завершился с ошибкой")

# 1) Ни одна строка не потеряна: строк ровно столько, сколько писали.
if fact_lines != expected_facts:
    problems.append("PROBLEM: фактов-строк {} вместо {}".format(fact_lines, expected_facts))
if inbox_lines != expected_inbox:
    problems.append("PROBLEM: inbox-строк {} вместо {}".format(inbox_lines, expected_inbox))

# 2) Все id уникальны внутри своего файла (главный признак гонки — дубль id).
if len(set(fact_ids)) != len(fact_ids):
    dups = sorted({x for x in fact_ids if fact_ids.count(x) > 1})
    problems.append("PROBLEM: дубли id в facts: {}".format(dups))
if len(set(inbox_ids)) != len(inbox_ids):
    dups = sorted({x for x in inbox_ids if inbox_ids.count(x) > 1})
    problems.append("PROBLEM: дубли id в inbox: {}".format(dups))

# 3) id остались человекочитаемыми (формат X-YYYYMMDD-NNN, НЕ UUID).
fmt = re.compile(r"^[FI]-[0-9]{8}-[0-9]{3}$")
bad = [x for x in (fact_ids + inbox_ids) if not fmt.match(x)]
if bad:
    problems.append("PROBLEM: id не формата X-YYYYMMDD-NNN: {}".format(bad[:5]))

if not problems:
    print("WRITERS_OK facts={} inbox={} unique=yes".format(fact_lines, inbox_lines))
else:
    for pr in problems:
        print(pr)
PYEOF

OUT="$(AIDA_LEDGER_DIR="$LED" REPO_ROOT="$REPO_ROOT" \
       WRITERS="$WRITERS" PER_WRITER="$PER_WRITER" \
       python3 "$DRIVER" 2>&1)"; PYRC=$?

# `aida check` против того же каталога — реестр обязан быть валиден.
CHECK_OUT="$(run_aida_check "$LED")"; CHECK_RC=$?

rc=0
if ! assert_exit 0 "$PYRC"; then
  echo "    python-прогон писателей упал; вывод:"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  rc=1
fi
# Признак успеха: маркер WRITERS_OK и НИ ОДНОГО PROBLEM в выводе.
assert_out_has "WRITERS_OK" "$OUT"   || rc=1
assert_out_lacks "PROBLEM" "$OUT"    || rc=1
# check чистый.
if ! assert_exit 0 "$CHECK_RC"; then echo "    aida check rc=$CHECK_RC"; rc=1; fi
assert_out_has "реестр валиден" "$CHECK_OUT" || rc=1

exit "$rc"
