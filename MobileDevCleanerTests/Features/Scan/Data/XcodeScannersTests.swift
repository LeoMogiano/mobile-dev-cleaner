import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Xcode scanners")
struct XcodeScannersTests {
    // MARK: - DerivedDataScanner

    @Test("DerivedDataScanner: sharedCache for .noindex folders")
    func derivedDataNoindex() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/Xcode/DerivedData/ModuleCache.noindex/file.txt", bytes: 1024)
        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "ModuleCache")
        #expect(candidate?.group == .sharedCache)
        #expect(candidate?.risk == .regenerates)
    }

    @Test("DerivedDataScanner: projects group for valid workspace")
    func derivedDataValidProject() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        // Create a workspace at a specific path
        try temp.directory("Projects/MyApp.xcodeproj")

        // Create DerivedData with info.plist pointing to the workspace
        let buildDir = try temp.directory("Library/Developer/Xcode/DerivedData/MyApp-abcdef12345678901234567890ab")
        var plistDict: [String: NSObject] = [:]
        let wsPath = temp.url.appending(path: "Projects/MyApp.xcodeproj").path
        plistDict["WorkspacePath"] = wsPath as NSString
        try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        ).write(to: buildDir.appending(path: "info.plist"))

        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "MyApp")
        #expect(candidate?.group == .projects)
        #expect(candidate?.isOrphan == false)
    }

    @Test("DerivedDataScanner: orphanProjects group when workspace missing")
    func derivedDataOrphanProject() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        // Create DerivedData with info.plist pointing to non-existent workspace
        let buildDir = try temp.directory("Library/Developer/Xcode/DerivedData/old-prototype-abcdefghijklmnopqrstuvwxyzab")
        var plistDict: [String: NSObject] = [:]
        plistDict["WorkspacePath"] = "/non/existent/MyApp.xcodeproj" as NSString
        try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        ).write(to: buildDir.appending(path: "info.plist"))

        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "old-prototype")
        #expect(candidate?.group == .orphanProjects)
        #expect(candidate?.isOrphan == true)
        #expect(candidate?.reason?.isEmpty == false)
    }

    @Test("DerivedDataScanner: hash stripping for orphans")
    func derivedDataHashStripping() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let buildDir = try temp.directory("Library/Developer/Xcode/DerivedData/MyProject-abcdefghijklmnopqrstuvwxyzab")
        var plistDict: [String: NSObject] = [:]
        plistDict["WorkspacePath"] = "/non/existent/MyApp.xcodeproj" as NSString
        try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        ).write(to: buildDir.appending(path: "info.plist"))

        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "MyProject")
    }

    @Test("DerivedDataScanner: name collision adds parent prefix")
    func derivedDataNameCollision() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        // Create two projects with the same name in different parent directories
        try temp.directory("Projects/web/MyApp.xcodeproj")
        try temp.directory("Projects/mobile/MyApp.xcodeproj")

        let buildDir1 = try temp.directory("Library/Developer/Xcode/DerivedData/MyApp-abcdef12345678901234567890ab")
        var plistDict1: [String: NSObject] = [:]
        plistDict1["WorkspacePath"] = temp.url.appending(path: "Projects/web/MyApp.xcodeproj").path as NSString
        try PropertyListSerialization.data(
            fromPropertyList: plistDict1,
            format: .xml,
            options: 0
        ).write(to: buildDir1.appending(path: "info.plist"))

        let buildDir2 = try temp.directory("Library/Developer/Xcode/DerivedData/MyApp-zyxwvu98765432109876543210zy")
        var plistDict2: [String: NSObject] = [:]
        plistDict2["WorkspacePath"] = temp.url.appending(path: "Projects/mobile/MyApp.xcodeproj").path as NSString
        try PropertyListSerialization.data(
            fromPropertyList: plistDict2,
            format: .xml,
            options: 0
        ).write(to: buildDir2.appending(path: "info.plist"))

        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 2)
        let names = Set(report.candidates.map { $0.name })
        #expect(names.contains("web/MyApp"))
        #expect(names.contains("mobile/MyApp"))
    }

    @Test("DerivedDataScanner: empty when no subdirs")
    func derivedDataEmpty() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let context = temp.scanContext()
        let scanner = DerivedDataScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.isEmpty)
    }

    // MARK: - XcodeCachesScanner

    @Test("XcodeCachesScanner: all cache paths included")
    func xcodeCaches() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Caches/com.apple.dt.Xcode/file.txt", bytes: 512)
        try temp.file("Library/Developer/CoreSimulator/Caches/file.txt", bytes: 512)
        try temp.file("Library/Logs/CoreSimulator/file.txt", bytes: 512)

        let context = temp.scanContext()
        let scanner = XcodeCachesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 3)
        #expect(report.candidates.allSatisfy { $0.risk == .regenerates })
    }

    @Test("XcodeCachesScanner: missing paths dropped")
    func xcodeCachesMissing() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let context = temp.scanContext()
        let scanner = XcodeCachesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.isEmpty)
    }

    // MARK: - TestResiduesScanner

    @Test("TestResiduesScanner: single item")
    func testResidues() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/XCTestDevices/file.txt", bytes: 256)
        let context = temp.scanContext()
        let scanner = TestResiduesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        #expect(report.candidates.first?.risk == .regenerates)
    }

    // MARK: - DeviceSupportScanner

    @Test("DeviceSupportScanner: device model and version naming")
    func deviceSupportDeviceModel() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/Xcode/iOS DeviceSupport/iPhone15,2 17.5 (21F79)/file.txt", bytes: 1024)
        let context = temp.scanContext()
        let scanner = DeviceSupportScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "iPhone15,2 · iOS 17.5")
    }

    @Test("DeviceSupportScanner: os version only naming")
    func deviceSupportOSVersion() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/Xcode/watchOS DeviceSupport/11.2 (22R3318)/file.txt", bytes: 512)
        let context = temp.scanContext()
        let scanner = DeviceSupportScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "watchOS 11.2")
    }

    // MARK: - ArchivesScanner

    @Test("ArchivesScanner: app name and version from plist")
    func archivesWithVersion() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let archiveDir = try temp.directory("Library/Developer/Xcode/Archives/2026-10-09/MyApp.xcarchive")
        var plistDict: [String: NSObject] = [:]
        plistDict["Name"] = "MyApp" as NSString
        var appProps: [String: NSObject] = [:]
        appProps["CFBundleShortVersionString"] = "1.2.0" as NSString
        plistDict["ApplicationProperties"] = appProps as NSObject
        try PropertyListSerialization.data(
            fromPropertyList: plistDict,
            format: .xml,
            options: 0
        ).write(to: archiveDir.appending(path: "Info.plist"))
        try temp.file("Library/Developer/Xcode/Archives/2026-10-09/MyApp.xcarchive/file.txt", bytes: 2048)

        let context = temp.scanContext()
        let scanner = ArchivesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "MyApp 1.2.0")
        #expect(candidate?.risk == .hasCost)
        #expect(candidate?.cost?.isEmpty == false)
    }

    @Test("ArchivesScanner: fallback to archive name")
    func archivesFallbackName() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/Xcode/Archives/2026-10-09/OldApp.xcarchive/file.txt", bytes: 1024)
        let context = temp.scanContext()
        let scanner = ArchivesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.name == "OldApp")
    }

    // MARK: - PreviewsScanner

    @Test("PreviewsScanner: single item with xcrun command")
    func previews() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Developer/Xcode/UserData/Previews/file.txt", bytes: 512)
        let context = temp.scanContext()
        let scanner = PreviewsScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.risk == .regenerates)
        if case .command(let executable, let arguments) = candidate?.execution {
            #expect(executable == "/usr/bin/xcrun")
            #expect(arguments.contains("simctl"))
        } else {
            Issue.record("Expected command execution strategy")
        }
    }

    // MARK: - DependencyCachesScanner

    @Test("DependencyCachesScanner: pods mix with .regenerates and .hasCost")
    func dependencyCaches() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Caches/CocoaPods/file.txt", bytes: 1024)
        try temp.file("Library/Caches/org.carthage.CarthageKit/file.txt", bytes: 512)
        try temp.file(".fastlane/file.txt", bytes: 256)
        try temp.file(".cocoapods/repos/master/file.txt", bytes: 2048)

        let context = temp.scanContext()
        let scanner = DependencyCachesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 4)
        let regenerateCounts = report.candidates.filter { $0.risk == .regenerates }.count
        let hasCostCounts = report.candidates.filter { $0.risk == .hasCost }.count
        #expect(regenerateCounts == 3)
        #expect(hasCostCounts == 1)
    }

    @Test("DependencyCachesScanner: cocoapods repos has size-dependent cost")
    func dependencyCachesPodsReposSize() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".cocoapods/repos/master/file.txt", bytes: 1_000_000_000)
        let context = temp.scanContext()
        let scanner = DependencyCachesScanner()
        let report = await scanner.scan(in: context)

        #expect(report.candidates.count == 1)
        let candidate = report.candidates.first
        #expect(candidate?.risk == .hasCost)
        #expect(candidate?.cost?.contains("~") == true)
    }
}
