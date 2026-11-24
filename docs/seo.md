# Référencement et performances mobiles

## Ce que reçoit un visiteur ou un moteur

L’accueil, la galerie, le contact et les mentions légales gardent les chemins `/`, `/realisations`, `/contact` et `/mentions-legales`. Les alias `/studio` et `/videos` redirigent en 301 vers l’accueil et la galerie. La section `/#informations` reste accessible sur l’accueil.

Chaque vignette contient un lien HTML vers `/realisations/:id`. Rails sert directement le titre, les catégories, le texte disponible et le lecteur aux visiteurs qui ouvrent ou rechargent cette adresse. Turbo utilise la même fiche pour la modale. La galerie filtrée revient à l’adresse canonique de la galerie dans son balisage et porte `noindex,follow`. Les brouillons répondent 404 sur leur URL individuelle.

Chaque page publique possède un titre, une description et une URL canonique. L’accueil décrit le studio en JSON-LD `Organization`. Une fiche publiée avec description, vignette et date de première publication attestée expose un `VideoObject` avec l’adresse du lecteur YouTube et une URL stable de vignette. La fiche dispose également des métadonnées Open Graph et de partage. Le plan `/sitemap.xml` liste les quatre pages publiques et les seules réalisations publiées. Son adresse figure dans `/robots.txt`. [Bonnes pratiques vidéo de Google](https://developers.google.com/search/docs/appearance/video)

## Mesures du 24 novembre 2026

Lighthouse 13.6.0 et Chrome 157 ont visité une copie locale en mode production, en HTTPS sur Puma, avec assets précompilés, SQLite isolée et six fiches de laboratoire dotées de vignettes synthétiques. Le profil mobile simule 412 pixels CSS, une densité de 1,75, une latence de 150 ms, un débit descendant de 1,6 Mbit/s et un ralentissement CPU ×4. Chaque valeur est la médiane de trois navigations avec réinitialisation du cache du navigateur. Les scores sont sur 100.

| Page | Performance | Accessibilité | Bonnes pratiques | SEO | LCP | CLS | TBT | Transfert |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Accueil | 94 | 100 | 100 | 100 | 3,15 s | 0 | 0 ms | 293 Kio |
| Galerie avec six films | 95 | 100 | 100 | 100 | 3,01 s | 0,0007 | 0 ms | 286 Kio |
| Fiche individuelle | 100 | 100 | 100 | 100 | 1,53 s | 0 | 0 ms | 257 Kio |

Le premier passage de diagnostic donnait 80 en performance sur l’accueil et 82 sur la galerie. L’en-tête charge maintenant un logo WebP de 7 Ko. Cinq SVG officiels Font Awesome remplacent les deux fichiers de police d’icônes qui totalisaient 277 Ko. Sur l’écran simulé, le navigateur a choisi le photogramme de 800 pixels. Les six requêtes de vignettes ont obtenu directement une image WebP et un statut 200.

Les appels externes étaient bloqués, notamment l’iframe YouTube. La mesure de la fiche couvre le document Rails et ses ressources locales. Le VPS, le proxy commun, la compression en production, les images du catalogue réel et le coût du vrai lecteur devront être mesurés lors de la recette. Le score SEO porte sur les vérifications automatisables de Lighthouse. L’indexation effective et l’expérience des visiteurs se constatent après publication.

## Vérifier avant et après la bascule

1. **Comparer les adresses.** Récupérer auprès du propriétaire le sitemap existant, les exports Search Console et, si disponibles, les anciens liens entrants. Faire correspondre chaque page existante à son contenu dans Rails. Conserver les adresses déjà partagées, prévoir une 301 vers le contenu équivalent lorsqu’un chemin change et vérifier sa réponse finale. Les éventuels liens historiques d’un film nécessitent le rapprochement vérifié du catalogue. [Guide Google pour les changements d’URL](https://developers.google.com/search/docs/crawling-indexing/site-move-with-url-changes)
2. **Valider un véritable film.** Confirmer avec le propriétaire le titre, la description du projet, la vignette représentative, la date de première publication, le réglage de visibilité et l’autorisation d’intégration YouTube. Ouvrir son URL directement avec JavaScript désactivé, vérifier le titre et le texte du film, puis réactiver JavaScript et essayer le lecteur sur mobile. Vérifier que le film fait l’objet principal de la page et que la vignette répond sans authentification. Les données structurées complètes peuvent ensuite être contrôlées avec le test des résultats enrichis. [Référencement vidéo](https://developers.google.com/search/docs/appearance/video)
3. **Vérifier le domaine définitif.** Contrôler le HTTPS, le domaine canonique, les aperçus de partage, les redirections, `/robots.txt` et `/sitemap.xml`, puis inspecter l’accueil, la galerie et une fiche dans Search Console. Soumettre le sitemap depuis la propriété vérifiée du propriétaire et suivre les pages indexées, les résultats vidéo et les erreurs 404. [Utiliser Search Console](https://developers.google.com/search/docs/monitor-debug/search-console-start)
4. **Mesurer l’expérience réelle.** Refaire le test mobile sur la galerie avec ses photos réelles et sur une fiche avec YouTube accessible. Suivre les Core Web Vitals sur une période disposant de trafic suffisant et examiner les données au 75e percentile. Les seuils « bons » sont LCP ≤ 2,5 s, INP ≤ 200 ms et CLS ≤ 0,1. Dans le laboratoire, les deux premières pages dépassent 2,5 s en LCP. Le TBT décrit le blocage lors du chargement et l’INP devra être mesuré lors d’interactions réelles. [Définition et mesure des Web Vitals](https://web.dev/articles/vitals)
