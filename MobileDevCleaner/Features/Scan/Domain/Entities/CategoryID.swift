import Foundation

/// Ids match the prototype data (`mkData()`); case order is the sidebar order.
enum CategoryID: String, Sendable, Codable, CaseIterable, Hashable {
    case builds, caches, tests, sims, runtimes, devsup, archives, previews, pods
    case gcache, gdeps, gvers, jdks, glogs, acache, avds, sysimg, ndk, studio
    case fprojects, pubcache, fsdk, fvm

    var tool: Tool {
        switch self {
        case .builds, .caches, .tests, .sims, .runtimes, .devsup, .archives, .previews, .pods: .xcode
        case .gcache, .gdeps, .gvers, .jdks, .glogs, .acache, .avds, .sysimg, .ndk, .studio: .android
        case .fprojects, .pubcache, .fsdk, .fvm: .flutter
        }
    }

    var holdsDevices: Bool { self == .sims || self == .avds }
}
