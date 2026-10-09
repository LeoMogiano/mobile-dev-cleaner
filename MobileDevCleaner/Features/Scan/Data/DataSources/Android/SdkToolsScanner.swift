import Foundation

struct SdkToolsScanner: CategoryScanner {
    let category: CategoryID = .ndk

    func scan(in context: ScanContext) async -> CategoryReport {
        guard context.exists(context.paths.androidSdk) else {
            return CategoryReport(id: category)
        }

        var specs: [CandidateSpec] = []
        let entries = context.subdirectories(of: context.paths.androidSdk)

        for entry in entries {
            let name = entry.lastPathComponent
            if name == "ndk" {
                specs.append(contentsOf: scanNdk(in: context, root: entry))
            } else if name == "cmake" {
                specs.append(contentsOf: scanVersioned(in: context, root: entry, kind: "cmake"))
            } else if name == "build-tools" {
                specs.append(contentsOf: scanVersioned(in: context, root: entry, kind: "build-tools"))
            } else if name == "platforms" {
                specs.append(contentsOf: scanPlatforms(in: context, root: entry))
            }
        }

        let candidates = await context.candidates(for: specs, category: category)
        return CategoryReport(id: category, candidates: candidates.sortedForDisplay())
    }

    private func scanNdk(in context: ScanContext, root: URL) -> [CandidateSpec] {
        let versions = context.subdirectories(of: root)
            .map { ($0.lastPathComponent, $0) }
            .sorted { compareVersions($0.0, $1.0) > 0 }

        var specs: [CandidateSpec] = []
        for (index, (version, url)) in versions.enumerated() {
            let isNewest = index == 0
            let reason = isNewest ? L10n.string("Probablemente es la versión que usas.") : nil
            specs.append(CandidateSpec(
                url: url,
                name: L10n.string("NDK \(version)"),
                risk: .hasCost,
                reason: reason,
                cost: { size in
                    L10n.string("Se volverá a descargar si un proyecto la pide (~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))).")
                }
            ))
        }
        return specs
    }

    private func scanVersioned(in context: ScanContext, root: URL, kind: String) -> [CandidateSpec] {
        let versions = context.subdirectories(of: root)
            .map { ($0.lastPathComponent, $0) }
            .sorted { compareVersions($0.0, $1.0) > 0 }

        var specs: [CandidateSpec] = []
        for (index, (version, url)) in versions.enumerated() {
            let isNewest = index == 0
            let reason = isNewest ? L10n.string("Probablemente es la versión que usas.") : nil
            specs.append(CandidateSpec(
                url: url,
                name: L10n.string("\(kind) \(version)"),
                risk: .hasCost,
                reason: reason,
                cost: { size in
                    L10n.string("Se volverá a descargar si un proyecto la pide (~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))).")
                }
            ))
        }
        return specs
    }

    private func scanPlatforms(in context: ScanContext, root: URL) -> [CandidateSpec] {
        let versions = context.subdirectories(of: root)
            .map { ($0.lastPathComponent, $0) }
            .sorted { compareVersions($0.0, $1.0) > 0 }

        var specs: [CandidateSpec] = []
        for (index, (version, url)) in versions.enumerated() {
            let isNewest = index == 0
            let reason = isNewest ? L10n.string("Probablemente es la versión que usas.") : nil
            specs.append(CandidateSpec(
                url: url,
                name: L10n.string("Plataforma \(version)"),
                risk: .hasCost,
                reason: reason,
                cost: { size in
                    L10n.string("Se volverá a descargar si un proyecto la pide (~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))).")
                }
            ))
        }
        return specs
    }

    /// Numeric dot-separated compare: "25.1.8937393" > "25.0.1".
    private func compareVersions(_ a: String, _ b: String) -> Int {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }

        let maxLen = max(aParts.count, bParts.count)
        for i in 0..<maxLen {
            let aPart = i < aParts.count ? aParts[i] : 0
            let bPart = i < bParts.count ? bParts[i] : 0
            if aPart != bPart { return aPart - bPart }
        }
        return 0
    }
}
