#!/usr/bin/env bash
# file_sync :: file -> src_dir -> dest_dir
# TODO: Configure run on save to match project paths and use enviromental variables to map.
function file_sync() {
  local file="${1}"
  local src_dir="${2}"
  local dest_dir="${3}"
  local relative="${file/$src_dir/}"

  [ "$(find "${src_dir}" -name "$(basename "${file}")" | wc -l)" -eq "0" ] &&
    echo "${file} is not in ${src_dir}. Please fix wildcard matching." &&
    return 1

  echo "\
    ##############   DEBUG INFORMATION   ##############
    FILE:     ${file}
    SRC_DIR:  ${src_dir}
    DEST_DIR: ${dest_dir}
    RELATIVE: ${relative}

    MOVING:   ${file}
    TO:       ${dest_dir}/${relative}"
  local final_parent_dir
  final_parent_dir="$(dirname "${dest_dir}/${relative}")"
  [ ! -d "${final_parent_dir}" ] &&
    echo "'${final_parent_dir}' directory does not exist." &&
    return 1
  cp "$file" "${dest_dir}/${relative}" &&
    echo "FILE TRANSFER SUCCESFUL!!!" ||
    echo "COULD NOT TRANSFER FILE!!!"
}

file_sync "${@}"
