#!/usr/bin/env bash

echo "~/.bash_profile: bash login settings" >&2

# shellcheck source=./.bashrc
[ -f "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"
