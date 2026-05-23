import SwiftUI
import WebKit

final class WebViewStore: ObservableObject {
    let webView: WKWebView
    
    init() {
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
    }
    
    func isLoadingPage() -> Bool { return webView.isLoading }
}

extension WKWebView {
    func evaluateJavaScriptAsync(_ script: String) async -> Any? {
        await withCheckedContinuation { continuation in
            evaluateJavaScript(script) { result, error in
                continuation.resume(returning: result)
            }
        }
    }
}
