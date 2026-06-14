#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Читатель РЕЕСТРА ВОЗМОЖНОСТЕЙ (PROJECTS/capabilities.json).

Единственная точка чтения реестра возможностей. Ядро правды (scripts/aida_kernel.py)
зовёт отсюда find_capability/builtin_covering, а не держит свою копию списка.
Реестр — единственный источник правды о том, что система умеет встроенно и что
требует внешней обвязки (столб «Возможности» ядра правды, D-20260614-003).
Только стандартная библиотека python3 (без pip/jq).

Путь к реестру: PROJECTS/capabilities.json в корне репо, переопределяется
AIDA_CAPABILITIES_FILE (для тестов на временной копии).

Поля возможности (см. шапку самого capabilities.json):
  name, status, covers, name_ru, note.

status ∈ STATUSES; единственный «уже доступно без внешней обвязки» — BUILTIN.

Подкоманды (для bash/тестов, вывод без jq):
  status <name>
      Печатает status возможности (без перевода строки). Неизвестное имя →
      код выхода 2 (понятный отказ в stderr).
  builtin-covers <need>
      Печатает name встроенной (status=встроено) возможности, закрывающей
      потребность <need> (по полю covers), по одной на строку. Пусто, если
      встроенной под эту потребность нет.

Exit codes:
  0  — успех;
  2  — реестр недоступен/повреждён ИЛИ неизвестное имя (понятный отказ в stderr).
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_FILE = os.path.join(ROOT, "PROJECTS", "capabilities.json")
CAPABILITIES_FILE = os.environ.get("AIDA_CAPABILITIES_FILE", DEFAULT_FILE)

# Допустимые статусы возможности (дословно из шапки capabilities.json).
BUILTIN = "встроено"
STATUSES = {"встроено", "внешнее", "нужен-апи", "нужна-подписка",
            "нужна-настройка", "костыль"}


def _die(msg):
    sys.stderr.write("ОШИБКА (реестр возможностей): {}\n".format(msg))
    raise SystemExit(2)


def load_capabilities():
    """Список возможностей из реестра в порядке файла. Отказ при отсутствии/порче
    — чтобы вызывающий честно сказал «не прочитал», а не выдумал список."""
    if not os.path.exists(CAPABILITIES_FILE):
        _die("файл реестра не найден: {}".format(CAPABILITIES_FILE))
    try:
        with open(CAPABILITIES_FILE, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        _die("файл реестра {} не читается/не JSON: {}".format(CAPABILITIES_FILE, exc))
    caps = data.get("capabilities")
    if not isinstance(caps, list):
        _die("в реестре {} нет массива 'capabilities'".format(CAPABILITIES_FILE))
    for i, cap in enumerate(caps):
        if not isinstance(cap, dict) or not cap.get("name"):
            _die("возможность #{} в реестре без поля 'name'".format(i))
    return caps


def find_capability(name):
    """Возможность по имени (или None)."""
    for cap in load_capabilities():
        if cap.get("name") == name:
            return cap
    return None


def builtin_covering(need):
    """Список ВСТРОЕННЫХ (status=встроено) возможностей, закрывающих потребность
    need (по полю covers). Пустой список, если встроенной под эту потребность нет.
    Используется capability-воротами ядра: внешний костыль под need нельзя
    предлагать первым, если есть встроенное, закрывающее тот же need."""
    out = []
    for cap in load_capabilities():
        if cap.get("status") == BUILTIN and cap.get("covers") == need:
            out.append(cap)
    return out


def cmd_status(args):
    if len(args) != 1:
        _die("status требует <name>")
    cap = find_capability(args[0])
    if cap is None:
        _die("неизвестная возможность '{}'".format(args[0]))
    sys.stdout.write(str(cap.get("status", "")))
    return 0


def cmd_builtin_covers(args):
    if len(args) != 1:
        _die("builtin-covers требует <need>")
    for cap in builtin_covering(args[0]):
        sys.stdout.write(cap["name"] + "\n")
    return 0


COMMANDS = {
    "status": cmd_status,
    "builtin-covers": cmd_builtin_covers,
}


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] not in COMMANDS:
        sys.stderr.write(
            "usage: aida_capabilities.py {status <name> | builtin-covers <need>}\n")
        return 2
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    sys.exit(main())
