#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT/Sources/WorkPane/Resources"
ICON_DIR="$ROOT/assets/icon.icon"

out="$(xcrun actool --version | grep -A 1 short-bundle-version | tail -n 1)"
[[ "$out" =~ ([0-9]+)\.[0-9]+ ]] && major="${BASH_REMATCH[1]}" || major=0
if (( major < 26 )); then
  echo "actool $major < 26 — skipping icon compilation"
  exit 0
fi

assets=$(ls -1 "$ICON_DIR/Assets")
for asset in $assets; do
  cp "$ICON_DIR/Assets/$asset" "$DEST_DIR/$asset"
done

xcrun actool "$ICON_DIR" --compile "$DEST_DIR" --platform macosx --minimum-deployment-target 14.0 >/dev/null

for asset in $assets; do
  rm "$DEST_DIR/$asset"
done

echo "Icon assets were successfully compiled into $DEST_DIR/Assets.car"
