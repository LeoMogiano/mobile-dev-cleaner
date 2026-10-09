import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("SelectionStore")
@MainActor
struct SelectionStoreTests {
    func makeCandidate(_ id: String, size: Int64 = 100) -> CleanupCandidate {
        CleanupCandidate(
            id: id,
            category: .builds,
            name: "Test",
            url: URL(fileURLWithPath: "/tmp/\(id)"),
            size: size,
            risk: .regenerates,
            group: nil,
            isOrphan: false,
            modifiedAt: nil,
            reason: nil,
            cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/\(id)"))
        )
    }

    func makeDevice(_ id: String, sizes: DeviceSizes = .init()) -> DeviceCandidate {
        DeviceCandidate(
            id: id,
            category: .sims,
            name: "Sim",
            osVersion: "iOS 18",
            kind: .iphone,
            url: URL(fileURLWithPath: "/tmp/\(id)"),
            sizes: sizes,
            isRunning: false,
            isAvailable: true,
            plans: [
                DeviceActionPlan(action: .clean, risk: .regenerates, freedBytes: 200, steps: [.remove(URL(fileURLWithPath: "/tmp/\(id)"))])
            ]
        )
    }

    func makeReport(_ id: CategoryID, candidates: [CleanupCandidate] = [], devices: [DeviceCandidate] = []) -> CategoryReport {
        CategoryReport(id: id, candidates: candidates, devices: devices)
    }

    @Test("toggle inserts when not selected")
    func testToggleInserts() {
        let store = SelectionStore()
        let candidate = makeCandidate("c1")
        store.toggle(candidate)
        #expect(store.isSelected(candidate))
    }

    @Test("toggle removes when selected")
    func testToggleRemoves() {
        let store = SelectionStore()
        let candidate = makeCandidate("c1")
        store.toggle(candidate)
        store.toggle(candidate)
        #expect(!store.isSelected(candidate))
    }

    @Test("select adds multiple candidates")
    func testSelect() {
        let store = SelectionStore()
        let c1 = makeCandidate("c1")
        let c2 = makeCandidate("c2")
        store.select([c1, c2])
        #expect(store.isSelected(c1))
        #expect(store.isSelected(c2))
        #expect(store.count == 2)
    }

    @Test("deselect removes candidates")
    func testDeselect() {
        let store = SelectionStore()
        let c1 = makeCandidate("c1")
        let c2 = makeCandidate("c2")
        store.select([c1, c2])
        store.deselect([c1])
        #expect(!store.isSelected(c1))
        #expect(store.isSelected(c2))
    }

    @Test("setAction toggles when repeated")
    func testSetActionToggles() {
        let store = SelectionStore()
        let device = makeDevice("d1")
        store.setAction(.clean, for: device)
        #expect(store.action(for: device) == .clean)
        store.setAction(.clean, for: device)
        #expect(store.action(for: device) == nil)
    }

    @Test("setAction replaces different action")
    func testSetActionReplaces() {
        let store = SelectionStore()
        let device = makeDevice("d1")
        store.setAction(.clean, for: device)
        store.setAction(.reset, for: device)
        #expect(store.action(for: device) == .reset)
    }

    @Test("prune drops missing candidate IDs")
    func testPruneCandidates() {
        let store = SelectionStore()
        let c1 = makeCandidate("c1")
        let c2 = makeCandidate("c2")
        store.select([c1, c2])

        let reports: [CategoryID: CategoryReport] = [
            .builds: makeReport(.builds, candidates: [c1])
        ]
        store.prune(to: reports)
        #expect(store.isSelected(c1))
        #expect(!store.isSelected(c2))
    }

    @Test("prune drops missing device IDs")
    func testPruneDevices() {
        let store = SelectionStore()
        let d1 = makeDevice("d1")
        let d2 = makeDevice("d2")
        store.setAction(.clean, for: d1)
        store.setAction(.reset, for: d2)

        let reports: [CategoryID: CategoryReport] = [
            .sims: makeReport(.sims, devices: [d1])
        ]
        store.prune(to: reports)
        #expect(store.action(for: d1) == .clean)
        #expect(store.action(for: d2) == nil)
    }

    @Test("selectedBytes sums candidates")
    func testSelectedBytesForCandidates() {
        let store = SelectionStore()
        let c1 = makeCandidate("c1", size: 100)
        let c2 = makeCandidate("c2", size: 200)
        store.select([c1, c2])

        let reports: [CategoryID: CategoryReport] = [
            .builds: makeReport(.builds, candidates: [c1, c2])
        ]
        #expect(store.selectedBytes(in: reports) == 300)
    }

    @Test("selectedBytes sums device plan freedBytes")
    func testSelectedBytesForDevices() {
        let store = SelectionStore()
        let d1 = makeDevice("d1")
        store.setAction(.clean, for: d1)

        let reports: [CategoryID: CategoryReport] = [
            .sims: makeReport(.sims, devices: [d1])
        ]
        #expect(store.selectedBytes(in: reports) == 200)
    }

    @Test("clear empties selection")
    func testClear() {
        let store = SelectionStore()
        let c1 = makeCandidate("c1")
        let d1 = makeDevice("d1")
        store.toggle(c1)
        store.setAction(.clean, for: d1)
        store.clear()
        #expect(store.isEmpty)
        #expect(store.count == 0)
    }

    @Test("isEmpty detects empty state")
    func testIsEmpty() {
        let store = SelectionStore()
        #expect(store.isEmpty)
        let c1 = makeCandidate("c1")
        store.toggle(c1)
        #expect(!store.isEmpty)
    }
}
