import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("FileChangeJournal")
struct FileChangeJournalTests {
    @Test("Reports a file written under a watched root since the given event id")
    func reportsChanges() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let root = try temp.directory("DerivedData/App-abc")
        try await Task.sleep(for: .milliseconds(300))
        let since = FileChangeJournal.currentEventID

        try temp.file("DerivedData/App-abc/Build/Products/a.o", bytes: 128)

        // fseventsd persists asynchronously; poll until the history includes the write.
        var found = false
        for _ in 0..<20 where !found {
            try await Task.sleep(for: .milliseconds(250))
            let changes = await FileChangeJournal.changes(since: since, under: [root.path])
            found = changes.isComplete && changes.paths.contains { $0.contains("App-abc") }
        }
        #expect(found)
    }

    @Test("No roots means nothing changed")
    func emptyRoots() async {
        let changes = await FileChangeJournal.changes(since: 0, under: [])
        #expect(changes == .init(paths: [], isComplete: true))
    }
}
