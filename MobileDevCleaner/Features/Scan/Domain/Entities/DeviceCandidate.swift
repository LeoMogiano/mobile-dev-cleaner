import Foundation

enum DeviceKind: String, Sendable, Codable, Hashable {
    case iphone, ipad, watch, tv, vision, phone, tablet
}

enum DeviceAction: String, Sendable, Codable, CaseIterable, Hashable {
    case clean
    case reset
    case delete
}

struct DeviceSizes: Sendable, Hashable {
    var data: Int64 = 0
    var cache: Int64 = 0
    var snapshots: Int64 = 0
    /// Everything else (system base, configs).
    var other: Int64 = 0

    var total: Int64 { data + cache + snapshots + other }
}

struct DeviceActionPlan: Sendable, Hashable {
    let action: DeviceAction
    let risk: RiskLevel
    let freedBytes: Int64
    let steps: [ExecutionStrategy]
}

struct DeviceCandidate: Identifiable, Sendable, Hashable {
    /// Simulator UDID or AVD name.
    let id: String
    let category: CategoryID
    let name: String
    /// "iOS 18.2", "API 34 · Android 14".
    let osVersion: String
    let kind: DeviceKind
    let url: URL
    let sizes: DeviceSizes
    var isRunning: Bool
    let isAvailable: Bool
    let plans: [DeviceActionPlan]

    func plan(for action: DeviceAction) -> DeviceActionPlan? {
        plans.first { $0.action == action }
    }
}
