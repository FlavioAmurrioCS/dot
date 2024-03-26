#!/usr/bin/env bash
# shellcheck disable=SC3033
# shellcheck disable=SC2317
# TODO: Make sure this works for bash,zsh
# TODO: Add check for which shell is being used
# TODO: Add shims for fzf and gum
# TODO: Use gum for enhanced user experience
# TODO: Add support for zsh

###############################################################################
# region: SCRIPT SETUP DO NOT EDIT
###############################################################################
__DEV_SH_CURRENT_SHELL__=${__DEV_SH_CURRENT_SHELL__:-$(ps -o args= -p "$$" | cut -d' ' -f1 | xargs basename)}
__DEV_SH_CURRENT_SHELL__=${__DEV_SH_CURRENT_SHELL__:-bash}
__DEV_SH_SCRIPT__="${__DEV_SH_SCRIPT__:-${0}}"
__DEV_SH_IS_SOURCED__='false'

case "${__DEV_SH_CURRENT_SHELL__}" in
  sh|-sh)
  (return 0 2>/dev/null) && __DEV_SH_IS_SOURCED__='true'
  if [ "${__DEV_SH_IS_SOURCED__}" = 'true' ]; then
    __DEV_SH_SCRIPT__="CAN'T BE DETERMINED"
  fi
  ;;
  bash|-bash)
  (return 0 2>/dev/null) && __DEV_SH_IS_SOURCED__='true'
  # shellcheck disable=SC3028
  # shellcheck disable=SC3054
  __DEV_SH_SCRIPT__="${BASH_SOURCE[0]}"
  ;;
  zsh|-zsh)
  # shellcheck disable=SC3010
  [[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT =~ :file$ ]] && __DEV_SH_IS_SOURCED__='true'
  # shellcheck disable=SC2296
  __DEV_SH_SCRIPT__="${(%):-%N}"
  ;;
  ksh)
  # shellcheck disable=SC3010
  # shellcheck disable=SC2296
  [[ -n $KSH_VERSION && $(cd "$(dirname -- "$0")" && printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] && __DEV_SH_IS_SOURCED__='true'
  # shellcheck disable=SC2296
  __DEV_SH_SCRIPT__="${.sh.file}"
  ;;
  *)
  echo "NOT IMPLEMENTED: ${__DEV_SH_CURRENT_SHELL__}" >&2
  ;;
esac

__DEV_SH_SCRIPT_DIR__="$(cd "$(dirname "${__DEV_SH_SCRIPT__}")" >/dev/null 2>&1 && pwd -P)"
__DEV_SH_SCRIPT__="${__DEV_SH_SCRIPT_DIR__}/$(basename "${__DEV_SH_SCRIPT__}")"
__DEV_SH_FUNCTION_LIST__=()
while IFS='' read -r line; do
  __DEV_SH_FUNCTION_LIST__+=("$line")
done < <(grep -E '^[^ ]+\(\) {' "${__DEV_SH_SCRIPT__}" | cut -d' ' -f1 | cut -d'(' -f1 | grep -vE "^_")

case "${RUNNING_OS:="$(uname -s)"}" in
Darwin)
  export APPLICATION_DIR="${HOME}/Applications"
  export HOMEBREW_HOME="${APPLICATION_DIR}/brew"
  export HOMEBREW_PREFIX="${HOMEBREW_HOME}"
  export HOMEBREW_CASK_OPTS="--appdir=${APPLICATION_DIR}"
  export PATH="${HOMEBREW_HOME}/bin:${PATH}"
  ;;
Linux)
  : Do nothing
  ;;
*)
  : "${RUNNING_OS} is not configured." >&2
  ;;
esac

