import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Gradle scanners")
struct GradleScannersTests {
    @Test("GradleCachesScanner category")
    func gradleCachesScannerCategory() {
        let scanner = GradleCachesScanner()
        #expect(scanner.category == .gcache)
    }

    @Test("GradleCachesScanner lists subdirectories excluding modules-2")
    func gradleCachesListsSubdirectories() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/transforms-4/data.bin", bytes: 4096)
        try temp.file(".gradle/caches/8.4/data.bin", bytes: 4096)
        try temp.file(".gradle/caches/modules-2/subdir/data.bin", bytes: 4096)
        try temp.file(".gradle/caches/build-cache/data.bin", bytes: 4096)

        let scanner = GradleCachesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.id == .gcache)
        #expect(report.candidates.count == 3)
        let names = Set(report.candidates.map(\.name))
        #expect(names.contains("Gradle 8.4"))
        #expect(names.contains("transforms-4"))
        #expect(names.contains("build-cache"))
        #expect(!names.contains("modules-2"))
    }

    @Test("GradleCachesScanner regenerates risk")
    func gradleCachesRegeneratesRisk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/test-cache/file.bin", bytes: 1024)

        let scanner = GradleCachesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { $0.risk == .regenerates })
    }

    @Test("GradleCachesScanner includes native and notifications")
    func gradleCachesIncludesNativeAndNotifications() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/native/binary", bytes: 512)
        try temp.file(".gradle/notifications/notify", bytes: 256)

        let scanner = GradleCachesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        let names = Set(report.candidates.map(\.name))
        #expect(names.contains(where: { $0.contains("Binarios") }))
        #expect(names.contains(where: { $0.contains("Avisos") }))
    }

    @Test("GradleCachesScanner empty when no .gradle directory")
    func gradleCachesEmptyWhenMissing() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let scanner = GradleCachesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.isEmpty)
    }

    @Test("GradleDependenciesScanner category")
    func gradleDependenciesScannerCategory() {
        let scanner = GradleDependenciesScanner()
        #expect(scanner.category == .gdeps)
    }

    @Test("GradleDependenciesScanner lists modules-2 subdirectories")
    func gradleDependenciesListsModules2() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/modules-2/files-2.1/data.bin", bytes: 4096)
        try temp.file(".gradle/caches/modules-2/metadata-1.0/data.bin", bytes: 4096)
        try temp.file(".gradle/caches/modules-2/other-cache/data.bin", bytes: 4096)

        let scanner = GradleDependenciesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.id == .gdeps)
        #expect(report.candidates.count == 3)
        let names = Set(report.candidates.map(\.name))
        #expect(names.contains("files-2.1"))
        #expect(names.contains("metadata-1.0"))
        #expect(names.contains("other-cache"))
    }

    @Test("GradleDependenciesScanner hasCost risk")
    func gradleDependenciesHasCostRisk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/modules-2/files-2.1/file.bin", bytes: 1024)

        let scanner = GradleDependenciesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { $0.risk == .hasCost })
    }

    @Test("GradleDependenciesScanner cost contains tilde")
    func gradleDependenciesCostContainsTilde() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/modules-2/files-2.1/file.bin", bytes: 1_000_000)

        let scanner = GradleDependenciesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { candidate in
            guard let cost = candidate.cost else { return false }
            return cost.contains("~")
        })
    }

    @Test("GradleDependenciesScanner specific cost messages")
    func gradleDependenciesSpecificCostMessages() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/caches/modules-2/files-2.1/f1", bytes: 1_000_000)
        try temp.file(".gradle/caches/modules-2/metadata-1.0/f2", bytes: 1_000_000)
        try temp.file(".gradle/caches/modules-2/other/f3", bytes: 1_000_000)

        let scanner = GradleDependenciesScanner()
        let report = await scanner.scan(in: temp.scanContext())

        let byName = Dictionary(uniqueKeysWithValues: report.candidates.map { ($0.name, $0.cost ?? "") })

        #expect(byName["files-2.1"]?.contains("volverá a descargar") ?? false)
        #expect(byName["metadata-1.0"]?.contains("Se reconstruye") ?? false)
        #expect(byName["other"]?.contains("reconstruye") ?? false)
    }

    @Test("GradleVersionsScanner category")
    func gradleVersionsScannerCategory() {
        let scanner = GradleVersionsScanner()
        #expect(scanner.category == .gvers)
    }

    @Test("GradleVersionsScanner lists wrapper dists")
    func gradleVersionsListsWrapperDists() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/wrapper/dists/gradle-8.4-bin/abc/data.bin", bytes: 4096)
        try temp.file(".gradle/wrapper/dists/gradle-7.6-all/def/data.bin", bytes: 4096)

        let scanner = GradleVersionsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.id == .gvers)
        #expect(report.candidates.count == 2)
        let names = Set(report.candidates.map(\.name))
        #expect(names.contains("Gradle 8.4"))
        #expect(names.contains("Gradle 7.6"))
    }

    @Test("GradleVersionsScanner hasCost risk")
    func gradleVersionsHasCostRisk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/wrapper/dists/gradle-8.4-bin/x/file.zip", bytes: 1024)

        let scanner = GradleVersionsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { $0.risk == .hasCost })
    }

    @Test("GradleVersionsScanner cost contains tilde")
    func gradleVersionsCostContainsTilde() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/wrapper/dists/gradle-8.4-bin/x/file.zip", bytes: 1_000_000)

        let scanner = GradleVersionsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { candidate in
            guard let cost = candidate.cost else { return false }
            return cost.contains("~") && cost.contains("próxima")
        })
    }

    @Test("GradleJdksScanner category")
    func gradleJdksScannerCategory() {
        let scanner = GradleJdksScanner()
        #expect(scanner.category == .jdks)
    }

    @Test("GradleJdksScanner lists subdirectories")
    func gradleJdksListsSubdirectories() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/jdks/jdk-17/data.bin", bytes: 4096)
        try temp.file(".gradle/jdks/jdk-11/data.bin", bytes: 4096)

        let scanner = GradleJdksScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.id == .jdks)
        #expect(report.candidates.count == 2)
        let names = Set(report.candidates.map(\.name))
        #expect(names.contains("jdk-17"))
        #expect(names.contains("jdk-11"))
    }

    @Test("GradleJdksScanner hasCost risk")
    func gradleJdksHasCostRisk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/jdks/jdk-17/bin/java", bytes: 1024)

        let scanner = GradleJdksScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { $0.risk == .hasCost })
    }

    @Test("GradleJdksScanner cost contains tilde")
    func gradleJdksCostContainsTilde() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/jdks/jdk-17/bin/java", bytes: 1_000_000)

        let scanner = GradleJdksScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { candidate in
            guard let cost = candidate.cost else { return false }
            return cost.contains("~") && cost.contains("volverá a descargar")
        })
    }

    @Test("GradleLogsScanner category")
    func gradleLogsScannerCategory() {
        let scanner = GradleLogsScanner()
        #expect(scanner.category == .glogs)
    }

    @Test("GradleLogsScanner lists daemon and kotlin daemon paths")
    func gradleLogsListsDaemonPaths() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/daemon/gc.log", bytes: 512)
        try temp.file(".kotlin/daemon/log.txt", bytes: 256)

        let scanner = GradleLogsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.id == .glogs)
        #expect(report.candidates.count >= 2)
        let names = Set(report.candidates.map(\.name))
        #expect(names.contains(where: { $0.contains("daemon") }))
    }

    @Test("GradleLogsScanner regenerates risk")
    func gradleLogsRegeneratesRisk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file(".gradle/daemon/gc.log", bytes: 512)

        let scanner = GradleLogsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.candidates.allSatisfy { $0.risk == .regenerates })
    }

    @Test("GradleLogsScanner includes kotlin daemon from Application Support")
    func gradleLogsIncludesAppSupportKotlinDaemon() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        try temp.file("Library/Application Support/kotlin/daemon/log", bytes: 256)

        let scanner = GradleLogsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        let names = Set(report.candidates.map(\.name))
        #expect(names.contains(where: { $0.contains("Application Support") }))
    }

    @Test("GradleLogsScanner empty when no directories exist")
    func gradleLogsEmptyWhenMissing() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let scanner = GradleLogsScanner()
        let report = await scanner.scan(in: temp.scanContext())

        #expect(report.isEmpty)
    }
}
