# TD05 : tri des vulnérabilités (brouillon à reformuler)

Source : vulnerabilities.json (Trivy 0.73.0, image abb19cde..., empreintes dans scanner-artifacts.sha256). Liste filtrée : high-critical.tsv.
Résultat : 0 CRITICAL et 48 HIGH, sur 21 composants. Les MEDIUM, LOW et UNKNOWN ne sont pas triés ici.
Responsable : Pierre (propriétaire du dépôt et de l'image). Date de révision : 2026-10-22. Expiration de toute exception : 2026-11-15.
Mentions : "testé" = vu dans une sortie ; "raisonnement" = déduit de l'architecture.

Contrôles en place (testés) : API uid 10001, CapEff 0, NoNewPrivs 1, racine en lecture seule, aucun port publié sur l'API (api-identity.txt, runtime-controls.txt, root-write-denied.txt) ; proxy dans le même état (proxy-identity.txt). Binaires setuid et bibliothèques chargées : reach-check.txt.

## A. Correctif disponible

| Composant | Version installée | Version corrigée | Statut Trivy | Identifiants (titre) |
|---|---|---|---|---|
| libssl3t64 | 3.5.7-1~deb13u2 | 3.5.7-1~deb13u3 | fixed | CVE-2026-84782 (openssl: compat-openssl: openssl: Information disclosure via DTLS hand) |
| openssl | 3.5.7-1~deb13u2 | 3.5.7-1~deb13u3 | fixed | CVE-2026-84782 (openssl: compat-openssl: openssl: Information disclosure via DTLS hand) |
| openssl-provider-legacy | 3.5.7-1~deb13u2 | 3.5.7-1~deb13u3 | fixed | CVE-2026-84782 (openssl: compat-openssl: openssl: Information disclosure via DTLS hand) |
| libpcre2-8-0 | 10.46-1~deb13u2 | 10.46-1~deb13u3 | fixed | CVE-2026-103111 (pcre2: pcre2: Out-of-bounds write via crafted regular expression) |

- Atteignabilité : non démontrée. Les requêtes entrantes passent par le proxy en HTTP, sans TLS terminé dans cette pile (raisonnement : nginx.conf n'écoute qu'en HTTP). OpenSSL et PCRE2 ne servent donc qu'au code de l'API ou à ses connexions sortantes. reach-check.txt dit si libssl, libcrypto et libpcre2 sont chargées dans le processus API (testé : chargée ou non, pas : utilisée). Par prudence, je les traite comme atteignables.
- Chemin d'accès de l'attaquant : requête HTTP vers 127.0.0.1:8080, puis proxy, puis gunicorn. Il n'est exploitable que si la faille se déclenche dans ce traitement (raisonnement ; descriptions complètes non lues).
- Disposition : reconstruction sur une base contenant la version corrigée, nouveau scan du nouveau digest et nouveaux tests avant déploiement. Non faite dans ce TD : un rebuild change le digest et la référence de release (TD6). D'ici là : acceptation temporaire.
- Responsable : Pierre. Revue : 2026-10-22. Expiration : 2026-11-15.
- Risque résiduel : tant que abb19cde... tourne, ces versions sont présentes. Bornes testées : uid 10001, CapEff 0, NoNewPrivs 1, racine en lecture seule, aucun port publié sur l'API. Non borné : la sortie Internet de l'API (threat-tests.txt, T3).

## B. Famille util-linux (sans correctif)

| Composant | Version installée | Version corrigée | Statut Trivy | Identifiants (titre) |
|---|---|---|---|---|
| bsdutils | 1:2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| libblkid1 | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| liblastlog2-2 | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| libmount1 | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| libsmartcols1 | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| libuuid1 | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| login | 1:4.16.0-2+really2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| mount | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |
| util-linux | 2.41.5-0+deb13u1 | aucun correctif | affected | CVE-2026-76642 (util-linux: util-linux: failed external mount helper still runs privil); CVE-2026-78408 (util-linux: util-linux: nsenter --join-cgroup leaks root cgroup migrat); CVE-2026-78409 (util-linux: util-linux: X-mount.subdir detached-tree resolution can es); CVE-2026-78410 (util-linux: util-linux: restricted bind mounts do not pin the source, ) |

- Correctif : aucun dans la base Debian au moment du scan (statut affected, scan du 2026-10-15).
- Atteignabilité : ce sont des bibliothèques et outils système. Les atteindre suppose d'abord d'exécuter du code dans le conteneur (raisonnement : l'API n'expose que des routes HTTP, pas de shell). Les binaires setuid listés dans reach-check.txt ne peuvent pas élever de privilèges avec NoNewPrivs 1 et CapEff 0 (testé : les deux valeurs ; raisonnement : la conséquence).
- Chemin d'accès de l'attaquant : exécution de code dans l'API, puis appel local d'un de ces outils. Non testé CVE par CVE.
- Disposition : acceptation temporaire, sans correctif disponible. Responsable : Pierre. Revue : 2026-10-22 (refaire le scan, reconstruire si un correctif est publié). Expiration : 2026-11-15.
- Risque résiduel : après compromission de l'API, une faille locale reste exploitable dans les limites uid 10001, sans capacités, racine en lecture seule, plus la sortie Internet (T3).

## C. Autres composants (sans correctif ou correctif reporté)

| Composant | Version installée | Version corrigée | Statut Trivy | Identifiants (titre) |
|---|---|---|---|---|
| libacl1 | 2.3.2-2+b1 | aucun correctif | affected | CVE-2026-54369 (acl: Symlink traversal privilege escalation via libacl functions) |
| libncursesw6 | 6.5+20250216-2 | aucun correctif | affected | CVE-2025-69720 (ncurses: ncurses: Buffer overflow vulnerability may lead to arbitrary ) |
| libsystemd0 | 257.13-1~deb13u1 | aucun correctif | affected | CVE-2026-16742 (systemd: systemd-homed: Local privilege escalation via missing home-re) |
| libtinfo6 | 6.5+20250216-2 | aucun correctif | affected | CVE-2025-69720 (ncurses: ncurses: Buffer overflow vulnerability may lead to arbitrary ) |
| libudev1 | 257.13-1~deb13u1 | aucun correctif | affected | CVE-2026-16742 (systemd: systemd-homed: Local privilege escalation via missing home-re) |
| ncurses-base | 6.5+20250216-2 | aucun correctif | affected | CVE-2025-69720 (ncurses: ncurses: Buffer overflow vulnerability may lead to arbitrary ) |
| ncurses-bin | 6.5+20250216-2 | aucun correctif | affected | CVE-2025-69720 (ncurses: ncurses: Buffer overflow vulnerability may lead to arbitrary ) |
| perl-base | 5.40.1-6+deb13u1 | aucun correctif | fix_deferred | CVE-2026-9538 (perl-Archive-Tar: perl-Archive-Tar: Denial of Service via crafted tar ) |

- Correctif : aucun dans la base Debian au moment du scan. perl-base est en fix_deferred (correctif reporté par Debian).
- Atteignabilité : mêmes raisonnements que pour util-linux. reach-check.txt dit lesquelles de ces bibliothèques (libsystemd, libudev, libncursesw, libtinfo, libacl) sont chargées par l'API.
- Disposition : acceptation temporaire. Responsable : Pierre. Revue : 2026-10-22. Expiration : 2026-11-15.
- Risque résiduel : même borne que ci-dessus.

## Ce que ce tri ne couvre pas
- Les images du proxy (nginx) et de PostgreSQL ne sont pas scannées dans ce TD : seul l'API l'est.
- Les 99 MEDIUM, 70 LOW et 3 UNKNOWN ne sont pas triés.
- Les descriptions complètes des CVE ne sont pas lues ; la date de construction de la base Trivy n'est pas enregistrée (voir OBSERVATIONS.md).
- L'atteignabilité est un raisonnement, sauf les points marqués testés.

## Mise à jour : atteignabilité mesurée (reach-check.txt, reach-workers.txt)
- libssl et libcrypto : 5 mappages chacune dans PID 1, donc chargées (testé). Les paquets libssl3t64, openssl et openssl-provider-legacy sont à traiter comme atteignables. Correctif disponible (3.5.7-1~deb13u3) : décision de reconstruction à prendre avec une échéance (voir ci-dessous).
- libpcre2 n'apparaît dans les mappages d'aucun processus de l'API (PID 1 et workers) au moment du test. Une bibliothèque pouvant être chargée plus tard, je ne conclus pas à l'inaccessibilité.
- libsystemd, libudev, libblkid, libmount, libuuid, libsmartcols, libncursesw, libtinfo et libacl : 0 mappage dans PID 1 (testé).
- Binaires setuid présents dans l'image (reach-check.txt) : inutilisables pour élever les privilèges tant que NoNewPrivs=1 et CapEff=0 (api-identity.txt). Cette protection vient de compose.yaml, pas de l'image.
- Limite : un mappage montre qu'une bibliothèque est chargée, pas qu'une fonction vulnérable est appelée.
