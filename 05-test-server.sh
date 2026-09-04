#!/bin/bash
# ==========================================================================
# 05-test-server.sh
# Vérifie que le serveur natif démarre correctement via systemd.
#
# À lancer en root : sudo bash 05-test-server.sh
# ==========================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-config.sh"

PASS=0
FAIL=0

check() {
  local desc="$1"; shift
  if "$@"; then
    echo "  [OK] $desc"
    PASS=$((PASS+1))
  else
    echo "  [ECHEC] $desc"
    FAIL=$((FAIL+1))
  fi
}

echo "=== 1/4 : Vérification du binaire ==="
check "EcoServer présent et exécutable" test -x "$INSTALL_DIR/EcoServer"
check "eco-server.env présent" test -f "$INSTALL_DIR/eco-server.env"

echo ""
echo "=== 2/4 : Démarrage via systemd ==="
systemctl restart eco-server
echo "  -> Attente 25s pour laisser le serveur s'initialiser..."
sleep 25

check "Service actif (running)" systemctl is-active --quiet eco-server

echo ""
echo "=== 3/4 : Vérification du process et du port web ==="
check "Processus EcoServer trouvé" pgrep -f "$INSTALL_DIR/EcoServer" >/dev/null
check "Port web 3001 répond" bash -c "curl -sf -o /dev/null http://localhost:3001 || curl -sf -o /dev/null http://localhost:3001/"

echo ""
echo "=== 4/4 : Dernières lignes de log ==="
journalctl -u eco-server -n 30 --no-pager

echo ""
echo "=========================================================="
echo " Résultat : $PASS test(s) OK, $FAIL test(s) en échec."
if [[ $FAIL -eq 0 ]]; then
  echo " Le serveur natif semble fonctionner correctement."
else
  echo " Vérifie les logs ci-dessus (journalctl -u eco-server -f)"
  echo " et surtout l'erreur 'libgdiplus' si le process crash direct."
fi
echo "=========================================================="

exit $FAIL
