import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Flutter scanners")
struct FlutterScannersTests {
    private func project(_ temp: TempDirectory, _ rel: String, root: URL? = nil, fvm: String? = nil) throws -> FlutterProject {
        let dir = try temp.directory(rel)
        return FlutterProject(root: dir, name: dir.lastPathComponent, flutterRoot: root, fvmVersion: fvm)
    }

    @Test("projects scanner lists build and .dart_tool, disambiguating equal names")
    func projectsScanner() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let a = try project(temp, "x/app")
        let b = try project(temp, "y/app")
        let c = try project(temp, "solo")
        try temp.file("x/app/build/o.bin", bytes: 10)
        try temp.file("y/app/.dart_tool/o.bin", bytes: 20)
        try temp.file("solo/build/o.bin", bytes: 5)
        let ctx = temp.scanContext(flutter: MockFlutterProjects(list: [a, b, c]))

        let report = await FlutterProjectsScanner().scan(in: ctx)

        #expect(Set(report.candidates.map(\.name)) == ["x/app · build", "y/app · .dart_tool", "solo · build"])
        #expect(report.candidates.allSatisfy { $0.risk == .regenerates && $0.group == nil })
    }

    @Test("pub cache is a single hasCost row")
    func pubCache() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file(".pub-cache/hosted/pkg.bin", bytes: 100)

        let report = await PubCacheScanner().scan(in: temp.scanContext())

        #expect(report.candidates.count == 1)
        #expect(report.candidates.first?.risk == .hasCost)
        #expect(report.candidates.first?.url.lastPathComponent == ".pub-cache")
    }

    @Test("pub cache absent gives empty report")
    func pubCacheAbsent() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let report = await PubCacheScanner().scan(in: temp.scanContext())

        #expect(report.candidates.isEmpty)
    }

    @Test("sdk cache finds home and project SDKs, dedupes, excludes fvm")
    func sdkCache() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("flutter/bin/flutter", bytes: 1)
        try temp.file("flutter/bin/cache/a.bin", bytes: 50)
        try Data("3.22.0\n".utf8).write(to: temp.file("flutter/version"))
        try temp.file("custom/sdk/bin/flutter", bytes: 1)
        try temp.file("custom/sdk/bin/cache/a.bin", bytes: 40)
        try temp.file("fvm/versions/3.19.0/bin/flutter", bytes: 1)
        try temp.file("fvm/versions/3.19.0/bin/cache/a.bin", bytes: 30)
        let projects = [
            try project(temp, "p1", root: temp.url.appending(path: "flutter")),
            try project(temp, "p2", root: temp.url.appending(path: "custom/sdk")),
            try project(temp, "p3", root: temp.url.appending(path: "fvm/versions/3.19.0")),
        ]
        let ctx = temp.scanContext(flutter: MockFlutterProjects(list: projects))

        let report = await FlutterSdkCacheScanner(extraRoots: []).scan(in: ctx)

        #expect(report.candidates.count == 2)
        #expect(report.candidates.first?.name == "Flutter 3.22.0")
        #expect(report.candidates.last?.name.hasPrefix("Flutter ") == true)
        #expect(report.candidates.allSatisfy { $0.url.path.hasSuffix("bin/cache") && $0.risk == .hasCost })
    }

    @Test("fvm not installed is not applicable")
    func fvmAbsent() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }

        let report = await FvmVersionsScanner().scan(in: temp.scanContext())

        #expect(report.isApplicable == false)
    }

    @Test("fvm versions split into used and unused")
    func fvmGroups() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("fvm/versions/3.19.0/a.bin", bytes: 10)
        try temp.file("fvm/versions/3.22.0/a.bin", bytes: 20)
        try temp.file("fvm/versions/3.24.0/a.bin", bytes: 30)
        try FileManager.default.createSymbolicLink(
            atPath: temp.url.appending(path: "fvm/default").path,
            withDestinationPath: temp.url.appending(path: "fvm/versions/3.24.0").path)
        let ctx = temp.scanContext(flutter: MockFlutterProjects(list: [try project(temp, "p", fvm: "3.19.0")]))

        let report = await FvmVersionsScanner().scan(in: ctx)
        let byName = Dictionary(uniqueKeysWithValues: report.candidates.map { ($0.name, $0) })

        #expect(report.isApplicable)
        #expect(byName["Flutter 3.19.0"]?.group == .usedByProjects)
        #expect(byName["Flutter 3.24.0"]?.group == .usedByProjects)
        #expect(byName["Flutter 3.22.0"]?.group == .unusedByProjects)
        #expect(byName["Flutter 3.22.0"]?.reason != nil)
        #expect(report.candidates.last?.group == .unusedByProjects)
    }
}
