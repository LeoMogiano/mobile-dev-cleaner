import Foundation

struct CategoryReport: Sendable, Hashable {
    let id: CategoryID
    var candidates: [CleanupCandidate] = []
    var devices: [DeviceCandidate] = []
    /// Some paths could not be read (Full Disk Access missing).
    var accessDenied = false
    /// False when the tool behind the category is not installed (FVM): hidden everywhere,
    /// even with "Mostrar categorías vacías".
    var isApplicable = true

    var totalSize: Int64 {
        candidates.reduce(0) { $0 + $1.size } + devices.reduce(0) { $0 + $1.sizes.total }
    }

    /// Device cache and snapshots regenerate; app data does not.
    var regeneratesSize: Int64 {
        candidates.filter { $0.risk == .regenerates }.reduce(0) { $0 + $1.size }
            + devices.reduce(0) { $0 + $1.sizes.cache + $1.sizes.snapshots }
    }

    var hasCostSize: Int64 { totalSize - regeneratesSize }

    var isEmpty: Bool { candidates.isEmpty && devices.isEmpty }
}

struct ScanResult: Sendable, Hashable {
    let scannedAt: Date
    var reports: [CategoryID: CategoryReport]

    var totalSize: Int64 { reports.values.reduce(0) { $0 + $1.totalSize } }
}

enum ScanEvent: Sendable {
    case started([CategoryID])
    case categoryFinished(CategoryReport)
    case finished(ScanResult)
}
