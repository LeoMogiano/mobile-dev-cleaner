import Foundation

struct SimulatorEntry: Sendable, Hashable {
    /// "com.apple.CoreSimulator.SimRuntime.iOS-18-2"
    let runtime: String
    let udid: String
    let name: String
    let isBooted: Bool
    let isAvailable: Bool
    let typeIdentifier: String
}

struct SimulatorsScanner: CategoryScanner {
    let category: CategoryID = .sims

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: .sims)
        guard let json = await Self.simctl(["list", "devices", "--json"], runner: context.runner) else { return report }

        let layouts = Self.parseDevices(json).compactMap { layout(for: $0, in: context) }
        let measured = await context.sizes.sizes(of: layouts.flatMap(\.urls))

        report.devices = layouts
            .compactMap { Self.device(from: $0, measured: measured) }
            .sorted { $0.sizes.total > $1.sizes.total }
        return report
    }

    // MARK: - Parsing

    static func simctl(_ arguments: [String], runner: any ProcessRunning) async -> String? {
        guard let result = try? await runner.run("/usr/bin/xcrun", arguments: ["simctl"] + arguments),
              result.succeeded, !result.stdout.isEmpty else { return nil }
        return result.stdout
    }

    static func parseDevices(_ json: String) -> [SimulatorEntry] {
        guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let byRuntime = object["devices"] as? [String: Any] else { return [] }
        return byRuntime.sorted { $0.key < $1.key }.flatMap { runtime, value -> [SimulatorEntry] in
            (value as? [[String: Any]] ?? []).compactMap { device in
                guard let udid = device["udid"] as? String else { return nil }
                return SimulatorEntry(
                    runtime: runtime,
                    udid: udid,
                    name: device["name"] as? String ?? udid,
                    isBooted: device["state"] as? String == "Booted",
                    isAvailable: device["isAvailable"] as? Bool ?? true,
                    typeIdentifier: device["deviceTypeIdentifier"] as? String ?? ""
                )
            }
        }
    }

    /// "com.apple.CoreSimulator.SimRuntime.iOS-18-2" → "iOS 18.2".
    static func osVersion(fromRuntime runtime: String) -> String {
        let last = runtime.split(separator: ".").last.map(String.init) ?? runtime
        let parts = last.split(separator: "-").map(String.init)
        guard let platform = parts.first else { return runtime }
        let version = parts.dropFirst().joined(separator: ".")
        return version.isEmpty ? platform : "\(platform) \(version)"
    }

    static func kind(fromType identifier: String) -> DeviceKind {
        if identifier.contains("Watch") { return .watch }
        if identifier.contains("Apple-TV") { return .tv }
        if identifier.contains("Vision") { return .vision }
        if identifier.contains("iPad") { return .ipad }
        return .iphone
    }

    // MARK: - Layout

    private struct Layout {
        let entry: SimulatorEntry
        let dir: URL
        let dataDir: URL
        let cachePaths: [URL]
        let snapshotPaths: [URL]

        var urls: [URL] { [dir, dataDir] + cachePaths + snapshotPaths }
    }

    private func layout(for entry: SimulatorEntry, in context: ScanContext) -> Layout? {
        let dir = context.paths.coreSimulatorDevices.appending(path: entry.udid, directoryHint: .isDirectory)
        guard context.exists(dir) else { return nil }
        let data = dir.appending(path: "data", directoryHint: .isDirectory)
        let apps = context.subdirectories(
            of: data.appending(path: "Containers/Data/Application", directoryHint: .isDirectory))

        let roots = [data] + apps
        let caches = roots.flatMap { root in
            root == data
                ? ["Library/Caches", "tmp", "Library/Logs"].map { root.appending(path: $0, directoryHint: .isDirectory) }
                : ["Library/Caches", "tmp"].map { root.appending(path: $0, directoryHint: .isDirectory) }
        }
        let snapshots = roots.map { $0.appending(path: "Library/SplashBoard", directoryHint: .isDirectory) }

        return Layout(
            entry: entry, dir: dir, dataDir: data,
            cachePaths: caches.filter(context.exists), snapshotPaths: snapshots.filter(context.exists))
    }

    private static func device(from layout: Layout, measured: [URL: Int64]) -> DeviceCandidate? {
        func sum(_ urls: [URL]) -> Int64 { urls.reduce(0) { $0 + (measured[$1] ?? 0) } }
        let total = measured[layout.dir] ?? 0
        guard total > 0 else { return nil }

        let dataDir = measured[layout.dataDir] ?? 0
        let cache = sum(layout.cachePaths)
        let snapshots = sum(layout.snapshotPaths)
        let sizes = DeviceSizes(
            data: max(0, dataDir - cache - snapshots),
            cache: cache,
            snapshots: snapshots,
            other: max(0, total - dataDir))

        let entry = layout.entry
        let udid = entry.udid
        let plans = [
            DeviceActionPlan(
                action: .clean, risk: .regenerates, freedBytes: cache + snapshots,
                steps: (layout.cachePaths + layout.snapshotPaths).map { .remove($0) }),
            DeviceActionPlan(
                action: .reset, risk: .hasCost, freedBytes: sizes.data + cache + snapshots,
                steps: [.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "erase", udid])]),
            DeviceActionPlan(
                action: .delete, risk: .hasCost, freedBytes: sizes.total,
                steps: [.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", udid])]),
        ]

        return DeviceCandidate(
            id: udid,
            category: .sims,
            name: entry.isAvailable ? entry.name : entry.name + L10n.string(" (no disponible)"),
            osVersion: osVersion(fromRuntime: entry.runtime),
            kind: kind(fromType: entry.typeIdentifier),
            url: layout.dir,
            sizes: sizes,
            isRunning: entry.isBooted,
            isAvailable: entry.isAvailable,
            plans: plans)
    }
}
