import SwiftUI

struct BrowserView: View {
	@StateObject private var webViewStore = WebViewStore()
	@StateObject private var downloadManager = DownloadManager()
	@State private var showDownloads = false
	
	private let placement: ToolbarItemPlacement = .automatic
	
	var body: some View {
		VStack(spacing: 0) {
			if webViewStore.isLoading {
				ProgressView(value: webViewStore.estimatedProgress)
				//					.progressViewStyle(.linear)
			}
			HStack {
				TextField("Enter URL", text: $webViewStore.currentURL)
					.textFieldStyle(.roundedBorder)
					.submitLabel(.go)
					.onSubmit {
						onURLSubmit()
					}
				
				Button("Go") {
					onURLSubmit()
				}
			}
			.padding()
			
			WebView(webView: webViewStore.webView, url: webViewStore.currentURL, downloadManager: downloadManager)
		}
		.frame(minWidth: 1000, minHeight: 700)
		.toolbar(
			content: {
				ToolbarItem(placement: placement) {
					Button("Back", systemImage: "arrowshape.backward") {
						if webViewStore.webView.canGoBack {
							webViewStore.webView.goBack()
						}
					}
				}
				
				ToolbarItem(placement: placement) {
					Button("Forward", systemImage: "arrowshape.forward") {
						if webViewStore.webView.canGoForward {
							webViewStore.webView.goForward()
						}
					}
				}
				
				ToolbarItem(placement: placement) {
					Button("Refresh", systemImage: "arrow.clockwise") {
						webViewStore.webView.reload()
					}
				}
				
				ToolbarItem(placement: placement) {
					Button {
						showDownloads.toggle()
					} label: {
						Label("Downloads", systemImage: "arrow.down.circle")
					}
				}
			}
		)
		.sheet(isPresented: $showDownloads) {
			DownloadsListView(manager: downloadManager)
		}
	}
	
	private func onURLSubmit() {
//		NotificationCenter.default.post(name: .loadURL, object: urlString)
		NotificationCenter.default.post(name: .loadURL, object: webViewStore.currentURL)
	}
}

#Preview {
	BrowserView()
}
