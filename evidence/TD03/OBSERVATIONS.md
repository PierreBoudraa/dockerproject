# TD03 : observations

## Etape 1 : ressources privees et secret
- Reseau td03-private et volumes td03-postgres-data, td03-db-secret crees avec les labels course.lab=TD03 et course.environment=course-lab ; aucune collision (step1-collisions.txt).
- Mot de passe aleatoire (43 octets) genere dans secrets/ (mode 600, ignore par git), copie dans le volume secret en 0440, proprietaire postgres (70), groupe 10001 (API).
- Lisible par postgres et par l'API, refuse pour un utilisateur inconnu, ecriture refusee en montage ro ; mot de passe absent des preuves (step1-readcheck.txt).

## Etape 2 : connexion privee
- scripts/td03-run.sh lance postgres puis l'API sur td03-private ; l'API joint postgres:5432 par le DNS Docker.
- /readyz depuis un pair temporaire : HTTP 200 {"status":"ready"} (step2-readyz.txt).
- Aucun port hote (PortBindings={}, docker port vide) ; limites memoire, CPU et processus ; utilisateurs non root (70:70 et 10001:10001) (step2-inspect.txt).

## Etape 3 : persistance
- Avant : ligne SQL id=1, element API id=2 (HTTP 201), relus a l'identique en base et via l'API.
- Conteneurs supprimes puis recrees : ID postgres 28a37ac6... -> 83bcb74c..., ID API 11ce7b29... -> 502de2c4... (step3-containers-*.txt).
- Apres : memes lignes, memes valeurs, memes dates de creation des volumes (step3-compare.txt).
- Journal PostgreSQL : "Skipping initialization" (step3-skip-init.txt).

## Pourquoi cela prouve la persistance
Un ID de conteneur different prouve que les conteneurs d'origine, avec leur couche inscriptible, ont ete detruits et remplaces. Si les donnees etaient dans cette couche, elles auraient disparu et PostgreSQL aurait reinitialise une base vide. Elles sont revenues identiques : elles vivent dans le volume nomme td03-postgres-data, dont le cycle de vie est independant de celui des conteneurs. Un simple redemarrage ne prouverait rien : le conteneur et sa couche inscriptible survivent, donc les donnees reviendraient meme sans volume.
