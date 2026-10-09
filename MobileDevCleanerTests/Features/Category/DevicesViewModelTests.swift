import Foundation
import Testing
@testable import MobileDevCleaner

private struct FakeScanRepository: ScanRepository {
    let events: @Sendable () -> AsyncStream<ScanEvent>
    func scan(tools: Set<Tool>) -> AsyncStream<ScanEvent> { events() }
    func invalidateSizes(of urls: [URL]) async {}
}

@Suite("DevicesViewModel")
@MainActor
struct DevicesViewModelTests {
    private func makeDevice(
        id: String, name: String, os: String, kind: DeviceKind, sizes: DeviceSizes,
        isRunning: Bool = false
    ) -> DeviceCandidate {
        let cleanPlan = DeviceActionPlan(
            action: .clean,
            risk: .regenerates,
            freedBytes: sizes.cache + sizes.snapshots,
            steps: [.remove(URL(fileURLWithPath: "/fake"))]
        )
        let resetPlan = DeviceActionPlan(
            action: .reset,
            risk: .hasCost,
            freedBytes: sizes.data + sizes.cache + sizes.snapshots,
            steps: [.remove(URL(fileURLWithPath: "/fake"))]
        )
        let deletePlan = DeviceActionPlan(
            action: .delete,
            risk: .hasCost,
            freedBytes: sizes.total,
            steps: [.remove(URL(fileURLWithPath: "/fake"))]
        )
        return DeviceCandidate(
            id: id,
            category: .sims,
            name: name,
            osVersion: os,
            kind: kind,
            url: URL(fileURLWithPath: "/fake/\(id)"),
            sizes: sizes,
            isRunning: isRunning,
            isAvailable: true,
            plans: [cleanPlan, resetPlan, deletePlan]
        )
    }

    private struct TestContext {
        let vm: DevicesViewModel
        let scan: ScanStore
        let selection: SelectionStore
        let settings: SettingsStore
        let router: AppRouter
    }

    private func makeContext(
        category: CategoryID = .sims,
        report: CategoryReport = CategoryReport(id: .sims)
    ) -> TestContext {
        let scanRepo = FakeScanRepository {
            AsyncStream { continuation in
                continuation.yield(.started([category]))
                continuation.yield(.categoryFinished(report))
                continuation.yield(.finished(ScanResult(scannedAt: Date(), reports: [category: report])))
                continuation.finish()
            }
        }
        let scanStore = ScanStore(scan: ScanUseCase(repository: scanRepo), flushInterval: .milliseconds(20))
        let selectionStore = SelectionStore()
        let settingsStore = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let router = AppRouter()

        let vm = DevicesViewModel(
            category: category, scan: scanStore, selection: selectionStore,
            settings: settingsStore, router: router
        )

        scanStore.handle(.start)
        return TestContext(vm: vm, scan: scanStore, selection: selectionStore, settings: settingsStore, router: router)
    }

    @Test("sizeText shows total device size formatted")
    func sizeTextFormatting() async {
        let sizes = DeviceSizes(data: 500_000_000, cache: 200_000_000, snapshots: 100_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.sizeText != "" }
        let expected = ByteFormatter.string(sizes.total)
        #expect(ctx.vm.sizeText == expected)
    }

