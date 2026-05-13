import SwiftUI

/// Colored pane icon (only custom styling we keep outside system chrome).
struct PaneSwatchView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: PaneStore

    let pane: MailPane
    var size: CGFloat = 38
    var cornerRadius: CGFloat = 10

    private var isDark: Bool {
        ThemeResolver.isDark(uiAppearance: store.uiAppearance, colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(WorkPaneTheme.resolvedSwatchColor(pane: pane, isDark: isDark))
                .frame(width: size, height: size)
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(isDark ? 0.12 : 0.22), lineWidth: 1)
                }
                .shadow(color: .black.opacity(isDark ? 0.28 : 0.1), radius: 2, y: 1)

            Image(systemName: pane.resolvedIconSymbolName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 0, y: 1)
        }
        .accessibilityHidden(true)
    }
}
