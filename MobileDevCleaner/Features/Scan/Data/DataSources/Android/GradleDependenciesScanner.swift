import Foundation

struct GradleDependenciesScanner: CategoryScanner {
    let category: CategoryID = .gdeps

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        let modules2 = context.paths.gradle
            .appending(path: "caches", directoryHint: .isDirectory)
            .appending(path: "modules-2", directoryHint: .isDirectory)

        for subdir in context.subdirectories(of: modules2) {
            let name = subdir.lastPathComponent
            let cost: (@Sendable (Int64) -> String)? = { size in
                let formatted = ByteFormatter.string(size, locale: AppLanguage.current.locale)
                if name == "files-2.1" {
                    return L10n.string("Gradle volverá a descargar ~\(formatted) en el próximo build.")
                } else if name.starts(with: "metadata") {
                    return L10n.string("Se reconstruye al resolver dependencias (~\(formatted)).")
                } else {
                    return L10n.string("Gradle lo reconstruye en el próximo build (~\(formatted)).")
                }
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
