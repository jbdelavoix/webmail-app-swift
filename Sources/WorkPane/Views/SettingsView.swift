import AppKit
import SwiftUI

private enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case panes

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .general: return "gearshape"
        case .panes: return "person.crop.rectangle.stack"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: PaneStore
    @State private var tab: SettingsTab = .general
    /// Selection in the panes split view (independent from main window `activePaneId`).
    @State private var settingsPaneSelection: Int64?

    var body: some View {
        TabView(selection: $tab) {
            generalTab
                .tabItem {
                    Label {
                        Text("settings.tab.general", bundle: store.stringsBundle)
                    } icon: {
                        Image(systemName: SettingsTab.general.systemImage)
                    }
                }
                .tag(SettingsTab.general)

            panesTab
                .tabItem {
                    Label {
                        Text("settings.tab.panes", bundle: store.stringsBundle)
                    } icon: {
                        Image(systemName: SettingsTab.panes.systemImage)
                    }
                }
                .tag(SettingsTab.panes)
        }
        .tabViewStyle(.automatic)
        .frame(minWidth: 640, minHeight: 460)
        .preferredColorScheme(Self.preferredScheme(for: store.uiAppearance))
    }

    private var generalTab: some View {
        Form {
            Section {
                Picker(selection: $store.uiAppearance) {
                    Text("settings.theme.system", bundle: store.stringsBundle).tag("system")
                    Text("settings.theme.light", bundle: store.stringsBundle).tag("light")
                    Text("settings.theme.dark", bundle: store.stringsBundle).tag("dark")
                } label: {
                    Text("settings.theme", bundle: store.stringsBundle)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("settings.section.appearance", bundle: store.stringsBundle)
            }

            Section {
                Picker(selection: $store.appLanguage) {
                    Text("language.option.system", bundle: store.stringsBundle).tag("system")
                    Text(verbatim: "English").tag("en")
                    Text(verbatim: "Français").tag("fr")
                    Text(verbatim: "Deutsch").tag("de")
                    Text(verbatim: "Español").tag("es")
                    Text(verbatim: "Italiano").tag("it")
                } label: {
                    Text("settings.language", bundle: store.stringsBundle)
                }
            } header: {
                Text("settings.section.language", bundle: store.stringsBundle)
            } footer: {
                Text("language.footer", bundle: store.stringsBundle)
                    .font(.caption)
                    .paneSettingsHelpText()
            }

            Section {
                TextField(
                    String(localized: "settings.ua.placeholder", bundle: store.stringsBundle),
                    text: $store.customUserAgent,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...8)
                .font(.system(.caption, design: .monospaced))
                Button {
                    store.customUserAgent = ""
                } label: {
                    Text("settings.ua.reset", bundle: store.stringsBundle)
                }
                .disabled(store.customUserAgent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("settings.ua.header", bundle: store.stringsBundle)
            } footer: {
                Text("settings.ua.footer", bundle: store.stringsBundle)
                    .font(.caption)
                    .paneSettingsHelpText()
            }
        }
        .formStyle(.grouped)
    }

    private var panesTab: some View {
        PanesEditorSplitView(selection: $settingsPaneSelection)
            .onAppear {
                syncSelectionWithPanes()
            }
            .onChange(of: store.panes.map(\.id)) { _, _ in
                syncSelectionWithPanes()
            }
    }

    private func syncSelectionWithPanes() {
        if store.panes.isEmpty {
            settingsPaneSelection = nil
            return
        }
        if settingsPaneSelection == nil
            || !store.panes.contains(where: { $0.id == settingsPaneSelection }) {
            settingsPaneSelection = store.panes.first?.id
        }
    }
}

/// Two-pane editor: plain list + thin system separator (no `HSplitView` grabber).
private struct PanesEditorSplitView: View {
    @EnvironmentObject private var store: PaneStore
    @Binding var selection: Int64?
    @State private var showCustomSheet = false
    @State private var sheetCustomName = ""
    @State private var sheetCustomURL = ""

    var body: some View {
        HStack(spacing: 0) {
            listColumn
                .frame(minWidth: 200, idealWidth: 248, maxWidth: 320)

            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            detailColumn
                .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var listColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("settings.panes", bundle: store.stringsBundle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("settings.panes.hint", bundle: store.stringsBundle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .paneSettingsHelpText()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity, alignment: .leading)

            List(selection: $selection) {
                ForEach(store.panes) { acc in
                    PaneListRow(pane: acc)
                        .tag(acc.id)
                        .listRowSeparator(.hidden)
                        .contextMenu {
                            Button {
                                store.movePaneUp(id: acc.id)
                            } label: {
                                Label {
                                    Text("pane.move_up", bundle: store.stringsBundle)
                                } icon: {
                                    Image(systemName: "arrow.up")
                                }
                            }
                            .disabled(store.panes.first?.id == acc.id)
                            Button {
                                store.movePaneDown(id: acc.id)
                            } label: {
                                Label {
                                    Text("pane.move_down", bundle: store.stringsBundle)
                                } icon: {
                                    Image(systemName: "arrow.down")
                                }
                            }
                            .disabled(store.panes.last?.id == acc.id)
                            Divider()
                            Button(role: .destructive) {
                                store.delete(acc.id)
                            } label: {
                                Label {
                                    Text("pane.remove", bundle: store.stringsBundle)
                                } icon: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                }
                .onMove { source, destination in
                    store.movePanes(from: source, to: destination)
                }
            }
            .listStyle(.plain)

            Divider()

            addPaneToolbar
        }
    }

    private var addPaneToolbar: some View {
        HStack {
            Menu {
                ForEach(MailPane.Provider.allCases.filter { $0 != .custom }, id: \.self) { p in
                    Button {
                        store.addPreset(p)
                        selection = store.panes.last?.id
                    } label: {
                        Label {
                            Text(verbatim: p.displayName)
                        } icon: {
                            Image(systemName: p.symbolName)
                        }
                    }
                }
                Divider()
                Button {
                    sheetCustomName = ""
                    sheetCustomURL = ""
                    showCustomSheet = true
                } label: {
                    Label {
                        Text("pane.custom_ellipsis", bundle: store.stringsBundle)
                    } icon: {
                        Image(systemName: "link.badge.plus")
                    }
                }
            } label: {
                Label {
                    Text("pane.add", bundle: store.stringsBundle)
                } icon: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .sheet(isPresented: $showCustomSheet) {
            addCustomPaneSheet
        }
    }

    private var addCustomPaneSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "sheet.field.display_name", bundle: store.stringsBundle),
                        text: $sheetCustomName
                    )
                    TextField(
                        String(localized: "sheet.field.url_placeholder", bundle: store.stringsBundle),
                        text: $sheetCustomURL
                    )
                    .textContentType(.URL)
                } header: {
                    Text("sheet.section.custom_pane", bundle: store.stringsBundle)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(String(localized: "sheet.add_custom_pane", bundle: store.stringsBundle))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showCustomSheet = false
                    } label: {
                        Text("action.cancel", bundle: store.stringsBundle)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let name = sheetCustomName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let url = sheetCustomURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !url.isEmpty else { return }
                        store.addCustom(
                            name: name.isEmpty ? "Custom" : name,
                            url: url
                        )
                        selection = store.panes.last?.id
                        showCustomSheet = false
                    } label: {
                        Text("action.add", bundle: store.stringsBundle)
                    }
                    .disabled(sheetCustomURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .frame(minWidth: 420, minHeight: 200)
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        if store.panes.isEmpty {
            ContentUnavailableView(
                String(localized: "empty.no_panes", bundle: store.stringsBundle),
                systemImage: "tray",
                description: Text("empty.no_panes.settings_detail", bundle: store.stringsBundle)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let id = selection, store.panes.contains(where: { $0.id == id }) {
            PaneSettingsDetailView(paneId: id)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            ContentUnavailableView(
                String(localized: "empty.choose_pane", bundle: store.stringsBundle),
                systemImage: "envelope.open",
                description: Text("empty.choose_pane.detail", bundle: store.stringsBundle)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Settings list column: full title + host (wider list than main window).
private struct PaneListRow: View {
    @EnvironmentObject private var store: PaneStore
    let pane: MailPane

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            PaneSwatchView(pane: pane, size: 32, cornerRadius: 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(pane.sidebarTitle(stringsBundle: store.stringsBundle))
                    .font(.body)
                    .lineLimit(1)
                if let u = pane.resolvedURL() {
                    Text(u.host ?? u.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

extension SettingsView {
    static func preferredScheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
