#!/usr/bin/env bash
# Import Developer ID Application .p12 into a temporary keychain (GitHub Actions).
# Secrets: MACOS_CERTIFICATE_P12 (base64), MACOS_CERTIFICATE_PASSWORD, KEYCHAIN_PASSWORD.
# No-op if MACOS_CERTIFICATE_P12 is unset or empty.
set -euo pipefail

[[ -n "${MACOS_CERTIFICATE_P12:-}" ]] || { echo "No MACOS_CERTIFICATE_P12 — skip keychain import"; exit 0; }
[[ -n "${MACOS_CERTIFICATE_PASSWORD:-}" ]] || { echo "MACOS_CERTIFICATE_PASSWORD required" >&2; exit 1; }
[[ -n "${KEYCHAIN_PASSWORD:-}" ]] || { echo "KEYCHAIN_PASSWORD required" >&2; exit 1; }

KEYCHAIN="${RUNNER_TEMP:-/tmp}/build.keychain-db"
CERT_P12="${RUNNER_TEMP:-/tmp}/signing.p12"

security delete-keychain "$KEYCHAIN" 2>/dev/null || true
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security list-keychains -d user -s "$KEYCHAIN"
security default-keychain -s "$KEYCHAIN"

echo "$MACOS_CERTIFICATE_P12" | base64 -d > "$CERT_P12"
security import "$CERT_P12" -k "$KEYCHAIN" -P "$MACOS_CERTIFICATE_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productsign
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
rm -f "$CERT_P12"

echo "Keychain ready for codesign"
