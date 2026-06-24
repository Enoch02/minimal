import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
	let webView: WKWebView

	@ObservedObject var downloadManager: DownloadManager
	var onNewTabRequested: ((URL) -> Void)?

	func makeCoordinator() -> Coordinator {
		Coordinator(
			downloadManager: downloadManager,
			onNewTabRequested: onNewTabRequested
		)
	}

	func makeNSView(context: Context) -> WKWebView {
		webView.navigationDelegate = context.coordinator
		webView.uiDelegate = context.coordinator
		return webView
	}

	func updateNSView(_ nsView: WKWebView, context: Context) {}

	final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
		let downloadManager: DownloadManager
		let onNewTabRequested: ((URL) -> Void)?

		init(
			downloadManager: DownloadManager,
			onNewTabRequested: ((URL) -> Void)?
		) {
			self.downloadManager = downloadManager
			self.onNewTabRequested = onNewTabRequested
		}

		// MARK: - WKNavigationDelegate

		func webView(
			_ webView: WKWebView,
			decidePolicyFor navigationResponse: WKNavigationResponse,
			decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
		) {
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

		// MARK: - WKUIDelegate (target="_blank" / ⌘-click)
		// TODO: this is not working!
		func webView(
			_ webView: WKWebView,
			createWebViewWith configuration: WKWebViewConfiguration,
			for navigationAction: WKNavigationAction,
			windowFeatures: WKWindowFeatures
		) -> WKWebView? {
			if let url = navigationAction.request.url {
				onNewTabRequested?(url)
			}
			return nil
		}

		// MARK: - Download Handoff

		func sendToAria2(webView: WKWebView, downloadURL: URL) async {
			let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
			let cookiesList = await getCookies(from: cookieStore, for: downloadURL)
			let cookieHeader = cookiesList.map {
				"\($0.name)=\($0.value)"
			}.joined(separator: "; ")

			let userAgent = await webView.evaluateJavaScriptAsync(
				"navigator.userAgent"
			) as? String ?? ""
			let referer = webView.url?.absoluteString ?? ""

			downloadManager.addDownload(
				url: downloadURL,
				cookies: cookieHeader,
				userAgent: userAgent,
				referer: referer
			)
		}

		func getCookies(
			from store: WKHTTPCookieStore,
			for url: URL
		) async -> [HTTPCookie] {
			await withCheckedContinuation { continuation in
				store.getAllCookies { cookies in
					let filtered = cookies.filter {
						guard let domain = url.host else { return false }
						return domain.hasSuffix(
							$0.domain.trimmingCharacters(
								in: CharacterSet(charactersIn: ".")
							)
						)
					}
					continuation.resume(returning: filtered)
				}
			}
		}
	}
}
