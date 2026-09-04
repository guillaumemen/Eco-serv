#!/bin/bash
# ==========================================================================
# 02-migrate-data.sh
# Copie les données sauvegardées (Configs/Storage/Mods + token) depuis le
# backup Docker vers l'installation native /opt/eco-server, et crée le
# script de lancement start.sh.
#
# À lancer en root : sudo bash 02-migrate-data.sh [chemin_du_backup]
# Si aucun chemin n'est donné, le dernier backup créé est utilisé.
# ==========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-config.sh"

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être lancé en root (sudo)." >&2
  exit 1
fi

if [[ -n "${1:-}" ]]; then
  BACKUP_DIR="$1"
elif [[ -f "$BACKUP_ROOT/.last-backup" ]]; then
  BACKUP_DIR=$(cat "$BACKUP_ROOT/.last-backup")
else
  echo "Aucun backup spécifié et aucun backup précédent trouvé." >&2
  echo "Usage: $0 /root/eco-backup/20260904-153000" >&2
  exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Le dossier de backup n'existe pas : $BACKUP_DIR" >&2
  exit 1
fi

echo "=== Migration depuis : $BACKUP_DIR ==="

if [[ ! -d "$INSTALL_DIR" ]] || [[ ! -f "$INSTALL_DIR/EcoServer" ]]; then
  echo "Le serveur natif ne semble pas installé dans $INSTALL_DIR." >&2
  echo "Lance d'abord 01-backup-and-install.sh." >&2
  exit 1
fi

for folder in Configs Storage Mods; do
  if [[ -d "$BACKUP_DIR/$folder" ]]; then
    echo "  -> Copie de $folder vers $INSTALL_DIR/$folder"
    rm -rf "${INSTALL_DIR:?}/$folder"
    cp -a "$BACKUP_DIR/$folder" "$INSTALL_DIR/$folder"
  else
    echo "  !! $folder absent du backup, ignoré."
  fi
done

echo "  -> Copie du fichier d'environnement (token)"
cp -a "$BACKUP_DIR/eco-server.env" "$INSTALL_DIR/eco-server.env"
chmod 600 "$INSTALL_DIR/eco-server.env"

echo "  -> Ajustement des permissions pour l'utilisateur $ECO_USER"
chown -R "$ECO_USER:$ECO_USER" "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/EcoServer"

echo "  -> Création du script de lancement start.sh"
cat > "$INSTALL_DIR/start.sh" <<'EOF'
#!/bin/bash
# Wrapper de lancement — lit le token depuis eco-server.env
cd "$(dirname "${BASH_SOURCE[0]}")"
set -a
source ./eco-server.env
set +a
exec ./EcoServer --userToken="$ECO_USER_TOKEN"
EOF
chmod +x "$INSTALL_DIR/start.sh"
chown "$ECO_USER:$ECO_USER" "$INSTALL_DIR/start.sh"

echo ""
echo "=========================================================="
echo " Migration terminée."
echo " Données en place dans : $INSTALL_DIR"
echo " Prochaine étape : installer le service systemd (eco-server.service)"
echo "=========================================================="
