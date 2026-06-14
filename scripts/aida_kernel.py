#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Ядро правды v0.1 — детерминированный гейт перехода «мысль → опора».

Основание: D-20260614-003, D-20260614-004. ТЗ:
docs/AIDA_TRUTH_KERNEL_V01_TZ_2026-06-14.md. Только стандартная библиотека.

ПРИНЦИП (нерушимый). Ядро проверяет НЕ мысль, а ПЕРЕХОД от мысли к опоре.
Свободное рассуждение (type=reasoning) проходит мимо. Гейт срабатывает, когда
модель ГОВОРИТ факт / ДАЁТ совет / ПРЕДЛАГАЕТ инструмент-действие. Тогда вопрос:
на чём держится?

ВЕРДИКТ ВЫНОСИТ ЭТОТ КОД против ДОВЕРЕННОГО ИСТОЧНИКА. НИКОГДА не модель-судья.
Асимметрия: любой глюк/неопределённость → «не проверено»/«стоп», НИКОГДА
«проверено».

АНТИ-ВЕДРО (главное). Модель НЕ подаёт произвольную команду-проверку (иначе
подделка через печать нужного = ведро со штампом «проверено»). Модель ВЫБИРАЕТ
источник из БЕЛОГО СПИСКА адаптеров (ADAPTERS). Адаптер с неизвестным именем /
не из списка → claim «не проверено» (никогда «проверено»). Аргумент адаптера —
КЛЮЧ/ИМЯ/ПУТЬ (что искать в доверенном источнике), НЕ команда к исполнению.

ВХОД (claim). dict со схемой (валидируется как в crypto/classify.py — невалидный
отбрасывается → «не проверено»):
  type            : reasoning | fact | recommendation | action
  text            : текст наружу (черновик модели)
  adapter         : имя адаптера из ADAPTERS (для проверяемого claim)
  arg             : ключ/имя/путь для адаптера (НЕ команда)
  expected        : ожидаемое значение (сверяется КОДОМ с источником)
  supports        : [ключи структурной памяти, на которые опирается claim]
  horizon         : permanent | temporary | null (горизонт совета)
  tool            : имя предлагаемого инструмента (для recommendation/action)
  need            : ярлык потребности инструмента (для capability-ворот)

ВЕРДИКТЫ (выносит код):
  passed                  — проверено: источник подтвердил ожидаемое;
  unverified              — не проверено (асимметрия): глюк/неизвестный
                            адаптер/нет ожидаемого/невалидный claim/упал адаптер;
  stop                    — стоп: противоречие источнику/памяти, временная опора
                            как постоянная основа, внешний костыль при встроенном.

