import Foundation

struct SystemImagesScanner: CategoryScanner {
    let category: CategoryID = .sysimg

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: .sysimg)
        let root = context.paths.androidSdk.appending(path: "system-images", directoryHint: .isDirectory)
        let avds = AVDConfigReader.read(in: context)

        var specs: [CandidateSpec] = []
        for api in context.subdirectories(of: root) {
            for variant in context.subdirectories(of: api) {
                for abi in context.subdirectories(of: variant) {
                    let relative = [root.lastPathComponent, api.lastPathComponent, variant.lastPathComponent, abi.lastPathComponent]
                        .joined(separator: "/")
                    let users = avds.filter { Self.normalized($0.systemImagePath).hasSuffix(relative) }.map(\.displayName)
                    specs.append(Self.spec(url: abi, api: api.lastPathComponent, variant: variant.lastPathComponent, users: users))
                }
            }
        }
        report.candidates = await context.candidates(for: specs, category: .sysimg).sortedForDisplay()
        return report
    }

    private static func normalized(_ path: String?) -> String {
        var value = (path ?? "").trimmingCharacters(in: .whitespaces)
        while value.hasSuffix("/") { value.removeLast() }
        return value
    }

    private static func spec(url: URL, api: String, variant: String, users: [String]) -> CandidateSpec {
        let used = !users.isEmpty
        let joined = users.joined(separator: ", ")
        return CandidateSpec(
            url: url,
            name: name(api: api, variant: variant),
            risk: .hasCost,
            group: used ? .usedByEmulators : .unusedByEmulators,
            isOrphan: !used,
            cost: { size in
                let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
                return used
                    ? L10n.string("\(joined) no arrancará hasta volver a descargarla (\(sizeText)).")
                    : L10n.string("Ningún emulador la usa. Si la necesitas, se descarga de nuevo (\(sizeText)).")
            })
    }

    /// "Android 14 · API 34 · Google Play"
    private static func name(api: String, variant: String) -> String {
        var parts: [String] = []
        if let level = AVDConfigReader.apiLevel(from: api) {
            if let version = AVDConfigReader.androidVersion(api: level) { parts.append("Android \(version)") }
            parts.append("API \(level)")
        } else {
            parts.append(api)
        }
        switch variant {
        case "default": break
        case "google_apis_playstore": parts.append("Google Play")
        case "google_apis": parts.append("Google APIs")
        default: parts.append(variant)
        }
        return parts.joined(separator: " · ")
    }
}
