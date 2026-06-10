//
//  MinimalApp.swift
//  Minimal
//
//  Created by Enoch Adesanya on 18/05/2026.
//

import SwiftUI

@main
struct MinimalApp: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@AppStorage("appTheme") var appTheme: String = "system"
	@AppStorage("urlToLoadOnStart") var startupURL: String = "https://example.com"
	
	init() {
		UserDefaults.standard.register(defaults: [
			"urlToLoadOnStart": "https://example.com",
			"terminateDownloadsOnQuit": true
		]
		)
	}
	
	var body: some Scene {
		WindowGroup {
			BrowserView(startupURL: startupURL)
			.preferredColorScheme(appTheme == "light" ? .light : appTheme == "dark" ? .dark : nil)
		}
		
		Settings {
			SettingsView()
		}
	}
}

//TODO: can I check what process spawned the aria2c one before killing it?
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		let terminate = UserDefaults.standard.bool(forKey: "terminateDownloadsOnQuit")
		
		// This is a bit tricky since we don't have direct access to the manager here
		// without making it a singleton or similar.
		// For simplicity, we'll look for any active 'aria2c' processes and kill them if required.
		if terminate {
			let task = Process()
			task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
			task.arguments = ["aria2c"]
			try? task.run()
		}
		
		return .terminateNow
	}
}
