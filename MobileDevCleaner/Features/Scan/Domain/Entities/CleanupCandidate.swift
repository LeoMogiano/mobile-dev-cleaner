import Foundation

struct CleanupCandidate: Identifiable, Sendable, Hashable {
    /// Absolute path; stable across rescans.
    let id: String
    let category: CategoryID
    let name: String
    let url: URL
    let size: Int64
    let risk: RiskLevel
    let group: CandidateGroup?
    let isOrphan: Bool
    let modifiedAt: Date?
    /// "Por qué aparece" in the inspector.
    let reason: String?
    /// Concrete cost copy for `.hasCost` items.
    let cost: String?
    let execution: ExecutionStrategy
    /// Run before `execution`, e.g. deleting a runtime's simulators.
    var prerequisites: [ExecutionStrategy] = []

    var steps: [ExecutionStrategy] { prerequisites + [execution] }
}
