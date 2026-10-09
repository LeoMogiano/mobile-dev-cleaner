import Foundation
import Testing
@testable import MobileDevCleaner

private struct FakeScanRepository: ScanRepository {
    let reports: [CategoryID: CategoryReport]
    let finishes: Bool

    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> {
        AsyncStream { continuation in
            continuation.yield(.started(Array(CategoryID.allCases)))
            if finishes {
                continuation.yield(.finished(ScanResult(scannedAt: Date(), reports: reports)))
                continuation.finish()
            }
        }
    }

    func invalidateSizes(of urls: [URL]) async {}
}

@Suite("DashboardViewModel")
@MainActor
struct DashboardViewModelTests {
    private func candidate(_ id: CategoryID, _ name: String, _ size: Int64, risk: RiskLevel = .regenerates) -> CleanupCandidate {
        let url = URL(fileURLWithPath: "/tmp/mdc-dash/\(id.rawValue)/\(name)")
        return CleanupCandidate(
            id: url.path, category: id, name: name, url: url, size: size, risk: risk, group: nil,
            isOrphan: false, modifiedAt: nil, reason: nil, cost: nil, execution: .remove(url)
        )
    }

    private struct Fixture {
        let model: DashboardViewModel
        let scan: ScanStore
        let selection: SelectionStore
        let settings: SettingsStore
        let router: AppRouter
    }

    private func fixture(_ reports: [CategoryReport], finishes: Bool = true) async -> Fixture {
        let repo = FakeScanRepository(reports: Dictionary(uniqueKeysWithValues: reports.map { ($0.id, $0) }), finishes: finishes)
        let scan = ScanStore(scan: ScanUseCase(repository: repo), flushInterval: .milliseconds(10))
        let selection = SelectionStore()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let router = AppRouter()
        scan.handle(.start)
        if finishes { await waitUntil { scan.status != .scanning } }
        let model = DashboardViewModel(scan: scan, selection: selection, settings: settings, router: router)
        return Fixture(model: model, scan: scan, selection: selection, settings: settings, router: router)
    }

    private var sample: [CategoryReport] {
        [
            CategoryReport(id: .builds, candidates: [candidate(.builds, "a", 500), candidate(.builds, "cost", 100, risk: .hasCost)]),
            CategoryReport(id: .caches, candidates: [candidate(.caches, "a", 400)]),
            CategoryReport(id: .gcache, candidates: [candidate(.gcache, "a", 300)]),
            CategoryReport(id: .previews, candidates: [candidate(.previews, "a", 200)]),
            CategoryReport(id: .glogs, candidates: [candidate(.glogs, "a", 50)])
        ]
    }

    @Test("recommended bytes sum regenerable items only")
    func recommendedBytes() async {
        let f = await fixture(sample)
        #expect(f.model.recommendedBytes == 1450)
    }

    @Test("excluded paths are left out of recommended")
    func excludedPaths() async {
        let f = await fixture(sample)
        f.settings.excludedPaths = ["/tmp/mdc-dash/caches"]
        #expect(f.model.recommendedBytes == 1050)
        #expect(!f.model.visibleRecommended.contains { $0.id == .caches })
    }

    @Test("categories with denied access are not recommended")
    func deniedAccess() async {
        var denied = CategoryReport(id: .caches, candidates: [candidate(.caches, "a", 400)])
        denied.accessDenied = true
        let f = await fixture([denied, CategoryReport(id: .builds, candidates: [candidate(.builds, "a", 500)])])
        #expect(f.model.recommendedBytes == 500)
        #expect(f.model.showsAccessBanner)
        f.model.handle(.dismissBanner)
        #expect(!f.model.showsAccessBanner)
    }

    @Test("list shows top 3 by size and expands to all")
    func topThreeAndMore() async {
        let f = await fixture(sample)
        #expect(f.model.visibleRecommended.map(\.id) == [.builds, .caches, .gcache])
        #expect(f.model.hasMoreRecommended)
        #expect(f.model.hiddenRecommendedCount == 2)
        f.model.handle(.toggleRecommendedList)
        #expect(f.model.visibleRecommended.count == 5)
        #expect(f.model.visibleRecommended.first?.id == .builds)
    }

    @Test("decision rows list categories with cost")
    func decisionRows() async {
        let f = await fixture(sample)
        #expect(f.model.decisionRows.map(\.id) == [.builds])
        f.model.handle(.openCategory(.builds))
        #expect(f.router.selection == .category(.builds))
    }

    @Test("cleanRecommended selects regenerable ids and presents review")
    func cleanRecommended() async {
        let f = await fixture(sample)
        f.settings.excludedPaths = ["/tmp/mdc-dash/glogs"]
        f.model.handle(.cleanRecommended)
        #expect(f.selection.count == 4)
        #expect(f.selection.candidateIDs.contains("/tmp/mdc-dash/builds/a"))
        #expect(!f.selection.candidateIDs.contains("/tmp/mdc-dash/builds/cost"))
        #expect(!f.selection.candidateIDs.contains("/tmp/mdc-dash/glogs/a"))
        #expect(f.router.isReviewPresented)
    }

    @Test("state moves from scanning to results")
    func scanningToResults() async {
        let running = await fixture(sample, finishes: false)
        #expect(running.model.state == .scanning)
        let done = await fixture(sample)
        #expect(done.model.state == .results)
        #expect(done.model.footer().hasPrefix("Último escaneo"))
    }

    @Test("state is clean when nothing was found")
    func cleanState() async {
        let f = await fixture([])
        #expect(f.model.state == .clean)
    }
}
