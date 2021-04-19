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

# Integrate the bottom to the top
######################################################################
#!/usr/bin/env bash

export ssh_options=(
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

function onlyInLinux() { uname -s | grep -q Linux; }
function onlyInMac() { uname -s | grep -q Darwin; }
function bnr() {
  echo
  python -c "print(' ${*} '.center(78, '='))"
}
# shellcheck disable=SC2120
onlyInMac && function md5sum() { cat | md5 "${@}"; }

function color_log() {
  local color=${1} && shift
  local options="-e"
  [[ "${1}" == "-n" ]] && options+="n" && shift
  echo "${options}" "${color}${*}\033[0m" 1>&2
}
function log_info() { color_log '\033[1;37m' "${@}"; }
function log_error() { color_log '\033[1;31m' "${@}"; }
function log_success() { color_log '\033[1;32m' "${@}"; }
function log_warning() { color_log '\033[1;33m' "${@}"; }

function help_arg_count_usage() {
  local min_args="${1}" && shift &&
    local usage="${1}" && shift
  [[ "${1}" == "-h" || "${1}" == "--help" || "$#" -lt "${min_args}" ]] &&
    msg --info "USAGE: ${usage}" &&
    return 0
  return 1
}

function append_to_history_no_exec() {
  help_arg_count_usage 1 "${FUNCNAME[0]:-append_to_history} <cmd>" "$@" && return 0
  local hist_file="${HISTFILE:-${HOME}/.bash_history}"
  if grep -q "${*}" "${hist_file}"; then
    grep -v "${*}" "${hist_file}" >/tmp/history
    cat /tmp/history >"${hist_file}"
    rm /tmp/history
  fi
  log_warning "Appending '${*}' to '${hist_file}'" &&
    echo "${@}" >>"${hist_file}"
}

function append_to_history() {
  append_to_history_no_exec "${@}"
  "${@}"
}

function cmd_check() {
  local cmd_ndef=""
  for cmd in "$@"; do
    command -v "${cmd}" >/dev/null 2>&1 || cmd_ndef="${cmd_ndef} ${cmd}"
  done
  [ -n "${cmd_ndef}" ] &&
    log_error "The following were not found in PATH:${cmd_ndef}" &&
    return 1
  return 0
}

function select_one() {
  local selected
  selected="$(cat | awk '!x[$0]++' | fzf -0)"
  [ -z "${selected}" ] &&
    log_error "Selection cancelled." &&
    return 1
  echo "${selected}" && return 0
}

function strToHash() {
  local input="${*}"
  echo "${input}" | md5sum | tr 'abcdef0-' ' ' | tr -d ' ' | grep -o ".........$"
}

function strToHashPort() {
  local input="${*}"
  local HASH_NUM
  HASH_NUM="$(strToHash "${input}")"
  echo "$((HASH_NUM % 64511 + 1023))"
}

# =================================== vscode ===================================

function __selectRemoteFolder() {
  help_arg_count_usage 2 "${FUNCNAME[0]:-__selectRemoteFolder} <host> <remote_folder>" "$@" && return 0
  local host="${1}"
  local destination="${2}"
  remote_command="find ${destination} -maxdepth 1 -type d -follow"
  ssh "${ssh_options[@]}" "${host}" ''"${remote_command}"'' 2>/dev/null | select_one || return 1
}

function __selectLocalFolder() {
  help_arg_count_usage 2 "${FUNCNAME[0]:-__selectLocalFolder} <folder>" "$@" && return 0
  destination="${1}"
  find "${destination}" -maxdepth 1 -type d | select_one || return 1
}

function __selectHostFromInventoryApi() {
  local url="https://BLANK/runsqlcsv?sql=select%20ad.hostname%0Afrom%20asset_data%20ad%0Awhere%20ad.os_version%20like%20%27RHEL%25%27"
  cache_command curl -s -X GET "${url}" --insecure |
    cut -d '"' -f2 |
    grep "BLANK$" |
    select_one || return 1
}

function host_info() {
  local host="${1}"
  # shellcheck disable=SC2016
  local remote_command='
  REAL_HOME=$(readlink -f "${HOME}")
  REAL_PROJECT_HOME=$(readlink -f "${PROJECT_HOME:-${HOME}/projects}")
  mkdir -p "${REAL_PROJECT_HOME}"
  echo "${USER}" "${REAL_HOME}" "${REAL_PROJECT_HOME}"'
  ssh "${ssh_options[@]}" "${host}" ''"${remote_command}"'' 2>/dev/null
}

# TODO: Remote dot clone
function __remoteGitClone() {
  local host="${1}"
  local git_ssh_url="${2}"
  local folder
  folder=$(echo "${git_ssh_url}" | cut -d '/' -f2 | cut -d '.' -f1)

  # shellcheck disable=SC2016
  local remote_command='
  ! command -v git >/dev/null 2>&1 &&
    echo "Git not found. Installing Git..." 1>&2 &&
    sudo yum install -y git vim tmux 1>&2 &&
    ssh-keyscan BLANK >>~/.ssh/known_hosts 1>&2
  [ ! -d ~/projects ] && mkdir -p ~/projects
  project_home="$(readlink -f ~/projects)/'"${folder}"'"
  [ ! -d "${project_home}" ] && { git clone '"${git_ssh_url}"' "${project_home}" --recursive 1>&2 || { echo "Error Clonning '"${git_ssh_url}"'" 1>&2 && exit 1; }; }
  echo "${project_home}"'

  # shellcheck disable=SC2029
  ssh "${ssh_options[@]}" -q "${host}" "${remote_command}"
}

function __localGitClone() {
  local git_ssh_url="${1}"
  local folder
  folder=$(echo "${git_ssh_url}" | cut -d '/' -f2 | cut -d '.' -f1)

  [ ! -d ~/projects ] && mkdir -p ~/projects

  local project_home=~/projects/${folder}
  [ ! -d "${project_home}" ] &&
    { git clone "${git_ssh_url}" "${project_home}" --recursive || { log_warning "Error Cloning ${git_ssh_url}" && return 1; }; }
  echo "${project_home}"
}

function __getGitHubToken() {
  local github_token
  github_token=$(grep "^export GITHUB_TOKEN=" ~/.localrc ~/.bashrc ~/.zshrc 2>/dev/null | head -1 | cut -d '=' -f2 | tr -d '"')
  [ -n "${github_token}" ] && echo "${github_token}" && return 0

  log_warning "No GITHUB_TOKEN detected in ~/.localrc ~/.bashrc ~/.zshrc or env. Let's get one!"

  local github_user="${USER}"
  if echo "${USER}" | grep -qE "deploy|root|regadmin"; then
    read -r -p "Enter github username(default: ${USER}): " github_user
  fi

  local github_password
  read -r -s -p "Enter github password for ${github_user}: " github_password

  log_info "\nRequesting GITHUB_TOKEN..."
  github_token=$(curl -s -u "${github_user}:${github_password}" -X POST https://BLANK/api/v3/authorizations \
    --data '{"scopes":["repo","user","write:discussion"],"note": "vscode-setup'"${RANDOM}"'"}' |
    grep '"token"' |
    cut -d '"' -f4)
  [ -z "${github_token}" ] && log_error "Could not get GITHUB_TOKEN, check github password!" && return 1

  log_success "Adding GITHUB_TOKEN to ~/.localrc!"
  echo 'export GITHUB_TOKEN="'"${github_token}"'"' >>~/.localrc
  echo "${github_token}"
}

function __listGitProjects() {
  # Make sure the following are set: GITHUB_TOKEN GITHUB_ORGS GITHUB_USERS
  # For ORGS and USERS one can list many in a space separated manner
  # TODO: Switch array for GITHUB_ORGS and GITHUB_USERS.
  # TODO: Save the output to a file for caching.
  local github_orgs=${GITHUB_ORGS:-BLANK}
  local github_users=${GITHUB_USERS:-${USER} famurriomoya}
  local github_token
  github_token=${GITHUB_TOKEN:-$(__getGitHubToken)} || return 1
  {
    for i in $(echo "${github_orgs}" | tr ' ' '\n' | sort -u); do
      curl -s -H "Authorization: token ${github_token}" "https://BLANK/api/v3/orgs/${i}/repos?per_page=999" ||
        { log_error "Could not reach github or invalid GITHUB_TOKEN." && return 1; } &
    done
    for j in $(echo "${github_users}" | tr ' ' '\n' | sort -u); do
      curl -s -H "Authorization: token ${github_token}" "https://BLANK/api/v3/users/${j}/repos?per_page=999" ||
        { log_error "Could not reach github or invalid GITHUB_TOKEN." && return 1; } &
    done
  } | grep "ssh_url" | cut -d '"' -f4
}

# =================================== vscode ===================================

function isCentos() {
  hostnamectl | grep -q CentOS
}
function isRedHat() {
  hostnamectl | grep -q "Red Hat"
}
function installRpmFromUrl() {
  local rpm_url="${1}"
  local rpm_file
  rpm_file="$(basename "${rpm_url}")"
  wget -q "${rpm_url}" &&
    sudo yum -y install "./${rpm_file}" &&
    rm -rf "./${rpm_file}"
}

function addRepo() {
  local url
  for url in "${@}"; do
    local label
    label=$(echo "${url}" | rev | cut -d "/" -f1-2 | rev | tr '[:lower:]' '[:upper:]' | tr '/_' '-')
    local block="[${label}]
name=${label}
baseurl=${url}
enabled=1
gpgcheck=0
priority=40
"
    if ! grep -q "${url}" /etc/yum.repos.d/ -rl; then
      {
        echo "${block}"
        # case "${label}" in
        # *CENTOS*)
        #   isCentos && echo "${block}"
        #   ;;
        # *RHEL*)
        #   isRedHat && echo "${block}"
        #   ;;
        # *)
        #   echo "${block}"
        #   ;;
        # esac
      } | sudo tee -a /etc/yum.repos.d/setup.repo
    else
      echo "${url} is already here."
    fi
  done
}

# TODO: INSTALL YUM REQUIREMENTS
function yum_required() {
  echo install
}

function canConnect() {
  help_arg_count_usage 1 "${FUNCNAME[0]} <url>" "$@" && return 0
  curl -s -m 2 "${1}" >/dev/null && return 0
  log_error "Cannot connect to ${1}" && return 1
}

function wasFileModifiedToday() {
  help_arg_count_usage 1 "${FUNCNAME[0]} <file>" "$@" && return 1
  [ ! -f "${1}" ] && return 0
  local python_cmd
  local file_date
  # shellcheck disable=SC2012
  file_date="$(date +"%Y") $(ls -ltr "${1}" | tail -n 1 | rev | awk '{print $2,$3,$4}' | rev)"
  python_cmd="from datetime import datetime, timedelta
yesterday = datetime.now() - timedelta(days=1)
if datetime.strptime('${file_date}', '%Y %b %d %H:%M') > yesterday:
  exit(0)
exit(1)
"
  python -c "${python_cmd}"
}

function remoteDotUpdate() {
  help_arg_count_usage 1 "${FUNCNAME[0]} <host>" "$@" && return 0
  local host=${1}
  # shellcheck disable=SC2016
  local remote_cmd='
  [ ! -d "${HOME}/.cfg/" ] && {
    git clone --bare git@BLANK:famurriomoya/dot.git "${HOME}/.cfg"
    if git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}" checkout; then
      echo "Checked out config."
    else
      echo "Backing up pre-existing dot files."
      mkdir -p ~/.config-backup
      git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}" checkout 2>&1 | grep -E "\s+\." | awk '\''{print $1}'\'' | xargs -I{} mv {} ~/.config-backup/{}
      git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}" checkout
    fi
  }
  git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}" pull
  git "--git-dir=${HOME}/.cfg/" "--work-tree=${HOME}" config --local status.showUntrackedFiles no
  '

  ssh "${ssh_options[@]}" "${host}" ''"${remote_cmd}"''
}

