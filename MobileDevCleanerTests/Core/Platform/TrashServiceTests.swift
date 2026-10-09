import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("TrashService")
struct TrashServiceTests {
    @Test("moveToTrash moves file to Trash")
    func moveToTrashSuccess() async throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let fileURL = try tempDir.file("test.txt", bytes: 100)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let service = TrashService()
        let trashedURL = try await service.moveToTrash(fileURL)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        #expect(trashedURL != nil)

        if let trashedURL {
            try? FileManager.default.removeItem(at: trashedURL)
        }
    }

    @Test("moveToTrash returns nil for nonexistent path")
    func moveToTrashNonexistent() async throws {
        let nonexistent = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString)", directoryHint: .notDirectory)

        let service = TrashService()
        let result = try await service.moveToTrash(nonexistent)

        #expect(result == nil)
    }

    @Test("remove permanently deletes file")
    func removeSuccess() async throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let fileURL = try tempDir.file("test.txt", bytes: 100)
        #expect(FileManager.default.fileExists(atPath: fileURL.path))

        let service = TrashService()
        try await service.remove(fileURL)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("remove does not throw error for nonexistent path")
    func removeNonexistent() async throws {
        let nonexistent = URL(filePath: "/tmp/nonexistent-\(UUID().uuidString)", directoryHint: .notDirectory)

        let service = TrashService()
        try await service.remove(nonexistent)
    }

    @Test("remove recursively deletes directory")
    func removeDirectory() async throws {
        let tempDir = try TempDirectory()
        defer { tempDir.remove() }

        let dirURL = try tempDir.directory("dir/subdir")
        try tempDir.file("dir/subdir/file.txt", bytes: 50)

        #expect(FileManager.default.fileExists(atPath: dirURL.path))

        let service = TrashService()
        try await service.remove(dirURL)

        #expect(!FileManager.default.fileExists(atPath: dirURL.path))
    }
}
