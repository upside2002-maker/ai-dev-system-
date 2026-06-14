#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Диспетчер СТРУКТУРНЫХ ЗАЯВОК (фронт поверх влитых ядер, D-20260614-007).

Основание: ТЗ docs/AIDA_STRUCTURED_CLAIMS_TZ_2026-06-14.md + рамка Owner.
Только стандартная библиотека.

ПРИНЦИП (нерушимый). Ворота срабатывают НЕ на свободный текст, а на МОМЕНТ,
когда текст становится ОПОРОЙ. Этот момент модель объявляет САМА, ПОДАВАЯ
конверт-заявку (JSON с kind). Диспетчер срабатывает ТОЛЬКО на поданный конверт;
текст модели в него НЕ передаётся как сырьё для классификации. Грубый сторож
свободного текста ОТКЛОНЁН — здесь НЕ воскрешён: НЕТ авто-классификации речи,
НЕТ модели-судьи. Вердикт выносит влитой КОД против доверенных источников.

ЭТОТ ФАЙЛ НЕ ПРОВЕРЯЕТ. Он делает ровно три вещи:
  1) валидирует САМ конверт (схема/полнота/белые списки) — безопасно, т.к. это
     проверка ЗАЯВКИ, а не речи; невалидный/неполный → unverified (асимметрия);
  2) по таблице из ПЯТИ строк переименовывает поля конверта в форму, которую
     ждёт УЖЕ ВЛИТОЙ верификатор;
  3) зовёт этот влитой верификатор и возвращает его вердикт (коды 0/3/4).

ТАБЛИЦА МАРШРУТОВ (пять строк kind → влитой верификатор):
  fact_claim       → aida_kernel.gate(type=fact)          источник(7 адаптеров)+память
  advice_basis     → aida_kernel.gate(type=recommendation) контекст-срок (временная опора)
  capability_check → aida_kernel.gate(type=recommendation) реестр (встроенное под need)
  action_request   → aida_ledger.cmd_action                ворота дел (requested→executed)
  done_report (a)  → aida_ledger.run_check                 сверка журнал↔мир ЦЕЛИКОМ
  done_report (b)  → aida_kernel.gate(type=fact)           file/git/test признак готовности

ЧЕСТНЫЙ ПРЕДЕЛ (по ТЗ, чёрным по белому). done_report ветка (а) run_check
ГЛОБАЛЬНА: сверяет ВЕСЬ журнал действий с наблюдаемой зоной (журнал↔мир целиком),
а НЕ конкретный рапорт. Она ловит ложь, только если та уже есть в журнале как
расхождение (исполнено-А-в-мире-Б / маркер-без-заявки / заявлено-исполнение-мир-
пуст). Чисто словесное «готово» без выставленного действия ветка (а) НЕ видит —
это необъявленная словесная опора, вне охвата ПО КОНСТРУКЦИИ (цена отказа от
парсера речи). Не переоцениваем.

