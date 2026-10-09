import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("PathGuard")
struct PathGuardTests {
    private let temp: TempDirectory
    private let paths: PathProvider
    private let guardrail: PathGuard

    init() throws {
        temp = try TempDirectory()
        paths = temp.paths
        guardrail = PathGuard(paths: paths)
    }

    @Test("typical scanner paths are removable")
    func typicalPaths() {
        let urls = [
            paths.derivedData.appending(path: "App-abc"),
            paths.caches.appending(path: "com.apple.dt.Xcode"),
            paths.logs.appending(path: "CoreSimulator"),
            paths.previews,
            paths.archives.appending(path: "2024-01-01/App.xcarchive"),
            paths.xcode.appending(path: "iOS DeviceSupport/17.0"),
            paths.coreSimulatorDevices.appending(path: "UDID/data/Library/Caches"),
            paths.coreSimulatorCaches,
            paths.developer.appending(path: "XCTestDevices"),
            paths.cocoapodsRepos,
            paths.home.appending(path: ".fastlane"),
            paths.gradle.appending(path: "caches/modules-2"),
            paths.gradle.appending(path: "wrapper/dists/gradle-8.0"),
            paths.android.appending(path: "build-cache"),
            paths.avd.appending(path: "Pixel.avd"),
            paths.avd.appending(path: "Pixel.ini"),
            paths.androidSdk.appending(path: "system-images/android-34"),
            paths.kotlinDaemon,
            paths.applicationSupport.appending(path: "kotlin/daemon"),
            paths.applicationSupport.appending(path: "Google/AndroidStudio2023.1"),
            paths.preferences.appending(path: "AndroidStudio2023.1"),
            paths.caches.appending(path: "JetBrains/AndroidStudio2023.1"),
        ]
        for url in urls {
            #expect(guardrail.isRemovable(url), "expected removable: \(url.path)")
        }
    }

    @Test("roots, home and library are never removable")
    func rootsRejected() {
        let urls = [
            paths.home, paths.library, paths.developer, paths.caches, paths.gradle, paths.android,
            paths.androidSdk, paths.derivedData.deletingLastPathComponent().deletingLastPathComponent(),
            paths.preferences, paths.applicationSupport, paths.preferences.appending(path: "com.apple.finder.plist"),
            paths.home.appending(path: ".kotlin"), paths.home.appending(path: ".cocoapods"),
            URL(filePath: "/"),
        ]
        for url in urls {
            #expect(!guardrail.isRemovable(url), "expected rejected: \(url.path)")
        }
    }

    @Test("paths outside the allowed roots are rejected")
    func outsideRoots() {
        #expect(!guardrail.isRemovable(paths.home.appending(path: "Documents/file.txt")))
        #expect(!guardrail.isRemovable(paths.library.appending(path: "Keychains/login.keychain-db")))
        #expect(!guardrail.isRemovable(URL(filePath: "/etc/hosts")))
        #expect(!guardrail.isRemovable(URL(string: "relative/path")!))
    }

    @Test("parent traversal is rejected")
    func traversal() {
        let url = URL(filePath: paths.derivedData.path + "/../../../../Documents")
        #expect(!guardrail.isRemovable(url))
        #expect(!guardrail.isRemovable(paths.caches.appending(path: "../Keychains/x")))
    }

    @Test("symlinked parent pointing outside is rejected")
    func symlinkEscape() throws {
        let outside = try temp.directory("outside/target")
        let link = paths.caches.appending(path: "escape")
        try FileManager.default.createDirectory(at: paths.caches, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside.deletingLastPathComponent())
        #expect(!guardrail.isRemovable(link.appending(path: "target")))
        #expect(guardrail.isRemovable(link), "the link itself lives inside the root")
    }

    @Test("protected names and extensions are rejected")
    func protectedComponents() {
        let urls = [
            paths.androidSdk.appending(path: "platform-tools"),
            paths.androidSdk.appending(path: "cmdline-tools/latest"),
            paths.androidSdk.appending(path: "licenses"),
            paths.android.appending(path: "adbkey"),
            paths.android.appending(path: "adbkey.pub"),
            paths.android.appending(path: "debug.keystore"),
            paths.gradle.appending(path: "caches/release.jks"),
            paths.caches.appending(path: "Provisioning Profiles/x"),
            paths.developer.appending(path: "MobileDevice/x"),
            paths.caches.appending(path: "certs/dev.p12"),
            paths.caches.appending(path: "certs/a.mobileprovision"),
            paths.caches.appending(path: "certs/a.cer"),
            paths.caches.appending(path: "certs/a.pem"),
            paths.caches.appending(path: "Certificates"),
            paths.caches.appending(path: "iPhone Backup/x"),
            paths.androidSdk.appending(path: "PLATFORM-TOOLS"),
        ]
        for url in urls {
            #expect(!guardrail.isRemovable(url), "expected rejected: \(url.path)")
        }
    }

    @Test("preferences only allow Android Studio folders")
    func preferencesPrefix() {
        #expect(guardrail.isRemovable(paths.preferences.appending(path: "AndroidStudioPreview2024.3")))
        #expect(!guardrail.isRemovable(paths.preferences.appending(path: "com.apple.dt.Xcode.plist")))
    }

    @Test("allowed commands")
    func allowedCommands() {
        let avdmanager = paths.androidSdk.appending(path: "cmdline-tools/latest/bin/avdmanager").path
        #expect(guardrail.isAllowedCommand(executable: "/usr/bin/xcrun", arguments: ["simctl", "erase", "ABC"]))
        #expect(guardrail.isAllowedCommand(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", "ABC"]))
        #expect(guardrail.isAllowedCommand(executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", "ABC"]))
        #expect(guardrail.isAllowedCommand(executable: "/usr/bin/xcrun", arguments: ["simctl", "--set", "previews", "delete", "all"]))
        #expect(guardrail.isAllowedCommand(executable: avdmanager, arguments: ["delete", "avd", "-n", "Pixel"]))
    }

    @Test("unlisted commands are rejected")
    func rejectedCommands() {
        let avdmanager = paths.androidSdk.appending(path: "cmdline-tools/latest/bin/avdmanager").path
        let cases: [(String, [String])] = [
            ("/bin/rm", ["-rf", "/"]),
            ("/usr/bin/xcrun", ["simctl", "erase", "all"]),
            ("/usr/bin/xcrun", ["simctl", "delete", "unavailable"]),
            ("/usr/bin/xcrun", ["simctl", "erase", "booted"]),
            ("/usr/bin/xcrun", ["simctl", "erase", "--all"]),
            ("/usr/bin/xcrun", ["simctl", "erase"]),
            ("/usr/bin/xcrun", ["simctl", "shutdown", "ABC"]),
            ("/usr/bin/xcrun", ["simctl", "erase", "ABC", "extra"]),
            ("/usr/bin/xcrun", ["simctl", "runtime", "delete"]),
            ("/usr/bin/xcrun", ["simctl", "--set", "previews", "delete", "ABC"]),
            ("xcrun", ["simctl", "erase", "ABC"]),
            ("/tmp/avdmanager", ["delete", "avd", "-n", "Pixel"]),
            (avdmanager, ["delete", "avd", "-n"]),
            (avdmanager, ["delete", "avd", "-n", "-x"]),
            (avdmanager, ["list", "avd"]),
        ]
        for (executable, arguments) in cases {
            #expect(!guardrail.isAllowedCommand(executable: executable, arguments: arguments), "expected rejected: \(executable) \(arguments)")
        }
    }
}