    @Test("badges contains hasCost when devices present")
    func badgesShowCostRisk() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.badges.count > 0 }
        #expect(ctx.vm.badges.contains(.hasCost))
    }

    @Test("cards in order with correct symbols")
    func cardsOrderAndSymbols() async {
        let sizes1 = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let sizes2 = DeviceSizes(data: 200_000_000, cache: 100_000_000, snapshots: 50_000_000)
        let iPad = makeDevice(id: "2", name: "iPad Pro", os: "iPadOS 18.1", kind: .ipad, sizes: sizes2)
        let iPhone = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes1)
        let report = CategoryReport(id: .sims, devices: [iPhone, iPad])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 2 }
        #expect(ctx.vm.cards[0].symbol == "iphone")
        #expect(ctx.vm.cards[1].symbol == "ipad")
    }

    @Test("segments show three actions with correct labels")
    func segmentLabels() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        #expect(card.segments.count == 3)
        #expect(card.segments[0].label == "Limpiar")
        #expect(card.segments[1].label == "Restablecer")
        #expect(card.segments[2].label == "Eliminar")
    }

    @Test("action description is empty when nothing is chosen")
    func actionDescriptionDefault() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        #expect(card.actionDescription == nil)
        #expect(card.chosen == nil)
    }

    @Test("setAction clean selects clean and updates description")
    func setActionClean() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        ctx.vm.handle(.setAction("1", .clean))
        await waitUntil { ctx.vm.cards[0].chosen == .clean }

        let card = ctx.vm.cards[0]
        #expect(card.segments[0].isOn == true)
        #expect(card.actionDescription == "Libera \(ByteFormatter.string(75_000_000)). Tus apps y datos quedan.")
        #expect(ctx.selection.action(for: device) == .clean)
    }

    @Test("setAction reset selects reset and updates description")
    func setActionReset() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        ctx.vm.handle(.setAction("1", .reset))
        await waitUntil { ctx.vm.cards[0].chosen == .reset }

        let card = ctx.vm.cards[0]
        #expect(card.segments[1].isOn == true)
        #expect(card.actionDescription == "Libera \(ByteFormatter.string(175_000_000)). Se pierden apps y datos.")
    }

    @Test("setAction delete selects delete and updates description")
    func setActionDelete() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        ctx.vm.handle(.setAction("1", .delete))
        await waitUntil { ctx.vm.cards[0].chosen == .delete }

        let card = ctx.vm.cards[0]
        #expect(card.segments[2].isOn == true)
        #expect(card.actionDescription == "Libera \(ByteFormatter.string(sizes.total)). Se borra el dispositivo.")
    }

    @Test("tapping same action again clears it")
    func toggleActionClears() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        ctx.vm.handle(.setAction("1", .clean))
        await waitUntil { ctx.vm.cards[0].chosen == .clean }

        ctx.vm.handle(.setAction("1", .clean))
        await waitUntil { ctx.vm.cards[0].chosen == nil }

        let card = ctx.vm.cards[0]
        #expect(card.actionDescription == nil)
    }

    @Test("running device shows in use and prevents action")
    func runningDevicePreventsAction() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes, isRunning: true)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        #expect(card.isRunning == true)

        ctx.vm.handle(.setAction("1", .clean))
        await waitUntil { ctx.router.toast != nil }

        #expect(ctx.router.toast == "Ciérralo para poder limpiarlo")
        #expect(ctx.vm.cards[0].chosen == nil)
    }

    @Test("accessibility label includes name osVersion and size")
    func accessibilityLabel() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        let sizeText = ByteFormatter.string(sizes.total)
        #expect(card.accessibilityLabel == "iPhone 15, iOS 18.2, \(sizeText)")
    }

    @Test("accessibility label for running device mentions in use")
    func accessibilityLabelRunning() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes, isRunning: true)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        let sizeText = ByteFormatter.string(sizes.total)
        #expect(card.accessibilityLabel == "iPhone 15, iOS 18.2, \(sizeText), en uso")
    }

    @Test("countText shows singular device")
    func countTextSingular() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.countText != "" }
        #expect(ctx.vm.countText == "1 dispositivo · elige una acción por dispositivo")
    }

    @Test("countText shows plural devices")
    func countTextPlural() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device1 = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let device2 = makeDevice(id: "2", name: "iPad Pro", os: "iPadOS 18.1", kind: .ipad, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device1, device2])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.countText != "" }
        #expect(ctx.vm.countText == "2 dispositivos · elige una acción por dispositivo")
    }

    @Test("search filters devices case insensitive")
    func searchFilterCaseInsensitive() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let iPhone = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let iPad = makeDevice(id: "2", name: "iPad Pro", os: "iPadOS 18.1", kind: .ipad, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [iPhone, iPad])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 2 }
        ctx.router.searchQuery = "ipad"
        await waitUntil { ctx.vm.cards.count == 1 }
        #expect(ctx.vm.cards[0].name == "iPad Pro")
    }

    @Test("search filters by osVersion")
    func searchFilterOsVersion() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let iPhone = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let watch = makeDevice(id: "2", name: "Apple Watch", os: "watchOS 11.1", kind: .watch, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [iPhone, watch])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 2 }
        ctx.router.searchQuery = "watchos"
        await waitUntil { ctx.vm.cards.count == 1 }
        #expect(ctx.vm.cards[0].name == "Apple Watch")
    }

    @Test("inspect action sets inspectedID and card state")
    func inspectAction() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        ctx.vm.handle(.inspect("1"))
        await waitUntil { ctx.vm.cards[0].isInspected }

        #expect(ctx.router.inspectedID == "1")
        #expect(ctx.vm.cards[0].isInspected == true)
    }

    @Test("isEmpty reflects empty report")
    func emptyReport() async {
        let report = CategoryReport(id: .sims, devices: [])
        let ctx = makeContext(report: report)

        #expect(ctx.vm.isEmpty == true)
    }

    @Test("isEmpty false with devices")
    func notEmptyReport() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        #expect(ctx.vm.isEmpty == false)
    }

    @Test("showsAccessBanner when accessDenied")
    func accessDeniedBanner() async {
        let report = CategoryReport(id: .sims, devices: [], accessDenied: true)
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.showsAccessBanner }
        #expect(ctx.vm.showsAccessBanner == true)
    }

    @Test("segment freesText shows correct freed bytes")
    func segmentFreesText() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]

        let cleanFreed = sizes.cache + sizes.snapshots
        let cleanText = ByteFormatter.string(cleanFreed)
        #expect(card.segments[0].freesText == "Libera \(cleanText)")

        let resetFreed = sizes.data + sizes.cache + sizes.snapshots
        let resetText = ByteFormatter.string(resetFreed)
        #expect(card.segments[1].freesText == "Libera \(resetText)")

        #expect(card.segments[2].freesText == "Libera \(ByteFormatter.string(sizes.total))")
    }

    @Test("segment risks are correct")
    func segmentRisks() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]

        #expect(card.segments[0].risk == .regenerates)
        #expect(card.segments[1].risk == .hasCost)
        #expect(card.segments[2].risk == .hasCost)
    }

    @Test("card sizeText shows total formatted")
    func cardSizeText() async {
        let sizes = DeviceSizes(data: 100_000_000, cache: 50_000_000, snapshots: 25_000_000)
        let device = makeDevice(id: "1", name: "iPhone 15", os: "iOS 18.2", kind: .iphone, sizes: sizes)
        let report = CategoryReport(id: .sims, devices: [device])
        let ctx = makeContext(report: report)

        await waitUntil { ctx.vm.cards.count == 1 }
        let card = ctx.vm.cards[0]
        let expected = ByteFormatter.string(sizes.total)
        #expect(card.sizeText == expected)
    }
}
