import Foundation

enum Tool: String, Sendable, Codable, CaseIterable, Hashable {
    case xcode
    case android
    case flutter

    /// Brand names, not localized.
    var displayName: String {
        switch self {
        case .xcode: "Xcode"
        case .android: "Android"
        case .flutter: "Flutter"
        }
    }
}

enum RiskLevel: String, Sendable, Codable, Hashable {
    case regenerates
    case hasCost
}
