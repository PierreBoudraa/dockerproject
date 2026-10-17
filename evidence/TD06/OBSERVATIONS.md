# TD06 - Observations

## Identites
- Observation (UTC): 2026-10-17T14:15Z
- Docker Engine: 29.8.1 ; Compose: v5.5.1
  - Ecart: versions.env attend Engine 29.7.2 et Compose 5.5.0. Les scripts de deploiement et de regression sont passes malgre cet ecart.
- release_sha (source de D): e33fcfd2c1d220c2c9b2d0fa2f7ce62da1771576
- CI run: https://github.com/PierreBoudraa/dockerproject/actions/runs/39036489432
  - conclusion success, run_attempt=3 (tentatives 1-2: build-publish refuse par GHCR, permission_denied: read_package ; jobs echoues relances sur le meme SHA)
- D: ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:f5d77bc62b3e52e3de4e309067bc1785ee577b76693f722e3f0d0850f4d3dc92
- P: ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:abb19cde9713bb12ea75a712865c350b427ae49f1cec999c5bdfef6a714da901
- SHA source OCI: D = e33fcfd2c1d220c2c9b2d0fa2f7ce62da1771576 ; P = 80871b2d2cc527f94aa2f2dbe47e59ea2b6f5e79
- Le SHA de l'image active apres rollback (P) est plus ancien que celui de la definition operationnelle et des commits de preuves.

## Preuves CI
- sha256 sbom.cdx.json: 4b2fb7c2ff5b512c454fe245ac8f9d38fe5c9d62ed7bfa0353a956d65d1432bb
- sha256 vulnerabilities.json: d80675fcd4cf6dcbf9dde5bf9378adda121e5d2a582f25c4d218afff87d0dc75
- sha256 SHA256SUMS: 2f76e1403b29e211de05f848608d870d99f0aeebaf0eaa375355ebf3e45a2468
- sha256sum --check SHA256SUMS: OK
- Scan Trivy v0.73.0 (non filtre, non bloquant): 0 CRITICAL, 48 HIGH (4 corrigeables, voir fixable-high.txt), 99 MEDIUM, 70 LOW, 3 UNKNOWN
- Run de PR 39037762936: validate success, build-publish et supply-chain skipped
- imagetools: digest du registre = D (imagetools-D.txt)

## Approbation
- reviewer=leoChen, decision=APPROVED, decided_at_utc=2026-10-17T13:58Z (APPROVAL.md)
- Non verifie: l'autorisation de ce relecteur selon le cours.

## Deploiement et rollback (state/release-state.env)
- 14:06:22Z deploy D: deploy rc=0, smoke rc=0, regression rc=0 (active-release.txt)
- 14:11:03Z premier rollback (attempt1-no-failure/): sans echec prealable, non retenu comme preuve
- 14:13:46Z redeploiement de D (redeploy-D.txt)
- Avant rollback, D actif: smoke.sh avec EXPECTED_GIT_SHA=P echoue, exit_code=1
  (git_sha: expected '80871b2d...', observed 'e33fcfd2...') -> smoke-before-rollback.txt
- Declencheur de rollback: smoke echoue (version attendue differente)
- 14:14:16Z rollback: rc=0, current=P, previous=D, pas de pending-operation
- Apres rollback, P actif: smoke rc=0, regression rc=0 (after-rollback-smoke.txt, regression-after-rollback.txt)
- Image active avant: D ; apres: P (rolled-back-release.txt)
- Base de donnees: non modifiee, aucune restauration; marqueur de persistance (id 2) intact.

## Ecarts et limites
- regression.sh ne lit pas EXPECTED_GIT_SHA dans ce starter: regression-before-rollback.txt (exit_code=0) et regression-after-rollback.txt ne prouvent pas le changement de version. Le test discriminant est smoke.sh.
- Etat dans state/release-state.env, pas deploy/state/current-image; --initialize non execute (etat deja existant, current=P).
- Jeton gh (scopes repo, workflow, read:packages, ...) utilise pour le login GHCR a la place d'un jeton read:packages dedie; aucun jeton dans un fichier.
- Reglage GHCR (Manage Actions access, role Write) fait dans le navigateur, non versionne.
- pytest: BLOCKED en local (python3-venv absent sous Python 3.14); prouve par le job validate (Python 3.12).
- Le workflow ne filtre pas le scan aux High/Critical corrigeables et n'a pas de seuil bloquant.
- Premiers runs 39034881471 et 39036240036 en echec (sources non suivies par Git); le push initial 39a9c26 n'a cree aucun run.
- Remediation proposee, non appliquee: reconstruire sur une base plus recente puis rescanner.
- HEAD de la definition au moment de la redaction: 12eacd1250f7f360bd02341f678f36642fd17177
