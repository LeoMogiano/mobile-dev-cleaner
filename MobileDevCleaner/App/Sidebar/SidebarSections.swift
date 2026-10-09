import Foundation

/// Pure sidebar model: sections with totals; only the biggest `visibleLimit` rows show,
/// the rest collapse into "N más pequeñas".
struct SidebarSections: Equatable {
    enum RowState: Equatable {
        case normal, notFound, noAccess, scanning
    }

    struct Row: Equatable, Identifiable {
        let id: CategoryID
        let name: String
        let symbol: String
        let sizeText: String
        let state: RowState
        let tip: String
    }

    struct Section: Equatable, Identifiable {
        let tool: Tool
        let title: String
        /// Empty while scanning.
        let total: String
        let rows: [Row]
        let hiddenCount: Int
        let isExpanded: Bool
        var id: Tool { tool }
        var hasMore: Bool { smallCount > 0 }
        var moreLabel: String { isExpanded ? "Menos" : "\(hiddenCount) más pequeñas" }
        var moreSymbol: String { isExpanded ? "chevron.down" : "chevron.right" }
        fileprivate(set) var smallCount = 0
    }

    static let visibleLimit = 4

    let sections: [Section]

    init(
        reports: [CategoryID: CategoryReport],
        pending: Set<CategoryID>,
        showEmpty: Bool,
        expanded: Set<Tool>,
        selected: CategoryID? = nil,
        tools: Set<Tool> = Set(Tool.allCases)
    ) {
        let scanning = !pending.isEmpty
        sections = Tool.allCases.filter(tools.contains).map { tool in
            let ids = CategoryID.allCases.filter { $0.tool == tool }
            var rows: [(row: Row, size: Int64)] = []
            var total: Int64 = 0
            for id in ids {
                let info = CategoryInfo.info(for: id)
                let report = reports[id]
                let state = Self.state(report, pending: pending.contains(id))
                let size = report?.totalSize ?? 0
                if state == .normal || state == .notFound { total += size }
                if state == .notFound && !showEmpty { continue }
                let row = Row(
                    id: id, name: info.name, symbol: info.symbol,
                    sizeText: Self.text(state, size), state: state,
                    tip: "\(info.name) · \(info.technicalName)"
                )
                rows.append((row, size))
            }
            // While scanning sizes are unknown: keep the first rows so the list doesn't jump.
            let ranked = scanning ? rows : rows.enumerated().sorted {
                $0.element.size != $1.element.size ? $0.element.size > $1.element.size : $0.offset < $1.offset
            }.map(\.element)
            var shown = Set(ranked.prefix(Self.visibleLimit).map(\.row.id))
            if let selected { shown.insert(selected) }
            let smalls = rows.filter { !shown.contains($0.row.id) }.count
            let isOpen = expanded.contains(tool)
            let showAll = isOpen && !scanning
            var section = Section(
                tool: tool,
                title: tool == .xcode ? "Xcode" : "Android",
                total: scanning ? "" : ByteFormatter.string(total),
                rows: (showAll ? rows : rows.filter { shown.contains($0.row.id) }).map(\.row),
                hiddenCount: showAll ? 0 : smalls,
                isExpanded: showAll
            )
            section.smallCount = smalls
            return section
        }
    }

    private static func state(_ report: CategoryReport?, pending: Bool) -> RowState {
        guard let report, !pending else { return .scanning }
        if report.accessDenied && report.isEmpty { return .noAccess }
        return report.totalSize == 0 ? .notFound : .normal
    }

    private static func text(_ state: RowState, _ size: Int64) -> String {
        switch state {
        case .scanning: "…"
        case .noAccess: "Sin acceso"
        case .notFound: "No encontrado"
        case .normal: ByteFormatter.string(size)
        }
    }
}
