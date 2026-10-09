import Foundation

protocol HistoryLocalDataSource: Sendable {
    /// Empty when the file does not exist yet.
    func read() async throws -> [HistoryEntry]
    func write(_ entries: [HistoryEntry]) async throws
}

struct HistoryLocalDataSourceImpl: HistoryLocalDataSource {
    let fileURL: URL

    func read() async throws -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([HistoryEntry].self, from: data)
    }

    func write(_ entries: [HistoryEntry]) async throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
}
