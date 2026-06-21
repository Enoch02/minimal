import Foundation
import Combine
import SwiftUI

open class DownloadTask: Identifiable, ObservableObject {
	public let id = UUID()
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

open class DownloadManager: ObservableObject {
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
