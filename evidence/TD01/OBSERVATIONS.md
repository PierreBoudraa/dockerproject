# TD01 : observations

## Commandes principales
- Vérification : `docker version`, `docker info`, `docker pull --platform "$COURSE_IMAGE_PLATFORM" "$NGINX_IMAGE"`
- Création : `./scripts/td01-run.sh` (nom td01-web, labels course.lab=TD01 et course.environment=course-lab, --restart no, port 127.0.0.1:8080:8080)
- Inspection : `docker ps`, `docker inspect`, `docker top`, `docker port`, `docker logs`, `curl -i http://127.0.0.1:8080/`
- Cycle de vie : `docker stop`, `docker start`, `docker rm`, puis `./scripts/td01-run.sh`

## ID observés
| Objet | ID |
|---|---|
| Conteneur d'origine | fef506bae907f1ebf687c6db4c5bb2e981afa8d3f9adf60e5e67741b52168901 |
| Après stop puis start | identique à l'original |
| Conteneur recréé | 5c2474294c3c958785f947247de72b19b9118a88e9db391b4c2a3f489a70165c |
| Image (avant, après rm, après recréation) | sha256:8059701048a6cc7d64e8ab2812a44be70161bfa9ecfc01d69e95b8ff2a648705 |

## Résultats HTTP
- Conteneur actif : HTTP/1.1 200 OK (Welcome to nginx!, 896 octets), curl_exit=0
- Après docker stop : `curl: (7) Failed to connect to 127.0.0.1 port 8080`, curl_exit=7
- Après docker rm : même échec, curl_exit=7
- Après recréation : 200 OK, curl_exit=0

## Échecs de vérification
- Au premier essai de l'étape 2, `tee` a échoué (`No such file or directory`) car `evidence/TD01/` n'existait pas. Le dossier a été créé, puis la commande relancée.
- Les échecs curl (code 7) après stop et rm étaient attendus : ils prouvent que le service est arrêté.

## Pourquoi l'ID est conservé au démarrage mais change à la recréation
(à reformuler avec vos mots)
`docker stop` arrête seulement le processus du conteneur : l'objet conteneur, sa configuration et son système de fichiers restent, donc `docker start` relance le même objet avec le même ID. `docker rm` détruit l'objet. `docker run` en crée un nouveau à partir de l'image, et Docker lui attribue un nouvel ID. L'image, elle, n'est pas touchée par ces opérations : c'est pourquoi son ID n'a pas changé.

## État final
- Conteneur td01-web supprimé, port 8080 libre pour TD2.
- Image nginx épinglée conservée, script `scripts/td01-run.sh` conservé et versionné.
- Aucun `docker system prune`, aucun objet étranger supprimé.

## Fichiers
step2-*, step3-*, step4-*, step5-verify.txt, step5-cleanup.txt, evidence1.png
