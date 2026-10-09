import Foundation

/// One reviewed unit of work: a marked candidate or a device with its chosen action.
struct CleanupOperation: Identifiable, Sendable, Hashable {
    enum Source: Sendable, Hashable {
        case candidate
        case device(DeviceAction)
    }

    /// Candidate path or device id.
    let id: String
    let category: CategoryID
    /// Candidate name, or "iPhone 16 Pro · Restablecer" for devices.
    let name: String
    let size: Int64
    let risk: RiskLevel
    /// Cost explanation shown under "Tiene costo" in the review.
    let note: String?
    let source: Source
    let steps: [ExecutionStrategy]
    /// Revealed in Finder on failure; its cached size is dropped afterwards.
    let url: URL
}
