import Foundation

/// Case order is the display order inside a category.
enum CandidateGroup: String, Sendable, Codable, CaseIterable, Hashable {
    case sharedCache
    case projects
    case orphanProjects
    case usedByEmulators
    case unusedByEmulators
    case usedByProjects
    case unusedByProjects
    case olderRuntimes
    case latestRuntimes
}
