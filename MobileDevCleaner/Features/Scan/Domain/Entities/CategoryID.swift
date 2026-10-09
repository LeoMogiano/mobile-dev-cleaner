import Foundation

/// Ids match the prototype data (`mkData()`); case order is the sidebar order.
enum CategoryID: String, Sendable, Codable, CaseIterable, Hashable {
    case builds, caches, tests, sims, runtimes, devsup, archives, previews, pods
    case gcache, gdeps, gvers, jdks, glogs, acache, avds, sysimg, ndk, studio

    var tool: Tool {
        switch self {
        case .builds, .caches, .tests, .sims, .runtimes, .devsup, .archives, .previews, .pods: .xcode
        default: .android
        }
    }

    var holdsDevices: Bool { self == .sims || self == .avds }
}
