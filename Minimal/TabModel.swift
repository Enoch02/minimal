import Foundation

final class TabModel: Identifiable {
	let id = UUID()
	let webViewStore: WebViewStore

	init(url: String = "") {
		webViewStore = WebViewStore(startupURL: url)
	}
}
