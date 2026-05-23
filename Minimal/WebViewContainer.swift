import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let webView: WKWebView
    @ObservedObject var downloadManager: DownloadManager
    
    func makeCoordinator() -> Coordinator {
        Coordinator(downloadManager: downloadManager)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: "https://example.com") {
            webView.load(URLRequest(url: url))
        }
        
        NotificationCenter.default.addObserver(forName: .loadURL, object: nil, queue: .main) { notification in
            guard let value = notification.object as? String else { return }
            let formatted = value.hasPrefix("http") ? value : "https://\(value)"
            guard let url = URL(string: formatted) else { return }
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    final class Coordinator: NSObject, WKNavigationDelegate {
        let downloadManager: DownloadManager
        
        init(downloadManager: DownloadManager) {
            self.downloadManager = downloadManager
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            let response = navigationResponse.response
            
            if !navigationResponse.canShowMIMEType {
                guard let url = response.url else {
                    decisionHandler(.cancel)
                    return
                }
                
                Task {
                    await sendToAria2(webView: webView, downloadURL: url)
                }
                
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func sendToAria2(webView: WKWebView, downloadURL: URL) async {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            let cookiesList = await getCookies(from: cookieStore, for: downloadURL)
            let cookieHeader = cookiesList.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            
            let userAgent = await webView.evaluateJavaScriptAsync("navigator.userAgent") as? String ?? ""
            let referer = webView.url?.absoluteString ?? ""
            
            downloadManager.addDownload(url: downloadURL, cookies: cookieHeader, userAgent: userAgent, referer: referer)
        }
        
        func getCookies(from store: WKHTTPCookieStore, for url: URL) async -> [HTTPCookie] {
            await withCheckedContinuation { continuation in
                store.getAllCookies { cookies in
                    let filtered = cookies.filter {
                        guard let domain = url.host else { return false }
                        return domain.hasSuffix($0.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")))
                    }
                    continuation.resume(returning: filtered)
                }
            }
        }
    }
}

extension Notification.Name {
    static let loadURL = Notification.Name("loadURL")
}
