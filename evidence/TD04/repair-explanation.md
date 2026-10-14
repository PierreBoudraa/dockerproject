# Étape 4 : explication de la réparation

Ligne modifiée : `nginx/nginx.conf`, ligne 33 (`set $api_upstream ...`).
Avant : `delivery-apis:8000`. Après : `delivery-api:8000`.

Le proxy disait `delivery-apis could not be resolved`. Le nom de l'upstream de `nginx.conf` avait été changé, ce qui provoquait l'erreur, l'erreur ne venait pas de l'API, la base ou le réseau (vérifiés par les contrôles A à D). J'ai remis `delivery-api`, le nom du service Compose que le DNS Docker résout sur le réseau `edge`.

Preuves : incident-proxy-logs.txt, incident-diagnosis.txt, proxy-diff.txt, repaired-status.txt, regression-before-repair.txt, regression-after-repair.txt.
