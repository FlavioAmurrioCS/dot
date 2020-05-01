#!/usr/bin/env bash

ssh_options=(
  "-oCompression=yes"
  "-oControlMaster=auto"
  "-oControlPath=/tmp/%r@%h:%p"
  "-oControlPersist=yes"
  "-oForwardAgent=yes"
  "-oGSSAPIAuthentication=yes"
  "-oGSSAPIDelegateCredentials=yes"
  "-oKeepAlive=yes"
  "-oLogLevel=FATAL"
  "-oServerAliveCountMax=6"
  "-oServerAliveInterval=15"
  "-oStrictHostKeyChecking=no"
  "-oUserKnownHostsFile=/dev/null"
)

# TODO: Consider bash only option
function onlyOnMac() { uname -s | grep -q "Darwin"; }
function onlyOnLinux() { uname -s | grep -q "Linux"; }

function checkVar() {
  local silence=false
  [[ "${1}" == "-q" ]] && silence="true" && shift
  local var_ndef=""
  for var in "$@"; do
    [ "${!var// /}x" = 'x' ] && var_ndef="${var_ndef} ${var}"
  done
  [ -n "${var_ndef}" ] && {
    [[ "${silence}" == "false" ]] && log_error "The following vars have not been defined: ${var_ndef}"
    return 1
  }
  return 0
}

function checkCmd() {
  helpArgCountUsage 1 "${FUNCNAME[0]} <cmd...>" "${@}" && return 0
  local silence=false
  [[ "${1}" == "-q" ]] && silence="true" && shift
  local cmd_ndef=""
  for cmd in "$@"; do
    command -v "${cmd}" >/dev/null 2>&1 || cmd_ndef+=" ${cmd}"
  done
  [ -n "${cmd_ndef}" ] && {
    [[ "${silence}" == "false" ]] && log_error "The following command where not found: ${cmd_ndef}"
    return 1
  }
  return 0
}
function helpArgCountUsage() {
  local min_args="${1}" && shift &&
    local usage="${1}" && shift
  [[ "${1}" == "-h" || "${1}" == "--help" || "$#" -lt "${min_args}" ]] &&
    echo -e "USAGE: ${usage}" &&
    return 0
  return 1
}

function color_log() {
  local black="\033[0;30m"
  local blue="\033[0;34m"
  local blue_light="\033[1;34m"
  local brown="\033[0;33m"
  local cyan="\033[0;36m"
  local cyan_light="\033[1;36m"
  local gray_dark="\033[1;30m"
  local gray_light="\033[0;37m"
  local green="\033[0;32m"
  local green_light="\033[1;32m"
  local purple="\033[0;35m"
  local purple_light="\033[1;35m"
  local red="\033[0;31m"
  local red_light="\033[1;31m"
  local white="\033[1;37m"
  local yellow="\033[1;33m"
  local reset='\033[0m'

  local usage="${FUNCNAME[0]:-color_log} <color> [-n] <text>
    ${black}black(\\\033[0;30m)
    ${blue_light}blue_light(\\\033[1;34m)
    ${blue}blue(\\\033[0;34m)
    ${brown}brown(\\\033[0;33m)
    ${cyan_light}cyan_light(\\\033[1;36m)
    ${cyan}cyan(\\\033[0;36m)
    ${gray_dark}gray_dark(\\\033[1;30m)
    ${gray_light}gray_light(\\\033[0;37m)
    ${green_light}green_light(\\\033[1;32m)
    ${green}green(\\\033[0;32m)
    ${purple_light}purple_light(\\\033[1;35m)
    ${purple}purple(\\\033[0;35m)
    ${red_light}red_light(\\\033[1;31m)
    ${red}red(\\\033[0;31m)
    ${reset}reset(\\\033[0m)
    ${white}white(\\\033[1;37m)
    ${yellow}yellow(\\\033[1;33m)
  "
  helpArgCountUsage 2 "${usage}" "${@}" && return 0
  local color="${yellow}"
  checkVar "${1}" >/dev/null 2>&1 && color="${!1// /}" && shift
  local options="-e"
  [[ "${1}" == "-n" ]] && options+="n" && shift
  echo "${options}" "${color}${*}\033[0m" 1>&2
}

function log_error() { color_log red "${@}"; }
function log_info() { color_log white "${@}"; }
function log_success() { color_log green_light "${@}"; }
function log_warning() { color_log yellow "${@}"; }

function bnr() { python -c "print(' ${*} '.center(78, '='))"; }

function runAndRecord() {
  helpArgCountUsage 1 "${FUNCNAME[0]:-runAndRecord} <cmd> [args...]" "${@}" && return 0
  local histFile="${HISTFILE:-${HOME}/.bash_history}"
  grep -q "${*}" "${histFile}" || {
    log_warning "Appending '${*}' to '${histFile}'" &&
      echo "${@}" >>${histFile}
  }
  "${@}"
}

function fzfSelectOne() {
  local selected
  selected="$(cat | fzf -0)"
  [ -z "${selected}" ] &&
    log_error "Selection cancelled." &&
    return 1
  echo "${selected}" && return 0
}

function tunnel() {
  helpArgCountUsage 2 "${FUNCNAME[0]} <hostname> <remote_port> [local_port]" "${@}" && return 0
  local host="${1}"
  local local_port="${2}"
  local remote_port="${3:-${local_port}}"
  ssh -N -f -L "localhost:${local_port}:localhost:${remote_port}" "${host}" &&
    log_success "Tunnel opened from ${host}:${remote_port} to localhost:${local_port}. (http://localhost:${local_port})"
}

function getCol() {
  cat | awk '{print $'"${1}"'}'
}

function abspath() {
  helpArgCountUsage 1 "${FUNCNAME[0]} <file|directory>" "${@}" && return 0
  if [ -d "${1}" ]; then
    (cd "${1}" && pwd)
  elif [ -f "${1}" ]; then
    if [[ "${1}" == /* ]]; then
      echo "${1}"
    elif [[ "${1}" == */* ]]; then
      echo "$(cd "${1%/*}" && pwd)/${1##*/}"
    else
      echo "$(pwd)/${1}"
    fi
  fi
  log_error "${1} does not exist." && return 1
}

function port() {
  helpArgCountUsage 1 "${FUNCNAME[0]} <port> [-k]" "${@}" && return 0
  local port="${1}"
  local pid
  pid="$(lsof -i ":${port}" | getCol 2 | sort -u | grep -v PID)"
  ! checkVar -q pid && log_info "No process is using port ${port}." && return 0
  [ "${2}" = "-k" ] && kill -9 "${pid}" && log_success "Port ${port} is now free."
}

onlyOnMac && function md5sum() { cat | md5 "${@}"; }

function strToHash() {
  local input="${*}"
  echo "${input}" | md5sum | tr -d 'abcdef0-' | grep -o ".........$"
}

function strToHashPort() {
  local input="${*}"
  local hash_num
  hash_num="$(strToHash "${input}")"
  echo "$((hash_num % 64511 + 1023))"
}

function pserver() {
  helpArgCountUsage 0 "${FUNCNAME[0]} [port]" "${@}" && return 0
  local port
  port="${1:-"$(strToHashPort "$(basename "$(pwd)")")"}"
  nohup python -m SimpleHTTPServer "${port}" &
  log_success "http://localhost:${port}"
}

function rmux() {
  helpArgCountUsage 0 "${FUNCNAME[0]} [hostname]" "${@}" && return 0
  local host=${1:-ubuntu}
  local tmux_cmd='{ tmux has-session >/dev/null 2>&1 && tmux a; } || tmux'
  ssh "${host}" -t "${tmux_cmd}"
}
