import SwiftUI

struct ErrorPageView: View {
	let error: WebError
	let onRetry: () -> Void

	var body: some View {
		VStack(spacing: 16) {
			Spacer()

			Image(systemName: "exclamationmark.triangle")
				.font(.system(size: 48))
				.foregroundColor(.secondary)

			Text(error.description)
				.font(.title2)
				.multilineTextAlignment(.center)

			if let url = error.failingURL {
				Text(url)
					.font(.caption)
					.foregroundColor(.secondary)
					.lineLimit(2)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 40)
			}

			HStack(spacing: 16) {
				Button("Retry") {
					onRetry()
				}
				.buttonStyle(.borderedProminent)
			}
			.padding(.top, 8)

			Spacer()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(NSColor.controlBackgroundColor))
	}
}

#Preview {
	ErrorPageView(
		error: WebError(
			code: -1009,
			domain: NSURLErrorDomain,
			description: "No internet connection",
			failingURL: "https://example.com"
		),
		onRetry: {}
	)
}
