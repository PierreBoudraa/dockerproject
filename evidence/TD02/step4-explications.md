# TD02 etape 4 : explications

- Image taguee avec le SHA Git complet (80871b2d...), poussee sur GHCR, puis digest resolu : sha256:abb19cde...
- Un tag est modifiable, un digest identifie un contenu precis. release.env contient donc la reference @sha256, pas le tag ni l'ID local.
- Execution par digest : /version renvoie le meme git_sha que mon build enregistre (step3-sha-final.txt).
- Erreurs rencontrees : noms en majuscules refuses par Docker (le nom du depot doit etre en minuscules), token a regenerer.
- Token saisi uniquement a l'invite masquee, non stocke ; verification grep : aucun token dans les preuves.
