import SwiftUI
import AppKit

enum CategoryIntent: Sendable {
    case toggle(String)
    case selectAll
    case selectNone
    case inspect(String)
    case showInFinder(String)
}

struct CandidateRowModel: Identifiable, Hashable {
    let id: String
    let name: String
    /// Full path, only when "Mostrar nombres técnicos" is on.
    let path: String?
    let sizeText: String
    /// Size relative to the biggest row, for the 90×4 bar.
    let fraction: Double
    let risk: RiskLevel
    /// Badge per row only when the category mixes risks.
    let showsBadge: Bool
    let isSelected: Bool
    /// Rendered at 0.5 opacity; toggling shows a toast instead.
    let isExcluded: Bool
    let isInspected: Bool
    let accessibilityLabel: String
}

struct CandidateGroupModel: Identifiable, Hashable {
    let id: String
    /// nil for categories without groups.
    let title: String?
    let sizeText: String
    /// "Huérfano: seguro de borrar" / "Sin uso".
    let tag: String?
    let rows: [CandidateRowModel]
}

@MainActor @Observable
final class CategoryViewModel {
    let category: CategoryID
    let info: CategoryInfo
    var isExplainerExpanded = false

    @ObservationIgnored private let scan: ScanStore
    @ObservationIgnored private let selection: SelectionStore
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let router: AppRouter

    var sizeText: String {
        guard let report = scan.report(for: category) else { return "" }
        return ByteFormatter.string(report.totalSize)
    }

    var badges: [MDCBadgeKind] {
        guard let report = scan.report(for: category) else { return [] }
        var result: [MDCBadgeKind] = []
        if report.regeneratesSize > 0 {
            result.append(.regenerates)
        }
        if report.hasCostSize > 0 {
            result.append(.hasCost)
        }
        return result
    }

    var groups: [CandidateGroupModel] {
        guard let report = scan.report(for: category) else { return [] }
        let showBadgeOnRows = badges.count > 1
        let filteredCandidates = filterCandidates(report.candidates)
        let maxSize = report.candidates.map(\.size).max() ?? 1

        var groupedDict: [CandidateGroup?: [CleanupCandidate]] = [:]
        for candidate in filteredCandidates {
            let group = candidate.group
            if groupedDict[group] == nil {
                groupedDict[group] = []
            }
            groupedDict[group]?.append(candidate)
        }

        var result: [CandidateGroupModel] = []
        for candidateGroup in [nil] + CandidateGroup.allCases {
            guard let items = groupedDict[candidateGroup], !items.isEmpty else { continue }

            let groupTitle = candidateGroup.map { group in
                switch group {
                case .sharedCache: L10n.string("Caché compartido")
                case .projects: L10n.string("Tus proyectos")
                case .orphanProjects: L10n.string("Proyectos que ya no existen")
                case .usedByEmulators: L10n.string("Usadas por tus emuladores")
                case .unusedByEmulators: L10n.string("Ningún emulador la usa")
                }
            }

            let groupTag: String? = {
                switch candidateGroup {
                case .orphanProjects: L10n.string("Huérfano: seguro de borrar")
                case .unusedByEmulators: L10n.string("Sin uso")
                default: nil
                }
            }()

            let rows = items.map { candidate in
                let isExcl = settings.isExcluded(candidate.url.path)
                let frac = maxSize > 0 ? Double(candidate.size) / Double(maxSize) : 0
                return CandidateRowModel(
                    id: candidate.id,
                    name: candidate.name,
                    path: settings.showTechnicalNames ? candidate.url.path : nil,
                    sizeText: ByteFormatter.string(candidate.size),
                    fraction: frac,
                    risk: candidate.risk,
                    showsBadge: showBadgeOnRows,
                    isSelected: selection.isSelected(candidate),
                    isExcluded: isExcl,
                    isInspected: router.inspectedID == candidate.id,
                    accessibilityLabel: "\(candidate.name), \(ByteFormatter.string(candidate.size)), \(candidate.risk == .regenerates ? L10n.string("Se regenera solo") : L10n.string("Tiene costo"))"
                )
            }

            let groupSize = items.reduce(0) { $0 + $1.size }

            result.append(CandidateGroupModel(
                id: candidateGroup?.rawValue ?? "none",
                title: groupTitle,
                sizeText: ByteFormatter.string(groupSize),
                tag: groupTag,
                rows: rows
            ))
        }

        return result
    }

    var countText: String {
        guard let report = scan.report(for: category) else { return "" }
        let filteredCandidates = filterCandidates(report.candidates)
        let visibleCount = filteredCandidates.count
        let selectedCount = filteredCandidates.filter { selection.isSelected($0) }.count

        let countPart = visibleCount == 1 ? L10n.string("1 elemento") : L10n.string("\(visibleCount) elementos")

        if selectedCount > 0 {
            let selectedText = selectedCount == 1 ? L10n.string("1 marcado") : L10n.string("\(selectedCount) marcados")
            return "\(countPart) · \(selectedText)"
        }
        return countPart
    }

    var showsAccessBanner: Bool {
        scan.report(for: category)?.accessDenied ?? false
    }

    var isEmpty: Bool {
        guard let report = scan.report(for: category) else { return true }
        return report.isEmpty
    }

    private func matchesSearch(_ candidate: CleanupCandidate) -> Bool {
        let query = router.searchQuery
        guard !query.isEmpty else { return true }
        let normalized = query.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let name = candidate.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        let path = candidate.url.path.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        return name.contains(normalized) || path.contains(normalized)
    }

    private func filterCandidates(_ candidates: [CleanupCandidate]) -> [CleanupCandidate] {
        candidates.filter { matchesSearch($0) }
    }

    init(category: CategoryID, scan: ScanStore, selection: SelectionStore, settings: SettingsStore, router: AppRouter) {
        self.category = category
        self.info = CategoryInfo.info(for: category)
        self.scan = scan
        self.selection = selection
        self.settings = settings
        self.router = router
    }

    func handle(_ intent: CategoryIntent) {
        switch intent {
        case .toggle(let id):
            guard let report = scan.report(for: category), let candidate = report.candidates.first(where: { $0.id == id }) else { return }
            if settings.isExcluded(candidate.url.path) {
                router.toast = L10n.string("Está en Carpetas excluidas (Ajustes › General)")
            } else {
                selection.toggle(candidate)
            }

        case .selectAll:
            guard let report = scan.report(for: category) else { return }
            let filteredCandidates = filterCandidates(report.candidates)
            let toSelect = filteredCandidates.filter { !settings.isExcluded($0.url.path) }
            selection.select(toSelect)

        case .selectNone:
            guard let report = scan.report(for: category) else { return }
            let filteredCandidates = filterCandidates(report.candidates)
            selection.deselect(filteredCandidates)

        case .inspect(let id):
            router.inspect(id)

        case .showInFinder(let id):
            guard let report = scan.report(for: category), let candidate = report.candidates.first(where: { $0.id == id }) else { return }
            NSWorkspace.shared.activateFileViewerSelecting([candidate.url])
        }
    }
}
