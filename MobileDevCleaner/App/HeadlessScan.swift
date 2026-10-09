import Foundation

/// `MobileDevCleaner --scan-report [--cold]`: read-only scan of the real disk that prints
/// timings and per-category totals, then exits. Used for the performance gate.
enum HeadlessScan {
    static var isRequested: Bool { CommandLine.arguments.contains("--scan-report") }

    @MainActor
    static func run() async -> Never {
        if CommandLine.arguments.contains("--cold") {
            let sizes: any SizeCalculating = sl()
            await sizes.clearCache()
        }
        let scan: ScanUseCase = sl()
        let clock = ContinuousClock()
        let start = clock.now
        var firstCategory: Duration?
        var result: ScanResult?

        for await event in scan() {
            switch event {
            case .started:
                break
            case .categoryFinished(let report):
                if firstCategory == nil { firstCategory = clock.now - start }
                let elapsed = (clock.now - start).formatted(.units(allowed: [.milliseconds]))
                print(String(format: "%-9@ %12lld bytes  %3d items %2d devices  %@%@",
                             report.id.rawValue, report.totalSize, report.candidates.count, report.devices.count,
                             elapsed, report.accessDenied ? "  (access denied)" : ""))
            case .finished(let scanResult):
                result = scanResult
            }
        }

        let total = clock.now - start
        print("first category: \(firstCategory?.formatted(.units(allowed: [.milliseconds])) ?? "-")")
        print("total time:     \(total.formatted(.units(allowed: [.milliseconds])))")
        print("total size:     \(result?.totalSize ?? 0) bytes (\(ByteFormatter.string(result?.totalSize ?? 0)))")
        exit(0)
    }
}
