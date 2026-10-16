import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Simulators scanner")
struct SimulatorsScannerTests {
    private let udid = "AAAA-1111"
    private let runtime = "com.apple.CoreSimulator.SimRuntime.iOS-18-2"

    private func devicesJSON(udid: String, state: String = "Booted", available: Bool = true, type: String = "iPhone-16") -> String {
        """
        {"devices":{"\(runtime)":[{"udid":"\(udid)","name":"iPhone 16","state":"\(state)","isAvailable":\(available),
        "deviceTypeIdentifier":"com.apple.CoreSimulator.SimDeviceType.\(type)"}],
        "com.apple.CoreSimulator.SimRuntime.tvOS-17-0":[]}}
        """
    }

    private func runner(_ json: String, exit: Int32 = 0) -> MockProcessRunner {
        MockProcessRunner { _, args in
            ProcessResult(exitCode: exit, stdout: args.contains("devices") ? json : "", stderr: "")
        }
    }

    private func makeDevice(_ temp: TempDirectory) throws {
        try temp.file("Library/Developer/CoreSimulator/Devices/\(udid)/device.plist", bytes: 20_000)
        let data = "Library/Developer/CoreSimulator/Devices/\(udid)/data"
        try temp.file("\(data)/Documents/user.db", bytes: 100_000)
        try temp.file("\(data)/Library/Caches/c.bin", bytes: 40_000)
        try temp.file("\(data)/Library/Logs/l.log", bytes: 8_000)
        try temp.file("\(data)/Containers/Data/Application/APP1/Library/Caches/c.bin", bytes: 30_000)
        try temp.file("\(data)/Containers/Data/Application/APP1/tmp/t.bin", bytes: 10_000)
        try temp.file("\(data)/Containers/Data/Application/APP1/Library/SplashBoard/Snapshots/s.ktx", bytes: 50_000)
    }

    @Test("breakdown adds up and plans are built")
    func breakdownAndPlans() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeDevice(temp)
        let context = temp.scanContext(runner: runner(devicesJSON(udid: udid)))

        let report = await SimulatorsScanner().scan(in: context)
        let device = try #require(report.devices.first)
        let dir = temp.paths.coreSimulatorDevices.appending(path: udid)
        let total = try await context.sizes.size(of: dir)

        #expect(device.id == udid)
        #expect(device.osVersion == "iOS 18.2")
        #expect(device.kind == .iphone)
        #expect(device.sizes.total == total)
        #expect(device.sizes.cache > 0)
        #expect(device.sizes.snapshots > 0)
        #expect(device.sizes.data > 0)
        #expect(device.sizes.other > 0)

        let clean = try #require(device.plan(for: .clean))
        #expect(clean.risk == .regenerates)
        #expect(clean.freedBytes == device.sizes.cache + device.sizes.snapshots)
        #expect(clean.steps.count == 5)
        let reset = try #require(device.plan(for: .reset))
        #expect(reset.risk == .hasCost)
        #expect(reset.steps == [.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "erase", udid])])
        #expect(reset.freedBytes == device.sizes.data + device.sizes.cache + device.sizes.snapshots)
        let delete = try #require(device.plan(for: .delete))
        #expect(delete.steps == [.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", udid])])
        #expect(delete.freedBytes == device.sizes.total)
    }

    @Test("booted state marks the device as running")
    func bootedIsRunning() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeDevice(temp)
        let booted = await SimulatorsScanner().scan(in: temp.scanContext(runner: runner(devicesJSON(udid: udid))))
        let shutdown = await SimulatorsScanner().scan(in: temp.scanContext(runner: runner(devicesJSON(udid: udid, state: "Shutdown"))))
        #expect(booted.devices.first?.isRunning == true)
        #expect(shutdown.devices.first?.isRunning == false)
    }

    @Test("unavailable device gets a suffix and kind follows the type")
    func unavailableName() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeDevice(temp)
        let json = devicesJSON(udid: udid, available: false, type: "iPad-Pro")
        let device = try #require(await SimulatorsScanner().scan(in: temp.scanContext(runner: runner(json))).devices.first)
        #expect(device.name.hasPrefix("iPhone 16 ("))
        #expect(device.isAvailable == false)
        #expect(device.kind == .ipad)
    }

    @Test("devices without a folder are skipped")
    func missingFolder() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let report = await SimulatorsScanner().scan(in: temp.scanContext(runner: runner(devicesJSON(udid: udid))))
        #expect(report.devices.isEmpty)
    }

    @Test("CLI failure or bad JSON yields an empty report")
    func cliFailure() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeDevice(temp)
        let failed = await SimulatorsScanner().scan(in: temp.scanContext(runner: runner("", exit: 1)))
        let garbage = await SimulatorsScanner().scan(in: temp.scanContext(runner: runner("not json")))
        let thrown = await SimulatorsScanner().scan(in: temp.scanContext(runner: MockProcessRunner { _, _ in
            throw ProcessRunnerError.executableNotFound("xcrun")
        }))
        #expect(failed.isEmpty && garbage.isEmpty && thrown.isEmpty)
    }

    @Test("runtime id maps to a readable OS version")
    func osVersionParsing() {
        #expect(SimulatorsScanner.osVersion(fromRuntime: "com.apple.CoreSimulator.SimRuntime.watchOS-11-0") == "watchOS 11.0")
    }
}

@Suite("Previews scanner")
struct PreviewsScannerTests {
    @Test("empty folder with xcrun command prepared")
    func previewsEmpty() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let context = temp.scanContext()
        let report = await PreviewsScanner().scan(in: context)
        #expect(report.candidates.isEmpty)
    }

    /// xcrun only runs at cleanup time; a broken toolchain shows up as a cleanup failure instead.
    @Test("previews are listed even when xcrun fails")
    func previewsXcrunFailure() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("Library/Developer/Xcode/UserData/Previews/data.bin", bytes: 512)
        let failed = await PreviewsScanner().scan(in: temp.scanContext(runner: MockProcessRunner { _, _ in
            ProcessResult(exitCode: 1, stdout: "", stderr: "")
        }))
        #expect(failed.candidates.count == 1)
    }
}
