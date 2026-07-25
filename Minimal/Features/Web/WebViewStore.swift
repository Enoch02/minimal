import Combine
import SwiftUI
import WebKit

struct WebError: Identifiable, Equatable {
	let id = UUID()
	let code: Int
	let domain: String
	let description: String
	let failingURL: String?

	static func == (lhs: WebError, rhs: WebError) -> Bool {
		lhs.id == rhs.id
	}
}

final class WebViewStore: ObservableObject {
	@Published var isLoading = false
	@Published var estimatedProgress: Double = 0
	@Published var currentURL: String
	@Published var title: String = ""
	@Published var error: WebError?

	let webView: WKWebView
	let isIncognito: Bool
	private var observers: [NSKeyValueObservation] = []
	private var lastRecordedURL: String?
	
	init(startupURL: String, isIncognito: Bool = false) {
		self.isIncognito = isIncognito
		currentURL = startupURL
		let configuration = WKWebViewConfiguration()
		if isIncognito {
			configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
		}
		webView = WKWebView(frame: .zero, configuration: configuration)
		
		setupObservers()
		
		if !startupURL.isEmpty, let url = URL(string: startupURL) {
			webView.load(URLRequest(url: url))
		}
	}
	
	func loadURL(_ urlString: String) {
		let formatted = urlString.hasPrefix("http")
			? urlString
			: "https://\(urlString)"
		guard let url = URL(string: formatted) else { return }
		webView.load(URLRequest(url: url))
	}
	
	private func setupObservers() {
		let loadingObserver = webView.observe(
			\.isLoading,
			 options: [.initial, .new],
			 changeHandler: { [weak self] webView, _ in
				 // schedule to run later on the main thread
				 DispatchQueue.main.async {
					 self?.isLoading = webView.isLoading
				 }
			 }
		)
		
		let progressObserver = webView.observe(
			\.estimatedProgress,
			 options: [.initial, .new],
			 changeHandler: { [weak self] webview, _ in
				 DispatchQueue.main.async {
					 self?.estimatedProgress = webview.estimatedProgress
				 }
			 }
		)
		
		let currentURLObserver = webView.observe(
			\.url,
			 options: [.initial, .new],
			 changeHandler: { [weak self] webview, _ in
				 DispatchQueue.main.async {
					 let urlString = webview.url?.absoluteString ?? ""
					 self?.currentURL = urlString

					 guard
						 let self,
						 !urlString.isEmpty,
						 urlString != self.lastRecordedURL,
						 !self.isIncognito
					 else { return }

					 self.lastRecordedURL = urlString
					 HistoryManager.shared.addVisit(
						url: urlString,
						title: webview.title ?? ""
					 )
				 }
			 }
		)
		
		let titleObserver = webView.observe(
			\.title,
			 options: [.initial, .new],
			 changeHandler: { [weak self] webview, _ in
				 DispatchQueue.main.async {
					 self?.title = webview.title ?? ""
				 }
			 }
		)
		
		observers = [
			loadingObserver,
			progressObserver,
			currentURLObserver,
			titleObserver,
		]
	}
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
