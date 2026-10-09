import Foundation

struct DerivedDataScanner: CategoryScanner {
    let category: CategoryID = .builds

    func scan(in context: ScanContext) async -> CategoryReport {
        let root = context.paths.derivedData
        let subdirs = context.subdirectories(of: root)

        var specs: [CandidateSpec] = []
        var projectNameCounts: [String: Int] = [:]

        for dir in subdirs {
            do {
                let infoPlistURL = dir.appending(path: "info.plist")
                if context.exists(infoPlistURL) {
                    if let workspacePath = try context.plist.string(forKey: "WorkspacePath", at: infoPlistURL) {
                        if context.exists(URL(filePath: workspacePath)) {
                            let projectName = URL(filePath: workspacePath)
                                .lastPathComponent
                                .replacingOccurrences(of: ".xcodeproj", with: "")
                                .replacingOccurrences(of: ".xcworkspace", with: "")
                            projectNameCounts[projectName, default: 0] += 1
                        }
                    }
                }
            } catch {
                continue
            }
        }

        for dir in subdirs {
            let folderName = dir.lastPathComponent
            let spec = buildCandidateSpec(
                for: dir,
                folderName: folderName,
                projectNameCounts: projectNameCounts,
                context: context
            )
            specs.append(spec)
        }

        let candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }

    private func buildCandidateSpec(
        for dir: URL,
        folderName: String,
        projectNameCounts: [String: Int],
        context: ScanContext
    ) -> CandidateSpec {
        let infoPlistURL = dir.appending(path: "info.plist")

        if folderName.hasSuffix(".noindex") {
            let name = folderName.replacingOccurrences(of: ".noindex", with: "")
            return CandidateSpec(
                url: dir,
                name: name,
                risk: .regenerates,
                group: .sharedCache
            )
        }

        do {
            if let workspacePath = try context.plist.string(forKey: "WorkspacePath", at: infoPlistURL) {
                if context.exists(URL(filePath: workspacePath)) {
                    let projectURL = URL(filePath: workspacePath)
                    var projectName = projectURL.lastPathComponent
                        .replacingOccurrences(of: ".xcodeproj", with: "")
                        .replacingOccurrences(of: ".xcworkspace", with: "")

                    if let count = projectNameCounts[projectName], count > 1 {
                        let parentName = projectURL.deletingLastPathComponent().lastPathComponent
                        projectName = "\(parentName)/\(projectName)"
                    }

                    return CandidateSpec(
                        url: dir,
                        name: projectName,
                        risk: .regenerates,
                        group: .projects
                    )
                }
            }
        } catch {
        }

        let cleanedName = stripTrailingHash(from: folderName)
        return CandidateSpec(
            url: dir,
            name: cleanedName,
            risk: .regenerates,
            group: .orphanProjects,
            isOrphan: true,
            reason: L10n.string("El proyecto ya no existe en tu disco. Nadie lo va a regenerar.")
        )
    }

    private func stripTrailingHash(from name: String) -> String {
        guard let lastDashIdx = name.lastIndex(of: "-") else { return name }
        let afterDash = name[name.index(after: lastDashIdx)...]
        if afterDash.count == 28 && afterDash.allSatisfy({ $0.isLowercase }) {
            return String(name[..<lastDashIdx])
        }
        return name
    }
}
