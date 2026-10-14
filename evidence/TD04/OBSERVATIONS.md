# TD04 : observations (Compose, incident proxy)

## Contexte
Pile Compose à trois services (proxy, delivery-api, postgres), volumes TD03 conservés (step1-model.txt, resolved-compose.yaml). Un autre Claude a joué le saboteur : une faute tirée au sort par un script, cause non lue avant mon diagnostic.

## Références
- Définition known-good : commit 472830b8bc3e718fa6c599a2fdc9d7157ddd6fa3 (known-good-sha.txt)
- Digest de l'API : sha256:abb19cde9713bb12ea75a712865c350b427ae49f1cec999c5bdfef6a714da901 (step2-api-image.txt)
- Comportement de référence : trois services healthy, /healthz, /readyz, /version en 200 (ps-healthy.txt, step2-baseline.txt)

## Incident
- Première observation UTC : 2026-10-13T16:29:30Z (incident-start.txt). Le log du proxy date l'erreur de 16:29:34.
- Requête en échec : GET /healthz via le proxy, HTTP 502 Bad Gateway (incident-status.txt, incident-body.txt).
- Log du proxy : "delivery-apis could not be resolved (2: Server failure)" (incident-proxy-logs.txt).
- API en interne : /readyz renvoie ready, dépendance postgres (incident-diagnosis.txt, A).
- Base : PostgreSQL accepte les connexions (incident-diagnosis.txt, B).
- Depuis le conteneur du proxy : delivery-api se résout en 172.19.0.2 et /healthz répond, wget exit=0 (incident-diagnosis.txt, C).
- Healthchecks : les trois services restent healthy pendant le 502 (incident-ps.txt, incident-diagnosis.txt, D).

## Hypothèses en concurrence
1. API ou PostgreSQL en panne : écartée, A, B et D montrent l'API prête et la base disponible.
2. Mauvais port d'upstream : écartée, un mauvais port aurait donné une erreur de connexion, pas une erreur de résolution de nom.
3. Mauvais nom d'hôte d'upstream dans nginx.conf : retenue (hypothesis.md, écrite avant d'afficher proxy-diff.txt).

## Cause supportée par les preuves
nginx.conf ligne 33 : `set $api_upstream delivery-apis:8000;` au lieu de `delivery-api:8000` (proxy-diff.txt, nginx.failed.conf). Le log et le diff concordent.

## Réparation minimale
Une seule ligne dans nginx/nginx.conf, `delivery-apis` remplacé par `delivery-api`. Seul le proxy a été recréé. API, base et volumes sont restés en place (repaired-ps.txt). Explication : repair-explanation.md.

## Même requête après réparation
- GET /healthz : HTTP 200 (repaired-status.txt, repaired-body.json), à 2026-10-14T10:18:24Z (repair-time.txt).
- /readyz ready (repaired-ready.json), /version (repaired-version.json), port publié 127.0.0.1:8080 (proxy-port.txt).
- smoke.sh : PASS (smoke-after-repair.txt).
- regression.sh : exit=1 avant réparation (regression-before-repair.txt), exit=0 après (regression-after-repair.txt).
- Même digest d'API et marqueur TD03 inchangé (regression-after-repair.txt).

## Ce que cet exercice n'a pas testé
- Une seule classe de faute (nom d'hôte). Ports, timeouts, réseau et secrets n'ont pas été mis en cause.
- La survie du proxy à la recréation du conteneur API (nouvelle IP) : la config utilise un resolver avec re-résolution, mais je ne l'ai pas éprouvée.
- Le healthcheck du proxy teste /nginx-health, local : il est resté vert pendant le 502. Je n'ai pas modifié cette limite.
- Les limites de ressources, le délai d'arrêt et le comportement sous charge.
- Le durcissement (TD05) et les écritures après réparation : la régression compare des données en lecture, avec 2 lignes seulement.
- Le saboteur était un autre Claude et non une personne : une seule faute, tirée au sort, pas de débrief croisé.
- Docker Desktop a été arrêté entre l'étape 3 et le commit de l'hypothèse. La pile a été relancée sans changer nginx.conf fautif.
