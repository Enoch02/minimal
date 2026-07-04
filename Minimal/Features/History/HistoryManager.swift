import Foundation

struct HistoryVisit: Identifiable, Codable, Equatable {
	let id: UUID
	let url: String
	let title: String
	let date: Date

	init(url: String, title: String, date: Date = Date()) {
		self.id = UUID()
		self.url = url
		self.title = title
		self.date = date
	}
}

final class HistoryManager: ObservableObject {
	static let shared = HistoryManager()

	@Published var visits: [HistoryVisit] = []

	private let maxVisits = 1000
	private let userDefaultsKey = "historyVisits"

	private init() {
		load()
	}

	func addVisit(url: String, title: String) {
		let visit = HistoryVisit(url: url, title: title)
		visits.insert(visit, at: 0)
		if visits.count > maxVisits {
			visits = Array(visits.prefix(maxVisits))
		}
		save()
	}

	func delete(_ visit: HistoryVisit) {
		visits.removeAll { $0.id == visit.id }
		save()
	}

	func deleteAll() {
		visits.removeAll()
		save()
	}

	private func save() {
		if let data = try? JSONEncoder().encode(visits) {
			UserDefaults.standard.set(data, forKey: userDefaultsKey)
		}
	}

	private func load() {
		guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
		visits = (try? JSONDecoder().decode([HistoryVisit].self, from: data)) ?? []
	}
}
