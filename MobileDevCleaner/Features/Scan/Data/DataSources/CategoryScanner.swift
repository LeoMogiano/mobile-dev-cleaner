import Foundation

protocol CategoryScanner: Sendable {
    var category: CategoryID { get }
    func scan(in context: ScanContext) async -> CategoryReport
}

/// What a scanner wants listed; `ScanContext.candidates(for:)` measures and builds the rows.
struct CandidateSpec: Sendable {
    let url: URL
    let name: String
    let risk: RiskLevel
    var group: CandidateGroup?
    var isOrphan = false
    var reason: String?
    /// Receives the measured size so copy can say "~4,6 GB".
    var cost: (@Sendable (Int64) -> String)?
    /// Defaults to `.remove(url)`.
    var execution: ExecutionStrategy?
}

struct ScanContext: Sendable {
    let paths: PathProvider
    let sizes: any SizeCalculating
    let runner: any ProcessRunning
    let plist: any PlistReading
    let probe: any ProcessProbing
    /// Shared `pubspec.yaml` discovery for the Flutter scanners (one walk per scan).
    var flutter: any FlutterProjectLocating = NoFlutterProjects()

    /// Direct children (files and folders, hidden included), sorted by name. Missing → [].
    func contents(of url: URL) -> [URL] {
        let items = (try? FileManager.default.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: []
        )) ?? []
        return items.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Direct child folders, symlinks excluded.
    func subdirectories(of url: URL) -> [URL] {
        contents(of: url).filter { isDirectory($0) }
    }

    func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func isDirectory(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        return values?.isDirectory == true && values?.isSymbolicLink != true
    }

    /// False when the folder exists but macOS denies listing it (Full Disk Access).
    func isReadable(_ url: URL) -> Bool {
        guard exists(url) else { return true }
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: url.path)
            return true
        } catch {
            return false
        }
    }

    func modificationDate(_ url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    func readText(_ url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }

    /// Measures all specs in one batch; rows with size 0 or missing paths are dropped.
    func candidates(for specs: [CandidateSpec], category: CategoryID) async -> [CleanupCandidate] {
        let measured = await sizes.sizes(of: specs.map(\.url))
        return specs.compactMap { spec in
            guard let size = measured[spec.url], size > 0 else { return nil }
            return CleanupCandidate(
                id: spec.url.path,
                category: category,
                name: spec.name,
                url: spec.url,
                size: size,
                risk: spec.risk,
                group: spec.group,
                isOrphan: spec.isOrphan,
                modifiedAt: modificationDate(spec.url),
                reason: spec.reason,
                cost: spec.cost?(size),
                execution: spec.execution ?? .remove(spec.url)
            )
        }
    }
}

extension Array where Element == CleanupCandidate {
    /// Group order first, then biggest first.
    func sortedForDisplay() -> [CleanupCandidate] {
        let order = Dictionary(uniqueKeysWithValues: CandidateGroup.allCases.enumerated().map { ($1, $0) })
        return sorted {
            let lhs = $0.group.flatMap { order[$0] } ?? -1
            let rhs = $1.group.flatMap { order[$0] } ?? -1
            return lhs != rhs ? lhs < rhs : $0.size > $1.size
        }
    }
}
