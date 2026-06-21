import SwiftUI

final class TabManager: ObservableObject {
	@Published var tabs: [TabModel]
	@Published var selectedTabID: UUID

	var selectedTab: TabModel {
		tabs.first { $0.id == selectedTabID } ?? tabs[0]
	}

	init(startupURL: String) {
		let firstTab = TabModel(url: startupURL)
		tabs = [firstTab]
		selectedTabID = firstTab.id
	}

	@discardableResult // tell the compiler it's okay if the callers ignore the return values
	func addTab(url: String = "") -> TabModel {
		let tab = TabModel(url: url)
		tabs.append(tab)
		selectedTabID = tab.id
		
		return tab
	}

	func closeTab(_ tab: TabModel) {
		guard tabs.count > 1 else { return }

		if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
			let wasSelected = selectedTabID == tab.id
			tabs.remove(at: index)

			if wasSelected {
				let newIndex = min(index, tabs.count - 1)
				selectedTabID = tabs[newIndex].id
			}
		}
	}

	func selectTab(_ tab: TabModel) {
		selectedTabID = tab.id
	}
}

// MARK: - FocusedValue for keyboard shortcut support

struct FocusedTabManagerKey: FocusedValueKey {
	typealias Value = TabManager
}

extension FocusedValues {
	var tabManager: TabManager? {
		get { self[FocusedTabManagerKey.self] }
		set { self[FocusedTabManagerKey.self] = newValue }
	}
}
