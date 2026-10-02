# TD02 : observations

## Image et revision
- SHA Git de l'image testee : 80871b2d2cc527f94aa2f2dbe47e59ea2b6f5e79 (step3-sha-final.txt)
- Label OCI revision : identique au SHA. Source : https://github.com/PierreBoudraa/dockerProject. Version : 0.2.0. Utilisateur : 10001:10001.
- /version (execution locale puis par digest) : git_sha identique au SHA enregistre (step3-version-v2.txt, step4-version.txt, step5-compare.txt).

## Builds et cache
- Premier build : 2 etapes CACHED. Second build : 9 CACHED, meme manifeste d'image (step2-cache.txt).

## Registre
- Reference observee : ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:abb19cde9713bb12ea75a712865c350b427ae49f1cec999c5bdfef6a714da901
- release.env contient cette reference @sha256, pas un tag ni un ID local.
- Execution par digest : /healthz 200, /version avec le bon SHA, /readyz 503 (PostgreSQL absent, attendu avant TD3).
- Aucune porte BLOCKED.

## Echecs rencontres
- /version initial : git_sha=unknown, version=0.0.0-dev, car APP_VERSION et GIT_SHA etaient des ARG sans ENV. Corrige par ENV (commit 80871b2). Preuve : step3-version.txt puis step3-version-v2.txt.
- Premiers essais de push : reference refusee car noms avec majuscules ou proprietaire manquant. Corrige en minuscules, rien n'avait ete pousse.
- Un lancement par digest avant la creation de release.env a echoue (invalid reference format) ; ces fichiers ont ete supprimes et refaits.

## Etat final
- td02-api supprime, port 8080 libre pour TD3 (curl_exit=7).
- Image locale delivery-api:80871b2d..., journaux, resultats HTTP et preuve de digest conserves.
- Aucun docker system prune, aucun objet etranger supprime.

## Fichiers
build-first/second/third.txt, step2-*, step3-*, step4-*, push.txt, pull-digest.txt, step5-compare.txt, step5-cleanup.txt
