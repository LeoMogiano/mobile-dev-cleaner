import Foundation

struct ArchivesScanner: CategoryScanner {
    let category: CategoryID = .archives

    func scan(in context: ScanContext) async -> CategoryReport {
        let archivesRoot = context.paths.archives
        let dateFolders = context.subdirectories(of: archivesRoot)

        var specs: [CandidateSpec] = []
        for dateFolder in dateFolders {
            let xcarchives = context.contents(of: dateFolder).filter { url in
                url.lastPathComponent.hasSuffix(".xcarchive") && context.isDirectory(url)
            }
            for archiveURL in xcarchives {
                let spec = buildArchiveSpec(for: archiveURL, context: context)
                specs.append(spec)
            }
        }

        let candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }

    private func buildArchiveSpec(for archiveURL: URL, context: ScanContext) -> CandidateSpec {
        let infoPlistURL = archiveURL.appending(path: "Info.plist")
        var displayName = archiveURL.lastPathComponent.replacingOccurrences(of: ".xcarchive", with: "")

        do {
            if let dict = try context.plist.dictionary(at: infoPlistURL) {
                if let appName = dict["Name"] as? String {
                    if let appPropsDict = dict["ApplicationProperties"] as? [String: Any],
                       let version = appPropsDict["CFBundleShortVersionString"] as? String {
                        displayName = "\(appName) \(version)"
                    } else {
                        displayName = appName
                    }
                }
            }
        } catch {
        }

        return CandidateSpec(
            url: archiveURL,
            name: displayName,
            risk: .hasCost,
            cost: { _ in
                L10n.string("Pierdes los símbolos para leer crashes de esta versión.")
            }
        )
    }
}
