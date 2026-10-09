import Foundation
import Testing
@testable import MobileDevCleaner

private struct FakeScanRepository: ScanRepository {
    let events: @Sendable () -> AsyncStream<ScanEvent>
    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> { events() }
    func invalidateSizes(of urls: [URL]) async {}
}

@Suite("CategoryViewModel")
@MainActor
struct CategoryViewModelTests {
    private func makeCandidate(
        id: String, name: String, path: String, size: Int64,
        risk: RiskLevel, group: CandidateGroup? = nil
    ) -> CleanupCandidate {
        CleanupCandidate(
            id: id, category: .builds, name: name, url: URL(fileURLWithPath: path),
            size: size, risk: risk, group: group, isOrphan: false, modifiedAt: nil,
            reason: nil, cost: nil, execution: .remove(URL(fileURLWithPath: path))
        )
    }

    private struct TestContext {
        let vm: CategoryViewModel
        let scan: ScanStore
        let selection: SelectionStore
        let settings: SettingsStore
        let router: AppRouter
    }

    private func makeContext(
        category: CategoryID = .builds,
        report: CategoryReport = CategoryReport(id: .builds)
    ) -> TestContext {
        let scanRepo = FakeScanRepository {
            AsyncStream { continuation in
                continuation.yield(.started([category]))
                continuation.yield(.categoryFinished(report))
                continuation.yield(.finished(ScanResult(scannedAt: Date(), reports: [category: report])))
                continuation.finish()
            }
        }
        let scanStore = ScanStore(scan: ScanUseCase(repository: scanRepo), flushInterval: .milliseconds(20))
        let selectionStore = SelectionStore()
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let router = AppRouter()

        let vm = CategoryViewModel(
            category: category, scan: scanStore, selection: selectionStore,
            settings: settingsStore, router: router
        )

        scanStore.handle(.start)
        return TestContext(vm: vm, scan: scanStore, selection: selectionStore, settings: settingsStore, router: router)
    }

