import Foundation

struct GradleVersionsScanner: CategoryScanner {
    let category: CategoryID = .gvers

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        let dists = context.paths.gradle
            .appending(path: "wrapper", directoryHint: .isDirectory)
            .appending(path: "dists", directoryHint: .isDirectory)

        for subdir in context.subdirectories(of: dists) {
            let name = subdir.lastPathComponent
            let displayName = parseGradleDistName(name) ?? name
            let cost: (@Sendable (Int64) -> String)? = { size in
                let formatted = ByteFormatter.string(size, locale: AppLanguage.current.locale)
                return L10n.string("Se volverá a descargar la próxima vez que abras un proyecto que la use (~\(formatted)).")
            }

            specs.append(CandidateSpec(
                url: subdir,
                name: displayName,
                risk: .hasCost,
                cost: cost
            ))
        }

        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }

    private func parseGradleDistName(_ dirname: String) -> String? {
        let pattern = #"^gradle-(\d+\.\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(dirname.startIndex..<dirname.endIndex, in: dirname)
        guard let match = regex.firstMatch(in: dirname, range: range) else { return nil }
        if let versionRange = Range(match.range(at: 1), in: dirname) {
            return "Gradle \(dirname[versionRange])"
        }
        return nil
    }
}
