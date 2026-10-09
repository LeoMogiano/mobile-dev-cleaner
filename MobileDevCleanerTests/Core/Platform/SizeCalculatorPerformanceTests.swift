import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("SizeCalculator performance", .tags(.performance), .serialized)
struct SizeCalculatorPerformanceTests {
    @Test("50k files: cold walk < 1.5 s, cached < 50 ms")
    func coldAndCached() async throws {
        let temp = try TempDirectory("mdc-perf")
        defer { temp.remove() }
        let root = try temp.directory("fixture")
        let fm = FileManager.default
        let payload = Data(repeating: 0x61, count: 512)
        for d in 0..<2_000 {
            let dir = root.appending(path: "d\(d / 20)/s\(d)", directoryHint: .isDirectory)
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            for f in 0..<25 { try payload.write(to: dir.appending(path: "f\(f).dat")) }
        }

        let calc = SizeCalculator(cacheURL: temp.url.appending(path: "cache.json"))
        let clock = ContinuousClock()
        var size: Int64 = 0
        let cold = try await clock.measure { size = try await calc.size(of: root) }
        let cached = try await clock.measure { _ = try await calc.size(of: root) }
        let duStart = clock.now
        let du = try DirectoryWalkerTests.duBytes(root)
        let duTime = clock.now - duStart

        print("PERF walker cold=\(cold) cached=\(cached) du=\(duTime) size=\(size) duSize=\(du)")
        #expect(size > 0)
        #expect(cold < .milliseconds(1500))
        #expect(cached < .milliseconds(50))
    }
}

extension Tag {
    @Tag static var performance: Self
}
