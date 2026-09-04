# Migration Eco : Docker → installation native

## Récupérer ce dépôt sur ton VPS

```bash
git clone https://github.com/guillaumemen/Eco-serv.git /root/eco-migration
cd /root/eco-migration
chmod +x *.sh
```

Voir tout en bas pour créer le dépôt GitHub si ce n'est pas déjà fait.

## Important : Docker n'est jamais touché

Le container Docker `eco` continue de tourner normalement pendant toute la
migration — il n'est ni arrêté, ni modifié, ni supprimé par ces scripts.
Ils installent le serveur natif **en parallèle**, dans `/eco`. Les deux
serveurs (Docker sur ses ports actuels + natif dans `/eco`) peuvent donc
coexister le temps que tu valides que la version native fonctionne. À toi
de décider quand/si tu veux arrêter le container manuellement, une fois
que tu es satisfait du résultat.

## Avant de commencer

- **Le SDK .NET n'est pas nécessaire.** Le serveur Eco pour Linux est un
  binaire auto-contenu ; il embarque son propre runtime .NET. Les seules
  dépendances système sont `libgdiplus` et `libc6-dev` (installées
  automatiquement par le script 1).
- `DOCKER_DIR="/opt/eco-server"` (là où vit ton `docker-compose.yml` et les
  volumes actuels) et `INSTALL_DIR="/eco"` (nouvelle installation native,
  dossier séparé pour ne rien écraser).
- Seuls `Configs/`, `Storage/` et `Mods/` sont sauvegardés et migrés. Les
  dossiers `Mods-incompatibles`, `Mods-ancienne-version-*` et
  `backup-avant-reset-*` déjà présents dans `/opt/eco-server` sont
  volontairement ignorés — ils restent sur place, intacts.
- Tous les scripts numérotés doivent être lancés **en root** (`sudo bash ...`),
  dans l'ordre, depuis le même dossier.

## Ordre d'exécution

1. `sudo bash 01-backup-and-install.sh`
   Copie Configs/Storage/Mods + docker-compose.yml dans
   `/root/eco-backup/<horodatage>/` (sans toucher au container Docker,
   qui continue de tourner), installe les dépendances, télécharge le
   serveur natif via SteamCMD dans `/eco`. Extrait aussi automatiquement
   ton `userToken` depuis le compose actuel.

2. `sudo bash 02-migrate-data.sh`
   Copie les données sauvegardées vers `/eco` et crée `start.sh`
   (pratique pour tester en mode interactif avant de passer par systemd :
   `sudo -u eco /eco/start.sh`).

3. `sudo bash 03-install-service.sh`
   Installe `eco-server.service` dans systemd, l'active au démarrage.

4. `sudo bash 04-ufw-ports.sh`
   Ouvre les ports UFW réellement utilisés par ta config (3000/udp,
   3001/tcp, 3002/tcp). La plage complète 3000-3004 est proposée en
   commentaire si tu en as besoin plus tard.

5. `sudo bash 05-test-server.sh`
   Démarre le service, attend l'initialisation, vérifie process + port web
   + logs, et donne un résumé pass/fail.

## Une fois que tout fonctionne

Le container Docker tourne toujours normalement (il n'a jamais été touché).
Une fois que tu as confirmé que le serveur natif fonctionne bien dans
`/eco` et que les joueurs peuvent s'y connecter, c'est à toi de décider
quand arrêter le container Docker — par exemple :

```bash
cd /opt/eco-server && docker compose stop
# Optionnel, une fois vraiment sûr de toi :
# docker compose down
```

Attention : si les deux serveurs tournent en même temps sur les mêmes
ports (3000/3001/3002), il y aura un conflit de port. Pense à changer les
ports de l'un des deux le temps du test, ou à arrêter temporairement le
container pour tester le natif sans conflit.

Garde le dossier `/root/eco-backup/` un moment au cas où.

## Commandes utiles

```bash
sudo systemctl status eco-server      # état du service
sudo systemctl restart eco-server     # redémarrer
sudo journalctl -u eco-server -f      # logs en direct
```

## En cas de problème

- **`DllNotFoundException: libgdiplus`** → `sudo apt install libgdiplus`
  puis relance le service.
- **Le service ne démarre pas du tout** → vérifie que
  `/eco/eco-server.env` contient bien une ligne `ECO_USER_TOKEN=...`
  non vide.
- **Le port web ne répond pas** → vérifie `LocalWebIP` dans
  `/eco/Configs/Network.eco` (doit être `"0.0.0.0"` pour être accessible
  depuis l'extérieur).

## Créer et pousser le dépôt GitHub

Ces fichiers ne contiennent aucun secret (le token est extrait à
l'exécution et stocké uniquement dans `eco-server.env`, exclu par
`.gitignore`). Tu peux donc les mettre sur GitHub, même en public si tu veux.

1. Crée un dépôt vide sur GitHub (sans README ni licence auto-générés) :
   `https://github.com/new`

2. Sur ta machine (ou directement sur le VPS, dans le dossier téléchargé) :

```bash
cd eco-migration
git remote add origin https://github.com/<ton-user>/<ton-repo>.git
git branch -M main
git push -u origin main
```

3. Ensuite, sur le VPS, pour récupérer/mettre à jour les scripts :

```bash
git clone https://github.com/<ton-user>/<ton-repo>.git /root/eco-migration
# ou, si déjà cloné :
cd /root/eco-migration && git pull
```

Authentification GitHub : en HTTPS, GitHub demande un token d'accès
personnel (Settings → Developer settings → Personal access tokens) à la
place du mot de passe. En SSH, configure une clé sur le VPS et utilise
`git@github.com:<ton-user>/<ton-repo>.git` à la place.
