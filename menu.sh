#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BOOTSTRAP_BASE_URL="${PROXMOX_SCRIPT_BASE_URL:-https://raw.githubusercontent.com/Galaxie0n/proxmox-script/main}"

bootstrap_file() {
  local rel_path="$1"
  local target_path="${SCRIPT_DIR}/${rel_path}"

  if [[ -f "$target_path" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"
  echo "Téléchargement de ${rel_path} depuis ${BOOTSTRAP_BASE_URL}..." >&2
  curl -fsSL "${BOOTSTRAP_BASE_URL}/${rel_path}" -o "$target_path"
}

bootstrap_dependencies() {
  if [[ ! -f "${SCRIPT_DIR}/lib/ui.sh" ]]; then
    if ! command -v curl >/dev/null 2>&1; then
      echo "curl est requis pour télécharger les dépendances." >&2
      exit 1
    fi
  fi

  bootstrap_file "lib/ui.sh"
  bootstrap_file "lib/json.sh"
  bootstrap_file "lib/pve.sh"
  bootstrap_file "modules/lxc_debian12_base.sh"
  bootstrap_file "modules/vm_ubuntu2404_cloudinit.sh"

  chmod +x "${SCRIPT_DIR}/lib/ui.sh" \
    "${SCRIPT_DIR}/lib/json.sh" \
    "${SCRIPT_DIR}/lib/pve.sh" \
    "${SCRIPT_DIR}/modules/lxc_debian12_base.sh" \
    "${SCRIPT_DIR}/modules/vm_ubuntu2404_cloudinit.sh"
}

bootstrap_dependencies

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
