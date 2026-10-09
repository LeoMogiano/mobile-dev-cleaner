import Foundation

actor HistoryRepositoryImpl: HistoryRepository {
    private let dataSource: any HistoryLocalDataSource
    private var cached: [HistoryEntry]?

    init(dataSource: any HistoryLocalDataSource) {
        self.dataSource = dataSource
    }

    func load() async -> Either<Failure, [HistoryEntry]> {
        if let cached = cached { return .right(cached) }
        return await Either.catching(domain: "history") {
            let entries = try await dataSource.read()
            self.cached = entries.sorted { $0.date > $1.date }
            return self.cached ?? []
        }
    }

    func append(_ entry: HistoryEntry) async -> Either<Failure, [HistoryEntry]> {
        let current = cached ?? []
        let updated = [entry] + current
        return await Either.catching(domain: "history") {
            try await dataSource.write(updated)
            self.cached = updated
            return updated
        }
    }
}