Каждый вердикт несёт МАШИННЫЙ reason_code (verdict выносится кодом, не текстом):
см. REASONS.
"""

import argparse
import json
import os
import sys

# Соседние модули ядра (aida_ledger, aida_capabilities, aida_registry) лежат
# рядом в scripts/ — добавляем каталог скрипта в путь, чтобы импорт работал
# независимо от cwd вызывающего.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Переиспользуем ядро реестра (И-5/И-13/И-14/структурная память/norm_value) —
# не дублируем логику фактов.
import aida_ledger as L  # noqa: E402
import aida_capabilities as C  # noqa: E402


# --- белый список адаптеров (АНТИ-ВЕДРО) ------------------------------------
# Имена строго из ТЗ §«Анти-ведро». Значение — функция-резолвер источника:
#   resolver(arg) -> Resolved
# Resolver НИКОГДА не исполняет произвольную команду: он лезет в конкретный
# доверенный источник по ключу/имени/пути. Если источник недоступен/нет записи
# → Resolved(found=False) (асимметрия даст «не проверено», не «проверено»).
ADAPTER_NAMES = (
    "ledger.fact",
    "project.status",
    "git.snapshot",
    "capability.exists",
    "billing.manual_record",
    "file.exists",
    "test.result",
)

CLAIM_TYPES = ("reasoning", "fact", "recommendation", "action")
HORIZONS = (None, "permanent", "temporary")

# Машинные коды вердиктов — вердикт выносит КОД, не текст модели.
REASONS = {
    "OK_REASONING": "свободное рассуждение — гейт не применяется",
    "OK_SOURCE_MATCH": "источник подтвердил ожидаемое",
    "OK_CAPABILITY_OK": "предложенный инструмент не нарушает «сначала встроенное»",
    "UNVERIFIED_INVALID_CLAIM": "claim не прошёл схему — не проверено (асимметрия)",
    "UNVERIFIED_UNKNOWN_ADAPTER": "адаптер не из белого списка — не проверено",
    "UNVERIFIED_NO_SOURCE": "у факта нет источника-из-белого-списка — требует источника",
    "UNVERIFIED_NO_EXPECTED": "не задано ожидаемое значение — нечего сверять, не проверено",
    "UNVERIFIED_ADAPTER_FAILED": "адаптер не нашёл/не смог прочитать источник — не проверено",
    "STOP_CONTRADICTS_SOURCE": "значение источника противоречит ожидаемому — стоп",
    "STOP_CONTRADICTS_MEMORY": "claim противоречит структурной памяти по key — стоп",
    "STOP_TEMPORARY_AS_PERMANENT": "опора временная — нельзя как постоянная основа без пометки — стоп",
    "STOP_EXTERNAL_OVER_BUILTIN": "внешний костыль предложен при встроенном — сначала встроенное — стоп",
}


class Resolved:
    """Результат адаптера: найдено ли, значение из источника, опц. valid_until."""

    __slots__ = ("found", "value", "valid_until", "detail")

    def __init__(self, found, value=None, valid_until=None, detail=""):
        self.found = found
        self.value = value
        self.valid_until = valid_until
        self.detail = detail


# --- резолверы адаптеров (каждый лезет в КОНКРЕТНЫЙ источник по ключу) -------
def _adapter_ledger_fact(arg):
    """ledger.fact(key): актуальное (не заменённое, не stale) значение факта по
    структурному ключу из ledger/facts.jsonl. Не команда — поиск по key."""
    rec = _latest_active_fact_by_key(arg)
    if rec is None:
        return Resolved(False, detail="нет активного факта с key={}".format(arg))
    return Resolved(True, value=rec.get("value"),
                    valid_until=rec.get("valid_until"),
                    detail="факт {}".format(rec.get("id")))


def _adapter_billing_manual_record(arg):
    """billing.manual_record(key): ручная запись Owner'а (подписка/кредит) СО
    СРОКОМ ГОДНОСТИ. Та же структурная память (key/value/valid_until), но опора
    ОБЯЗАНА нести valid_until — иначе это не «ручная запись со сроком», а
    бессрочный факт, и адаптер сообщает found=False (асимметрия → не проверено)."""
    rec = _latest_active_fact_by_key(arg)
    if rec is None:
        return Resolved(False, detail="нет ручной записи с key={}".format(arg))
    if rec.get("valid_until") is None:
        return Resolved(False, detail="запись {} без срока годности — не ручная "
                                      "запись со сроком".format(rec.get("id")))
    return Resolved(True, value=rec.get("value"),
                    valid_until=rec.get("valid_until"),
                    detail="ручная запись {}".format(rec.get("id")))


def _adapter_capability_exists(arg):
    """capability.exists(name): статус возможности из PROJECTS/capabilities.json.
    found=True → value = статус ('встроено'/'внешнее'/...). Неизвестная → found=False."""
    cap = C.find_capability(arg)
    if cap is None:
        return Resolved(False, detail="нет возможности {} в реестре".format(arg))
    return Resolved(True, value=cap.get("status"),
                    detail="возможность {}".format(arg))


def _adapter_file_exists(arg):
    """file.exists(path): файл реально есть на диске (под корнем репо). value =
    'да'/'нет'. Путь нормализуется и не выпускается за пределы репо."""
    root = os.path.abspath(L.ROOT)
    target = os.path.abspath(os.path.join(root, arg))
    # Защита: путь не должен убегать из репо (../../etc/...). Если убегает —
    # источник недоступен (асимметрия), а не «проверено».
    if not target.startswith(root + os.sep) and target != root:
        return Resolved(False, detail="путь вне корня репо: {}".format(arg))
    return Resolved(True, value="да" if os.path.exists(target) else "нет",
                    detail="path {}".format(arg))


def _adapter_project_status(arg):
    """project.status(slug): статус проекта. v0.1 — наличие проекта в реестре
    PROJECTS/projects.json (доверенный источник состава проектов). value =
    'есть'/'нет'. Снимок git репозитория — отдельный адаптер git.snapshot."""
    try:
        import aida_registry as R
    except Exception as exc:  # pragma: no cover - защита от среды
        return Resolved(False, detail="реестр проектов недоступен: {}".format(exc))
    try:
        proj = R.find_project(arg)
    except SystemExit:
        return Resolved(False, detail="реестр проектов не прочитан")
    if proj is None:
        return Resolved(False, detail="нет проекта {} в реестре".format(arg))
    return Resolved(True, value="есть", detail="проект {}".format(arg))


def _adapter_git_snapshot(arg):
    """git.snapshot(repo): реальное состояние репозитория (короткий HEAD).
    Доверенный источник — git. value = короткий sha HEAD. Недоступен → found=False.
    Не команда от модели: arg — slug/путь, git зовётся ядром фиксированной командой."""
    import subprocess
    repo = arg
    # slug → путь из реестра проектов (если это slug, а не путь).
    if not os.path.isabs(repo):
        try:
            import aida_registry as R
            proj = R.find_project(arg)
            if proj is not None:
                repo = R._expand_home(proj.get("repo", "")) or arg
        except Exception:
            pass
    if not repo or not os.path.isdir(os.path.join(repo, ".git")):
        return Resolved(False, detail="нет git-репозитория: {}".format(arg))
    try:
        out = subprocess.run(["git", "-C", repo, "rev-parse", "--short", "HEAD"],
                             capture_output=True, text=True, timeout=10)
    except Exception as exc:  # pragma: no cover
        return Resolved(False, detail="git недоступен: {}".format(exc))
    if out.returncode != 0:
        return Resolved(False, detail="git rev-parse не дал HEAD")
    return Resolved(True, value=out.stdout.strip(), detail="git {}".format(arg))


def _adapter_test_result(arg):
    """test.result(test_id): ТОЛЬКО заранее зарегистрированная проверка из
    PROJECTS/test_results.json. value = 'pass'/'fail'. Незарегистрированный
    test_id → found=False (асимметрия → не проверено). Модель не может выдать
    произвольный «успешный» результат — он должен быть зарегистрирован заранее."""
    path = os.environ.get("AIDA_TEST_RESULTS_FILE",
                          os.path.join(L.ROOT, "PROJECTS", "test_results.json"))
    if not os.path.exists(path):
        return Resolved(False, detail="нет реестра результатов тестов")
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        return Resolved(False, detail="реестр результатов не читается: {}".format(exc))
    results = data.get("results", {})
    if arg not in results:
        return Resolved(False, detail="тест {} не зарегистрирован".format(arg))
    return Resolved(True, value=str(results[arg]), detail="test {}".format(arg))


ADAPTERS = {
    "ledger.fact": _adapter_ledger_fact,
    "project.status": _adapter_project_status,
    "git.snapshot": _adapter_git_snapshot,
    "capability.exists": _adapter_capability_exists,
    "billing.manual_record": _adapter_billing_manual_record,
    "file.exists": _adapter_file_exists,
    "test.result": _adapter_test_result,
}
# Контракт: имена ADAPTERS совпадают с белым списком ТЗ (анти-ведро).
assert set(ADAPTERS) == set(ADAPTER_NAMES), "ADAPTERS разошлись с белым списком"


# --- доступ к структурной памяти (через ledger-ядро, без дубля) -------------
def _latest_active_fact_by_key(key):
    """Актуальный (последняя запись на id, не заменённый, не stale/superseded)
    факт с данным структурным key, либо None. Если активных с этим key несколько
    с РАЗНЫМ значением — это противоречие памяти; его ловит aida check (ошибка
    реестра), а здесь возвращаем None (источник неоднозначен → не проверено)."""
    if not key:
        return None
    raw = L.read_records("facts")
    superseded = L._superseded_ids(raw)
    active = []
    for rec in L._latest_by_id(raw):
        if rec.get("id") in superseded:
            continue
        if rec.get("status") in ("stale", "superseded"):
            continue
        if isinstance(rec.get("key"), str) and rec["key"].strip() == key:
            active.append(rec)
    if len(active) != 1:
        return None
    return active[0]


def _memory_value_for_key(key):
    """Нормализованное значение памяти по key (или None, если факта нет)."""
    rec = _latest_active_fact_by_key(key)
    if rec is None:
        return None, None
    return L.norm_value(rec.get("value")), rec


# --- горизонт даты опоры -----------------------------------------------------
def _is_dated_temporal(valid_until):
    """True, если valid_until — конкретная опора со сроком (дата или event:),
    т.е. опора ВРЕМЕННАЯ. None → бессрочная (не временная)."""
    return isinstance(valid_until, str) and bool(valid_until.strip())


# --- результат вердикта ------------------------------------------------------
class Verdict:
    def __init__(self, status, reason_code, detail="", evidence=None):
        self.status = status            # passed | unverified | stop
        self.reason_code = reason_code  # ключ из REASONS
        self.detail = detail
        self.evidence = evidence or {}

    def to_dict(self):
        return {
            "status": self.status,
            "reason_code": self.reason_code,
            "reason": REASONS.get(self.reason_code, self.reason_code),
            "detail": self.detail,
            "evidence": self.evidence,
        }


# --- валидация claim (асимметрия: невалидный → не проверено) -----------------
def validate_claim(claim):
    """Вернуть (ok, reason). Невалидный claim → не проверено (не «проверено»).
    Образец из crypto/classify.py: выход через схему, иначе отброс."""
    if not isinstance(claim, dict):
        return False, "claim не объект"
    t = claim.get("type")
    if t not in CLAIM_TYPES:
        return False, "type '{}' не из {}".format(t, CLAIM_TYPES)
    if claim.get("horizon") not in HORIZONS:
        return False, "horizon '{}' не из {}".format(claim.get("horizon"), HORIZONS)
    # supports — список строк, если задан.
    sup = claim.get("supports", [])
    if sup is not None and (not isinstance(sup, list)
                            or any(not isinstance(x, str) for x in sup)):
        return False, "supports должен быть списком ключей-строк"
    # adapter, если задан, — строка.
    if "adapter" in claim and claim.get("adapter") is not None \
            and not isinstance(claim.get("adapter"), str):
        return False, "adapter должен быть строкой"
    return True, ""


# --- ГЛАВНОЕ: вынести вердикт (детерминированно, кодом) ----------------------
def evaluate(claim):
    """Вынести вердикт по claim. Возвращает Verdict. Вердикт выносит ЭТОТ КОД.

    Порядок (асимметрия — любая неопределённость роняет в unverified/stop):
      0. невалидный claim                         → unverified
      1. type=reasoning                           → passed (гейт не применяется)
      2. контекст: опора временная как постоянная → stop
      3. capability: внешний костыль при встроенном → stop
      4. проверяемость факта/совета:
         - нет adapter и type=fact               → unverified (требует источника)
         - adapter не из белого списка           → unverified
         - нет expected                          → unverified
         - адаптер не нашёл/упал                 → unverified
         - значение ≠ expected                   → stop (противоречит источнику)
         - совпало                               → passed
      5. противоречие структурной памяти по key  → stop
    """
    ok, why = validate_claim(claim)
    if not ok:
        return Verdict("unverified", "UNVERIFIED_INVALID_CLAIM", why)

    ctype = claim["type"]

    # 1. Свободное рассуждение — мимо гейта (анти-тормоз).
    if ctype == "reasoning":
        return Verdict("passed", "OK_REASONING")

    # 2. КОНТЕКСТ — случай «200 временные». Совет/факт ОПИРАЕТСЯ на структурную
    #    память. Если хотя бы одна опора ВРЕМЕННАЯ (valid_until есть), а горизонт
    #    совета постоянный (horizon=permanent) — стоп: временное как постоянная
    #    основа без пометки. Механически, без модели.
    ctx_stop = _check_context(claim)
    if ctx_stop is not None:
        return ctx_stop

    # 3. ВОЗМОЖНОСТИ — случай «Телеграм». Для recommendation/action с инструментом:
    #    если предложен ВНЕШНИЙ инструмент под потребность, а есть ВСТРОЕННОЕ,
    #    закрывающее ту же потребность — стоп «сначала встроенное».
    if ctype in ("recommendation", "action"):
        cap_stop = _check_capability(claim)
        if cap_stop is not None:
            return cap_stop

    # 4. Противоречие СТРУКТУРНОЙ ПАМЯТИ по key (механически). СТРОГО ДО проверки
    #    источника: claim с собственным утверждением key=value, расходящимся с
    #    памятью, — это «противоречит памяти» (стоп), а не «нет источника». Стоп
    #    конкретнее и сильнее, чем «не проверено» (асимметрия в сторону строгости).
    mem_stop = _check_memory(claim)
    if mem_stop is not None:
        return mem_stop

    # 5. ПРОВЕРЯЕМОСТЬ против доверенного источника (анти-ведро).
    src_verdict = _check_source(claim)
    if src_verdict is not None:
        return src_verdict

    # Совет/действие без проверяемой опоры, но прошедшее контекст и возможности:
    # для type=fact это уже отсеяно в _check_source (нет adapter → unverified);
    # сюда доходят recommendation/action без источника-факта — они допустимы,
    # т.к. совет не обязан быть «фактом о мире»; capability/context уже проверены.
    return Verdict("passed", "OK_CAPABILITY_OK",
                   "совет прошёл контекст и возможности; фактических утверждений "
                   "к сверке не заявлено")


def _check_context(claim):
    """Контекст-ворота: временная опора как постоянная основа → stop. Иначе None."""
    supports = claim.get("supports") or []
    if not supports:
        return None
    horizon = claim.get("horizon")
    temporal_supports = []
    for key in supports:
        rec = _latest_active_fact_by_key(key)
        if rec is None:
            continue
        vu = rec.get("valid_until")
        if _is_dated_temporal(vu):
            temporal_supports.append((key, vu, rec.get("id")))
    if not temporal_supports:
        return None
    # Опора временная. Совет на постоянный горизонт без пометки временности → стоп.
    if horizon == "permanent":
        parts = ", ".join("{}(до {}, {})".format(k, vu, fid)
                          for k, vu, fid in temporal_supports)
        return Verdict(
            "stop", "STOP_TEMPORARY_AS_PERMANENT",
            "опора временная: {} — нельзя как постоянная основа без пометки".format(parts),
            evidence={"temporal_supports": [
                {"key": k, "valid_until": vu, "fact": fid}
                for k, vu, fid in temporal_supports]})
    return None


def _check_capability(claim):
    """Capability-ворота: внешний костыль при встроенном → stop. Иначе None.

    Для inструмента с потребностью need: если предложенный инструмент НЕ встроен
    (его статус ≠ встроено или его нет в реестре как встроенного), а в реестре
    есть ВСТРОЕННАЯ возможность, закрывающая тот же need — стоп «сначала встроенное».
    """
    tool = claim.get("tool")
    need = claim.get("need")
    if not tool or not need:
        return None
    builtin = C.builtin_covering(need)
    if not builtin:
        return None  # нет встроенного под эту потребность — внешнее законно
    # Есть встроенное под need. Предложенный tool сам встроен?
    cap = C.find_capability(tool)
    if cap is not None and cap.get("status") == C.BUILTIN:
        return None  # предложен сам встроенный инструмент — нормально
    builtin_names = ", ".join(b["name"] for b in builtin)
    return Verdict(
        "stop", "STOP_EXTERNAL_OVER_BUILTIN",
        "инструмент '{}' внешний под потребность '{}', а есть встроенное "
        "({}) — сначала встроенное".format(tool, need, builtin_names),
        evidence={"tool": tool, "need": need,
                  "builtin": [b["name"] for b in builtin]})


def _check_source(claim):
    """Проверяемость против доверенного источника (анти-ведро). Возвращает Verdict
    при вынесенном вердикте (passed/unverified/stop по источнику), иначе None
    (источник не заявлен и тип не fact — пусть решают остальные ворота)."""
    adapter = claim.get("adapter")
    ctype = claim["type"]

    if not adapter:
        if ctype == "fact":
            # type=fact без источника-из-белого-списка → требует источника,
            # наружу НЕ как факт, в память не пишется (асимметрия).
            return Verdict("unverified", "UNVERIFIED_NO_SOURCE",
                           "факт без источника-из-белого-списка")
        return None  # recommendation/action без фактической сверки — ок до прочих ворот

    # Адаптер заявлен. Он из белого списка?
    if adapter not in ADAPTERS:
        return Verdict("unverified", "UNVERIFIED_UNKNOWN_ADAPTER",
                       "адаптер '{}' не из белого списка {}".format(
                           adapter, ADAPTER_NAMES))

    expected = claim.get("expected", None)
    if expected is None:
        return Verdict("unverified", "UNVERIFIED_NO_EXPECTED",
                       "адаптер '{}' заявлен, но нет expected — нечего сверять".format(adapter))

    # Исполняем РЕЗОЛВЕР (не команду модели) против доверенного источника.
    arg = claim.get("arg")
    try:
        resolved = ADAPTERS[adapter](arg)
    except Exception as exc:  # любой глюк → не проверено (асимметрия)
        return Verdict("unverified", "UNVERIFIED_ADAPTER_FAILED",
                       "адаптер '{}' упал: {}".format(adapter, exc))

    if not resolved.found:
        return Verdict("unverified", "UNVERIFIED_ADAPTER_FAILED",
                       "источник не дал значения: {}".format(resolved.detail),
                       evidence={"adapter": adapter, "arg": arg})

    # Сверяем НОРМАЛИЗОВАННО (кодом). Совпало → проверено; нет → противоречит.
    got = L.norm_value(resolved.value)
    want = L.norm_value(expected)
    if got == want:
        return Verdict("passed", "OK_SOURCE_MATCH",
                       "источник подтвердил: {}={}".format(arg, resolved.value),
                       evidence={"adapter": adapter, "arg": arg,
                                 "source_value": resolved.value,
                                 "valid_until": resolved.valid_until})
    return Verdict("stop", "STOP_CONTRADICTS_SOURCE",
                   "источник даёт {!r}, заявлено {!r} — противоречит источнику".format(
                       resolved.value, expected),
                   evidence={"adapter": adapter, "arg": arg,
                             "source_value": resolved.value, "expected": expected})


def _check_memory(claim):
    """Противоречие СТРУКТУРНОЙ ПАМЯТИ по key (механически). Если claim несёт
    собственное утверждение key=value (claim_key/claim_value) и в памяти по тому
    же key другое значение — стоп «противоречит памяти». Без модели. Иначе None."""
    ck = claim.get("claim_key")
    if not ck:
        return None
    if "claim_value" not in claim:
        return None
    mem_norm, rec = _memory_value_for_key(ck)
    if mem_norm is None:
        return None  # в памяти нет такого key — нечему противоречить
    claim_norm = L.norm_value(claim.get("claim_value"))
    if claim_norm != mem_norm:
        return Verdict(
            "stop", "STOP_CONTRADICTS_MEMORY",
            "claim говорит {}={!r}, память (факт {}) говорит {!r} — противоречит "
            "памяти".format(ck, claim.get("claim_value"), rec.get("id"),
                            rec.get("value")),
            evidence={"key": ck, "claim_value": claim.get("claim_value"),
                      "memory_value": rec.get("value"), "fact": rec.get("id")})
    return None


# --- ВОРОТА ВЫХОДА (наружу / в память / в журнал ошибок) --------------------
# corrections/model_errors.jsonl — НОВЫЙ append-only журнал: автозапись при
# пойманной лжи (противоречит источнику/памяти / без источника / устарело).
# Лежит в corrections/ (критпуть — но это данные, пишутся дозаписью, И-14).
MODEL_ERRORS_FILE = os.environ.get(
    "AIDA_MODEL_ERRORS_FILE",
    os.path.join(L.ROOT, "corrections", "model_errors.jsonl"))

# Вердикты, при которых факт ловится как ложь/непроверенное и пишется в журнал.
# passed — НЕ пишется (норма). reasoning — мимо. Остальные unverified/stop — да.
_LOGGED_REASONS = {
    "UNVERIFIED_NO_SOURCE", "UNVERIFIED_UNKNOWN_ADAPTER",
    "UNVERIFIED_NO_EXPECTED", "UNVERIFIED_ADAPTER_FAILED",
    "STOP_CONTRADICTS_SOURCE", "STOP_CONTRADICTS_MEMORY",
    "STOP_TEMPORARY_AS_PERMANENT", "STOP_EXTERNAL_OVER_BUILTIN",
}


def record_model_error(claim, verdict):
    """Дозаписать пойманную ложь/непроверенное в corrections/model_errors.jsonl
    (append-only, И-14). Возвращает True, если запись сделана. Невинные вердикты
    (passed/OK_*) не пишутся."""
    if verdict.reason_code not in _LOGGED_REASONS:
        return False
    os.makedirs(os.path.dirname(MODEL_ERRORS_FILE), exist_ok=True)
    rec = {
        "recorded_at": L.now_iso(),
        "verdict": verdict.status,
        "reason_code": verdict.reason_code,
        "reason": REASONS.get(verdict.reason_code, verdict.reason_code),
        "detail": verdict.detail,
        "claim_type": claim.get("type"),
        "claim_text": claim.get("text", ""),
        "evidence": verdict.evidence,
    }
    line = json.dumps(rec, ensure_ascii=False, sort_keys=True)
    with open(MODEL_ERRORS_FILE, "a", encoding="utf-8") as fh:
        fh.write(line + "\n")
    return True


# Плашки статуса для подстановки в черновик наружу.
_PLAQUE = {
    "passed": "[проверено]",
    "unverified": "[не проверено]",
    "stop": "[СТОП]",
}


def render_outward(claim, verdict):
    """Пересобрать черновик наружу со статус-плашкой (ворота выхода).

    - passed   → текст как есть с плашкой [проверено];
    - unverified → факт выпускается ТОЛЬКО как «не проверено: …», не как факт;
    - stop     → ответ НЕ выпускается: отказ с причиной (текст модели подавлен).
    """
    text = claim.get("text", "")
    if verdict.status == "passed":
        return "{} {}".format(_PLAQUE["passed"], text).strip()
    if verdict.status == "unverified":
        return "{} {}\n(причина: {})".format(
            _PLAQUE["unverified"], text, verdict.detail or REASONS.get(verdict.reason_code))
    # stop — ответ не выпускается наружу, только отказ с причиной.
    return "{} ответ не выпущен. Причина: {}".format(
        _PLAQUE["stop"], verdict.detail or REASONS.get(verdict.reason_code))


def gate(claim):
    """ПОЛНЫЕ ворота: вердикт + побочные эффекты выхода.

    Возвращает dict с verdict, наружным текстом, флагами записи. ПИШЕТ:
      - в corrections/model_errors.jsonl — при пойманной лжи/непроверенном;
    НЕ пишет факт в facts.jsonl автоматически — это делает оператор/доверенный
    контур командой `aida fact` ТОЛЬКО при passed (в память идёт только
    «проверено»; здесь возвращаем флаг memory_eligible, а сам факт пишет aida,
    чтобы И-5/замок/структурная память применились единым путём).
    """
    verdict = evaluate(claim)
    logged = record_model_error(claim, verdict)
    memory_eligible = (
        verdict.status == "passed"
        and claim.get("type") == "fact"
        and bool(claim.get("claim_key") or claim.get("arg"))
    )
    return {
        "verdict": verdict.to_dict(),
        "outward": render_outward(claim, verdict),
        "logged_error": logged,
        "memory_eligible": memory_eligible,
    }


# --- CLI (для тестов и оператора) -------------------------------------------
def cmd_gate(args):
    """Полные ворота выхода: вердикт + наружный текст + журнал ошибок.

    Код выхода кодирует вердикт машинно: 0 passed, 3 unverified, 4 stop.
    """
    payload = _read_payload(args)
    try:
        claim = json.loads(payload)
    except ValueError as exc:
        v = Verdict("unverified", "UNVERIFIED_INVALID_CLAIM",
                    "claim не JSON: {}".format(exc))
        result = {"verdict": v.to_dict(), "outward": render_outward({}, v),
                  "logged_error": False, "memory_eligible": False}
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 3
    result = gate(claim)
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        v = result["verdict"]
        print("ВЕРДИКТ: {} [{}]".format(v["status"], v["reason_code"]))
        print("  {}".format(v["reason"]))
        print("--- наружу ---")
        print(result["outward"])
        if result["logged_error"]:
            print("(записано в corrections/model_errors.jsonl)")
    return {"passed": 0, "unverified": 3, "stop": 4}[result["verdict"]["status"]]


def _read_payload(args):
    if args.file and args.file != "-":
        with open(args.file, "r", encoding="utf-8") as fh:
            return fh.read()
    return sys.stdin.read()


def cmd_eval(args):
    """Прочитать claim (JSON из файла/stdin), вынести вердикт, напечатать его.

    Код выхода кодирует вердикт МАШИННО (вердикт выносит код):
      0 — passed; 3 — unverified; 4 — stop.
    """
    payload = _read_payload(args)
    try:
        claim = json.loads(payload)
    except ValueError as exc:
        # Битый JSON claim — это тоже невалидный claim → не проверено.
        v = Verdict("unverified", "UNVERIFIED_INVALID_CLAIM",
                    "claim не JSON: {}".format(exc))
        print(json.dumps(v.to_dict(), ensure_ascii=False, indent=2))
        return 3

    v = evaluate(claim)
    out = v.to_dict()
    if args.json:
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        print("ВЕРДИКТ: {} [{}]".format(out["status"], out["reason_code"]))
        print("  {}".format(out["reason"]))
        if out["detail"]:
            print("  {}".format(out["detail"]))
    return {"passed": 0, "unverified": 3, "stop": 4}[v.status]


def cmd_adapters(_args):
    """Напечатать белый список адаптеров (для проверки анти-ведра)."""
    for name in ADAPTER_NAMES:
        print(name)
    return 0


def build_parser():
    p = argparse.ArgumentParser(
        prog="aida-kernel", description="ядро правды v0.1 — вердикт перехода к опоре")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("eval", help="вынести вердикт по claim (JSON из файла/stdin)")
    s.add_argument("--file", default="-", help="файл с claim-JSON (- = stdin)")
    s.add_argument("--json", action="store_true", help="вывод вердикта в JSON")
    s.set_defaults(func=cmd_eval)

    s = sub.add_parser("gate", help="полные ворота выхода: вердикт + наружу + журнал ошибок")
    s.add_argument("--file", default="-", help="файл с claim-JSON (- = stdin)")
    s.add_argument("--json", action="store_true", help="вывод результата в JSON")
    s.set_defaults(func=cmd_gate)

    s = sub.add_parser("adapters", help="печать белого списка адаптеров")
    s.set_defaults(func=cmd_adapters)

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
