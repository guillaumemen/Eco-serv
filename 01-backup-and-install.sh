#!/bin/bash
# ==========================================================================
# 01-backup-and-install.sh
# - Sauvegarde (copie) les données (Configs/Storage/Mods) du serveur Docker
#   actuel, SANS jamais l'arrêter ni le modifier — le container continue
#   de tourner normalement pendant et après ce script.
# - Installe les dépendances nécessaires (PAS de SDK .NET : EcoServer est
#   un binaire auto-contenu sur Linux, il ne lui faut que libgdiplus et
#   libc6-dev, plus les libs 32-bit pour faire tourner steamcmd)
# - Télécharge le serveur Eco via SteamCMD dans $INSTALL_DIR
#
# À lancer en root : sudo bash 01-backup-and-install.sh
# ==========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/00-config.sh"

if [[ $EUID -ne 0 ]]; then
  echo "Ce script doit être lancé en root (sudo)." >&2
  exit 1
fi

if [[ "$(readlink -f "$DOCKER_DIR")" == "$(readlink -f "$INSTALL_DIR" 2>/dev/null || echo "$INSTALL_DIR")" ]]; then
  echo "DOCKER_DIR et INSTALL_DIR sont identiques ($DOCKER_DIR)." >&2
  echo "Cela écraserait tes données Docker actuelles. Change INSTALL_DIR dans 00-config.sh." >&2
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

echo "=== 1/5 : Sauvegarde des données actuelles ==="
mkdir -p "$BACKUP_DIR"

for folder in Configs Storage Mods; do
  if [[ -d "$DOCKER_DIR/$folder" ]]; then
    echo "  -> Copie de $DOCKER_DIR/$folder"
    cp -a "$DOCKER_DIR/$folder" "$BACKUP_DIR/"
  else
    echo "  !! Dossier introuvable : $DOCKER_DIR/$folder (vérifie DOCKER_DIR dans 00-config.sh)"
  fi
done

if [[ -f "$DOCKER_DIR/docker-compose.yml" ]]; then
  cp -a "$DOCKER_DIR/docker-compose.yml" "$BACKUP_DIR/docker-compose.yml.bak"
fi

echo "Sauvegarde terminée dans : $BACKUP_DIR"
echo "$BACKUP_DIR" > "$BACKUP_ROOT/.last-backup"

echo ""
echo "=== 2/5 : Extraction du userToken depuis docker-compose.yml ==="
USER_TOKEN=""
if [[ -f "$DOCKER_DIR/docker-compose.yml" ]]; then
  USER_TOKEN=$(grep -oP -- '--userToken=\K[^"'\''[:space:]]+' "$DOCKER_DIR/docker-compose.yml" || true)
fi

if [[ -z "$USER_TOKEN" ]]; then
  echo "  !! Impossible d'extraire automatiquement le userToken."
  echo "     Tu devras le renseigner manuellement dans $BACKUP_DIR/eco-server.env"
  echo "ECO_USER_TOKEN=" > "$BACKUP_DIR/eco-server.env"
else
  echo "  -> Token extrait avec succès (masqué)."
  echo "ECO_USER_TOKEN=$USER_TOKEN" > "$BACKUP_DIR/eco-server.env"
fi
chmod 600 "$BACKUP_DIR/eco-server.env"

echo ""
echo "=== 3/5 : Docker NON touché ==="
echo "  -> Le container '$CONTAINER_NAME' continue de tourner normalement."
echo "     On installe juste le serveur natif en parallèle dans $INSTALL_DIR."

echo ""
echo "=== 4/5 : Installation des dépendances ==="
export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt-get update -y
add-apt-repository -y multiverse || true
apt-get update -y

# Pré-acceptation de la licence Steam pour une installation non-interactive
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note '' | debconf-set-selections

apt-get install -y curl wget tar libgdiplus libc6-dev lib32gcc-s1 steamcmd

echo ""
echo "=== 5/5 : Création de l'utilisateur système et téléchargement du serveur ==="
if ! id "$ECO_USER" &>/dev/null; then
  useradd -r -m -d "/home/$ECO_USER" -s /usr/sbin/nologin "$ECO_USER"
  echo "  -> Utilisateur système '$ECO_USER' créé."
else
  echo "  -> Utilisateur '$ECO_USER' déjà existant."
fi

mkdir -p "$INSTALL_DIR"
chown -R "$ECO_USER:$ECO_USER" "$INSTALL_DIR"

echo "  -> Téléchargement du serveur Eco via SteamCMD (appid $STEAM_APPID)..."
sudo -u "$ECO_USER" steamcmd \
  +force_install_dir "$INSTALL_DIR" \
  +login anonymous \
  +app_update "$STEAM_APPID" validate \
  +quit

echo ""
echo "=========================================================="
echo " Étape 1 terminée."
echo " Sauvegarde : $BACKUP_DIR"
echo " Serveur natif téléchargé dans : $INSTALL_DIR"
echo " Prochaine étape : 02-migrate-data.sh"
echo "=========================================================="
