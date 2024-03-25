#!/usr/bin/env bash
# shellcheck disable=SC1090
echo 'sourcing ~/.bashrc' >&2
__DEV_SH_CURRENT_SHELL__=bash
__DEV_SH_SCRIPT__="${HOME}/dotfiles/dev.sh"
[ -f "${__DEV_SH_SCRIPT__}" ] && . "${__DEV_SH_SCRIPT__}"
