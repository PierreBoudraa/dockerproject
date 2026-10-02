# TD02 etape 3 : explications

- /healthz : 200, l'application tourne. /readyz : 503, car PostgreSQL est absent (attendu avant TD3).
- Premier /version : git_sha=unknown, version=0.0.0-dev. Cause : ARG disponible seulement au build, alors que app/config.py lit os.getenv.
- Correction : ENV APP_VERSION et ENV GIT_SHA dans le stage runtime. Nouveau commit 80871b2, image rebuild, /version affiche le bon SHA et 0.2.0.
- Utilisateur du conteneur : uid=10001. Port : 127.0.0.1:8080 vers 8000.
- td02-api reste en cours d'execution (port 8080 occupe) jusqu'au nettoyage.
