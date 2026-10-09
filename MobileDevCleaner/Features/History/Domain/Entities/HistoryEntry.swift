import Foundation

struct HistoryEntry: Identifiable, Sendable, Codable, Equatable {
    struct Slice: Sendable, Codable, Equatable {
        let category: CategoryID
        let bytes: Int64
    }

    let id: UUID
    let date: Date
    let freedBytes: Int64
    let itemCount: Int
    /// Freed bytes per category, biggest first.
    let breakdown: [Slice]
}

extension HistoryEntry {
    init?(outcome: CleanupOutcome, date: Date = .now) {
        guard !outcome.done.isEmpty else { return nil }
        let bytes = Dictionary(grouping: outcome.done, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.size } }
        self.init(
            id: UUID(),
            date: date,
            freedBytes: outcome.freedBytes,
            itemCount: outcome.done.count,
            breakdown: bytes
                .map { Slice(category: $0.key, bytes: $0.value) }
                .sorted { $0.bytes != $1.bytes ? $0.bytes > $1.bytes : $0.category.rawValue < $1.category.rawValue }
        )
    }
}
