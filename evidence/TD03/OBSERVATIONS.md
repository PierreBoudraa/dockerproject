# TD03 : persistance

## Etape 3
- Avant : ligne SQL id=1, element API id=2 (HTTP 201), relus a l'identique en base et via l'API.
- Conteneurs supprimes puis recrees par scripts/td03-run.sh : ID postgres 28a37ac6... -> 83bcb74c..., ID API 11ce7b29... -> 502de2c4... (step3-containers-*.txt).
- Apres : memes lignes, memes ID, memes valeurs, memes dates de creation des volumes (step3-compare.txt).
- Journal PostgreSQL : "Database directory appears to contain a database; Skipping initialization" (step3-skip-init.txt).

## Pourquoi cela prouve la persistance
Un ID de conteneur different prouve que les conteneurs d'origine, avec leur couche inscriptible, ont ete detruits et remplaces. Si les donnees etaient dans cette couche, elles auraient disparu avec eux, et PostgreSQL aurait reinitialise une base vide depuis le SQL. Les deux enregistrements sont pourtant revenus identiques : ils vivent dans le volume nomme td03-postgres-data, dont le cycle de vie est independant de celui des conteneurs (date de creation inchangee). Un simple redemarrage ne prouverait rien : le conteneur et sa couche inscriptible survivent, donc les donnees reviendraient meme sans volume.
