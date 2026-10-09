import SwiftUI

struct SidebarView: View {
    @Environment(ScanStore.self) private var store
    @Environment(AppRouter.self) private var router
    @AppStorage("general.showEmpty") private var showEmpty = false
    @State private var expanded: Set<Tool> = []

    var body: some View {
        let model = SidebarSections(
            reports: store.reports, pending: store.pending, showEmpty: showEmpty,
            expanded: expanded, selected: selectedCategory
        )
        List(selection: selection) {
            SidebarRow(title: "Resumen", symbol: "square.grid.2x2", isSelected: router.selection == .overview)
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
            Section {
                flutterRow
            } header: {
                SidebarSectionHeader(title: "Flutter")
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

    private var flutterRow: some View {
        Button {
            router.toast = "Limpieza de proyectos Flutter (build/, .dart_tool, pub cache): llega pronto"
        } label: {
            SidebarRow(title: "Proyectos Flutter", symbol: "square.3.layers.3d", iconColor: .mdcText3, badge: "Pronto")
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.mdcText2)
        .help("Proyectos Flutter: build/, .dart_tool y caché de pub")
    }

    private var historyFooter: some View {
        VStack(spacing: 0) {
            Divider()
            Button { router.show(.history) } label: {
                SidebarRow(
                    title: "Historial", symbol: "clock.arrow.circlepath",
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
                .shadow(color: Color(red: 60 / 255, green: 80 / 255, blue: 1).opacity(0.3), radius: 3, y: 2)
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
