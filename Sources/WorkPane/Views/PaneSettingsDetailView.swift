import SwiftUI

/// Right column: edits persist immediately (no Save).
struct PaneSettingsDetailView: View {
    @EnvironmentObject private var store: PaneStore
    @Environment(\.colorScheme) private var colorScheme
    let paneId: Int64
    @State private var iconPickerPresented = false

    private var pane: MailPane? {
        store.panes.first { $0.id == paneId }
    }

    private var isDark: Bool {
        ThemeResolver.isDark(uiAppearance: store.uiAppearance, colorScheme: colorScheme)
    }

    var body: some View {
        Group {
            if let acc = pane {
                Form {
                    Section {
                        TextField(
                            String(localized: "pane.name_in_sidebar", bundle: store.stringsBundle),
                            text: sidebarNameBinding
                        )
                    } header: {
                        Text("pane.sidebar", bundle: store.stringsBundle)
                    } footer: {
                        Text("pane.sidebar_footer", bundle: store.stringsBundle)
                            .font(.caption)
                            .paneSettingsHelpText()
                    }

                    Section {
                        ColorPicker(
                            String(localized: "pane.icon_color", bundle: store.stringsBundle),
                            selection: swatchColorBinding,
                            supportsOpacity: false
                        )
                        Button {
                            store.setPaneCustomColor(id: paneId, hex: nil)
                        } label: {
                            Text("pane.use_default_color", bundle: store.stringsBundle)
                        }
                    } header: {
                        Text("pane.appearance", bundle: store.stringsBundle)
                    } footer: {
                        Text("pane.color_footer", bundle: store.stringsBundle)
                            .font(.caption)
                            .paneSettingsHelpText()
                    }

                    Section {
                        HStack(spacing: 16) {
                            Button {
                                iconPickerPresented = true
                            } label: {
                                PaneSwatchView(pane: acc, size: 56, cornerRadius: 12)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text("pane.icon_choose.accessibility", bundle: store.stringsBundle))
                            .help(Text("pane.icon_choose.help", bundle: store.stringsBundle))
                            .popover(isPresented: $iconPickerPresented) {
                                PaneIconPickerPopover(paneId: paneId, isPresented: $iconPickerPresented)
                                    .environmentObject(store)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)

                        Button {
                            store.setPaneSidebarIcon(id: paneId, symbol: nil)
                        } label: {
                            Text("pane.use_default_icon", bundle: store.stringsBundle)
                        }
                        .disabled(store.panes.first { $0.id == paneId }?.customIconSymbol == nil)
                    } header: {
                        Text("pane.icon_section", bundle: store.stringsBundle)
                    } footer: {
                        Text("pane.icon_footer", bundle: store.stringsBundle)
                            .font(.caption)
                            .paneSettingsHelpText()
                    }

                    if acc.provider == "custom" {
                        Section {
                            TextField(
                                String(localized: "pane.title_field", bundle: store.stringsBundle),
                                text: customTitleBinding
                            )
                            TextField(
                                String(localized: "pane.url_field", bundle: store.stringsBundle),
                                text: customURLBinding
                            )
                            .textContentType(.URL)
                        } header: {
                            Text("pane.custom_pane", bundle: store.stringsBundle)
                        } footer: {
                            Text("pane.custom_footer", bundle: store.stringsBundle)
                                .font(.caption)
                                .paneSettingsHelpText()
                        }
                    } else {
                        Section {
                            LabeledContent {
                                Text(verbatim: presetLabel(acc.provider))
                                    .foregroundStyle(.secondary)
                            } label: {
                                Label {
                                    Text("pane.service", bundle: store.stringsBundle)
                                } icon: {
                                    Image(systemName: acc.resolvedIconSymbolName)
                                }
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            store.delete(paneId)
                        } label: {
                            Text("pane.remove", bundle: store.stringsBundle)
                        }
                    }
                }
                .formStyle(.grouped)
                .onChange(of: paneId) { _, _ in
                    iconPickerPresented = false
                }
            } else {
                ContentUnavailableView(
                    String(localized: "pane.removed", bundle: store.stringsBundle),
                    systemImage: "trash"
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func presetLabel(_ provider: String) -> String {
        MailPane.Provider(rawValue: provider)?.displayName ?? provider
    }

    private var sidebarNameBinding: Binding<String> {
        Binding(
            get: { store.panes.first { $0.id == paneId }?.customName ?? "" },
            set: { store.setPaneSidebarName(id: paneId, raw: $0) }
        )
    }

    private var customTitleBinding: Binding<String> {
        Binding(
            get: { store.panes.first { $0.id == paneId }?.paneMeta?.name ?? "" },
            set: { store.setCustomPaneTitle(id: paneId, raw: $0) }
        )
    }

    private var customURLBinding: Binding<String> {
        Binding(
            get: { store.panes.first { $0.id == paneId }?.paneMeta?.url ?? "" },
            set: { store.setCustomPaneURL(id: paneId, raw: $0) }
        )
    }

    private var swatchColorBinding: Binding<Color> {
        Binding(
            get: {
                guard let acc = store.panes.first(where: { $0.id == paneId }) else {
                    return .gray
                }
                return WorkPaneTheme.resolvedSwatchColor(pane: acc, isDark: isDark)
            },
            set: { newValue in
                if let hex = newValue.toHexRGBString() {
                    store.setPaneCustomColor(id: paneId, hex: hex)
                }
            }
        )
    }
}

private struct PaneIconPickerPopover: View {
    @EnvironmentObject private var store: PaneStore
    let paneId: Int64
    @Binding var isPresented: Bool

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(40), spacing: 6), count: 4),
                spacing: 6
            ) {
                ForEach(PaneIconChoices.all, id: \.self) { sym in
                    let current = store.panes.first { $0.id == paneId }?.customIconSymbol
                    let isSelected = current == sym
                    Button {
                        store.setPaneSidebarIcon(id: paneId, symbol: sym)
                        isPresented = false
                    } label: {
                        Image(systemName: sym)
                            .font(.system(size: 17, weight: .medium))
                            .symbolRenderingMode(.monochrome)
                            .frame(width: 40, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.05))
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        }
        .frame(width: 218, height: 340)
    }
}
