import Foundation

protocol HistoryRepository: Sendable {
    /// Newest first.
    func load() async -> Either<Failure, [HistoryEntry]>
    /// Prepends `entry`, persists, and returns the updated list (newest first).
    func append(_ entry: HistoryEntry) async -> Either<Failure, [HistoryEntry]>
}
