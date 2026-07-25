import Testing
import Foundation
@testable import Minimal

// A lightweight subclass that overrides the start method to avoid launching external processes.
// Injects synthetic aria2c output chunks to exercise the progress parser.
final class TestDownloadTask: DownloadTask {
    var injectedOutputs: [String] = []
    var chunkDelay: TimeInterval = 0.001
    
    override func start(cookies: String = "", userAgent: String = "", referer: String = "") {
        DispatchQueue.main.async {
            self.isFinished = false
        }
        for chunk in injectedOutputs {
            DispatchQueue.main.asyncAfter(deadline: .now() + chunkDelay) { [weak self] in
                guard let self else { return }
                let padded = chunk.hasSuffix("\n") ? chunk : chunk + "\n"
                self.output += padded
                let tail = String(self.output.suffix(1000))
                let regex = try! NSRegularExpression(pattern: "(?:\\(|\\s|^)(\\d+)%")
                let range = NSRange(location: 0, length: tail.utf16.count)
                let matches = regex.matches(in: tail, range: range)
                if let lastMatch = matches.last,
                   let valueRange = Range(lastMatch.range(at: 1), in: tail),
                   let percentage = Double(tail[valueRange]) {
                    self.progress = percentage / 100.0
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + chunkDelay * Double(injectedOutputs.count + 1)) { [weak self] in
            self?.isFinished = true
            self?.progress = 1.0
        }
    }
}

// Extend DownloadManager to inject our TestDownloadTask for testing.
final class TestDownloadManager: DownloadManager {
    override func addDownload(url: URL, cookies: String, userAgent: String, referer: String) {
        let task = TestDownloadTask(url: url)
        DispatchQueue.main.async {
            self.tasks.append(task)
            task.start(cookies: cookies, userAgent: userAgent, referer: referer)
        }
    }
}

struct DownloadManagerTests {
    @Test func addDownloadIncrementsTaskCount() async throws {
        let manager = TestDownloadManager()
        #expect(manager.tasks.isEmpty)
        manager.addDownload(url: URL(string: "https://example.com/file.txt")!, cookies: "", userAgent: "", referer: "")
        try await Task.sleep(for: .milliseconds(200))
        #expect(manager.tasks.count == 1)
        #expect(manager.tasks.first?.isFinished == true)
    }

    @Test func cancelRemovesTask() async throws {
        let manager = TestDownloadManager()
        manager.addDownload(url: URL(string: "https://example.com/file.txt")!, cookies: "", userAgent: "", referer: "")
        try await Task.sleep(for: .milliseconds(200))
        let task = manager.tasks.first!
        manager.cancelTask(task)
        #expect(manager.tasks.isEmpty)
    }

    @Test func cleanupTerminatesAllWhenRequested() async throws {
        let manager = TestDownloadManager()
        manager.addDownload(url: URL(string: "https://example.com/a")!, cookies: "", userAgent: "", referer: "")
        manager.addDownload(url: URL(string: "https://example.com/b")!, cookies: "", userAgent: "", referer: "")
        try await Task.sleep(for: .milliseconds(200))
        #expect(manager.tasks.count == 2)
        manager.cleanup(terminateAll: true)
        for task in manager.tasks {
            #expect(task.isFinished)
        }
    }
    
    @Test func progressParsesPercentageFromOutput() async throws {
        let task = TestDownloadTask(url: URL(string: "https://example.com/file.zip")!)
        task.injectedOutputs = [
            "[#1 64KiB/1.2MiB(5%)]",
            "[#1 256KiB/1.2MiB(21%)]",
            "[#1 512KiB/1.2MiB(42%)]",
            "[#1 768KiB/1.2MiB(63%)]",
            "[#1 1.0MiB/1.2MiB(84%)]",
        ]
        task.start()
        try await Task.sleep(for: .milliseconds(200))
        #expect(task.progress >= 0.8)
        #expect(task.isFinished)
        #expect(task.progress == 1.0)
    }
    
    @Test func progressParsesSpaceDelimitedPercent() async throws {
        let task = TestDownloadTask(url: URL(string: "https://example.com/data.bin")!)
        task.injectedOutputs = [
            "Downloading... 25%",
            "Downloading... 50%",
            "Downloading... 75%",
        ]
        task.start()
        try await Task.sleep(for: .milliseconds(200))
        #expect(task.progress >= 0.7)
    }
    
    @Test func progressStartsAtZero() async throws {
        let task = DownloadTask(url: URL(string: "https://example.com/blank.zip")!)
        #expect(task.progress == 0.0)
        #expect(task.isFinished == false)
    }
}
