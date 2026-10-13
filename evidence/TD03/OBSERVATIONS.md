# TD03 : observations

Trois affirmations distinctes, chacune avec ses preuves. Donnees synthetiques uniquement.

## 1. Accessibilite privee
Affirmation : l'API joint PostgreSQL uniquement par un reseau Docker prive, et rien n'est expose sur l'hote.
- Appartenance au reseau : td03-postgres et td03-delivery-api sont sur td03-private (step5-network.txt).
- DNS par nom de service : le nom postgres se resout en adresse IP depuis le reseau (step5-dns.txt), et l'API l'utilise pour se connecter (postgres:5432).
- /readyz : HTTP 200 {"status":"ready"} depuis un pair temporaire sur td03-private (step2-readyz.txt).
- Aucun port hote : PortBindings vide pour les deux conteneurs (step5-ports.txt, step2-inspect.txt).
- Limite : le reseau n'est pas internal, donc les conteneurs pourraient encore sortir vers Internet. Prive veut dire non expose sur l'hote.

## 2. Persistance
Affirmation : les donnees survivent au remplacement des conteneurs parce qu'elles sont dans le volume td03-postgres-data.
- Avant et apres suppression/recreation : meme ligne SQL (id 1) et meme element API (id 2), memes valeurs (step3-compare.txt, six comparaisons IDENTIQUE).
- Les ID de conteneur ont change (step3-containers-before.txt et step3-containers-after.txt), donc ce sont bien de nouveaux conteneurs.
- Journal PostgreSQL : "Skipping initialization" (step3-skip-init.txt) : la base existante a ete reutilisee, pas recreee depuis le SQL.

## 3. Reprise apres sinistre (recuperation des donnees sauvegardees)
Affirmation : la sauvegarde est utilisable, car elle a ete verifiee puis restauree ailleurs.
- Sauvegarde pg_dump au format personnalise, non vide, 11 entrees listees (step4-list.txt), SHA-256 5830624bb3c666bd... verifie avant restauration (step4-sha256.txt).
- Cible de restauration separee : conteneur etiquete, sans reseau ni port hote, volume jetable.
- Les enregistrements restaures sont identiques aux originaux (step4-compare.txt, step5-compare.txt).
- Temps de restauration (verification du checksum + pg_restore) : 0.2 s, mesure sur une seconde restauration jetable (step5-restore-secs.txt).
- La base de travail est restee disponible et inchangee, API en HTTP 200. Seuls le conteneur et le volume de restauration ont ete supprimes, sans prune.

## Limite de cette sauvegarde
Elle prouve la recuperation des enregistrements captures au moment du dump, pas des ecritures faites apres. Elle ne prouve pas non plus un objectif complet de reprise apres sinistre : pas de RPO ni de RTO definis, une seule copie sur la meme machine, aucune restauration de l'API ni du reseau, aucune sauvegarde automatique.

## Secrets
Le mot de passe (secrets/, mode 600) et le dump (backups/) sont ignores par Git et absents des preuves partagees.

## Suite
TD4 placera ces services derriere un proxy dans Compose.
