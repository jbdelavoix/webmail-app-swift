import AppKit
import SwiftUI

/// Main window: standard `NavigationSplitView` (sidebar + detail), system chrome and materials only.
struct ContentView: View {
    @EnvironmentObject private var store: PaneStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                // Fixed width: a wide min…max range lets new windows open with a different default than the first.
                .navigationSplitViewColumnWidth(min: 92, ideal: 92, max: 92)
        } detail: {
            detail
                .frame(minWidth: 360)
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("")
        .background(TitleSuppression())
        .toolbar {
            if !store.panes.isEmpty {
                ToolbarItem(placement: .navigation) {
                    Button {
                        store.requestWebReload()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(String(localized: "toolbar.reload.help", bundle: store.stringsBundle))
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            DispatchQueue.main.async {
                NSApp.unhide(nil)
                if let w = NSApp.keyWindow ?? NSApp.mainWindow {
                    w.makeKeyAndOrderFront(nil)
                } else if let w = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
                    w.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    private var sidebar: some View {
        ZStack(alignment: .top) {
            List(selection: Binding(
                get: { store.activePaneId },
                set: { store.select($0) }
            )) {
                ForEach(store.panes) { acc in
                    PaneRowView(pane: acc)
                        .tag(Optional(acc.id))
                        .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                }
                .onDelete { indices in
                    let ids = indices.map { store.panes[$0].id }
                    ids.forEach(store.delete)
                }
            }
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)
            .toolbar(removing: .sidebarToggle)

            SidebarTopScrollBlur()
                .frame(height: SidebarTopChrome.totalBlurHeight)
                .frame(maxWidth: .infinity)
                .offset(y: -SidebarTopChrome.overlapIntoTitlebar)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if store.panes.isEmpty {
            ContentUnavailableView(
                String(localized: "empty.no_panes", bundle: store.stringsBundle),
                systemImage: "envelope",
                description: Text("empty.no_panes.detail", bundle: store.stringsBundle)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            let activeId = store.activePaneId ?? store.panes.first?.id
            ZStack {
                ForEach(store.panes) { acc in
                    let isActive = activeId == acc.id
                    PaneWebView(
                        pane: acc,
                        userAgentOverride: store.customUserAgent,
                        reloadToken: isActive ? store.webReloadNonce : -1
                    )
                    .id(acc.id)
                    .opacity(isActive ? 1 : 0)
                    .allowsHitTesting(isActive)
                    .accessibilityHidden(!isActive)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Lifts the vibrancy strip into the unified title bar; keeps a band over the first list rows for scrolling content.
private enum SidebarTopChrome {
    /// Keeps vibrancy under the unified title bar / traffic lights.
    static let overlapIntoTitlebar: CGFloat = 44
    /// Band over the list only — keep small so the frosted strip does not reach too far down the rows.
    static let overListHeight: CGFloat = 22
    static var totalBlurHeight: CGFloat { overlapIntoTitlebar + overListHeight }
}

/// Native sidebar vibrancy over scrolling rows under the window controls (SwiftUI `Material` does not match AppKit here).
private struct SidebarTopScrollBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> SidebarTopEffectContainer {
        SidebarTopEffectContainer()
    }

    func updateNSView(_ nsView: SidebarTopEffectContainer, context: Context) {}
}

private final class SidebarTopEffectContainer: NSView {
    private let effect = NSVisualEffectView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        effect.material = .sidebar
        effect.blendingMode = .withinWindow
        effect.state = .followsWindowActiveState
        effect.isEmphasized = true
        effect.wantsLayer = true
        addSubview(effect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        effect.material = .sidebar
        effect.blendingMode = .withinWindow
        effect.state = .followsWindowActiveState
        effect.isEmphasized = true
        effect.wantsLayer = true
        addSubview(effect)
    }

    override func layout() {
        super.layout()
        effect.frame = bounds
        updateFadeMask()
    }

    private func updateFadeMask() {
        guard bounds.height > 1 else { return }
        guard let layer = effect.layer else { return }
        let m = CAGradientLayer()
        m.frame = layer.bounds
        m.colors = [
            NSColor.white.cgColor,
            NSColor.white.cgColor,
            NSColor.clear.cgColor,
        ]
        m.locations = [0, 0.45, 1]
        m.startPoint = CGPoint(x: 0.5, y: 1)
        m.endPoint = CGPoint(x: 0.5, y: 0)
        layer.mask = m
    }
}

// Hides the default window title so the toolbar refresh control sits in a clean title bar.
private struct TitleSuppression: NSViewRepresentable {
    func makeNSView(context: Context) -> TitleSyncView {
        let v = TitleSyncView()
        v.sync()
        return v
    }

    func updateNSView(_ nsView: TitleSyncView, context: Context) {
        nsView.sync()
    }

    fileprivate final class TitleSyncView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            sync()
            DispatchQueue.main.async { [weak self] in
                self?.sync()
            }
        }

        override func layout() {
            super.layout()
            sync()
        }

        func sync() {
            guard let win = window else { return }
            win.representedURL = nil
            win.title = ""
            win.subtitle = ""
            win.titleVisibility = .hidden
        }
    }
}
