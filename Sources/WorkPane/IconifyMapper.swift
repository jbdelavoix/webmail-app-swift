import Foundation

/// Maps colon-style web icon ids (e.g. `simple-icons:gmail`) stored in `paneMeta.icon` to SF Symbols.
enum IconifyMapper {
    private static let map: [String: String] = [
        // Built-in providers & common ids
        "simple-icons:gmail": "envelope.fill",
        "simple-icons:microsoftoutlook": "building.2.fill",
        "simple-icons:icloud": "icloud.fill",
        "simple-icons:yahoo": "envelope.circle.fill",
        // Common custom / UI
        "mdi:email": "envelope.fill",
        "mdi:email-outline": "envelope",
        "mdi:email-open": "envelope.open.fill",
        "mdi:gmail": "envelope.fill",
        "mdi:web": "globe",
        "mdi:link": "link",
        "mdi:link-variant": "link.circle.fill",
        "mdi:at": "at",
        "mdi:user": "person.fill",
        "mdi:office-building": "building.2.fill",
        "mdi:google": "g.circle.fill",
        "mdi:microsoft-outlook": "building.2.fill",
        "logos:google-gmail": "envelope.fill",
        "logos:microsoft-outlook": "building.2.fill",
        "logos:yahoo": "envelope.circle.fill",
        "fa-solid:envelope": "envelope.fill",
        "fa:envelope": "envelope.fill",
        "heroicons:envelope": "envelope.fill",
        "tabler:mail": "envelope.fill",
        "carbon:email": "envelope.fill",
    ]

    static func sfSymbol(forIconifyID raw: String) -> String {
        let id = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let hit = map[id] { return hit }
        // Normalise "mdi-email" → "mdi:email"
        let colonised = id.replacingOccurrences(of: "-", with: ":")
        if let hit = map[colonised] { return hit }
        if id.contains("gmail") || id.contains("google-mail") { return "envelope.fill" }
        if id.contains("outlook") || id.contains("office") { return "building.2.fill" }
        if id.contains("icloud") || id.contains("apple") { return "icloud.fill" }
        if id.contains("yahoo") { return "envelope.circle.fill" }
        if id.contains("mail") || id.contains("email") { return "envelope.fill" }
        return "envelope.fill"
    }
}

extension MailPane {
    /// Uses `customIconSymbol` when allowed; else `paneMeta.icon` mapped through `IconifyMapper`; otherwise preset SF Symbol.
    var resolvedIconSymbolName: String {
        if let raw = customIconSymbol?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty,
           PaneIconChoices.isAllowed(raw) {
            return raw
        }
        if let icon = paneMeta?.icon {
            let t = icon.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return IconifyMapper.sfSymbol(forIconifyID: t) }
        }
        return providerSymbolName
    }
}
