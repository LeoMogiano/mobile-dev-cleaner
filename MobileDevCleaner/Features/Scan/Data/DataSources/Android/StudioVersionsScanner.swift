import Foundation

struct StudioVersionsScanner: CategoryScanner {
    let category: CategoryID = .studio

    func scan(in context: ScanContext) async -> CategoryReport {
        let roots = StudioVersion.roots(in: context.paths)
        guard let current = StudioVersion.newest(in: roots.map(\.url), context: context) else {
            return CategoryReport(id: category)
        }

        var specs: [CandidateSpec] = []
        for root in roots {
            for (version, url) in StudioVersion.folders(in: root.url, context: context) where version != current {
                specs.append(spec(for: version, url: url, kind: root.kind))
            }
        }
        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }

    private func spec(for version: StudioVersion, url: URL, kind: StudioVersion.Root.Kind) -> CandidateSpec {
        switch kind {
        case .settings, .preferences:
            let suffix = kind == .preferences ? L10n.string(" (preferencias)") : ""
            let label = version.codename ?? version.number
            return CandidateSpec(
                url: url, name: "Android Studio \(version.displayName)\(suffix)", risk: .hasCost,
                cost: { _ in L10n.string("Pierdes los ajustes y plugins de \(label). Tu versión actual no cambia.") }
            )
        case .caches:
            return CandidateSpec(url: url, name: L10n.string("Caché de Studio \(version.number)"), risk: .regenerates)
        case .logs:
            return CandidateSpec(url: url, name: L10n.string("Logs de Studio \(version.number)"), risk: .regenerates)
        }
    }
}

struct StudioVersion: Hashable, Comparable, Sendable {
    let year: Int
    let minor: Int

    struct Root {
        enum Kind { case settings, preferences, caches, logs }
        let url: URL
        let kind: Kind
    }

    var number: String { "\(year).\(minor)" }
    var displayName: String { codename.map { "\($0) \(number)" } ?? number }

    var codename: String? {
        switch (year, minor) {
        case (2022, 1): "Electric Eel"
        case (2022, 2): "Flamingo"
        case (2022, 3): "Giraffe"
        case (2023, 1): "Hedgehog"
        case (2023, 2): "Iguana"
        case (2023, 3): "Jellyfish"
        case (2024, 1): "Koala"
        case (2024, 2): "Ladybug"
        case (2024, 3): "Meerkat"
        case (2025, 1): "Narwhal"
        default: nil
        }
    }

    static func < (lhs: StudioVersion, rhs: StudioVersion) -> Bool {
        (lhs.year, lhs.minor) < (rhs.year, rhs.minor)
    }

    /// "AndroidStudio2023.1", "AndroidStudioPreview2024.3" (a preview counts as that version).
    init?(folderName: String) {
        guard let match = folderName.firstMatch(of: /^AndroidStudio(?:Preview)?(\d{4})\.(\d+)/),
              let year = Int(match.1), let minor = Int(match.2) else { return nil }
        self.year = year
        self.minor = minor
    }

    static func roots(in paths: PathProvider) -> [Root] {
        [
            Root(url: paths.applicationSupport.appending(path: "Google", directoryHint: .isDirectory), kind: .settings),
            Root(url: paths.preferences, kind: .preferences),
            Root(url: paths.caches.appending(path: "Google", directoryHint: .isDirectory), kind: .caches),
            Root(url: paths.caches.appending(path: "JetBrains", directoryHint: .isDirectory), kind: .caches),
            Root(url: paths.logs.appending(path: "Google", directoryHint: .isDirectory), kind: .logs),
        ]
    }

    static func folders(in root: URL, context: ScanContext) -> [(StudioVersion, URL)] {
        context.contents(of: root).compactMap { url in
            StudioVersion(folderName: url.lastPathComponent).map { ($0, url) }
        }
    }

    static func newest(in roots: [URL], context: ScanContext) -> StudioVersion? {
        roots.flatMap { folders(in: $0, context: context).map(\.0) }.max()
    }
}
