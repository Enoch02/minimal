import Combine
import SwiftUI
import WebKit

final class WebViewStore: ObservableObject {
	@Published var isLoading = false
	@Published var estimatedProgress: Double = 0
	@Published var currentURL: String
	
	let webView: WKWebView
	private var observers: [NSKeyValueObservation] = []
	
	init(startupURL: String) {
		currentURL = startupURL
		let configuration = WKWebViewConfiguration()
		webView = WKWebView(frame: .zero, configuration: configuration)
		
		setupObservers()
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
		
		observers = [loadingObserver, progressObserver, currentURLObserver]
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
