import Foundation

struct EmulatorsScanner: CategoryScanner {
    let category: CategoryID = .avds

    private struct Layout {
        let config: AVDConfig
        let data: [URL]
        let cache: [URL]
        let snapshots: URL

        var urls: [URL] { [config.url, snapshots] + data + cache }
    }

    func scan(in context: ScanContext) async -> CategoryReport {
        var report = CategoryReport(id: .avds)
        let layouts = AVDConfigReader.read(in: context)
            .filter { context.exists($0.url) }
            .map(Self.layout)
        guard !layouts.isEmpty else { return report }

        let running = await context.probe.runningApps().runningAVDs
        let measured = await context.sizes.sizes(of: layouts.flatMap(\.urls))
        let avdmanager = context.paths.androidSdk.appending(path: "cmdline-tools/latest/bin/avdmanager")
        let hasManager = context.exists(avdmanager)

        report.devices = layouts.compactMap { layout in
            Self.device(from: layout, measured: measured, isRunning: running.contains(layout.config.name),
                        avdmanager: hasManager ? avdmanager : nil, avdIni: context.paths.avd, context: context)
        }
        .sorted { $0.sizes.total > $1.sizes.total }
        return report
    }

    private static func layout(for config: AVDConfig) -> Layout {
        func files(_ names: [String]) -> [URL] { names.map { config.url.appending(path: $0) } }
        return Layout(
            config: config,
            data: files(["userdata-qemu.img", "userdata-qemu.img.qcow2", "userdata.img", "sdcard.img", "sdcard.img.qcow2"]),
            cache: files(["cache.img", "cache.img.qcow2", "tmpAdbCmds"]),
            snapshots: config.url.appending(path: "snapshots", directoryHint: .isDirectory))
    }

    private static func osVersion(_ config: AVDConfig) -> String {
        guard let api = config.apiLevel else { return "Android" }
        return AVDConfigReader.androidVersion(api: api).map { "API \(api) · Android \($0)" } ?? "API \(api)"
    }

    private static func device(
        from layout: Layout, measured: [URL: Int64], isRunning: Bool,
        avdmanager: URL?, avdIni: URL, context: ScanContext
    ) -> DeviceCandidate? {
        func sum(_ urls: [URL]) -> Int64 { urls.reduce(0) { $0 + (measured[$1] ?? 0) } }
        let config = layout.config
        let total = measured[config.url] ?? 0
        guard total > 0 else { return nil }

        let data = sum(layout.data)
        let cache = sum(layout.cache)
        let snapshots = measured[layout.snapshots] ?? 0
        let sizes = DeviceSizes(data: data, cache: cache, snapshots: snapshots, other: max(0, total - data - cache - snapshots))

        let existing = { (urls: [URL]) in urls.filter(context.exists).map { ExecutionStrategy.remove($0) } }
        let deleteSteps: [ExecutionStrategy] = avdmanager.map {
            [.command(executable: $0.path, arguments: ["delete", "avd", "-n", config.name])]
        } ?? [.remove(config.url), .remove(avdIni.appending(path: "\(config.name).ini"))]

        let isTablet = [config.deviceType, config.displayName].contains { $0?.localizedCaseInsensitiveContains("tablet") == true }
        return DeviceCandidate(
            id: config.name,
            category: .avds,
            name: config.displayName,
            osVersion: osVersion(config),
            kind: isTablet ? .tablet : .phone,
            url: config.url,
            sizes: sizes,
            isRunning: isRunning,
            isAvailable: true,
            plans: [
                DeviceActionPlan(action: .clean, risk: .regenerates, freedBytes: cache + snapshots,
                                 steps: existing([layout.snapshots] + layout.cache)),
                DeviceActionPlan(action: .reset, risk: .hasCost, freedBytes: data + cache + snapshots,
                                 steps: existing(layout.data)),
                DeviceActionPlan(action: .delete, risk: .hasCost, freedBytes: sizes.total, steps: deleteSteps),
            ])
    }
}
