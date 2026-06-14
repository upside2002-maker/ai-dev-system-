#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ядро реестра фактов и решений Aida (шаг 2, v0.1).

Вся работа с JSONL живёт здесь; scripts/aida — тонкая bash-обёртка. Только
стандартная библиотека (никаких pip/jq).

Воплощённые инварианты (policies/AIDA_INVARIANTS.md):
  И-4  карантин — inbox принимает сырое свободно; в facts только через aida.
  И-5  источник — факт без source.kind+source.ref не пишется и не проходит check.
  И-6  типы/оси — у каждой записи тип (файл), статус, источник (у фактов), область.
  И-13 срок годности — поле expires; просроченное метится предупреждением.
  И-14 дописываемость — НИ ОДНА существующая строка не правится и не удаляется.
       Любое изменение состояния = НОВАЯ строка. Единственный путь записи —
       append (open mode 'a'); read-modify-write над строками отсутствует как класс.

Кодировка: всё в UTF-8, json.dump(..., ensure_ascii=False) — русский в значениях.
"""

import argparse
import contextlib
import datetime
import fcntl
import json
import os
import re
import sys

# --- размещение реестра ----------------------------------------------------
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LEDGER_DIR = os.environ.get("AIDA_LEDGER_DIR", os.path.join(ROOT, "ledger"))

FILES = {
    "inbox": "inbox.jsonl",
    "facts": "facts.jsonl",
    "decisions": "decisions.jsonl",
    "contradictions": "contradictions.jsonl",
    # Ворота дел v0.1 (второй столб строгого ядра, D-20260614-006): журнал
    # ДЕЙСТВИЙ. Строки одного A-id: requested → executed|failed. Пишется ТОЛЬКО
    # через защищённый адаптер (cmd_action) теми же примитивами журнала
    # (allocate_and_append/append_record/ledger_lock) — не свой движок.
    "actions": "actions.jsonl",
}

# Префикс id по файлу.
PREFIX = {
    "inbox": "I",
    "facts": "F",
    "decisions": "D",
    "contradictions": "C",
    "actions": "A",
}

# --- ворота дел: наблюдаемая зона и белый список адаптеров записи -----------
# Наблюдаемая зона — каталог МИРА, который сверка-с-миром (run_check) сравнивает
# с журналом действий. Маркеры кладёт сюда только адаптер marker.write. Любой
# маркер тут БЕЗ соответствующей executed-заявки = ИНЦИДЕНТ (ловля «сказал А —
# сделал Б» и прямой записи мимо ядра). Лежит ВНУТРИ ledger/, но это не *.jsonl —
# валидатор реестра как реестр его не читает, только сверка-с-миром.
OBSERVED_SUBDIR = "observed"
# Белый список адаптеров записи (анти-ведро): модель ВЫБИРАЕТ адаптер из набора,
# произвольную команду не подаёт. v0.1 — один реальный адаптер.
ACTION_KINDS = {"marker.write"}
ACTION_PHASES = {"requested", "executed", "failed"}
# Префиксы критпутей: цель в этих зонах защищённому адаптеру записи ЗАПРЕЩЕНА
# (денежный/системный контур — поздний слой; v0.1 пишет только в наблюдаемую
# зону). Совпадает по духу с .githooks/commit-msg CRITICAL_PREFIXES.
ACTION_CRITICAL_PREFIXES = ("scripts/", "schemas/", "policies/", "templates/",
                            "corrections/")

# --- словари допустимых значений (enum дословно из ТЗ §3) -------------------
SCOPES = {"system", "global", "sitka-office", "astro", "aida-voice", "crypto"}
FACT_STATUSES = {"verified", "accepted", "stale", "superseded"}
CONFIDENCES = {"low", "medium", "high"}
SOURCE_KINDS = {"command", "file", "git", "url", "human", "handoff"}
DECISION_BY = {"owner", "admin", "tl-sitka", "tl-astro", "tl-crypto"}
DECISION_STATUSES = {"active", "superseded", "revoked"}
INBOX_STATUSES = {"raw", "promoted", "dropped"}
CONTRADICTION_STATUSES = {"open", "resolved"}

ID_RE = {
    "facts": re.compile(r"^F-[0-9]{8}-[0-9]{3}$"),
    "decisions": re.compile(r"^D-[0-9]{8}-[0-9]{3}$"),
    "contradictions": re.compile(r"^C-[0-9]{8}-[0-9]{3}$"),
    "inbox": re.compile(r"^I-[0-9]{8}-[0-9]{3}$"),
    "actions": re.compile(r"^A-[0-9]{8}-[0-9]{3}$"),
}
DATE_RE = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
EXPIRES_RE = re.compile(r"^(?:[0-9]{4}-[0-9]{2}-[0-9]{2}|event:.+)$")
# valid_until (структурная память ядра правды, D-20260614-003) — тот же формат,
# что expires (И-13): дата | event:… | null. Переиспользуем EXPIRES_RE.
VALID_UNTIL_RE = EXPIRES_RE
ANY_ID_RE = re.compile(r"^[FDIC]-[0-9]{8}-[0-9]{3}$")


class AidaError(Exception):
    """Понятный отказ для оператора (печатается без трейсбэка)."""


# --- низкоуровневое чтение/запись ------------------------------------------
def path_for(name):
    return os.path.join(LEDGER_DIR, FILES[name])


def read_records(name):
    """Читать файл реестра. Отсутствующий/пустой файл — пустой список (норма)."""
    p = path_for(name)
    records = []
    if not os.path.exists(p):
        return records
    with open(p, "r", encoding="utf-8") as fh:
        for lineno, line in enumerate(fh, 1):
            if not line.strip():
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError as exc:
                # При обычной работе (генерация id и т.п.) битая строка — повод
                # упасть понятно, а не молча; check разберёт её подробнее.
                raise AidaError(
                    "файл реестра {} повреждён: строка {} — не JSON ({}).\n"
                    "Как исправить: запусти `aida check` — он покажет все битые "
                    "строки; почини их в git-истории (строки только дописываются, "
                    "И-14), повреждённую не удаляй, а исправь её содержимое.".format(
                        FILES[name], lineno, exc.msg
                    )
                )
    return records


def append_record(name, record):
    """ЕДИНСТВЕННЫЙ путь записи (И-14): дописать строку, ничего не трогая.

    Открытие в режиме 'a' физически не даёт переписать существующие строки.

    ВНИМАНИЕ про гонку: сама по себе эта функция атомарна на уровне одной
    строки, но связка «прочитать max id → +1 → дописать» (next_id+append) —
    НЕТ. Два процесса (голос+телефон+чаты пишут в ОДИН реестр, D-20260613-006)
    могут одновременно прочитать один и тот же max и выдать ОДИН id. Поэтому
    выдача id и дозапись делаются под файловым замком — см. ledger_lock() и
    allocate_and_append(). Прямой вызов append_record (например, дозапись
    inbox-строки со статусом promoted, где id берётся из уже существующей
    записи, а не генерируется) безопасен и под замком не нуждается.
    """
    os.makedirs(LEDGER_DIR, exist_ok=True)
    line = json.dumps(record, ensure_ascii=False, sort_keys=True)
    with open(path_for(name), "a", encoding="utf-8") as fh:
        fh.write(line + "\n")


# --- файловый замок против гонки выдачи id (D-20260613-006) -----------------
# Имя замка на каталог реестра: один писатель за раз по ВСЕМУ реестру. Замок
# общий для всех файлов (facts/decisions/inbox/contradictions) — этого достаточно
# и проще, чем замок на файл; запись редкая, конкуренция за разные файлы не
# критична, а простота важнее. Lock-файл живёт рядом с *.jsonl и сам в реестр
# не входит (не *.jsonl, валидатор его не видит).
LOCK_FILENAME = ".aida.lock"


@contextlib.contextmanager
def ledger_lock():
    """Эксклюзивный файловый замок (fcntl.flock) на весь каталог реестра.

    Сериализует пишущих: пока один держит замок, остальные ждут на flock и
    входят только после release. Замок берётся ДО чтения max id и держится ДО
    конца дозаписи — выдача id и append неделимы, дублей id и потери строк нет.

    Замок освобождается всегда (в т.ч. при исключении): flock снимается при
    закрытии дескриптора, а 'with open(...)' закрывает его на выходе из блока
    по любой причине. Lock-файл не удаляем — гонка на unlink сама по себе
    источник проблем, а пустой служебный файл безвреден.
    """
    os.makedirs(LEDGER_DIR, exist_ok=True)
    lock_path = os.path.join(LEDGER_DIR, LOCK_FILENAME)
    # 'a' — создаёт файл при отсутствии, существующий не трогает (содержимое
    # нам не нужно, важен только дескриптор для flock).
    with open(lock_path, "a", encoding="utf-8") as lock_fh:
        fcntl.flock(lock_fh.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            # Явно снимаем замок до закрытия (close его тоже снял бы, но так
            # намерение видно и окно между release и close минимально).
            fcntl.flock(lock_fh.fileno(), fcntl.LOCK_UN)


def allocate_and_append(name, build_record, day=None):
    """Атомарно выдать id и дозаписать строку ПОД ОДНИМ замком (анти-гонка).

    build_record(rid) -> dict: получает свежевыданный id и возвращает готовую
    запись. Чтение max id, +1 и append идут внутри одного ledger_lock(), поэтому
    параллельные писатели не получат одинаковый id и не затрут строки друг друга.
    Сохраняется человекочитаемый id формата X-YYYYMMDD-NNN (НЕ UUID).

    Возвращает выданный id.
    """
    with ledger_lock():
        rid = next_id(name, day=day)
        record = build_record(rid)
        append_record(name, record)
    return rid


def now_iso():
    return datetime.datetime.now().astimezone().replace(microsecond=0).isoformat()


def today():
    return datetime.date.today().isoformat()


def next_id(name, day=None):
    """Сгенерировать id: префикс + дата + (макс номер за день в файле) + 1."""
    day = day or today()
    daystr = day.replace("-", "")
    prefix = "{}-{}-".format(PREFIX[name], daystr)
    max_n = 0
    for rec in read_records(name):
        rid = rec.get("id", "")
        if isinstance(rid, str) and rid.startswith(prefix):
            try:
                max_n = max(max_n, int(rid[len(prefix):]))
            except ValueError:
                continue
    return "{}{:03d}".format(prefix, max_n + 1)


def find(name, rid):
    """Последняя запись с данным id (или None). Записей с одним id может быть
    несколько (история через supersedes пишет НОВЫЙ id, но статус-записи inbox
    переиспользуют id — берём последнюю как актуальное состояние)."""
    found = None
    for rec in read_records(name):
        if rec.get("id") == rid:
            found = rec
    return found


def is_superseded(name, rid):
    """True, если на этот id уже ссылается чья-то supersedes — значит он не
    «голова» истории и новые переходы от него создали бы развилку (против И-14)."""
    for rec in read_records(name):
        if rec.get("supersedes") == rid:
            return True
    return False


def require(cond, message):
    if not cond:
        raise AidaError(message)


# --- команды записи --------------------------------------------------------
def cmd_inbox(args):
    def build(rid):
        rec = {
            "id": rid,
            "note": args.note,
            "status": "raw",
            "promoted_to": None,
            "recorded_by": args.by,
            "recorded_at": now_iso(),
        }
        if args.context:
            rec["context"] = args.context
        return rec

    rid = allocate_and_append("inbox", build)
    print("OK: в карантин записано {}".format(rid))
    print("  заметка: {}".format(args.note))
    return 0


def _build_source(args):
    # И-5: источник обязателен и осмыслен. Пустой или ПРОБЕЛЬНЫЙ kind/ref —
    # тот же отказ, что и при полном отсутствии флагов: пробелы источником не
    # являются. Сверяем по .strip(), чтобы "   " не обходил проверку.
    kind = args.source_kind.strip() if isinstance(args.source_kind, str) else args.source_kind
    ref = args.source_ref.strip() if isinstance(args.source_ref, str) else args.source_ref
    require(
        kind and ref,
        "факт без источника — не факт (И-5); сырое клади в карантин: "
        "aida inbox \"...\".\n"
        "Как исправить: добавь --source-kind {command|file|git|url|human|handoff} "
        "и --source-ref \"<команда/путь/адрес/кто>\".",
    )
    require(
        kind in SOURCE_KINDS,
        "недопустимый --source-kind '{}'. Допустимо: {}.".format(
            kind, " ".join(sorted(SOURCE_KINDS))
        ),
    )
    source = {"kind": kind, "ref": ref}
    if args.quote and args.quote.strip():
        source["quote"] = args.quote
    return source


def norm_value(value):
    """Каноническая строка значения для МЕХАНИЧЕСКОГО сравнения по key.

    Структурная память сравнивает значения как строки после нормализации, чтобы
    противоречие памяти ловилось одинаково независимо от типа записи (число 200
    и строка "200" — одно значение; True/"true"/"yes" — одно; регистр/пробелы по
    краям не значат). Это детерминированная функция, без модели.
    """
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        # 200 и 200.0 → одна строка; целое печатаем без .0
        if isinstance(value, float) and value.is_integer():
            value = int(value)
        return str(value)
    s = str(value).strip().lower()
    if s in ("true", "yes", "on", "вкл", "да"):
        return "true"
    if s in ("false", "no", "off", "выкл", "нет"):
        return "false"
    return s


def _coerce_value_arg(raw):
    """--value приходит строкой из CLI; приводим к int/float/bool/None, чтобы в
    реестре значение легло осмысленным типом (а не всегда строкой). Сравнение всё
    равно идёт через norm_value, но хранение типизированным — честнее."""
    if raw is None:
        return None
    s = raw.strip()
    low = s.lower()
    if low == "null":
        return None
    if low in ("true", "false"):
        return low == "true"
    # целое/дробное?
    try:
        if re.match(r"^-?[0-9]+$", s):
            return int(s)
        if re.match(r"^-?[0-9]+\.[0-9]+$", s):
            return float(s)
    except ValueError:
        pass
    return s


def _validate_fact_fields(args):
    require(
        args.scope in SCOPES,
        "недопустимый --scope '{}'. Допустимо: {}.".format(
            args.scope, " ".join(sorted(SCOPES))
        ),
    )
    require(
        args.confidence in CONFIDENCES,
        "недопустимый --confidence '{}'. Допустимо: {}.".format(
            args.confidence, " ".join(sorted(CONFIDENCES))
        ),
    )
    if args.expires is not None:
        require(
            EXPIRES_RE.match(args.expires),
            "недопустимый --expires '{}'. Формат: YYYY-MM-DD | event:<описание>.".format(
                args.expires
            ),
        )
    # Структурная память (опционально): key/value/valid_until.
    key = getattr(args, "key", None)
    if key is not None:
        require(
            bool(key.strip()),
            "--key задан, но пустой. Либо непустой машинный ключ, либо вовсе не "
            "указывай (key опционален).",
        )
    valid_until = getattr(args, "valid_until", None)
    if valid_until is not None:
        require(
            VALID_UNTIL_RE.match(valid_until),
            "недопустимый --valid-until '{}'. Формат: YYYY-MM-DD | event:<описание>.".format(
                valid_until
            ),
        )


def _write_fact(args, statement, origin=None):
    _validate_fact_fields(args)
    source = _build_source(args)

    require(
        bool(statement and statement.strip()),
        "у факта пустое утверждение (statement). Для promote укажи "
        "--statement \"одно предложение\", если сырой заметки недостаточно.",
    )

    # Замок берём ДО проверок ссылок (supersedes/origin), чтения max id и
    # дозаписи — весь критический участок записи факта сериализован. Это
    # исключает гонку выдачи id и заодно держит проверки ссылок согласованными
    # с моментом записи.
    with ledger_lock():
        if args.supersedes is not None:
            require(
                find("facts", args.supersedes) is not None,
                "--supersedes {}: такого факта нет в facts.jsonl.\n"
                "Как исправить: проверь id через `aida show facts`.".format(args.supersedes),
            )
        if origin is not None:
            require(
                find("inbox", origin) is not None,
                "--origin {}: такой записи нет в inbox.jsonl.".format(origin),
            )

        rid = next_id("facts")
        rec = {
            "id": rid,
            "statement": statement,
            "scope": args.scope,
            "status": "verified",
            "confidence": args.confidence,
            "source": source,
            "checked_at": args.checked_at or today(),
            "expires": args.expires,  # None — норма (бессрочный)
            "supersedes": args.supersedes,
            "origin": origin,
            "recorded_by": args.by,
            "recorded_at": now_iso(),
        }
        # Структурная память (опционально): добавляем поля ТОЛЬКО когда заданы,
        # чтобы факты без структурного ключа писались как раньше (обратная
        # совместимость — старые строки и новые без key идентичны по форме).
        key = getattr(args, "key", None)
        if key is not None:
            rec["key"] = key.strip()
            rec["value"] = _coerce_value_arg(getattr(args, "value", None))
            rec["valid_until"] = getattr(args, "valid_until", None)
        append_record("facts", rec)
    return rid


def cmd_fact(args):
    rid = _write_fact(args, args.statement, origin=None)
    print("OK: факт записан {} (status: verified)".format(rid))
    print("  утверждение: {}".format(args.statement))
    print("  источник: {} → {}".format(args.source_kind, args.source_ref))
    return 0


def cmd_promote(args):
    inbox_rec = find("inbox", args.inbox_id)
    require(
        inbox_rec is not None,
        "promote {}: такой записи нет в inbox.jsonl.\n"
        "Как исправить: посмотри карантин через `aida show inbox`.".format(args.inbox_id),
    )
    require(
        inbox_rec.get("status") == "raw",
        "promote {}: запись уже в статусе '{}', повторно не продвигается.".format(
            args.inbox_id, inbox_rec.get("status")
        ),
    )
    # 1) пишем факт с origin. Утверждение факта: явный --statement, иначе
    #    сама сырая заметка карантина (note) как отправная формулировка.
    statement = args.statement if getattr(args, "statement", None) else inbox_rec["note"]
    fact_id = _write_fact(args, statement, origin=args.inbox_id)
    # 2) ДОПИСЫВАЕМ inbox-запись со статусом promoted (новой строкой, И-14).
    #    Старую строку не трогаем — это новое состояние того же id.
    promoted = {
        "id": inbox_rec["id"],
        "note": inbox_rec["note"],
        "status": "promoted",
        "promoted_to": fact_id,
        "recorded_by": args.by,
        "recorded_at": now_iso(),
    }
    if "context" in inbox_rec:
        promoted["context"] = inbox_rec["context"]
    append_record("inbox", promoted)
    print("OK: {} продвинут в факт {}".format(args.inbox_id, fact_id))
    print("  inbox-запись дописана статусом promoted (старая строка не тронута)")
    return 0


def _copy_fact_with_status(args, new_status, reason=None):
    """Повышение/пометка факта = НОВАЯ запись-копия со supersedes старого id.

    Замок держим вокруг проверки «голова истории» (is_superseded) + выдачи id +
    дозаписи: иначе два параллельных перехода от одной головы оба прошли бы
    is_superseded и создали бы развилку (против И-14) и/или одинаковый id.
    """
    with ledger_lock():
        src = find("facts", args.fact_id)
        require(
            src is not None,
            "{}: такого факта нет в facts.jsonl.\n"
            "Как исправить: посмотри `aida show facts`.".format(args.fact_id),
        )
        require(
            not is_superseded("facts", args.fact_id),
            "{}: на этот факт уже ссылается более новая запись (он не «голова» "
            "истории). Переходи от актуальной версии — найди её через "
            "`aida show facts` (стрелка ← показывает, что чем заменено).".format(args.fact_id),
        )
        rid = next_id("facts")
        rec = dict(src)  # копия всех полей источника
        rec["id"] = rid
        rec["status"] = new_status
        rec["supersedes"] = src["id"]
        rec["recorded_by"] = args.by
        rec["recorded_at"] = now_iso()
        rec["checked_at"] = today()
        if reason is not None:
            rec["reason"] = reason
        append_record("facts", rec)
    return src["id"], rid


def cmd_accept(args):
    require(
        find("facts", args.fact_id) is not None
        and find("facts", args.fact_id).get("status") == "verified",
        "accept {}: повышать verified→accepted можно только факт в статусе "
        "verified (сейчас '{}').".format(
            args.fact_id,
            (find("facts", args.fact_id) or {}).get("status", "нет такого"),
        ),
    )
    old, new = _copy_fact_with_status(args, "accepted")
    print("OK: факт {} повышен до accepted новой записью {} (старая не тронута)".format(old, new))
    return 0


def cmd_stale(args):
    old, new = _copy_fact_with_status(args, "stale", reason=args.reason)
    print("OK: факт {} помечен stale новой записью {} (старая не тронута)".format(old, new))
    print("  причина: {}".format(args.reason))
    return 0


def cmd_decision(args):
    require(
        args.by in DECISION_BY,
        "недопустимый --by '{}'. Допустимо: {}.".format(
            args.by, " ".join(sorted(DECISION_BY))
        ),
    )
    require(
        args.scope in SCOPES,
        "недопустимый --scope '{}'. Допустимо: {}.".format(
            args.scope, " ".join(sorted(SCOPES))
        ),
    )
    require(
        DATE_RE.match(args.decided_at),
        "недопустимый --decided-at '{}'. Формат YYYY-MM-DD; дату бери из "
        "DISPATCHER/журнала, не выдумывай.".format(args.decided_at),
    )
    # Проверка ссылки supersedes + выдача id + дозапись — под одним замком.
    with ledger_lock():
        if args.supersedes is not None:
            require(
                find("decisions", args.supersedes) is not None,
                "--supersedes {}: такого решения нет в decisions.jsonl.".format(args.supersedes),
            )
        rid = next_id("decisions")
        rec = {
            "id": rid,
            "decision": args.decision,
            "decided_by": args.by,
            "decided_at": args.decided_at,
            "scope": args.scope,
            "basis": list(args.basis or []),
            "review_when": args.review_when,
            "status": "active",
            "supersedes": args.supersedes,
            "recorded_by": args.recorded_by or args.by,
            "recorded_at": now_iso(),
        }
        append_record("decisions", rec)
    print("OK: решение записано {} (status: active)".format(rid))
    print("  решено ({}, {}): {}".format(args.by, args.decided_at, args.decision))
    return 0


def cmd_contradict(args):
    require(
        args.a != args.b,
        "противоречие требует ДВУХ разных фактов; a и b совпадают ('{}'). "
        "Факт не противоречит сам себе.\n"
        "Как исправить: укажи две разные стороны — `aida show facts` для их "
        "id.".format(args.a),
    )
    require(
        args.working in (args.a, args.b),
        "contradict: --working '{}' должен совпадать с a ('{}') или b ('{}').".format(
            args.working, args.a, args.b
        ),
    )
    # Проверка существования сторон + выдача id + дозапись — под одним замком.
    with ledger_lock():
        fa = find("facts", args.a)
        fb = find("facts", args.b)
        require(
            fa is not None,
            "contradict: факт-сторона A '{}' не существует в facts.jsonl.\n"
            "Как исправить: оба конфликтующих факта должны быть заведены заранее "
            "(`aida fact ...`), затем `aida show facts` для их id.".format(args.a),
        )
        require(
            fb is not None,
            "contradict: факт-сторона B '{}' не существует в facts.jsonl.".format(args.b),
        )
        rid = next_id("contradictions")
        rec = {
            "id": rid,
            "a": args.a,
            "b": args.b,
            "working": args.working,
            "resolves_when": args.resolves_when,
            "status": "open",
            "resolved_by": None,
            "recorded_by": args.by,
            "recorded_at": now_iso(),
        }
        append_record("contradictions", rec)
    print("OK: противоречие записано {} (status: open)".format(rid))
    print("  A={} B={} рабочая версия={}".format(args.a, args.b, args.working))
    return 0


# --- ворота дел v0.1: защищённый адаптер записи (D-20260614-006) ------------
# ИДЕЯ. Модель не пишет в цель напрямую этим путём. Она ЗАЯВЛЯЕТ действие (цель +
# ожидаемое изменение), а ядро исполняет РОВНО заявленное и журналирует обе фазы:
# requested (до исполнения) и executed (после, тем же id). Так «сказать А —
# записать Б» невозможно ВНУТРИ этого пути: что записано в журнал заявкой, то и
# исполнено кодом, одно поле change. Обход (прямая запись в наблюдаемую зону мимо
# адаптера или подмена содержимого после executed) ловится постфактум сверкой-с-
# миром в run_check.
#
# ЧЕСТНЫЙ ПРЕДЕЛ v0.1 (см. дизайн §«ГЛАВНАЯ ЧЕСТНАЯ ПРАВДА»): это НЕ клетка прав.
# У процесса с правами на запись остаётся возможность тронуть файлы мимо ядра;
# v0.1 такой обход не блокирует физически, а ЛОВИТ постфактум (recon → инцидент).
# Полная клетка (урезанная учётка, физически нельзя писать мимо) — поздний слой.

def observed_dir():
    """Каталог наблюдаемой зоны (мир, который сверяем с журналом)."""
    return os.path.join(LEDGER_DIR, OBSERVED_SUBDIR)


def _validate_marker_target(target):
    """Цель адаптера marker.write должна быть простым именем маркера, не путём.

    Без '/', без '..', без ведущей точки-обхода — чтобы заявкой нельзя было
    выписать запись за пределы наблюдаемой зоны (path traversal). Это и есть
    «ядро исполняет РОВНО заявленное, и не больше»: цель ограничена зоной.
    """
    require(
        bool(target and target.strip()),
        "пустая цель действия (--target). Укажи имя маркера в наблюдаемой зоне.",
    )
    t = target.strip()
    require(
        "/" not in t and "\\" not in t and ".." not in t and not t.startswith("."),
        "недопустимая цель '{}': имя маркера без '/', '\\', '..' и ведущей точки "
        "(адаптер marker.write пишет только в наблюдаемую зону ledger/{}/, "
        "выход за неё запрещён).".format(target, OBSERVED_SUBDIR),
    )
    return t


def _refuse_critical_target(target):
    """Отказ на запись в критпуть БЕЗ права (v0.1: этому адаптеру — всегда).

    Цель в зоне scripts/**, schemas/**, policies/** … защищённому адаптеру
    записи запрещена в v0.1 (он пишет только в наблюдаемую зону). Это явный
    отказ «запись в критпуть без заявки/права», а не молчаливый промах.
    """
    t = (target or "").strip()
    for prefix in ACTION_CRITICAL_PREFIXES:
        if t == prefix.rstrip("/") or t.startswith(prefix):
            raise AidaError(
                "цель '{}' в критпути ({}): защищённый адаптер записи v0.1 в "
                "критпуть НЕ пишет (денежный/системный контур — поздний слой). "
                "Критпуть меняется людьми через git с подписью Approved-by "
                "(.githooks/commit-msg), не этим путём.".format(t, prefix))


def _apply_marker_write(target, change):
    """Исполнить РОВНО заявку marker.write: записать change в маркер цели.

    Возвращает абсолютный путь записанного маркера. Запись атомарна на уровне
    содержимого (полная перезапись файла маркера). Маркер — наблюдаемое
    состояние мира; его содержимое потом сверяется с journal-полем change.
    """
    name = _validate_marker_target(target)
    odir = observed_dir()
    os.makedirs(odir, exist_ok=True)
    path = os.path.join(odir, name)
    # change=None трактуем как пустую строку (заявка «обнулить маркер»).
    payload = "" if change is None else str(change)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(payload)
    return path


def cmd_action(args):
    """Защищённый адаптер записи: заявить → исполнить РОВНО заявку → закрыть.

    Один проход = одно действие: пишем requested (цель+изменение объявлены ДО
    исполнения), исполняем РОВНО заявленное через выбранный адаптер, затем
    дозаписываем executed (тем же id, И-14) либо failed при ошибке исполнения.
    Заявка и исполнение оперируют ОДНИМИ полями (target/change) — внутри пути
    «сказать А — записать Б» невозможно.
    """
    kind = args.kind
    require(
        kind in ACTION_KINDS,
        "неизвестный адаптер действия '{}'. Белый список (анти-ведро): {}.".format(
            kind, " ".join(sorted(ACTION_KINDS))),
    )
    # Отказ на критпуть — ДО открытия заявки (нечего журналировать, если цель
    # запрещена). Это «отказ на запись в критпуть без заявки/права» из ТЗ.
    _refuse_critical_target(args.target)
    target = _validate_marker_target(args.target)
    change = args.change

    # 1) ЗАЯВКА (requested): открываем действие ДО исполнения. allocate_and_append
    #    выдаёт A-id и дописывает строку под общим замком реестра — не свой движок.
    def build_requested(rid):
        return {
            "id": rid,
            "phase": "requested",
            "kind": kind,
            "target": target,
            "change": change,
            "recorded_by": args.by,
            "recorded_at": now_iso(),
        }

    aid = allocate_and_append("actions", build_requested)
    print("OK: заявка действия {} открыта (requested)".format(aid))
    print("  адаптер: {}  цель: {}".format(kind, target))

    # 2) ИСПОЛНЕНИЕ РОВНО ЗАЯВКИ + закрытие строкой executed|failed (тот же id).
    try:
        if kind == "marker.write":
            path = _apply_marker_write(target, change)
        else:  # недостижимо (kind проверен выше), но без молчаливого провала
            raise AidaError("адаптер '{}' без исполнителя".format(kind))
    except (OSError, AidaError) as exc:
        append_record("actions", {
            "id": aid,
            "phase": "failed",
            "kind": kind,
            "target": target,
            "change": change,
            "reason": str(exc),
            "recorded_by": args.by,
            "recorded_at": now_iso(),
        })
        sys.stderr.write("ОТКАЗ: действие {} не исполнено: {}\n".format(aid, exc))
        return 2

    append_record("actions", {
        "id": aid,
        "phase": "executed",
        "kind": kind,
        "target": target,
        "change": change,
        "recorded_by": args.by,
        "recorded_at": now_iso(),
    })
    print("OK: действие {} исполнено РОВНО заявкой (executed)".format(aid))
    print("  маркер: {}".format(path))
    return 0


def show_actions(scope, status):
    # У действий нет scope; фильтр scope игнорируем, status трактуем как phase.
    rows = read_records("actions")
    # Свернём по id, оставив последнюю фазу как актуальное состояние.
    rows = _latest_by_id(rows)
    rows = [r for r in rows if (not status or r.get("phase") == status)]
    if not rows:
        print("  (действий нет)")
        return
    for r in rows:
        rsn = "" if not r.get("reason") else "  причина: {}".format(r["reason"])
        print("{}  [{}/{}]  цель: {}{}".format(
            r["id"], r.get("kind"), r.get("phase"), r.get("target"), rsn))
        print("    изменение: {}".format(r.get("change")))


# --- show (человекочитаемо) ------------------------------------------------
def _latest_by_id(records):
    """Свернуть историю: оставить последнюю запись на каждый id (актуальное
    состояние). Порядок появления id сохраняется."""
    order = []
    latest = {}
    for rec in records:
        rid = rec.get("id")
        if rid not in latest:
            order.append(rid)
        latest[rid] = rec
    return [latest[r] for r in order]


def _passes(rec, scope, status):
    if scope and rec.get("scope") != scope:
        return False
    if status and rec.get("status") != status:
        return False
    return True


def _superseded_ids(records):
    """id фактов, на которые ссылается чья-то supersedes — это история, не
    текущее знание. Используется, чтобы по умолчанию не показывать заменённое."""
    return {r["supersedes"] for r in records
            if isinstance(r.get("supersedes"), str)}


def show_facts(scope, status):
    all_records = read_records("facts")
    superseded = _superseded_ids(all_records)
    rows = _latest_by_id(all_records)
    rows = [r for r in rows if _passes(r, scope, status)]
    # По умолчанию (без явного --status) прячем заменённые факты — показываем
    # только текущее знание; история живёт в файле и git. С явным --status
    # показываем всё подходящее (можно поднять и заменённое).
    hidden = 0
    if not status:
        kept = [r for r in rows if r.get("id") not in superseded]
        hidden = len(rows) - len(kept)
        rows = kept
    if not rows:
        print("  (фактов нет)")
        if hidden:
            print("  ({} заменённых скрыто — история; покажет --status)".format(hidden))
        return
    for r in rows:
        sup = "" if r.get("supersedes") is None else "  ←{}".format(r["supersedes"])
        tag = "  [заменён]" if r.get("id") in superseded else ""
        exp = r.get("expires")
        exp_s = "бессрочно" if exp is None else exp
        print("{}  [{}/{}/{}]  до: {}{}{}".format(
            r["id"], r["scope"], r["status"], r["confidence"], exp_s, sup, tag))
        print("    {}".format(r["statement"]))
        src = r.get("source", {})
        line = "    источник: {} → {}".format(src.get("kind"), src.get("ref"))
        print(line)
        if src.get("quote"):
            print("    выжимка: {}".format(src["quote"]))
    if hidden:
        print("  ({} заменённых скрыто — история; покажет --status)".format(hidden))


def show_decisions(scope, status):
    all_records = read_records("decisions")
    superseded = _superseded_ids(all_records)
    rows = _latest_by_id(all_records)
    rows = [r for r in rows if _passes(r, scope, status)]
    hidden = 0
    if not status:
        kept = [r for r in rows if r.get("id") not in superseded]
        hidden = len(rows) - len(kept)
        rows = kept
    if not rows:
        print("  (решений нет)")
        if hidden:
            print("  ({} заменённых скрыто — история; покажет --status)".format(hidden))
        return
    for r in rows:
        sup = "" if r.get("supersedes") is None else "  ←{}".format(r["supersedes"])
        tag = "  [заменено]" if r.get("id") in superseded else ""
        print("{}  [{}/{}]  {}, {}{}{}".format(
            r["id"], r["scope"], r["status"], r["decided_by"], r["decided_at"], sup, tag))
        print("    {}".format(r["decision"]))
        if r.get("basis"):
            print("    основание: {}".format("; ".join(r["basis"])))
        if r.get("review_when"):
            print("    пересмотр: {}".format(r["review_when"]))
    if hidden:
        print("  ({} заменённых скрыто — история; покажет --status)".format(hidden))


def show_inbox(scope, status):
    # У inbox нет scope; фильтр scope игнорируем, status — поддерживаем.
    rows = _latest_by_id(read_records("inbox"))
    rows = [r for r in rows if (not status or r.get("status") == status)]
    if not rows:
        print("  (карантин пуст)")
        return
    for r in rows:
        pr = "" if r.get("promoted_to") is None else "  →{}".format(r["promoted_to"])
        print("{}  [{}]{}".format(r["id"], r["status"], pr))
        print("    {}".format(r["note"]))
        if r.get("context"):
            print("    контекст: {}".format(r["context"]))


def show_contradictions(scope, status):
    rows = _latest_by_id(read_records("contradictions"))
    rows = [r for r in rows if (not status or r.get("status") == status)]
    if not rows:
        print("  (противоречий нет)")
        return
    for r in rows:
        rb = "" if r.get("resolved_by") is None else "  разрешил: {}".format(r["resolved_by"])
        print("{}  [{}]  рабочая версия: {}{}".format(
            r["id"], r["status"], r["working"], rb))
        print("    A={}  B={}".format(r["a"], r["b"]))
        print("    разрешит: {}".format(r["resolves_when"]))


SHOW = {
    "facts": show_facts,
    "decisions": show_decisions,
    "inbox": show_inbox,
    "contradictions": show_contradictions,
    "actions": show_actions,
}


def cmd_show(args):
    print("=== {} ===".format(args.what))
    SHOW[args.what](args.scope, args.status)
    return 0


# --- валидатор (aida check, §5) --------------------------------------------
def _check_common(name, rec, lineno, errors, ids_seen):
    """Общие проверки строки: id (шаблон + уникальность), recorded_*."""
    rid = rec.get("id")
    if not isinstance(rid, str) or not ID_RE[name].match(rid or ""):
        errors.append("{}:{}: id '{}' не соответствует шаблону {}".format(
            FILES[name], lineno, rid, ID_RE[name].pattern))
        return None
    # Уникальность id в файле. Для inbox допускаются ПОВТОРЫ id (raw→promoted —
    # новое состояние того же id, И-14); для остальных файлов id уникален.
    if name != "inbox":
        if rid in ids_seen:
            errors.append("{}:{}: id '{}' дублируется (впервые на строке {})".format(
                FILES[name], lineno, rid, ids_seen[rid]))
        else:
            ids_seen[rid] = lineno
    for field in ("recorded_by", "recorded_at"):
        if not rec.get(field):
            errors.append("{}:{}: пустое обязательное поле '{}'".format(
                FILES[name], lineno, field))
    return rid


def _enum(name, rec, lineno, field, allowed, errors):
    val = rec.get(field)
    if val not in allowed:
        errors.append("{}:{}: поле '{}'='{}' не из допустимых ({})".format(
            FILES[name], lineno, field, val, " ".join(sorted(allowed))))


def _required(name, rec, lineno, field, errors):
    if field not in rec:
        errors.append("{}:{}: нет обязательного поля '{}'".format(
            FILES[name], lineno, field))
        return False
    return True


def run_check():
    """Вернуть (errors, warnings, info) — три списка строк."""
    errors, warnings, info = [], [], []

    # Сырые строки с номерами: ловим битый JSON по месту (§8.4).
    raw = {}
    for name in FILES:
        p = path_for(name)
        raw[name] = []
        if not os.path.exists(p):
            continue
        with open(p, "r", encoding="utf-8") as fh:
            for lineno, line in enumerate(fh, 1):
                if not line.strip():
                    continue
                try:
                    raw[name].append((lineno, json.loads(line)))
                except json.JSONDecodeError as exc:
                    errors.append("{}:{}: строка не является валидным JSON ({})".format(
                        FILES[name], lineno, exc.msg))

    # Множества существующих id по файлам (для проверки ссылок поперёк файлов).
    fact_ids = {rec["id"] for _, rec in raw["facts"] if isinstance(rec.get("id"), str)}
    decision_ids = {rec["id"] for _, rec in raw["decisions"] if isinstance(rec.get("id"), str)}
    inbox_ids = {rec["id"] for _, rec in raw["inbox"] if isinstance(rec.get("id"), str)}

    # ---- facts -----------------------------------------------------------
    ids_seen = {}
    for lineno, rec in raw["facts"]:
        rid = _check_common("facts", rec, lineno, errors, ids_seen)
        for field in ("statement", "scope", "status", "confidence", "source",
                      "checked_at", "expires", "supersedes", "origin"):
            _required("facts", rec, lineno, field, errors)
        _enum("facts", rec, lineno, "scope", SCOPES, errors)
        _enum("facts", rec, lineno, "status", FACT_STATUSES, errors)
        _enum("facts", rec, lineno, "confidence", CONFIDENCES, errors)
        # И-5: источник обязателен и непуст. Пустые/ПРОБЕЛЬНЫЕ kind/ref (после
        # strip) источником не являются — это ошибка наравне с отсутствием поля.
        src = rec.get("source")
        s_kind = src.get("kind") if isinstance(src, dict) else None
        s_ref = src.get("ref") if isinstance(src, dict) else None
        s_kind_ok = isinstance(s_kind, str) and s_kind.strip()
        s_ref_ok = isinstance(s_ref, str) and s_ref.strip()
        if not isinstance(src, dict) or not s_kind_ok or not s_ref_ok:
            errors.append("{}:{}: факт без источника (И-5): нужны непустые "
                          "source.kind и source.ref".format(FILES["facts"], lineno))
        elif src.get("kind") not in SOURCE_KINDS:
            errors.append("{}:{}: source.kind='{}' не из допустимых ({})".format(
                FILES["facts"], lineno, src.get("kind"), " ".join(sorted(SOURCE_KINDS))))
        # checked_at — дата.
        if rec.get("checked_at") and not DATE_RE.match(str(rec.get("checked_at"))):
            errors.append("{}:{}: checked_at '{}' не формата YYYY-MM-DD".format(
                FILES["facts"], lineno, rec.get("checked_at")))
        # expires — дата | event: | null.
        exp = rec.get("expires", "<нет>")
        if exp is not None and exp != "<нет>" and not EXPIRES_RE.match(str(exp)):
            errors.append("{}:{}: expires '{}' не формата YYYY-MM-DD|event:…|null".format(
                FILES["facts"], lineno, exp))
        # Ссылки.
        sup = rec.get("supersedes")
        if sup is not None and sup not in fact_ids:
            errors.append("{}:{}: supersedes '{}' указывает в никуда (нет такого "
                          "факта)".format(FILES["facts"], lineno, sup))
        org = rec.get("origin")
        if org is not None and org not in inbox_ids:
            errors.append("{}:{}: origin '{}' указывает в никуда (нет такой "
                          "inbox-записи)".format(FILES["facts"], lineno, org))
        # Структурная память (опционально): key — непустая строка; valid_until —
        # дата|event:|null. Поля опциональны (старые факты их не несут), но если
        # заданы — должны быть валидны.
        if "key" in rec:
            k = rec.get("key")
            if not isinstance(k, str) or not k.strip():
                errors.append("{}:{}: key задан, но не непустая строка".format(
                    FILES["facts"], lineno))
        if "valid_until" in rec:
            vu = rec.get("valid_until")
            if vu is not None and not VALID_UNTIL_RE.match(str(vu)):
                errors.append("{}:{}: valid_until '{}' не формата "
                              "YYYY-MM-DD|event:…|null".format(
                                  FILES["facts"], lineno, vu))

    # ---- decisions -------------------------------------------------------
    ids_seen = {}
    for lineno, rec in raw["decisions"]:
        _check_common("decisions", rec, lineno, errors, ids_seen)
        for field in ("decision", "decided_by", "decided_at", "scope", "basis",
                      "review_when", "status", "supersedes"):
            _required("decisions", rec, lineno, field, errors)
        _enum("decisions", rec, lineno, "decided_by", DECISION_BY, errors)
        _enum("decisions", rec, lineno, "scope", SCOPES, errors)
        _enum("decisions", rec, lineno, "status", DECISION_STATUSES, errors)
        if rec.get("decided_at") and not DATE_RE.match(str(rec.get("decided_at"))):
            errors.append("{}:{}: decided_at '{}' не формата YYYY-MM-DD".format(
                FILES["decisions"], lineno, rec.get("decided_at")))
        if "basis" in rec and not isinstance(rec.get("basis"), list):
            errors.append("{}:{}: basis должен быть массивом строк".format(
                FILES["decisions"], lineno))
        sup = rec.get("supersedes")
        if sup is not None and sup not in decision_ids:
            errors.append("{}:{}: supersedes '{}' указывает в никуда (нет такого "
                          "решения)".format(FILES["decisions"], lineno, sup))

    # ---- inbox -----------------------------------------------------------
    ids_seen = {}
    for lineno, rec in raw["inbox"]:
        _check_common("inbox", rec, lineno, errors, ids_seen)
        for field in ("note", "status", "promoted_to"):
            _required("inbox", rec, lineno, field, errors)
        _enum("inbox", rec, lineno, "status", INBOX_STATUSES, errors)
        pt = rec.get("promoted_to")
        if pt is not None and pt not in fact_ids:
            errors.append("{}:{}: promoted_to '{}' указывает в никуда (нет такого "
                          "факта)".format(FILES["inbox"], lineno, pt))
        # promoted без promoted_to — рассогласование статуса.
        if rec.get("status") == "promoted" and pt is None:
            errors.append("{}:{}: status=promoted, но promoted_to пуст".format(
                FILES["inbox"], lineno))

    # ---- contradictions --------------------------------------------------
    ids_seen = {}
    for lineno, rec in raw["contradictions"]:
        _check_common("contradictions", rec, lineno, errors, ids_seen)
        for field in ("a", "b", "working", "resolves_when", "status", "resolved_by"):
            _required("contradictions", rec, lineno, field, errors)
        _enum("contradictions", rec, lineno, "status", CONTRADICTION_STATUSES, errors)
        a, b, w = rec.get("a"), rec.get("b"), rec.get("working")
        # Противоречие требует ДВУХ разных фактов: a==b — самопротиворечие,
        # факт не спорит сам с собой.
        if a is not None and b is not None and a == b:
            errors.append("{}:{}: a и b совпадают ('{}') — противоречие требует "
                          "двух разных фактов".format(FILES["contradictions"], lineno, a))
        if a is not None and a not in fact_ids:
            errors.append("{}:{}: сторона a '{}' не существует в facts.jsonl".format(
                FILES["contradictions"], lineno, a))
        if b is not None and b not in fact_ids:
            errors.append("{}:{}: сторона b '{}' не существует в facts.jsonl".format(
                FILES["contradictions"], lineno, b))
        # §5.4: working равен a или b.
        if w is not None and w not in (a, b):
            errors.append("{}:{}: working '{}' не равен ни a ('{}'), ни b ('{}')".format(
                FILES["contradictions"], lineno, w, a, b))
        rbv = rec.get("resolved_by")
        if rbv is not None:
            if not ANY_ID_RE.match(str(rbv)) or (rbv not in fact_ids and rbv not in decision_ids):
                errors.append("{}:{}: resolved_by '{}' указывает в никуда (ни факт, "
                              "ни решение)".format(FILES["contradictions"], lineno, rbv))

    # ---- структурная память: противоречие по key (ОШИБКА; ядро правды) ---
    # МЕХАНИЧЕСКИ, без модели: среди АКТУАЛЬНЫХ фактов (последняя запись на id,
    # не заменённых, не stale/superseded) два с одним key, но разным
    # нормализованным value — противоречие памяти. Один key = одно текущее знание.
    fact_superseded = _superseded_ids([r for _, r in raw["facts"]])
    active_by_key = {}  # key -> list of (id, norm_value, raw_value)
    for rec in _latest_by_id([r for _, r in raw["facts"]]):
        if rec.get("id") in fact_superseded:
            continue
        if rec.get("status") in ("stale", "superseded"):
            continue
        k = rec.get("key")
        if not isinstance(k, str) or not k.strip():
            continue
        active_by_key.setdefault(k.strip(), []).append(
            (rec.get("id"), norm_value(rec.get("value")), rec.get("value")))
    for k, rows in active_by_key.items():
        distinct = {nv for _, nv, _ in rows}
        if len(distinct) > 1:
            ids = ", ".join("{}={!r}".format(rid, rv) for rid, _, rv in rows)
            errors.append(
                "противоречие памяти по key '{}': активные факты несут разные "
                "значения ({}). Один key — одно текущее знание: оставь актуальное, "
                "остальные пометь stale/supersede.".format(k, ids))

    # ---- §5.5 просроченные факты (ПРЕДУПРЕЖДЕНИЕ, не отказ; И-13) ---------
    # Считаем по актуальному состоянию (последняя запись на id).
    for rec in _latest_by_id([r for _, r in raw["facts"]]):
        exp = rec.get("expires")
        status = rec.get("status")
        if isinstance(exp, str) and DATE_RE.match(exp) and status not in ("stale", "superseded"):
            if exp < today():
                warnings.append("факт {} протух (expires {} в прошлом, статус "
                                "'{}') — перепроверь или пометь stale".format(
                                    rec.get("id"), exp, status))

    # ---- §5.6 открытые противоречия (информационно) ----------------------
    for rec in _latest_by_id([r for _, r in raw["contradictions"]]):
        if rec.get("status") == "open":
            info.append("открытое противоречие {}: работаем по {} (разрешит: {})".format(
                rec.get("id"), rec.get("working"), rec.get("resolves_when")))

    # ---- ворота дел: журнал действий (форма строк) -----------------------
    # Те же общие проверки (id-шаблон, recorded_*), плюс enum phase/kind и
    # обязательные поля действия. id ПОВТОРЯЕТСЯ между фазами (как inbox) —
    # дубль id не считаем ошибкой (передаём отдельный ids_seen, как inbox).
    ids_seen = {}
    for lineno, rec in raw["actions"]:
        rid = rec.get("id")
        if not isinstance(rid, str) or not ID_RE["actions"].match(rid or ""):
            errors.append("{}:{}: id '{}' не соответствует шаблону {}".format(
                FILES["actions"], lineno, rid, ID_RE["actions"].pattern))
        for field in ("recorded_by", "recorded_at"):
            if not rec.get(field):
                errors.append("{}:{}: пустое обязательное поле '{}'".format(
                    FILES["actions"], lineno, field))
        for field in ("phase", "kind", "target", "change"):
            _required("actions", rec, lineno, field, errors)
        _enum("actions", rec, lineno, "phase", ACTION_PHASES, errors)
        _enum("actions", rec, lineno, "kind", ACTION_KINDS, errors)
        # failed-строка обязана нести непустую причину; requested/executed — нет.
        if rec.get("phase") == "failed":
            rsn = rec.get("reason")
            if not (isinstance(rsn, str) and rsn.strip()):
                errors.append("{}:{}: phase=failed без непустого reason".format(
                    FILES["actions"], lineno))

    # ---- СВЕРКА-С-МИРОМ (ядро ворот дел): ловля «сказал А — сделал Б» -----
    # НЕ журнал-с-собой, а МИР (содержимое маркеров наблюдаемой зоны) ПРОТИВ
    # журнала исполненных действий. Инцидент (ОШИБКА, exit≠0), если:
    #   1) маркер в зоне есть, но его содержимое НЕ совпадает ни с одной
    #      executed-заявкой на эту цель — «заявлено А, в мире Б» ИЛИ подмена
    #      содержимого после исполнения;
    #   2) маркер в зоне есть, а executed-заявки на эту цель нет вовсе —
    #      прямая запись мимо ядра (обход журнала).
    # Симметрично: executed-заявка есть, а маркера в мире нет — тоже инцидент
    # (заявили исполнение, мир пуст).
    # Маркеры читаем из ФАЙЛОВ зоны (мир), а ожидания — из журнала.
    executed_by_target = {}   # target -> set нормализованных ожидаемых change
    executed_ids_by_target = {}
    for _, rec in raw["actions"]:
        if rec.get("phase") != "executed":
            continue
        if rec.get("kind") != "marker.write":
            continue
        tgt = rec.get("target")
        if not isinstance(tgt, str) or not tgt.strip():
            continue
        exp = "" if rec.get("change") is None else str(rec.get("change"))
        executed_by_target.setdefault(tgt, set()).add(exp)
        executed_ids_by_target.setdefault(tgt, []).append(rec.get("id"))

    odir = observed_dir()
    observed = {}   # target -> фактическое содержимое маркера (мир)
    if os.path.isdir(odir):
        for entry in sorted(os.listdir(odir)):
            fp = os.path.join(odir, entry)
            if not os.path.isfile(fp):
                continue
            try:
                with open(fp, "r", encoding="utf-8") as fh:
                    observed[entry] = fh.read()
            except OSError as exc:
                errors.append("ИНЦИДЕНТ (ворота дел): не прочесть маркер мира "
                              "'{}' ({})".format(entry, exc))

    # (1)+(2): каждый маркер мира должен подтверждаться executed-заявкой.
    for tgt, actual in sorted(observed.items()):
        if tgt not in executed_by_target:
            errors.append(
                "ИНЦИДЕНТ (ворота дел): маркер мира '{}' изменён БЕЗ заявки "
                "(нет executed-действия на эту цель в actions.jsonl). Прямая "
                "запись мимо ядра — обход журнала.".format(tgt))
            continue
        if actual not in executed_by_target[tgt]:
            decl = "; ".join(sorted(repr(v) for v in executed_by_target[tgt]))
            errors.append(
                "ИНЦИДЕНТ (ворота дел): «сказал А — сделал Б» по цели '{}': в "
                "мире {!r}, а журнал (executed {}) заявлял {}. Расхождение "
                "заявки и факта.".format(
                    tgt, actual, ", ".join(executed_ids_by_target[tgt]), decl))

    # симметрично: заявили исполнение, но маркера в мире нет.
    for tgt, ids in sorted(executed_ids_by_target.items()):
        if tgt not in observed:
            errors.append(
                "ИНЦИДЕНТ (ворота дел): executed-действие ({}) по цели '{}' "
                "есть в журнале, а маркера в мире нет — заявлено исполнение, "
                "мир пуст.".format(", ".join(ids), tgt))

    return errors, warnings, info


def cmd_check(_args):
    errors, warnings, info = run_check()
    if info:
        print("--- открытые противоречия (информация) ---")
        for line in info:
            print("  i {}".format(line))
    if warnings:
        print("--- предупреждения (срок годности, И-13) ---")
        for line in warnings:
            print("  ! {}".format(line))
    if errors:
        print("--- ОШИБКИ ({}) ---".format(len(errors)))
        for line in errors:
            print("  x {}".format(line))
        print("РЕЕСТР НЕВАЛИДЕН: исправь перечисленное (строки только "
              "дописываются, И-14 — битую строку чини в git-истории, не удаляй).")
        return 1
    print("OK: реестр валиден ({} предупреждений, {} открытых противоречий)".format(
        len(warnings), len(info)))
    return 0


# --- разбор аргументов -----------------------------------------------------
def build_parser():
    p = argparse.ArgumentParser(prog="aida", description="реестр фактов и решений Aida")
    p.add_argument("--by", default="worker", help="кто делает запись (recorded_by)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("inbox", help="запись в карантин")
    s.add_argument("note")
    s.add_argument("--context")
    s.set_defaults(func=cmd_inbox)

    def add_source_args(sp):
        sp.add_argument("--source-kind", dest="source_kind")
        sp.add_argument("--source-ref", dest="source_ref")
        sp.add_argument("--quote")
        sp.add_argument("--scope", required=True)
        sp.add_argument("--confidence", default="medium")
        sp.add_argument("--expires", default=None)
        sp.add_argument("--checked-at", dest="checked_at", default=None)
        # Структурная память (опционально, ядро правды): машинный ключ/значение и
        # срок годности ОПОРЫ. Без --key факт пишется как раньше.
        sp.add_argument("--key", default=None,
                        help="машинный ключ структурной памяти (опционально)")
        sp.add_argument("--value", default=None,
                        help="машинное значение по ключу (строка/число/true|false|null)")
        sp.add_argument("--valid-until", dest="valid_until", default=None,
                        help="срок годности опоры: YYYY-MM-DD | event:<...> (опционально)")

    s = sub.add_parser("fact", help="новый факт со источником")
    s.add_argument("statement")
    add_source_args(s)
    s.add_argument("--supersedes", default=None)
    s.set_defaults(func=cmd_fact)

    s = sub.add_parser("promote", help="факт из карантина")
    s.add_argument("inbox_id")
    s.add_argument("--statement", default=None,
                   help="формулировка факта; по умолчанию — текст заметки карантина")
    add_source_args(s)
    s.add_argument("--supersedes", default=None)
    s.set_defaults(func=cmd_promote)

    s = sub.add_parser("accept", help="повысить факт verified→accepted")
    s.add_argument("fact_id")
    s.set_defaults(func=cmd_accept)

    s = sub.add_parser("stale", help="пометить факт протухшим")
    s.add_argument("fact_id")
    s.add_argument("--reason", required=True)
    s.set_defaults(func=cmd_stale)

    s = sub.add_parser("decision", help="новое решение")
    s.add_argument("decision")
    s.add_argument("--by", dest="by", required=True,
                   help="owner|admin|tl-sitka|tl-astro|tl-crypto")
    s.add_argument("--scope", required=True)
    s.add_argument("--decided-at", dest="decided_at", required=True,
                   help="YYYY-MM-DD из DISPATCHER/журнала")
    s.add_argument("--basis", action="append", default=[],
                   help="можно несколько раз (id фактов / свободный текст)")
    s.add_argument("--review-when", dest="review_when", default=None)
    s.add_argument("--supersedes", default=None)
    s.add_argument("--recorded-by", dest="recorded_by", default=None)
    s.set_defaults(func=cmd_decision)

    s = sub.add_parser("contradict", help="противоречие двух фактов")
    s.add_argument("a")
    s.add_argument("b")
    s.add_argument("--working", required=True)
    s.add_argument("--resolves-when", dest="resolves_when", required=True)
    s.set_defaults(func=cmd_contradict)

    # Ворота дел v0.1: защищённый адаптер записи. Модель ЗАЯВЛЯЕТ цель+изменение,
    # ядро исполняет РОВНО заявку и журналирует requested+executed (или failed).
    s = sub.add_parser("action",
                       help="защищённое действие: заявить цель+изменение, "
                            "ядро исполнит ровно заявку и запишет в журнал")
    s.add_argument("--kind", required=True,
                   help="адаптер записи из белого списка (v0.1: marker.write)")
    s.add_argument("--target", required=True,
                   help="цель: имя маркера в наблюдаемой зоне ledger/observed/ "
                        "(критпуть запрещён)")
    s.add_argument("--change", default=None,
                   help="ожидаемое изменение: новое содержимое маркера")
    s.set_defaults(func=cmd_action)

    s = sub.add_parser("show", help="человекочитаемая выдача")
    s.add_argument("what", nargs="?", default="facts",
                   choices=["facts", "decisions", "inbox", "contradictions",
                            "actions"])
    s.add_argument("--scope", default=None)
    s.add_argument("--status", default=None)
    s.set_defaults(func=cmd_show)

    s = sub.add_parser("check", help="валидатор реестра")
    s.set_defaults(func=cmd_check)

    return p


def main(argv=None):
    parser = build_parser()
    # Подкоманда decision переопределяет --by как required; для остальных --by
    # глобальный с дефолтом. argparse разрулит, т.к. decision определяет свой.
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except AidaError as exc:
        sys.stderr.write("ОТКАЗ: {}\n".format(exc))
        return 2


if __name__ == "__main__":
    sys.exit(main())
