#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
ASSETS="../Simba/Assets.xcassets"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CONCEPT="${CONCEPT:-3d}"
ICON_BG="${ICON_BG:-white}"
MASTER="${MASTER:-icon-master.png}"
CLOSED="${CLOSED:-icon-master-closed.png}"
[[ "${1:-}" == "--from-master" ]] && FROM_MASTER=1 || FROM_MASTER=0

swiftc -O -o "$TMP/svg2png" svg2png.swift
render() {
  "$TMP/svg2png" "$1" "$2" "$3" "$4"
}
resize() {
  sips -z "$3" "$2" "$1" --out "$4" >/dev/null
}
menubar_contents() {
  cat > "$1/Contents.json" <<EOF
{
  "images" : [
    { "filename" : "$2.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "$2@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "idiom" : "universal", "scale" : "3x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "$3" }
}
EOF
}

if [[ "$CONCEPT" == "3d" ]]; then
  if [[ "$FROM_MASTER" == 0 ]]; then
    swiftc -O -o "$TMP/render3d" render3d.swift
    STATE=open ICON_BG="$ICON_BG" "$TMP/render3d" "$TMP/open" >/dev/null
    STATE=closed ICON_BG="$ICON_BG" "$TMP/render3d" "$TMP/closed" >/dev/null
    cp "$TMP/open/render.png" "$MASTER"
    cp "$TMP/closed/render.png" "$CLOSED"
  fi
  [[ -f "$MASTER" && -f "$CLOSED" ]] || { echo "no masters to compose from; run without --from-master first" >&2; exit 1; }
  swiftc -O -o "$TMP/compose" compose.swift
  ICON_BG="$ICON_BG" "$TMP/compose" "$MASTER" "$CLOSED" "$ASSETS"
  menubar_contents "$ASSETS/MenuBarSimba.imageset" menubar original
  menubar_contents "$ASSETS/MenuBarSimbaIdle.imageset" menubar-idle original
  echo "Assets regenerated from Design/$MASTER and Design/$CLOSED (background: $ICON_BG)."
  exit 0
else
  python3 generate.py "$CONCEPT" "$TMP/svg" >/dev/null
  SVG="$TMP/svg"
  render "$SVG/app-icon.svg" 1024 1024 "$TMP/icon.png"
  MW=$(sed -n 's/.*<svg[^>]* width="\([0-9]*\)".*/\1/p' "$SVG/mark.svg" | head -1)
  MH=$(sed -n 's/.*<svg[^>]* height="\([0-9]*\)".*/\1/p' "$SVG/mark.svg" | head -1)
  render "$SVG/mark.svg" $((MW * 2)) $((MH * 2)) "$TMP/mark.png"
  resize "$TMP/mark.png" $((MW / 2)) $((MH / 2)) "$ASSETS/SimbaMark.imageset/mark.png"
  resize "$TMP/mark.png" $MW $MH "$ASSETS/SimbaMark.imageset/mark@2x.png"
fi

for size in 16 32 128 256 512; do
  resize "$TMP/icon.png" $size $size "$ASSETS/AppIcon.appiconset/icon_${size}x${size}.png"
  resize "$TMP/icon.png" $((size * 2)) $((size * 2)) "$ASSETS/AppIcon.appiconset/icon_${size}x${size}@2x.png"
done

render "$SVG/menubar-active.svg" 360 360 "$TMP/active.png"
resize "$TMP/active.png" 18 18 "$ASSETS/MenuBarSimba.imageset/menubar.png"
resize "$TMP/active.png" 36 36 "$ASSETS/MenuBarSimba.imageset/menubar@2x.png"
render "$SVG/menubar-idle.svg" 360 360 "$TMP/idle.png"
resize "$TMP/idle.png" 18 18 "$ASSETS/MenuBarSimbaIdle.imageset/menubar-idle.png"
resize "$TMP/idle.png" 36 36 "$ASSETS/MenuBarSimbaIdle.imageset/menubar-idle@2x.png"
menubar_contents "$ASSETS/MenuBarSimba.imageset" menubar template
menubar_contents "$ASSETS/MenuBarSimbaIdle.imageset" menubar-idle template
echo "Assets regenerated (concept: $CONCEPT)."
