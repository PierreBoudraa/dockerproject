#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. scripts/course-env.sh
. ./release.env

NET=td03-private
VOL_DATA=td03-postgres-data
VOL_SECRET=td03-db-secret
PG=td03-postgres
API=td03-delivery-api
INIT_SQL="db/init/001-schema.sql"
DB_NAME="delivery"
DB_USER="delivery"
LABELS=(--label course.lab=TD03 --label course.environment=course-lab)

[ -f "$INIT_SQL" ] || { echo "SQL introuvable: $INIT_SQL"; exit 1; }
chmod a+r "$INIT_SQL"

# 1. Garde-fous: ne toucher qu'aux objets TD03
for k in network:$NET volume:$VOL_DATA volume:$VOL_SECRET; do
  kind=${k%%:*}; name=${k#*:}
  lab=$(docker $kind inspect "$name" --format '{{index .Labels "course.lab"}}')
  [ "$lab" = "TD03" ] || { echo "STOP: $kind $name n'appartient pas a TD03"; exit 1; }
done
for c in $PG $API; do
  if docker inspect "$c" >/dev/null 2>&1; then
    lab=$(docker inspect "$c" --format '{{index .Config.Labels "course.lab"}}')
    [ "$lab" = "TD03" ] || { echo "STOP: conteneur $c n'appartient pas a TD03"; exit 1; }
    docker rm -f "$c" >/dev/null
  fi
done

# 2. PostgreSQL (aucun port publie)
docker run -d --name $PG "${LABELS[@]}" \
  --network $NET --network-alias postgres --restart no \
  --user 70:70 --cap-drop ALL --security-opt no-new-privileges \
  --memory 512m --memory-swap 512m --cpus 1.0 --pids-limit 200 \
  --env POSTGRES_USER="$DB_USER" --env POSTGRES_DB="$DB_NAME" \
  --env POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password \
  -v "$VOL_DATA:/var/lib/postgresql/data" \
  -v "$VOL_SECRET:/run/secrets:ro" \
  -v "$PWD/$INIT_SQL:/docker-entrypoint-initdb.d/01-init.sql:ro" \
  "$POSTGRES_IMAGE" >/dev/null

# 3. Attendre PostgreSQL (TCP, donc apres l'initialisation)
for i in $(seq 1 60); do
  if docker exec $PG pg_isready -h 127.0.0.1 -p 5432 -U "$DB_USER" -d "$DB_NAME" >/dev/null 2>&1; then
    echo "postgres pret apres ${i}s"; break
  fi
  [ "$i" = 60 ] && { echo "STOP: postgres pas pret"; docker logs --tail 20 $PG; exit 1; }
  sleep 1
done

# 4. API (aucun port publie)
docker run -d --name $API "${LABELS[@]}" \
  --network $NET --network-alias delivery-api --restart no \
  --cap-drop ALL --security-opt no-new-privileges \
  --memory 256m --memory-swap 256m --cpus 0.5 --pids-limit 100 \
  --env DATABASE_HOST=postgres --env DATABASE_PORT=5432 \
  --env POSTGRES_DB="$DB_NAME" --env POSTGRES_USER="$DB_USER" \
  --env POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password \
  -v "$VOL_SECRET:/run/secrets:ro" \
  "$DELIVERY_API_IMAGE" >/dev/null
sleep 5
docker ps --filter label=course.lab=TD03 --format 'table {{.Names}}\t{{.Status}}'