export TOOL_INSTALLER_OPT_DIR="${TOOL_INSTALLER_OPT_DIR:-${HOME}/opt/runtool}"
export TOOL_INSTALLER_BIN_DIR="${TOOL_INSTALLER_BIN_DIR:-${TOOL_INSTALLER_OPT_DIR}/bin}"
export TOOL_INSTALLER_PIPX_HOME="${TOOL_INSTALLER_PIPX_HOME:-${TOOL_INSTALLER_OPT_DIR}/pipx_home}"
export TOOL_INSTALLER_PACKAGE_DIR="${TOOL_INSTALLER_PACKAGE_DIR:-${TOOL_INSTALLER_OPT_DIR}/packages}"
export TOOL_INSTALLER_GIT_PROJECT_DIR="${TOOL_INSTALLER_GIT_PROJECT_DIR:-${TOOL_INSTALLER_OPT_DIR}/git_projects}"
export PIPX_BIN_DIR="${PIPX_BIN_DIR:-${TOOL_INSTALLER_BIN_DIR}}"
export PIPX_HOME="${PIPX_HOME:-${TOOL_INSTALLER_PIPX_HOME}}"
export PATH="${TOOL_INSTALLER_BIN_DIR}:${HOME}/.local/bin:${PATH}"
export HATCH_ENV_TYPE_VIRTUAL_PATH="venv"
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --exact"

###############################################################################
# endregion: SCRIPT SETUP DO NOT EDIT
###############################################################################

###############################################################################
# region: FUNCTIONS THAT ARE COMMON FOR BOTH SOURCED AND EXECUTED
###############################################################################
_select_project() {
  __selected="$(find ~/{dev,worktrees,projects,dev/*git*/*} -maxdepth 3 \( -name .git -or -name packed-refs \) -prune -exec dirname {} \; 2>/dev/null | grep -v /trash/ | fzf --keep-right)"
  [ -n "${__selected}" ] && echo "${__selected}" && return 0
  return 1
}

,noerror() { "${@}" 2>/dev/null; }
,nooutput() { "${@}" >/dev/null 2>&1; }
,cache_clear() { ,nooutput rm -rf "${HOME}/.cache/dev.sh"; }
,uniq() { awk '!x[$0]++' "${@}"; }
grep() { command grep --color=auto --line-buffered "${@}"; }

,cache() {
  if [ -n "${NO_CACHE}" ]; then
    "${@}"
    return $?
  fi
  local cache_dir="${HOME}/.cache/dev.sh" \
    cache_file \
    temp_cache_file \
    temp_return_code \
    cmd_exit_code
  # TODO: Consider adding cache expiration
  # case "${1}" in
  # --permanent) shift 1 && cmd_str_to_be_hash="${*}" ;;
  # --hourly) shift 1 && cmd_str_to_be_hash="$(date +'%Y_%m_%d_%H') ${*}" ;;
  # *) cmd_str_to_be_hash="$(date +'%Y_%m_%d') ${*}" ;;
  # esac
  # command_hash=$(echo "${cmd_str_to_be_hash}" | md5sum | grep -oE '[a-z0-9]+')
  # cache_file="${cache_dir}/$(shUtil.joinBy '_' "${@}")_${command_hash}"
  cache_file="${cache_dir}/$(echo "${@}" | { md5sum 2>/dev/null || md5; } | cut -d' ' -f1)"

  if [ -f "${cache_file}" ]; then
    cat "${cache_file}"
    return 0
  fi

  temp_return_code=$(mktemp)
  temp_cache_file=$(mktemp)
  {
    echo -n "1" >"${temp_return_code}"
    "${@}"
    echo -n "$?" >"${temp_return_code}"
  } | tee "${temp_cache_file}"
  cmd_exit_code="$(head -n 1 "${temp_return_code}")"
  if [ "${cmd_exit_code}" -eq 0 ]; then
    mkdir -p "${cache_dir}"
    mv "${temp_cache_file}" "${cache_file}"
  fi

  return "${cmd_exit_code}"
}

__get_repos__() {
  local domain user repo api_url complete_url_user complete_url_org curl_cmd
  read -r domain user repo <<<"$(echo "${1}" | awk -F[/:] '{print $4,$5,$6}')"
  curl_cmd=(curl --silent --fail)

  case "${domain}" in
  github.com) api_url="https://api.github.com" ;;
  *)
    api_url="https://${domain}/api/v3"
    curl_cmd+=(-H "Authorization: token ${GITHUB_TOKEN}")
    ;;
  esac
  complete_url_user="${api_url}/users/${user}/repos?per_page=99999"
  complete_url_org="${api_url}/orgs/${user}/repos?per_page=99999"
  "${curl_cmd[@]}" "${complete_url_org}" || "${curl_cmd[@]}" "${complete_url_user}"
}

