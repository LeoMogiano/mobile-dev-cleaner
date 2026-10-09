import Foundation

protocol CleanupRepository: Sendable {
    /// Runs operations one by one. Cancelling `token` stops before the next operation; the
    /// running one finishes (killing `simctl erase` halfway can corrupt a device).
    /// `.completed` is always the last event.
    func execute(
        _ operations: [CleanupOperation], movesToTrash: Bool, token: CancellationToken
    ) -> AsyncStream<CleanupEvent>
    /// Open apps that make cleaning `tools` unsafe.
    func blockingApps(for tools: Set<Tool>) async -> [BlockingApp]
}
