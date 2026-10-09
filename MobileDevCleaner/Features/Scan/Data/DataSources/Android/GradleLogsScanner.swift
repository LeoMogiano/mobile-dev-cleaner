import Foundation

struct GradleLogsScanner: CategoryScanner {
    let category: CategoryID = .glogs

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        let daemon = context.paths.gradle.appending(path: "daemon", directoryHint: .isDirectory)
        if context.exists(daemon) {
            specs.append(CandidateSpec(
                url: daemon,
                name: L10n.string("Logs del daemon"),
                risk: .regenerates
            ))
        }

        if context.exists(context.paths.kotlinDaemon) {
            specs.append(CandidateSpec(
                url: context.paths.kotlinDaemon,
                name: L10n.string("Kotlin daemon"),
                risk: .regenerates
            ))
        }

        let appSupportKotlin = context.paths.applicationSupport
            .appending(path: "kotlin", directoryHint: .isDirectory)
            .appending(path: "daemon", directoryHint: .isDirectory)
        if context.exists(appSupportKotlin) {
            specs.append(CandidateSpec(
                url: appSupportKotlin,
                name: L10n.string("Kotlin daemon (Application Support)"),
                risk: .regenerates
            ))
        }

        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }
}
