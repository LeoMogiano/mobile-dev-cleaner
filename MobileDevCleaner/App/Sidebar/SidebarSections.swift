import Foundation

/// Pure sidebar model: sections with totals, ≥ 1 GB rule and "N más pequeñas".
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

    static let smallThreshold: Int64 = 1_000_000_000

    let sections: [Section]

    init(
        reports: [CategoryID: CategoryReport],
        pending: Set<CategoryID>,
        showEmpty: Bool,
        expanded: Set<Tool>,
        selected: CategoryID? = nil
    ) {
        let scanning = !pending.isEmpty
        sections = Tool.allCases.map { tool in
            let ids = CategoryID.allCases.filter { $0.tool == tool }
            var rows: [(Row, small: Bool)] = []
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
                let measured = state == .normal || state == .notFound
                rows.append((row, measured && size < Self.smallThreshold && selected != id))
            }
            let smalls = rows.filter(\.small).count
            let isOpen = expanded.contains(tool)
            let showAll = isOpen || scanning
            var section = Section(
                tool: tool,
                title: tool == .xcode ? "Xcode" : "Android",
                total: scanning ? "" : ByteFormatter.string(total),
                rows: (showAll ? rows : rows.filter { !$0.small }).map(\.0),
                hiddenCount: scanning || isOpen ? 0 : smalls,
                isExpanded: isOpen && !scanning
            )
            section.smallCount = scanning ? 0 : smalls
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
