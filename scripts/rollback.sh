#!/usr/bin/env bash
set -Eeuo pipefail
# usage: scripts/rollback.sh   (sans argument : l'etat enregistre fait foi)
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/release-lib.sh"
[ "$#" -eq 0 ] || die "usage: rollback.sh (sans argument)" 2
command -v docker >/dev/null || die "docker introuvable" 4
require_no_marker
[ -f "$STATE_FILE" ] || die "aucun etat enregistre : rien a restaurer" 3
CUR="$(state_get current)"; PREV="$(state_get previous)"
valid_image "$CUR"  || die "current invalide dans l'etat : '$CUR'" 3
valid_image "$PREV" || die "aucun previous immuable enregistre : '$PREV'" 3
[ "$CUR" != "$PREV" ] || die "current == previous : rien a restaurer" 3
RUN="$(running_image)" || die "API absente" 4
[ "$RUN" = "$CUR" ] || die "etat enregistre ($CUR) != image active ($RUN) : revue necessaire" 3
switch_release rollback "$PREV" "$CUR" || exit 1
