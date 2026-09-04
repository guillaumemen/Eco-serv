#!/bin/bash
# ==========================================================================
# Configuration partagée pour la migration du serveur Eco (Docker -> natif)
# À adapter à ton environnement AVANT de lancer les autres scripts.
# ==========================================================================

# Dossier contenant ton docker-compose.yml actuel et les volumes bind-mount
# (Configs, Storage, Mods). C'est /opt/eco-server chez toi.
DOCKER_DIR="/opt/eco-server"

# Nom du container Docker actuel (container_name dans ton compose)
CONTAINER_NAME="eco"

# Dossier racine des sauvegardes (un sous-dossier horodaté sera créé dedans)
BACKUP_ROOT="/root/eco-backup"

# Dossier d'installation native du serveur (différent de DOCKER_DIR pour
# ne jamais écraser les données Docker actuelles ni les anciens backups
# manuels déjà présents dans /opt/eco-server)
INSTALL_DIR="/eco"

# Utilisateur système dédié qui fera tourner le serveur (jamais en root)
ECO_USER="eco"

# App ID Steam officiel du serveur dédié Eco
STEAM_APPID="739590"
