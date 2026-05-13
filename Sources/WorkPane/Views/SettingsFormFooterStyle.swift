import SwiftUI

extension View {
    /// Form section footers on macOS can wrap at odd widths; keep help text one readable block.
    func paneSettingsHelpText() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}
