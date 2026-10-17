#!/usr/bin/env bash
set -Eeuo pipefail
# Prouve que le validateur accepte les vrais fichiers et rejette chaque violation volontaire.
cd "$(dirname "$0")/.."
W=.github/workflows/container-delivery.yml; C=compose.yaml; D=Dockerfile
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
bad=0
run() { set +e; OUT="$(python3 scripts/check_delivery_policy.py --workflow "$1" --compose "$2" --dockerfile "$3" 2>&1)"; RC=$?; set -e; }
run "$W" "$C" "$D"
if [ "$RC" -eq 0 ]; then echo "PASS: fichiers reels acceptes"; else echo "FAIL: fichiers reels refuses"; echo "$OUT"; bad=1; fi
expect_reject() {  # label regle workflow compose dockerfile
  run "$3" "$4" "$5"
  if [ "$RC" -ne 0 ] && grep -q "FAIL $2" <<<"$OUT"; then echo "PASS: violation rejetee ($1 -> $2)"
  else echo "FAIL: violation non rejetee ($1) rc=$RC"; echo "$OUT"; bad=1; fi
}
sed 's/@3d3c42e5aac5ba805825da76410c181273ba90b1/@v7/' "$W" > "$T/w1"
expect_reject "action non epinglee" R1 "$T/w1" "$C" "$D"
sed '0,/^permissions:/s//permissions:\n  packages: write/' "$W" > "$T/w2"
expect_reject "ecriture globale" R2 "$T/w2" "$C" "$D"
sed 's/^\( *\)packages: read/\1packages: write/' "$W" > "$T/w5"
expect_reject "ecriture hors publication" R3 "$T/w5" "$C" "$D"
cp "$W" "$T/w3"; printf '      - run: echo "${{ secrets.DEPLOY_KEY }}"\n' >> "$T/w3"
expect_reject "secret de deploiement" R4 "$T/w3" "$C" "$D"
sed "s/github.event_name == 'push'/true/" "$W" > "$T/w4"
expect_reject "publication sur pull request" R6 "$T/w4" "$C" "$D"
sed 's/"127\.0\.0\.1:/"0.0.0.0:/' "$C" > "$T/c1"
expect_reject "port ouvert a tous" C1 "$W" "$T/c1" "$D"
cp "$C" "$T/c2"; printf '    privileged: true\n' >> "$T/c2"
expect_reject "conteneur privilegie" C2 "$W" "$T/c2" "$D"
cp "$D" "$T/d1"; printf 'USER root\n' >> "$T/d1"
expect_reject "utilisateur root" D1 "$W" "$C" "$T/d1"
exit "$bad"
