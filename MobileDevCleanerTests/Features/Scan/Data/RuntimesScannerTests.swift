import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Runtimes scanner")
struct RuntimesScannerTests {
    private struct Installed {
        let id: String
        let platform: String
        let version: String

        var runtimeIdentifier: String {
            "com.apple.CoreSimulator.SimRuntime.\(platform)-\(version.replacingOccurrences(of: ".", with: "-"))"
        }
    }

    private struct Device {
        let udid: String
        let name: String
        let runtime: String
        var state = "Shutdown"
    }

    private func runtimesJSON(_ runtimes: [Installed], root: URL) -> String {
        let entries = runtimes.map { runtime in
            """
            "\(runtime.id)":{"identifier":"\(runtime.id)","runtimeIdentifier":"\(runtime.runtimeIdentifier)",
            "version":"\(runtime.version)","deletable":true,"path":"\(root.appending(path: runtime.id).path)"}
            """
        }
        return "{\(entries.joined(separator: ","))}"
    }

    private func devicesJSON(_ devices: [Device]) -> String {
        let byRuntime = Dictionary(grouping: devices, by: \.runtime).map { runtime, list in
            let items = list.map { #"{"udid":"\#($0.udid)","name":"\#($0.name)","state":"\#($0.state)","isAvailable":true}"# }
            return "\"\(runtime)\":[\(items.joined(separator: ","))]"
        }
        return "{\"devices\":{\(byRuntime.joined(separator: ","))}}"
    }

    private func scan(_ runtimes: [Installed], devices: [Device] = []) async throws -> (CategoryReport, TempDirectory) {
        let temp = try TempDirectory()
        let root = temp.paths.systemRuntimes
        for runtime in runtimes {
            try temp.file("SystemLibrary/Developer/CoreSimulator/Profiles/Runtimes/\(runtime.id)/image.bin", bytes: 10_000)
        }
        let runtimeOutput = runtimesJSON(runtimes, root: root)
        let deviceOutput = devicesJSON(devices)
        let runner = MockProcessRunner { _, args in
            ProcessResult(exitCode: 0, stdout: args.contains("runtime") ? runtimeOutput : deviceOutput, stderr: "")
        }
        let report = await RuntimesScanner().scan(in: temp.scanContext(runner: runner))
        return (report, temp)
    }

    private let ios16 = Installed(id: "R16", platform: "iOS", version: "16.4")
    private let ios17 = Installed(id: "R17", platform: "iOS", version: "17.5")
    private let ios18 = Installed(id: "R18", platform: "iOS", version: "18.2")
    private let watch10 = Installed(id: "W10", platform: "watchOS", version: "10.5")

    @Test("keeps the two newest versions per platform out of the suggested group")
    func groupsByRecency() async throws {
        let (report, temp) = try await scan([ios16, ios17, ios18, watch10])
        defer { temp.remove() }

        let older = report.candidates.filter { $0.group == .olderRuntimes }.map(\.name)
        let latest = Set(report.candidates.filter { $0.group == .latestRuntimes }.map(\.name))
        #expect(older == ["iOS 16.4 Runtime"])
        #expect(latest == ["iOS 17.5 Runtime", "iOS 18.2 Runtime", "watchOS 10.5 Runtime"])
        #expect(report.candidates.first?.group == .olderRuntimes)
    }

    @Test("compares versions numerically")
    func numericVersions() async throws {
        let ios9 = Installed(id: "R9", platform: "iOS", version: "9.3")
        let ios10 = Installed(id: "R10", platform: "iOS", version: "10.0")
        let (report, temp) = try await scan([ios9, ios10, ios16])
        defer { temp.remove() }

        #expect(report.candidates.filter { $0.group == .olderRuntimes }.map(\.name) == ["iOS 9.3 Runtime"])
    }

    @Test("runtime with simulators is listed and deletes them first")
    func deletesSimulatorsFirst() async throws {
        let devices = [
            Device(udid: "D1", name: "iPhone 15", runtime: ios16.runtimeIdentifier),
            Device(udid: "D2", name: "iPad Air", runtime: ios16.runtimeIdentifier),
        ]
        let (report, temp) = try await scan([ios16], devices: devices)
        defer { temp.remove() }

        let candidate = try #require(report.candidates.first)
        #expect(candidate.steps == [
            .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", "D1"]),
            .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", "D2"]),
            .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", "R16"]),
        ])
        #expect(candidate.cost?.contains("iPhone 15, iPad Air") == true)
        #expect(candidate.reason?.contains("2") == true)
    }

    @Test("runtime without simulators only deletes itself")
    func unusedRuntime() async throws {
        let (report, temp) = try await scan([ios16])
        defer { temp.remove() }

        let candidate = try #require(report.candidates.first)
        #expect(candidate.prerequisites.isEmpty)
        #expect(candidate.steps == [.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", "R16"])])
    }

    @Test("runtime with a booted simulator is hidden")
    func bootedHidden() async throws {
        let devices = [Device(udid: "D1", name: "iPhone 15", runtime: ios16.runtimeIdentifier, state: "Booted")]
        let (report, temp) = try await scan([ios16, ios17], devices: devices)
        defer { temp.remove() }

        #expect(report.candidates.map(\.name) == ["iOS 17.5 Runtime"])
    }
}

