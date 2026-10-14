# Incident proxy : hypothèse (écrite avant lecture du diff)
Origine de la faute : tirée au sort par un script appliqué par un autre Claude (rôle de saboteur), cause non lue avant diagnostic.
Symptôme : GET /healthz via le proxy -> HTTP 502 Bad Gateway (incident-status.txt, incident-body.txt).
Hypothèse : le proxy utilise un nom d'hôte upstream incorrect (couche proxy -> API, résolution DNS). Le nom demandé n'est pas celui du service.
Preuves :
- incident-proxy-logs.txt : "delivery-apis could not be resolved (2: Server failure)".
- incident-diagnosis.txt C : depuis le proxy, delivery-api se résout (172.19.0.2) et /healthz répond, donc réseau et DNS Docker fonctionnent.
- incident-diagnosis.txt A, B, D : API prête en interne, PostgreSQL accepte les connexions, trois healthchecks verts.
Alternative écartée : mauvais port d'upstream. Il donnerait "Connection refused" dans le log, pas une erreur de résolution de nom. Autre alternative écartée : panne de l'API ou de PostgreSQL (A, B, D).
Remarque : le healthcheck du proxy reste vert car il teste /nginx-health, local, sans appeler l'API.
