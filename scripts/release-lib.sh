#!/usr/bin/env bash
# Fonctions communes a deploy.sh et rollback.sh. A sourcer, pas a executer.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
PROJECT=docker-delivery
STATE_DIR="$ROOT/state"
STATE_FILE="$STATE_DIR/release-state.env"
MARKER="$STATE_DIR/PENDING"
HISTORY="$STATE_DIR/history.log"
IMAGE_RE='^ghcr\.io/[a-z0-9][a-z0-9._/-]*@sha256:[a-f0-9]{64}$'
REV_RE='^[a-f0-9]{40}$'

die()         { echo "ERROR: $1" >&2; exit "${2:-1}"; }
now()         { date -u +%FT%TZ; }
valid_image() { [[ "${1:-}" =~ $IMAGE_RE ]]; }
log_event()   { mkdir -p "$STATE_DIR"; printf '%s op=%s image=%s result=%s\n' "$(now)" "$1" "$2" "$3" >> "$HISTORY"; }
running_image() {
  local cid; cid="$(docker compose -p "$PROJECT" ps -q delivery-api)"
  [ -n "$cid" ] || return 1
  docker inspect --format '{{.Config.Image}}' "$cid"
}
revision_of() { docker image inspect --format '{{index .Config.Labels "org.opencontainers.image.revision"}}' "$1"; }
state_get()   { { [ -f "$STATE_FILE" ] && sed -n "s/^$1=//p" "$STATE_FILE" | head -n1; } || true; }

write_state() {   # current previous : ecriture atomique
  local tmp; mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"
  tmp="$(mktemp "$STATE_DIR/.state.XXXXXX")"
  printf 'updated_at_utc=%s\ncurrent=%s\nprevious=%s\n' "$(now)" "$1" "$2" > "$tmp"
  mv -f -- "$tmp" "$STATE_FILE"
}
init_state() {
  if [ -f "$STATE_FILE" ]; then return 0; fi
  local run; run="$(running_image)" || die "API absente : etat impossible a initialiser" 4
  valid_image "$run" || die "BLOCKED: image active non immuable : $run" 4
  write_state "$run" ""
  log_event init "$run" recorded
}
require_no_marker() {
  [ ! -e "$MARKER" ] || { cat "$MARKER" >&2
    die "operation precedente non terminee ($MARKER). Revoir : image active, release.env, $STATE_FILE ; supprimer le marqueur seulement apres revue." 3; }
}
write_marker() {  # op target fallback
  mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"
  ( set -o noclobber
    printf 'operation=%s\ntarget=%s\nfallback=%s\nstarted_at_utc=%s\npid=%s\n' "$1" "$2" "$3" "$(now)" "$$" > "$MARKER" ) 2>/dev/null \
    || die "marqueur deja present : $MARKER" 3
}
set_release_image() {  # release.env puis .env (lu par Compose), atomiques
  local tmp
  tmp="$(mktemp "$ROOT/.release.env.XXXXXX")"
  printf 'DELIVERY_API_IMAGE=%s\n' "$1" > "$tmp"; chmod 644 "$tmp"; mv -f -- "$tmp" "$ROOT/release.env"
  tmp="$(mktemp "$ROOT/.env.XXXXXX")"
  cat "$ROOT/.env.example" "$ROOT/release.env" > "$tmp"; chmod 644 "$tmp"; mv -f -- "$tmp" "$ROOT/.env"
}
activate_api() {       # seul delivery-api est recree ; ni build, ni pull implicite
  set_release_image "$1"
  DELIVERY_API_IMAGE="$1" docker compose -p "$PROJECT" up --detach --no-build --pull never \
    --no-deps --force-recreate --wait --wait-timeout 120 delivery-api </dev/null
}
smoke_with_retry() {   # le proxy re-resout le DNS toutes les 10 s
  local i
  for i in 1 2 3 4 5 6; do
    if EXPECTED_GIT_SHA="$1" bash "$ROOT/scripts/smoke.sh" </dev/null; then return 0; fi
    echo "smoke : tentative $i/6 echouee, nouvelle tentative dans 5 s" >&2; sleep 5
  done
  return 1
}
verify_release() {     # image active == $1, /version == revision OCI, regression
  local cid; cid="$(docker compose -p "$PROJECT" ps -q delivery-api)"
  [ -n "$cid" ] || { echo "API absente" >&2; return 1; }
  [ "$(docker inspect --format '{{.Config.Image}}' "$cid")" = "$1" ] || { echo "image active != $1" >&2; return 1; }
  smoke_with_retry "$2" || return 1
  bash "$ROOT/scripts/regression.sh" </dev/null || return 1
}
recover() { activate_api "$FALLBACK" && verify_release "$FALLBACK" "$REV_F"; }

switch_cleanup() {
  local rc=$?
  trap - EXIT INT TERM HUP
  if [ "$PHASE" = done ]; then exit "$rc"; fi
  [ "$rc" -ne 0 ] || rc=1
  echo "ECHEC OU INTERRUPTION (phase=$PHASE) : retour vers $FALLBACK" >&2
  if recover; then
    log_event "$OP" "$TARGET" "failed-recovered-to-previous"
    mv -f -- "$MARKER" "$STATE_DIR/failed-operation-$(date -u +%Y%m%dT%H%M%SZ).txt"
    echo "RECOVERED: image precedente reactivee et verifiee ; trace dans $STATE_DIR/" >&2
  else
    log_event "$OP" "$TARGET" "failed-RECOVERY-FAILED"
    echo "RECOVERY FAILED: marqueur conserve : $MARKER (revue manuelle requise)" >&2
    rc=2
  fi
  exit "$rc"
}

switch_release() {     # op target fallback
  OP="$1"; TARGET="$2"; FALLBACK="$3"
  local rev_t
  docker pull "$TARGET" </dev/null || die "pull impossible : $TARGET" 4
  rev_t="$(revision_of "$TARGET")"
  [[ "$rev_t" =~ $REV_RE ]] || die "revision OCI absente ou invalide pour $TARGET : '$rev_t'" 5
  REV_F="$(revision_of "$FALLBACK")"
  [[ "$REV_F" =~ $REV_RE ]] || die "revision OCI invalide pour $FALLBACK : '$REV_F'" 5
  write_marker "$OP" "$TARGET" "$FALLBACK"
  PHASE=activating
  trap switch_cleanup EXIT; trap 'exit 130' INT; trap 'exit 143' TERM HUP
  if activate_api "$TARGET" && verify_release "$TARGET" "$rev_t"; then
    write_state "$TARGET" "$FALLBACK"
    PHASE=done; rm -f -- "$MARKER"
    log_event "$OP" "$TARGET" ok
    echo "PASS: $OP verifie : image active $TARGET (revision $rev_t)"
    return 0
  fi
  echo "FAIL: verification de $TARGET echouee" >&2
  return 1
}