export color_black="\033[0;30m"
export color_blue="\033[0;34m"
export color_blue_light="\033[1;34m"
export color_brown="\033[0;33m"
export color_cyan="\033[0;36m"
export color_cyan_light="\033[1;36m"
export color_gray_dark="\033[1;30m"
export color_gray_light="\033[0;37m"
export color_green="\033[0;32m"
export color_green_light="\033[1;32m"
export color_purple="\033[0;35m"
export color_purple_light="\033[1;35m"
export color_red="\033[0;31m"
export color_red_light="\033[1;31m"
export color_white="\033[1;37m"
export color_yellow="\033[1;33m"
export color_reset='\033[0m'
ansi() { echo -e "\e[${1}m${*:2}\e[0m"; }
bold() { ansi 1 "$@"; }
italic() { ansi 3 "$@"; }
underline() { ansi 4 "$@"; }
strikethrough() { ansi 9 "$@"; }
red() { ansi 31 "$@"; }
blue() { ansi 34 "$@"; }

function rainbow_taste() {
  printf "\
\033[0;30mcolor_black(\\\033[0;30m)
\033[0;34mcolor_blue(\\\033[0;34m)
\033[1;34mcolor_blue_light(\\\033[1;34m)
\033[0;33mcolor_brown(\\\033[0;33m)
\033[0;36mcolor_cyan(\\\033[0;36m)
\033[1;36mcolor_cyan_light(\\\033[1;36m)
\033[1;30mcolor_gray_dark(\\\033[1;30m)
\033[0;37mcolor_gray_light(\\\033[0;37m)
\033[0;32mcolor_green(\\\033[0;32m)
\033[1;32mcolor_green_light(\\\033[1;32m)
\033[0;35mcolor_purple(\\\033[0;35m)
\033[1;35mcolor_purple_light(\\\033[1;35m)
\033[0;31mcolor_red(\\\033[0;31m)
\033[1;31mcolor_red_light(\\\033[1;31m)
\033[1;37mcolor_white(\\\033[1;37m)
\033[1;33mcolor_yellow(\\\033[1;33m)
\033[0mcolor_reset(\\\033[0m)
"
}
