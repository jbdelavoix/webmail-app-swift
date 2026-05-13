import SwiftUI
import WebKit

struct PaneWebView: NSViewRepresentable {
    let pane: MailPane
    /// Non-empty string sets `WKWebView.customUserAgent` for all navigations. Empty clears it (WebKit default).
    let userAgentOverride: String
    /// Only the active pane passes a non-negative counter; increment from the toolbar to reload in place.
    let reloadToken: Int

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore(forIdentifier: pane.dataStoreId)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        context.coordinator.userAgentOverride = userAgentOverride
        Self.applyUserAgent(webView, override: userAgentOverride)
        if let url = pane.resolvedURL() {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.userAgentOverride = userAgentOverride
        Self.applyUserAgent(webView, override: userAgentOverride)

        if reloadToken >= 0 {
            if let prev = context.coordinator.lastReloadToken {
                if reloadToken != prev {
                    webView.reload()
                }
            }
            context.coordinator.lastReloadToken = reloadToken
        }

        guard let want = pane.resolvedURL() else { return }
        if webView.url == nil || webView.url?.absoluteString != want.absoluteString {
            webView.load(URLRequest(url: want))
        }
    }

    static func resolvedUserAgent(override: String) -> String? {
        let trimmed = override.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func applyUserAgent(_ webView: WKWebView, override: String) {
        webView.customUserAgent = resolvedUserAgent(override: override)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var userAgentOverride: String = ""
        var lastReloadToken: Int?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            PaneWebView.applyUserAgent(webView, override: userAgentOverride)
            return .allow
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                guard let window = webView.window, window.isKeyWindow else { return }
                window.makeFirstResponder(webView)
            }
        }
    }
}
