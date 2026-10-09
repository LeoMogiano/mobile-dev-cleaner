import Foundation

struct ExecuteCleanupUseCase: Sendable {
    private let repository: any CleanupRepository

    init(repository: any CleanupRepository) {
        self.repository = repository
    }

    func callAsFunction(
        _ operations: [CleanupOperation], movesToTrash: Bool, token: CancellationToken
    ) -> AsyncStream<CleanupEvent> {
        repository.execute(operations, movesToTrash: movesToTrash, token: token)
    }
}
