import SwiftUI

struct BrowserView: View {
	@StateObject private var tabManager: TabManager
	@StateObject private var downloadManager = DownloadManager()
	@State private var showDownloads = false
	@State private var showHistory = false
	
	init(startupURL: String) {
		_tabManager = StateObject(
			wrappedValue: TabManager(startupURL: startupURL)
		)
	}
	
	var body: some View {
		HStack(spacing: 0) {
			if showHistory {
				HistorySidebarView { url in
					tabManager.selectedTab.webViewStore.loadURL(url)
					showHistory = false
				}
				
				Divider()
			}
			
			VStack(spacing: 0) {
				TabBarView(tabManager: tabManager)
				
				Divider()
				
				ActiveTabContentView(
					webViewStore: tabManager.selectedTab.webViewStore,
					downloadManager: downloadManager,
					showDownloads: $showDownloads,
					showHistory: $showHistory,
					onNewTabRequested: { url in
						tabManager.addTab(url: url.absoluteString)
					}
				)
				.id(tabManager.selectedTabID)
			}
		}
		.frame(minWidth: 1000, minHeight: 700)
		.focusedValue(\.tabManager, tabManager)
		.background(
			Button("") {
				showHistory.toggle()
			}
			.keyboardShortcut("y", modifiers: .command)
			.hidden()
		)
	}
}

// MARK: - Per-Tab Content

/// Extracted so that `@ObservedObject` properly subscribes to
/// the selected tab's `WebViewStore` and re-renders when its
/// `isLoading`, `estimatedProgress`, or `currentURL` change.
private struct ActiveTabContentView: View {
	@ObservedObject var webViewStore: WebViewStore
	@ObservedObject var downloadManager: DownloadManager
	@Binding var showDownloads: Bool
	@Binding var showHistory: Bool
	var onNewTabRequested: (URL) -> Void
	
	private let placement: ToolbarItemPlacement = .automatic
	
	var body: some View {
		VStack(spacing: 0) {
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
			.padding(.horizontal, 6)
			.padding(.vertical, 3)
			
			if webViewStore.isLoading {
				ProgressView(value: webViewStore.estimatedProgress)
			}
			
			WebView(
				webView: webViewStore.webView,
				downloadManager: downloadManager,
				onNewTabRequested: onNewTabRequested
			)
		}
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
						showHistory.toggle()
					} label: {
						Label("History", systemImage: "clock")
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
		webViewStore.loadURL(webViewStore.currentURL)
	}
}

#Preview {
	BrowserView(startupURL: "https://example.com")
}
