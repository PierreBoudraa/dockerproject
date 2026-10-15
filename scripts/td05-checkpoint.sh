#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
. scripts/course-env.sh
set -a; . ./release.env; set +a
P=docker-delivery; E=evidence/TD05
api_id="$(docker compose -p $P ps -q delivery-api)"
proxy_id="$(docker compose -p $P ps -q proxy)"

test "$(docker inspect --format '{{.Config.Image}}' "$api_id")" = "$(cat $E/scanned-digest.txt)" && echo "PASS: image en cours = digest scanné"
test "$(cat $E/scanned-digest.txt)" = "$DELIVERY_API_IMAGE" && echo "PASS: digest scanné = release.env"
bash scripts/smoke.sh
bash scripts/regression.sh
bash scripts/verify_runtime_contract.sh
api_id="$(docker compose -p $P ps -q delivery-api)"
test "$(docker exec "$api_id" id -u)" = 10001 && echo "PASS: API en uid 10001"
docker exec "$api_id" test -r /run/secrets/postgres_password && echo "PASS: secret lisible par l'API"

set +e
docker exec --user 0 "$api_id" touch /srv/td05-checkpoint-denied > $E/checkpoint-denied.txt 2>&1
rc=$?
set -e
cat $E/checkpoint-denied.txt; echo "exit_code=$rc" | tee -a $E/checkpoint-denied.txt
[ "$rc" -ne 0 ] && grep -q 'Read-only file system' $E/checkpoint-denied.txt \
  || { echo 'FAIL: écriture interdite non refusée pour la bonne raison'; exit 1; }
echo "PASS: écriture refusée (Read-only file system)"

sha256sum --check $E/scanner-artifacts.sha256
python3 - <<'CHECK'
import json
from pathlib import Path
p = Path('evidence/TD05')
sbom = json.loads((p/'sbom.cdx.json').read_text())
assert sbom['bomFormat'] == 'CycloneDX' and isinstance(sbom['components'], list)
assert isinstance(json.loads((p/'vulnerabilities.json').read_text()), dict)
assert (p/'TRIAGE.md').stat().st_size
print('PASS: SBOM CycloneDX, scan JSON et TRIAGE.md présents')
CHECK

docker run --rm --platform "$COURSE_IMAGE_PLATFORM" --network none --read-only \
  --user "$(id -u):$(id -g)" --group-add 10001 --cap-drop ALL \
  --mount type=volume,source=td03-db-secret,target=/run/secrets,readonly \
  --mount "type=bind,source=$PWD/evidence,target=/evidence,readonly" \
  "$PYTHON_IMAGE" python -c '
from pathlib import Path
secret = Path("/run/secrets/postgres_password").read_bytes().strip()
if not secret:
    raise SystemExit("STOP: protected password file is empty")
leaks = [str(p.relative_to("/evidence")) for p in Path("/evidence").rglob("*")
         if p.is_file() and secret in p.read_bytes()]
if leaks:
    print("STOP: remove the password from these evidence files:", *leaks, sep="\n")
    raise SystemExit(1)
print("PASS: valeur du mot de passe absente des preuves")'
printf 'PASS: allowed behavior, denied write and saved scan checks agree\n'
