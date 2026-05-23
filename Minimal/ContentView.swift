//
//  ContentView.swift
//  Minimal
//
//  Created by Enoch Adesanya on 18/05/2026.
//

import SwiftUI
import WebKit
import Combine

// MARK: - Models & Managers

class DownloadTask: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let filename: String
    @Published var output: String = ""
    @Published var isFinished: Bool = false
    
    var process: Process?
    private var outputPipe: Pipe?
    
    init(url: URL) {
        self.url = url
        self.filename = url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent
    }
    
    func start(cookies: String, userAgent: String, referer: String) {
        let process = Process()
        self.process = process
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aria2c")
        
        let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        process.arguments = [
            "--dir=\(downloads.path)",
            "--max-connection-per-server=16",
            "--split=16",
            "--min-split-size=1M",
            "--continue=true",
            "--header=Cookie: \(cookies)",
            "--header=Referer: \(referer)",
            "--header=User-Agent: \(userAgent)",
            url.absoluteString
        ]
        
        let pipe = Pipe()
        self.outputPipe = pipe
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                return
            }
            if let str = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.output += str
                }
            }
        }
        
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.isFinished = true
            }
        }
        
        do {
            try process.run()
        } catch {
            output += "Failed to launch: \(error.localizedDescription)"
            isFinished = true
        }
    }
    
    func cancel() {
        process?.terminate()
    }
}

class DownloadManager: ObservableObject {
    @Published var tasks: [DownloadTask] = []
    
    func addDownload(url: URL, cookies: String, userAgent: String, referer: String) {
        let task = DownloadTask(url: url)
        DispatchQueue.main.async {
            self.tasks.append(task)
            task.start(cookies: cookies, userAgent: userAgent, referer: referer)
        }
    }
    
    func cancelTask(_ task: DownloadTask) {
        task.cancel()
        tasks.removeAll { $0.id == task.id }
    }
    
    func cleanup(terminateAll: Bool) {
        if terminateAll {
            tasks.forEach { $0.cancel() }
        }
    }
}

final class WebViewStore: ObservableObject {
	let webView: WKWebView
	
	init() {
		let configuration = WKWebViewConfiguration()
		self.webView = WKWebView(frame: .zero, configuration: configuration)
	}
	
	func isLoadingPage() -> Bool { return webView.isLoading }
}

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

extension Notification.Name {
	static let loadURL = Notification.Name("loadURL")
}

struct WebView: NSViewRepresentable {
	let webView: WKWebView
	@ObservedObject var downloadManager: DownloadManager
	
	func makeCoordinator() -> Coordinator {
		Coordinator(downloadManager: downloadManager)
	}
	
	func makeNSView(context: Context) -> WKWebView {
		webView.navigationDelegate = context.coordinator
		
		if let url = URL(string: "https://example.com") {
			webView.load(URLRequest(url: url))
		}
		
		NotificationCenter.default.addObserver(forName: .loadURL, object: nil, queue: .main) { notification in
			guard let value = notification.object as? String
			else { return }
			
			let formatted = value.hasPrefix("http") ? value : "https://\(value)"
			
			guard let url = URL(string: formatted)
					
			else { return }
			
			webView.load(URLRequest(url: url))
		}
		
		return webView
	}
	
	func updateNSView(_ nsView: WKWebView, context: Context) {
		
	}
	
	final class Coordinator: NSObject, WKNavigationDelegate {
		let downloadManager: DownloadManager
		
		init(downloadManager: DownloadManager) {
			self.downloadManager = downloadManager
		}
		
		func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
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
		
		func sendToAria2(webView: WKWebView, downloadURL: URL) async {
			let cookieStore = webView.configuration
				.websiteDataStore
				.httpCookieStore
			
			let cookiesList = await getCookies(from: cookieStore, for: downloadURL)
			
			let cookieHeader = cookiesList
				.map { "\($0.name)=\($0.value)" }
				.joined(separator: "; ")
			
			let userAgent = await webView.evaluateJavaScriptAsync("navigator.userAgent") as? String ?? ""
			let referer = webView.url?.absoluteString ?? ""
			
			downloadManager.addDownload(url: downloadURL, cookies: cookieHeader, userAgent: userAgent, referer: referer)
		}
		
		func getCookies(from store: WKHTTPCookieStore, for url: URL) async -> [HTTPCookie] {
			await withCheckedContinuation { continuation in
				store.getAllCookies { cookies in
					let filtered = cookies.filter {
						guard let domain = url.host else {
							return false
						}
						return domain.hasSuffix($0.domain.trimmingCharacters(in: CharacterSet(charactersIn: ".")))
					}
					continuation.resume(returning: filtered)
				}
			}
		}
	}
}

// MARK: - Download UI Components

struct DownloadsListView: View {
    @ObservedObject var manager: DownloadManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTask: DownloadTask?
    
    var body: some View {
        NavigationStack {
            List(manager.tasks) { task in
                HStack {
                    VStack(alignment: .leading) {
                        Text(task.filename)
                            .font(.headline)
                        Text(task.url.absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if task.isFinished {
                        Text("Finished")
                            .foregroundColor(.green)
                    } else {
                        Button("Cancel") {
                            manager.cancelTask(task)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedTask = task
                }
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                DownloadDetailView(task: task)
            }
            .overlay {
                if manager.tasks.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Active Downloads")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct DownloadDetailView: View {
    @ObservedObject var task: DownloadTask
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(task.filename)
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(task.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                }
                .onChange(of: task.output) { newValue in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            Divider()
            
            HStack {
                if !task.isFinished {
                    Button("Cancel Download") {
                        task.cancel()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Text("Download Finished")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}

// MARK: - Async JS Helper
extension WKWebView {
	func evaluateJavaScriptAsync(_ script: String) async -> Any? {
		await withCheckedContinuation { continuation in
			evaluateJavaScript(script) { result, error in
				continuation.resume(returning: result)
			}
		}
	}
}

#Preview {
	BrowserView()
}
