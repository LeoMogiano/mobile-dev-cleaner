import Foundation

/// What the user marked for cleanup: candidate paths and one action per device.
@MainActor @Observable
final class SelectionStore {
    private(set) var candidateIDs: Set<String> = []
    private(set) var deviceActions: [String: DeviceAction] = [:]

    var isEmpty: Bool { candidateIDs.isEmpty && deviceActions.isEmpty }
    var count: Int { candidateIDs.count + deviceActions.count }

    func isSelected(_ candidate: CleanupCandidate) -> Bool {
        candidateIDs.contains(candidate.id)
    }

    func toggle(_ candidate: CleanupCandidate) {
        if candidateIDs.remove(candidate.id) == nil { candidateIDs.insert(candidate.id) }
    }

    func select(_ candidates: [CleanupCandidate]) {
        candidateIDs.formUnion(candidates.map(\.id))
    }

    func deselect(_ candidates: [CleanupCandidate]) {
        candidateIDs.subtract(candidates.map(\.id))
    }

    func action(for device: DeviceCandidate) -> DeviceAction? {
        deviceActions[device.id]
    }

    /// Tapping the chosen action again clears it (nothing is selected by default).
    func setAction(_ action: DeviceAction, for device: DeviceCandidate) {
        deviceActions[device.id] = deviceActions[device.id] == action ? nil : action
    }

    /// Replaces the selection with an imported plan.
    func apply(_ plan: PlanSelection) {
        candidateIDs = plan.candidateIDs
        deviceActions = plan.deviceActions
    }

    func clear() {
        candidateIDs.removeAll()
        deviceActions.removeAll()
    }

    /// Drops ids that no longer exist after a rescan or cleanup.
    func prune(to reports: [CategoryID: CategoryReport]) {
        let candidates = Set(reports.values.flatMap { $0.candidates.map(\.id) })
        let devices = Set(reports.values.flatMap { $0.devices.map(\.id) })
        candidateIDs.formIntersection(candidates)
        deviceActions = deviceActions.filter { devices.contains($0.key) }
    }

    func selectedBytes(in reports: [CategoryID: CategoryReport]) -> Int64 {
        reports.values.reduce(0) { total, report in
            let items = report.candidates.filter { candidateIDs.contains($0.id) }.reduce(0) { $0 + $1.size }
            let devices = report.devices.reduce(Int64(0)) { sum, device in
                guard let action = deviceActions[device.id] else { return sum }
                return sum + (device.plan(for: action)?.freedBytes ?? 0)
            }
            return total + items + devices
        }
    }
}
