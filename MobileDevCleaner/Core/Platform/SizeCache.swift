import Foundation

/// Persistent size cache, validated by the measured path's mtime.
struct SizeCache: Sendable, Codable {
    struct Entry: Codable, Sendable, Equatable {
        let size: Int64
        let mtime: Double
    }

    static let currentVersion = 1

    private(set) var version = SizeCache.currentVersion
    private(set) var entries: [String: Entry] = [:]

    static func load(from url: URL) -> SizeCache {
        guard let data = try? Data(contentsOf: url),
              let cache = try? JSONDecoder().decode(SizeCache.self, from: data),
              cache.version == currentVersion else { return SizeCache() }
        return cache
    }

    func save(to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }

    func lookup(_ path: String, mtime: Double) -> Int64? {
        guard let entry = entries[path], entry.mtime == mtime else { return nil }
        return entry.size
    }

    mutating func set(_ path: String, size: Int64, mtime: Double) {
        entries[path] = Entry(size: size, mtime: mtime)
    }

    mutating func remove(_ path: String) {
        entries[path] = nil
        let prefix = path.hasSuffix("/") ? path : path + "/"
        for key in entries.keys where key.hasPrefix(prefix) { entries[key] = nil }
    }

    mutating func removeAll() { entries.removeAll() }
}
