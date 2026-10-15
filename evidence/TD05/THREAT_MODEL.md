# TD05 : modèle de menaces (brouillon à reformuler)

Périmètre : pile docker-delivery (proxy, delivery-api, postgres) sur Docker Desktop / WSL2.
Image sous revue : ghcr.io/pierreboudraa/dockerproject/delivery-api@sha256:abb19cde... (image-under-review.txt).
Image scannée = image en cours d'exécution : MATCH (image-match.txt).
Base de référence avant tout durcissement : trois services healthy, smoke et régression PASS (before-ps.txt, before-smoke.txt, before-regression.txt).
Statut : "observé" = vu dans une sortie ; "prévu" = pas encore appliqué.

## Observations sur l'hôte (host-observations.txt)
- Linux 6.18.33.2-microsoft-standard-WSL2, Docker 29.8.1 (client et serveur), contexte default. Options de sécurité du démon : seccomp (profil intégré) et cgroupns, pas de mode rootless listé.
- Mon compte (uid 1000) est dans les groupes docker et sudo. Socket /var/run/docker.sock : srw-rw---- root:docker.
- Parmi 8080, 8000 et 5432, seul 127.0.0.1:8080 écoute dans WSL.
- secrets/ en 700, postgres_password en 600, hors Git. Dans le volume : 440, propriétaire 70, groupe 10001.
- Réseaux : data internal=true (postgres, api) ; edge internal=false (proxy, api).
- Durcissement : api et postgres ont cap_drop ALL et no-new-privileges ; le proxy (uid 101) n'a ni l'un ni l'autre ; rootfs non read-only pour les trois.

## 1. Démon Docker
- Chemin d'attaque : un processus lancé sous mon compte (script ou paquet non fiable) parle au socket, car je suis dans le groupe docker.
- Abus probable : lancer un conteneur qui monte td03-db-secret ou td03-postgres-data et lit le mot de passe ou la base.
- Contrôle : aucun conteneur de la pile ne monte le socket, le démon n'écoute pas en TCP, je n'exécute pas de code non fiable sous ce compte.
- Test pour réfuter : chercher docker.sock dans les montages (résultat 0, host-observations.txt) ; chercher 2375/2376 en écoute (aucun, threat-tests.txt T1). Réfuté si l'un des deux affiche quelque chose.
- Limite constatée : le listing du volume secret dans host-observations.txt a été fait par un conteneur jetable lancé avec mon compte, sans autre autorisation. Le contrôle ne couvre pas ce chemin. Risque accepté (compromis 1).

## 2. Réseau de la base de données
- Chemin d'attaque : compromission du proxy (seul service exposé) puis rebond vers postgres ; ou accès à 5432 depuis l'hôte.
- Abus probable : connexion à PostgreSQL pour lire ou modifier les données.
- Contrôle : postgres uniquement sur le réseau data (internal), proxy uniquement sur edge, aucun port publié sur postgres ni api.
- Test pour réfuter : résolution de postgres depuis le proxy (non résolu, T1/T2) ; connexion par IP depuis le proxy avec contrôle positif depuis l'API (threat-tests-2.txt, T11) ; sortie depuis postgres (bloquée, T4) ; ports de l'hôte (5432 et 8000 injoignables, before-regression.txt).
- Constat : l'API est sur edge, qui n'est pas internal, et T3 montre une sortie Internet possible. Le réseau interne protège la base, pas contre une exfiltration par une API compromise. Risque ouvert (compromis 2).

## 3. Fichier de mots de passe
- Chemin d'attaque : lecture par une API compromise (elle en a besoin), accès au volume via le démon (ressource 1), ou fuite dans Git, les preuves ou les logs.
- Abus probable : réutiliser le mot de passe pour se connecter à la base.
- Contrôle : volume monté en lecture seule dans api et postgres, absent du proxy ; 440 dans le volume ; copie hôte en 600 dans un dossier 700, ignorée par Git ; recherche du mot de passe dans les preuves à chaque commit (0 occurrence).
- Test pour réfuter : écriture refusée depuis l'API (threat-tests.txt T5) ; pas de /run/secrets dans le proxy (T5) ; git ls-files secrets/ vide.
- Hypothèse à vérifier : le rôle delivery est superutilisateur (créé par POSTGRES_USER). Test T10 dans threat-tests-2.txt, réfutée si rolsuper=f. Si rolsuper=t, une fuite du mot de passe donne tous les droits sur la base.

