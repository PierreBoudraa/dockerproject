#!/usr/bin/env bash
# usage: scripts/td03-api.sh METHOD /chemin ['{"json":"corps"}']
# Appelle l'API depuis un pair temporaire sur td03-private (corps sur stdout, code HTTP sur stderr)
set -euo pipefail
cd "$(dirname "$0")/.."
. ./release.env
docker run --rm --network td03-private \
  --label course.lab=TD03 --label course.environment=course-lab \
  --entrypoint python "$DELIVERY_API_IMAGE" -c '
import sys, urllib.request, urllib.error
method, path = sys.argv[1], sys.argv[2]
body = sys.argv[3].encode() if len(sys.argv) > 3 else None
req = urllib.request.Request("http://delivery-api:8000" + path, data=body, method=method,
                             headers={"Content-Type": "application/json"})
try:
    r = urllib.request.urlopen(req, timeout=5)
    code, out = r.status, r.read().decode()
except urllib.error.HTTPError as e:
    code, out = e.code, e.read().decode()
print(out)
sys.stderr.write("HTTP %s\n" % code)
' "$@"
