#!/usr/bin/env bash

function append_file() {
  help_arg_count_usage 2 "${FUNCNAME[0]:-append_file} <filename> <quoted_variables>" "$@" && return 0
  local file=${1} && shift
  msg --debug "Appending '${text}' to ${file}."
  cat <<EOF >>"${file}"
$@
EOF
}

function create_replace_file() {
  help_arg_count_usage 2 "${FUNCNAME[0]:-create_replace_file} <filename> <quoted_variables>" "$@" && return 0
  local file=${1} && shift
  cat <<EOF >>"${file}"
$@
EOF
}

function appendIfNotInFile() {
  local comment_char="#"
  [ "${1}" == "-c" ] && shift && comment_char=${1} && shift
  help_arg_count_usage 2 "${FUNCNAME[0]:-appendIfNotInFile} [-c <comment_char>] <file> <text> [search_string]" "$@" && return 0
  local file="${1}" && local text="${2}" && local search_string="${3:-${text}}"
  grep -o "^[^${comment_char}]*" "${file}" | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -q "${search_string}" ||
    append_file "${file}" "${text}"
}

function add_export_var() {
  local comment_char="#"
  [ "${1}" == "-c" ] && shift && comment_char=${1} && shift
  help_arg_count_usage 2 "${FUNCNAME[0]:-add_export_var} [-c <comment_char>] <var> <value|function>" "$@" && return 0
  local var="${1}"
  local value="${2}"
  if [ "$(type -t "${value}")" == "function" ]; then
    msg --debug "${value} is a function." &&
      value="$("${value}")" || return 1
  fi
  [ -z "${value}" ] && msg --debug "Value for ${var} is empty." && return 1
  local user_shell
  user_shell="$(finger "${USER}" | grep Shell | awk '{print $4}' | xargs basename)"
  local shellrc="${HOME}/.${user_shell:-bash}rc"
  appendIfNotInFile -c "#" "${shellrc}" 'export '"${var}"'="'"${value}"'"'
  { export "${var}"="$(eval "echo ${value}")"; } >/dev/null 2>&1
}

##############################################
################ HOST TOOLS ##################
##############################################
function host_has_internet_access() {
  help_arg_count_usage 1 "${FUNCNAME[0]:-host_has_internet_access} [host]" "$@" && return 0
  local host="${1}"
  ssh -q "${host}" 'sudo yum install -y nc; echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80' >/dev/null 2>&1 &&
    msg --success "${host} has internet access." &&
    return 0
  msg --warning "${host} does not have internet access." &&
    return 1
}

##############################################
################ CODE TOOLS ##################
##############################################

onlyInMac && function getGitHubToken() {
  # var_check GITHUB_TOKEN && msg --info "Token is already in enviroment." && return 0
  local GITHUB_USER
  local github_token
  read -r -p "Enter github username(default: ${USER}): " GITHUB_USER
  github_token=$(curl -s -u "${GITHUB_USER:-${USER}}" -X POST https://github.com/api/v3/authorizations \
    --data '{"scopes":["repo"],"note": "vscode-setup'"${RANDOM}"'"}' |
    grep '"token"' |
    cut -d '"' -f4)
  [ -z "${github_token}" ] && return 1
  echo "${github_token}" && return 0
}

function curl_with_proxy() {
  ! ssh -N -f -K -D 9999 -C "${USER}.BLANK.com" &&
    msg --error "Could not setup proxy" &&
    return 1
  curl --socks5-hostname localhost:9999 "$@"
}

function is_site_accessible() {
  help_arg_count_usage 0 "${FUNCNAME[0]:-is_site_accessible} [url]" "$@" && return 0
  local url="${1:-https://github.com}"
  curl -s --head --request GET "${url}" | grep -q "200 OK" &&
    msg --success "${url} is accessible." &&
    return 0 ||
    { msg --error "${url} is not accessible." && return 1; }
}

function get_subtring_within() {
  help_arg_count_usage 3 "${FUNCNAME[0]:-get_subtring_within} [string | -] <regex_start_pattern> <regex_end_pattern>" "$@" && return 0
  local string="${1}"
  local start="${2}"
  local end="${3}"
  # shellcheck disable=SC2001
  [ "${string}" != "-" ] && echo "${string}" | sed "s|.*${start}\(.*\)${end}.*|\1|" && return 0
  cat | sed "s|.*${start}\(.*\)${end}.*|\1|"
}

function remote_kill() {
  help_arg_count_usage 2 "${FUNCNAME[0]:-remote_kill} <host> <target>" "$@" && return 0
  local host="${1}"
  local target="${2}"
  ssh -q "${host}" 'ps aux | grep '"${target}"' | grep -v grep | grep ${USER} | awk '"'"'{print ${2}}'"'"' | xargs -r kill -9'
}

function get_col() {
  help_arg_count_usage 1 "${FUNCNAME[0]:-get_col} [col_num]" "$@" && return 0
  local col_num="${1}"
  ! [[ ${col_num} =~ ^[0-9]+$ ]] && msg --error "col_num must be numeric." && return 1
  cat | grep -v grep | awk '{print $'"${1}"'}'
}

alias pokecow="ssh dev-brn docker run --rm -i xaviervia/pokemonsay 'This is cool!'"

keyadd() {
  echo "twasha"
  ssh-add -K ~/.ssh/id_rsa
}

# https://github.com/LazoCoder/Pokemon-Terminal
# https://github.com/vsoch/pokemon
# https://github.com/LazoCoder/Pokemon-Terminal
# https://github.com/dfrankland/pokemonsay
# https://github.com/xaviervia/docker-pokemonsay

# Install brew
function install_homebrew() {
  [ ! -f "$HOMEBREW_HOME/bin/brew" ] &&
    dispblock "Installing Homebrew in $HOMEBREW_HOME" &&
    git clone https://github.com/Homebrew/brew.git $HOMEBREW_HOME &&
    echo_good "Homebrew is installed!"
}

# eval "$(pipenv --completion)"
# TODO: LazyLoading
# compdef pipenv
# _pipenv() {
#   eval $(env COMMANDLINE="${words[1,$CURRENT]}" _PIPENV_COMPLETE=complete-zsh  pipenv)
# }
# if [[ "$(basename -- ${(%):-%x})" != "_pipenv" ]]; then
#   autoload -U compinit && compinit
#   compdef _pipenv pipenv
# fi

function sendSshKey() {
  [ "$#" -lt 1 ] && {
    echo_error "USAGE: sendSshKey <hostname> [user]"
    return 1
  }
  host="$1"
  user="regadmin"
  [ "$#" -gt 1 ] && user="$2"
  ssh -q "$host" 'sudo -u '"$user"' bash -c "cat >> /home/'"$user"'/.ssh/authorized_keys"' <~/.ssh/id_rsa.pub &&
    echo_good "id_rsa.pub was appended to $host:/home/$user/.ssh/authorized_keys" ||
    echo_error "Error" 1>&2
}

function runScriptRemotely() {
  [ "$#" -lt 2 ] && {
    echo_error "USAGE: runScriptRemotely <hostname> <script.sh> [user]"
    return 1
  }
  host="$1"
  script="$2"
  user="regadmin"
  [ ! -f "$script" ] && echo_error "$script does not exist" && return 1
  [ "$#" -gt 2 ] && user="$3"
  ssh -q "$host" 'sudo -u '"$user"' bash -c "cat | bash -"' <"$script" ||
    echo_error "Error" 1>&2
}
