import Foundation

struct PlanTransferRepositoryImpl: PlanTransferRepository {
    func export(
        reports: [CategoryID: CategoryReport], candidateIDs: Set<String>, deviceActions: [String: DeviceAction]
    ) async -> Either<Failure, Data> {
        await Either.catching(domain: "export_plan") {
            var toolReports: [String: MdcPlanFile.Report] = [:]
            for id in CategoryID.allCases {
                guard let report = reports[id] else { continue }
                let tool = id.tool.rawValue
                var entry = toolReports[tool] ?? MdcPlanFile.Report(tool: tool, candidates: [], containers: [])
                entry.candidates += report.candidates
                    .filter { candidateIDs.contains($0.id) }
                    .map { candidate(for: $0, tool: tool) }
                entry.containers += report.devices.compactMap { device in
                    deviceActions[device.id].flatMap { container(for: device, action: $0, tool: tool) }
                }
                toolReports[tool] = entry
            }
            let file = MdcPlanFile(scannedAt: ISO8601DateFormatter().string(from: .now), reports: toolReports)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(file)
        }
    }

    private func candidate(for candidate: CleanupCandidate, tool: String) -> MdcPlanFile.Candidate {
        MdcPlanFile.Candidate(
            id: candidate.id, path: candidate.url.path, displayName: candidate.name,
            risk: nodeRisk(candidate.risk), category: categoryToNode(candidate.category), tool: tool,
            size: candidate.size, reason: candidate.reason ?? "", execution: executionToNode(candidate.execution),
            group: candidate.group?.rawValue, selected: true)
    }

    private func container(for device: DeviceCandidate, action: DeviceAction, tool: String) -> MdcPlanFile.Container? {
        guard device.plan(for: action) != nil else { return nil }
        return MdcPlanFile.Container(
            id: device.id, path: device.url.path, name: device.name,
            kind: device.category == .sims ? "ios_simulator" : "android_avd", tool: tool,
            totalSize: device.sizes.total,
            breakdown: [
                MdcPlanFile.Component(label: "data", size: device.sizes.data, role: "state"),
                MdcPlanFile.Component(label: "cache", size: device.sizes.cache, role: "cache"),
                MdcPlanFile.Component(label: "snapshots", size: device.sizes.snapshots, role: "snapshot"),
            ],
            actions: device.plans.map { plan in
                MdcPlanFile.Action(
                    name: nodeAction(plan.action), risk: nodeRisk(plan.risk), description: "",
                    estimatedSize: plan.freedBytes, execution: containerExecution(plan.steps, action: nodeAction(plan.action)))
            },
            selectedAction: nodeAction(action))
    }

    private func nodeRisk(_ risk: RiskLevel) -> String { risk == .regenerates ? "green" : "yellow" }

    private func nodeAction(_ action: DeviceAction) -> String {
        switch action {
        case .clean: "soft_clean"
        case .reset: "reset"
        case .delete: "delete"
        }
    }

    func importPlan(_ data: Data, reports: [CategoryID: CategoryReport]) async -> Either<Failure, PlanSelection> {
        do {
            let decoder = JSONDecoder()
            let planFile = try decoder.decode(MdcPlanFile.self, from: data)
            var selection = PlanSelection()
            let candidateIndex = Set(reports.values.flatMap { $0.candidates.map(\.id) })
            let deviceIndex = Set(reports.values.flatMap { $0.devices.map(\.id) })
            for report in planFile.reports.values {
                for candidate in report.candidates where candidate.selected == true {
                    if candidateIndex.contains(candidate.path) {
                        selection.candidateIDs.insert(candidate.path)
                    } else {
                        selection.skipped += 1
                    }
                }
                for container in report.containers where container.selectedAction != nil {
                    if deviceIndex.contains(container.id) {
                        if let action = nodeActionToDeviceAction(container.selectedAction ?? "") {
                            selection.deviceActions[container.id] = action
                        } else {
                            selection.skipped += 1
                        }
                    } else {
                        selection.skipped += 1
                    }
                }
            }
            return .right(selection)
        } catch is DecodingError {
            return .left(Failure.decoding(domain: "import_plan"))
        } catch {
            return .left(Failure.map(error, domain: "import_plan"))
        }
    }

    private func categoryToNode(_ id: CategoryID) -> String {
        switch id {
        case .builds, .tests: "derived_data"
        case .caches: "xcode_caches"
        case .sims: "ios_simulators"
        case .runtimes: "ios_runtimes"
        case .devsup: "ios_device_support"
        case .archives: "xcode_archives"
        case .previews: "xcode_previews"
        case .pods: "cocoapods"
        case .gcache: "gradle_caches"
        case .gdeps: "gradle_deps"
        case .gvers: "gradle_wrappers"
        case .jdks: "gradle_jdks"
        case .glogs: "gradle_daemon"
        case .acache: "android_caches"
        case .avds: "android_avds"
        case .sysimg: "android_sdk_system_images"
        case .ndk: "android_sdk_versioned"
        case .studio: "android_studio_orphan"
        case .fprojects: "flutter_projects"
        case .pubcache: "pub_cache"
        case .fsdk: "flutter_sdk_cache"
        case .fvm: "fvm_versions"
        }
    }

    private func executionToNode(_ strategy: ExecutionStrategy) -> MdcPlanFile.Execution {
        switch strategy {
        case .remove(let url):
            MdcPlanFile.Execution(kind: "remove", path: url.path, executable: nil, args: nil, containerAction: nil)
        case .command(let executable, let arguments):
            MdcPlanFile.Execution(kind: "cli_command", path: nil, executable: executable, args: arguments, containerAction: nil)
        }
    }

    /// `cleaner.ts` runs a container action as one command, or removes its colon-joined paths.
    private func containerExecution(_ steps: [ExecutionStrategy], action: String) -> MdcPlanFile.Execution {
        if steps.count == 1, case .command(let executable, let arguments) = steps[0] {
            return MdcPlanFile.Execution(
                kind: "container_action", path: nil, executable: executable, args: arguments, containerAction: action)
        }
        let paths = steps.compactMap { step -> String? in
            if case .remove(let url) = step { return url.path }
            return nil
        }
        return MdcPlanFile.Execution(
            kind: "container_action", path: paths.joined(separator: ":"), executable: nil, args: nil, containerAction: action)
    }

    private func nodeActionToDeviceAction(_ action: String) -> DeviceAction? {
        switch action {
        case "soft_clean": .clean
        case "reset": .reset
        case "delete": .delete
        default: nil
        }
    }
}
