import Foundation

enum WorkPaneStrings {
    /// `system` (or empty) → `Bundle.module` (OS language order). Otherwise the matching `.lproj` inside the SwiftPM resource bundle.
    static func bundle(for languageCode: String) -> Bundle {
        let code = languageCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !code.isEmpty, code != "system",
              let path = Bundle.module.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .module }
        return bundle
    }
}
