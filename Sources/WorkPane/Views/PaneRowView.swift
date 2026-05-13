import SwiftUI

/// Main window: swatch + truncated title (narrow column).
struct PaneRowView: View {
    @EnvironmentObject private var store: PaneStore
    let pane: MailPane
    /// Max characters for the title (ellipsis if longer).
    var maxTitleLength: Int = 11

    var body: some View {
        VStack(spacing: 5) {
            PaneSwatchView(pane: pane, size: 30, cornerRadius: 7)
            Text(pane.sidebarTitleTruncated(maxLength: maxTitleLength, stringsBundle: store.stringsBundle))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pane.sidebarTitle(stringsBundle: store.stringsBundle))
        .help(pane.sidebarTitle(stringsBundle: store.stringsBundle))
    }
}

extension MailPane {
    var providerSymbolName: String {
        switch provider {
        case "gmail": return "envelope.fill"
        case "outlook": return "building.2.fill"
        case "icloud": return "icloud.fill"
        case "yahoo": return "envelope.circle.fill"
        case "custom": return "link.circle.fill"
        default: return "envelope.fill"
        }
    }
}

extension MailPane.Provider {
    var symbolName: String {
        switch self {
        case .gmail: return "envelope.fill"
        case .outlook: return "building.2.fill"
        case .icloud: return "icloud.fill"
        case .yahoo: return "envelope.circle.fill"
        case .custom: return "link.circle.fill"
        }
    }
}
