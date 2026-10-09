import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("FlutterProjectFinder")
struct FlutterProjectFinderTests {
    private func finder(_ temp: TempDirectory, fda: Bool = true) -> FlutterProjectFinder {
        FlutterProjectFinder(home: temp.url, hasFullDiskAccess: { fda })
    }

    private func names(_ projects: [FlutterProject]) -> Set<String> {
        Set(projects.map(\.name))
    }

    @Test("finds nested projects and respects max depth")
    func depth() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("a/pubspec.yaml", bytes: 1)
        try temp.file("work/mono/app/pubspec.yaml", bytes: 1)
        try temp.file("1/2/3/4/ok5/pubspec.yaml", bytes: 1)
        try temp.file("1/2/3/4/5/deep6/pubspec.yaml", bytes: 1)

        let found = names(await finder(temp).projects())

        #expect(found == ["a", "app", "ok5"])
    }

    @Test("skips Library, hidden, node_modules and build folders")
    func skips() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        for dir in ["Library/x", ".hidden/x", "node_modules/x", "app/build/x", "app/ios/Pods/x", "fvm/x", "Applications/x"] {
            try temp.file("\(dir)/pubspec.yaml", bytes: 1)
        }
        try temp.file("app/pubspec.yaml", bytes: 1)

        let found = await finder(temp).projects()

        #expect(found.map(\.name) == ["app"])
    }

    @Test("does not list the packages inside a Flutter SDK")
    func skipsSdk() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("development/flutter/bin/flutter", bytes: 1)
        try temp.file("development/flutter/packages/flutter_tools/pubspec.yaml", bytes: 1)
        try temp.file("development/app/pubspec.yaml", bytes: 1)

        let found = names(await finder(temp).projects())

        #expect(found == ["app"])
    }

    @Test("skips Documents without Full Disk Access, includes it with")
    func fullDiskAccess() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("Documents/proj/pubspec.yaml", bytes: 1)
        try temp.file("code/other/pubspec.yaml", bytes: 1)

        #expect(names(await finder(temp, fda: false).projects()) == ["other"])
        #expect(names(await finder(temp, fda: true).projects()) == ["proj", "other"])
    }

    @Test("never walks home media folders")
    func mediaFolders() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        for dir in ["Music", "Movies", "Pictures", "Public"] { try temp.file("\(dir)/proj/pubspec.yaml", bytes: 1) }
        try temp.file("code/ok/pubspec.yaml", bytes: 1)

        #expect(names(await finder(temp, fda: true).projects()) == ["ok"])
    }

    @Test("parses flutterRoot and the fvm version")
    func metadata() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("p1/pubspec.yaml", bytes: 1)
        try Data(#"{"flutterRoot":"file:///opt/sdk/flutter"}"#.utf8)
            .write(to: temp.file("p1/.dart_tool/package_config.json"))
        try Data(#"{"flutter":"3.24.0"}"#.utf8).write(to: temp.file("p1/.fvmrc"))
        try temp.file("p2/pubspec.yaml", bytes: 1)
        try Data(#"{"flutterSdkVersion":"3.19.6"}"#.utf8).write(to: temp.file("p2/.fvm/fvm_config.json"))

        let found = await finder(temp).projects()
        let p1 = try #require(found.first { $0.name == "p1" })
        let p2 = try #require(found.first { $0.name == "p2" })

        #expect(p1.flutterRoot?.path == "/opt/sdk/flutter")
        #expect(p1.fvmVersion == "3.24.0")
        #expect(p2.flutterRoot == nil)
        #expect(p2.fvmVersion == "3.19.6")
    }

    @Test("reuses the walk within 10 seconds")
    func memoized() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("a/pubspec.yaml", bytes: 1)
        let sut = finder(temp)

        let first = await sut.projects()
        try temp.file("b/pubspec.yaml", bytes: 1)
        let second = await sut.projects()

        #expect(first == second)
        #expect(names(second) == ["a"])
    }
}

@Suite("FlutterProjectFinder performance", .tags(.performance), .serialized)
struct FlutterProjectFinderPerformanceTests {
    @Test("20k folders: walk < 1 s")
    func walk() async throws {
        let temp = try TempDirectory("mdc-perf-flutter")
        defer { temp.remove() }
        let fm = FileManager.default
        for a in 0..<20 {
            for b in 0..<50 {
                for c in 0..<20 {
                    try fm.createDirectory(
                        at: temp.url.appending(path: "g\(a)/h\(b)/i\(c)", directoryHint: .isDirectory),
                        withIntermediateDirectories: true)
                }
            }
        }
        try temp.file("g3/h4/i5/pubspec.yaml", bytes: 1)

        let sut = FlutterProjectFinder(home: temp.url, hasFullDiskAccess: { true })
        var found: [FlutterProject] = []
        let time = await ContinuousClock().measure { found = await sut.projects() }

        print("PERF flutterFinder=\(time)")
        #expect(found.count == 1)
        #expect(time < .seconds(1))
    }
}
