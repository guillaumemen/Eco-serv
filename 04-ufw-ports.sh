#!/bin/bash
# ==========================================================================
# 04-ufw-ports.sh
# Ouvre les ports Eco dans le pare-feu UFW.
#
# À lancer en root : sudo bash 04-ufw-ports.sh
# ==========================================================================
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être lancé en root (sudo)." >&2
  exit 1
fi

echo "=== Ports réellement utilisés par ta configuration actuelle ==="
ufw allow 3000/udp comment 'Eco - jeu (UDP)'
ufw allow 3001/tcp comment 'Eco - dashboard web (TCP)'
ufw allow 3002/tcp comment 'Eco - port additionnel (TCP)'

echo ""
echo "=== Plage par défaut Eco (3000-3004, TCP+UDP) ==="
echo "Décommente les lignes suivantes si tu veux ouvrir toute la plage"
echo "standard (utile si tu actives des ports optionnels plus tard) :"
echo ""
echo "# ufw allow 3000:3004/tcp comment 'Eco - plage TCP complète'"
echo "# ufw allow 3000:3004/udp comment 'Eco - plage UDP complète'"

ufw reload
ufw status verbose

echo ""
echo "=========================================================="
echo " Ports ouverts. Vérifie que ton fournisseur VPS n'a pas"
echo " aussi un pare-feu réseau externe (security group) à ouvrir."
echo "=========================================================="
