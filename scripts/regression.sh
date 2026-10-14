#!/usr/bin/env bash
set -Eeuo pipefail
# Regression : application, isolation, persistance, identite de release.
# Valeurs attendues = observations TD3 sauvegardees (evidence/TD03). Code non nul au premier echec.
cd "$(dirname "$0")/.."
. ./release.env
P=docker-delivery
T3=evidence/TD03
BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"

ok()   { echo "PASS: $*"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
get()  { curl --fail --silent --show-error --max-time 5 "$BASE_URL$1"; }
field() { python3 -c 'import json,sys;print(json.loads(sys.argv[1]).get(sys.argv[2]))' "$1" "$2"; }
json_eq() { python3 - "$1" "$2" <<'PY'
import json, sys
a = json.loads(sys.argv[1]); b = json.loads(open(sys.argv[2]).read())
sys.exit(0 if a == b else 1)
PY
}

API=$(docker compose -p $P ps -q delivery-api); [ -n "$API" ] || fail "conteneur delivery-api absent"
PG=$(docker compose -p $P ps -q postgres);      [ -n "$PG" ]  || fail "conteneur postgres absent"
PX=$(docker compose -p $P ps -q proxy);         [ -n "$PX" ]  || fail "conteneur proxy absent"

echo "== Application (via le proxy)"
b=$(get /healthz) || fail "/healthz injoignable ou non 200 via le proxy"
[ "$(field "$b" status)" = ok ] || fail "/healthz status != ok"; ok "/healthz ok"
b=$(get /readyz) || fail "/readyz injoignable ou non 200"
[ "$(field "$b" status)" = ready ] && [ "$(field "$b" dependency)" = postgres ] || fail "/readyz pas ready/postgres"; ok "/readyz ready (postgres)"
VER=$(get /version) || fail "/version injoignable"
[ "$(field "$VER" application)" = delivery-api ] || fail "/version application inattendue"; ok "/version delivery-api"

echo "== Persistance (marqueur TD3, id 2)"
b=$(get /api/items/2) || fail "/api/items/2 non 200"
json_eq "$b" $T3/step3-api-item-after.json || fail "element API 2 different de TD3"; ok "element API 2 identique a TD3"
b=$(get /api/items) || fail "/api/items non 200"
json_eq "$b" $T3/step3-api-list-after.json || fail "liste API differente de TD3"; ok "liste API identique a TD3"
rows=$(docker compose -p $P exec -T postgres psql -U delivery -d delivery -Atc "SELECT * FROM items ORDER BY id")
[ "$rows" = "$(cat $T3/step4-orig-rows.txt)" ] || fail "lignes SQL differentes de TD3"; ok "lignes SQL identiques a TD3"

echo "== Isolation"
for c in "$PG:postgres" "$API:delivery-api"; do
  pb=$(docker inspect "${c%%:*}" --format '{{json .HostConfig.PortBindings}}')
  { [ "$pb" = "{}" ] || [ "$pb" = "null" ]; } || fail "${c##*:} publie des ports : $pb"
done; ok "postgres et delivery-api : aucun port publie"
pb=$(docker inspect "$PX" --format '{{json .HostConfig.PortBindings}}')
[ "$pb" = '{"8080/tcp":[{"HostIp":"127.0.0.1","HostPort":"8080"}]}' ] || fail "proxy mal publie : $pb"; ok "proxy publie uniquement 127.0.0.1:8080"
for port in 5432 8000; do
  if timeout 2 bash -c "exec 3<>/dev/tcp/127.0.0.1/$port" 2>/dev/null; then fail "port $port joignable depuis l'hote"; fi
done; ok "5432 et 8000 injoignables depuis l'hote"

echo "== Identite de release"
img=$(docker inspect "$API" --format '{{.Config.Image}}')
[ "$img" = "$DELIVERY_API_IMAGE" ] || fail "image API $img != release.env"; ok "image API = release.env"
[ "$(docker inspect "$API" --format '{{.Image}}')" = "sha256:${DELIVERY_API_IMAGE##*@sha256:}" ] || fail "imageID != digest"; ok "imageID = digest"
rev=$(docker inspect "$API" --format '{{index .Config.Labels "org.opencontainers.image.revision"}}')
[ "$(field "$VER" git_sha)" = "$rev" ] || fail "git_sha de /version != label revision"; ok "git_sha = revision de l'image"
git diff --quiet "$(cat evidence/TD04/known-good-sha.txt)" -- compose.yaml nginx/nginx.conf \
  || fail "compose.yaml/nginx.conf different du known-good"; ok "definitions = known-good"

echo "PASS: regression complete"
