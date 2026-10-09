import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("DirectoryWalker")
struct DirectoryWalkerTests {
    @Test("sums nested files by allocated size")
    func nestedFiles() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("a.bin", bytes: 10_000)
        try temp.file("sub/b.bin", bytes: 20_000)
        try temp.file("sub/deep/c.bin", bytes: 30_000)
        let size = try DirectoryWalker.allocatedSize(at: temp.url)
        #expect(size >= 60_000)
        #expect(size < 60_000 + 3 * 65_536)
    }

    @Test("does not follow symlinks")
    func symlinkNotFollowed() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let outside = try TempDirectory()
        defer { outside.remove() }
        try outside.file("big.bin", bytes: 1_000_000)
        let root = try temp.directory("root")
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "link"), withDestinationURL: outside.url)
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "filelink"), withDestinationURL: outside.url.appending(path: "big.bin"))
        #expect(try DirectoryWalker.allocatedSize(at: root) == 0)
        #expect(try DirectoryWalker.allocatedSize(at: root.appending(path: "link")) == 0)
    }

    @Test("counts a hardlink once")
    func hardlinkOnce() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let original = try temp.file("one.bin", bytes: 100_000)
        let single = try DirectoryWalker.allocatedSize(at: temp.url)
        try FileManager.default.linkItem(at: original, to: temp.url.appending(path: "two.bin"))
        try FileManager.default.createDirectory(at: temp.url.appending(path: "d"), withIntermediateDirectories: true)
        try FileManager.default.linkItem(at: original, to: temp.url.appending(path: "d/three.bin"))
        #expect(try DirectoryWalker.allocatedSize(at: temp.url) == single)
    }

    @Test("skips an unreadable subdirectory")
    func unreadableSubdirectory() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        try temp.file("ok.bin", bytes: 8_000)
        let locked = try temp.directory("locked")
        try temp.file("locked/secret.bin", bytes: 500_000)
        let before = try DirectoryWalker.allocatedSize(at: temp.url)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: locked.path)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: locked.path) }
        let after = try DirectoryWalker.allocatedSize(at: temp.url)
        #expect(after < before)
        #expect(after >= 8_000)
    }

    @Test("throws for a nonexistent path")
    func nonexistentThrows() throws {
        let missing = FileManager.default.temporaryDirectory.appending(path: "mdc-missing-\(UUID().uuidString)")
        #expect(throws: (any Error).self) { try DirectoryWalker.allocatedSize(at: missing) }
    }

    @Test("single file returns its allocated size")
    func singleFile() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let file = try temp.file("x.bin", bytes: 50_000)
        let size = try DirectoryWalker.allocatedSize(at: file)
        #expect(size >= 50_000)
        #expect(size < 50_000 + 65_536)
    }

    @Test("matches du -sk within 1%")
    func matchesDu() throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        for dir in 0..<20 {
            for file in 0..<30 {
                try temp.file("d\(dir)/s\(dir % 3)/f\(file).bin", bytes: 1_000 + file * 4_000)
            }
        }
        let walker = try DirectoryWalker.allocatedSize(at: temp.url)
        let du = try Self.duBytes(temp.url)
        let diff = abs(Double(walker - du)) / Double(du)
        #expect(diff < 0.01, "walker=\(walker) du=\(du)")
    }

    static func duBytes(_ url: URL) throws -> Int64 {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/du")
        process.arguments = ["-sk", url.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        let kb = Int64(text.split(whereSeparator: \.isWhitespace).first ?? "0") ?? 0
        return kb * 1024
    }
}