@Suite("Runtimes scanner parsing")
struct RuntimesScannerParsingTests {
    private func runtimeJSON(path: String, deletable: Bool = true, size: Int = 2_000_000_000) -> String {
        """
        {"UUID-1":{"identifier":"UUID-1","version":"17.0","runtimeIdentifier":"com.apple.CoreSimulator.SimRuntime.iOS-17-0",
        "platformIdentifier":"com.apple.platform.iphonesimulator","path":"\(path)","sizeBytes":\(size),"deletable":\(deletable)},
        "UUID-2":{"identifier":"UUID-2","version":"16.4","runtimeIdentifier":"com.apple.CoreSimulator.SimRuntime.iOS-16-4",
        "path":"\(path)-used","sizeBytes":1000,"deletable":true}}
        """
    }

    private func runner(runtimes: String, used: String = "com.apple.CoreSimulator.SimRuntime.iOS-16-4") -> MockProcessRunner {
        MockProcessRunner { _, args in
            if args.contains("runtime") { return ProcessResult(exitCode: 0, stdout: runtimes, stderr: "") }
            let devices = "{\"devices\":{\"\(used)\":[{\"udid\":\"X\",\"name\":\"n\",\"state\":\"Shutdown\",\"isAvailable\":true}]}}"
            return ProcessResult(exitCode: 0, stdout: devices, stderr: "")
        }
    }

    @Test("lists deletable runtimes, including those used by devices")
    func listsUnused() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let dir = try temp.file("rt/iOS_17/image.bin", bytes: 50_000).deletingLastPathComponent()
        let context = temp.scanContext(runner: runner(runtimes: runtimeJSON(path: dir.path)))

        let report = await RuntimesScanner().scan(in: context)
        let item = try #require(report.candidates.first { $0.id == dir.path })
        #expect(report.candidates.count == 2)
        #expect(item.name == "iOS 17.0 Runtime")
        #expect(item.risk == .hasCost)
        #expect(item.size > 0 && item.size < 2_000_000_000)
        #expect(item.execution == .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", "UUID-1"]))
        #expect(item.cost?.contains("iOS 17.0") == true)
    }

    @Test("non-deletable runtimes are excluded")
    func skipsNonDeletable() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let context = temp.scanContext(runner: runner(runtimes: runtimeJSON(path: "/nonexistent", deletable: false)))
        #expect(await RuntimesScanner().scan(in: context).candidates.map(\.name) == ["iOS 16.4 Runtime"])
    }

    @Test("falls back to json sizeBytes when the path cannot be measured")
    func sizeFallback() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let context = temp.scanContext(runner: runner(runtimes: runtimeJSON(path: temp.url.appending(path: "gone").path)))
        let candidates = await RuntimesScanner().scan(in: context).candidates
        #expect(candidates.first { $0.name == "iOS 17.0 Runtime" }?.size == 2_000_000_000)
    }

    @Test("xcrun failure yields empty report")
    func xcrunFailure() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let failed = await RuntimesScanner().scan(in: temp.scanContext(runner: MockProcessRunner { _, _ in
            ProcessResult(exitCode: 1, stdout: "", stderr: "xcrun: error")
        }))
        let timeout = await RuntimesScanner().scan(in: temp.scanContext(runner: MockProcessRunner { _, _ in
            throw ProcessRunnerError.timedOut(executable: "xcrun", after: .seconds(30))
        }))
        #expect(failed.isEmpty && timeout.isEmpty)
    }
}
