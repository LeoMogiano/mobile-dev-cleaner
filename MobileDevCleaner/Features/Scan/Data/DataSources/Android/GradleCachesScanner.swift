import Foundation

struct GradleCachesScanner: CategoryScanner {
    let category: CategoryID = .gcache

    func scan(in context: ScanContext) async -> CategoryReport {
        var specs: [CandidateSpec] = []

        let caches = context.paths.gradle.appending(path: "caches", directoryHint: .isDirectory)
        for subdir in context.subdirectories(of: caches) {
            let name = subdir.lastPathComponent
            guard name != "modules-2" else { continue }

            let displayName = parseGradleVersion(name) ?? name
            specs.append(CandidateSpec(
                url: subdir,
                name: displayName,
                risk: .regenerates
            ))
        }

        let native = context.paths.gradle.appending(path: "native", directoryHint: .isDirectory)
        if context.exists(native) {
            specs.append(CandidateSpec(
                url: native,
                name: L10n.string("Binarios nativos de Gradle"),
                risk: .regenerates
            ))
        }

        let notifications = context.paths.gradle.appending(path: "notifications", directoryHint: .isDirectory)
        if context.exists(notifications) {
            specs.append(CandidateSpec(
                url: notifications,
                name: L10n.string("Avisos de Gradle"),
                risk: .regenerates
            ))
        }

        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }

    private func parseGradleVersion(_ dirname: String) -> String? {
        let versionPattern = #"^(\d+\.\d+)(?:\.\d+)?$"#
        guard let regex = try? NSRegularExpression(pattern: versionPattern) else { return nil }
        let range = NSRange(dirname.startIndex..<dirname.endIndex, in: dirname)
        guard let match = regex.firstMatch(in: dirname, range: range) else { return nil }
        if let versionRange = Range(match.range(at: 1), in: dirname) {
            return "Gradle \(dirname[versionRange])"
        }
        return nil
    }
}
