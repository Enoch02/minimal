import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
	let webView: WKWebView

	@ObservedObject var webViewStore: WebViewStore
	@ObservedObject var downloadManager: DownloadManager
	var onNewTabRequested: ((URL) -> Void)?

	func makeCoordinator() -> Coordinator {
		Coordinator(
			webViewStore: webViewStore,
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
		let webViewStore: WebViewStore
		let downloadManager: DownloadManager
		let onNewTabRequested: ((URL) -> Void)?

		init(
			webViewStore: WebViewStore,
			downloadManager: DownloadManager,
			onNewTabRequested: ((URL) -> Void)?
		) {
			self.webViewStore = webViewStore
			self.downloadManager = downloadManager
			self.onNewTabRequested = onNewTabRequested
		}

		// MARK: - WKNavigationDelegate

		func webView(
			_ webView: WKWebView,
			didStartProvisionalNavigation navigation: WKNavigation!
		) {
			DispatchQueue.main.async {
				self.webViewStore.error = nil
			}
		}

		func webView(
			_ webView: WKWebView,
			didFailProvisionalNavigation navigation: WKNavigation!,
			withError error: Error
		) {
			handleError(error, webView: webView)
		}

		func webView(
			_ webView: WKWebView,
			didFail navigation: WKNavigation!,
			withError error: Error
		) {
			handleError(error, webView: webView)
		}

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

				DispatchQueue.main.async {
					self.webViewStore.error = nil
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

		// MARK: - Error Handling

		private func handleError(_ error: Error, webView: WKWebView) {
			let nsError = error as NSError

			guard nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled else {
				return
			}

			guard nsError.domain != "WebKitErrorDomain" || nsError.code != 102 else {
				return
			}

			guard nsError.domain != WKErrorDomain || !(1...2).contains(nsError.code) else {
				return
			}

			DispatchQueue.main.async {
				self.webViewStore.error = WebError(
					code: nsError.code,
					domain: nsError.domain,
					description: self.friendlyDescription(for: nsError),
					failingURL: (nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)
						?? webView.url?.absoluteString
				)
			}
		}

		private func friendlyDescription(for error: NSError) -> String {
			if error.domain == NSURLErrorDomain {
				switch error.code {
				case NSURLErrorNotConnectedToInternet:
					return "No internet connection"
				case NSURLErrorTimedOut:
					return "The connection timed out"
				case NSURLErrorCannotFindHost:
					return "Server not found"
				case NSURLErrorCannotConnectToHost:
					return "Cannot connect to server"
				case NSURLErrorDNSLookupFailed:
					return "DNS lookup failed"
				case NSURLErrorBadURL:
					return "Invalid URL"
				case NSURLErrorUnsupportedURL:
					return "Unsupported URL scheme"
				case NSURLErrorServerCertificateUntrusted:
					return "Server certificate is untrusted"
				case NSURLErrorServerCertificateHasBadDate:
					return "Server certificate is expired"
				case NSURLErrorServerCertificateNotYetValid:
					return "Server certificate is not yet valid"
				case NSURLErrorCannotLoadFromNetwork:
					return "Cannot load resource from network"
				case NSURLErrorSecureConnectionFailed:
					return "Secure connection failed"
				case NSURLErrorAppTransportSecurityRequiresSecureConnection:
					return "App Transport Security blocked a cleartext connection"
				default:
					break
				}
			}
			return error.localizedDescription
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
