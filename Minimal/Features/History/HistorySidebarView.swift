import SwiftUI

struct HistorySidebarView: View {
	@ObservedObject private var historyManager = HistoryManager.shared
	@State private var searchText = ""

	var onVisitSelected: (String) -> Void

	private var groupedVisits: [(Date, [HistoryVisit])] {
		let filtered = searchText.isEmpty
			? historyManager.visits
			: historyManager.visits.filter {
				$0.title.localizedCaseInsensitiveContains(searchText)
					|| $0.url.localizedCaseInsensitiveContains(searchText)
			}

		let calendar = Calendar.current
		var groups: [(Date, [HistoryVisit])] = []
		var currentDate: Date?
		var currentGroup: [HistoryVisit] = []

		for visit in filtered {
			let day = calendar.startOfDay(for: visit.date)
			if day != currentDate {
				if let date = currentDate, !currentGroup.isEmpty {
					groups.append((date, currentGroup))
				}
				currentDate = day
				currentGroup = [visit]
			} else {
				currentGroup.append(visit)
			}
		}
		if let date = currentDate, !currentGroup.isEmpty {
			groups.append((date, currentGroup))
		}

		return groups
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				TextField("Search history", text: $searchText)
					.textFieldStyle(.roundedBorder)

				Button("Clear All") {
					historyManager.deleteAll()
				}
				.buttonStyle(.plain)
				.foregroundColor(.red)
				.disabled(historyManager.visits.isEmpty)
			}
			.padding(8)

			Divider()

			if historyManager.visits.isEmpty {
				Spacer()
				Text("No history")
					.foregroundColor(.secondary)
				Spacer()
			} else {
				List {
					ForEach(groupedVisits, id: \.0) { date, visits in
						Section(header: Text(dateFormatter.string(from: date))) {
							ForEach(visits) { visit in
								Button {
									onVisitSelected(visit.url)
								} label: {
									VStack(alignment: .leading, spacing: 2) {
										Text(visit.title.isEmpty ? visit.url : visit.title)
											.lineLimit(1)
										Text(visit.url)
											.font(.caption)
											.foregroundColor(.secondary)
											.lineLimit(1)
									}
								}
								.buttonStyle(.plain)
								.swipeActions {
									Button(role: .destructive) {
										historyManager.delete(visit)
									} label: {
										Label("Delete", systemImage: "trash")
									}
								}
							}
						}
					}
				}
				.listStyle(.sidebar)
			}
		}
		.frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
	}

	private var dateFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateStyle = .long
		formatter.timeStyle = .none
		return formatter
	}
}
