import Foundation
import Testing
@testable import MobileDevCleaner

private final class CallLog: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [[CleanupOperation]] = []
    private var scans = 0

    func record(_ operations: [CleanupOperation]) { lock.withLock { values.append(operations) } }
    func recordScan() { lock.withLock { scans += 1 } }
    var executions: [[CleanupOperation]] { lock.withLock { values } }
    var scanCount: Int { lock.withLock { scans } }
}

private actor MockCleanupRepository: CleanupRepository {
    typealias Script = @Sendable ([CleanupOperation], CancellationToken) -> AsyncStream<CleanupEvent>

    nonisolated let log = CallLog()
    private let script: Script
    private var responses: [[BlockingApp]]
    private(set) var blockingCalls = 0

    init(blocking: [[BlockingApp]] = [[]], script: @escaping Script = MockCleanupRepository.succeedAll) {
        responses = blocking
        self.script = script
    }

    nonisolated func execute(
        _ operations: [CleanupOperation], movesToTrash: Bool, token: CancellationToken
    ) -> AsyncStream<CleanupEvent> {
        log.record(operations)
        return script(operations, token)
    }

    func blockingApps(for tools: Set<Tool>) async -> [BlockingApp] {
        blockingCalls += 1
        return responses.count > 1 ? responses.removeFirst() : (responses.first ?? [])
    }

    /// All operations succeed except those whose id is in `failing`.
    static func succeedAll(_ operations: [CleanupOperation], _ token: CancellationToken) -> AsyncStream<CleanupEvent> {
        outcomeStream(operations, failing: [])
    }

    static func outcomeStream(_ operations: [CleanupOperation], failing: Set<String>, movedToTrash: Bool = true) -> AsyncStream<CleanupEvent> {
        AsyncStream { continuation in
            var done: [CleanupOperation] = []
            var failures: [CleanupFailureItem] = []
            for (index, op) in operations.enumerated() {
                continuation.yield(.started(index: index))
                if failing.contains(op.id) {
                    failures.append(CleanupFailureItem(operation: op, reason: "denied"))
                    continuation.yield(.finished(index: index, failure: .permissionDenied()))
                } else {
                    done.append(op)
                    continuation.yield(.finished(index: index, failure: nil))
                }
            }
            continuation.yield(.completed(CleanupOutcome(done: done, failures: failures, wasCancelled: false, movedToTrash: movedToTrash)))
            continuation.finish()
        }
    }
}

private actor MockNotifier: CleanupNotifying {
    private(set) var calls: [(freed: Int64, failures: Int)] = []
    func notifyCleanupFinished(freedBytes: Int64, failureCount: Int) async { calls.append((freedBytes, failureCount)) }
}

private actor StubHistoryRepository: HistoryRepository {
    private(set) var entries: [HistoryEntry] = []
    func load() async -> Either<Failure, [HistoryEntry]> { .right(entries) }
    func append(_ entry: HistoryEntry) async -> Either<Failure, [HistoryEntry]> {
        entries.insert(entry, at: 0)
        return .right(entries)
    }
}

private struct StubScanRepository: ScanRepository {
    let reports: [CategoryID: CategoryReport]
    let log: CallLog
    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> {
        log.recordScan()
        return AsyncStream { continuation in
            continuation.yield(.started(Array(reports.keys)))
            for report in reports.values { continuation.yield(.categoryFinished(report)) }
            continuation.yield(.finished(ScanResult(scannedAt: Date(), reports: reports)))
            continuation.finish()
        }
    }
    func invalidateSizes(of urls: [URL]) async {}
}

@Suite("CleanupFlowViewModel")
@MainActor
struct CleanupFlowViewModelTests {
    private struct Context {
        let vm: CleanupFlowViewModel
        let repo: MockCleanupRepository
        let notifier: MockNotifier
        let history: HistoryStore
        let historyRepo: StubHistoryRepository
        let selection: SelectionStore
        let settings: SettingsStore
        let router: AppRouter
        let scan: ScanStore
    }

    private static func candidate(
        _ id: String, category: CategoryID = .builds, size: Int64, risk: RiskLevel, cost: String? = nil
    ) -> CleanupCandidate {
        let url = URL(filePath: "/tmp/mdc/\(id)")
        return CleanupCandidate(
            id: url.path, category: category, name: id, url: url, size: size, risk: risk, group: nil,
            isOrphan: false, modifiedAt: nil, reason: nil, cost: cost, execution: .remove(url))
    }

