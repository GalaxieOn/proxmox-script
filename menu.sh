#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"

ensure_whiptail

while true; do
  choice=$(prompt_menu "Proxmox Script" "Choisissez un module" 15 70 6 \
    "lxc_debian12_base" "Créer un LXC Debian 12" \
    "vm_ubuntu2404_cloudinit" "Créer une VM Ubuntu 24.04 Cloud-Init" \
    "quit" "Quitter" ) || exit 0

  case "$choice" in
    lxc_debian12_base)
      "$SCRIPT_DIR/modules/lxc_debian12_base.sh"
      ;;
    vm_ubuntu2404_cloudinit)
      "$SCRIPT_DIR/modules/vm_ubuntu2404_cloudinit.sh"
      ;;
    quit)
      exit 0
      ;;
  esac

done
