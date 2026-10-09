import Foundation

struct FvmVersionsScanner: CategoryScanner {
    let category: CategoryID = .fvm

    func scan(in context: ScanContext) async -> CategoryReport {
        let versions = context.paths.fvmVersions
        guard context.isDirectory(versions) else { return CategoryReport(id: category, isApplicable: false) }

        var inUse = Set(await context.flutter.projects().compactMap(\.fvmVersion))
        let globalDefault = context.paths.fvm.appending(path: "default")
        if let target = try? FileManager.default.destinationOfSymbolicLink(atPath: globalDefault.path) {
            let resolved = URL(filePath: target, relativeTo: context.paths.fvm).resolvingSymlinksInPath()
            if resolved.deletingLastPathComponent().resolvingSymlinksInPath() == versions.resolvingSymlinksInPath() {
                inUse.insert(resolved.lastPathComponent)
            }
        }

        let specs = context.subdirectories(of: versions).map { dir -> CandidateSpec in
            let used = inUse.contains(dir.lastPathComponent)
            return CandidateSpec(
                url: dir,
                name: "Flutter \(dir.lastPathComponent)",
                risk: .hasCost,
                group: used ? .usedByProjects : .unusedByProjects,
                reason: used ? nil : L10n.string("Ningún proyecto la usa"),
                cost: { size in
                    let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
                    return L10n.string("Se descargará de nuevo (\(sizeText)) con fvm install.")
                })
        }
        var report = CategoryReport(id: category)
        report.candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return report
    }
}
