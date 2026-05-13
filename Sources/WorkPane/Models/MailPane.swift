import Foundation

/// Pane record persisted to disk (identity, URLs, and WebKit data-store binding).
struct MailPane: Codable, Identifiable, Equatable, Hashable {
    var id: Int64
    var provider: String
    /// Opaque website-data partition string (persisted).
    var partition: String
    /// Stable WKWebsiteDataStore key (Swift-native; persisted).
    var dataStoreId: UUID
    var customName: String?
    var customColor: String?
    /// When set (and in `PaneIconChoices`), overrides `paneMeta` / preset icon in the UI.
    var customIconSymbol: String?
    var paneMeta: PaneMeta?
    var unreadCount: Int

    struct PaneMeta: Codable, Equatable, Hashable {
        var name: String
        var url: String
        var icon: String
    }

    enum Provider: String, CaseIterable {
        case gmail
        case outlook
        case icloud
        case yahoo
        case custom

        var defaultURL: URL? {
            switch self {
            case .gmail: return URL(string: "https://mail.google.com")
            case .outlook: return URL(string: "https://outlook.office365.com/mail/inbox")
            case .icloud: return URL(string: "https://mail.icloud.com")
            case .yahoo: return URL(string: "https://mail.yahoo.com")
            case .custom: return nil
            }
        }

        /// Brand names — not localized.
        var displayName: String {
            switch self {
            case .gmail: return "Gmail"
            case .outlook: return "Outlook"
            case .icloud: return "iCloud Mail"
            case .yahoo: return "Yahoo Mail"
            case .custom: return "Custom"
            }
        }
    }

    func resolvedURL() -> URL? {
        if let preset = Provider(rawValue: provider), preset != .custom {
            return preset.defaultURL
        }
        if provider == "custom", let raw = paneMeta?.url {
            return URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }

    func sidebarTitle(stringsBundle: Bundle) -> String {
        if let name = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        if let meta = paneMeta?.name, provider == "custom", !meta.isEmpty {
            return meta
        }
        if let p = Provider(rawValue: provider) {
            return p.displayName
        }
        return String(localized: "pane.fallback_title", bundle: stringsBundle)
    }

    /// For narrow sidebars: ellipsis when longer than `maxLength` (Unicode ellipsis).
    func sidebarTitleTruncated(maxLength: Int = 14, stringsBundle: Bundle) -> String {
        let t = sidebarTitle(stringsBundle: stringsBundle)
        guard t.count > maxLength else { return t }
        guard maxLength > 1 else { return String(t.prefix(1)) }
        return String(t.prefix(maxLength - 1)) + "…"
    }

    init(
        id: Int64,
        provider: String,
        partition: String,
        dataStoreId: UUID,
        customName: String?,
        customColor: String?,
        customIconSymbol: String? = nil,
        paneMeta: PaneMeta?,
        unreadCount: Int
    ) {
        self.id = id
        self.provider = provider
        self.partition = partition
        self.dataStoreId = dataStoreId
        self.customName = customName
        self.customColor = customColor
        self.customIconSymbol = customIconSymbol
        self.paneMeta = paneMeta
        self.unreadCount = unreadCount
    }

    static func newPreset(_ preset: Provider) -> MailPane {
        let id = Int64(Date().timeIntervalSince1970 * 1000)
        let part = "persist:\(preset.rawValue)-\(id)"
        let url = preset.defaultURL?.absoluteString ?? ""
        let icon: String = switch preset {
        case .gmail: "simple-icons:gmail"
        case .outlook: "simple-icons:microsoftoutlook"
        case .icloud: "simple-icons:icloud"
        case .yahoo: "simple-icons:yahoo"
        case .custom: "mdi:email"
        }
        return MailPane(
            id: id,
            provider: preset.rawValue,
            partition: part,
            dataStoreId: UUID(),
            customName: nil,
            customColor: nil,
            customIconSymbol: nil,
            paneMeta: PaneMeta(name: preset.displayName, url: url, icon: icon),
            unreadCount: 0
        )
    }

    static func newCustom(name: String, url: String) -> MailPane {
        let id = Int64(Date().timeIntervalSince1970 * 1000)
        let part = "persist:custom-\(id)"
        return MailPane(
            id: id,
            provider: "custom",
            partition: part,
            dataStoreId: UUID(),
            customName: nil,
            customColor: nil,
            customIconSymbol: nil,
            paneMeta: PaneMeta(name: name, url: url, icon: "mdi:email"),
            unreadCount: 0
        )
    }
}

extension MailPane {
    enum CodingKeys: String, CodingKey {
        case id, provider, partition, dataStoreId, customName, customColor, customIconSymbol, paneMeta, unreadCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int64.self, forKey: .id)
        provider = try c.decode(String.self, forKey: .provider)
        partition = try c.decodeIfPresent(String.self, forKey: .partition) ?? "persist:\(provider)-\(id)"
        dataStoreId = try c.decodeIfPresent(UUID.self, forKey: .dataStoreId) ?? UUID()
        customName = try c.decodeIfPresent(String.self, forKey: .customName)
        customColor = try c.decodeIfPresent(String.self, forKey: .customColor)
        customIconSymbol = try c.decodeIfPresent(String.self, forKey: .customIconSymbol)
        paneMeta = try c.decodeIfPresent(PaneMeta.self, forKey: .paneMeta)
        unreadCount = try c.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(provider, forKey: .provider)
        try c.encode(partition, forKey: .partition)
        try c.encode(dataStoreId, forKey: .dataStoreId)
        try c.encodeIfPresent(customName, forKey: .customName)
        try c.encodeIfPresent(customColor, forKey: .customColor)
        try c.encodeIfPresent(customIconSymbol, forKey: .customIconSymbol)
        try c.encodeIfPresent(paneMeta, forKey: .paneMeta)
        try c.encode(unreadCount, forKey: .unreadCount)
    }
}
