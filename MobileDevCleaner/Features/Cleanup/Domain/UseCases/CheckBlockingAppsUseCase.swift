import Foundation

struct CheckBlockingAppsUseCase: Sendable {
    private let repository: any CleanupRepository

    init(repository: any CleanupRepository) {
        self.repository = repository
    }

    func callAsFunction(for operations: [CleanupOperation]) async -> [BlockingApp] {
        let tools = Set(operations.map(\.category.tool))
        guard !tools.isEmpty else { return [] }
        return await repository.blockingApps(for: tools)
    }
}
