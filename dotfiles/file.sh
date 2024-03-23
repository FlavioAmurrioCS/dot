#!/usr/bin/env bash
_current_shell=$(ps -o args= -p "$$" | cut -d' ' -f1 | xargs basename)
__THIS_SCRIPT__="$0"
IS_SOURCED='false'

case "${_current_shell}" in
  sh)
  (return 0 2>/dev/null) && IS_SOURCED='true'
  if [ "${IS_SOURCED}" = 'true' ]; then
    __THIS_SCRIPT__="CAN'T BE DETERMINED"
  fi
  ;;
  bash)
  (return 0 2>/dev/null) && IS_SOURCED='true'
  # shellcheck disable=SC3028
  # shellcheck disable=SC3054
  __THIS_SCRIPT__="${BASH_SOURCE[0]}"
  ;;
  zsh)
  # shellcheck disable=SC3010
  [[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT =~ :file$ ]] && IS_SOURCED='true'
  # shellcheck disable=SC2296
  __THIS_SCRIPT__="${(%):-%N}"
  ;;
  ksh)
  # shellcheck disable=SC3010
  # shellcheck disable=SC2296
  [[ -n $KSH_VERSION && $(cd "$(dirname -- "$0")" && printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] && IS_SOURCED='true'
  # shellcheck disable=SC2296
  __THIS_SCRIPT__="${.sh.file}"
  ;;
  *)
  echo "NOT IMPLEMENTED"
  ;;
esac


SCRIPT_HOME="$(cd "$(dirname "${__THIS_SCRIPT__}")" >/dev/null 2>&1 && pwd -P)"
SCRIPT_PATH="${SCRIPT_HOME}/$(basename "${__THIS_SCRIPT__}")"



echo "0: $0"
echo "SHELL: $SHELL"
echo "IS_SOURCED: $IS_SOURCED"
echo "__THIS_SCRIPT__: $__THIS_SCRIPT__"
echo "_current_shell: $_current_shell"
echo "SCRIPT_HOME: ${SCRIPT_HOME}"
echo "SCRIPT_PATH: ${SCRIPT_PATH}"
echo "######################"


echo "#"
return 0


echo 'return didnt work'





# ###########
# #!/usr/bin/env bash

# _current_shell=$(ps -o args= -p "$$" | cut -f1 | xargs basename)

# SHELLS=(
# /bin/sh
# /bin/bash
# /bin/zsh
# /bin/ksh
# /bin/dash
# /bin/csh
# /bin/tcsh
# )

# for s in ${SHELLS[@]}; do
#   echo ""
#   echo "Testing ${s}"
#   "${s}" -c '. /Users/flavio/file.sh' && echo "RETURN WORKS" || echo "RETURN FAILS"
# done

# for s in ${SHELLS[@]}; do
#   echo ""
#   echo "Testing ${s}"
#   "${s}" -c 'echo $(ps -o args= -p "$$")'
# done


# for s in ${SHELLS[@]}; do
#   echo ""
#   echo "Testing ${s}"
#   "${s}" '/Users/flavio/file.sh' && echo "RETURN WORKS" || echo "RETURN FAILS"
# done