    private static let defaultCandidates = [
        candidate("A", size: 3_000_000, risk: .regenerates),
        candidate("B", category: .caches, size: 2_000_000, risk: .regenerates),
        candidate("C", size: 5_000_000, risk: .hasCost, cost: "Hay que bajarlo otra vez"),
        candidate("D", category: .caches, size: 1_000_000, risk: .regenerates),
    ]

    private func makeContext(
        candidates: [CleanupCandidate] = CleanupFlowViewModelTests.defaultCandidates,
        selected: [String]? = nil,
        blocking: [[BlockingApp]] = [[]],
        configure: (SettingsStore) -> Void = { _ in },
        script: MockCleanupRepository.Script? = nil
    ) async -> Context {
        let repo = script.map { MockCleanupRepository(blocking: blocking, script: $0) } ?? MockCleanupRepository(blocking: blocking)
        var reports: [CategoryID: CategoryReport] = [:]
        for candidate in candidates {
            reports[candidate.category, default: CategoryReport(id: candidate.category)].candidates.append(candidate)
        }
        let scan = ScanStore(
            scan: ScanUseCase(repository: StubScanRepository(reports: reports, log: repo.log)), flushInterval: .milliseconds(10))
        scan.handle(.start)
        await waitUntil { scan.reports.count == reports.count && scan.status != .scanning }
        let selection = SelectionStore()
        let ids = Set(selected ?? candidates.map(\.id))
        selection.select(candidates.filter { ids.contains($0.id) })
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        configure(settings)
        let notifier = MockNotifier()
        let historyRepo = StubHistoryRepository()
        let history = HistoryStore(load: LoadHistoryUseCase(repository: historyRepo), record: RecordCleanupUseCase(repository: historyRepo))
        let router = AppRouter()
        router.isReviewPresented = true
        let vm = CleanupFlowViewModel(
            buildPlan: BuildCleanupPlanUseCase(), execute: ExecuteCleanupUseCase(repository: repo),
            checkBlocking: CheckBlockingAppsUseCase(repository: repo), notifier: notifier,
            scan: scan, selection: selection, settings: settings, history: history, router: router)
        return Context(vm: vm, repo: repo, notifier: notifier, history: history, historyRepo: historyRepo,
                       selection: selection, settings: settings, router: router, scan: scan)
    }

    private func open(_ ctx: Context) async {
        ctx.vm.handle(.appear)
        await waitUntil { ctx.vm.stage != .checking }
    }

    @Test("appear builds the plan without excluded paths and lands on review")
    func appearPlan() async {
        let ctx = await makeContext(configure: { $0.excludedPaths = ["/tmp/mdc/B"] })
        #expect(ctx.vm.stage == .checking)
        await open(ctx)
        #expect(ctx.vm.stage == .review)
        #expect(ctx.vm.operations.map(\.name) == ["A", "C", "D"])
    }

    @Test("review texts and groups")
    func reviewTexts() async {
        let ctx = await makeContext()
        await open(ctx)
        let vm = ctx.vm
        #expect(vm.totalText == ByteFormatter.string(11_000_000))
        #expect(vm.countText == "4 elementos")
        #expect(vm.regenerateHeader == "3 elementos · \(ByteFormatter.string(6_000_000))")
        #expect(vm.costHeader == "1 elemento · \(ByteFormatter.string(5_000_000))")
        #expect(vm.regenerateRows.map(\.id) == [.builds, .caches])
        #expect(vm.regenerateRows.map(\.countText) == ["1 elemento", "2 elementos"])
        #expect(vm.regenerateRows[1].sizeText == ByteFormatter.string(3_000_000))
        #expect(vm.costRows.count == 1)
        #expect(vm.costRows[0].name == "C")
        #expect(vm.costRows[0].categoryName == CategoryInfo.info(for: .builds).name)
        #expect(vm.costRows[0].note == "C: hay que bajarlo otra vez")
    }

    @Test("headers are nil when a risk group is empty")
    func emptyGroups() async {
        let ctx = await makeContext(selected: [CleanupFlowViewModelTests.defaultCandidates[0].id])
        await open(ctx)
        #expect(ctx.vm.costHeader == nil)
        #expect(ctx.vm.costRows.isEmpty)
        #expect(ctx.vm.countText == "1 elemento")
    }

