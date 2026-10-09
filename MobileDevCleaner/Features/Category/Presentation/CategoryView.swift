import SwiftUI

struct CategoryView: View {
    let category: CategoryID

    @Environment(ScanStore.self) private var scanStore
    @Environment(SelectionStore.self) private var selectionStore
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CategoryViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                content(viewModel)
                    .frame(maxWidth: 860)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 90)
                    .frame(maxWidth: .infinity)
            }
        }
        .task(id: category) {
            viewModel = CategoryViewModel(
                category: category, scan: scanStore, selection: selectionStore,
                settings: settingsStore, router: router
            )
        }
    }

    private func content(_ vm: CategoryViewModel) -> some View {
        @Bindable var vm = vm
        return VStack(spacing: 14) {
            CategoryHeader(category: category, sizeText: vm.sizeText, badges: vm.badges)
            if vm.showsAccessBanner {
                CategoryAccessBanner()
            }
            MDCExplainerCard(
                whatIsIt: vm.info.whatIsIt, ifDeleted: vm.info.ifDeleted, comesBack: vm.info.comesBack,
                isExpanded: $vm.isExplainerExpanded
            )
            if vm.isEmpty {
                CategoryEmptyState(symbol: vm.info.symbol)
            } else {
                actions(vm)
                if vm.groups.isEmpty {
                    Text("Nada coincide con el filtro o la búsqueda.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.mdcText3)
                        .padding(28)
                }
                ForEach(vm.groups) { group in
                    CandidateGroupView(
                        group: group,
                        onToggle: { vm.handle(.toggle($0)) },
                        onInspect: { vm.handle(.inspect($0)) },
                        onShowInFinder: { vm.handle(.showInFinder($0)) }
                    )
                }
            }
        }
    }

    private func actions(_ vm: CategoryViewModel) -> some View {
        HStack(spacing: 8) {
            Text(vm.countText)
                .font(.system(size: 12))
                .foregroundStyle(Color.mdcText2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Marcar todo") { vm.handle(.selectAll) }
                .keyboardShortcut("a")
                .help("Marcar todo (⌘A)")
            Button("Ninguno") { vm.handle(.selectNone) }
        }
        .buttonStyle(MDCSecondaryButtonStyle(height: 24, horizontalPadding: 10, weight: .regular))
    }
}
