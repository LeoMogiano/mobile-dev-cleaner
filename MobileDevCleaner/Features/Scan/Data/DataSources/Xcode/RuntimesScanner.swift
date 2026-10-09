import Foundation

struct RuntimesScanner: CategoryScanner {
    let category: CategoryID = .runtimes

    private struct Runtime {
        let identifier: String
        let runtimeIdentifier: String
        let label: String
        let url: URL
        let sizeBytes: Int64
    }

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: .runtimes)
        report.accessDenied = !context.isReadable(context.paths.systemRuntimes)

        async let runtimeJSON = SimulatorsScanner.simctl(["runtime", "list", "-j"], runner: context.runner)
        async let deviceJSON = SimulatorsScanner.simctl(["list", "devices", "--json"], runner: context.runner)
        guard let runtimeJSON = await runtimeJSON else { return report }

        let inUse = Set((await deviceJSON).map(SimulatorsScanner.parseDevices)?.map(\.runtime) ?? [])
        let runtimes = Self.parseRuntimes(runtimeJSON, fallbackRoot: context.paths.systemRuntimes)
            .filter { !inUse.contains($0.runtimeIdentifier) }

        let measured = await context.sizes.sizes(of: runtimes.map(\.url))
        report.candidates = runtimes.compactMap { runtime in
            let size = measured[runtime.url].flatMap { $0 > 0 ? $0 : nil } ?? runtime.sizeBytes
            guard size > 0 else { return nil }
            let label = runtime.label
            let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
            return CleanupCandidate(
                id: runtime.url.path,
                category: .runtimes,
                name: "\(label) Runtime",
                url: runtime.url,
                size: size,
                risk: .hasCost,
                group: nil,
                isOrphan: false,
                modifiedAt: context.modificationDate(runtime.url),
                reason: nil,
                cost: L10n.string("Xcode lo volverá a descargar si creas un simulador con \(label) (\(sizeText))."),
                execution: .command(
                    executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", runtime.identifier]))
        }
        .sortedForDisplay()
        return report
    }

    private static func parseRuntimes(_ json: String, fallbackRoot: URL) -> [Runtime] {
        guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else { return [] }
        return object.sorted { $0.key < $1.key }.compactMap { key, value in
            guard let entry = value as? [String: Any], entry["deletable"] as? Bool ?? true else { return nil }
            let identifier = entry["identifier"] as? String ?? key
            let runtimeIdentifier = entry["runtimeIdentifier"] as? String ?? ""
            let path = (entry["path"] as? String) ?? (entry["runtimeBundlePath"] as? String)
            return Runtime(
                identifier: identifier,
                runtimeIdentifier: runtimeIdentifier,
                label: label(entry, runtimeIdentifier: runtimeIdentifier),
                url: path.map { URL(filePath: $0) } ?? fallbackRoot.appending(path: identifier),
                sizeBytes: (entry["sizeBytes"] as? NSNumber)?.int64Value ?? 0)
        }
    }

    /// "iOS 17.0"
    private static func label(_ entry: [String: Any], runtimeIdentifier: String) -> String {
        let parsed = SimulatorsScanner.osVersion(fromRuntime: runtimeIdentifier)
        let platform = parsed.split(separator: " ").first.map(String.init) ?? platformName(entry["platformIdentifier"] as? String)
        let version = entry["version"] as? String ?? parsed.split(separator: " ").dropFirst().joined(separator: " ")
        return version.isEmpty ? platform : "\(platform) \(version)"
    }

    private static func platformName(_ identifier: String?) -> String {
        switch identifier?.split(separator: ".").last {
        case "appletvsimulator": "tvOS"
        case "watchsimulator": "watchOS"
        case "xrsimulator": "visionOS"
        default: "iOS"
        }
    }
}
