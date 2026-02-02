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

vm_id=$(prompt_input "VM Debian 13.3" "VM ID" "")
json_set "$json_file" "vm_id" "$vm_id"

vm_name=$(prompt_input "VM Debian 13.3" "Nom de la VM" "debian13")
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

memory=$(prompt_input "Ressources" "RAM (MB)" "2048")
json_set "$json_file" "memory" "$memory"

disk_size=$(prompt_input "Ressources" "Disque (GB)" "20")
json_set "$json_file" "disk_size" "$disk_size"

password=$(prompt_password "Sécurité" "Mot de passe (pour l'installateur)")
json_set "$json_file" "password" "$password"

options=$(prompt_input "Options" "Options supplémentaires (qm create/set)" "")
json_set "$json_file" "options" "$options"

summary=$(json_pretty "$json_file")
whiptail --title "Récapitulatif" --msgbox "$summary" 20 80 --scrolltext
if ! prompt_yesno "Confirmation" "Lancer la création de la VM ?"; then
  exit 0
fi

image_dir="/var/lib/vz/template/iso"
image_name="debian-13.3.0-amd64-netinst.iso"
image_path="${image_dir}/${image_name}"
image_url="https://cdimage.debian.org/debian-cd/13.3.0/amd64/iso-cd/${image_name}"

if [[ ! -f "$image_path" ]]; then
  echo "Téléchargement de l'ISO Debian 13.3..." >&2
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
  --scsihw virtio-scsi-pci \
  $options

qm set "$vm_id" \
  --scsi0 "${storage}:${disk_size}G" \
  --ide2 "${storage}:iso/${image_name},media=cdrom" \
  --boot order=scsi0;ide2

whiptail --title "Terminé" --msgbox "VM Debian 13.3 créée (ISO attachée)." 10 60
