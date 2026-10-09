import Foundation
@testable import MobileDevCleaner

/// Isolated per-test temp directory. Never points at the real home.
struct TempDirectory: Sendable {
    let url: URL

    init(_ name: String = "mdc-tests") throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "\(name)-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// Creates a file with `bytes` of content (and any intermediate folders).
    @discardableResult
    func file(_ relativePath: String, bytes: Int = 0) throws -> URL {
        let fileURL = url.appending(path: relativePath)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data(repeating: 0x61, count: bytes))
        return fileURL
    }

    @discardableResult
    func directory(_ relativePath: String) throws -> URL {
        let dirURL = url.appending(path: relativePath, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
        return dirURL
    }

    var paths: PathProvider {
        PathProvider(home: url, systemLibrary: url.appending(path: "SystemLibrary", directoryHint: .isDirectory))
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
