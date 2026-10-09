import Foundation

enum Tool: String, Sendable, Codable, CaseIterable, Hashable {
    case xcode
    case android
}

enum RiskLevel: String, Sendable, Codable, Hashable {
    case regenerates
    case hasCost
}
