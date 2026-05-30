//
//  SettingsView.swift
//  Minimal
//
//  Created by Enoch Adesanya on 30/05/2026.
//

import SwiftUI

struct SettingsView: View {
	@AppStorage("terminateDownloadsOnQuit") var terminateDownloadsOnQuit: Bool = true
	@AppStorage("urlToLoadOnStart") var urlToLoad: String = ""
	
	var body: some View {
		TabView {
			Form {
				Toggle(
					"Terminate downloads on quit",
					isOn: $terminateDownloadsOnQuit
				)
				.help("If enabled, all active aria2 processes will be killed when the app is closed.")
			}
			.tabItem {
				Label("General", systemImage: "gearshape")
			}
			
			//TODO: add code that checks if the URL is proper
			Form {
				TextField("Default Page:", text: $urlToLoad)
					.help("Set the web page to load as soon as the browser opens")
			}
			.tabItem {
				Label("Browser", systemImage: "network")
			}
		}
		.padding()
		.frame(width: 400, height: 150)
	}
}

#Preview {
	SettingsView()
}
