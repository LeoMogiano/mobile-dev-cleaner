import Foundation

/// Last line of defense before anything is deleted or a command runs.
struct PathGuard: Sendable {
    let paths: PathProvider

    private struct Root {
        let url: URL
        /// When set, the first component below the root must start with this prefix.
        var firstComponentPrefix: String?
        /// The scanner offers this very folder as a candidate (e.g. `~/.fastlane`).
        var includesRoot = false
    }

    private static let protectedNames = [
        "platform-tools", "cmdline-tools", "licenses", "keystore", "provisioning profiles",
        "mobiledevice", "certificates", "adbkey", "backup",
    ]
    private static let protectedExtensions: Set<String> = ["jks", "keystore", "p12", "mobileprovision", "cer", "pem"]
    private static let reservedTargets: Set<String> = ["all", "unavailable", "booted"]

    /// Roots the scanners may delete inside of; never the root itself.
    private var roots: [Root] {
        [
            Root(url: paths.developer),
            Root(url: paths.caches),
            Root(url: paths.logs),
            Root(url: paths.applicationSupport.appending(path: "Google", directoryHint: .isDirectory)),
            Root(url: paths.applicationSupport.appending(path: "kotlin", directoryHint: .isDirectory)),
            Root(url: paths.preferences, firstComponentPrefix: "AndroidStudio"),
            Root(url: paths.gradle),
            Root(url: paths.android),
            Root(url: paths.androidSdk),
            Root(url: paths.home.appending(path: ".kotlin", directoryHint: .isDirectory)),
            Root(url: paths.home.appending(path: ".cocoapods", directoryHint: .isDirectory)),
            Root(url: paths.home.appending(path: ".fastlane", directoryHint: .isDirectory), includesRoot: true),
        ]
    }

    func isRemovable(_ url: URL) -> Bool {
        guard let target = Self.resolvedComponents(url) else { return false }
        return roots.contains { root in
            let base = Self.components(of: root.url.resolvingSymlinksInPath())
            guard !base.isEmpty, target.count >= base.count, Array(target.prefix(base.count)) == base else { return false }
            let relative = Array(target.dropFirst(base.count))
            if relative.isEmpty { return root.includesRoot }
            if let prefix = root.firstComponentPrefix, !relative[0].hasPrefix(prefix) { return false }
            return !relative.contains(where: Self.isProtected)
        }
    }

    func isAllowedCommand(executable: String, arguments: [String]) -> Bool {
        if executable == "/usr/bin/xcrun" {
            switch arguments.count {
            case 3 where arguments[0] == "simctl" && ["erase", "delete"].contains(arguments[1]):
                return Self.isSafeTarget(arguments[2])
            case 4 where arguments[0] == "simctl" && arguments[1] == "runtime" && arguments[2] == "delete":
                return Self.isSafeTarget(arguments[3])
            case 5 where arguments == ["simctl", "--set", "previews", "delete", "all"]:
                return true
            default:
                return false
            }
        }
        let avdmanager = paths.androidSdk.appending(path: "cmdline-tools/latest/bin/avdmanager").path
        if executable == avdmanager, arguments.count == 4, arguments[0] == "delete", arguments[1] == "avd", arguments[2] == "-n" {
            return Self.isSafeTarget(arguments[3])
        }
        return false
    }

    private static func isSafeTarget(_ value: String) -> Bool {
        !value.trimmingCharacters(in: .whitespaces).isEmpty
            && !value.hasPrefix("-")
            && !reservedTargets.contains(value.lowercased())
    }

    private static func isProtected(_ component: String) -> Bool {
        let lower = component.lowercased()
        if protectedNames.contains(where: lower.contains) { return true }
        return protectedExtensions.contains((lower as NSString).pathExtension)
    }

    /// Standardizes and resolves symlinks of the parent folder; the last component is kept as is
    /// (removing a symlink never follows it).
    private static func resolvedComponents(_ url: URL) -> [String]? {
        guard url.isFileURL, url.path.hasPrefix("/"), url.path != "/" else { return nil }
        if url.pathComponents.contains("..") { return nil }
        let standardized = url.standardizedFileURL
        let parent = standardized.deletingLastPathComponent().resolvingSymlinksInPath()
        return components(of: parent) + [standardized.lastPathComponent]
    }

    private static func components(of url: URL) -> [String] {
        url.path.split(separator: "/").map(String.init)
    }
}