,clone() {
  local project domain owner repo project_path projects
  projects=${1:-"$({
    for i in $(echo "${GITHUB_FOLLOW}" | tr ' ' '\n' | sort -u); do
      ,cache __get_repos__ "${i}" &
    done
  } | grep "ssh_url" | cut -d '"' -f4 | sort -u | fzf --multi --exit-0)"}

  if [ -z "${projects}" ] && [ -z "${GITHUB_FOLLOW}" ]; then
    echo "Set GITHUB_FOLLOW to a list of github users/orgs to follow or pass in clone url directly. If github enterprise, set GITHUB_TOKEN as well." >&2
    return 1
  fi

  for project in ${projects}; do
    case "${project}" in
    https*) read -r domain owner repo <<<"$(echo "${project}" | sed -E 's|https://([^/]+)/(.+)\/(.+).*|\1 \2 \3|')" ;;
    *) read -r domain owner repo <<<"$(echo "${project}" | sed -E 's/.*@(.+):(.+)\/(.+)\.git/\1 \2 \3/')" ;;
    esac

    project_path="${HOME}/dev/${domain}/${owner}/${repo}"
    if [ ! -d "${project_path}" ]; then
      git clone "${project}" "${project_path}"
    fi
  done
}

,mv-project() {
  local domain owner repo new_project_path git_remote original_project_path
  for original_project_path in "${@}"; do
    echo "- ${original_project_path}"
    original_project_path=$(realpath "${original_project_path}")
    git_remote=$(git -C "${original_project_path}" remote get-url origin 2>/dev/null)
    if [ -z "${git_remote}" ]; then
      echo "${original_project_path} does not have a remote origin" >&2
      continue
    fi
    case "${git_remote}" in
    https*) read -r domain owner repo <<<"$(echo "${git_remote}" | sed -E 's|https://([^/]+)/(.+)\/(.+).*|\1 \2 \3|')" ;;
    *) read -r domain owner repo <<<"$(echo "${git_remote}" | sed -E 's/.*@(.+):(.+)\/(.+)\.git/\1 \2 \3/')" ;;
    esac
    new_project_path="${HOME}/dev/${domain}/${owner}/$(basename "${original_project_path}")"
    if [ ! -d "${new_project_path}" ]; then
      mkdir -p "$(dirname "${new_project_path}")"
      mv "${original_project_path}" "${new_project_path}"
    else
      echo "${new_project_path} already exists. Skipping..." >&2
    fi
  done
}

,runtool() { command runtool "${@}"; }

###############################################################################
# endregion: FUNCTIONS THAT ARE COMMON FOR BOTH SOURCED AND EXECUTED
###############################################################################

