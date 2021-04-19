#!/usr/bin/env bash
# shellcheck source=/dev/null

echo "~/.bash_profile: bash login settings" >&2

# shellcheck source=./.bashrc
[ -f "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"
