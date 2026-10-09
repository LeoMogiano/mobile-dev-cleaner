import Foundation

struct LoadHistoryUseCase: Sendable {
    private let repository: any HistoryRepository

    init(repository: any HistoryRepository) {
        self.repository = repository
    }

    func callAsFunction() async -> Either<Failure, [HistoryEntry]> {
        await repository.load()
    }
}
