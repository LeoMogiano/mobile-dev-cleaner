import SwiftUI

enum CleanupFlowIntent: Sendable {
    /// Sheet opened: build the plan and check for open apps.
    case appear
    case recheck
    case toggleUnderstands
    case setMovesToTrash(Bool)
    case confirm
    case cancelCleanup
    case toggleFailures
    case showInFinder(String)
    case finish(showHistory: Bool)
    case dismiss
}

/// "Se regenera solo" rows are grouped by category.
struct ReviewGroupRow: Identifiable, Hashable {
    let id: CategoryID
    let name: String
    let symbol: String
    /// "3 elementos".
    let countText: String
    let sizeText: String
}

struct ReviewCostRow: Identifiable, Hashable {
    let id: String
    let name: String
    let categoryName: String
    let sizeText: String
    let note: String
}

struct BlockingAppRow: Identifiable, Hashable {
    let id: DevApp
    /// "Xcode", "Simulator", "Android Studio", "Emulador Android".
    let name: String
    let detail: String
    let symbol: String
    /// Tile tint; nil uses the secondary text color.
    let tool: Tool?
}

struct ResultFailureRow: Identifiable, Hashable {
    let id: String
    let name: String
    let reason: String
}

@MainActor @Observable
final class CleanupFlowViewModel {
    enum Stage: Equatable {
        case checking
        case review
        case blocked
        case progress
        case result
    }

    private(set) var stage: Stage = .checking
    private(set) var operations: [CleanupOperation] = []
    private(set) var blockingApps: [BlockingAppRow] = []
    private(set) var isRechecking = false
    private(set) var understands = false
    private(set) var isFailuresExpanded = false

    // Progress
    private(set) var completedIndex = 0
    private(set) var freedSoFar: Int64 = 0
    private(set) var currentName = ""

    private(set) var outcome: CleanupOutcome?

    @ObservationIgnored private var token: CancellationToken?
    @ObservationIgnored private var flowTask: Task<Void, Never>?

    @ObservationIgnored private let buildPlan: BuildCleanupPlanUseCase
    @ObservationIgnored private let execute: ExecuteCleanupUseCase
    @ObservationIgnored private let checkBlocking: CheckBlockingAppsUseCase
    @ObservationIgnored private let notifier: any CleanupNotifying
    @ObservationIgnored private let scan: ScanStore
    @ObservationIgnored private let selection: SelectionStore
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let history: HistoryStore
    @ObservationIgnored private let router: AppRouter

    init(
        buildPlan: BuildCleanupPlanUseCase, execute: ExecuteCleanupUseCase,
        checkBlocking: CheckBlockingAppsUseCase, notifier: any CleanupNotifying,
        scan: ScanStore, selection: SelectionStore, settings: SettingsStore,
        history: HistoryStore, router: AppRouter
    ) {
        self.buildPlan = buildPlan
        self.execute = execute
        self.checkBlocking = checkBlocking
        self.notifier = notifier
        self.scan = scan
        self.selection = selection
        self.settings = settings
        self.history = history
        self.router = router
    }

    // MARK: - Review

    private var totalBytes: Int64 { operations.reduce(0) { $0 + $1.size } }
    private var regenerating: [CleanupOperation] { operations.filter { $0.risk == .regenerates } }
    private var costly: [CleanupOperation] { operations.filter { $0.risk == .hasCost } }

    var totalText: String { ByteFormatter.string(totalBytes) }
    var countText: String { Self.ess(operations.count) }
    var regenerateHeader: String? { Self.header(for: regenerating) }
    var costHeader: String? { Self.header(for: costly) }

    var regenerateRows: [ReviewGroupRow] {
        var order: [CategoryID] = []
        let grouped = Dictionary(grouping: regenerating) { $0.category }
        for op in regenerating where !order.contains(op.category) { order.append(op.category) }
        return order.map { id in
            let items = grouped[id] ?? []
            let info = CategoryInfo.info(for: id)
            return ReviewGroupRow(
                id: id, name: info.name, symbol: info.symbol, countText: Self.ess(items.count),
                sizeText: ByteFormatter.string(items.reduce(0) { $0 + $1.size }))
        }
    }

    var costRows: [ReviewCostRow] {
        costly.map {
            ReviewCostRow(
                id: $0.id, name: $0.name, categoryName: CategoryInfo.info(for: $0.category).name,
                sizeText: ByteFormatter.string($0.size), note: $0.note ?? "")
        }
    }

    /// nil unless "Mostrar comandos" is on.
    var commands: [String]? {
        guard settings.showCommands else { return nil }
        return operations.flatMap { $0.steps.map { $0.commandLine(movesToTrash: settings.moveToTrash) } }
    }

    var movesToTrash: Bool { settings.moveToTrash }
    var needsUnderstanding: Bool { settings.confirmCost && !costly.isEmpty }
    var canClean: Bool { !operations.isEmpty && (!needsUnderstanding || understands) }
    var primaryTitle: String { needsUnderstanding ? L10n.string("Entiendo, limpiar") : L10n.string("Limpiar") }

    // MARK: - Progress

    var progressFraction: Double { totalBytes > 0 ? Double(freedSoFar) / Double(totalBytes) : 0 }
    var freedText: String { ByteFormatter.string(freedSoFar) }
    var ofTotalText: String { L10n.string("de \(ByteFormatter.string(totalBytes))") }

