import Foundation

protocol PlanTransferRepository: Sendable {
    /// Encodes the selection as an `mdc` plan JSON.
    func export(
        reports: [CategoryID: CategoryReport], candidateIDs: Set<String>, deviceActions: [String: DeviceAction]
    ) async -> Either<Failure, Data>
    /// Matches a plan's selected items against the current scan.
    func importPlan(_ data: Data, reports: [CategoryID: CategoryReport]) async -> Either<Failure, PlanSelection>
}
