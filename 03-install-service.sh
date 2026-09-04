#!/bin/bash
# ==========================================================================
# 03-install-service.sh
# Installe et active le service systemd eco-server (démarrage au boot,
# redémarrage automatique en cas de crash).
#
# À lancer en root : sudo bash 03-install-service.sh
# ==========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être lancé en root (sudo)." >&2
  exit 1
fi

cp "$SCRIPT_DIR/eco-server.service" /etc/systemd/system/eco-server.service

systemctl daemon-reload
systemctl enable eco-server

echo ""
echo "=========================================================="
echo " Service systemd installé et activé au démarrage."
echo " Pour démarrer le serveur : sudo systemctl start eco-server"
echo " Pour voir les logs live  : sudo journalctl -u eco-server -f"
echo "=========================================================="
