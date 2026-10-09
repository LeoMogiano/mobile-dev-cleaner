import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("BuildCleanupPlanUseCase")
struct BuildCleanupPlanUseCaseTests {
    @Test("includes only marked candidates")
    func includesOnlyMarkedCandidates() {
        let useCase = BuildCleanupPlanUseCase()

        let candidate1 = CleanupCandidate(
            id: "path1",
            category: .builds,
            name: "Build1",
            url: URL(fileURLWithPath: "/tmp/build1"),
            size: 1000,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/build1"))
        )

        let candidate2 = CleanupCandidate(
            id: "path2",
            category: .builds,
            name: "Build2",
            url: URL(fileURLWithPath: "/tmp/build2"),
            size: 2000,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/build2"))
        )

        let report = CategoryReport(
            id: .builds,
            candidates: [candidate1, candidate2],
            devices: []
        )

        let reports: [CategoryID: CategoryReport] = [.builds: report]
        let candidateIDs: Set<String> = ["path1"]

        let result = useCase(reports: reports, candidateIDs: candidateIDs, deviceActions: [:])

        #expect(result.count == 1)
        #expect(result[0].id == "path1")
        #expect(result[0].name == "Build1")
    }

    @Test("respects category order and report order")
    func respectsOrderingByCategoryThenReport() {
        let useCase = BuildCleanupPlanUseCase()

        let buildsCandidate = CleanupCandidate(
            id: "builds1",
            category: .builds,
            name: "BuildsItem",
            url: URL(fileURLWithPath: "/tmp/builds1"),
            size: 1000,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/builds1"))
        )

        let cachesCandidate = CleanupCandidate(
            id: "caches1",
            category: .caches,
            name: "CachesItem",
            url: URL(fileURLWithPath: "/tmp/caches1"),
            size: 2000,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/caches1"))
        )

        let reports: [CategoryID: CategoryReport] = [
            .builds: CategoryReport(id: .builds, candidates: [buildsCandidate], devices: []),
            .caches: CategoryReport(id: .caches, candidates: [cachesCandidate], devices: [])
        ]
        let candidateIDs: Set<String> = ["builds1", "caches1"]

        let result = useCase(reports: reports, candidateIDs: candidateIDs, deviceActions: [:])

        #expect(result.count == 2)
        #expect(result[0].category == .builds)
        #expect(result[1].category == .caches)
    }

    @Test("includes cost note with lowercased first letter")
    func includesCostNoteWithLowercasedFirstLetter() {
        let useCase = BuildCleanupPlanUseCase()

        let costCandidate = CleanupCandidate(
            id: "cost1",
            category: .caches,
            name: "Old SDK",
            url: URL(fileURLWithPath: "/tmp/sdk"),
            size: 5000,
            risk: .hasCost,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: "This SDK is from 2020 and is not needed.",
            execution: .remove(URL(fileURLWithPath: "/tmp/sdk"))
        )

        let report = CategoryReport(
            id: .caches,
            candidates: [costCandidate],
            devices: []
        )

        let reports: [CategoryID: CategoryReport] = [.caches: report]
        let candidateIDs: Set<String> = ["cost1"]

        let result = useCase(reports: reports, candidateIDs: candidateIDs, deviceActions: [:])

        #expect(result.count == 1)
        #expect(result[0].note == "Old SDK: this SDK is from 2020 and is not needed.")
    }

