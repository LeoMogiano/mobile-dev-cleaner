import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("HistoryStore")
struct HistoryStoreTests {
    nonisolated private static func makeMockRepository() -> MockHistoryRepository {
        MockHistoryRepository()
    }

    @Test("load intent populates entries")
    @MainActor
    func loadPopulatesEntries() async {
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
        let entry = HistoryEntry(outcome: outcome)!

        let repo = MockHistoryRepository()
        await repo.setEntries([entry])

        let load = LoadHistoryUseCase(repository: repo)
        let record = RecordCleanupUseCase(repository: repo)
        let store = HistoryStore(load: load, record: record)

        store.handle(.load)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.entries.count == 1)
        #expect(store.entries[0].id == entry.id)
    }

    @Test("record adds entry to store")
    @MainActor
    func recordAddsEntry() async {
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

        let repo = MockHistoryRepository()
        let load = LoadHistoryUseCase(repository: repo)
        let record = RecordCleanupUseCase(repository: repo)
        let store = HistoryStore(load: load, record: record)

        await store.record(outcome)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.entries.count == 1)
        #expect(store.entries[0].freedBytes == 100)
    }

    @Test("totalFreed sums all freed bytes")
    @MainActor
    func totalFreedSums() async {
        let operation1 = CleanupOperation(
            id: "t1",
            category: .builds,
            name: "T1",
            size: 100,
            risk: .regenerates,
            note: nil,
            source: .candidate,
            steps: [],
            url: URL(fileURLWithPath: "/tmp")
        )
        let operation2 = CleanupOperation(
            id: "t2",
            category: .caches,
            name: "T2",
            size: 200,
            risk: .regenerates,
            note: nil,
            source: .candidate,
            steps: [],
            url: URL(fileURLWithPath: "/tmp")
        )

        let outcome1 = CleanupOutcome(
            done: [operation1],
            failures: [],
            wasCancelled: false,
            movedToTrash: true
        )
        let outcome2 = CleanupOutcome(
            done: [operation2],
            failures: [],
            wasCancelled: false,
            movedToTrash: true
        )

        let entry1 = HistoryEntry(outcome: outcome1)!
        let entry2 = HistoryEntry(outcome: outcome2)!

        let repo = MockHistoryRepository()
        await repo.setEntries([entry1, entry2])

        let load = LoadHistoryUseCase(repository: repo)
        let record = RecordCleanupUseCase(repository: repo)
        let store = HistoryStore(load: load, record: record)

        store.handle(.load)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(store.totalFreed == 300)
    }
}

private actor MockHistoryRepository: HistoryRepository {
    private var entries: [HistoryEntry] = []

    func setEntries(_ entries: [HistoryEntry]) {
        self.entries = entries
    }

    func load() async -> Either<Failure, [HistoryEntry]> {
        .right(entries)
    }

    func append(_ entry: HistoryEntry) async -> Either<Failure, [HistoryEntry]> {
        entries.insert(entry, at: 0)
        return .right(entries)
    }
}