    var stepText: String {
        let n = operations.count
        return L10n.string("\(min(n, completedIndex + 1)) de \(n) · \(currentName)")
    }

    // MARK: - Result

    var resultFreedText: String { ByteFormatter.string(outcome?.freedBytes ?? 0) }
    var resultCountText: String { Self.ess(outcome?.done.count ?? 0) }
    var wasCancelled: Bool { outcome?.wasCancelled ?? false }
    var showsTrashNote: Bool { (outcome?.movedToTrash ?? false) && (outcome?.freedBytes ?? 0) > 0 }

    var failureRows: [ResultFailureRow] {
        (outcome?.failures ?? []).map { ResultFailureRow(id: $0.id, name: $0.operation.name, reason: $0.reason) }
    }

    var failureHeader: String {
        let n = outcome?.failures.count ?? 0
        return n == 1 ? L10n.string("1 no se pudo limpiar") : L10n.string("\(n) no se pudieron limpiar")
    }

    // MARK: - Intents

    func handle(_ intent: CleanupFlowIntent) {
        switch intent {
        case .appear: appear()
        case .recheck: recheck()
        case .toggleUnderstands: understands.toggle()
        case .setMovesToTrash(let value): settings.moveToTrash = value
        case .confirm: confirm()
        case .cancelCleanup: token?.cancel()
        case .toggleFailures: isFailuresExpanded.toggle()
        case .showInFinder(let id): showInFinder(id)
        case .finish(let showHistory):
            router.isReviewPresented = false
            router.show(showHistory ? .history : .overview)
        case .dismiss:
            if stage != .progress { router.isReviewPresented = false }
        }
    }

    private func appear() {
        guard flowTask == nil else { return }
        operations = buildPlan(
            reports: scan.reports, candidateIDs: selection.candidateIDs, deviceActions: selection.deviceActions
        ).filter { op in
            guard case .candidate = op.source else { return true }
            return !settings.isExcluded(op.url.path)
        }
        stage = .checking
        flowTask = Task { [self] in
            await refreshBlocking()
            stage = blockingApps.isEmpty ? .review : .blocked
            flowTask = nil
        }
    }

    private func recheck() {
        guard stage == .blocked, !isRechecking else { return }
        isRechecking = true
        Task { [self] in
            await refreshBlocking()
            isRechecking = false
            if blockingApps.isEmpty { stage = .review }
        }
    }

    private func confirm() {
        guard canClean, stage == .review, flowTask == nil else { return }
        flowTask = Task { [self] in
            await refreshBlocking()
            guard blockingApps.isEmpty else {
                stage = .blocked
                flowTask = nil
                return
            }
            await runCleanup()
            flowTask = nil
        }
    }

    private func runCleanup() async {
        let token = CancellationToken()
        self.token = token
        completedIndex = 0
        freedSoFar = 0
        currentName = operations.first?.name ?? ""
        stage = .progress
        let planned = operations
        for await event in execute(planned, movesToTrash: settings.moveToTrash, token: token) {
            switch event {
            case .started(let index):
                completedIndex = index
                if planned.indices.contains(index) { currentName = planned[index].name }
            case .finished(let index, let failure):
                if failure == nil, planned.indices.contains(index) { freedSoFar += planned[index].size }
            case .completed(let result):
                await finish(with: result)
            }
        }
        self.token = nil
    }

    private func finish(with result: CleanupOutcome) async {
        outcome = result
        stage = .result
        await history.record(result)
        selection.clear()
        scan.handle(.start)
        if !result.wasCancelled {
            await notifier.notifyCleanupFinished(freedBytes: result.freedBytes, failureCount: result.failures.count)
        }
    }

    private func refreshBlocking() async {
        let apps = await checkBlocking(for: operations)
        blockingApps = apps.map(Self.row(for:))
    }

    private func showInFinder(_ id: String) {
        guard let op = outcome?.failures.first(where: { $0.id == id })?.operation else { return }
        NSWorkspace.shared.activateFileViewerSelecting([op.url])
    }

    // MARK: - Helpers

    private static func ess(_ n: Int) -> String {
        n == 1 ? L10n.string("1 elemento") : L10n.string("\(n) elementos")
    }

    private static func header(for ops: [CleanupOperation]) -> String? {
        guard !ops.isEmpty else { return nil }
        return "\(ess(ops.count)) · \(ByteFormatter.string(ops.reduce(0) { $0 + $1.size }))"
    }

    private static func row(for app: BlockingApp) -> BlockingAppRow {
        switch app.app {
        case .xcode:
            BlockingAppRow(id: .xcode, name: "Xcode", detail: L10n.string("Puede tener un build en curso"), symbol: "hammer", tool: .xcode)
        case .simulator:
            BlockingAppRow(id: .simulator, name: "Simulator", detail: L10n.string("Hay simuladores abiertos"), symbol: "iphone", tool: nil)
        case .androidStudio:
            BlockingAppRow(id: .androidStudio, name: "Android Studio", detail: L10n.string("Puede tener un build en curso"), symbol: "cpu", tool: .android)
        case .androidEmulator:
            BlockingAppRow(
                id: .androidEmulator, name: L10n.string("Emulador Android"),
                detail: app.details.isEmpty ? L10n.string("En ejecución") : app.details.joined(separator: ", "),
                symbol: "smartphone", tool: .android)
        }
    }
}
