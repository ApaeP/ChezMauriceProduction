# Chez Maurice Production

Application Rails de la refonte. Le dossier `site/` est autonome. À la racine du dépôt, on retrouve l’application Rails historique avec son code, ses contenus, son formulaire de contact et ses médias. Le site actuellement en ligne est une troisième source, une application Next.js.

## Lancer le site

Depuis la racine du worktree, avec Ruby 4.0.10, Bundler et libvips installés, lancer :

```sh
cd site
bin/setup
```

Ouvrir [l’accueil](http://localhost:3000), [la galerie](http://localhost:3000/realisations) ou [le contact](http://localhost:3000/contact). Pour les lancements suivants, utiliser `bin/dev`. Un autre port peut être choisi, par exemple `PORT=3084 bin/dev`. Les pages publiques fonctionnent sans identifiants de fournisseur. Le catalogue initial est vide.

Rails 8.1.4.1 sert les pages et les assets. Tailwind CSS v4 est compilé par la gemme Rails. Turbo et Stimulus utilisent Importmap. Lato, Poppins et Font Awesome sont servis localement avec leurs licences dans `vendor/licenses/`. L’image d’accueil est le premier photogramme du film historique du studio, décliné en deux tailles WebP. La future bande démo reste à définir avec Paul.

La page contact reprend le téléphone, l’adresse et le courriel publiés. Le clic sur le courriel ouvre la messagerie du visiteur. L’ancienne collecte par formulaire, ses deux e-mails de suivi et son anti-spam restent consultables dans l’application historique. Valider le parcours souhaité et les coordonnées de l’hébergeur dans les mentions légales avant la bascule.

## Vérifier un film

1. En local, partir d’un [import de brouillons](docs/reprise-catalogue.md). Pour un essai visuel manuel, utiliser un film et un identifiant YouTube dont le propriétaire autorise l’intégration. Renseigner les catégories et joindre la véritable miniature si elles sont disponibles.
2. Une fiche en brouillon donne une 404 à son URL et reste absente de la galerie et du [sitemap](http://localhost:3000/sitemap.xml). Une fois sa publication explicitement validée, la fiche apparaît sous `/realisations/:id`.
3. Dans la galerie, choisir une catégorie, faire défiler puis ouvrir une vignette. L’URL prend celle du film et le focus rejoint la modale. Fermer avec le bouton, Échap ou Précédent. Le filtre, la position et le focus reviennent à la vignette. Le bouton Suivant rouvre le film.
4. Recharger l’URL du film ou l’ouvrir dans un autre onglet. Une page complète présente le titre et le lecteur dans le HTML servi par Rails. Contrôler le titre, la description, l’URL canonique et les conditions de publication du balisage vidéo. Voir les [vérifications SEO](docs/seo.md).

Pour reproduire le parcours sans compte ni vidéo réelle, les tests système créent des fiches dans la base de test et bloquent le lecteur externe. Chrome doit être disponible. On peut lancer les vérifications depuis `site/` :

```sh
bin/rails test:all
bin/rails zeitwerk:check
bin/rails tailwindcss:build
bin/jobs check
```

## File de tâches et connexions

Le site utilise SQLite en développement, en test et en production. En développement, lancer `bin/jobs` dans un second terminal pour traiter les tâches persistantes. En production, le rôle Kamal dédié lance un seul worker à un thread. Le superviseur, le dispatcher des tâches différées et le worker s’exécutent dans le même processus Ruby en mode async. Le dispatcher permet les reprises différées. Les tâches réussies sont supprimées à la fin de leur exécution. Les échecs restent consultables. Aucun scheduler périodique ni worker dans Puma n’est configuré.

- [Frame.io V4](docs/frame-io.md) fournit la lecture des métadonnées et le téléchargement en flux de l’original. L’accès est désactivé tant que le mode de connexion du studio reste à confirmer. Le guide distingue les deux profils OAuth conservés dans le code et le cas des comptes Legacy auto-migrés pouvant encore utiliser un ancien jeton Frame.io.
- [Google et YouTube](docs/youtube.md) couvrent le consentement du propriétaire, le contrôle de la chaîne et le protocole d’envoi reprenable. Le client rend l’URL de session à l’appelant avant le premier envoi d’octets. Elle doit rester confidentielle.
- [Déploiement et sauvegarde](docs/deploiement.md) décrit le proxy partagé, les secrets, le volume persistant, les deux rôles et la répétition de restauration.

Les deux clients peuvent se tester séparément. Le webhook Frame.io et la tâche persistante qui reliera la lecture de l’original, la session YouTube et la mise à jour de la fiche restent à réaliser. La reprise du protocole YouTube est disponible pour cette future tâche.

Un même export pourra viser « Site », « Bande démo » ou les deux. Avec le propriétaire, il reste à identifier les champs et options du projet réel, le signal d’export final et la visibilité YouTube voulue. Paul précisera le parcours de la bande démo. Pour la recette de bout en bout, il faudra l’accès au projet Frame.io, l’autorisation de la chaîne YouTube, les textes et légendes des films, et un original dont l’envoi est autorisé.
