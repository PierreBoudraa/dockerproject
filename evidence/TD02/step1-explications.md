# TD02 étape 1 : explications

- **Deux stages** : le builder installe les dépendances, le runtime ne reçoit que le venv et les fichiers de l'API. L'image finale est plus petite et n'a pas d'outils de build.
- **`--require-hashes`** : pip refuse tout paquet dont le hash ne correspond pas à `requirements.txt`, donc un paquet modifié est rejeté.
- **`requirements.txt` copié avant le code** : la couche des dépendances reste en cache tant que ce fichier ne change pas, même si on modifie `app/`.
- **UID/GID 10001** : Gunicorn ne tourne pas en root, ce qui limite les dégâts en cas de compromission.
- **Labels OCI** : version, source et révision Git permettent de savoir quel code a produit l'image (valeurs injectées par `--build-arg`).
- **`EXPOSE 8000`** : documente le port d'écoute, mais ne publie rien. La publication se fait avec `-p` au lancement.
- **Healthcheck** : utilise `urllib` car l'image n'a pas `curl`. Il est borné (intervalle 30 s, timeout 3 s, 3 essais), donc il ne bloque jamais indéfiniment.
- **Exec form** : Gunicorn est le PID 1 et reçoit directement SIGTERM, ce qui permet un arrêt propre.
- **`.dockerignore`** : `.git`, `evidence`, `tests` et `.env*` restent hors du contexte (pas de fuite de secrets, build plus rapide). Preuve : `step1-context.txt` ne liste que 12 fichiers utiles.
- **Warning `InvalidDefaultArgInFrom`** : il vient du Dockerfile temporaire de vérification (ARG sans valeur par défaut), pas du vrai Dockerfile. Il est sans conséquence.
- **Note d'honnêteté** : le Dockerfile et ces explications ont été rédigés avec l'aide de l'assistant, puis relus.
