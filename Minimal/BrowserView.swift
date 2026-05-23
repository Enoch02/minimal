import SwiftUI

struct BrowserView: View {
    @State private var urlString = "https://testfilehub.github.io"
    @StateObject private var webViewStore = WebViewStore()
    @StateObject private var downloadManager = DownloadManager()
    @State private var showDownloads = false
    
    private let placement: ToolbarItemPlacement = .automatic
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Enter URL", text: $urlString)
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
            
            if webViewStore.isLoadingPage() {
                ProgressView()
                    .progressViewStyle(.linear)
            }
            
            WebView(webView: webViewStore.webView, downloadManager: downloadManager)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .toolbar {
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
        .sheet(isPresented: $showDownloads) {
            DownloadsListView(manager: downloadManager)
        }
    }
    
    private func onURLSubmit() {
        NotificationCenter.default.post(name: .loadURL, object: urlString)
    }
}

#Preview {
    BrowserView()
}
