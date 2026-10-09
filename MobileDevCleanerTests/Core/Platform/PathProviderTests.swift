import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("PathProvider")
struct PathProviderTests {
    @Test("derivedData is built from home")
    func derivedData() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home, systemLibrary: URL(filePath: "/Library", directoryHint: .isDirectory))

        #expect(provider.derivedData.path == "/Users/test/Library/Developer/Xcode/DerivedData")
    }

    @Test("systemRuntimes is built from systemLibrary")
    func systemRuntimes() {
        let provider = PathProvider(home: URL(filePath: "/Users/test", directoryHint: .isDirectory), systemLibrary: URL(filePath: "/System/Library", directoryHint: .isDirectory))

        #expect(provider.systemRuntimes.path == "/System/Library/Developer/CoreSimulator/Profiles/Runtimes")
    }

    @Test("coreSimulatorDevices is built from home")
    func coreSimulatorDevices() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.coreSimulatorDevices.path == "/Users/test/Library/Developer/CoreSimulator/Devices")
    }

    @Test("gradle is built from home")
    func gradle() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.gradle.path == "/Users/test/.gradle")
    }

    @Test("android is built from home")
    func android() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.android.path == "/Users/test/.android")
    }

    @Test("avd is built from android")
    func avd() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.avd.path == "/Users/test/.android/avd")
    }

    @Test("androidSdk is built from home")
    func androidSdk() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.androidSdk.path == "/Users/test/Library/Android/sdk")
    }

    @Test("sizeCacheFile is in appCacheDirectory")
    func sizeCacheFile() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.sizeCacheFile.path == "/Users/test/Library/Caches/com.leomogiano.MobileDevCleaner/sizes.json")
    }

    @Test("cocoapodsRepos is built from home")
    func cocoapodsRepos() {
        let home = URL(filePath: "/Users/test", directoryHint: .isDirectory)
        let provider = PathProvider(home: home)

        #expect(provider.cocoapodsRepos.path == "/Users/test/.cocoapods/repos")
    }
}