    @Test("device with clean action has no note")
    func deviceWithCleanActionHasNoNote() {
        let useCase = BuildCleanupPlanUseCase()

        let plan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: 1000,
            steps: [.remove(URL(fileURLWithPath: "/tmp/cache"))]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .clean]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.count == 1)
        #expect(result[0].name == "iPhone 16 · Limpiar")
        #expect(result[0].note == nil)
    }

    @Test("device with reset action includes reset note")
    func deviceWithResetActionIncludesResetNote() {
        let useCase = BuildCleanupPlanUseCase()

        let plan = DeviceActionPlan(
            action: .reset,
            risk: .hasCost,
            freedBytes: 5000,
            steps: [.command(executable: "xcrun", arguments: ["simctl", "erase", "sim1"])]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .reset]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.count == 1)
        #expect(result[0].note?.contains("quedará como recién creado") == true)
    }

    @Test("device with delete action includes delete note")
    func deviceWithDeleteActionIncludesDeleteNote() {
        let useCase = BuildCleanupPlanUseCase()

        let plan = DeviceActionPlan(
            action: .delete,
            risk: .hasCost,
            freedBytes: 10000,
            steps: [.command(executable: "xcrun", arguments: ["simctl", "delete", "sim1"])]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .delete]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.count == 1)
        #expect(result[0].note?.contains("se borra el dispositivo completo") == true)
    }

    @Test("device without action does not appear")
    func deviceWithoutActionDoesNotAppear() {
        let useCase = BuildCleanupPlanUseCase()

        let plan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: 1000,
            steps: [.remove(URL(fileURLWithPath: "/tmp/cache"))]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: [:])

        #expect(result.isEmpty)
    }

    @Test("device action without matching plan does not appear")
    func deviceActionWithoutMatchingPlanDoesNotAppear() {
        let useCase = BuildCleanupPlanUseCase()

        let cleanPlan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: 1000,
            steps: [.remove(URL(fileURLWithPath: "/tmp/cache"))]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [cleanPlan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .reset]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.isEmpty)
    }

    @Test("uses plan freed bytes for device size")
    func usesPlanFreedBytesForDeviceSize() {
        let useCase = BuildCleanupPlanUseCase()

        let plan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: 7500,
            steps: [.remove(URL(fileURLWithPath: "/tmp/cache"))]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .clean]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.count == 1)
        #expect(result[0].size == 7500)
    }

    @Test("uses plan risk and steps for device operation")
    func usesPlanRiskAndStepsForDeviceOperation() {
        let useCase = BuildCleanupPlanUseCase()

        let steps: [ExecutionStrategy] = [
            .command(executable: "xcrun", arguments: ["simctl", "erase", "sim1"])
        ]
        let plan = DeviceActionPlan(
            action: .reset,
            risk: .hasCost,
            freedBytes: 5000,
            steps: steps
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(id: .sims, candidates: [], devices: [device])
        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let deviceActions: [String: DeviceAction] = ["sim1": .reset]

        let result = useCase(reports: reports, candidateIDs: [], deviceActions: deviceActions)

        #expect(result.count == 1)
        #expect(result[0].risk == .hasCost)
        #expect(result[0].steps == steps)
    }

    @Test("combines candidates and devices in correct order")
    func combinesCandidatesAndDevicesInCorrectOrder() {
        let useCase = BuildCleanupPlanUseCase()

        let candidate = CleanupCandidate(
            id: "cand1",
            category: .sims,
            name: "Derived Build",
            url: URL(fileURLWithPath: "/tmp/build"),
            size: 1000,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/build"))
        )

        let plan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: 2000,
            steps: [.remove(URL(fileURLWithPath: "/tmp/cache"))]
        )

        let device = DeviceCandidate(
            id: "sim1",
            category: .sims,
            name: "iPhone 16",
            osVersion: "iOS 18.2",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/sim"),
            sizes: DeviceSizes(),
            isRunning: false,
            isAvailable: true,
            plans: [plan]
        )

        let report = CategoryReport(
            id: .sims,
            candidates: [candidate],
            devices: [device]
        )

        let reports: [CategoryID: CategoryReport] = [.sims: report]
        let candidateIDs: Set<String> = ["cand1"]
        let deviceActions: [String: DeviceAction] = ["sim1": .clean]

        let result = useCase(reports: reports, candidateIDs: candidateIDs, deviceActions: deviceActions)

        #expect(result.count == 2)
        #expect(result[0].source == .candidate)
        #expect(result[1].source == .device(.clean))
    }
}
