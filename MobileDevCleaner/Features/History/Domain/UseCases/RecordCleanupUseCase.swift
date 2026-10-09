import Foundation

struct RecordCleanupUseCase: Sendable {
    private let repository: any HistoryRepository

    init(repository: any HistoryRepository) {
        self.repository = repository
    }

    /// Nothing is recorded when the cleanup freed nothing; returns nil then.
    func callAsFunction(_ outcome: CleanupOutcome, date: Date = .now) async -> Either<Failure, [HistoryEntry]>? {
        guard let entry = HistoryEntry(outcome: outcome, date: date) else { return nil }
        return await repository.append(entry)
    }
}
