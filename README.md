# Proxmox Script

Ce dépôt fournit un menu interactif pour créer rapidement des LXC Debian 12 et des VM Ubuntu 24.04 Cloud-Init.

## Lancement rapide

```bash
curl -fsSL https://raw.githubusercontent.com/GalaxieOn/proxmox-script/main/menu.sh -o menu.sh \
  && chmod +x menu.sh \
  && PROXMOX_SCRIPT_BASE_URL="https://raw.githubusercontent.com/GalaxieOn/proxmox-script/main" ./menu.sh
```

**Recommandation :** publiez et utilisez des *releases* GitHub afin de figer les versions (ex: `.../releases/download/v1.0.0/menu.sh`).
