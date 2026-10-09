import Foundation

actor ScanRepositoryImpl: ScanRepository {
    private let context: ScanContext
    private let scanners: [any CategoryScanner]

    init(context: ScanContext, scanners: [any CategoryScanner]) {
        self.context = context
        self.scanners = scanners
    }

    nonisolated func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> {
        let selected = scanners.filter { tools.contains($0.category.tool) }
        let context = context
        return AsyncStream { continuation in
            let task = Task {
                let state = Signposts.scan.beginInterval("scan")
                continuation.yield(.started(selected.map(\.category)))
                await context.sizes.syncWithFileChanges()
                var reports: [CategoryID: CategoryReport] = [:]
                await withTaskGroup(of: CategoryReport.self) { group in
                    for scanner in selected {
                        group.addTask {
                            let interval = Signposts.scan.beginInterval("category", "\(scanner.category.rawValue)")
                            defer { Signposts.scan.endInterval("category", interval) }
                            return await scanner.scan(in: context)
                        }
                    }
                    for await report in group {
                        reports[report.id] = report
                        continuation.yield(.categoryFinished(report))
                    }
                }
                await context.sizes.flush()
                Signposts.scan.endInterval("scan", state)
                if !Task.isCancelled {
                    continuation.yield(.finished(ScanResult(scannedAt: .now, reports: reports)))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func invalidateSizes(of urls: [URL]) async {
        await context.sizes.invalidate(urls)
    }
}
