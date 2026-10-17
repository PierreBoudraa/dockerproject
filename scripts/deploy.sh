#!/usr/bin/env bash
set -Eeuo pipefail
# usage: scripts/deploy.sh ghcr.io/<owner>/<repo>/<image>@sha256:<64 hex>
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/release-lib.sh"
[ "$#" -eq 1 ] || die "usage: deploy.sh <ghcr.io/...@sha256:64hex> (exactement un argument)" 2
CAND="$1"
valid_image "$CAND" || die "REJECTED: '$CAND' n'est pas un digest GHCR immuable (attendu : ghcr.io/...@sha256:<64 hex minuscules>)" 2
command -v docker >/dev/null || die "docker introuvable" 4
require_no_marker
init_state
CUR="$(state_get current)"
RUN="$(running_image)" || die "API absente" 4
[ "$RUN" = "$CUR" ] || die "etat enregistre ($CUR) != image active ($RUN) : revue necessaire" 3
if [ "$CAND" = "$CUR" ]; then echo "NOOP: $CAND est deja actif"; log_event deploy "$CAND" noop; exit 0; fi
switch_release deploy "$CAND" "$CUR" || exit 1
