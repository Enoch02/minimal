import Testing
import Foundation
@testable import Minimal

// A lightweight subclass that overrides the start method to avoid launching external processes.
final class TestDownloadTask: DownloadTask {
    override func start(cookies: String = "", userAgent: String = "", referer: String = "") {
        // Simulate immediate completion without external work.
        DispatchQueue.main.async {
            self.isFinished = true
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
        // Give the async dispatch a moment to run.
        try await Task.sleep(for: .seconds(0.1))
        #expect(manager.tasks.count == 1)
        #expect(manager.tasks.first?.isFinished == true)
    }

    @Test func cancelRemovesTask() async throws {
        let manager = TestDownloadManager()
        manager.addDownload(url: URL(string: "https://example.com/file.txt")!, cookies: "", userAgent: "", referer: "")
        try await Task.sleep(for: .seconds(0.1))
        let task = manager.tasks.first!
        manager.cancelTask(task)
        #expect(manager.tasks.isEmpty)
    }

    @Test func cleanupTerminatesAllWhenRequested() async throws {
        let manager = TestDownloadManager()
        manager.addDownload(url: URL(string: "https://example.com/a")!, cookies: "", userAgent: "", referer: "")
        manager.addDownload(url: URL(string: "https://example.com/b")!, cookies: "", userAgent: "", referer: "")
        try await Task.sleep(for: .seconds(0.1))
        #expect(manager.tasks.count == 2)
        manager.cleanup(terminateAll: true)
        // The tasks remain in the array but should be marked as finished.
        for task in manager.tasks {
            #expect(task.isFinished)
        }
    }
}
