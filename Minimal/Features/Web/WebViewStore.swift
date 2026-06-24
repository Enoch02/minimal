import Combine
import SwiftUI
import WebKit

final class WebViewStore: ObservableObject {
	@Published var isLoading = false
	@Published var estimatedProgress: Double = 0
	@Published var currentURL: String
	@Published var title: String = ""
	
	let webView: WKWebView
	private var observers: [NSKeyValueObservation] = []
	
	init(startupURL: String) {
		currentURL = startupURL
		let configuration = WKWebViewConfiguration()
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
					 self?.currentURL = webview.url?.absoluteString ?? ""
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
