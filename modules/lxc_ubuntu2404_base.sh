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

ct_id=$(prompt_input "LXC Ubuntu 24.04" "ID du conteneur (CT ID)" "")
json_set "$json_file" "ct_id" "$ct_id"

hostname=$(prompt_input "LXC Ubuntu 24.04" "Hostname" "ubuntu2404")
json_set "$json_file" "hostname" "$hostname"

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

storage_list=$(list_storages_for_lxc || true)
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

disk=$(prompt_input "Ressources" "Disque (GB)" "8")
json_set "$json_file" "disk" "$disk"

ip_mode=$(prompt_menu "Réseau" "Adresse IP" 12 70 3 \
  "dhcp" "DHCP" \
  "statique" "Statique" )
json_set "$json_file" "ip_mode" "$ip_mode"

ip_cidr=""
gateway=""
if [[ "$ip_mode" == "statique" ]]; then
  ip_cidr=$(prompt_input "Réseau" "IP/CIDR (ex: 192.168.1.10/24)" "")
  gateway=$(prompt_input "Réseau" "Gateway" "")
  json_set "$json_file" "ip_cidr" "$ip_cidr"
  json_set "$json_file" "gateway" "$gateway"
fi

password=$(prompt_password "Sécurité" "Mot de passe root")
json_set "$json_file" "password" "$password"

options=$(prompt_input "Options" "Options supplémentaires (pct create)" "")
json_set "$json_file" "options" "$options"

summary=$(json_pretty "$json_file")
whiptail --title "Récapitulatif" --msgbox "$summary" 20 80 --scrolltext
if ! prompt_yesno "Confirmation" "Lancer la création du LXC ?"; then
  exit 0
fi

pveam update

template=$(get_ubuntu2404_template)
if [[ -z "$template" ]]; then
  echo "Template Ubuntu 24.04 introuvable via pveam." >&2
  exit 1
fi

template_path="/var/lib/vz/template/cache/${template}"
if [[ ! -f "$template_path" ]]; then
  echo "Téléchargement du template $template" >&2
  pveam download local "$template"
fi

net0="name=eth0,bridge=${bridge},ip=dhcp"
if [[ "$ip_mode" == "statique" ]]; then
  net0="name=eth0,bridge=${bridge},ip=${ip_cidr},gw=${gateway}"
fi

pct create "$ct_id" "$template_path" \
  --hostname "$hostname" \
  --cores "$cores" \
  --memory "$memory" \
  --rootfs "${storage}:${disk}G" \
  --net0 "$net0" \
  --password "$password" \
  --unprivileged 1 \
  --features nesting=1 \
  $options

pct start "$ct_id"

pct exec "$ct_id" -- bash -c "apt-get update && apt-get install -y ca-certificates curl"

whiptail --title "Terminé" --msgbox "LXC Ubuntu 24.04 créé et démarré." 10 60
