import Foundation

final class TabModel: Identifiable {
	let id = UUID()
	let webViewStore: WebViewStore
	let isIncognito: Bool

	init(url: String = "", isIncognito: Bool = false) {
		self.isIncognito = isIncognito
		webViewStore = WebViewStore(startupURL: url, isIncognito: isIncognito)
	}
}
