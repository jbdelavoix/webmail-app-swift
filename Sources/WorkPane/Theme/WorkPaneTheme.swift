import AppKit
import SwiftUI

/// Per-pane swatch colors (stable HSL from pane id). Everything else uses system chrome.
enum WorkPaneTheme {
    static func paneSwatchColor(id: Int64, isDark: Bool) -> Color {
        let hue = Double((id * 137) % 360) / 360.0
        let brightness = isDark ? 0.52 : 0.46
        return Color(hue: hue, saturation: 0.70, brightness: brightness)
    }

    /// `customColor` is persisted as `#RRGGBB` (HTML-style hex).
    static func resolvedSwatchColor(pane: MailPane, isDark: Bool) -> Color {
        if let raw = pane.customColor?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
           let c = Color(hexRGB: raw) {
            return c
        }
        return paneSwatchColor(id: pane.id, isDark: isDark)
    }
}

extension Color {
    /// Parses `#RGB`, `#RRGGBB`, or bare hex digits.
    init?(hexRGB raw: String) {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard !s.isEmpty else { return nil }
        if s.count == 3 {
            let chars = Array(s)
            s = "\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
        }
        guard s.count == 6, let v = UInt64(s, radix: 16) else { return nil }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// `#RRGGBB` for `MailPane.customColor`, or `nil` if conversion fails.
    func toHexRGBString() -> String? {
        guard let ns = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(round(ns.redComponent * 255))
        let g = Int(round(ns.greenComponent * 255))
        let b = Int(round(ns.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

enum ThemeResolver {
    static func isDark(uiAppearance: String, colorScheme: ColorScheme) -> Bool {
        switch uiAppearance {
        case "light": return false
        case "dark": return true
        default: return colorScheme == .dark
        }
    }
}
