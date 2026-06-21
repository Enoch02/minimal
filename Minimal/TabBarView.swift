import SwiftUI

struct TabBarView: View {
	@ObservedObject var tabManager: TabManager
	
	var body: some View {
		HStack(spacing: 0) {
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 2) {
					ForEach(tabManager.tabs) { tab in
						TabItemView(
							webViewStore: tab.webViewStore,
							isSelected: tab.id == tabManager.selectedTabID,
							canClose: tabManager.tabs.count > 1,
							onSelect: { tabManager.selectTab(tab) },
							onClose: { tabManager.closeTab(tab) }
						)
					}
				}
				.padding(.horizontal, 4)
			}
			
			Divider()
				.frame(height: 20)
				.padding(.horizontal, 4)
			
			Button(action: { tabManager.addTab() }) {
				Image(systemName: "plus")
					.font(.system(size: 12, weight: .medium))
					.frame(width: 28, height: 28)
					.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
			.padding(.trailing, 8)
			.help("New Tab")
		}
		.frame(height: 36)
		.background(.bar)
	}
}

// MARK: - Individual Tab Item

private struct TabItemView: View {
	@ObservedObject var webViewStore: WebViewStore
	let isSelected: Bool
	let canClose: Bool
	let onSelect: () -> Void
	let onClose: () -> Void
	
	@State private var isHovering = false
	
	private var displayTitle: String {
		let title = webViewStore.title
		if !title.isEmpty { return title }
		let url = webViewStore.currentURL
		if !url.isEmpty { return url }
		return "New Tab"
	}
	
	var body: some View {
		HStack(spacing: 4) {
			Text(displayTitle)
				.font(.system(size: 12))
				.lineLimit(1)
				.truncationMode(.tail)
				.frame(maxWidth: 180, alignment: .leading)
			
			if canClose && (isSelected || isHovering) {
				Button(action: onClose) {
					Image(systemName: "xmark")
						.font(.system(size: 8, weight: .bold))
						.foregroundStyle(.secondary)
						.frame(width: 16, height: 16)
						.contentShape(Circle())
				}
				.buttonStyle(.plain)
			} else if canClose {
				// Reserve space so tabs don't shift on hover
				Color.clear
					.frame(width: 16, height: 16)
			}
		}
		.padding(.horizontal, 10)
		.padding(.vertical, 6)
		.background(
			RoundedRectangle(cornerRadius: 6)
				.fill(tabBackground)
		)
		.onHover { hovering in
			isHovering = hovering
		}
		.onTapGesture {
			onSelect()
		}
	}
	
	private var tabBackground: some ShapeStyle {
		if isSelected {
			return AnyShapeStyle(Color.accentColor.opacity(0.15))
		} else if isHovering {
			return AnyShapeStyle(Color.secondary.opacity(0.1))
		} else {
			return AnyShapeStyle(Color.clear)
		}
	}
}
