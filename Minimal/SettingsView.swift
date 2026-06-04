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
	
	@State private var urlBuffer: String = ""
	
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
			
			Form {
				TextField("Default Page:", text: $urlBuffer)
					.help("Set the web page to load as soon as the browser opens")
					.autocorrectionDisabled()
					.overlay(alignment: .trailing) {
						if !urlBuffer.isEmpty {
							let isValid = validateURL(urlBuffer) == .valid
							
							Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
								.foregroundStyle(isValid ? .green : .red)
								.padding(.trailing, 6)
						}
					}
					.onSubmit {
						if validateURL(urlBuffer) == .valid {
							urlToLoad = urlBuffer  // only write to AppStorage if valid
						} else {
							urlBuffer = urlToLoad  // revert buffer to last known good value
						}
					}
				
				if let message = validationMessage(validateURL(urlBuffer)) {
					Label(message, systemImage: "exclamationmark.triangle.fill")
						.font(.caption)
						.foregroundStyle(.red)
						.transition(.opacity.combined(with: .move(edge: .top)))
				}
			}
			.tabItem {
				Label("Browser", systemImage: "network")
			}
		}
		.padding()
		.frame(width: 400, height: 150)
		.onAppear {
			urlBuffer = urlToLoad
		}
	}
}

#Preview {
	SettingsView()
}
