#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="WorkPane"
SPM_TARGET="WorkPane"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist" 2>/dev/null || echo "0.0.0")"
VERSION_TAG="v${VERSION#v}"
DIST="$ROOT/dist"
STAGING="$DIST/dmg-staging"
APP_BUNDLE="$DIST/$APP.app"
DMG="$DIST/$APP-$VERSION_TAG.dmg"

rm -rf "$DIST"
mkdir -p "$DIST"

"$ROOT/scripts/build-app-icon.sh"

swift build -c release

BIN="$(swift build -c release --show-bin-path)/$APP"
BUNDLE="$(swift build -c release --show-bin-path)/${APP}_${SPM_TARGET}.bundle"
CAR="$ROOT/Sources/WorkPane/Resources/Assets.car"

[[ -f "$BIN" ]] || { echo "Missing $BIN" >&2; exit 1; }

rm -rf "$APP_BUNDLE" "$STAGING" "$DMG"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$APP"
cp "$ROOT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
[[ -d "$BUNDLE" ]] && cp -R "$BUNDLE" "$APP_BUNDLE/Contents/Resources/"
[[ -f "$CAR" ]] && cp "$CAR" "$APP_BUNDLE/Contents/Resources/Assets.car"

ENTITLEMENTS="$ROOT/WorkPane.entitlements"
if [[ -n "${MACOS_CODESIGN_IDENTITY:-}" ]]; then
  codesign --deep --force --options runtime --timestamp \
    --entitlements "$ENTITLEMENTS" \
    --sign "$MACOS_CODESIGN_IDENTITY" \
    "$APP_BUNDLE"
else
  codesign --force --sign - "$APP_BUNDLE" 2>/dev/null || true
fi

mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP $VERSION_TAG" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo "Successfully built $DMG"