ВЕРДИКТЫ (как у ядра): passed | unverified | stop. Код выхода CLI: 0/3/4.
"""

import argparse
import json
import os
import sys
import types

# Соседние модули ядра лежат в scripts/ — добавляем каталог в путь, чтобы импорт
# работал независимо от cwd вызывающего (как в aida_kernel.py).
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import aida_kernel as K  # noqa: E402  (gate, evaluate, Verdict, render_outward)
import aida_ledger as L   # noqa: E402  (cmd_action, run_check, AidaError)


# Поддержанные типы конверта (oneOf по kind в schemas/claim.schema.json).
CLAIM_KINDS = (
    "fact_claim",
    "advice_basis",
    "capability_check",
    "action_request",
    "done_report",
)

# Машинные коды диспетчера (вердикт выносит КОД). Маршрутные вердикты приходят от
# влитых ядер с их reason_code; здесь — только коды о САМОМ конверте и о воротах
# дел/сверке-с-миром, у которых своего reason_code нет.
DISPATCH_REASONS = {
    "UNVERIFIED_INVALID_ENVELOPE": "конверт не прошёл схему/полноту — не проверено (асимметрия)",
    "UNVERIFIED_UNSUPPORTED_KIND": "тип заявки не из пяти поддержанных — отклонён",
    "UNVERIFIED_DONE_NO_METHOD": "done_report без способа сверки (нет mode/adapter) — не проверено",
    "OK_ACTION_EXECUTED": "действие исполнено РОВНО заявкой через ворота дел (executed)",
    "STOP_ACTION_REFUSED": "ворота дел отказали в действии (критпуть/неизвестный адаптер/ошибка)",
    "OK_WORLD_RECONCILED": "сверка журнал↔мир целиком прошла — расхождений нет",
    "STOP_WORLD_INCIDENT": "сверка журнал↔мир целиком нашла инцидент (расхождение/обход/мир пуст)",
}


def _verdict(status, reason_code, detail="", evidence=None, reasons=None):
    """Собрать K.Verdict с reason из нужного словаря (ядра или диспетчера)."""
    v = K.Verdict(status, reason_code, detail, evidence)
    # Verdict.to_dict() ищет текст в K.REASONS; для наших кодов подставим свой.
    table = reasons or DISPATCH_REASONS
    if reason_code not in K.REASONS:
        # Временный лоскут: дополняем словарь ядра нашими кодами для to_dict.
        K.REASONS.setdefault(reason_code, table.get(reason_code, reason_code))
    return v


# --- проверка САМОГО конверта (заявки, не речи) ------------------------------
def validate_envelope(claim):
    """(ok, reason). Невалидный/неполный конверт → не проверено (асимметрия).

    Это безопасная авто-проверка ТОЛЬКО на заявке: схема, обязательные поля по
    kind, типы. НИКОГДА не трогает свободный текст модели."""
    if not isinstance(claim, dict):
        return False, "конверт не объект"
    kind = claim.get("kind")
    if kind not in CLAIM_KINDS:
        return False, "kind '{}' не из {}".format(kind, CLAIM_KINDS)

    if kind == "fact_claim":
        # adapter/arg/expected/key/value — все опциональны на уровне конверта;
        # достаточность для сверки решает влитой gate (нет adapter → unverified).
        if "adapter" in claim and not isinstance(claim["adapter"], str):
            return False, "adapter должен быть строкой"
    elif kind == "advice_basis":
        sup = claim.get("supports")
        if not isinstance(sup, list) or any(not isinstance(x, str) for x in sup):
            return False, "advice_basis требует supports — список ключей-строк"
        if claim.get("horizon") not in (None, "permanent", "temporary"):
            return False, "horizon '{}' не из permanent|temporary|null".format(
                claim.get("horizon"))
    elif kind == "capability_check":
        if not (isinstance(claim.get("tool"), str) and claim["tool"].strip()):
            return False, "capability_check требует непустой tool"
        if not (isinstance(claim.get("need"), str) and claim["need"].strip()):
            return False, "capability_check требует непустой need"
    elif kind == "action_request":
        if not (isinstance(claim.get("act_kind"), str) and claim["act_kind"].strip()):
            return False, "action_request требует непустой act_kind"
        if not (isinstance(claim.get("target"), str) and claim["target"].strip()):
            return False, "action_request требует непустой target"
    elif kind == "done_report":
        if claim.get("mode") not in ("world", "source"):
            return False, "done_report требует mode=world|source (способ сверки)"
        if claim.get("mode") == "source":
            if not (isinstance(claim.get("adapter"), str) and claim["adapter"].strip()):
                return False, "done_report mode=source требует adapter сверки"
    return True, ""


def _by(claim):
    by = claim.get("by")
    return by if isinstance(by, str) and by.strip() else "worker"


# --- ПЯТЬ МАРШРУТОВ (переименование полей → вызов ВЛИТОГО верификатора) ------
def _route_fact_claim(claim):
    """fact_claim → влитой aida_kernel.gate(type=fact). Переименование:
    adapter/arg/expected как есть; key→claim_key, value→claim_value (память)."""
    inner = {"type": "fact", "text": claim.get("text", "")}
    for src in ("adapter", "arg", "expected"):
        if src in claim:
            inner[src] = claim[src]
    if "key" in claim:
        inner["claim_key"] = claim["key"]
    if "value" in claim:
        inner["claim_value"] = claim["value"]
    return K.gate(inner)


def _route_advice_basis(claim):
    """advice_basis → влитой gate(type=recommendation) с supports+horizon.
    Контекст-ворота ядра ловят временную опору под постоянный горизонт."""
    inner = {
        "type": "recommendation",
        "text": claim.get("text", ""),
        "supports": claim.get("supports", []),
        "horizon": claim.get("horizon"),
    }
    return K.gate(inner)


def _route_capability_check(claim):
    """capability_check → влитой gate(type=recommendation) с tool+need.
    Capability-ворота ядра ловят внешний инструмент при встроенном под need."""
    inner = {
        "type": "recommendation",
        "text": claim.get("text", ""),
        "tool": claim["tool"],
        "need": claim["need"],
    }
    return K.gate(inner)


def _silenced_cmd_action(ns):
    """Вызвать влитой cmd_action, проглотив его stdout/stderr (он печатает свой
    операторский след: «заявка открыта», «исполнено РОВНО заявкой», «маркер: …»).
    Диспетчер сам отдаёт единый вердикт/JSON, поэтому след ядра дел не должен
    пачкать его вывод. Возвращает код возврата cmd_action (0 ок / 2 отказ).
    AidaError из _refuse_critical_target пробрасывается наверх как есть."""
    import io
    import contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        return L.cmd_action(ns)


def _route_action_request(claim):
    """action_request → влитой aida_ledger.cmd_action (ворота дел). Переименование:
    act_kind→kind, target→target, change→change, by→by. Влитое ядро дел печатает
    свой след сам — мы его глушим и читаем только код возврата, сворачивая в вердикт.

    cmd_action: 0 — исполнено РОВНО заявкой (requested→executed); 2 — отказ
    (критпуть/неизвестный адаптер/ошибка исполнения, в журнал пишется failed)."""
    ns = types.SimpleNamespace(
        kind=claim["act_kind"],
        target=claim["target"],
        change=claim.get("change"),
        by=_by(claim),
    )
    try:
        rc = _silenced_cmd_action(ns)
    except L.AidaError as exc:
        # _refuse_critical_target бросает AidaError ДО открытия заявки.
        v = _verdict("stop", "STOP_ACTION_REFUSED",
                     "ворота дел отказали: {}".format(exc),
                     evidence={"act_kind": claim["act_kind"],
                               "target": claim["target"]})
        return {"verdict": v.to_dict(), "outward": K.render_outward(claim, v),
                "logged_error": False, "memory_eligible": False}
    if rc == 0:
        v = _verdict("passed", "OK_ACTION_EXECUTED",
                     "действие по цели '{}' исполнено РОВНО заявкой".format(
                         claim["target"]),
                     evidence={"act_kind": claim["act_kind"],
                               "target": claim["target"]})
    else:
        v = _verdict("stop", "STOP_ACTION_REFUSED",
                     "ворота дел не исполнили действие (код {})".format(rc),
                     evidence={"act_kind": claim["act_kind"],
                               "target": claim["target"]})
    return {"verdict": v.to_dict(), "outward": K.render_outward(claim, v),
            "logged_error": False, "memory_eligible": False}


def _route_done_report(claim):
    """done_report → две ветки по mode.

    (а) mode=world: влитой aida_ledger.run_check — ГЛОБАЛЬНАЯ сверка журнал↔мир.
        Любой инцидент сверки (расхождение/обход/мир-пуст) → stop. Это
        ЕДИНСТВЕННЫЙ прямой ловец «executed-заявка есть, маркера в мире нет»
        (ledger ~1238). НЕ пер-рапортно — журнал↔мир целиком; не переоцениваем.
    (б) mode=source: влитой gate(type=fact) через адаптер file/git/test —
        сверка конкретного признака готовности с миром."""
    if claim["mode"] == "world":
        errors, _warnings, _info = L.run_check()
        # Считаем инцидентами ворот дел только строки сверки-с-миром; прочие
        # ошибки реестра (если есть) тоже валят рапорт — мир/журнал не в порядке.
        if errors:
            detail = "; ".join(errors[:5])
            v = _verdict("stop", "STOP_WORLD_INCIDENT",
                         "сверка журнал↔мир целиком: {}".format(detail),
                         evidence={"incidents": errors})
        else:
            v = _verdict("passed", "OK_WORLD_RECONCILED",
                         "журнал действий и наблюдаемая зона сходятся целиком")
        return {"verdict": v.to_dict(), "outward": K.render_outward(claim, v),
                "logged_error": False, "memory_eligible": False}

    # (б) mode=source — gate(fact) через file/git/test.
    inner = {"type": "fact", "text": claim.get("text", "")}
    for src in ("adapter", "arg", "expected"):
        if src in claim:
            inner[src] = claim[src]
    return K.gate(inner)


# Таблица из ПЯТИ строк: kind → маршрут в влитой верификатор.
ROUTES = {
    "fact_claim": _route_fact_claim,
    "advice_basis": _route_advice_basis,
    "capability_check": _route_capability_check,
    "action_request": _route_action_request,
    "done_report": _route_done_report,
}
assert set(ROUTES) == set(CLAIM_KINDS), "ROUTES разошлись с поддержанными kind"


def dispatch(claim):
    """Единая точка: провалидировать конверт → смаршрутить в влитой верификатор.

    Возвращает dict {verdict, outward, logged_error, memory_eligible} — той же
    формы, что K.gate, чтобы CLI и тесты работали единообразно."""
    ok, why = validate_envelope(claim)
    if not ok:
        kind = claim.get("kind") if isinstance(claim, dict) else None
        code = ("UNVERIFIED_UNSUPPORTED_KIND" if kind not in CLAIM_KINDS
                else "UNVERIFIED_INVALID_ENVELOPE")
        v = _verdict("unverified", code, why)
        return {"verdict": v.to_dict(),
                "outward": K.render_outward(claim if isinstance(claim, dict) else {}, v),
                "logged_error": False, "memory_eligible": False}
    return ROUTES[claim["kind"]](claim)


# --- CLI: aida_claim eval|gate (коды 0/3/4) ---------------------------------
_EXIT = {"passed": 0, "unverified": 3, "stop": 4}


def _read_payload(args):
    if args.file and args.file != "-":
        with open(args.file, "r", encoding="utf-8") as fh:
            return fh.read()
    return sys.stdin.read()


def _bad_json(exc, args):
    v = _verdict("unverified", "UNVERIFIED_INVALID_ENVELOPE",
                 "конверт не JSON: {}".format(exc))
    result = {"verdict": v.to_dict(), "outward": K.render_outward({}, v),
              "logged_error": False, "memory_eligible": False}
    _print(result, args)
    return 3


def _print(result, args):
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return
    v = result["verdict"]
    print("ВЕРДИКТ: {} [{}]".format(v["status"], v["reason_code"]))
    print("  {}".format(v["reason"]))
    if v.get("detail"):
        print("  {}".format(v["detail"]))
    print("--- наружу ---")
    print(result["outward"])
    if result.get("logged_error"):
        print("(записано в corrections/model_errors.jsonl)")


def cmd_eval(args):
    """eval = gate без побочных эффектов выхода (но влитые ядра могут писать свой
    журнал — для fact это journal ошибок ядра; здесь как у kernel eval, печать
    вердикта). Возвращает код вердикта 0/3/4."""
    payload = _read_payload(args)
    try:
        claim = json.loads(payload)
    except ValueError as exc:
        return _bad_json(exc, args)
    result = dispatch(claim)
    _print(result, args)
    return _EXIT[result["verdict"]["status"]]


def cmd_gate(args):
    """gate = полные ворота: вердикт + наружный текст + побочные эффекты влитых
    ядер (journal ошибок ядра, требуемые ворота дел). Возвращает код 0/3/4."""
    payload = _read_payload(args)
    try:
        claim = json.loads(payload)
    except ValueError as exc:
        return _bad_json(exc, args)
    result = dispatch(claim)
    _print(result, args)
    return _EXIT[result["verdict"]["status"]]


def cmd_kinds(_args):
    """Печать пяти поддержанных типов (для контракт-теста маршрутов)."""
    for k in CLAIM_KINDS:
        print(k)
    return 0


def build_parser():
    p = argparse.ArgumentParser(
        prog="aida-claim",
        description="диспетчер структурных заявок — маршрут в влитые ядра")
    sub = p.add_subparsers(dest="cmd", required=True)

    for name, func, helptext in (
        ("eval", cmd_eval, "вынести вердикт по конверту (JSON из файла/stdin)"),
        ("gate", cmd_gate, "полные ворота: вердикт + наружу + побочные эффекты"),
    ):
        s = sub.add_parser(name, help=helptext)
        s.add_argument("--file", default="-", help="файл с конверт-JSON (- = stdin)")
        s.add_argument("--json", action="store_true", help="вывод в JSON")
        s.set_defaults(func=func)

    s = sub.add_parser("kinds", help="печать пяти поддержанных типов заявок")
    s.set_defaults(func=cmd_kinds)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    try:
        return args.func(args)
    except L.AidaError as exc:
        sys.stderr.write("ОТКАЗ: {}\n".format(exc))
        return 2


if __name__ == "__main__":
    sys.exit(main())