    @Test("understanding gate follows the setting and the presence of costly items")
    func understandingGate() async {
        let ctx = await makeContext()
        await open(ctx)
        #expect(ctx.vm.needsUnderstanding)
        #expect(!ctx.vm.canClean)
        #expect(ctx.vm.primaryTitle == "Entiendo, limpiar")
        ctx.vm.handle(.toggleUnderstands)
        #expect(ctx.vm.canClean)

        let relaxed = await makeContext(configure: { $0.confirmCost = false })
        await open(relaxed)
        #expect(!relaxed.vm.needsUnderstanding)
        #expect(relaxed.vm.canClean)
        #expect(relaxed.vm.primaryTitle == "Limpiar")

        let safeOnly = await makeContext(selected: [CleanupFlowViewModelTests.defaultCandidates[0].id])
        await open(safeOnly)
        #expect(safeOnly.vm.canClean)
        #expect(safeOnly.vm.primaryTitle == "Limpiar")
    }

    @Test("commands only show when the setting is on and follow the trash setting")
    func commands() async {
        let off = await makeContext(selected: [CleanupFlowViewModelTests.defaultCandidates[0].id])
        await open(off)
        #expect(off.vm.commands == nil)

        let on = await makeContext(selected: [CleanupFlowViewModelTests.defaultCandidates[0].id], configure: { $0.showCommands = true })
        await open(on)
        #expect(on.vm.commands == ["mv \"/tmp/mdc/A\" ~/.Trash/"])
        on.vm.handle(.setMovesToTrash(false))
        #expect(on.vm.commands == ["rm -rf \"/tmp/mdc/A\""])
        #expect(!on.settings.moveToTrash)
    }

    @Test("blocked stage shows rows and recheck returns to review once closed")
    func blockedAndRecheck() async {
        let apps = [
            BlockingApp(app: .xcode, details: []), BlockingApp(app: .simulator, details: []),
            BlockingApp(app: .androidStudio, details: []), BlockingApp(app: .androidEmulator, details: ["b", "a"]),
        ]
        let ctx = await makeContext(blocking: [apps, apps, []])
        await open(ctx)
        #expect(ctx.vm.stage == .blocked)
        let rows = ctx.vm.blockingApps
        #expect(rows.map(\.name) == ["Xcode", "Simulator", "Android Studio", "Emulador Android"])
        #expect(rows.map(\.symbol) == ["hammer", "iphone", "cpu", "smartphone"])
        #expect(rows.map(\.tool) == [.xcode, nil, .android, .android])
        #expect(rows[0].detail == "Puede tener un build en curso")
        #expect(rows[1].detail == "Hay simuladores abiertos")
        #expect(rows[3].detail == "b, a")

        ctx.vm.handle(.recheck)
        #expect(ctx.vm.isRechecking)
        await waitUntil { !ctx.vm.isRechecking }
        #expect(ctx.vm.stage == .blocked)
        ctx.vm.handle(.recheck)
        await waitUntil { ctx.vm.stage == .review }
        #expect(ctx.vm.blockingApps.isEmpty)
    }

    @Test("emulator without running AVD names falls back to a generic detail")
    func emulatorFallback() async {
        let ctx = await makeContext(blocking: [[BlockingApp(app: .androidEmulator, details: [])]])
        await open(ctx)
        #expect(ctx.vm.blockingApps.first?.detail == "En ejecución")
    }

    @Test("confirm re-checks open apps and goes back to blocked without executing")
    func confirmRechecks() async {
        let ctx = await makeContext(blocking: [[], [BlockingApp(app: .xcode, details: [])]], configure: { $0.confirmCost = false })
        await open(ctx)
        #expect(ctx.vm.stage == .review)
        ctx.vm.handle(.confirm)
        await waitUntil { ctx.vm.stage == .blocked }
        #expect(ctx.repo.log.executions.isEmpty)
        #expect(ctx.vm.blockingApps.map(\.id) == [.xcode])
    }

    @Test("confirm is ignored until the cost is understood")
    func confirmNeedsUnderstanding() async {
        let ctx = await makeContext()
        await open(ctx)
        ctx.vm.handle(.confirm)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(ctx.vm.stage == .review)
        #expect(ctx.repo.log.executions.isEmpty)
    }

