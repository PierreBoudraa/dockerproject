# TD05 : observations (brouillon à reformuler)

## Contexte
- Rédigé (UTC) : 2026-10-15T21:09:13Z
- Docker : client=29.8.1 server=29.8.1, démon rootful, mon compte est dans le groupe docker (host-observations.txt)
- Digest scanné et en cours d'exécution : ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:abb19cde9713bb12ea75a712865c350b427ae49f1cec999c5bdfef6a714da901, résultat MATCH (image-match.txt)
- Chaîne d'identité : config = sha256:82b74e9f8881991e27510aee3847898d5b3cc9b017f1eb00fd40d0aa67b75b07 = ImageID vu par Trivy (scan-identity-chain.txt)

## Scanner
- scan_start_utc=2026-10-15T20:03:57Z
- trivy_image=aquasec/trivy:0.73.0@sha256:4bbf3824d974b70f27631005e2e6194d4d8fbd6e72c4a9e04cf521e25c5cb07f
- Version: 0.73.0
- scan_end_utc=2026-10-15T20:04:49Z
- État de la base de vulnérabilités (trivy-vuln-stderr.txt) :
  - 2026-10-15T20:04:17Z	INFO	[vulndb] Need to update DB
  - 2026-10-15T20:04:17Z	INFO	[vulndb] Downloading vulnerability DB...
  - 2026-10-15T20:04:17Z	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
  - 2026-10-15T20:04:21Z	ERROR	[vulndb] Failed to download artifact	repo="mirror.gcr.io/aquasec/trivy-db:2" err="oci download error: failed to fetch the layer: GET https://mirror.gcr.io/v2/aquasec/trivy-db/blobs/sha256:af5513d695a02da161738139b9bde7e0e9550052d6789
  - 2026-10-15T20:04:21Z	INFO	[vulndb] Trying to download artifact from other repository...
  - 2026-10-15T20:04:21Z	INFO	[vulndb] Downloading artifact...	repo="ghcr.io/aquasecurity/trivy-db:2"
  - 2026-10-15T20:04:47Z	INFO	[vulndb] Artifact successfully downloaded	repo="ghcr.io/aquasecurity/trivy-db:2"
- La date de construction de la base n'est pas enregistrée. Trivy signale une version 0.76.0 ; l'image du scanner reste épinglée par digest.
- Empreintes (sha256sum -c : OK pour les deux fichiers, contrôlé après copie des preuves) :
  - ca2b9af8a7ff95ccf0adfef6736815d2ca9b195e1d6ed680310844a620279e2d  evidence/TD05/sbom.cdx.json
  - 2fdd7646e117e83fae7cbe861239ad3e842aebd216b2e0b6c3e10d595df3f6e3  evidence/TD05/vulnerabilities.json
  - 1cc026bee02743402743cf6c31d45f272ea82f263a4d1b9ba5e96c6958fa6c0e  evidence/TD05/high-critical.tsv
- SBOM : CycloneDX 1.7, 102 composants. Scan : 0 CRITICAL, 48 HIGH, 99 MEDIUM, 70 LOW, 3 UNKNOWN.

## Triage (TRIAGE.md)
- 48 HIGH sur 21 composants. 4 ont un correctif (libssl3t64, openssl, openssl-provider-legacy, libpcre2-8-0) : reconstruction à planifier en TD6, acceptation temporaire d'ici là. 17 n'ont pas de correctif : acceptation temporaire.
- Revue : 2026-10-22. Expiration des exceptions : 2026-11-15. Responsable : Pierre.
- Une reconstruction produit un nouveau digest et exige un nouveau scan et une nouvelle approbation.

## Contrôles API et proxy (testés)
- Voir runtime-controls.txt, api-identity.txt, proxy-identity.txt, postgres-process.txt.
- API : CapEff:	0000000000000000 NoNewPrivs:	1 
- Proxy : CapEff:	0000000000000000 NoNewPrivs:	1 
- PostgreSQL : processus sous l'utilisateur 70, 1 test d'écriture sur PGDATA réussi (postgres-data-writable.txt)

## Action autorisée et action refusée
- Refusée (root écrit dans la racine de l'API, root-write-denied.txt) :
  - touch: cannot touch '/srv/td05-denied': Read-only file system
  - exit_code=1
- Contrôle positif : root: /tmp ok (root-write-allowed-tmp.txt)
- Autorisée juste après le refus (allowed-after-denial.txt) : PASS: liveness, readiness, and release-identity checks succeeded
- Valeur du mot de passe dans les preuves : PASS: the current password value was not found in local evidence files (secret-leak-check.txt)

## Rejeu de la définition TD4 puis retour au durci
- Début (UTC) : 2026-10-15T21:02:50Z ; fin : 2026-10-15T21:03:42Z
- Définition TD4 active : proxy readonly=false capdrop=null ; smoke : PASS: liveness, readiness, and release-identity checks succeeded (known-good-ps.txt, known-good-smoke.txt)
- Retour au durci : proxy readonly=true capdrop=["ALL"] ; smoke : PASS: liveness, readiness, and release-identity checks succeeded ; régression : PASS: regression complete (returned-hardened-ps.txt, returned-hardened-regression.txt)
- Volumes conservés (volumes-after-rollback.txt) : td03-db-secret td03-postgres-data 
- Différence TD4 -> durci (definition-diff.txt, definition-diff-stat.txt) : +12 lignes dans compose.yaml, +3 dans nginx.conf. API : user 10001, read_only, tmpfs /tmp. Proxy : user 101, read_only, cap_drop ALL, no-new-privileges, tmpfs /tmp. PostgreSQL : seulement un commentaire d'exception (racine inscriptible). nginx.conf : fastcgi, uwsgi et scgi temp_path vers /tmp.
- Le rejeu remplace une définition, pas une image : l'API garde le digest abb19cde... pendant tout l'essai (known-good-ps.txt). La restauration d'un digest est faite en TD6.

## Limite constatée pendant le rejeu
- regression.sh a affiché PASS pendant que la définition TD4 tournait : son contrôle "definitions" compare les fichiers du dossier au commit durci, pas les conteneurs en cours d'exécution. Il ne détecte donc pas une perte de durcissement. Cette sortie n'a été vue qu'à l'écran, elle n'est pas enregistrée dans un fichier.

## Non exécuté (BLOCKED)
- Reconstruction de l'image sur une base corrigée : BLOCKED (TD6, nouveau digest).
- Scan des images du proxy et de PostgreSQL : BLOCKED (hors énoncé).
- Séparation d'un réseau public du réseau edge pour supprimer la sortie Internet de l'API : BLOCKED (risque ouvert du modèle de menaces).

## Limite restante
- Démon Docker rootful : tout processus lancé sous mon compte (groupe docker) pilote le démon, donc l'accès aux volumes, dont le secret. Risque résiduel accepté (THREAT_MODEL.md, compromis 1).
