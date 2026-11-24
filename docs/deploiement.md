# Déploiement sur le VPS personnel

La configuration cible le proxy Kamal partagé de `vps-perso`, le compte SSH
`ubuntu` et l’image Linux amd64 `ghcr.io/apaep/chez-maurice-production`.
Le service utilise deux conteneurs sur le même VPS et le même volume Docker
local `chez-maurice-production-storage`, monté dans chacun sous `/rails/storage`.

- Le web prépare les schémas avec `bin/rails db:prepare`, puis sert Rails.
  Le proxy route le domaine `APP_HOST`, termine HTTPS et contrôle `/up`.
- Le worker exécute `bin/jobs`. Son verrou `flock` sur le volume retarde
  le nouveau processus jusqu’à l’arrêt du précédent lors d’un déploiement.
  Kamal démarre le rôle web en premier et attend sa santé avant le nouveau
  worker. L’ancien web et l’ancien worker peuvent encore utiliser la base
  pendant les migrations. Toute migration incompatible exige une interruption
  préparée des écritures.
- La base applicative, Solid Queue, Solid Cache et Solid Cable utilisent les
  quatre bases SQLite de `config/database.yml`. Active Storage utilise le
  même volume. Un redémarrage des conteneurs conserve ces données.

## Valider localement

Exécuter ces commandes à la racine du dépôt après `bundle install`. Docker doit être démarré pour construire l’image.

```sh
APP_HOST=maurice.example.test SECRET_KEY_BASE=validation-locale KAMAL_REGISTRY_PASSWORD=validation-locale bundle exec kamal config
docker build --platform linux/amd64 -t chez-maurice-production:verification .
```

La première commande rend la configuration sans accès SSH, 1Password ou
registre. Les valeurs de validation servent uniquement à cette commande.
La deuxième commande construit l’image à partir du checkout courant, y compris
les modifications locales. Pour une livraison, `bin/deploy` se place à la
racine du projet et Kamal construit depuis un clone du commit. Les deux builds
appliquent `.dockerignore` pour exclure les clés, les données de travail,
les documents Word à la racine et les anciens assets compilés. Les données
historiques conservées dans un répertoire privé frère restent hors du contexte
de construction.

## Préparer une première mise en ligne

1. Valider le catalogue et les liens YouTube publiables avant d’importer les
   données réelles. Conserver séparément une copie de la source historique.
2. Paul fournit le domaine. Définir `APP_HOST` avec le nom seul et vérifier les
   enregistrements DNS A et AAAA, ainsi que l’absence de conflit de domaine
   sur le proxy partagé. Le certificat est demandé lors du déploiement.
