import Foundation

/// The `mdc` CLI `ScanResult` (`src/models/scan.ts`). `mdc clean --plan` runs the items with
/// `selected: true` and containers with a `selectedAction`.
struct MdcPlanFile: Codable, Equatable {
    struct Execution: Codable, Equatable {
        /// "remove" | "cli_command" | "container_action".
        var kind: String
        var path: String?
        var executable: String?
        var args: [String]?
        /// "soft_clean" | "reset" | "delete".
        var containerAction: String?
    }

    struct Candidate: Codable, Equatable {
        var id: String
        var path: String
        var displayName: String
        /// "green" (regenerates) | "yellow" (has cost).
        var risk: String
        /// `Category` raw value from `src/models/enums.ts`.
        var category: String
        var tool: String
        var size: Int64
        var reason: String
        var execution: Execution
        var group: String?
        var selected: Bool
    }

    struct Component: Codable, Equatable {
        var label: String
        var size: Int64
        /// "state" | "cache" | "snapshot".
        var role: String
    }

    struct Action: Codable, Equatable {
        var name: String
        var risk: String
        var description: String
        var estimatedSize: Int64
        var execution: Execution
    }

    struct Container: Codable, Equatable {
        var id: String
        var path: String
        var name: String
        /// "ios_simulator" | "android_avd".
        var kind: String
        var tool: String
        var totalSize: Int64
        var breakdown: [Component]
        var actions: [Action]
        var selectedAction: String?
    }

    struct Report: Codable, Equatable {
        var tool: String
        var candidates: [Candidate]
        var containers: [Container]
    }

    /// ISO 8601.
    var scannedAt: String
    /// Keyed by tool ("xcode", "android").
    var reports: [String: Report]
}
