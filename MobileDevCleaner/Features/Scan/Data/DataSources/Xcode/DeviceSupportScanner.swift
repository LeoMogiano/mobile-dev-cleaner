import Foundation

struct DeviceSupportScanner: CategoryScanner {
    let category: CategoryID = .devsup

    func scan(in context: ScanContext) async -> CategoryReport {
        let platformPaths = [
            ("iOS DeviceSupport", "iOS"),
            ("watchOS DeviceSupport", "watchOS"),
            ("tvOS DeviceSupport", "tvOS"),
            ("visionOS DeviceSupport", "visionOS"),
        ]

        var specs: [CandidateSpec] = []
        for (folderName, platformName) in platformPaths {
            let platformPath = context.paths.xcode.appending(path: folderName)
            let subdirs = context.subdirectories(of: platformPath)
            for subdir in subdirs {
                let displayName = formatDeviceSupportName(subdir.lastPathComponent, platform: platformName)
                specs.append(CandidateSpec(
                    url: subdir,
                    name: displayName,
                    risk: .regenerates
                ))
            }
        }

        let candidates = await context.candidates(for: specs, category: category).sortedForDisplay()
        return CategoryReport(id: category, candidates: candidates)
    }

    private func formatDeviceSupportName(_ folderName: String, platform: String) -> String {
        // "iPhone15,2 17.5 (21F79)" or "17.5 (21F79)"

        let withoutBuild = folderName
            .replacingOccurrences(of: #"\s*\([^)]+\)\s*$"#, with: "", options: .regularExpression)

        if withoutBuild.contains(",") {
            return withoutBuild.replacingOccurrences(of: " ", with: " · \(platform) ")
        } else {
            return "\(platform) \(withoutBuild)"
        }
    }
}
