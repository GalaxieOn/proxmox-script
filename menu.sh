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
  bootstrap_file "modules/lxc_ubuntu2404_base.sh"
  bootstrap_file "modules/lxc_debian133_base.sh"
  bootstrap_file "modules/vm_ubuntu2404_cloudinit.sh"
  bootstrap_file "modules/vm_ubuntu2404_base.sh"
  bootstrap_file "modules/vm_debian133_base.sh"

  chmod +x "${SCRIPT_DIR}/lib/ui.sh" \
    "${SCRIPT_DIR}/lib/json.sh" \
    "${SCRIPT_DIR}/lib/pve.sh" \
    "${SCRIPT_DIR}/modules/lxc_debian12_base.sh" \
    "${SCRIPT_DIR}/modules/lxc_ubuntu2404_base.sh" \
    "${SCRIPT_DIR}/modules/lxc_debian133_base.sh" \
    "${SCRIPT_DIR}/modules/vm_ubuntu2404_cloudinit.sh" \
    "${SCRIPT_DIR}/modules/vm_ubuntu2404_base.sh" \
    "${SCRIPT_DIR}/modules/vm_debian133_base.sh"
}

bootstrap_dependencies

# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"

ensure_whiptail

while true; do
  category=$(prompt_menu "Proxmox Script" "Choisissez le type" 12 70 4 \
    "lxc" "Conteneur LXC" \
    "vm" "Machine virtuelle (VM)" \
    "quit" "Quitter" ) || exit 0

  case "$category" in
    lxc)
      lxc_choice=$(prompt_menu "LXC" "Choisissez une version" 14 70 6 \
        "debian12" "Debian 12" \
        "ubuntu2404" "Ubuntu 24.04" \
        "debian133" "Debian 13.3" \
        "back" "Retour" ) || exit 0
      case "$lxc_choice" in
        debian12)
          "$SCRIPT_DIR/modules/lxc_debian12_base.sh"
          ;;
        ubuntu2404)
          "$SCRIPT_DIR/modules/lxc_ubuntu2404_base.sh"
          ;;
        debian133)
          "$SCRIPT_DIR/modules/lxc_debian133_base.sh"
          ;;
        back)
          continue
          ;;
      esac
      ;;
    vm)
      vm_choice=$(prompt_menu "VM" "Choisissez une version" 14 70 6 \
        "ubuntu2404_cloudinit" "Ubuntu 24.04 Cloud-Init" \
        "ubuntu2404_base" "Ubuntu 24.04 (sans Cloud-Init)" \
        "debian133" "Debian 13.3" \
        "back" "Retour" ) || exit 0
      case "$vm_choice" in
        ubuntu2404_cloudinit)
          "$SCRIPT_DIR/modules/vm_ubuntu2404_cloudinit.sh"
          ;;
        ubuntu2404_base)
          "$SCRIPT_DIR/modules/vm_ubuntu2404_base.sh"
          ;;
        debian133)
          "$SCRIPT_DIR/modules/vm_debian133_base.sh"
          ;;
        back)
          continue
          ;;
      esac
      ;;
    quit)
      exit 0
      ;;
  esac
done
