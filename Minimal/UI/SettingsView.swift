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
	@AppStorage("appTheme") var appTheme: String = "system"
	@AppStorage("askForDownloadLocation") var askForDownloadLocation: Bool = false
	@AppStorage("defaultDownloadDirectory") var defaultDownloadDirectory: String = ""
	
	@State private var urlBuffer: String = ""
	
	private var displayDownloadDirectory: String {
		defaultDownloadDirectory.isEmpty
			? FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.path
			: defaultDownloadDirectory
	}
	
	var body: some View {
		TabView {
			Form {
				Toggle(
					"Terminate downloads on quit",
					isOn: $terminateDownloadsOnQuit
				)
				.help("If enabled, all active aria2 processes will be killed when the app is closed.")
				
				Picker("App Theme", selection: $appTheme) {
					Text("System").tag("system")
					Text("Light").tag("light")
					Text("Dark").tag("dark")
				}
				.pickerStyle(SegmentedPickerStyle())
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
							urlToLoad = urlBuffer
						} else {
							urlBuffer = urlToLoad
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
			
			Form {
				Toggle(
					"Ask for download location each time",
					isOn: $askForDownloadLocation
				)
				.help("If enabled, a folder picker will appear for every download.")
				
				HStack {
					VStack(alignment: .leading, spacing: 2) {
						Text("Default download directory:")
							.font(.caption)
							.foregroundColor(.secondary)
						Text(displayDownloadDirectory)
							.font(.callout)
							.lineLimit(1)
							.truncationMode(.middle)
					}
					
					Spacer()
					
					Button("Change...") {
						pickDownloadDirectory()
					}
					
					if !defaultDownloadDirectory.isEmpty {
						Button("Reset") {
							defaultDownloadDirectory = ""
						}
						.buttonStyle(.borderless)
						.foregroundColor(.secondary)
					}
				}
			}
			.tabItem {
				Label("Downloads", systemImage: "arrow.down.circle")
			}
		}
		.padding()
		.frame(width: 400, height: 200)
		.preferredColorScheme(appTheme == "light" ? .light : appTheme == "dark" ? .dark : nil)
		.onAppear {
			urlBuffer = urlToLoad
		}
	}
	
	private func pickDownloadDirectory() {
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.canCreateDirectories = true
		panel.message = "Choose default download directory"
		panel.prompt = "Select"
		guard panel.runModal() == .OK, let url = panel.url else { return }
		defaultDownloadDirectory = url.path
	}
}

#Preview {
	SettingsView()
}
