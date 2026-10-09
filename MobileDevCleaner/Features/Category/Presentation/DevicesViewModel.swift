import SwiftUI

enum DevicesIntent: Sendable {
    case setAction(String, DeviceAction)
    case inspect(String)
}

struct DeviceSegmentModel: Identifiable, Hashable {
    let id: DeviceAction
    /// "Limpiar" / "Restablecer" / "Eliminar".
    let label: String
    /// "Libera 1,2 GB".
    let freesText: String
    let risk: RiskLevel
    let isOn: Bool
}

struct DeviceCardModel: Identifiable, Hashable {
    let id: String
    let name: String
    let osVersion: String
    let symbol: String
    let sizeText: String
    /// Shows "En uso"; the action picker is dimmed and disabled.
    let isRunning: Bool
    let segments: [DeviceSegmentModel]
    let chosen: DeviceAction?
    let isInspected: Bool
    /// "Libera 550 MB. Tus apps y datos quedan."; nil until an action is chosen.
    let actionDescription: String?
    let accessibilityLabel: String
}

@MainActor @Observable
final class DevicesViewModel {
    let category: CategoryID
    let info: CategoryInfo
    var isExplainerExpanded = false

    @ObservationIgnored private let scan: ScanStore
    @ObservationIgnored private let selection: SelectionStore
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let router: AppRouter

    init(category: CategoryID, scan: ScanStore, selection: SelectionStore, settings: SettingsStore, router: AppRouter) {
        self.category = category
        self.info = CategoryInfo.info(for: category)
        self.scan = scan
        self.selection = selection
        self.settings = settings
        self.router = router
    }

    var sizeText: String {
        guard let report = scan.report(for: category) else { return "" }
        return ByteFormatter.string(report.totalSize)
    }

    var badges: [MDCBadgeKind] {
        guard let report = scan.report(for: category), !report.devices.isEmpty else { return [] }
        return [.hasCost]
    }

    var cards: [DeviceCardModel] {
        guard let report = scan.report(for: category) else { return [] }
        return report.devices.filter(matchesSearch).map(makeCard)
    }

    var countText: String {
        guard let report = scan.report(for: category) else { return "" }
        let count = report.devices.count
        return "\(count) \(count == 1 ? "dispositivo" : "dispositivos") · elige una acción por dispositivo"
    }

    var isEmpty: Bool {
        scan.report(for: category)?.devices.isEmpty ?? true
    }

    var showsAccessBanner: Bool {
        scan.report(for: category)?.accessDenied ?? false
    }

    func handle(_ intent: DevicesIntent) {
        switch intent {
        case .setAction(let id, let action):
            guard let device = scan.report(for: category)?.devices.first(where: { $0.id == id }) else { return }
            if device.isRunning {
                router.toast = "Ciérralo para poder limpiarlo"
            } else {
                selection.setAction(action, for: device)
            }
        case .inspect(let id):
            router.inspect(id)
        }
    }

    private func makeCard(_ device: DeviceCandidate) -> DeviceCardModel {
        let chosen = selection.action(for: device)
        let sizeText = ByteFormatter.string(device.sizes.total)
        let segments = DeviceAction.allCases.compactMap { action -> DeviceSegmentModel? in
            guard let plan = device.plan(for: action) else { return nil }
            let label: String = switch action {
            case .clean: "Limpiar"
            case .reset: "Restablecer"
            case .delete: "Eliminar"
            }
            return DeviceSegmentModel(
                id: action, label: label,
                freesText: "Libera " + ByteFormatter.string(plan.freedBytes),
                risk: plan.risk, isOn: chosen == action
            )
        }
        return DeviceCardModel(
            id: device.id, name: device.name, osVersion: device.osVersion,
            symbol: Self.symbol(for: device.kind), sizeText: sizeText,
            isRunning: device.isRunning, segments: segments,
            chosen: chosen, isInspected: router.inspectedID == device.id,
            actionDescription: chosen.flatMap { action in
                segments.first { $0.id == action }.map { "\($0.freesText). \(Self.consequence(of: action))" }
            },
            accessibilityLabel: "\(device.name), \(device.osVersion), \(sizeText)" + (device.isRunning ? ", en uso" : "")
        )
    }

    private static func symbol(for kind: DeviceKind) -> String {
        switch kind {
        case .iphone: "iphone"
        case .ipad, .tablet: "ipad"
        case .watch: "applewatch"
        case .tv: "appletv"
        case .vision: "visionpro"
        case .phone: "smartphone"
        }
    }

    private static func consequence(of action: DeviceAction) -> String {
        switch action {
        case .clean: L10n.string("Tus apps y datos quedan.")
        case .reset: L10n.string("Se pierden apps y datos.")
        case .delete: L10n.string("Se borra el dispositivo.")
        }
    }

    private func matchesSearch(_ device: DeviceCandidate) -> Bool {
        let query = router.searchQuery
        guard !query.isEmpty else { return true }
        let normalized = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let name = device.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let os = device.osVersion.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        return name.contains(normalized) || os.contains(normalized)
    }
}
