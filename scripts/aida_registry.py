#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Читатель ЕДИНОГО реестра проектов (PROJECTS/projects.json).

Единственная точка чтения реестра: bash-слои (scripts/aida-brief и далее) зовут
этот скрипт, а не держат свою копию списка проектов. Реестр — единственный
источник правды о том, какие проекты есть и где они лежат (П2 аудита,
D-20260613-008). Только стандартная библиотека python3 (без pip/jq).

Путь к реестру: PROJECTS/projects.json в корне репо, переопределяется
AIDA_PROJECTS_FILE (для тестов на временной копии).

Поля проекта (см. шапку самого projects.json):
  slug, name_ru, repo, tl_role, overlay, mailbox, snapshot.
В repo раскрывается ${HOME} (и $HOME) — путь в реестре хранится переносимо.

Подкоманды (вывод заточен под потребление из bash, без jq):
  slugs
      Печатает слаги по одному на строку В ПОРЯДКЕ реестра (порядок строк
      экрана сводки). Замена захардкоженному ALL_SLUGS.

  field <slug> <field>
      Печатает ОДНО значение поля проекта (без перевода строки в конце для
      строковых; для snapshot — 'true'/'false'). Для repo ${HOME} уже раскрыт.
      Неизвестный slug/field — код выхода 2, сообщение в stderr.

  has <slug>
      Код выхода 0, если slug есть в реестре, иначе 1 (тихо). Для проверки
      --scope.

Exit codes:
  0  — успех;
  2  — реестр недоступен/повреждён ИЛИ неизвестный slug/field (понятный отказ
       в stderr; вызывающий bash честно деградирует, а не выдумывает).
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_FILE = os.path.join(ROOT, "PROJECTS", "projects.json")
PROJECTS_FILE = os.environ.get("AIDA_PROJECTS_FILE", DEFAULT_FILE)

# Поля проекта, которые умеет отдавать `field`. snapshot — булево (true/false).
STR_FIELDS = ("slug", "name_ru", "repo", "tl_role", "overlay", "mailbox")
BOOL_FIELDS = ("snapshot",)
ALL_FIELDS = STR_FIELDS + BOOL_FIELDS


def _die(msg):
    sys.stderr.write("ОШИБКА (реестр проектов): {}\n".format(msg))
    raise SystemExit(2)


def _expand_home(value):
    """Раскрыть ${HOME}/$HOME в строковом пути. Реестр хранит путь переносимо."""
    home = os.environ.get("HOME", os.path.expanduser("~"))
    return value.replace("${HOME}", home).replace("$HOME", home)


def load_projects():
    """Список проектов из реестра в порядке файла. Отказ при отсутствии/порче —
    чтобы вызывающий честно сказал «не прочитал», а не выдумал список."""
    if not os.path.exists(PROJECTS_FILE):
        _die("файл реестра не найден: {}".format(PROJECTS_FILE))
    try:
        with open(PROJECTS_FILE, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        _die("файл реестра {} не читается/не JSON: {}".format(PROJECTS_FILE, exc))
    projects = data.get("projects")
    if not isinstance(projects, list) or not projects:
        _die("в реестре {} нет непустого массива 'projects'".format(PROJECTS_FILE))
    for i, proj in enumerate(projects):
        if not isinstance(proj, dict) or not proj.get("slug"):
            _die("проект #{} в реестре без поля 'slug'".format(i))
    return projects


def find_project(slug):
    for proj in load_projects():
        if proj.get("slug") == slug:
            return proj
    return None


def cmd_slugs(_args):
    for proj in load_projects():
        sys.stdout.write(proj["slug"] + "\n")
    return 0


def cmd_field(args):
    if len(args) != 2:
        _die("field требует <slug> <field>")
    slug, field = args
    if field not in ALL_FIELDS:
        _die("неизвестное поле '{}'. Допустимо: {}.".format(
            field, " ".join(ALL_FIELDS)))
    proj = find_project(slug)
    if proj is None:
        _die("неизвестный slug '{}'".format(slug))
    if field in BOOL_FIELDS:
        sys.stdout.write("true" if proj.get(field) else "false")
        return 0
    value = proj.get(field, "")
    if not isinstance(value, str):
        value = "" if value is None else str(value)
    if field == "repo":
        value = _expand_home(value)
    sys.stdout.write(value)
    return 0


def cmd_has(args):
    if len(args) != 1:
        _die("has требует <slug>")
    return 0 if find_project(args[0]) is not None else 1


COMMANDS = {
    "slugs": cmd_slugs,
    "field": cmd_field,
    "has": cmd_has,
}


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] not in COMMANDS:
        sys.stderr.write(
            "usage: aida_registry.py {slugs | field <slug> <field> | has <slug>}\n")
        return 2
    return COMMANDS[argv[0]](argv[1:])


if __name__ == "__main__":
    sys.exit(main())
