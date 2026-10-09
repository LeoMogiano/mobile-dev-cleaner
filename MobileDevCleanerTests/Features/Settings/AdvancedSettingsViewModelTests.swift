import Foundation
import Testing
@testable import MobileDevCleaner

private actor MockSizes: SizeCalculating {
    var footprint: Int64 = 2_300_000
    private(set) var cleared = false

    func size(of url: URL) async throws -> Int64 { 0 }
    func sizes(of urls: [URL]) async -> [URL: Int64] { [:] }
    func invalidate(_ urls: [URL]) async {}
    func clearCache() async {
        cleared = true
        footprint = 0
    }
    func cacheFootprint() async -> Int64 { footprint }
    func flush() async {}
    func syncWithFileChanges() async {}
}

private struct OneShotScanRepository: ScanRepository {
    let report: CategoryReport

    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> {
        AsyncStream { continuation in
            continuation.yield(.started([report.id]))
            continuation.yield(.finished(ScanResult(scannedAt: .now, reports: [report.id: report])))
            continuation.finish()
        }
    }

    func invalidateSizes(of urls: [URL]) async {}
}

@MainActor
private final class FileBox {
    var saved: Data?
    var toOpen: Data?
    var acceptsSave = true
}

@Suite("AdvancedSettingsViewModel")
@MainActor
struct AdvancedSettingsViewModelTests {
    private struct Context {
        let vm: AdvancedSettingsViewModel
        let settings: SettingsStore
        let selection: SelectionStore
        let router: AppRouter
        let sizes: MockSizes
        let files: FileBox
    }

    private static let candidate = CleanupCandidate(
        id: "/tmp/mdc/DerivedData/App", category: .builds, name: "App", url: URL(filePath: "/tmp/mdc/DerivedData/App"),
        size: 1_000, risk: .regenerates, group: nil, isOrphan: false, modifiedAt: nil, reason: nil, cost: nil,
        execution: .remove(URL(filePath: "/tmp/mdc/DerivedData/App")))

    private func makeContext() async -> Context {
        let report = CategoryReport(id: .builds, candidates: [Self.candidate])
        let scan = ScanStore(scan: ScanUseCase(repository: OneShotScanRepository(report: report)), flushInterval: .milliseconds(10))
        scan.handle(.start)
        await waitUntil { scan.report(for: .builds) != nil }
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let selection = SelectionStore()
        let router = AppRouter()
        let sizes = MockSizes()
        let files = FileBox()
        let repository = PlanTransferRepositoryImpl()
        let vm = AdvancedSettingsViewModel(
            settings: settings, sizes: sizes, exportPlan: ExportPlanUseCase(repository: repository),
            importPlan: ImportPlanUseCase(repository: repository), scan: scan, selection: selection, router: router,
            files: PlanFilePicking(
                save: { data in
                    guard files.acceptsSave else { return false }
                    files.saved = data
                    return true
                },
                open: { files.toOpen }))
        return Context(vm: vm, settings: settings, selection: selection, router: router, sizes: sizes, files: files)
    }

    @Test("appear shows the size cache footprint")
    func appearShowsCacheSize() async {
        let ctx = await makeContext()
        ctx.vm.handle(.appear)
        await waitUntil { ctx.vm.sizeCacheText == ByteFormatter.string(2_300_000) }
    }

    @Test("clearing the cache empties it and confirms")
    func clearCache() async {
        let ctx = await makeContext()
        ctx.vm.handle(.clearSizeCache)
        await waitUntil { ctx.router.toast != nil }
        #expect(await ctx.sizes.cleared)
        #expect(ctx.vm.sizeCacheText == ByteFormatter.string(0))
        #expect(ctx.router.toast == "Caché de tamaños vaciada. El próximo escaneo será completo.")
    }

    @Test("export saves the selection and reports the count")
    func exportSelection() async {
        let ctx = await makeContext()
        ctx.selection.toggle(Self.candidate)
        ctx.vm.handle(.exportPlan)
        await waitUntil { ctx.router.toast != nil }
        #expect(ctx.files.saved != nil)
        #expect(ctx.router.toast == "Plan exportado: 1 elemento")
    }

    @Test("export with nothing selected says the plan is empty")
    func exportEmpty() async {
        let ctx = await makeContext()
        ctx.vm.handle(.exportPlan)
        await waitUntil { ctx.router.toast != nil }
        #expect(ctx.router.toast == "Plan vacío exportado (no hay nada seleccionado)")
    }

    @Test("cancelling the save panel shows nothing")
    func exportCancelled() async {
        let ctx = await makeContext()
        ctx.files.acceptsSave = false
        ctx.vm.handle(.exportPlan)
        try? await Task.sleep(for: .milliseconds(100))
        #expect(ctx.router.toast == nil)
    }

    @Test("import applies the plan to the selection")
    func importApplies() async {
        let ctx = await makeContext()
        ctx.selection.toggle(Self.candidate)
        ctx.vm.handle(.exportPlan)
        await waitUntil { ctx.files.saved != nil }
        ctx.selection.clear()
        ctx.router.toast = nil
        ctx.files.toOpen = ctx.files.saved

        ctx.vm.handle(.importPlan)
        await waitUntil { ctx.router.toast != nil }
        #expect(ctx.selection.isSelected(Self.candidate))
        #expect(ctx.router.toast == "Plan importado: 1 elemento")
    }

    @Test("an unreadable plan shows an error and keeps the selection")
    func importInvalid() async {
        let ctx = await makeContext()
        ctx.files.toOpen = Data("not json".utf8)
        ctx.vm.handle(.importPlan)
        await waitUntil { ctx.router.toast != nil }
        #expect(ctx.router.toast == "No pudimos leer el plan.")
        #expect(ctx.selection.isEmpty)
    }

    @Test("show onboarding presents it")
    func showOnboarding() async {
        let ctx = await makeContext()
        ctx.vm.handle(.showOnboarding)
        #expect(ctx.router.isOnboardingPresented)
    }

    @Test("reset asks first and only resets on confirm")
    func resetFlow() async {
        let ctx = await makeContext()
        ctx.settings.showCommands = true
        ctx.vm.handle(.askReset)
        #expect(ctx.vm.isAskingReset)
        ctx.vm.handle(.cancelReset)
        #expect(!ctx.vm.isAskingReset)
        #expect(ctx.settings.showCommands)

        ctx.vm.handle(.askReset)
        ctx.vm.handle(.confirmReset)
        #expect(!ctx.vm.isAskingReset)
        #expect(!ctx.settings.showCommands)
        #expect(ctx.router.toast == "Ajustes restablecidos")
    }
}
