import Combine
import Foundation

@MainActor
final class PaneStore: ObservableObject {
    @Published private(set) var panes: [MailPane] = []
    @Published var activePaneId: Int64?
    @Published var uiAppearance: String = "system" {
        didSet { savePrefs() }
    }
    @Published var customUserAgent: String = "" {
        didSet { savePrefs() }
    }
    /// `system` or a BCP-47 language code supported by the app (`en`, `fr`, …).
    @Published var appLanguage: String = "system" {
        didSet { savePrefs() }
    }
    /// Bumped from the toolbar reload control to reload the active `WKWebView` in place.
    @Published private(set) var webReloadNonce: Int = 0

    /// Bundle used for all UI strings (respects `appLanguage`).
    var stringsBundle: Bundle {
        WorkPaneStrings.bundle(for: appLanguage)
    }

    private let panesURL: URL
    private let prefsURL: URL

    private struct PrefsFile: Codable {
        var uiAppearance: String?
        var activePaneId: Int64?
        var customUserAgent: String?
        var appLanguage: String?
    }

    init() {
        let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let supportDir = applicationSupport.appendingPathComponent("WorkPane", isDirectory: true)
        try? FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        panesURL = supportDir.appendingPathComponent("panes.json")
        prefsURL = supportDir.appendingPathComponent("preferences.json")
        load()
    }

    func load() {
        if let data = try? Data(contentsOf: prefsURL),
           let p = try? JSONDecoder().decode(PrefsFile.self, from: data) {
            uiAppearance = p.uiAppearance ?? "system"
            activePaneId = p.activePaneId
            customUserAgent = p.customUserAgent ?? ""
            appLanguage = p.appLanguage ?? "system"
        }
        if let data = try? Data(contentsOf: panesURL) {
            panes = (try? JSONDecoder().decode([MailPane].self, from: data)) ?? []
        }
        if activePaneId == nil {
            activePaneId = panes.first?.id
        }
    }

    private func savePanes() {
        guard let data = try? JSONEncoder().encode(panes) else { return }
        try? data.write(to: panesURL, options: .atomic)
    }

    private func savePrefs() {
        let p = PrefsFile(
            uiAppearance: uiAppearance,
            activePaneId: activePaneId,
            customUserAgent: customUserAgent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : customUserAgent,
            appLanguage: appLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appLanguage == "system"
                ? nil
                : appLanguage
        )
        guard let data = try? JSONEncoder().encode(p) else { return }
        try? data.write(to: prefsURL, options: .atomic)
    }

    func save() {
        savePanes()
        savePrefs()
    }

    func addPreset(_ preset: MailPane.Provider) {
        guard preset != .custom else { return }
        var list = panes
        list.append(MailPane.newPreset(preset))
        panes = list
        activePaneId = list.last?.id
        save()
    }

    func addCustom(name: String, url: String) {
        var list = panes
        list.append(MailPane.newCustom(name: name, url: url))
        panes = list
        activePaneId = list.last?.id
        save()
    }

    func delete(_ id: Int64) {
        panes.removeAll { $0.id == id }
        if activePaneId == id {
            activePaneId = panes.first?.id
        }
        save()
    }

    func movePanes(from source: IndexSet, to destination: Int) {
        var list = panes
        list.move(fromOffsets: source, toOffset: destination)
        panes = list
        save()
    }

    func movePaneUp(id: Int64) {
        guard let i = panes.firstIndex(where: { $0.id == id }), i > 0 else { return }
        panes.swapAt(i, i - 1)
        save()
    }

    func movePaneDown(id: Int64) {
        guard let i = panes.firstIndex(where: { $0.id == id }), i < panes.count - 1 else { return }
        panes.swapAt(i, i + 1)
        save()
    }

    /// Clears when `symbol` is nil, empty, or not in `PaneIconChoices`.
    func setPaneSidebarIcon(id: Int64, symbol: String?) {
        guard let i = panes.firstIndex(where: { $0.id == id }) else { return }
        let t = symbol?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if t.isEmpty || !PaneIconChoices.isAllowed(t) {
            panes[i].customIconSymbol = nil
        } else {
            panes[i].customIconSymbol = t
        }
        save()
    }

    /// Persists `#RRGGBB` or clears when `hex` is nil/empty.
    func setPaneCustomColor(id: Int64, hex: String?) {
        guard let i = panes.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = hex?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty {
            panes[i].customColor = nil
        } else {
            var h = trimmed
            if !h.hasPrefix("#") { h = "#" + h }
            panes[i].customColor = h.uppercased()
        }
        save()
    }

    /// Sidebar label (optional); empty string clears the override.
    func setPaneSidebarName(id: Int64, raw: String) {
        guard let i = panes.firstIndex(where: { $0.id == id }) else { return }
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        panes[i].customName = t.isEmpty ? nil : t
        save()
    }

    /// Custom pane title (`paneMeta.name`).
    func setCustomPaneTitle(id: Int64, raw: String) {
        guard let i = panes.firstIndex(where: { $0.id == id }),
              panes[i].provider == "custom"
        else { return }
        var a = panes[i]
        let prev = a.paneMeta
            ?? MailPane.PaneMeta(
                name: "Custom",
                url: "",
                icon: "mdi:email"
            )
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = t.isEmpty ? prev.name : t
        a.paneMeta = MailPane.PaneMeta(name: name, url: prev.url, icon: prev.icon)
        panes[i] = a
        save()
    }

    /// Custom pane URL (`paneMeta.url`).
    func setCustomPaneURL(id: Int64, raw: String) {
        guard let i = panes.firstIndex(where: { $0.id == id }),
              panes[i].provider == "custom"
        else { return }
        var a = panes[i]
        let prev = a.paneMeta
            ?? MailPane.PaneMeta(
                name: "Custom",
                url: "",
                icon: "mdi:email"
            )
        let u = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        a.paneMeta = MailPane.PaneMeta(name: prev.name, url: u, icon: prev.icon)
        panes[i] = a
        save()
    }

    func select(_ id: Int64?) {
        activePaneId = id
        savePrefs()
    }

    func requestWebReload() {
        webReloadNonce += 1
    }
}
