import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("PlanTransferRepositoryImpl")
struct PlanTransferRepositoryImplTests {
    let repo = PlanTransferRepositoryImpl()

    @Test("export encodes selection")
    func exportEncodes() async {
        let candidate = CleanupCandidate(
            id: "/path/to/cache",
            category: .caches,
            name: "Cache",
            url: URL(fileURLWithPath: "/path/to/cache"),
            size: 100,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/cache"))
        )

        let report = CategoryReport(id: .caches, candidates: [candidate])
        let reports = [CategoryID.caches: report]

        let result = await repo.export(
            reports: reports,
            candidateIDs: Set([candidate.id]),
            deviceActions: [:]
        )

        guard case .right(let data) = result else {
            Issue.record("Export should succeed")
            return
        }

        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(MdcPlanFile.self, from: data)
        #expect(decoded != nil)
    }

    @Test("export maps category correctly")
    func exportCategoryMapping() async {
        let candidate = CleanupCandidate(
            id: "/path/to/builds",
            category: .builds,
            name: "Builds",
            url: URL(fileURLWithPath: "/path/to/builds"),
            size: 200,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/builds"))
        )

        let report = CategoryReport(id: .builds, candidates: [candidate])
        let reports = [CategoryID.builds: report]

        let result = await repo.export(
            reports: reports,
            candidateIDs: Set([candidate.id]),
            deviceActions: [:]
        )

        guard case .right(let data) = result else {
            Issue.record("Export should succeed")
            return
        }

        let decoder = JSONDecoder()
        let plan = try? decoder.decode(MdcPlanFile.self, from: data)
        #expect(plan?.reports["xcode"]?.candidates[0].category == "derived_data")
    }

    @Test("export maps risk correctly")
    func exportRiskMapping() async {
        let candidate1 = CleanupCandidate(
            id: "/path/1",
            category: .caches,
            name: "Cache 1",
            url: URL(fileURLWithPath: "/path/1"),
            size: 100,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/1"))
        )

        let candidate2 = CleanupCandidate(
            id: "/path/2",
            category: .caches,
            name: "Cache 2",
            url: URL(fileURLWithPath: "/path/2"),
            size: 50,
            risk: .hasCost,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/2"))
        )

        let report = CategoryReport(id: .caches, candidates: [candidate1, candidate2])
        let reports = [CategoryID.caches: report]

        let result = await repo.export(
            reports: reports,
            candidateIDs: Set([candidate1.id, candidate2.id]),
            deviceActions: [:]
        )

        guard case .right(let data) = result else {
            Issue.record("Export should succeed")
            return
        }

        let decoder = JSONDecoder()
        let plan = try? decoder.decode(MdcPlanFile.self, from: data)
        #expect(plan?.reports["xcode"]?.candidates[0].risk == "green")
        #expect(plan?.reports["xcode"]?.candidates[1].risk == "yellow")
    }

