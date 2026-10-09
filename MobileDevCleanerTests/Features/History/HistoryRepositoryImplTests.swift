import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("HistoryRepositoryImpl")
struct HistoryRepositoryImplTests {
    @Test("file does not exist returns empty")
    func nonExistentFileReturnsEmpty() async {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
        let dataSource = HistoryLocalDataSourceImpl(fileURL: tempURL)
        let repo = HistoryRepositoryImpl(dataSource: dataSource)

        let result = await repo.load()
        #expect(result.isRight)
        #expect(result.rightValue?.isEmpty ?? false)
    }

    @Test("append persists and reads back")
    func appendPersists() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("history.json")

        let dataSource = HistoryLocalDataSourceImpl(fileURL: fileURL)
        let repo1 = HistoryRepositoryImpl(dataSource: dataSource)

        let operation = CleanupOperation(
            id: "test1",
            category: .builds,
            name: "Test",
            size: 100,
            risk: .regenerates,
            note: nil,
            source: .candidate,
            steps: [],
            url: URL(fileURLWithPath: "/tmp")
        )
        let outcome = CleanupOutcome(
            done: [operation],
            failures: [],
            wasCancelled: false,
            movedToTrash: true
        )
        let entry = HistoryEntry(outcome: outcome, date: Date(timeIntervalSince1970: 0))!

        let appendResult = await repo1.append(entry)
        let appendedEntries = try #require(appendResult.rightValue)
        #expect(appendedEntries.count == 1)
        #expect(appendedEntries[0].id == entry.id)

        let repo2 = HistoryRepositoryImpl(dataSource: dataSource)
        let loadResult = await repo2.load()
        let loadedEntries = try #require(loadResult.rightValue)
        #expect(loadedEntries.count == 1)
        #expect(loadedEntries[0].id == entry.id)
    }

    @Test("newest first ordering")
    func newestFirst() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("history.json")

        let dataSource = HistoryLocalDataSourceImpl(fileURL: fileURL)
        let repo = HistoryRepositoryImpl(dataSource: dataSource)

        let operation = CleanupOperation(
            id: "test",
            category: .builds,
            name: "Test",
            size: 100,
            risk: .regenerates,
            note: nil,
            source: .candidate,
            steps: [],
            url: URL(fileURLWithPath: "/tmp")
        )
        let outcome = CleanupOutcome(
            done: [operation],
            failures: [],
            wasCancelled: false,
            movedToTrash: true
        )

        let date1 = Date(timeIntervalSince1970: 0)
        let date2 = Date(timeIntervalSince1970: 1000)
        let entry1 = HistoryEntry(outcome: outcome, date: date1)!
        let entry2 = HistoryEntry(outcome: outcome, date: date2)!

        _ = await repo.append(entry1)
        let result = await repo.append(entry2)
        #expect(result.isRight)
        let entries = result.rightValue ?? []

        #expect(entries.count == 2)
        #expect(entries[0].date == date2)
        #expect(entries[1].date == date1)
    }

    @Test("corrupted JSON returns left")
    func corruptedJSON() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("history.json")

        try "invalid json".write(to: fileURL, atomically: true, encoding: .utf8)

        let dataSource = HistoryLocalDataSourceImpl(fileURL: fileURL)
        let repo = HistoryRepositoryImpl(dataSource: dataSource)

        let result = await repo.load()
        #expect(result.leftValue != nil)
    }
}
