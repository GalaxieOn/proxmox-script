#!/usr/bin/env bash
set -euo pipefail

ensure_whiptail() {
  if ! command -v whiptail >/dev/null 2>&1; then
    echo "whiptail introuvable, installation..." >&2
    apt-get update -y
    apt-get install -y whiptail
  fi
}

prompt_input() {
  local title="$1" prompt="$2" default_value="${3:-}"
  whiptail --title "$title" --inputbox "$prompt" 10 70 "$default_value" 3>&1 1>&2 2>&3
}

prompt_password() {
  local title="$1" prompt="$2"
  whiptail --title "$title" --passwordbox "$prompt" 10 70 3>&1 1>&2 2>&3
}

prompt_menu() {
  local title="$1" prompt="$2" height="$3" width="$4" listheight="$5"
  shift 5
  whiptail --title "$title" --menu "$prompt" "$height" "$width" "$listheight" "$@" 3>&1 1>&2 2>&3
}

prompt_yesno() {
  local title="$1" prompt="$2"
  whiptail --title "$title" --yesno "$prompt" 10 70
}
