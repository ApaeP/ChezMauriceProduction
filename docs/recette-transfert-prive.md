# Recette d’un dépôt Frame.io vers YouTube en privé

Une fois la recette ouverte, tout **nouveau dépôt ou toute nouvelle copie de vidéo** dans le projet Frame.io « Publications » (`53d90e32-935b-45e7-b693-5702318d606d`) peut créer une vidéo privée sur la chaîne `UCnuO-797M605z7yuAjaitpg`. L’action du propriétaire consiste à déposer ou copier le film dans ce projet. Le worker transfère l’original et conserve une réalisation en brouillon dans Rails. La galerie publique reste indépendante.

## Préparer la cible et les accès

1. Disposer d’une instance de cette révision joignable en HTTPS depuis Frame.io, de ses propres identifiants de service, secrets et volume SQLite, et des rôles web et worker sur ce volume. La cible doit autoriser les connexions sortantes aux fournisseurs et disposer d’assez de stockage temporaire dans le worker pour l’original entier. Les fichiers du dépôt et l’inventaire local de `vps-perso` ne désignent aucune instance HTTPS de recette pour Chez Maurice. `config/deploy.yml` et les références 1Password livrées ciblent la production. Changer uniquement `APP_HOST` réutiliserait ces ressources. [Déploiement et sauvegarde](deploiement.md)
2. Sur l’instance de recette, activer la connexion Frame.io approuvée par le studio. Elle doit pouvoir lire tout le projet, les métadonnées utilisées et télécharger l’original. Vérifier le compte et l’espace de travail qui contiennent « Publications ». Dans Frame.io, un **Account Owner** ou **Content Admin** peut gérer la souscription depuis les réglages *Webhooks* de cet espace. La voie de création par l’API demande un accès OAuth autorisé. [Modes de connexion Frame.io](frame-io.md) · [Configurer une souscription dans l’interface Frame.io](https://help.frame.io/en/articles/15382181-set-up-webhooks-in-frame-io)
3. Activer la connexion YouTube (`DEPLOY_YOUTUBE=1` pour Kamal), enregistrer le callback exact de la cible et émettre une invitation avec `bin/rails youtube:inviter` **sur cette instance**. Le propriétaire autorise sa chaîne depuis `/connexion-youtube`. Vérifier sur l’écran de retour l’identifiant `UCnuO-797M605z7yuAjaitpg` et l’accès du propriétaire à cette chaîne dans YouTube Studio. Conserver les clés de chiffrement stables sur les deux rôles. [Autoriser la chaîne](youtube.md)
4. Choisir une courte fenêtre pendant laquelle le propriétaire peut contrôler les nouveaux dépôts et copies dans ce projet. Préparer un court original dont le transfert privé est autorisé. Relever son titre, sa description et sa taille pour comparaison. Si des champs texte personnalisés existent, relever leurs identifiants de définition exacts pour `FRAME_IO_TITLE_FIELD_ID` et `FRAME_IO_DESCRIPTION_FIELD_ID`. Le nom du fichier sert de titre si le champ titre est absent ou vide. Sans description renseignée, YouTube reçoit une description vide.
5. **Avant la première souscription**, convenir avec le propriétaire de suspendre les mouvements de fichiers dans le projet jusqu’au signal de départ. Dans le conteneur Rails de recette, exécuter `bin/rails frame_io:ouvrir_recette` avec la connexion Frame.io autorisée. La commande parcourt le projet, ses sous-dossiers et ses piles de versions. Elle inscrit dans SQLite les identifiants des fichiers préexistants pour les exclure du transfert. Elle affiche l’heure et le nombre d’identifiants exclus. Elle ne télécharge aucun original, ne crée aucun brouillon et conserve ce premier inventaire si on la relance. Cette étape fonctionne avant l’activation du profil de transfert.

   Remplacer `ID_DU_COMPTE` ci-dessous par le compte vérifié. Comparer avec le propriétaire la liste enregistrée aux fichiers qu’il voit dans tout le projet. Vérifier explicitement les **deux fichiers déjà signalés**, ainsi que tout fichier supplémentaire présent à l’ouverture, y compris les versions. Si un ID manque, garder la réception désactivée et examiner les droits de lecture du compte sur les dossiers et versions concernés. Relancer la commande d’ouverture conserve l’inventaire initial.

   ```sh
   bin/rails runner 'puts FrameIoTrial.find_by!(account_id: "ID_DU_COMPTE", project_id: FrameIoPublication::PROJECT_ID).existing_file_ids.sort'
   ```

6. Sur l’espace de travail vérifié, créer une **nouvelle souscription** à `file.upload.completed`, `file.copied` et `file.ready`, avec l’URL `https://<hôte-de-recette>/webhooks/frame-io`. Noter son ID et conserver dès la création le secret de signature dans le coffre de **cette cible**. Vérifier sa disponibilité avec le moyen de création choisi. L’API V4 fournit ce secret dans sa réponse de création. L’emplacement de ce secret dans l’interface reste à confirmer sur le compte du studio. Si la souscription est créée active, la suspendre dans les réglages ou avec sa mise à jour `active: false` pendant la configuration. Garder la réception Rails désactivée jusque-là. Les notifications de métadonnées sont ignorées. [Créer un webhook V4](https://developer.frame.io/platform/v4/api-reference/webhooks/create) · [Régler son activation](https://developer.frame.io/platform/v4/api-reference/webhooks/update)
7. Fournir `FRAME_IO_PRIVATE_TRIAL=1` et `FRAME_IO_WEBHOOK_SECRET` aux deux rôles. Donner le signal de départ après les contrôles suivants.

## Suivre un transfert réel

1. Vérifier que `/up` répond, que les migrations de la révision sont appliquées et que le worker s’est enregistré. Depuis le conteneur Rails de recette, ces contrôles lisent la configuration et SQLite sans appeler les fournisseurs.

   ```sh
   bin/rails runner 'p [FrameIoPublication.enabled?, YoutubeConnection.current&.channel_id, FrameIoTrial.where(project_id: FrameIoPublication::PROJECT_ID).pluck(:account_id, :created_at)]'
   bin/rails runner 'p SolidQueue::Process.where(kind: "Worker").pluck(:hostname, :pid, :last_heartbeat_at)'
   ```

   Attendre `true`, la chaîne prévue, un inventaire pour le compte vérifié et un worker dont le dernier signe de vie est récent. Le worker et le web doivent utiliser la même version et le même volume.

2. Activer la souscription, puis inviter le propriétaire à déposer **ou** copier le fichier d’essai dans « Publications ». Relever l’ID du fichier **obtenu dans ce projet** et l’ID du compte Frame.io. Pour une copie d’un ancien original depuis un autre projet, comparer le fichier désigné par le signal natif et cette destination. Un `POST /webhooks/frame-io` avec une réponse `202` confirme la mise en file d’un signal accepté. Vérifier dans les journaux du rôle worker l’exécution de `FrameIoPublicationJob`. Un original en cours de préparation peut donner lieu à une attente.
3. Dans `bin/rails console` sur la même instance, remplacer les deux identifiants ci-dessous par ceux relevés. Cette requête utilise la clé unique du fichier et limite la sortie aux éléments de recette.

   ```ruby
   FrameIoPublication.where(account_id: "ID_DU_COMPTE", project_id: FrameIoPublication::PROJECT_ID, file_id: "ID_DU_FICHIER_DE_DESTINATION").joins(:realisation).pluck(:state, :review_reason, :realisation_id, "realisations.title", "realisations.description", "realisations.published", "realisations.youtube_id")
   ```

   Attendre **une seule ligne** avec `completed`, un ID YouTube et `published = false`. Les signaux de dépôt, de copie et de fin de traitement peuvent se recouvrir pour ce même fichier. Ils doivent aboutir au même brouillon et au même ID YouTube. Une seconde copie crée un nouveau fichier Frame.io, donc un nouvel export éligible.
4. Dans YouTube Studio, ouvrir la vidéo qui porte cet ID sur la chaîne prévue. Attendre la fin du traitement, contrôler la visibilité **Privée**, le titre, la description et la lecture du film choisi. Vérifier que la chaîne ne contient qu’un exemplaire correspondant à cet essai. Sur la vitrine de recette, vérifier que `/realisations/ID_DU_BROUILLON` renvoie 404 et que la galerie et `/sitemap.xml` omettent cette fiche. Relever la révision, l’heure du dépôt, les identifiants de fichier et de vidéo, le résultat du worker et les contrôles Studio. Garder les jetons, signatures et URL de session hors du compte rendu.

## Interpréter un écart et clore la fenêtre

- **Aucun brouillon.** Vérifier dans l’ordre la souscription, le code HTTP, le worker, le compte Frame.io, l’ID du projet, le type vidéo et l’absence du fichier de destination dans l’inventaire d’ouverture. Un webhook désactivé répond 404, une signature invalide ou périmée répond 401. Un événement ignoré répond 204. Un POST accepté peut concerner un fichier que le worker écarte ensuite.
- **Transfert interrompu.** Une interruption réseau pendant l’envoi permet une reprise avec la session déjà enregistrée. Le worker recharge l’original et vérifie son empreinte. Une session expirée, une création dont l’issue est inconnue ou une réponse finale incohérente demandent un examen. Si `review` ou `creating_session` persiste, contrôler l’état de la tâche et YouTube Studio avant toute intervention. Ouvrir une deuxième session pourrait créer une deuxième vidéo. [Cas de reprise YouTube](youtube.md)
- **Clôture.** Suspendre la souscription de recette à la fin de la fenêtre autorisée, puis contrôler les tâches déjà reçues et leur résultat. Une fois celles-ci traitées, retirer l’activation `FRAME_IO_PRIVATE_TRIAL` des deux rôles de cette instance. La vidéo privée créée et son brouillon persistent pour que le propriétaire puisse les vérifier.

Pour répéter le parcours en local, exécuter `bundle exec ruby test/smoke/frame_io_publication.rb` depuis le dépôt. Ce contrôle utilise un worker distinct, SQLite temporaire et des fournisseurs simulés. La validation distante exige un hôte HTTPS, les accès du studio, le dépôt ou la copie volontaire du propriétaire et le contrôle du résultat dans YouTube Studio.
