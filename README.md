# WorkPane

**WorkPane** is a **small native macOS app** (release image on the order of **~5 MB**): **SwiftUI** plus the system **WebKit** only—no bundled browser engine. It stays **light and quick to open**, and gives you **separate panes** (each its own `WKWebView` and `WKWebsiteDataStore`) so you can **isolate productive work**—for example one pane for work mail, another for docs or dashboards, another for personal sites—without sessions, cookies, or storage bleeding between them.

Presets (Gmail, Outlook, iCloud Mail, Yahoo) and custom URLs are supported; the UI calls each connection a **pane** (with natural equivalents per language in localizations).

## Requirements

- macOS **14**+
- Xcode **15+** or Swift **5.9+** toolchain

## Build & run

From the repository root:

```bash
swift build
open .build/debug/WorkPane
```

Or open **`Package.swift`** in Xcode and run the **WorkPane** scheme.

## Icons

- **Dock / light–dark app icon:** source is **`assets/icon.icon`** — keep it **exactly** as **Icon Composer** exports it (`icon.json`, `Assets/`, etc.). Run **`./scripts/build-app-icon.sh`**: it compiles with **`actool` only when its major version is ≥ 26**; otherwise it **reuses** an existing **`Sources/WorkPane/Resources/Assets.car`** if present, or skips. SPM bundles **only** **`Assets.car`**. **`Info.plist`**: **`CFBundleIconName`** must match the name **`actool`** derives from the bundle (for `assets/icon.icon` it is **`icon`**, not `AppIcon`).
- **Regenerate** after editing the master icon: **`./scripts/build-app-icon.sh`** from the repository root.
- **Pane swatches:** icon ids stored with panes (e.g. `simple-icons:gmail`, `mdi:email`) are mapped to **SF Symbols** in **`IconifyMapper.swift`**.

## Build a DMG

```bash
./scripts/build-dmg.sh
```

Produces **`dist/WorkPane.app`** and **`dist/WorkPane-v<semver>.dmg`** (`<semver>` from **`CFBundleShortVersionString`** in **`Info.plist`**, with a **`v`** prefix). The mounted volume is named **`WorkPane v<semver>`**.

### Signing & notarization (GitHub release)

Tagged releases can use **repository secrets** for **Developer ID** signing and **notarization** (`notarytool` + `stapler`).

| Secret | Role |
|--------|------|
| `MACOS_CERTIFICATE_P12` | Base64 of the **Developer ID Application** `.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | Password for that `.p12` |
| `KEYCHAIN_PASSWORD` | Any string (temporary CI keychain) |
| `MACOS_CODESIGN_IDENTITY` | Full name, e.g. `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_API_ISSUER` | Issuer ID (App Store Connect → Integrations) |
| `APPLE_API_KEY_ID` | API key with **Developer** role |
| `APPLE_API_KEY_P8_BASE64` | Base64 of the `.p8` private key |

Without certificate secrets, the DMG is built with **ad hoc** signing. Without Apple API secrets, **notarization is skipped**.

## Settings

Preferences use the system **Settings** window (**⌘,**), not a modal sheet, so you can switch back to the main window without closing Settings first.

## UI

**SwiftUI** lists, forms, and a narrow sidebar; light/dark follows the system or your theme preference. Custom chrome is intentionally minimal: a **colored swatch** per pane. **Settings** is tabbed: **General** (appearance, language, user agent) and **Panes** (list, reorder, add presets or custom URL, per-pane options).

## Bundle identifier

**`Info.plist`** is embedded at link time (`CFBundleIdentifier` = **`jbdelavoix.workpane`**) so AppKit features that need a main bundle ID behave correctly. Automatic window tabbing is disabled in code as a safeguard.

## Data

- **Panes:** `~/Library/Application Support/WorkPane/panes.json`
- **Preferences:** `~/Library/Application Support/WorkPane/preferences.json`

---

A fuller browser-style shell around a similar idea lives in another repository: **[github.com/jbdelavoix/webmail-app](https://github.com/jbdelavoix/webmail-app)**.
