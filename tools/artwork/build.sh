#!/bin/zsh
set -euo pipefail
TOOLS="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$TOOLS/../.." && pwd)"
ASSETS="$REPO/src/assets/Simba.xcassets"
MASTERS="$TOOLS/masters"
SOURCES="$TOOLS/sources"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export ICON_BG="${ICON_BG:-white}"

ACTIVE_HEAD=()
IDLE_HEAD=()
IDLE_GAZE=(11 5)

build_masters() {
  for photo in "$SOURCES/active.png" "$SOURCES/idle.png"; do
    [[ -f "$photo" ]] || { echo "missing $photo: the original photos are not in the repo (see README.md)" >&2; exit 1; }
  done
  (( ${#ACTIVE_HEAD[@]} == 12 && ${#IDLE_HEAD[@]} == 12 )) || { echo "fill in ACTIVE_HEAD and IDLE_HEAD at the top of $0 first" >&2; exit 1; }
  swiftc -O -o "$TMP/subjectmask" "$TOOLS/subjectmask.swift"
  "$TMP/subjectmask" "$SOURCES/active.png" "$TMP/active-mask.png"
  python3 "$TOOLS/headcut.py" "$SOURCES/active.png" "$TMP/active-mask.png" "$MASTERS/active.png" "${ACTIVE_HEAD[@]}"
  "$TMP/subjectmask" "$SOURCES/idle.png" "$TMP/idle-mask.png"
  python3 "$TOOLS/headcut.py" "$SOURCES/idle.png" "$TMP/idle-mask.png" "$TMP/idle-cut.png" "${IDLE_HEAD[@]}" "${IDLE_GAZE[@]}"
  python3 "$TOOLS/earfix.py" "$TMP/idle-cut.png" "$TMP/idle-ears.png"
  python3 "$TOOLS/frontalize.py" "$TMP/idle-ears.png" "$TMP/idle-front.png"
  python3 "$TOOLS/matchlight.py" "$MASTERS/active.png" "$TMP/idle-front.png" "$MASTERS/idle.png"
  echo "masters rebuilt from $SOURCES"
}

compose() {
  swiftc -O -o "$TMP/compose" "$TOOLS/compose.swift"
  "$TMP/compose" "$MASTERS/active.png" "$MASTERS/idle.png" "$ASSETS"
  echo "assets composed from $MASTERS (background: $ICON_BG)"
}

case "${1:-}" in
  "")         compose ;;
  --masters)  build_masters; compose ;;
  *)          echo "usage: $0 [--masters]" >&2; exit 2 ;;
esac
