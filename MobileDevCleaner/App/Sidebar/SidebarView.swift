import SwiftUI

struct SidebarView: View {
    @Environment(ScanStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(SettingsStore.self) private var settings
    @State private var expanded: Set<Tool> = []

    var body: some View {
        let model = SidebarSections(
            reports: store.reports, pending: store.pending, showEmpty: settings.showEmpty,
            expanded: expanded, selected: selectedCategory, tools: settings.enabledTools
        )
        List(selection: selection) {
            SidebarRow(title: L10n.string("Resumen"), symbol: "square.grid.2x2", isSelected: router.selection == .overview)
                .tag(SidebarItem.overview)
            ForEach(model.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        SidebarRow(
                            title: row.name, symbol: row.symbol, trailing: row.sizeText,
                            isSelected: router.selection == .category(row.id),
                            isDimmed: row.state != .normal
                        )
                        .help(row.tip)
                        .tag(SidebarItem.category(row.id))
                    }
                    if section.hasMore { moreButton(section) }
                } header: {
                    SidebarSectionHeader(title: section.title, total: section.total)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 262, ideal: 262, max: 340)
        .safeAreaInset(edge: .top, spacing: 0) { SidebarWordmark() }
        .safeAreaInset(edge: .bottom, spacing: 0) { historyFooter }
    }

    private var selectedCategory: CategoryID? {
        if case .category(let id) = router.selection { id } else { nil }
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

private struct SidebarWordmark: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "trash")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0x3A / 255, green: 0xA0 / 255, blue: 1), location: 0),
                            .init(color: Color(red: 0x5B / 255, green: 0x6C / 255, blue: 1), location: 0.55),
                            .init(color: Color(red: 0xA3 / 255, green: 0x5B / 255, blue: 1), location: 1),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .accessibilityHidden(true)
            Text("Mobile Dev Cleaner")
                .font(.mont(13.5))
                .tracking(-0.27)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
