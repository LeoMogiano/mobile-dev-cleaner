import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Emulators scanner")
struct EmulatorsScannerTests {
    private func makeAVD(_ temp: TempDirectory, name: String = "Pixel_8_API_34", extra: String = "") throws {
        try temp.directory(".android/avd/\(name).avd")
        try "avd.ini.encoding=UTF-8\npath=\(temp.url.path)/.android/avd/\(name).avd\n"
            .write(to: temp.url.appending(path: ".android/avd/\(name).ini"), atomically: true, encoding: .utf8)
        let config = "avd.ini.displayname=\(name)\nhw.device.name=pixel_8\nimage.sysdir.1=system-images/android-34/google_apis_playstore/arm64-v8a/\n\(extra)"
        try config.write(to: temp.url.appending(path: ".android/avd/\(name).avd/config.ini"), atomically: true, encoding: .utf8)
        try temp.file(".android/avd/\(name).avd/userdata-qemu.img", bytes: 200_000)
        try temp.file(".android/avd/\(name).avd/sdcard.img", bytes: 60_000)
        try temp.file(".android/avd/\(name).avd/cache.img", bytes: 40_000)
        try temp.file(".android/avd/\(name).avd/snapshots/default_boot/ram.bin", bytes: 80_000)
        try temp.file(".android/avd/\(name).avd/system.img", bytes: 30_000)
    }

    @Test("parseINI reads key=value pairs and skips comments")
    func parseINI() {
        let values = AVDConfigReader.parseINI("# c\nkey = value\npath=/a=b\n\nbad line\n")
        #expect(values == ["key": "value", "path": "/a=b"])
    }

    @Test("reads config and derives API from the system image")
    func readsConfig() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp)
        let config = try #require(AVDConfigReader.read(in: temp.scanContext()).first)
        #expect(config.name == "Pixel_8_API_34")
        #expect(config.apiLevel == 34)
        #expect(config.systemImagePath == "system-images/android-34/google_apis_playstore/arm64-v8a/")
        #expect(config.url.lastPathComponent == "Pixel_8_API_34.avd")
    }

    @Test("sizes are split into data, cache, snapshots and other")
    func sizes() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp)
        let context = temp.scanContext()
        let device = try #require(await EmulatorsScanner().scan(in: context).devices.first)
        let total = try await context.sizes.size(of: device.url)

        #expect(device.name == "Pixel 8 API 34")
        #expect(device.osVersion == "API 34 · Android 14")
        #expect(device.kind == .phone)
        #expect(device.sizes.data > 0 && device.sizes.cache > 0 && device.sizes.snapshots > 0 && device.sizes.other > 0)
        #expect(device.sizes.total == total)
        let clean = try #require(device.plan(for: .clean))
        #expect(clean.steps.count == 2)
        #expect(clean.freedBytes == device.sizes.cache + device.sizes.snapshots)
        #expect(device.plan(for: .reset)?.steps.count == 2)
    }

    @Test("tablet is detected from the device name")
    func tablet() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp, name: "Pixel_Tablet_API_33")
        let device = try #require(await EmulatorsScanner().scan(in: temp.scanContext()).devices.first)
        #expect(device.kind == .tablet)
    }

    @Test("running AVDs come from the probe")
    func running() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp)
        let probe = MockProcessProbe(result: RunningApps(apps: [.androidEmulator], runningAVDs: ["Pixel_8_API_34"]))
        let device = try #require(await EmulatorsScanner().scan(in: temp.scanContext(probe: probe)).devices.first)
        #expect(device.isRunning)
    }

    @Test("delete falls back to removing the folder and ini without avdmanager")
    func deleteFallback() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp)
        let device = try #require(await EmulatorsScanner().scan(in: temp.scanContext()).devices.first)
        let steps = try #require(device.plan(for: .delete)).steps
        #expect(steps == [.remove(device.url), .remove(temp.paths.avd.appending(path: "Pixel_8_API_34.ini"))])
    }

    @Test("delete uses avdmanager when installed")
    func deleteWithAvdmanager() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try makeAVD(temp)
        let tool = try temp.file("Library/Android/sdk/cmdline-tools/latest/bin/avdmanager", bytes: 1)
        let device = try #require(await EmulatorsScanner().scan(in: temp.scanContext()).devices.first)
        #expect(device.plan(for: .delete)?.steps == [.command(executable: tool.path, arguments: ["delete", "avd", "-n", "Pixel_8_API_34"])])
    }
}
