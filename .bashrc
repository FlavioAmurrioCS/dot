#!/usr/bin/env bash
# shellcheck source=/dev/null

echo "~/.bashrc: bash settings"
export BASH_SILENCE_DEPRECATION_WARNING=1

# https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
export HISTSIZE=9000
export HISTFILESIZE=${HISTSIZE}
export HISTCONTROL=ignorespace:ignoredups

_bash_history_sync() {
  builtin history -a       #1
  HISTFILESIZE=${HISTSIZE} #2
  builtin history -c       #3
  builtin history -r       #4
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

[[ $- == *i* ]] &&
  bind '"\e[A": history-search-backward' &&
  bind '"\e[B": history-search-forward'

source() {
  if [ -z "$1" ]; then
    builtin source "${HOME}/.bashrc"
  else
    builtin source "$@"
  fi
}

# export PS1="\[\033[0;36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w/\[\e[34;1m\]\[\e[32;1m\]\$(command -v git > /dev/null 2>&1 && git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \color{#fff}{.*}.∗/ (\1)/') \[\e[0m\]\$ "
export PS1="\[\033[0;36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w/\[\e[34;1m\] \$ \[\033[0m\]"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
[ -f "${HOME}/.dot/dotrc" ] && source "${HOME}/.dot/dotrc"