3. Préparer le coffre applicatif `chez_maurice_production_deploy`, l’élément
   `production` et son champ `SECRET_KEY_BASE` (valeur neuve issue de
   `bin/rails secret`). Installer `op` sur le poste de déploiement. Le lanceur
   lit la référence 1Password de `.kamal/production.env` et Kamal transmet
   cette valeur aux deux rôles. Conserver aussi les clés de tout futur
   credential chiffré ajouté à l’application.
   Le premier démarrage du site utilise uniquement ce secret applicatif.
   Pour raccorder une plateforme média, configurer le profil décrit plus bas.
   Le proxy Kamal v0.9.2 journalise la query string. Les retours Google et Adobe utilisent
   un fragment, que le navigateur garde localement. La page de retour l’efface
   puis soumet les paramètres dans le corps d’un POST de même origine,
   protégé par CSRF. Le GET et le POST atteignent donc le proxy avec une
   query string vide. Le journal de requêtes de Thruster est désactivé et
   Rails filtre ces champs. Conserver ce comportement lors de l’ajout
   éventuel de collecteurs de traces ou de journaux.
   [Journalisation de kamal-proxy](https://github.com/basecamp/kamal-proxy/blob/v0.9.2/internal/server/logging_middleware.go#L96)
4. Préparer l’accès privé au package GHCR. Pour une publication depuis le Mac,
   fournir `KAMAL_REGISTRY_PASSWORD` depuis 1Password avec les droits de
   lecture et d’écriture des packages et, si nécessaire, `GHCR_USERNAME`.
   Pour une future CI, utiliser un environnement GitHub `production`, une clé
   SSH dédiée, la clé d’identité du VPS préalablement vérifiée, le token GitHub
   temporaire pour GHCR et un compte de service 1Password limité au coffre.
5. Lier la racine du checkout de livraison au lanceur `bin/app` de
   `vps-perso`. Ce lanceur sélectionne la clé de l’agent SSH via
   `VPS_SSH_PUBLIC_KEY_FILE`. Le poste doit reconnaître la clé d’identité
   du VPS vérifiée auprès de l’hébergeur.
6. Mettre en place et tester la sauvegarde ci-dessous sur des données de
   répétition. Tester également les migrations et le remplacement du worker
   avec un volume conservé entre deux lancements.
7. Lors de la mise en ligne autorisée, exécuter depuis `vps-perso`
   `bin/app chez-maurice-production setup` pour la première installation,
   puis `bin/app chez-maurice-production deploy` pour les livraisons suivantes.
   Vérifier le certificat sur le domaine, `/up`, la galerie, une fiche et
   les journaux des deux rôles. L’alias `worker-logs` affiche le démarrage du
   superviseur Solid Queue. Une bascule d’image conserve la base à sa version
   courante.

## Profils média et secrets 1Password

Définir les variables de sélection dans l’environnement de `bin/deploy` pour
chaque livraison. Le lanceur charge les références du profil choisi et Kamal
les transmet au web et au worker.

| Fonction | Sélection au déploiement | Références du coffre |
| --- | --- | --- |
| Vitrine seule | Laisser tous les sélecteurs absents | `.kamal/production.env` |
| Connexion YouTube du propriétaire | `DEPLOY_YOUTUBE=1` | `.kamal/youtube.env` et `.kamal/encryption.env` |
| Connexion Frame.io du propriétaire | `FRAME_IO_AUTH_MODE=user` | `.kamal/frame-io-user.env` et `.kamal/encryption.env` |
| Compte de service Frame.io | `FRAME_IO_AUTH_MODE=server_to_server` | `.kamal/frame-io-server-to-server.env` |
| Transfert privé après dépôt ou copie | `FRAME_IO_PRIVATE_TRIAL=1`, en plus des connexions Frame.io et YouTube | `.kamal/frame-io-private-trial.env` pour `FRAME_IO_WEBHOOK_SECRET` |

La connexion YouTube se combine avec chacun des deux modes Frame.io. Le mode
Adobe détermine la paire de credentials et le compte utilisés. Les clés
`ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` et `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`
sont communes à toutes les connexions consenties par le propriétaire. Générer
ces deux valeurs une seule fois avec `bin/rails db:encryption:init`, les
conserver dans le coffre et les réutiliser lors d’un changement de profil ou
d’une restauration. Les références 1Password se trouvent dans
`.kamal/encryption.env`.

Le profil vitrine démarre sans connexion média. Avant toute souscription de recette, `bin/rails frame_io:ouvrir_recette` enregistre sur le volume les identifiants des fichiers préexistants du projet. Conserver cet inventaire lors des redémarrages, sauvegardes et restaurations. Les variables facultatives `FRAME_IO_TITLE_FIELD_ID` et `FRAME_IO_DESCRIPTION_FIELD_ID` désignent les champs texte réels du projet. Le guide précise l’ordre d’ouverture, la souscription, la vérification dans Studio et le contrôle du brouillon. [Recette du transfert privé](recette-transfert-prive.md)

Les références 1Password livrées ciblent l’élément `production`. La configuration ci-dessus utilise aussi un nom fixe de service et de volume. Pour une recette distante, vérifier la configuration effective de **la cible de recette** et ses propres références aux secrets avant de s’en servir. Changer uniquement `APP_HOST` réutiliserait le service et les données de production.

Pour un compte Frame.io dont le propriétaire choisirait le mode OAuth utilisateur, créer un credential **OAuth Web App**,
autoriser le callback HTTPS exact `https://DOMAINE/connexion-frame-io/retour`
et renseigner les scopes approuvés pour Frame.io V4, dont `openid` et
`offline_access`. Le propriétaire choisit son compte depuis les résultats
renvoyés par Frame.io après consentement. En mode serveur-à-serveur, utiliser
la paire de service, ses scopes et `FRAME_IO_ACCOUNT_ID`. Si la distribution
des originaux de ce compte demande un autre hôte de média, renseigner
`FRAME_IO_MEDIA_HOSTS` avec les hôtes autorisés séparés par une virgule.
[Connexion Frame.io](frame-io.md) · [Connexion YouTube](youtube.md)

## Sauvegarder SQLite et vérifier la restauration

Le service décrit par `vps-perso/docs/backups.md` réalise actuellement des
`pg_dump` et archive des fichiers. Prévoir son adaptation à SQLite et aux
fichiers locaux avant d’activer l’entrée de cette application.

Une courte interruption permet de capturer les quatre bases et leurs fichiers au même instant.

1. Prévoir une courte fenêtre d’indisponibilité. Suspendre les déploiements,
   arrêter proprement le web et le worker et attendre la fin des imports ou
   consoles qui écrivent dans le volume. Vérifier qu’aucun autre conteneur
   en écriture n’utilise le volume.
2. Monter le volume en lecture seule dans le processus de copie et archiver
   l’intégralité de son contenu au repos, y compris les fichiers WAL et SHM
   éventuels et les fichiers Active Storage. Une copie du seul
   `production.sqlite3` en activité peut perdre des transactions.
   Rouvrir le service après la copie locale.
3. Transférer l’archive chiffrée ou protégée par chiffrement du bucket vers le
   stockage de sauvegarde privé du VPS, avec manifeste daté, taille,
   empreinte SHA-256, version applicative, rétention et suivi des échecs.
4. Télécharger une copie depuis ce stockage et vérifier son empreinte.
   L’extraire dans un **nouveau volume isolé**, avec droits UID/GID 1000.
   Exécuter `PRAGMA integrity_check;` sur chacune des quatre bases
   (résultat `ok`) puis `PRAGMA foreign_key_check;` (zéro ligne).
5. Démarrer uniquement le web avec l’image correspondant au manifeste, le
   volume restauré et les secrets nécessaires, sur une cible isolée avec
   sorties externes désactivées. Comparer les comptes de fiches et de tâches
   en attente, ainsi que plusieurs vignettes et fiches à la référence.
   Garder le worker arrêté pendant cette vérification pour préserver la file.
   Documenter le résultat et la durée de restauration.
