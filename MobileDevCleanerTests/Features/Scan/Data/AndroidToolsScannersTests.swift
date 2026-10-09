import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Android tools scanners")
struct AndroidToolsScannersTests {
    @Test("Android caches scanner finds basic caches")
    func androidCachesBasic() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".android/cache/file1", bytes: 1024)
        try temp.file(".android/build-cache/file2", bytes: 2048)
        try temp.file(".android/metrics/file3", bytes: 512)

        let context = temp.scanContext()
        let scanner = AndroidCachesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 3)
        #expect(report.candidates.allSatisfy { $0.risk == .regenerates })
    }

    @Test("Android caches scanner picks newest Android Studio")
    func androidCachesNewest() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".android/cache/file1", bytes: 1024)
        try temp.file("Library/Caches/Google/AndroidStudio2023.1/studio.cache", bytes: 4096)
        try temp.file("Library/Caches/Google/AndroidStudio2024.2/studio.cache", bytes: 8192)

        let context = temp.scanContext()
        let scanner = AndroidCachesScanner()
        let report = await scanner.scan(in: context)

        let studioCandidate = report.candidates.first { $0.name.contains("Android Studio") }
        #expect(studioCandidate != nil)
        #expect(studioCandidate!.url.path.contains("AndroidStudio2024.2"))
    }

    @Test("SDK tools scanner lists NDK versions")
    func sdkNdkVersions() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Android/sdk/ndk/25.1.8937393/CMakeLists.txt", bytes: 1024)
        try temp.file("Library/Android/sdk/ndk/24.0.8215888/CMakeLists.txt", bytes: 1024)
        try temp.file("Library/Android/sdk/ndk/23.1.7779620/CMakeLists.txt", bytes: 1024)

        let context = temp.scanContext()
        let scanner = SdkToolsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 3)
        let ndkNames = report.candidates.map { $0.name }
        #expect(ndkNames.contains { $0.contains("25.1") })
        #expect(ndkNames.contains { $0.contains("24.0") })
    }

    @Test("SDK tools scanner marks newest NDK with reason")
    func sdkNewestReason() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Android/sdk/ndk/25.1.8937393/file", bytes: 1024)
        try temp.file("Library/Android/sdk/ndk/24.0.8215888/file", bytes: 1024)

        let context = temp.scanContext()
        let scanner = SdkToolsScanner()
        let report = await scanner.scan(in: context)

        let newest = report.candidates.max { $0.size < $1.size }
        #expect(newest?.reason != nil)
        #expect(newest!.reason!.contains("Probablemente"))
    }

    @Test("SDK tools scanner lists build-tools versions")
    func sdkBuildTools() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Android/sdk/build-tools/30.0.3/aapt", bytes: 1024)
        try temp.file("Library/Android/sdk/build-tools/31.0.0/aapt", bytes: 1024)

        let context = temp.scanContext()
        let scanner = SdkToolsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 2)
        #expect(report.candidates.allSatisfy { $0.name.contains("build-tools") })
    }

    @Test("SDK tools scanner lists platforms")
    func sdkPlatforms() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Android/sdk/platforms/android-30/file", bytes: 1024)
        try temp.file("Library/Android/sdk/platforms/android-31/file", bytes: 1024)

        let context = temp.scanContext()
        let scanner = SdkToolsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 2)
        #expect(report.candidates.allSatisfy { $0.name.contains("Plataforma") })
    }

    @Test("Studio versions scanner excludes newest version")
    func studioExcludesNewest() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Application Support/Google/AndroidStudio2023.1/config", bytes: 1024)
        try temp.file("Library/Application Support/Google/AndroidStudio2024.2/config", bytes: 1024)

        let context = temp.scanContext()
        let scanner = StudioVersionsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.allSatisfy { !$0.url.path.contains("2024.2") })
        #expect(report.candidates.contains { $0.url.path.contains("2023.1") })
    }

    @Test("Studio versions scanner includes codenames")
    func studioCodenames() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Application Support/Google/AndroidStudio2023.1/config", bytes: 1024)
        try temp.file("Library/Application Support/Google/AndroidStudio2024.2/config", bytes: 2048)

        let context = temp.scanContext()
        let scanner = StudioVersionsScanner()
        let report = await scanner.scan(in: context)

        let hedgehog = report.candidates.first { $0.url.path.contains("2023.1") }
        #expect(hedgehog != nil)
        #expect(hedgehog!.name.contains("Hedgehog"))
    }

    @Test("Studio versions scanner differentiates preferences")
    func studioPreferences() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Application Support/Google/AndroidStudio2023.1/config", bytes: 1024)
        try temp.file("Library/Preferences/AndroidStudio2023.2", bytes: 2048)
        try temp.file("Library/Application Support/Google/AndroidStudio2024.2/config", bytes: 4096)

        let context = temp.scanContext()
        let scanner = StudioVersionsScanner()
        let report = await scanner.scan(in: context)

        let prefsCandidate = report.candidates.first { $0.url.path.contains("Preferences") }
        #expect(prefsCandidate != nil)
        #expect(prefsCandidate?.name.contains("preferencias") == true)
    }

    @Test("Studio versions scanner handles cache and logs")
    func studioCacheLogs() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Caches/Google/AndroidStudio2023.1/file", bytes: 1024)
        try temp.file("Library/Logs/Google/AndroidStudio2023.2/log", bytes: 2048)
        try temp.file("Library/Application Support/Google/AndroidStudio2024.2/config", bytes: 4096)

        let context = temp.scanContext()
        let scanner = StudioVersionsScanner()
        let report = await scanner.scan(in: context)

        let cacheCandidate = report.candidates.first { $0.name.contains("Caché") && $0.url.path.contains("2023.1") }
        #expect(cacheCandidate != nil)
        #expect(cacheCandidate!.risk == .regenerates)

        let logCandidate = report.candidates.first { $0.name.contains("Logs") && $0.url.path.contains("2023.2") }
        #expect(logCandidate != nil)
        #expect(logCandidate!.risk == .regenerates)
    }

    @Test("Studio versions scanner ignores preview versions in newest check")
    func studioPreviewIgnored() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Application Support/Google/AndroidStudio2024.2/config", bytes: 1024)
        try temp.file("Library/Application Support/Google/AndroidStudioPreview2024.2/config", bytes: 2048)

        let context = temp.scanContext()
        let scanner = StudioVersionsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.isEmpty)
    }
}