    @Test("full run reports results, records history, clears selection, rescans and notifies")
    func fullRun() async {
        let failingID = "/tmp/mdc/D"
        let ctx = await makeContext(
            script: { ops, _ in MockCleanupRepository.outcomeStream(ops, failing: [failingID]) })
        await open(ctx)
        ctx.vm.handle(.toggleUnderstands)
        let scansBefore = ctx.repo.log.scanCount
        ctx.vm.handle(.confirm)
        await waitUntil { ctx.vm.stage == .result }
        await waitUntil { await ctx.notifier.calls.count == 1 }

        let vm = ctx.vm
        #expect(vm.resultFreedText == ByteFormatter.string(10_000_000))
        #expect(vm.resultCountText == "3 elementos")
        #expect(!vm.wasCancelled)
        #expect(vm.showsTrashNote)
        #expect(vm.failureHeader == "1 no se pudo limpiar")
        #expect(vm.failureRows.map(\.name) == ["D"])
        #expect(vm.freedText == ByteFormatter.string(10_000_000))
        #expect(vm.ofTotalText == "de \(ByteFormatter.string(11_000_000))")
        #expect(vm.progressFraction > 0.9 && vm.progressFraction < 1)
        #expect(ctx.selection.isEmpty)
        #expect(ctx.history.entries.count == 1)
        #expect(ctx.history.entries.first?.freedBytes == 10_000_000)
        #expect(ctx.repo.log.scanCount == scansBefore + 1)
        let calls = await ctx.notifier.calls
        #expect(calls.first?.freed == 10_000_000)
        #expect(calls.first?.failures == 1)
        #expect(await ctx.repo.blockingCalls == 2)
    }

    @Test("plural failure header")
    func pluralFailures() async {
        let ctx = await makeContext(
            configure: { $0.confirmCost = false },
            script: { ops, _ in MockCleanupRepository.outcomeStream(ops, failing: ["/tmp/mdc/A", "/tmp/mdc/B"]) })
        await open(ctx)
        ctx.vm.handle(.confirm)
        await waitUntil { ctx.vm.stage == .result }
        #expect(ctx.vm.failureHeader == "2 no se pudieron limpiar")
        #expect(!ctx.vm.isFailuresExpanded)
        ctx.vm.handle(.toggleFailures)
        #expect(ctx.vm.isFailuresExpanded)
    }

    @Test("progress text and cancellation: no notification, dismiss ignored while running")
    func cancellation() async {
        let ctx = await makeContext(
            configure: { $0.confirmCost = false },
            script: { ops, token in
                AsyncStream { continuation in
                    Task {
                        continuation.yield(.started(index: 0))
                        continuation.yield(.finished(index: 0, failure: nil))
                        continuation.yield(.started(index: 1))
                        while !token.isCancelled { try? await Task.sleep(for: .milliseconds(5)) }
                        continuation.yield(.finished(index: 1, failure: nil))
                        continuation.yield(.completed(CleanupOutcome(
                            done: Array(ops.prefix(2)), failures: [], wasCancelled: true, movedToTrash: true)))
                        continuation.finish()
                    }
                }
            })
        await open(ctx)
        ctx.vm.handle(.confirm)
        await waitUntil { ctx.vm.stage == .progress && ctx.vm.completedIndex == 1 }
        #expect(ctx.vm.stepText == "2 de 4 · C")
        #expect(ctx.vm.freedSoFar == 3_000_000)
        ctx.vm.handle(.dismiss)
        #expect(ctx.router.isReviewPresented)
        ctx.vm.handle(.cancelCleanup)
        await waitUntil { ctx.vm.stage == .result }
        #expect(ctx.vm.wasCancelled)
        #expect(ctx.selection.isEmpty)
        try? await Task.sleep(for: .milliseconds(50))
        #expect(await ctx.notifier.calls.isEmpty)
    }

    @Test("dismiss closes the sheet from review and finish navigates")
    func routing() async {
        let ctx = await makeContext()
        await open(ctx)
        ctx.vm.handle(.dismiss)
        #expect(!ctx.router.isReviewPresented)

        ctx.router.isReviewPresented = true
        ctx.vm.handle(.finish(showHistory: true))
        #expect(!ctx.router.isReviewPresented)
        #expect(ctx.router.selection == .history)
        ctx.vm.handle(.finish(showHistory: false))
        #expect(ctx.router.selection == .overview)
    }

    @Test("empty plan cannot be cleaned")
    func emptyPlan() async {
        let ctx = await makeContext(selected: [])
        await open(ctx)
        #expect(ctx.vm.stage == .review)
        #expect(!ctx.vm.canClean)
        #expect(ctx.vm.progressFraction == 0)
    }
}
