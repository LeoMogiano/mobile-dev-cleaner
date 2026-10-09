import Foundation

struct AndroidCachesScanner: CategoryScanner {
    let category: CategoryID = .acache

    func scan(in context: ScanContext) async -> CategoryReport {
        let android = context.paths.android
        var specs = [
            CandidateSpec(url: android.appending(path: "cache"), name: L10n.string("Caché de herramientas"), risk: .regenerates),
            CandidateSpec(url: android.appending(path: "build-cache"), name: L10n.string("Build cache de Android"), risk: .regenerates),
            CandidateSpec(url: android.appending(path: "metrics"), name: L10n.string("Métricas de Android"), risk: .regenerates),
        ]
        // Only the version in use; older versions belong to "Versiones viejas de Studio".
        let caches = context.paths.caches.appending(path: "Google", directoryHint: .isDirectory)
        let logs = context.paths.logs.appending(path: "Google", directoryHint: .isDirectory)
        if let current = StudioVersion.newest(in: StudioVersion.roots(in: context.paths).map(\.url), context: context) {
            for (version, url) in StudioVersion.folders(in: caches, context: context) where version == current {
                specs.append(CandidateSpec(url: url, name: L10n.string("Caché de Android Studio"), risk: .regenerates))
            }
            for (version, url) in StudioVersion.folders(in: logs, context: context) where version == current {
                specs.append(CandidateSpec(url: url, name: L10n.string("Logs de Android Studio"), risk: .regenerates))
            }
        }
        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }
}
