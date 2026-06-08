#!/usr/bin/env bash
# Shared helper for pushing the current branch to multiple remotes.
#
# Sourced (not executed) from:
#   - scripts/take-shift.sh
#   - scripts/release-shift.sh
#   - scripts/approve-critical.sh
#
# Не использовать `set -e` здесь — наследует поведение из caller'а.
#
# Function: push_both BRANCH
#   Отправляет BRANCH в каждый remote из AIDS_REMOTES (по умолчанию
#   "origin backup"). Порядок важен — первый в списке считается источником
#   правды для совместной работы, его сбои — фатальные. Последующие —
#   мягкие (резервные копии, сетевые сбои терпимы).
#
#   Семантика:
#   - origin успешно принял + backup успешно принял → return 0
#   - origin принял + backup упал по сети  → return 0 (warn, не блокер)
#   - origin отверг (rejected/non-fast-forward) → return 75
#   - backup отверг (rejected/non-fast-forward) → return 0 (warn; origin уже принял)
#   - origin недоступен по сети → return 75 (источник правды нужен живой)
#   - AIDS_SKIP_PUSH=1 → return 0 без действий (для acceptance-тестов)
#
# Возвращаемые коды:
#   0   — все попытки прошли (с возможными warn по второстепенным remote)
#   75  — фатально (первый remote отверг или недоступен по сети)

push_both() {
  local branch="$1"
  if [[ -z "${branch}" ]]; then
    echo "ERROR (push_both): нужно указать ветку" >&2
    return 65
  fi

  if [[ "${AIDS_SKIP_PUSH:-0}" == "1" ]]; then
    echo "  (push пропущен — AIDS_SKIP_PUSH=1, режим тестирования)"
    return 0
  fi

  local remotes_list="${AIDS_REMOTES:-origin backup}"
  local first_remote=""

  for remote in ${remotes_list}; do
    [[ -z "${first_remote}" ]] && first_remote="${remote}"

    # Remote должен быть настроен.
    if ! git remote get-url "${remote}" >/dev/null 2>&1; then
      if [[ "${remote}" == "${first_remote}" ]]; then
        echo "  ERROR: remote '${remote}' (источник правды) не настроен" >&2
        echo "         Проверь 'git remote -v' и при необходимости 'git remote add ${remote} <url>'" >&2
        return 75
      else
        echo "  WARN: remote '${remote}' не настроен — пропускаю"
        continue
      fi
    fi

    local push_out
    if push_out="$(git push "${remote}" "${branch}" 2>&1)"; then
      echo "  push ${remote}: OK"
      continue
    fi

    # Push не прошёл — классифицируем ошибку.
    if echo "${push_out}" | grep -qE 'rejected|non-fast-forward'; then
      # Конфликт (кто-то опередил). Фатально ТОЛЬКО для источника правды
      # (первый remote). Если первый принял, а резервный отверг — источник
      # правды уже содержит мутацию, это не блокер: иначе помощник врёт о
      # состоянии («остановлено», хотя origin уже принял — баг ADS-PUSH-1).
      if [[ "${remote}" == "${first_remote}" ]]; then
        echo "${push_out}" >&2
        echo "" >&2
        echo "  ERROR: ${remote} (источник правды) отверг push (кто-то опередил):" >&2
        echo "    git pull --rebase ${remote} ${branch}" >&2
        echo "    разреши конфликт если будет, повтори операцию" >&2
        return 75
      else
        echo "  WARN: ${remote} (резерв) отверг push — источник правды уже принял, не блокер:"
        echo "${push_out}" | sed 's/^/    /' | head -3
        echo "    синхронизируй резерв позже: git pull --rebase ${remote} ${branch} && git push ${remote} ${branch}"
        continue
      fi
    fi

    if echo "${push_out}" | grep -qiE 'could not resolve host|connection refused|network is unreachable|operation timed out|unable to access|could not read'; then
      # Сетевая ошибка.
      if [[ "${remote}" == "${first_remote}" ]]; then
        echo "${push_out}" >&2
        echo "  ERROR: ${remote} (источник правды) недоступен — операцию нельзя завершить без него" >&2
        echo "  Проверь сеть и повтори." >&2
        return 75
      else
        echo "  WARN: ${remote} недоступен по сети — пропускаю (догонит позже):"
        echo "${push_out}" | sed 's/^/    /' | head -3
        continue
      fi
    fi

    # Прочая ошибка.
    echo "${push_out}" >&2
    if [[ "${remote}" == "${first_remote}" ]]; then
      echo "  ERROR: push ${remote} (источник правды) не удался — см. ошибку выше" >&2
      return 75
    else
      echo "  WARN: push ${remote} не удался, не блокер для совместной работы"
    fi
  done

  return 0
}
