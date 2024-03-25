#!/usr/bin/env zsh
# exec bash
echo 'sourcing ~/.zshrc' >&2
__DEV_SH_CURRENT_SHELL__=zsh
__DEV_SH_SCRIPT__="${HOME}/dotfiles/dev.sh"
[ -f "${__DEV_SH_SCRIPT__}" ] && . "${__DEV_SH_SCRIPT__}"
