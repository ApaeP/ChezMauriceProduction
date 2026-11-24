# Chez Maurice Production

L’application Rails 8 de la refonte se trouve à la racine du dépôt. Le site actuellement en ligne fonctionne avec Next.js. Le précédent site Rails est conservé dans l’historique Git.

## Lancer le site

Avec Ruby 4.0.10, Bundler et libvips installés, exécuter cette commande à la racine du checkout de la refonte. Elle prépare SQLite et démarre le serveur de développement avec Tailwind.

```sh
bin/setup
```

Ouvrir [l’accueil](http://localhost:3000), [la galerie](http://localhost:3000/realisations) ou [le contact](http://localhost:3000/contact). Pour les lancements suivants, utiliser `bin/dev`. Un autre port peut être choisi, par exemple `PORT=3084 bin/dev`. Les pages publiques fonctionnent sans identifiants de fournisseur. Le catalogue initial est vide.

Rails 8.1.4.1 sert les pages et les assets. Tailwind CSS v4 est compilé par la gemme Rails. Turbo et Stimulus utilisent Importmap. Lato, Poppins et Font Awesome sont servis localement avec leurs licences dans `vendor/licenses/`. L’image d’accueil est le premier photogramme du film historique du studio, décliné en deux tailles WebP. La future bande démo reste à définir avec Paul.

La page contact reprend le téléphone, l’adresse et le courriel publiés. Le clic sur le courriel ouvre la messagerie du visiteur. Valider le parcours souhaité et les coordonnées de l’hébergeur dans les mentions légales avant la bascule.

## Consulter l’ancien Rails

La révision `47ca43903537c6a34c86f70e6a5b7aac21eff4d6` contient le dernier arbre Rails historique, notamment le formulaire de contact, ses deux e-mails de suivi, son anti-spam, les logos et le film du studio. Depuis la racine du dépôt, on peut lire un fichier à cette révision en gardant son checkout actuel.

```sh
git show 47ca43903537c6a34c86f70e6a5b7aac21eff4d6:app/views/contacts/_form.html.erb
```

Pour consulter l’ensemble des fichiers versionnés, extraire cette révision dans un dossier temporaire distinct.

```sh
dossier_historique=$(mktemp -d)
git archive --format=tar 47ca43903537c6a34c86f70e6a5b7aac21eff4d6 | tar -xf - -C "$dossier_historique"
printf '%s\n' "$dossier_historique"
```

Les données éditoriales et les vignettes demandent leurs propres exports. Le [guide de reprise du catalogue](docs/reprise-catalogue.md) décrit les sources Next.js et Rails.

## Vérifier un film

1. En local, partir d’un [import de brouillons](docs/reprise-catalogue.md). Pour un essai visuel manuel, utiliser un film et un identifiant YouTube dont le propriétaire autorise l’intégration. Renseigner les catégories et joindre la véritable miniature si elles sont disponibles.
2. Une fiche en brouillon donne une 404 à son URL et reste absente de la galerie et du [sitemap](http://localhost:3000/sitemap.xml). Une fois sa publication explicitement validée, la fiche apparaît sous `/realisations/:id`.
3. Dans la galerie, choisir une catégorie, faire défiler puis ouvrir une vignette. L’URL prend celle du film et le focus rejoint la modale. Fermer avec le bouton, Échap ou Précédent. Le filtre, la position et le focus reviennent à la vignette. Le bouton Suivant rouvre le film.
4. Recharger l’URL du film ou l’ouvrir dans un autre onglet. Une page complète présente le titre et le lecteur dans le HTML servi par Rails. Contrôler le titre, la description, l’URL canonique et les conditions de publication du balisage vidéo. Voir les [vérifications SEO](docs/seo.md).

Les tests système créent des fiches dans la base de test et bloquent le lecteur externe. Avec Chrome installé, exécuter les vérifications depuis la racine du dépôt.

```sh
bin/rails test:all
bin/rails zeitwerk:check
bin/rails tailwindcss:build
bin/jobs check
```

## File de tâches et connexions

Le site utilise SQLite en développement, en test et en production. En développement, lancer `bin/jobs` dans un second terminal pour traiter les tâches persistantes. En production, le rôle Kamal dédié lance un seul worker à un thread. Le superviseur, le dispatcher des tâches différées et le worker s’exécutent dans le même processus Ruby en mode async. Le dispatcher permet les reprises différées. Les tâches réussies sont supprimées à la fin de leur exécution. Les échecs restent consultables. Aucun scheduler périodique ni worker dans Puma n’est configuré.

- La [recette du transfert privé](docs/recette-transfert-prive.md) utilise le projet Frame.io « Publications ». Une fois la recette ouverte, y déposer ou y copier un film déclenche son transfert par le worker vers la chaîne YouTube prévue, en privé. Rails conserve la fiche en brouillon. Les fichiers déjà présents avant l’ouverture sont exclus. Le transfert reste désactivé par défaut.
- Le [guide Frame.io V4](docs/frame-io.md) décrit les droits de lecture de l’original et des métadonnées, ainsi que les modes de connexion pris en charge.
- Le [guide YouTube](docs/youtube.md) décrit le consentement du propriétaire, le contrôle de la chaîne et la reprise du transfert.
- [Déploiement et sauvegarde](docs/deploiement.md) décrit le proxy partagé, les secrets, le volume persistant, les deux rôles et la répétition de restauration.

Le parcours éditorial de publication sur le site et l’expérience de la bande démo restent à définir avec Paul. La recette privée peut être validée indépendamment de ces choix.
