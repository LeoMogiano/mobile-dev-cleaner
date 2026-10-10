import SwiftUI

struct SidebarView: View {
    @Environment(ScanStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(SettingsStore.self) private var settings
    @State private var expanded: Set<Tool> = []
    @State private var openSections: Set<Tool> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let model = SidebarSections(
            reports: store.reports, pending: store.pending, showEmpty: settings.showEmpty,
            expanded: expanded, selected: selectedCategory, tools: settings.enabledTools
        )
        // Footer below the list, not a safe-area inset, so rows never scroll behind it.
        VStack(spacing: 0) {
            list(model)
            historyFooter
        }
        .navigationSplitViewColumnWidth(min: 262, ideal: 262, max: 340)
    }

    private func list(_ model: SidebarSections) -> some View {
        List(selection: selection) {
            SidebarRow(title: L10n.string("Resumen"), symbol: "square.grid.2x2", isSelected: router.selection == .overview)
                .tag(SidebarItem.overview)
            ForEach(model.sections) { section in
                toolRow(section)
                if openSections.contains(section.tool) {
                    ForEach(section.rows) { row in
                        SidebarRow(
                            title: row.name, symbol: row.symbol, trailing: row.sizeText,
                            isSelected: router.selection == .category(row.id),
                            isDimmed: row.state != .normal, disclosure: .reserved
                        )
                        .padding(.leading, 14)
                        .help(row.tip)
                        .tag(SidebarItem.category(row.id))
                    }
                    if section.hasMore { moreButton(section) }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) { SidebarWordmark() }
        .onChange(of: selectedCategory, initial: true) { revealSelection() }
    }

    private var selectedCategory: CategoryID? {
        if case .category(let id) = router.selection { id } else { nil }
    }

    private func toolRow(_ section: SidebarSections.Section) -> some View {
        let isOpen = openSections.contains(section.tool)
        return Button {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                if isOpen { openSections.remove(section.tool) } else { openSections.insert(section.tool) }
            }
        } label: {
            SidebarRow(
                title: section.title, symbol: section.tool.symbolName, trailing: section.total,
                disclosure: .chevron(isOpen: isOpen)
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOpen ? L10n.string("Expandido") : L10n.string("Contraído"))
    }

    /// Sections start collapsed; opening a category from elsewhere reveals its section.
    private func revealSelection() {
        guard let id = selectedCategory else { return }
        openSections.insert(id.tool)
    }

    private var selection: Binding<SidebarItem?> {
        Binding(
            get: { router.selection },
            set: { if let item = $0 { router.show(item) } }
        )
    }

    private func moreButton(_ section: SidebarSections.Section) -> some View {
        Button {
            if expanded.contains(section.tool) { expanded.remove(section.tool) } else { expanded.insert(section.tool) }
        } label: {
            Label(section.moreLabel, systemImage: section.moreSymbol)
                .font(.system(size: 12))
                .foregroundStyle(Color.mdcText2)
                .frame(height: 26)
                .padding(.leading, 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var historyFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button { router.show(.history) } label: {
                SidebarRow(
                    title: L10n.string("Historial"), symbol: "clock.arrow.circlepath",
                    isSelected: router.selection == .history
                )
                .padding(.horizontal, 8)
                .background(
                    router.selection == .history ? Color.mdcAccent : .clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
    }
}
