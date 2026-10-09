import SwiftUI

enum AdvancedSettingsIntent: Sendable {
    case appear
    case clearSizeCache
    case exportPlan
    case importPlan
    case showOnboarding
    case askReset
    case cancelReset
    case confirmReset
}

@MainActor @Observable
final class AdvancedSettingsViewModel {
    /// "2,3 MB".
    private(set) var sizeCacheText = ""
    private(set) var isAskingReset = false

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let sizes: any SizeCalculating
    @ObservationIgnored private let exportPlan: ExportPlanUseCase
    @ObservationIgnored private let importPlan: ImportPlanUseCase
    @ObservationIgnored private let scan: ScanStore
    @ObservationIgnored private let selection: SelectionStore
    @ObservationIgnored private let router: AppRouter
    @ObservationIgnored private let files: PlanFilePicking

    init(
        settings: SettingsStore, sizes: any SizeCalculating, exportPlan: ExportPlanUseCase,
        importPlan: ImportPlanUseCase, scan: ScanStore, selection: SelectionStore,
        router: AppRouter, files: PlanFilePicking
    ) {
        self.settings = settings
        self.sizes = sizes
        self.exportPlan = exportPlan
        self.importPlan = importPlan
        self.scan = scan
        self.selection = selection
        self.router = router
        self.files = files
    }

    func handle(_ intent: AdvancedSettingsIntent) {
        switch intent {
        case .appear: Task { await refreshCacheSize() }
        case .clearSizeCache: Task { await clearCache() }
        case .exportPlan: Task { await export() }
        case .importPlan: Task { await importFromFile() }
        case .showOnboarding: router.isOnboardingPresented = true
        case .askReset: isAskingReset = true
        case .cancelReset: isAskingReset = false
        case .confirmReset:
            settings.reset()
            isAskingReset = false
            router.toast = L10n.string("Ajustes restablecidos")
        }
    }

    private func refreshCacheSize() async {
        sizeCacheText = ByteFormatter.string(await sizes.cacheFootprint())
    }

    private func clearCache() async {
        await sizes.clearCache()
        await refreshCacheSize()
        router.toast = L10n.string("Caché de tamaños vaciada. El próximo escaneo será completo.")
    }

    private func export() async {
        let result = await exportPlan(
            reports: scan.reports, candidateIDs: selection.candidateIDs, deviceActions: selection.deviceActions)
        guard case .right(let data) = result else {
            router.toast = L10n.string("No pudimos exportar el plan.")
            return
        }
        // A cancelled save panel is not an error.
        guard await files.save(data) else { return }
        let count = selection.count
        router.toast = count == 0
            ? L10n.string("Plan vacío exportado (no hay nada seleccionado)")
            : L10n.string("Plan exportado: \(Self.items(count))")
    }

    private func importFromFile() async {
        guard let data = await files.open() else { return }
        switch await importPlan(data, reports: scan.reports) {
        case .left:
            router.toast = L10n.string("No pudimos leer el plan.")
        case .right(let plan):
            selection.apply(plan)
            let message = L10n.string("Plan importado: \(Self.items(plan.count))")
            router.toast = plan.skipped > 0
                ? message + L10n.string(" · \(plan.skipped) ya no existen")
                : message
        }
    }

    private static func items(_ count: Int) -> String {
        count == 1 ? L10n.string("1 elemento") : L10n.string("\(count) elementos")
    }
}

/// Save/open panels, injectable so tests never show UI or touch real files.
struct PlanFilePicking: Sendable {
    let save: @MainActor (Data) async -> Bool
    let open: @MainActor () async -> Data?
}
