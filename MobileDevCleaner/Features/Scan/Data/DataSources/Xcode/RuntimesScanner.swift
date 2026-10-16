import Foundation

struct RuntimesScanner: CategoryScanner {
    let category: CategoryID = .runtimes

    /// Versions per platform kept out of the suggested group.
    static let keptPerPlatform = 2

    private struct Runtime {
        let identifier: String
        let runtimeIdentifier: String
        let platform: String
        let version: String
        let url: URL
        let sizeBytes: Int64

        var label: String { version.isEmpty ? platform : "\(platform) \(version)" }
    }

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: .runtimes)
        report.accessDenied = !context.isReadable(context.paths.systemRuntimes)

        async let runtimeJSON = SimulatorsScanner.simctl(["runtime", "list", "-j"], runner: context.runner)
        async let deviceJSON = SimulatorsScanner.simctl(["list", "devices", "--json"], runner: context.runner)
        guard let runtimeJSON = await runtimeJSON else { return report }

        let devices = Dictionary(grouping: (await deviceJSON).map(SimulatorsScanner.parseDevices) ?? [], by: \.runtime)
        let runtimes = Self.parseRuntimes(runtimeJSON, fallbackRoot: context.paths.systemRuntimes)
            .filter { !(devices[$0.runtimeIdentifier] ?? []).contains(where: \.isBooted) }
        let latest = Self.latestIdentifiers(runtimes)

        let measured = await context.sizes.sizes(of: runtimes.map(\.url))
        report.candidates = runtimes.compactMap { runtime in
            let size = measured[runtime.url].flatMap { $0 > 0 ? $0 : nil } ?? runtime.sizeBytes
            guard size > 0 else { return nil }
            let simulators = devices[runtime.runtimeIdentifier] ?? []
            return CleanupCandidate(
                id: runtime.url.path,
                category: .runtimes,
                name: "\(runtime.label) Runtime",
                url: runtime.url,
                size: size,
                risk: .hasCost,
                group: latest.contains(runtime.identifier) ? .latestRuntimes : .olderRuntimes,
                isOrphan: false,
                modifiedAt: context.modificationDate(runtime.url),
                reason: Self.reason(simulators),
                cost: Self.cost(runtime.label, size: size, simulators: simulators),
                execution: .command(
                    executable: "/usr/bin/xcrun", arguments: ["simctl", "runtime", "delete", runtime.identifier]),
                prerequisites: simulators.map {
                    .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", $0.udid])
                })
        }
        .sortedForDisplay()
        return report
    }

    private static func latestIdentifiers(_ runtimes: [Runtime]) -> Set<String> {
        Set(Dictionary(grouping: runtimes, by: \.platform).values.flatMap { versions in
            versions
                .sorted { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
                .prefix(keptPerPlatform)
                .map(\.identifier)
        })
    }

    private static func reason(_ simulators: [SimulatorEntry]) -> String {
        simulators.isEmpty
            ? L10n.string("Ningún simulador lo usa.")
            : L10n.string("Lo usan \(simulators.count) simuladores: \(names(simulators)).")
    }

    private static func cost(_ label: String, size: Int64, simulators: [SimulatorEntry]) -> String {
        let sizeText = "~\(ByteFormatter.string(size, locale: AppLanguage.current.locale))"
        let redownload = L10n.string("Xcode lo volverá a descargar si creas un simulador con \(label) (\(sizeText)).")
        guard !simulators.isEmpty else { return redownload }
        return L10n.string("También se borran sus \(simulators.count) simuladores (\(names(simulators))). \(redownload)")
    }

    private static func names(_ simulators: [SimulatorEntry]) -> String {
        let shown = simulators.prefix(3).map(\.name).joined(separator: ", ")
        return simulators.count > 3 ? shown + "…" : shown
    }

    private static func parseRuntimes(_ json: String, fallbackRoot: URL) -> [Runtime] {
        guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else { return [] }
        return object.sorted { $0.key < $1.key }.compactMap { key, value in
            guard let entry = value as? [String: Any], entry["deletable"] as? Bool ?? true else { return nil }
            let identifier = entry["identifier"] as? String ?? key
            let runtimeIdentifier = entry["runtimeIdentifier"] as? String ?? ""
            let path = (entry["path"] as? String) ?? (entry["runtimeBundlePath"] as? String)
            let parts = platformAndVersion(entry, runtimeIdentifier: runtimeIdentifier)
            return Runtime(
                identifier: identifier,
                runtimeIdentifier: runtimeIdentifier,
                platform: parts.platform,
                version: parts.version,
                url: path.map { URL(filePath: $0) } ?? fallbackRoot.appending(path: identifier),
                sizeBytes: (entry["sizeBytes"] as? NSNumber)?.int64Value ?? 0)
        }
    }

    /// ("iOS", "17.0")
    private static func platformAndVersion(_ entry: [String: Any], runtimeIdentifier: String) -> (platform: String, version: String) {
        let parsed = SimulatorsScanner.osVersion(fromRuntime: runtimeIdentifier)
        let platform = parsed.split(separator: " ").first.map(String.init) ?? platformName(entry["platformIdentifier"] as? String)
        let version = entry["version"] as? String ?? parsed.split(separator: " ").dropFirst().joined(separator: " ")
        return (platform, version)
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