if [ "${__DEV_SH_IS_SOURCED__}" = 'true' ]; then
  : File is being sourced
  ###############################################################################
  # region: FUNCTIONS THAT SHOULD ONLY BE AVAILABLE WHEN FILE IS BEING SOURCED
  ###############################################################################
  ,cd() {
    __selected="$(_select_project)"
    [ -n "${__selected}" ] && cd "${__selected}" && return 0
    return 1
  }

  ,activate() {
    __walker=${PWD}
    while true; do
      __found="$(find . -type f -name activate -not -path './.tox/*' -print -quit)"
      # shellcheck disable=SC1090
      [ -n "${__found}" ] && source "${__found}" && return 0
      [ "${__walker}" = "/" ] && return 1
      __walker="$(dirname "${__walker}")"
    done
  }

  ,code() {
    __selected="$(_select_project)"
    [ -n "${__selected}" ] && code "${__selected}" "${@}" && return 0
    return 1
  }

  ,env() { env | fzf --multi; }
  ,web() {
    __git_url=$(git remote get-url origin) || return 1
    case "${__git_url}" in
    https*) : ;;
    *) __git_url="$(echo "${__git_url}" | sed -E 's|.*@(.+):(.+)\/(.+)\.git|https://\1/\2/\3|')" ;;
    esac
    ,runtool run rifle "${__git_url}"
  }

  echo 'sourcing dev.sh' >&2

  # shellcheck disable=SC1091
  [ -f "${HOME}/.secretsrc" ] && . "${HOME}/.secretsrc"
  # shellcheck disable=SC1091
  [ -f "${HOME}/.localrc" ] && . "${HOME}/.localrc"
  THEME_SH_THEME='atelier-sulphurpool'
  [ -n "${THEME_SH_THEME}" ] && which theme.sh >/dev/null 2>&1 && theme.sh "${THEME_SH_THEME}"

  # shellcheck disable=SC2139
  alias ,source="source ${__DEV_SH_SCRIPT__}"
  alias ,dotfiles='git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}"'
  alias ,dotfiles_code='GIT_DIR=${HOME}/.cfg/ GIT_WORK_TREE=${HOME} code ${HOME}'
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'
  alias .....='cd ../../../..'
  alias ......='cd ../../../../..'
  alias .......='cd ../../../../../..'

  case "$__DEV_SH_CURRENT_SHELL__" in
  bash)
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # ================================== history ===================================
    # https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
    export HISTSIZE=9000
    export HISTFILESIZE="${HISTSIZE}"
    export HISTCONTROL=ignorespace:ignoredups

    _bash_history_sync() {
      builtin history -a         #1
      HISTFILESIZE="${HISTSIZE}" #2
      builtin history -c         #3
      builtin history -r         #4
    }

    history() { #5
      _bash_history_sync
      builtin history "$@"
    }
    PROMPT_COMMAND=_bash_history_sync
    ## reedit a history substitution line if it failed
    shopt -s histreedit
    ## edit a recalled history line before executing
    shopt -s histverify

    shopt -s extglob

    [[ $- == *i* ]] &&
      bind '"\e[A": history-search-backward' &&
      bind '"\e[B": history-search-forward'

    # https://gist.github.com/vratiu/9780109
    # __TPUT_BOLD="$(tput bold)"
    # __TPUT_BLACK="${__TPUT_BOLD}$(tput setaf 8)"
    # __TPUT_RED="${__TPUT_BOLD}$(tput setaf 9)"
    # __TPUT_GREEN="${__TPUT_BOLD}$(tput setaf 10)"
    # __TPUT_YELLOW="${__TPUT_BOLD}$(tput setaf 11)"
    # __TPUT_BLUE="${__TPUT_BOLD}$(tput setaf 12)"
    # __TPUT_MAGENTA="${__TPUT_BOLD}$(tput setaf 13)"
    # __TPUT_CYAN="${__TPUT_BOLD}$(tput setaf 14)"
    # __TPUT_WHITE="${__TPUT_BOLD}$(tput setaf 15)"
    # __TPUT_RESET=$(tput sgr0)
    __TPUT_BOLD="\e[1m"
    __TPUT_BLACK="\[\e[1;90m\]"
    __TPUT_RED="\[\e[1;91m\]"
    __TPUT_GREEN="\[\e[1;92m\]"
    __TPUT_YELLOW="\[\e[1;93m\]"
    __TPUT_BLUE="\[\e[1;94m\]"
    __TPUT_MAGENTA="\[\e[1;95m\]"
    __TPUT_CYAN="\[\e[1;96m\]"
    __TPUT_WHITE="\[\e[1;97m\]"
    __TPUT_RESET="\e[0m"
    __PS1_BOLD="\[${__TPUT_BOLD}\]"
    __PS1_BLACK="\[${__TPUT_BLACK}\]"
    __PS1_RED="\[${__TPUT_RED}\]"
    __PS1_GREEN="\[${__TPUT_GREEN}\]"
    __PS1_YELLOW="\[${__TPUT_YELLOW}\]"
    __PS1_BLUE="\[${__TPUT_BLUE}\]"
    __PS1_MAGENTA="\[${__TPUT_MAGENTA}\]"
    __PS1_CYAN="\[${__TPUT_CYAN}\]"
    __PS1_WHITE="\[${__TPUT_WHITE}\]"
    __PS1_RESET="\[${__TPUT_RESET}\]"
    __PS1_USERNAME="${__PS1_YELLOW}\u"
    __PS1_AT="${__PS1_GREEN}@"
    __PS1_HOSTNAME="${__PS1_BLUE}\${MACHINE_NAME:-\h}"
    __PS1_WORKSPACE="${__TPUT_MAGENTA}\w"
    __PS1_PROMPT="${__PS1_RESET}${__PS1_BOLD}\n$ ${__PS1_RESET}"
    __PS1_WRAPPER_START="${__PS1_RESET}\n${__PS1_RED}["
    __PS1_WRAPPER_END="${__PS1_RED}]"
    # shellcheck disable=SC2016
    __PS1_GIT='$(
        BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        [ "${BRANCH}" = HEAD ] && BRANCH=$(git describe --contains --all HEAD 2>/dev/null)
        [ "${BRANCH}" != "" ] && {
            echo -n "'"${__TPUT_CYAN}"'['"${__TPUT_RED}"'${BRANCH}"
            git ls-files --error-unmatch -m --directory --no-empty-directory -o --exclude-standard ":/*" >/dev/null 2>&1 && echo -n " '"${__TPUT_YELLOW}✗"'"
            echo -n "'"${__TPUT_CYAN}"']"
        }
    )'
    export PS1="${__PS1_WRAPPER_START}${__PS1_USERNAME}${__PS1_AT}${__PS1_HOSTNAME} ${__PS1_WORKSPACE}${__PS1_WRAPPER_END}${__PS1_GIT}${__PS1_PROMPT}"
    unset __TPUT_BOLD __TPUT_BLACK __TPUT_RED __TPUT_GREEN __TPUT_YELLOW \
      __TPUT_BLUE __TPUT_MAGENTA __TPUT_CYAN __TPUT_WHITE __PS1_BLACK __PS1_RED \
      __PS1_GREEN __PS1_YELLOW __PS1_BLUE __PS1_MAGENTA __PS1_CYAN __PS1_WHITE \
      __PS1_USERNAME __PS1_AT __PS1_HOSTNAME __PS1_WORKSPACE __PS1_PROMPT \
      __PS1_WRAPPER_START __PS1_WRAPPER_END __PS1_GIT __TPUT_RESET __PS1_BOLD __PS1_RESET
    eval "$(fzf --bash)"
    ;;
  zsh)
    autoload -U colors && colors
    autoload -U +X compinit && compinit
    autoload -U +X bashcompinit && bashcompinit
    # shellcheck disable=SC1087
    # shellcheck disable=SC2154
    PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
    eval "$(fzf --zsh)"
    ;;
  *)
    PS1="dev.sh: ${__DEV_SH_CURRENT_SHELL__} not supported"
    ;;
  esac

  ###############################################################################
  # endregion: FUNCTIONS THAT SHOULD ONLY BE AVAILABLE WHEN FILE IS BEING SOURCED
  ###############################################################################

  ###############################################################################
  # region: DO NOT EDIT THE BLOCK BELOW
  ###############################################################################
  dev.sh() {
    "${__DEV_SH_SCRIPT__}" "${@}"
  }
  complete -W "${__DEV_SH_FUNCTION_LIST__[*]}" dev.sh
  complete -W "${__DEV_SH_FUNCTION_LIST__[*]}" ./dev.sh
  echo "You can now do dev.sh [tab][tab] for autocomplete :)" >&2
  return 0
  ###############################################################################
  # endregion: DO NOT EDIT THE BLOCK ABOVE
  ###############################################################################
fi

###############################################################################
# region: FUNCTIONS THAT SHOULD ONLY BE ACCESS WHEN FILE IS BEING EXECUTED
###############################################################################

hello_world() {
  echo "Hello World!"
}

###############################################################################
# endregion: FUNCTIONS THAT SHOULD ONLY BE ACCESS WHEN FILE IS BEING EXECUTED
###############################################################################

###############################################################################
# region: SCRIPT SETUP DO NOT EDIT
###############################################################################
: File is being executed
[ "${1}" = 'debug' ] && set -x && shift 1

# shellcheck disable=SC1009
# shellcheck disable=SC1058
# shellcheck disable=SC1073
# shellcheck disable=SC1072
if [ -n "${1}" ] && [[ ${__DEV_SH_FUNCTION_LIST__[*]} =~ ${1} ]]; then
  "${@}"
  exit $?
else
  echo "Usage: ${0} [function_name] [args]" >&2
  echo "Available functions:" >&2
  for function in "${__DEV_SH_FUNCTION_LIST__[@]}"; do
    echo "    ${function}" >&2
  done
  exit 1
fi
###############################################################################
# endregion: SCRIPT SETUP DO NOT EDIT
###############################################################################
