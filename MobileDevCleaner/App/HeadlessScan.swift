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
        print("peak memory:    \(ByteFormatter.string(peakFootprint())) (phys_footprint)")
        exit(0)
    }

    /// Same number as Activity Monitor's "Memory"; RSS also counts shared framework pages.
    private static func peakFootprint() -> Int64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int64(info.ledger_phys_footprint_peak) : 0
    }
}
