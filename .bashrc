#!/usr/bin/env bash
# shellcheck source=/dev/null

# TODO: REMOVE
# If this is a non iteracive shell then echo should be disabled
function status() {
  [[ $- == *i* ]] && echo "${@}"
}
# status "~/.bashrc: bash settings"

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

# source() {
#   if [ -z "${1}" ]; then
#     builtin source "${HOME}/.bashrc"
#   else
#     builtin source "${@}"
#   fi
# }

export PS1="\[\033[0;36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\W/\[\e[34;1m\]\[\e[32;1m\]\$(command -v git > /dev/null 2>&1 && git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/') \[\e[0m\]\$ "
export DOT_HOME="${HOME}/.dot"

[ -f "${DOT_HOME}/dotrc" ] && source "${DOT_HOME}/dotrc"

# ==================================== fzf =====================================
command -v fzf >/dev/null 2>&1 && {
  [[ $- == *i* ]] &&
    [ -f "${DOT_HOME}/fzf_scripts/completion.bash" ] &&
    source "${DOT_HOME}/fzf_scripts/completion.bash" 2>/dev/null
  [ -f "${DOT_HOME}/fzf_scripts/key-bindings.bash" ] &&
    source "${DOT_HOME}/fzf_scripts/key-bindings.bash" 2>/dev/null
}
