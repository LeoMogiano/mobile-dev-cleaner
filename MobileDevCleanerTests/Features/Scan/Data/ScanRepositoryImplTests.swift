import Foundation
import Testing
@testable import MobileDevCleaner

private struct FakeScanner: CategoryScanner {
    let category: CategoryID
    var delay: Duration = .zero
    var size: Int64 = 1_000

    func scan(in context: ScanContext) async -> CategoryReport {
        try? await Task.sleep(for: delay)
        let url = URL(filePath: "/tmp/\(category.rawValue)")
        let candidate = CleanupCandidate(
            id: url.path, category: category, name: category.rawValue, url: url, size: size,
            risk: .regenerates, group: nil, isOrphan: false, modifiedAt: nil, reason: nil, cost: nil,
            execution: .remove(url)
        )
        return CategoryReport(id: category, candidates: [candidate])
    }
}

@Suite("ScanRepositoryImpl")
struct ScanRepositoryImplTests {
    private func collect(_ stream: AsyncStream<ScanEvent>) async -> [ScanEvent] {
        var events: [ScanEvent] = []
        for await event in stream { events.append(event) }
        return events
    }

    @Test("Emits started, each category as it finishes, then the full result")
    func emitsIncrementally() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let repository = ScanRepositoryImpl(context: temp.scanContext(), scanners: [
            FakeScanner(category: .builds, delay: .milliseconds(200)),
            FakeScanner(category: .gcache),
        ])

        let events = await collect(repository.scan(tools: [.xcode, .android]))

        guard case .started(let ids) = events.first else { Issue.record("missing start"); return }
        #expect(Set(ids) == [.builds, .gcache])
        let finishedOrder = events.compactMap { event -> CategoryID? in
            if case .categoryFinished(let report) = event { return report.id }
            return nil
        }
        #expect(finishedOrder == [.gcache, .builds])
        guard case .finished(let result) = events.last else { Issue.record("missing finish"); return }
        #expect(result.totalSize == 2_000)
    }

    @Test("Only scans categories of the requested tools")
    func filtersByTool() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let repository = ScanRepositoryImpl(context: temp.scanContext(), scanners: [
            FakeScanner(category: .builds), FakeScanner(category: .gcache),
        ])

        let events = await collect(repository.scan(tools: [.android]))

        guard case .finished(let result) = events.last else { Issue.record("missing finish"); return }
        #expect(Array(result.reports.keys) == [.gcache])
    }

    @Test("Cancelling the consumer stops the scan without a finished event")
    func cancellation() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let repository = ScanRepositoryImpl(context: temp.scanContext(), scanners: [
            FakeScanner(category: .builds, delay: .seconds(5)),
        ])

        let task = Task { await collect(repository.scan(tools: [.xcode])) }
        try await Task.sleep(for: .milliseconds(100))
        task.cancel()
        let events = await task.value

        #expect(!events.contains { if case .finished = $0 { true } else { false } })
    }
}