    @Test("groups are ordered by enum and have correct titles")
    func groupsOrderAndTitles() async {
        let candidates = [
            makeCandidate(id: "1", name: "Item 1", path: "/1", size: 100, risk: .regenerates, group: .projects),
            makeCandidate(id: "2", name: "Item 2", path: "/2", size: 200, risk: .hasCost, group: .sharedCache),
            makeCandidate(id: "3", name: "Item 3", path: "/3", size: 150, risk: .regenerates, group: .orphanProjects),
        ]
        let report = CategoryReport(id: .builds, candidates: candidates)
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count == 3 }
        #expect(ctx.vm.groups[0].title == "Caché compartido")
        #expect(ctx.vm.groups[1].title == "Tus proyectos")
        #expect(ctx.vm.groups[2].title == "Proyectos que ya no existen")
    }

    @Test("group tags are correct for orphan and unused")
    func groupTags() async {
        let orphanCandidate = makeCandidate(id: "1", name: "Orphan", path: "/1", size: 100, risk: .regenerates, group: .orphanProjects)
        let unusedCandidate = makeCandidate(id: "2", name: "Unused", path: "/2", size: 200, risk: .hasCost, group: .unusedByEmulators)
        let projectCandidate = makeCandidate(id: "3", name: "Project", path: "/3", size: 150, risk: .regenerates, group: .projects)

        let report = CategoryReport(id: .builds, candidates: [orphanCandidate, unusedCandidate, projectCandidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count == 3 }

        let orphanGroup = ctx.vm.groups.first { $0.title == "Proyectos que ya no existen" }
        let unusedGroup = ctx.vm.groups.first { $0.title == "Ningún emulador la usa" }
        let projectGroup = ctx.vm.groups.first { $0.title == "Tus proyectos" }

        #expect(orphanGroup?.tag == "Huérfano: seguro de borrar")
        #expect(unusedGroup?.tag == "Sin uso")
        #expect(projectGroup?.tag == nil)
    }

    @Test("badges show regenerates and hasCost separately")
    func badgesAreCorrect() async {
        let regeneratesCandidate = makeCandidate(id: "1", name: "Regen", path: "/1", size: 100, risk: .regenerates)
        let costCandidate = makeCandidate(id: "2", name: "Cost", path: "/2", size: 200, risk: .hasCost)

        let report = CategoryReport(id: .builds, candidates: [regeneratesCandidate, costCandidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.badges.count == 2 }
        #expect(ctx.vm.badges.contains(.regenerates))
        #expect(ctx.vm.badges.contains(.hasCost))
    }

    @Test("search filter is case and diacritic insensitive")
    func searchFilters() async {
        let candidate1 = makeCandidate(id: "1", name: "Café", path: "/test/café", size: 100, risk: .regenerates)
        let candidate2 = makeCandidate(id: "2", name: "Test", path: "/other", size: 200, risk: .hasCost)

        let report = CategoryReport(id: .builds, candidates: [candidate1, candidate2])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }
        #expect(ctx.vm.groups[0].rows.count == 2)

        ctx.router.searchQuery = "cafe"
        await waitUntil { ctx.vm.groups[0].rows.count == 1 }
        #expect(ctx.vm.groups[0].rows[0].name == "Café")
    }

    @Test("count text shows visible and selected counts")
    func countText() async {
        let candidates = [
            makeCandidate(id: "1", name: "Item 1", path: "/1", size: 100, risk: .regenerates),
            makeCandidate(id: "2", name: "Item 2", path: "/2", size: 200, risk: .hasCost),
        ]
        let report = CategoryReport(id: .builds, candidates: candidates)
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.countText != "" }
        #expect(ctx.vm.countText == "2 elementos")

        ctx.selection.toggle(candidates[0])
        #expect(ctx.vm.countText == "2 elementos · 1 marcado")

        ctx.selection.toggle(candidates[1])
        #expect(ctx.vm.countText == "2 elementos · 2 marcados")
    }

    @Test("singular element text")
    func singularElement() async {
        let candidate = makeCandidate(id: "1", name: "Item", path: "/1", size: 100, risk: .regenerates)
        let report = CategoryReport(id: .builds, candidates: [candidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.countText != "" }
        #expect(ctx.vm.countText == "1 elemento")
    }

    @Test("toggle excluded item shows toast")
    func excludedToggleShowsToast() async {
        let candidate = makeCandidate(id: "1", name: "Item", path: "/excluded", size: 100, risk: .regenerates)
        let report = CategoryReport(id: .builds, candidates: [candidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }
        ctx.settings.excludedPaths = ["/excluded"]

        ctx.vm.handle(.toggle("1"))

        #expect(ctx.router.toast == "Está en Carpetas excluidas (Ajustes › General)")
    }

    @Test("selectAll skips excluded items")
    func selectAllSkipsExcluded() async {
        let excluded = makeCandidate(id: "1", name: "Excluded", path: "/excluded", size: 100, risk: .regenerates)
        let included = makeCandidate(id: "2", name: "Included", path: "/included", size: 200, risk: .hasCost)

        let report = CategoryReport(id: .builds, candidates: [excluded, included])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }
        ctx.settings.excludedPaths = ["/excluded"]

        ctx.vm.handle(.selectAll)

        #expect(ctx.selection.isSelected(excluded) == false)
        #expect(ctx.selection.isSelected(included) == true)
    }

    @Test("fraction calculation is correct")
    func fractionCalculation() async {
        let candidates = [
            makeCandidate(id: "1", name: "Small", path: "/1", size: 100, risk: .regenerates),
            makeCandidate(id: "2", name: "Medium", path: "/2", size: 500, risk: .hasCost),
            makeCandidate(id: "3", name: "Large", path: "/3", size: 1000, risk: .hasCost),
        ]
        let report = CategoryReport(id: .builds, candidates: candidates)
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }

        let rows = ctx.vm.groups[0].rows
        #expect(rows[0].fraction == 0.1)
        #expect(rows[1].fraction == 0.5)
        #expect(rows[2].fraction == 1.0)
    }

    @Test("accessibility label format")
    func accessibilityLabel() async {
        let candidate = makeCandidate(id: "1", name: "Test", path: "/test", size: 100, risk: .regenerates)
        let report = CategoryReport(id: .builds, candidates: [candidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }

        let row = ctx.vm.groups[0].rows[0]
        #expect(row.accessibilityLabel == "Test, \(ByteFormatter.string(100)), se regenera solo")
    }

    @Test("showTechnicalNames controls path display")
    func showTechnicalNames() async {
        let candidate = makeCandidate(id: "1", name: "Item", path: "/full/path", size: 100, risk: .regenerates)
        let report = CategoryReport(id: .builds, candidates: [candidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }

        ctx.settings.showTechnicalNames = false
        #expect(ctx.vm.groups[0].rows[0].path == nil)

        ctx.settings.showTechnicalNames = true
        #expect(ctx.vm.groups[0].rows[0].path == "/full/path")
    }

    @Test("showBadge only when category mixes risks")
    func showBadgeWhenMixedRisks() async {
        let regen = makeCandidate(id: "1", name: "Regen", path: "/1", size: 100, risk: .regenerates)
        let report1 = CategoryReport(id: .builds, candidates: [regen])
        let ctx1 = makeContext(report: report1)

        await waitUntil { ctx1.vm.groups.count > 0 }
        #expect(ctx1.vm.groups[0].rows[0].showsBadge == false)

        let cost = makeCandidate(id: "2", name: "Cost", path: "/2", size: 200, risk: .hasCost)
        let report2 = CategoryReport(id: .builds, candidates: [regen, cost])
        let ctx2 = makeContext(report: report2)

        await waitUntil { ctx2.vm.groups.count > 0 }
        #expect(ctx2.vm.groups[0].rows[0].showsBadge == true)
    }

    @Test("isExcluded property is correct")
    func isExcluded() async {
        let candidate = makeCandidate(id: "1", name: "Item", path: "/excluded", size: 100, risk: .regenerates)
        let report = CategoryReport(id: .builds, candidates: [candidate])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.groups.count > 0 }

        ctx.settings.excludedPaths = ["/excluded"]
        #expect(ctx.vm.groups[0].rows[0].isExcluded == true)
    }

    @Test("isEmpty reflects category report state")
    func isEmpty() async {
        let report = CategoryReport(id: .builds, candidates: [])
        let ctx = makeContext(report: report)

        #expect(ctx.vm.isEmpty == true)

        let candidate = makeCandidate(id: "1", name: "Item", path: "/1", size: 100, risk: .regenerates)
        let reportWithContent = CategoryReport(id: .builds, candidates: [candidate])
        let ctx2 = makeContext(report: reportWithContent)

        await waitUntil { ctx2.vm.groups.count > 0 }
        #expect(ctx2.vm.isEmpty == false)
    }

    @Test("showsAccessBanner when accessDenied")
    func accessDeniedBanner() async {
        let report = CategoryReport(id: .builds, candidates: [], accessDenied: true)
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.showsAccessBanner }
        #expect(ctx.vm.showsAccessBanner == true)
    }
}
