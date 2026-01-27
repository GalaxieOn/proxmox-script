#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"
# shellcheck source=lib/json.sh
source "$SCRIPT_DIR/lib/json.sh"
# shellcheck source=lib/pve.sh
source "$SCRIPT_DIR/lib/pve.sh"

ensure_whiptail

json_file="$(json_init)"
cleanup() {
  rm -f "$json_file"
}
trap cleanup EXIT

vm_id=$(prompt_input "VM Ubuntu 24.04" "VM ID" "")
json_set "$json_file" "vm_id" "$vm_id"

vm_name=$(prompt_input "VM Ubuntu 24.04" "Nom de la VM" "ubuntu2404")
json_set "$json_file" "vm_name" "$vm_name"

bridge_list=$(list_bridges || true)
if [[ -n "$bridge_list" ]]; then
  menu_items=()
  while IFS= read -r line; do
    menu_items+=("$line" "bridge")
  done <<< "$bridge_list"
  bridge=$(prompt_menu "Réseau" "Choisissez un bridge" 15 70 6 "${menu_items[@]}")
else
  bridge=$(prompt_input "Réseau" "Nom du bridge" "vmbr0")
fi
json_set "$json_file" "bridge" "$bridge"

storage_list=$(list_storages_for_vm || true)
if [[ -n "$storage_list" ]]; then
  menu_items=()
  while IFS= read -r line; do
    menu_items+=("$line" "storage")
  done <<< "$storage_list"
  storage=$(prompt_menu "Stockage" "Choisissez un storage" 15 70 6 "${menu_items[@]}")
else
  storage=$(prompt_input "Stockage" "Nom du storage" "local-lvm")
fi
json_set "$json_file" "storage" "$storage"

cores=$(prompt_input "Ressources" "CPU (cores)" "2")
json_set "$json_file" "cores" "$cores"

memory=$(prompt_input "Ressources" "RAM (MB)" "4096")
json_set "$json_file" "memory" "$memory"

disk_size=$(prompt_input "Ressources" "Disque (GB)" "20")
json_set "$json_file" "disk_size" "$disk_size"

ci_user=$(prompt_input "Cloud-Init" "Nom d'utilisateur (ciuser)" "ubuntu")
json_set "$json_file" "ci_user" "$ci_user"

ci_password=$(prompt_password "Cloud-Init" "Mot de passe (cipassword)")
json_set "$json_file" "ci_password" "$ci_password"

options=$(prompt_input "Options" "Options supplémentaires (qm create/set)" "")
json_set "$json_file" "options" "$options"

summary=$(json_pretty "$json_file")
whiptail --title "Récapitulatif" --msgbox "$summary" 20 80 --scrolltext
if ! prompt_yesno "Confirmation" "Lancer la création de la VM ?"; then
  exit 0
fi

image_dir="/var/lib/vz/template/iso"
image_name="ubuntu-24.04-server-cloudimg-amd64.img"
image_path="${image_dir}/${image_name}"
image_url="https://cloud-images.ubuntu.com/releases/24.04/release/${image_name}"

if [[ ! -f "$image_path" ]]; then
  echo "Téléchargement de l'image cloud Ubuntu 24.04..." >&2
  mkdir -p "$image_dir"
  curl -fsSL "$image_url" -o "$image_path"
fi

qm create "$vm_id" \
  --name "$vm_name" \
  --memory "$memory" \
  --cores "$cores" \
  --net0 "virtio,bridge=${bridge}" \
  --serial0 socket \
  --vga serial0 \
  $options

qm importdisk "$vm_id" "$image_path" "$storage"

qm set "$vm_id" \
  --scsihw virtio-scsi-pci \
  --scsi0 "${storage}:vm-${vm_id}-disk-0" \
  --ide2 "${storage}:cloudinit" \
  --boot c \
  --bootdisk scsi0 \
  --ciuser "$ci_user" \
  --cipassword "$ci_password" \
  --ipconfig0 ip=dhcp \
  --agent enabled=1

qm resize "$vm_id" scsi0 "${disk_size}G"

whiptail --title "Terminé" --msgbox "VM Ubuntu 24.04 créée." 10 60
