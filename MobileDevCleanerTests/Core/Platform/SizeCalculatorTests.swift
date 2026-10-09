import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("SizeCalculator")
struct SizeCalculatorTests {
    private func cacheURL(_ temp: TempDirectory) -> URL { temp.url.appending(path: "cache/sizes.json") }

    @Test("persisted cache hit skips the walk while mtime is unchanged")
    func cacheHit() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let target = try temp.directory("target")
        try temp.file("target/a.bin", bytes: 40_000)
        let first = SizeCalculator(cacheURL: cacheURL(temp))
        let size = try await first.size(of: target)
        await first.flush()

        // In-place rewrite keeps the dir mtime, so a re-walk would give a different size.
        try Data(repeating: 1, count: 400_000).write(to: target.appending(path: "a.bin"))

        let second = SizeCalculator(cacheURL: cacheURL(temp))
        #expect(try await second.size(of: target) == size)
    }

    @Test("changing the directory mtime invalidates the cache")
    func invalidationByMtime() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let target = try temp.directory("target")
        try temp.file("target/a.bin", bytes: 40_000)
        let calc = SizeCalculator(cacheURL: cacheURL(temp))
        let before = try await calc.size(of: target)
        try temp.file("target/b.bin", bytes: 200_000)
        let past = Date(timeIntervalSinceNow: 5)
        try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: target.path)
        let after = try await calc.size(of: target)
        #expect(after > before)
    }

    @Test("invalidate forces a new measurement")
    func explicitInvalidate() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let target = try temp.directory("target")
        let file = try temp.file("target/a.bin", bytes: 40_000)
        let calc = SizeCalculator(cacheURL: nil)
        let before = try await calc.size(of: target)
        try Data(repeating: 1, count: 400_000).write(to: file)
        #expect(try await calc.size(of: target) == before)
        await calc.invalidate([target])
        #expect(try await calc.size(of: target) > before)
    }

    @Test("sizes(of:) omits missing paths")
    func sizesSkipsMissing() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let present = try temp.directory("present")
        try temp.file("present/a.bin", bytes: 10_000)
        let missing = temp.url.appending(path: "missing")
        let calc = SizeCalculator(cacheURL: nil, maxConcurrency: 2)
        let result = await calc.sizes(of: [present, missing])
        #expect(result.count == 1)
        #expect(result[present] != nil)
    }

    @Test("flush writes the file and cacheFootprint reflects it")
    func flushWritesFile() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let target = try temp.directory("target")
        try temp.file("target/a.bin", bytes: 10_000)
        let url = cacheURL(temp)
        let calc = SizeCalculator(cacheURL: url)
        #expect(await calc.cacheFootprint() == 0)
        _ = try await calc.size(of: target)
        await calc.flush()
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(await calc.cacheFootprint() > 0)
    }

    @Test("clearCache removes memory and file")
    func clearCache() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let target = try temp.directory("target")
        try temp.file("target/a.bin", bytes: 10_000)
        let url = cacheURL(temp)
        let calc = SizeCalculator(cacheURL: url)
        _ = try await calc.size(of: target)
        await calc.flush()
        await calc.clearCache()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(await calc.cacheFootprint() == 0)
    }

    @Test("SizeCache remove also drops descendants")
    func cachePrefixRemove() {
        var cache = SizeCache()
        cache.set("/a/b", size: 1, mtime: 1)
        cache.set("/a/b/c", size: 2, mtime: 1)
        cache.set("/a/bc", size: 3, mtime: 1)
        cache.remove("/a/b")
        #expect(cache.lookup("/a/b", mtime: 1) == nil)
        #expect(cache.lookup("/a/b/c", mtime: 1) == nil)
        #expect(cache.lookup("/a/bc", mtime: 1) == 3)
    }

    @Test("SizeCache corrupt file yields empty cache")
    func corruptCache() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let file = try temp.file("bad.json", bytes: 0)
        try Data("{no json".utf8).write(to: file)
        #expect(SizeCache.load(from: file).entries.isEmpty)
    }
}
