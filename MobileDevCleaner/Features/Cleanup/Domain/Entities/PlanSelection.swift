import Foundation

/// What an imported plan marks in the current scan; importing never runs anything.
struct PlanSelection: Sendable, Equatable {
    var candidateIDs: Set<String> = []
    var deviceActions: [String: DeviceAction] = [:]
    /// Plan items that no longer exist on this Mac.
    var skipped = 0

    var count: Int { candidateIDs.count + deviceActions.count }
}
