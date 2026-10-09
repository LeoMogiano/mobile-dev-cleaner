import AppKit
import SwiftUI

enum DashboardIntent {
    case rescan
    case cleanRecommended
    case openCategory(CategoryID)
    case toggleRecommendedList
    case dismissBanner
    case grantAccess
}

@MainActor @Observable
final class DashboardViewModel {
    enum State: Equatable {
        case scanning
        case results
        case clean
    }

    struct CategoryRow: Identifiable, Equatable {
        let id: CategoryID
        let name: String
        let symbol: String
        let sizeText: String
    }

    struct ScanRow: Identifiable, Equatable {
        let id: CategoryID
        let name: String
        let symbol: String
        let tool: Tool
        let isFound: Bool
        let sizeText: String
        let isDimmed: Bool
    }

    struct ToolProgress: Identifiable, Equatable {
        let tool: Tool
        let fraction: Double
        let foundText: String
        var id: Tool { tool }
    }

    private(set) var isRecommendedExpanded = false
    private(set) var isBannerDismissed = false

    @ObservationIgnored private let scan: ScanStore
    @ObservationIgnored private let selection: SelectionStore
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let router: AppRouter

    init(scan: ScanStore, selection: SelectionStore, settings: SettingsStore, router: AppRouter) {
        self.scan = scan
        self.selection = selection
        self.settings = settings
        self.router = router
    }

    func handle(_ intent: DashboardIntent) {
        switch intent {
        case .rescan: scan.handle(.start)
        case .cleanRecommended:
            selection.select(recommendedCandidates)
            router.isReviewPresented = true
        case .openCategory(let id): router.show(.category(id))
        case .toggleRecommendedList: isRecommendedExpanded.toggle()
        case .dismissBanner: isBannerDismissed = true
        case .grantAccess:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    var state: State {
        guard case .finished = scan.status else { return .scanning }
        return scan.totalSize == 0 ? .clean : .results
    }

    var showsAccessBanner: Bool {
        !isBannerDismissed && state != .scanning && scan.reports.values.contains { $0.accessDenied }
    }

    // MARK: Hero

    var heroBytes: Int64 { scan.totalSize }
    var regenSize: Int64 { scan.regeneratesSize }
    var costSize: Int64 { scan.hasCostSize }
    var regenText: String { Self.format(regenSize) }
    var costText: String { Self.format(costSize) }

    var heroAccessibility: String {
        L10n.string("Puedes recuperar \(Self.format(heroBytes)): \(regenText) se regenera solo, \(costText) tiene costo")
    }

    // MARK: Recommended

    /// Regenerable items outside excluded folders, from categories that could be read.
    var recommendedCandidates: [CleanupCandidate] {
        scan.reports.values.filter { !$0.accessDenied }.flatMap { report in
            report.candidates.filter { $0.risk == .regenerates && !settings.isExcluded($0.url.path) }
        }
    }

    var recommendedBytes: Int64 { recommendedCandidates.reduce(0) { $0 + $1.size } }
    var recommendedText: String { Self.format(recommendedBytes) }
    var hasRecommended: Bool { recommendedBytes > 0 }

    private var recommendedRows: [CategoryRow] {
        var sizes: [CategoryID: Int64] = [:]
        for candidate in recommendedCandidates { sizes[candidate.category, default: 0] += candidate.size }
        return sizes.filter { $0.value > 0 }
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key.rawValue < $1.key.rawValue }
            .map { Self.row($0.key, bytes: $0.value) }
    }

    var visibleRecommended: [CategoryRow] {
        let rows = recommendedRows
        return isRecommendedExpanded ? rows : Array(rows.prefix(3))
    }

    var hiddenRecommendedCount: Int { max(0, recommendedRows.count - 3) }
    var hasMoreRecommended: Bool { hiddenRecommendedCount > 0 }

    var recommendedToggleLabel: String {
        isRecommendedExpanded ? L10n.string("Mostrar menos") : L10n.string("y \(hiddenRecommendedCount) más")
    }

    // MARK: Decision

    var decisionRows: [CategoryRow] {
        scan.reports.values.filter { !$0.accessDenied && $0.hasCostSize > 0 }
            .sorted { Self.order($0.id) < Self.order($1.id) }
            .map { Self.row($0.id, bytes: $0.hasCostSize) }
    }

    // MARK: Footer

    func footer(now: Date = .now) -> String {
        guard case .finished(let date) = scan.status else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.unitsStyle = .abbreviated
        let when = formatter.localizedString(for: date, relativeTo: now)
        return L10n.string("Último escaneo: \(when)")
    }

    // MARK: Scanning

    var percentText: String { "\(Int((scan.progress * 100).rounded()))%" }
    var currentPath: String { scan.currentPath ?? "" }

    var toolProgress: [ToolProgress] {
        Tool.allCases.map { tool in
            let found = scan.reports.values.filter { $0.id.tool == tool && !$0.accessDenied }.reduce(Int64(0)) { $0 + $1.totalSize }
            return ToolProgress(tool: tool, fraction: scan.progress(for: tool), foundText: Self.format(found))
        }
    }

    var scanRows: [ScanRow] {
        let ids = scan.scannedCategories.isEmpty ? CategoryID.allCases : scan.scannedCategories
        return ids.map { id in
            let info = CategoryInfo.info(for: id)
            guard !scan.pending.contains(id), let report = scan.reports[id] else {
                return ScanRow(id: id, name: info.name, symbol: info.symbol, tool: id.tool, isFound: false, sizeText: "", isDimmed: false)
            }
            let size = report.totalSize
            let text = report.accessDenied ? L10n.string("Sin acceso") : size == 0 ? L10n.string("No encontrado") : Self.format(size)
            return ScanRow(id: id, name: info.name, symbol: info.symbol, tool: id.tool, isFound: true, sizeText: text, isDimmed: report.accessDenied || size == 0)
        }
    }

    // MARK: Helpers

    private static func format(_ bytes: Int64) -> String {
        ByteFormatter.string(bytes, locale: AppLanguage.current.locale)
    }

    private static func order(_ id: CategoryID) -> Int { CategoryID.allCases.firstIndex(of: id) ?? 0 }

    private static func row(_ id: CategoryID, bytes: Int64) -> CategoryRow {
        let info = CategoryInfo.info(for: id)
        return CategoryRow(id: id, name: info.name, symbol: info.symbol, sizeText: format(bytes))
    }
}
