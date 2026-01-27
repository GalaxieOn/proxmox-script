#!/usr/bin/env bash
set -euo pipefail

list_bridges() {
  ip -o link show type bridge | awk -F': ' '{print $2}'
}

list_storages_for_lxc() {
  pvesm status --content rootdir | awk 'NR>1 {print $1}'
}

list_storages_for_vm() {
  pvesm status --content images | awk 'NR>1 {print $1}'
}

get_debian12_template() {
  local template
  template=$(pveam available -section system | awk '/debian-12/ {print $2}' | tail -n1)
  if [[ -z "$template" ]]; then
    return 1
  fi
  echo "$template"
}
