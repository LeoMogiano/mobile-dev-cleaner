import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("System images scanner")
struct SystemImagesScannerTests {
    private func setUp(_ temp: TempDirectory) throws {
        let sdk = "Library/Android/sdk/system-images"
        try temp.file("\(sdk)/android-34/google_apis_playstore/arm64-v8a/system.img", bytes: 80_000)
        try temp.file("\(sdk)/android-30/default/x86_64/system.img", bytes: 40_000)
        try temp.file(".android/avd/Pixel_8.ini", bytes: 0)
        try "path=\(temp.url.path)/.android/avd/Pixel_8.avd\n"
            .write(to: temp.url.appending(path: ".android/avd/Pixel_8.ini"), atomically: true, encoding: .utf8)
        try temp.directory(".android/avd/Pixel_8.avd")
        try "avd.ini.displayname=Pixel 8\nimage.sysdir.1=system-images/android-34/google_apis_playstore/arm64-v8a/\n"
            .write(to: temp.url.appending(path: ".android/avd/Pixel_8.avd/config.ini"), atomically: true, encoding: .utf8)
    }

    @Test("groups images by emulator usage")
    func grouping() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try setUp(temp)
        let items = await SystemImagesScanner().scan(in: temp.scanContext()).candidates

        #expect(items.count == 2)
        let used = try #require(items.first { $0.group == .usedByEmulators })
        let unused = try #require(items.first { $0.group == .unusedByEmulators })
        #expect(used.isOrphan == false)
        #expect(unused.isOrphan)
        #expect(used.risk == .hasCost && unused.risk == .hasCost)
        #expect(items.first == used)
    }

    @Test("names include Android version, API and variant")
    func names() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try setUp(temp)
        let names = Set(await SystemImagesScanner().scan(in: temp.scanContext()).candidates.map(\.name))
        #expect(names == ["Android 14 · API 34 · Google Play", "Android 11 · API 30"])
    }

    @Test("cost copy names the emulators that use the image")
    func costCopy() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try setUp(temp)
        let items = await SystemImagesScanner().scan(in: temp.scanContext()).candidates
        let used = try #require(items.first { $0.group == .usedByEmulators })
        let unused = try #require(items.first { $0.group == .unusedByEmulators })
        #expect(used.cost?.hasPrefix("Pixel 8 no arrancará") == true)
        #expect(unused.cost?.hasPrefix("Ningún emulador la usa") == true)
    }
}
