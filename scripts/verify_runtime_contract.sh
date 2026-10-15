#!/usr/bin/env bash
set -Eeuo pipefail
# Contrat d'execution : API/base privees, proxy en boucle locale, secret en fichier,
# ressources bornees, durcissement. Code non nul a la premiere exigence violee.
# API_CID / PROXY_CID / PG_CID permettent de tester le script sur un autre conteneur.
cd "$(dirname "$0")/.."
P=docker-delivery
API=${API_CID:-$(docker compose -p $P ps -q delivery-api)}
PX=${PROXY_CID:-$(docker compose -p $P ps -q proxy)}
PG=${PG_CID:-$(docker compose -p $P ps -q postgres)}
fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "PASS: $*"; }
insp() { docker inspect --format "$2" "$1"; }

for pair in "api:$API" "proxy:$PX" "postgres:$PG"; do
  n=${pair%%:*}; c=${pair#*:}
  [ -n "$c" ] || fail "$n : conteneur absent"
  insp "$c" '{{json .HostConfig.CapDrop}}' | grep -q ALL            || fail "$n : cap_drop ALL absent"
  insp "$c" '{{json .HostConfig.SecurityOpt}}' | grep -q no-new-privileges || fail "$n : no-new-privileges absent"
  [ "$(insp "$c" '{{.HostConfig.Privileged}}')" = false ]           || fail "$n : privileged"
  u=$(insp "$c" '{{.Config.User}}'); case "${u%%:*}" in ""|0|root) fail "$n : utilisateur root ($u)";; esac
  [ "$(insp "$c" '{{.HostConfig.Memory}}')" -gt 0 ]                 || fail "$n : memoire non bornee"
  [ "$(insp "$c" '{{.HostConfig.PidsLimit}}')" -gt 0 ]              || fail "$n : pids non bornes"
  [ "$(insp "$c" '{{.HostConfig.NanoCpus}}')" -gt 0 ]               || fail "$n : cpu non borne"
  ok "$n : cap_drop ALL, no-new-privileges, non root ($u), memoire/pids/cpu bornes"
done

for pair in "api:$API" "postgres:$PG"; do
  pb=$(insp "${pair#*:}" '{{json .HostConfig.PortBindings}}')
  { [ "$pb" = "{}" ] || [ "$pb" = "null" ]; } || fail "${pair%%:*} : port publie $pb"
done; ok "api et postgres : aucun port publie"
[ "$(insp "$PX" '{{json .HostConfig.PortBindings}}')" = '{"8080/tcp":[{"HostIp":"127.0.0.1","HostPort":"8080"}]}' ] \
  || fail "proxy : publication differente de 127.0.0.1:8080"; ok "proxy : 127.0.0.1:8080 uniquement"

for pair in "api:$API" "proxy:$PX"; do
  [ "$(insp "${pair#*:}" '{{.HostConfig.ReadonlyRootfs}}')" = true ] || fail "${pair%%:*} : racine non read-only"
done; ok "api et proxy : racine en lecture seule"

for pair in "api:$API" "postgres:$PG"; do
  insp "${pair#*:}" '{{range .Mounts}}{{.Destination}}={{.RW}} {{end}}' | grep -q '/run/secrets=false' \
    || fail "${pair%%:*} : secret absent ou inscriptible"
done; ok "secret monte en lecture seule dans api et postgres"
insp "$PX" '{{range .Mounts}}{{.Destination}} {{end}}' | grep -q /run/secrets && fail "proxy : secret monte"
ok "secret absent du proxy"
insp "$PG" '{{range .Mounts}}{{.Destination}}={{.RW}} {{end}}' | grep -q '/var/lib/postgresql/data=true' \
  || fail "postgres : volume de donnees non inscriptible"; ok "postgres : volume de donnees inscriptible"
[ "$(docker network inspect ${P}_data --format '{{.Internal}}')" = true ] || fail "reseau data non internal"
ok "reseau data internal"
echo "PASS: contrat d'execution respecte"
