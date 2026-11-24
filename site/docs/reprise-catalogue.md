# Reprendre les réalisations

Le site en ligne est une application Next.js. L’audit public a relevé 35 films et leurs identifiants Vimeo, sans description ni catégorie dans les données exposées. La source à demander pour préparer la bascule est l’export éditorial de cette application et ses fichiers image. Le dépôt Rails à la racine fournit une autre source, historique. Ses 35 entrées de seeds ont des catégories tirées au hasard et utilisent une colonne supprimée depuis.

## Export depuis la source Next.js

Demander au propriétaire les données qui alimentent la galerie du projet Next.js (module de données, CMS ou base selon son implémentation), les images originales et le critère d’ordre. Exécuter l’exporteur dans sa copie locale ou sur son export autorisé. Écrire un fichier UTF-8 `catalogue.json` et placer les images dans un dossier frère `originals/`. Voici un exemple de structure technique.

```json
{
  "version": 1,
  "source": "nextjs",
  "videos": [{
    "id": "fiche-de-test",
    "title": "Titre du fichier de test",
    "description": null,
    "position": 1,
    "vimeo_url": null,
    "categories": [],
    "thumbnail": {
      "key": "reference-de-l-image-dans-la-source",
      "file": "image-1",
      "filename": "vignette.png",
      "byte_size": 24576,
      "checksum": null
    }
  }]
}
```

- Utiliser l’identifiant stable de chaque fiche. Une clé texte convient, y compris un identifiant non numérique. Si la source utilise déjà l’identifiant Vimeo pour identifier chaque film de façon unique et stable, reprendre cette clé. Vérifier les doublons. L’indice du tableau varie avec le tri et ne convient pas comme identifiant.
- Copier le titre, la description, l’URL historique Vimeo et les noms de catégories réellement présents. Si la source fournit uniquement l’ID Vimeo numérique, la forme canonique est `https://vimeo.com/<id>`. En l’absence de description ou de lien, écrire `null`. En l’absence de catégories, écrire `[]`. Écrire le rang éditorial dans `position` (entier) ou utiliser l’ordre du tableau si celui-ci pilote effectivement la galerie.
- Pour chacune des images disponibles, copier les octets sous un nom local simple dans `originals/` et placer ce nom dans `file`. `key` indique la référence qui permet au propriétaire de retrouver l’image source. `filename` conserve le nom d’origine. `byte_size` contient la taille de l’original en octets et `checksum` son MD5 en Base64 lorsqu’il existe dans la source. Renseigner `thumbnail: null` pour une réalisation réellement sans vignette. Lorsqu’une référence existe et que l’original manque, récupérer l’original avant la reprise de la fiche.

Par exemple, à la fin du script d’export local, une fois `videos` construit d’après les champs réels du site avec les clés de cet exemple, écrire le manifeste avec `writeFileSync("catalogue.json", JSON.stringify({ version: 1, source: "nextjs", videos }, null, 2))` (`writeFileSync` provient de `node:fs`). Contrôler le nombre de fiches, quelques identifiants, l’ordre et les vignettes avec le propriétaire avant l’import.

## Export facultatif depuis une restauration de l’ancien Rails

1. Restaurer la sauvegarde historique dans une base PostgreSQL **locale** et préparer une copie des originaux Cloudinary. Depuis le dossier de la nouvelle application, utiliser un rôle PostgreSQL pouvant lire les tables historiques.

   ```sh
   mkdir -p /tmp/reprise-maurice-rails/originals
   psql -XqAt -h /tmp -d chez_maurice_copie -v ON_ERROR_STOP=1 \
     -f script/export_legacy_catalogue.sql > /tmp/reprise-maurice-rails/catalogue.json
   ```

2. Pour chaque entrée avec une vignette, prendre l’original correspondant à `thumbnail.key` et le copier sous `originals/<thumbnail.file>`. Pour l’exporteur Rails, ce nom local correspond à l’identifiant historique de la vidéo, sans extension. La requête lit uniquement les tables de vidéos, catégories et pièces jointes et produit un manifeste `source: "rails"`.

## Import dans la nouvelle application

Depuis le dossier de la nouvelle application, remplacer le chemin par celui du manifeste préparé.

```sh
bin/rails db:prepare
MANIFEST=/tmp/reprise-maurice-next/catalogue.json bin/rails catalogue:import
bin/rails runner 'pp Realisation.where.not(legacy_id: nil).ordered.pluck(:legacy_source, :legacy_id, :title, :position, :published)'
```

Chaque réalisation importée pour la première fois arrive en brouillon, avec son ancienne URL Vimeo si elle est connue. Une relance reconnaît la paire source/identifiant, actualise les métadonnées, catégories et vignette et conserve l’identifiant YouTube, la date et le choix de publication locaux. Les fiches absentes de l’export restent en base. Deux sources peuvent utiliser le même identifiant pour des films différents. Le rapprochement entre elles relève d’une vérification éditoriale. Importer les deux crée deux jeux de brouillons distincts.

Si une image attendue manque ou diffère de l’original, la commande indique la fiche à reprendre et quitte en erreur. Les fiches précédentes sont conservées et la fiche en erreur garde son état précédent. Corriger le fichier puis relancer la même commande.

Après rapprochement avec le véritable film YouTube et accord éditorial, la console Rails permet de renseigner `youtube_id` et de passer `published` à `true`. La galerie et la page individuelle rendent alors le film accessible. Le titre et un identifiant YouTube de onze caractères sont requis. L’existence de la vidéo, son audience et l’autorisation d’intégration se vérifient sur la chaîne choisie.

Le champ facultatif `published_at` correspond à la date de première publication de la vidéo attestée par sa source éditoriale. Renseigner l’horodatage connu pour que la page puisse l’inclure dans ses métadonnées vidéo. Lorsqu’il est inconnu, le laisser vide. La galerie accepte les films sans date.
