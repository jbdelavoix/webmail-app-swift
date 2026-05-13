import AppKit
import SwiftUI

@main
struct WorkPaneApp: App {
    @NSApplicationDelegateAdaptor(WorkPaneAppDelegate.self) private var appDelegate
    @StateObject private var store = PaneStore()

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, Self.locale(for: store.appLanguage))
                .preferredColorScheme(colorScheme(for: store.uiAppearance))
        }
        .commands {
            CommandGroup(replacing: .sidebar) {}
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environmentObject(store)
                .environment(\.locale, Self.locale(for: store.appLanguage))
        }
    }

    private func colorScheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private static func locale(for appLanguage: String) -> Locale {
        let c = appLanguage.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if c.isEmpty || c == "system" { return Locale.current }
        return Locale(identifier: c)
    }
}
