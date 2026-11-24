# Lecture d’un export Frame.io V4

Le client Ruby `MediaApi::FrameIo` lit la fiche d’un fichier, les valeurs de ses champs personnalisés et les octets de son original. Le projet peut démarrer sans identifiants. Les opérations s’exécutent uniquement lorsqu’un appelant invoque le client.

## Statut pour le compte du studio

Le studio doit d’abord confirmer comment son compte Frame.io V4 est administré. L’application démarre avec l’accès Frame.io désactivé. Les profils facultatifs ci-dessous décrivent les chemins déjà codés et vérifiés avec HTTP simulé. Le mode du propriétaire et l’activation d’un profil restent en suspens.

Frame.io documente une autre possibilité pour certains comptes Legacy auto-migrés vers V4 qui ne sont pas administrés dans Adobe Admin Console. Ils peuvent continuer à utiliser un ancien jeton développeur Frame.io avec l’en-tête `x-frameio-legacy-token-auth: true` sur les appels à l’API. L’éligibilité du studio et la disponibilité d’un tel jeton restent à vérifier dans son compte. Le client livré couvre les deux profils OAuth ci-dessous. Une prise en charge du jeton Legacy demanderait un branchement et une recette dédiés après confirmation de cette voie. [Authentification Frame.io V4](https://developer.frame.io/platform/v4/docs/guides/authentication/overview)

## Profils OAuth disponibles dans le code

Le compte individuel Frame.io V4 doit utiliser l’authentification Adobe pour permettre un consentement utilisateur. Le mode technique S2S est réservé aux comptes V4 administrés par Adobe Admin Console. L’exploitant choisit un seul mode pour le processus Rails avec `FRAME_IO_AUTH_MODE`. Le site public fonctionne également sans configuration Adobe. [Types de comptes et d’authentification Frame.io](https://developer.adobe.com/frameio/guides/Authentication/)

### Consentement du propriétaire avec OAuth Web App

1. Dans Adobe Developer Console, associer l’API Frame.io V4 à un projet avec un credential **OAuth Web App**. Inscrire le retour HTTPS exact comme URI de redirection par défaut et configurer le motif autorisé pour cette même adresse. En développement, ajouter le propriétaire aux utilisateurs bêta du projet si Adobe le demande. Vérifier que son compte peut ouvrir le projet et télécharger l’original de la vidéo d’essai. [Installation du credential Web App et redirect URI](https://developer.adobe.com/developer-console/docs/guides/authentication/UserAuthentication/implementation) · [Consentement des bêta-utilisateurs](https://developer.adobe.com/developer-console/docs/guides/authentication/UserAuthentication/)
2. Configurer `FRAME_IO_AUTH_MODE=user`, `ADOBE_WEB_CLIENT_ID`, `ADOBE_WEB_CLIENT_SECRET` et `ADOBE_WEB_SCOPES` sur le serveur. La dernière variable reprend les scopes Frame.io réellement accordés au projet. L’application ajoute les scopes IMS `openid` et `offline_access`. Il faut que le credential autorise l’accès hors connexion, sinon l’application demande de corriger la configuration et de renouveler le consentement. Préparer en production les clés stables de chiffrement Active Record et la sauvegarde du volume SQLite décrites dans le [guide de déploiement](deploiement.md).
3. Pour un essai local, utiliser un certificat HTTPS approuvé par le navigateur pour `localhost`. Dans Adobe, enregistrer par exemple `https://localhost:3443/connexion-frame-io/retour`. Avec les chemins de ce certificat et de sa clé, démarrer la copie locale depuis la racine du dépôt.

   ```sh
   bin/rails db:prepare tailwindcss:build
   bundle exec puma -C /dev/null -b 'ssl://127.0.0.1:3443?key=/chemin/localhost-key.pem&cert=/chemin/localhost.pem' config.ru
   ```

4. Dans un deuxième terminal, depuis la même application et le même environnement, exécuter `bin/rails frame_io:inviter`. Transmettre le code au propriétaire par un canal privé. Il ouvre `/connexion-frame-io` sur le même hôte HTTPS et dispose de quinze minutes pour terminer. Il saisit le code, clique sur « Autoriser avec Adobe » et accorde les permissions. Rails interroge les comptes Frame.io accessibles avec l’autorisation effectivement délivrée. Un seul compte s’active immédiatement. Si plusieurs comptes sont disponibles, la page permet de choisir par nom et identifiant. Elle affiche ensuite le compte actif. Une annulation, une invitation expirée ou un refus laisse la connexion précédente disponible. [Comptes accessibles à l’utilisateur Frame.io](https://developer.frame.io/platform/v4/api-reference/accounts/index)
5. En production, utiliser le domaine retenu pour `https://<domaine>/connexion-frame-io/retour`. Une nouvelle invitation permet de remplacer le compte choisi. Quitter l’espace de connexion ferme l’accès de gestion. Pour révoquer les droits d’Adobe, le propriétaire peut retirer l’application depuis les applications connectées de son compte Adobe. [Guide Adobe du consentement utilisateur](https://developer.adobe.com/developer-console/docs/guides/authentication/UserAuthentication/)

Le retour du fournisseur utilise un code à usage unique dans le fragment de l’URL. La page de retour transmet le code et l’état à Rails dans le corps d’un POST. Le serveur échange ce code auprès d’Adobe IMS en présentant son identifiant et son secret par authentification HTTP Basic. Les jetons restent côté serveur. Une sélection en attente de confirmation est chiffrée et liée à l’invitation. Une sélection réussie remplace atomiquement le compte actif. [Référence Adobe IMS](https://developer.adobe.com/developer-console/docs/guides/authentication/UserAuthentication/ims)

Les jetons d’accès et de renouvellement sont chiffrés dans SQLite. À l’approche de l’expiration, le client obtient la nouvelle paire IMS lors de sa prochaine utilisation. Un verrou de fichier sur le volume persistant sérialise l’échange pour les processus Rails partageant la même base. La nouvelle paire est enregistrée en une mise à jour conditionnelle. Les autres écritures SQLite restent possibles pendant l’appel réseau. Une autorisation révoquée ou expirée nécessite un nouveau consentement. Adobe indique une durée par défaut de quatorze jours pour le jeton de renouvellement. Après une longue inactivité, par exemple entre deux transferts mensuels, le propriétaire peut donc devoir reconnecter le compte. Un arrêt entre la rotation distante et l’enregistrement de la réponse peut également nécessiter une reconnexion. Aucun renouvellement périodique n’est planifié. [Cycle de vie des jetons Adobe](https://developer.adobe.com/developer-console/docs/guides/authentication/UserAuthentication/ims)

### Compte de service S2S

Configurer `FRAME_IO_AUTH_MODE=server_to_server`, `FRAME_IO_ACCOUNT_ID` et la paire `ADOBE_CLIENT_ID` / `ADOBE_CLIENT_SECRET` du credential **Server-to-Server**. `ADOBE_SCOPES` contient la liste exacte des scopes délivrés pour ce credential. Attribuer au compte de service l’accès au projet Frame.io. Ce mode demande le jeton avec `grant_type=client_credentials`. [Adobe IMS pour les comptes de service](https://developer.adobe.com/developer-console/docs/guides/authentication/ServerToServerAuthentication/implementation)

### Hôtes de livraison des fichiers

Les deux modes reconnaissent les hôtes documentés `assets.frame.io` et `s3.amazonaws.com`. Si le compte fournit une URL sur un autre hôte de diffusion, confirmer cet hôte puis le déclarer dans `FRAME_IO_MEDIA_HOSTS` (noms HTTPS exacts séparés par des virgules). Les requêtes vers l’API principale portent le jeton de l’utilisateur ou du compte de service. Les requêtes de téléchargement utilisent l’URL signée temporaire et contrôlent chaque destination de redirection. [Médias Frame.io](https://developer.frame.io/platform/v4/docs/guides/media-links)

## Essai en console avec un export autorisé

Après obtention des accès, préparer un véritable identifiant de fichier accessible au compte et saisir ces expressions dans `bin/rails console`. Elles appellent Adobe et peuvent télécharger le fichier complet dans un fichier temporaire local. Les objets d’authentification masquent leurs secrets lorsqu’ils sont inspectés.

```ruby
client = MediaApi::FrameIo.from_env; nil
file_id = ENV.fetch("FRAME_IO_TEST_FILE_ID")
details = client.file(file_id)
details.slice("id", "name", "type", "file_size", "media_type")
fields = client.metadata(file_id)
fields.map { |field| field.slice("field_definition_id", "field_type", "value") }
Tempfile.create("maurice-original", binmode: true) do |file|
  bytes = client.download_original(file_id, output: file)
  puts "#{bytes} octets reçus"
end
```

Le téléchargement accepte un `File`, `Tempfile` ou `StringIO` binaire positionné en fin de fichier. Il écrit par morceaux et compare la taille reçue à celle annoncée par Frame.io lorsqu’elle est présente. Une erreur restaure la longueur initiale du fichier de destination. Le tableau de métadonnées conserve les identifiants, les types de champ et les valeurs tels que Frame.io les retourne. Le paramétrage métier des champs éditoriaux et des destinations « Site » et « Bande démo » reste à déterminer avec le propriétaire. [Fiche fichier](https://developer.frame.io/platform/v4/api-reference/files/show) · [Champs de métadonnées](https://developer.frame.io/platform/v4/api-reference/metadata/show)

Les tests HTTP simulent l’échange IMS, la liste des comptes avec pagination, les deux modes d’authentification, le renouvellement concurrent, la révocation et le téléchargement en flux. Les tests de contrôleur couvrent le parcours du propriétaire. Depuis la racine du dépôt, vérifier les clients avec `bin/rails test test/services/adobe test/services/media_api`. La validation du consentement sur le vrai compte, de ses droits de lecture et du fichier d’essai reste à faire avec le propriétaire.
