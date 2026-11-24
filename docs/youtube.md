# Transfert d’un original vers YouTube

`Youtube::Client` crée une session puis transfère un fichier en fragments de
8 Mio. La taille du dernier fragment correspond aux octets restants. Chaque
reprise commence par interroger Google sur les octets reçus. Le client accepte
les fichiers binaires lisibles et repositionnables, comme un `File` ouvert en
`rb`. [Protocole de transfert YouTube](https://developers.google.com/youtube/v3/guides/using_resumable_upload_protocol)

## Autoriser la chaîne

### Préparer le projet Google

1. L’exploitant active YouTube Data API v3, configure l’écran de consentement et crée un client OAuth de type **Application Web**. Il inscrit l’URL exacte du retour, par exemple `http://localhost:3000/connexion-youtube/retour` en local et `https://<domaine>/connexion-youtube/retour` en production. Utiliser ce même hôte et ce même port dans le navigateur.
2. Il fournit `YOUTUBE_CLIENT_ID` et `YOUTUBE_CLIENT_SECRET` à Rails. En production, il configure aussi `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` et `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`, indépendantes du secret de session. `bin/rails db:encryption:init` permet de générer ces deux valeurs ; les conserver dans le coffre, avec les clés nécessaires à la restauration des sauvegardes. En développement et en test, Rails utilise par défaut des clés dérivées de son secret local.
3. Lors du premier essai réel, vérifier dans le navigateur que Google revient sur `/connexion-youtube/retour` avec les données dans le fragment. Le navigateur demande cette page par GET, efface le fragment de son historique puis transmet la réponse par POST avec la session et le jeton CSRF Rails. Les deux requêtes doivent arriver sur le proxy sans paramètres dans l’URL. Conserver la journalisation des corps HTTP désactivée. Le code et les jetons restent masqués dans les journaux Rails. Google annonce le mode `fragment` dans ses [métadonnées publiques](https://accounts.google.com/.well-known/openid-configuration).
4. Pour un projet externe en mode **Testing**, déclarer le propriétaire comme utilisateur test. Avec les permissions YouTube demandées ici, le jeton de renouvellement de ce mode expire après sept jours. Préparer le statut et les éventuelles validations nécessaires avant les transferts récurrents. [Durée des jetons Google](https://developers.google.com/identity/protocols/oauth2#expiration)

### Connecter ou reconnecter la chaîne

Depuis la racine du dépôt, l’exploitant exécute `bin/rails youtube:inviter` dans l’environnement visé et transmet au propriétaire le code affiché par un canal privé. Le code est valable quinze minutes à compter de son émission. Son usage ouvre uniquement la gestion de la chaîne sur ce navigateur, jusqu’à la même échéance.

Le propriétaire ouvre `/connexion-youtube`, saisit ce code, puis choisit **Autoriser avec Google**. Sur Google, il sélectionne le compte et la chaîne voulus et accorde la lecture de la chaîne (`youtube.readonly`) et l’envoi de vidéos (`youtube.upload`). Rails utilise un flux serveur avec état à usage unique, PKCE S256 et accès hors connexion. JavaScript doit être activé pour terminer le retour. Le propriétaire revient sur la page de gestion, où le nom et l’identifiant renvoyés par Google confirment la chaîne retenue. Le retour par fragment a été testé dans Chrome avec un fournisseur simulé. La validation du client Web et du mode de retour sur le compte Google du propriétaire reste à faire. Le jeton de renouvellement est chiffré en SQLite ; seul l’identifiant de l’invitation de gestion transite dans la session. [Protocole OAuth pour applications Web](https://developers.google.com/identity/protocols/oauth2/web-server)

Pour changer de chaîne ou rétablir une autorisation expirée ou révoquée, émettre un nouveau code puis choisir **Reconnecter avec Google**. Une fois les deux permissions accordées et la chaîne identifiée, cette connexion devient celle des prochains transferts. Un refus, une permission manquante ou une chaîne ambiguë laisse la connexion précédente en place. **Quitter l’espace de connexion** ferme l’accès de gestion du navigateur et conserve l’autorisation de transfert.

## Contrat pour l’appelant

1. Enregistrer pour l’export l’identifiant de la chaîne choisie lors du
   consentement. Le client le compare à la connexion active et à la chaîne
   indiquée par Google avant chaque création ou reprise. Reconnecter une autre
   chaîne suspend les anciens transferts jusqu’à décision du propriétaire.
   Identifier l’export original par sa version et son empreinte. Garder ce
   fichier immuable sur toute la durée du transfert. Fournir sa taille en
   octets et son type MIME, par exemple `video/mp4`.
2. Choisir le titre, la description, la catégorie officielle YouTube et la
   visibilité. `public`, `unlisted` et `private` sont acceptés. Une validation
   de chaîne peut utiliser `private`. Le projet décide séparément quels films
   apparaissent dans la galerie. L’API conserve son comportement par défaut
   pour les notifications d’abonnés.
3. Appeler une seule fois `start_session`, puis enregistrer durablement l’URL
   renvoyée pour **cet export** avant de transférer le premier octet. Traiter
   cette URL comme un secret. Si le POST échoue sans réponse, signaler la
   création incertaine avant de décider de l’ouverture d’une autre session.
4. Appeler `resume` avec l’URL enregistrée et le même original. Un succès
   renvoie l’identifiant de la vidéo créée. Enregistrer cet identifiant avant
   d’acquitter la tâche. YouTube peut encore traiter la vidéo.

Ces deux appels s’utilisent dans le processus autorisé à envoyer l’original.

```ruby
client = Youtube::Client.from_env
session_url = client.start_session(
  expected_channel_id: saved_channel_id, title: title, description: description, category_id: youtube_category,
  privacy_status: visibility, byte_size: expected_bytes, content_type: mime_type
)

# Enregistrer la session en base à ce point, puis la relire pour chaque reprise.
File.open(original_path, "rb") do |file|
  youtube_id = client.resume(expected_channel_id: saved_channel_id, session_url: saved_session_url, io: file,
    byte_size: expected_bytes, content_type: mime_type)
  # Enregistrer youtube_id pour cet export.
end
```

## Réagir aux interruptions

| Résultat | Action de l’appelant |
| --- | --- |
| `MediaApi::TransportError` pendant `resume` | Replanifier avec la même session et un délai progressif. Une coupure juste après le dernier PUT peut cacher un succès. La sonde suivante peut retrouver l’identifiant. |
| `Youtube::Client::RetryLater` | Différer la prochaine sonde. `retry_after` contient, lorsqu’il existe, l’en-tête HTTP brut en secondes ou sous forme de date HTTP. Sinon appliquer un délai progressif. |
| `Youtube::Client::SessionExpired` | Examiner l’état du transfert et la chaîne avant d’autoriser une nouvelle session. |
| `Youtube::Client::ChannelUnavailable` | Reconnecter la chaîne associée à l’export ou examiner la nouvelle destination avec le propriétaire. Le client ne transmet aucun octet à cette destination. |
| `MediaApi::Token::InvalidGrant` | Le propriétaire doit renouveler son consentement. Reprendre le transfert enregistré après reconnexion sur la même chaîne. |
| `MediaApi::HttpError` | Examiner `status` et `retry_after`. Pour un 401, contrôler le consentement et renouveler les autorisations si nécessaire. Pour un 403, vérifier les droits et le quota. |
| `Youtube::Client::ProtocolError` | Examiner les métadonnées de l’incident, en gardant les jetons et l’URL de session hors des journaux. |

Les tests HTTP simulés s’exécutent avec
`bin/rails test test/services/youtube/client_test.rb`. La recette avec accès
réel demande un fichier de test autorisé et la chaîne choisie par son
propriétaire. Vérifier dans YouTube Studio le titre, la visibilité, le
traitement et la présence d’une seule vidéo après interruption et reprise.
