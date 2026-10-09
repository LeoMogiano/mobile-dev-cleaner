import Foundation
import Testing
@testable import MobileDevCleaner

private struct FakeScanRepository: ScanRepository {
    let events: @Sendable () -> AsyncStream<ScanEvent>

    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> { events() }
    func invalidateSizes(of urls: [URL]) async {}
}

@Suite("ScanStore")
@MainActor
struct ScanStoreTests {
    private func report(_ id: CategoryID, bytes: Int64) -> CategoryReport {
        CategoryReport(id: id, candidates: [CleanupCandidate(
            id: "\(id.rawValue)-1", category: id, name: "x", url: URL(fileURLWithPath: "/tmp/\(id.rawValue)"),
            size: bytes, risk: .regenerates, group: nil, isOrphan: false, modifiedAt: nil, reason: nil, cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/\(id.rawValue)"))
        )])
    }

    private func store(_ events: @escaping @Sendable () -> AsyncStream<ScanEvent>) -> ScanStore {
        ScanStore(
            scan: ScanUseCase(repository: FakeScanRepository(events: events)),
            flushInterval: .milliseconds(20)
        )
    }

    @Test("scan runs to finished with every report applied")
    func finishesWithAllReports() async {
        let ids = CategoryID.allCases
        let sut = store {
            AsyncStream { continuation in
                continuation.yield(.started(ids))
                var all: [CategoryID: CategoryReport] = [:]
                for id in ids {
                    let r = CategoryReport(id: id, candidates: [CleanupCandidate(
            id: "\(id.rawValue)-1", category: id, name: "x", url: URL(fileURLWithPath: "/tmp/\(id.rawValue)"),
            size: 10, risk: .regenerates, group: nil, isOrphan: false, modifiedAt: nil, reason: nil, cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/\(id.rawValue)"))
        )])
                    all[id] = r
                    continuation.yield(.categoryFinished(r))
                }
                continuation.yield(.finished(ScanResult(scannedAt: Date(timeIntervalSince1970: 1), reports: all)))
                continuation.finish()
            }
        }
        #expect(sut.status == .idle)
        sut.handle(.start)
        #expect(sut.status == .scanning)
        await waitUntil { sut.status == .finished(Date(timeIntervalSince1970: 1)) }
        #expect(sut.reports.count == ids.count)
        #expect(sut.pending.isEmpty)
        #expect(sut.totalSize == Int64(ids.count) * 10)
        #expect(sut.progress == 1)
    }

    @Test("category events are batched and applied before finish")
    func batchesAppliedWithoutFinish() async {
        let sut = store {
            AsyncStream { continuation in
                continuation.yield(.started([.builds, .caches]))
                continuation.yield(.categoryFinished(CategoryReport(id: .builds)))
                continuation.yield(.categoryFinished(CategoryReport(id: .caches)))
            }
        }
        sut.handle(.start)
        await waitUntil { sut.reports.count == 2 }
        #expect(sut.pending.isEmpty)
        #expect(sut.status == .scanning)
        #expect(sut.report(for: .builds) != nil)
    }

    @Test("progress and current path follow pending categories")
    func progressTracksPending() async {
        let sut = store {
            AsyncStream { continuation in
                continuation.yield(.started([.builds, .caches, .gcache]))
                continuation.yield(.categoryFinished(CategoryReport(id: .builds)))
            }
        }
        sut.handle(.start)
        await waitUntil { sut.reports.count == 1 }
        #expect(abs(sut.progress - 1.0 / 3.0) < 0.001)
        #expect(sut.progress(for: .xcode) == 0.5)
        #expect(sut.progress(for: .android) == 0)
        #expect(sut.currentPath == CategoryInfo.info(for: .caches).displayPath)
    }

    @Test("cancel stops scanning and clears pending")
    func cancelStops() async {
        let sut = store { AsyncStream { _ in } }
        sut.handle(.start)
        #expect(sut.status == .scanning)
        sut.handle(.cancel)
        #expect(sut.status == .idle)
        #expect(sut.pending.isEmpty)
    }

    @Test("restart replaces the running scan")
    func restartReplaces() async {
        let sut = store { AsyncStream { _ in } }
        sut.handle(.start)
        sut.handle(.start)
        #expect(sut.status == .scanning)
        #expect(sut.pending.count == CategoryID.allCases.count)
    }
}