    @Test("import decodes plan")
    func importDecodes() async {
        let planFile = MdcPlanFile(
            scannedAt: ISO8601DateFormatter().string(from: Date()),
            reports: ["xcode": MdcPlanFile.Report(tool: "xcode", candidates: [], containers: [])]
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(planFile)

        let result = await repo.importPlan(data, reports: [:])
        guard case .right(let selection) = result else {
            Issue.record("Import should succeed")
            return
        }

        #expect(selection.candidateIDs.isEmpty)
        #expect(selection.deviceActions.isEmpty)
    }

    @Test("import marks missing items as skipped")
    func importSkipped() async {
        let candidate = CleanupCandidate(
            id: "/path/exists",
            category: .caches,
            name: "Exists",
            url: URL(fileURLWithPath: "/path/exists"),
            size: 100,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/exists"))
        )

        let report = CategoryReport(id: .caches, candidates: [candidate])

        let planFile = MdcPlanFile(
            scannedAt: ISO8601DateFormatter().string(from: Date()),
            reports: ["xcode": MdcPlanFile.Report(
                tool: "xcode",
                candidates: [
                    MdcPlanFile.Candidate(
                        id: "/path/exists",
                        path: "/path/exists",
                        displayName: "Exists",
                        risk: "green",
                        category: "xcode_caches",
                        tool: "xcode",
                        size: 100,
                        reason: "",
                        execution: MdcPlanFile.Execution(kind: "remove", path: "/path/exists", executable: nil, args: nil, containerAction: nil),
                        group: nil,
                        selected: true
                    ),
                    MdcPlanFile.Candidate(
                        id: "/path/gone",
                        path: "/path/gone",
                        displayName: "Gone",
                        risk: "green",
                        category: "xcode_caches",
                        tool: "xcode",
                        size: 50,
                        reason: "",
                        execution: MdcPlanFile.Execution(kind: "remove", path: "/path/gone", executable: nil, args: nil, containerAction: nil),
                        group: nil,
                        selected: true
                    )
                ],
                containers: []
            )]
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(planFile)

        let result = await repo.importPlan(data, reports: [CategoryID.caches: report])
        guard case .right(let selection) = result else {
            Issue.record("Import should succeed")
            return
        }

        #expect(selection.candidateIDs.count == 1)
        #expect(selection.skipped == 1)
    }

    @Test("import returns error for invalid JSON")
    func importInvalidJSON() async {
        let data = "not json".data(using: .utf8)!
        let result = await repo.importPlan(data, reports: [:])
        guard case .left(let failure) = result else {
            Issue.record("Should return error for invalid JSON")
            return
        }
        #expect(failure.type == .decoding)
    }

    @Test("export Flutter candidate")
    func exportFlutterCandidate() async {
        let candidate = CleanupCandidate(
            id: "/path/to/flutter/pubcache",
            category: .pubcache,
            name: "pub cache",
            url: URL(fileURLWithPath: "/path/to/flutter/pubcache"),
            size: 500,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/flutter/pubcache"))
        )

        let report = CategoryReport(id: .pubcache, candidates: [candidate])
        let reports = [CategoryID.pubcache: report]

        let result = await repo.export(
            reports: reports,
            candidateIDs: Set([candidate.id]),
            deviceActions: [:]
        )

        guard case .right(let data) = result else {
            Issue.record("Export should succeed")
            return
        }

        let decoder = JSONDecoder()
        let plan = try? decoder.decode(MdcPlanFile.self, from: data)
        #expect(plan?.reports["flutter"] != nil)
        #expect(plan?.reports["flutter"]?.candidates[0].category == "pub_cache")
        #expect(plan?.reports["flutter"]?.candidates[0].tool == "flutter")
    }

    @Test("export mixed xcode and flutter selection")
    func exportMixedSelection() async {
        let xcodeCandidate = CleanupCandidate(
            id: "/path/to/xcode/caches",
            category: .caches,
            name: "Xcode Caches",
            url: URL(fileURLWithPath: "/path/to/xcode/caches"),
            size: 100,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/xcode/caches"))
        )

        let flutterCandidate = CleanupCandidate(
            id: "/path/to/flutter/pubcache",
            category: .pubcache,
            name: "pub cache",
            url: URL(fileURLWithPath: "/path/to/flutter/pubcache"),
            size: 300,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/flutter/pubcache"))
        )

        let xcodeReport = CategoryReport(id: .caches, candidates: [xcodeCandidate])
        let flutterReport = CategoryReport(id: .pubcache, candidates: [flutterCandidate])
        let reports = [CategoryID.caches: xcodeReport, CategoryID.pubcache: flutterReport]

        let result = await repo.export(
            reports: reports,
            candidateIDs: Set([xcodeCandidate.id, flutterCandidate.id]),
            deviceActions: [:]
        )

        guard case .right(let data) = result else {
            Issue.record("Export should succeed")
            return
        }

        let decoder = JSONDecoder()
        let plan = try? decoder.decode(MdcPlanFile.self, from: data)
        #expect(plan?.reports["xcode"] != nil)
        #expect(plan?.reports["flutter"] != nil)
        #expect(plan?.reports["xcode"]?.candidates.count == 1)
        #expect(plan?.reports["flutter"]?.candidates.count == 1)
    }

    @Test("import Flutter candidate restores selection")
    func importFlutterCandidate() async {
        let flutterCandidate = CleanupCandidate(
            id: "/path/to/flutter/pubcache",
            category: .pubcache,
            name: "pub cache",
            url: URL(fileURLWithPath: "/path/to/flutter/pubcache"),
            size: 500,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/path/to/flutter/pubcache"))
        )

        let report = CategoryReport(id: .pubcache, candidates: [flutterCandidate])

        let planFile = MdcPlanFile(
            scannedAt: ISO8601DateFormatter().string(from: Date()),
            reports: ["flutter": MdcPlanFile.Report(
                tool: "flutter",
                candidates: [
                    MdcPlanFile.Candidate(
                        id: "/path/to/flutter/pubcache",
                        path: "/path/to/flutter/pubcache",
                        displayName: "pub cache",
                        risk: "green",
                        category: "pub_cache",
                        tool: "flutter",
                        size: 500,
                        reason: "",
                        execution: MdcPlanFile.Execution(kind: "remove", path: "/path/to/flutter/pubcache", executable: nil, args: nil, containerAction: nil),
                        group: nil,
                        selected: true
                    )
                ],
                containers: []
            )]
        )

        let encoder = JSONEncoder()
        let data = try! encoder.encode(planFile)

        let result = await repo.importPlan(data, reports: [CategoryID.pubcache: report])
        guard case .right(let selection) = result else {
            Issue.record("Import should succeed")
            return
        }

        #expect(selection.candidateIDs.count == 1)
        #expect(selection.candidateIDs.contains("/path/to/flutter/pubcache"))
    }
}
