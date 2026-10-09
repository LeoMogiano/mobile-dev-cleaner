import SwiftUI

enum ScanIntent: Sendable {
    case start
    case cancel
}

/// App-wide scan state shared by sidebar, dashboard and category views.
@MainActor @Observable
final class ScanStore {
    enum Status: Equatable {
        case idle
        case scanning
        case finished(Date)
    }

    private(set) var status: Status = .idle
    private(set) var reports: [CategoryID: CategoryReport] = [:]
    private(set) var pending: Set<CategoryID> = []
    private(set) var scannedCategories: [CategoryID] = []

    @ObservationIgnored private let scan: ScanUseCase
    @ObservationIgnored private let flushInterval: Duration
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var flushTask: Task<Void, Never>?
    @ObservationIgnored private var buffer: [CategoryReport] = []
    @ObservationIgnored private var generation = 0

    init(scan: ScanUseCase, flushInterval: Duration = .milliseconds(100)) {
        self.scan = scan
        self.flushInterval = flushInterval
    }

    func handle(_ intent: ScanIntent) {
        switch intent {
        case .start: start()
        case .cancel: cancel()
        }
    }

    func report(for id: CategoryID) -> CategoryReport? { reports[id] }

    var totalSize: Int64 { reports.values.reduce(0) { $0 + $1.totalSize } }
    var regeneratesSize: Int64 { reports.values.reduce(0) { $0 + $1.regeneratesSize } }
    var hasCostSize: Int64 { totalSize - regeneratesSize }

    var progress: Double { progress(of: scannedCategories) }

    func progress(for tool: Tool) -> Double {
        progress(of: scannedCategories.filter { $0.tool == tool })
    }

    /// Root path of the first category still being measured.
    var currentPath: String? {
        scannedCategories.first { pending.contains($0) }.map { CategoryInfo.info(for: $0).displayPath }
    }

    private func progress(of ids: [CategoryID]) -> Double {
        guard !ids.isEmpty else { return status == .idle ? 0 : 1 }
        return Double(ids.filter { !pending.contains($0) }.count) / Double(ids.count)
    }

    private func start() {
        stopTasks()
        generation += 1
        let current = generation
        status = .scanning
        scannedCategories = CategoryID.allCases
        pending = Set(CategoryID.allCases)
        scanTask = Task { [scan] in
            for await event in scan() {
                guard !Task.isCancelled, current == generation else { return }
                consume(event)
            }
        }
    }

    private func cancel() {
        stopTasks()
        generation += 1
        buffer.removeAll()
        pending = []
        if status == .scanning { status = .idle }
    }

    private func stopTasks() {
        scanTask?.cancel()
        flushTask?.cancel()
        scanTask = nil
        flushTask = nil
        buffer.removeAll()
    }

    private func consume(_ event: ScanEvent) {
        switch event {
        case .started(let ids):
            scannedCategories = ids
            pending = Set(ids)
        case .categoryFinished(let report):
            buffer.append(report)
            scheduleFlush()
        case .finished(let result):
            flushTask?.cancel()
            flushTask = nil
            buffer.removeAll()
            reports = result.reports
            pending = []
            status = .finished(result.scannedAt)
        }
    }

    private func scheduleFlush() {
        guard flushTask == nil else { return }
        flushTask = Task { [flushInterval] in
            try? await Task.sleep(for: flushInterval)
            guard !Task.isCancelled else { return }
            flush()
        }
    }

    private func flush() {
        flushTask = nil
        guard !buffer.isEmpty else { return }
        var merged = reports
        var remaining = pending
        for report in buffer {
            merged[report.id] = report
            remaining.remove(report.id)
        }
        buffer.removeAll()
        reports = merged
        pending = remaining
    }
}
