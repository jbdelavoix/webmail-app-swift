#!/usr/bin/env bash
# Notarize + staple dist/WorkPane-v<semver>.dmg (semver from Info.plist CFBundleShortVersionString).
# Env: APPLE_API_ISSUER, APPLE_API_KEY_ID, APPLE_API_KEY_P8 (full .p8 PEM content, not base64).
# Optional: APPLE_API_KEY_P8_BASE64 if you store the key base64-encoded in CI.
# No-op if APPLE_API_KEY_ID is unset.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist" 2>/dev/null || echo "0.0.0")"
VERSION_TAG="v${VERSION#v}"
DMG="$ROOT/dist/WorkPane-$VERSION_TAG.dmg"

[[ -f "$DMG" ]] || { echo "Missing $DMG" >&2; exit 1; }
[[ -n "${APPLE_API_KEY_ID:-}" ]] || { echo "No APPLE_API_KEY_ID — skip notarization"; exit 0; }
[[ -n "${APPLE_API_ISSUER:-}" ]] || { echo "APPLE_API_ISSUER required for notarization" >&2; exit 1; }

KEY_PATH="${RUNNER_TEMP:-/tmp}/AuthKey-notarize.p8"
if [[ -n "${APPLE_API_KEY_P8_BASE64:-}" ]]; then
  echo "$APPLE_API_KEY_P8_BASE64" | base64 -d > "$KEY_PATH"
elif [[ -n "${APPLE_API_KEY_P8:-}" ]]; then
  printf '%s\n' "$APPLE_API_KEY_P8" > "$KEY_PATH"
else
  echo "Set APPLE_API_KEY_P8 or APPLE_API_KEY_P8_BASE64" >&2
  exit 1
fi
chmod 600 "$KEY_PATH"

xcrun notarytool submit "$DMG" \
  --issuer "$APPLE_API_ISSUER" \
  --key-id "$APPLE_API_KEY_ID" \
  --key "$KEY_PATH" \
  --wait

xcrun stapler staple "$DMG"
rm -f "$KEY_PATH"
echo "Stapled $DMG"
