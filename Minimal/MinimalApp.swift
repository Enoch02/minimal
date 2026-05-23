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
    
    var body: some Scene {
        WindowGroup {
            BrowserView()
        }
        
        Settings {
            SettingsView()
        }
    }
}

struct SettingsView: View {
    @AppStorage("terminateDownloadsOnQuit") var terminateDownloadsOnQuit: Bool = true
    
    var body: some View {
        Form {
            Toggle("Terminate downloads on quit", isOn: $terminateDownloadsOnQuit)
                .help("If enabled, all active aria2 processes will be killed when the app is closed.")
        }
        .padding()
        .frame(width: 300, height: 100)
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