## 4. Système de fichiers API et proxy
- Chemin d'attaque : exécution de code dans l'API ou dans nginx, puis écriture ou persistance dans le conteneur.
- Abus probable : déposer un outil, modifier la configuration, élever ses privilèges.
- Contrôle observé : API en uid 10001, cap_drop ALL, no-new-privileges ; /srv et /usr non inscriptibles (threat-tests.txt T7) ; proxy en uid 101, nginx.conf monté en :ro dans compose.yaml et non modifiable (T6).
- Écarts observés : rootfs non read-only pour les trois services ; proxy sans cap_drop ni no-new-privileges ; /etc/nginx inscriptible par l'utilisateur nginx (T6) ; /tmp inscriptible (nécessaire).
- Test pour réfuter : T6 et T7, plus T12 (threat-tests-2.txt) pour savoir si le refus sur nginx.conf vient du flag :ro ou des droits du fichier sur l'hôte.
- Statut : read_only avec tmpfs, cap_drop et no-new-privileges sur le proxy sont prévus. Test de réfutation prévu : rejouer T6, T7 et la régression après le changement.

## 5. Identité de l'image
- Chemin d'attaque : une autre image que celle revue (tag mutable, image locale du même nom, build depuis un autre commit) est exécutée ou scannée à la place.
- Abus probable : du code non revu en exécution, ou un scan qui ne porte pas sur ce qui tourne.
- Contrôle : référence par digest dans release.env, utilisée par compose.yaml ; arrêt du scan si le digest diffère du conteneur ; regression.sh compare image, imageID et git_sha au label.
- Test pour réfuter : scanned = running = imageID (image-match.txt, MATCH) ; le commit 80871b2... du label existe dans le dépôt local (threat-tests.txt T8).
- Limites : l'image porte aussi un nom local delivery-api@sha256:... avec le même digest (T8). Le label revision est déclaré par l'image elle-même. git remote -v n'a rien affiché, donc le lien image.source n'a pas été vérifié ici. Le digest prouve les octets, pas leur innocuité : le scan reste à faire.

## 6. Dépendance d'exécution : gunicorn 23.0.0
- Chemin d'attaque : gunicorn analyse les requêtes HTTP relayées par le proxy ; une faille ou une version compromise donne l'exécution de code dans l'API.
- Abus probable : lecture du secret, requêtes SQL, sortie Internet (T3).
- Contrôle : versions épinglées avec empreintes (174 lignes --hash dans requirements.txt), image par digest, proxy devant gunicorn, utilisateur non root.
- Test pour réfuter : versions installées = versions épinglées (threat-tests.txt T9 : flask 3.1.2, gunicorn 23.0.0, psycopg 3.2.9, psycopg-binary 3.2.9). Réfuté si une version diffère.
- Limite : l'épinglage ne dit rien des vulnérabilités. Aucun état de CVE n'est établi à ce stade.

## Compromis
1. Groupe docker conservé. Il faut Docker pour travailler dans WSL. Coût : tout processus de mon compte pilote le démon. Atténuation : pas de socket monté, pas de TCP, pas de code non fiable sous ce compte. Alternative non retenue : Docker rootless, trop lourd à changer en cours de TD avec les volumes TD03.
2. API sur edge (à trancher). Laisser tel quel est simple et conforme au modèle TD04. L'alternative est un réseau public réservé au proxy et un réseau edge internal partagé avec l'API, ce qui supprime la sortie Internet de l'API. Coût : modifier compose.yaml, la régression, et vérifier que le port 127.0.0.1:8080 fonctionne toujours.

## Ce que ce modèle ne couvre pas
Pas de scan de vulnérabilités, pas de test de charge, pas d'analyse de l'hôte Windows ni de Docker Desktop lui-même.
