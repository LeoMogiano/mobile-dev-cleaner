import Foundation

struct GradleJdksScanner: CategoryScanner {
    let category: CategoryID = .jdks

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        let jdks = context.paths.gradle.appending(path: "jdks", directoryHint: .isDirectory)
        for subdir in context.subdirectories(of: jdks) {
            let name = subdir.lastPathComponent
            let cost: (@Sendable (Int64) -> String)? = { size in
                let formatted = ByteFormatter.string(size, locale: AppLanguage.current.locale)
                return L10n.string("Gradle lo volverá a descargar si un proyecto lo pide (~\(formatted)).")
            }

            specs.append(CandidateSpec(
                url: subdir,
                name: name,
                risk: .hasCost,
                cost: cost
            ))
        }

        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }
}
