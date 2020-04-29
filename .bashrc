#!/usr/bin/env bash
# shellcheck source=/dev/null

export PATH="$HOME/.local/bin:$PATH"

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# https://unix.stackexchange.com/questions/1288/preserve-bash-history-in-multiple-terminal-windows
HISTSIZE=9000
HISTFILESIZE=$HISTSIZE
HISTCONTROL=ignorespace:ignoredups

_bash_history_sync() {
  builtin history -a     #1
  HISTFILESIZE=$HISTSIZE #2
  builtin history -c     #3
  builtin history -r     #4
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

[[ $- == *i* ]] && bind '"\e[A": history-search-backward' && bind '"\e[B": history-search-forward'

# Overiding source command to allow to source ~/.*rc by default when passing
# no file
source() {
  if [ -z "$1" ]; then
    builtin source "${HOME}/.bashrc"
  else
    builtin source "$@"
  fi
}

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*)
  # export PS1="\[\e[0;32m\]\u@\[\e[1;32m\]\h:\[\e[0;34m\]\w/\[\e[34;1m\]\[\e[32;1m\]\$(command -v git > /dev/null 2>&1 && git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \color{#fff}{.*}.∗/ (\1)/') \[\e[0m\]\$ "
  command -v javac >/dev/null 2>&1 && JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")
  ;;
Darwin*)
  # export PS1="\[\e[0;34m\]\w/\[\e[34;1m\]\[\e[32;1m\]\$(command -v git > /dev/null 2>&1 && git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \color{#fff}{.*}.∗/ (\1)/') \[\e[0m\]\$ "
  JAVA_HOME="$(/usr/libexec/java_home)"
  ;;
esac

[ -n "$JAVA_HOME" ] && export JAVA_HOME

# [ -f ~/.fzf.bash ] && source ~/.fzf.bash
# [ -f /Users/famurriomoya/projects/vscode_setup/utility.sh ] && source /Users/famurriomoya/projects/vscode_setup/utility.sh

# export PS1="\[\033[0;36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w/\[\e[34;1m\]\[\e[32;1m\]\$(command -v git > /dev/null 2>&1 && git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \color{#fff}{.*}.∗/ (\1)/') \[\e[0m\]\$ "
export PS1="\[\033[0;36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w/\[\e[34;1m\] \$ "
# complete -C /Users/famurriomoya/.local/bin/terraform terraform

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

source "${HOME}/.settingsrc"