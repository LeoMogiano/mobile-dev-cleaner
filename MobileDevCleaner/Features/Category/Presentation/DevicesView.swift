import SwiftUI

struct DevicesView: View {
    let category: CategoryID

    @Environment(ScanStore.self) private var scanStore
    @Environment(SelectionStore.self) private var selectionStore
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(AppRouter.self) private var router
    @State private var viewModel: DevicesViewModel?

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
            viewModel = DevicesViewModel(
                category: category, scan: scanStore, selection: selectionStore,
                settings: settingsStore, router: router
            )
        }
    }

    private func content(_ vm: DevicesViewModel) -> some View {
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
                Text(vm.countText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.mdcText2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                grid(vm)
            }
        }
    }

    @ViewBuilder
    private func grid(_ vm: DevicesViewModel) -> some View {
        let cards = vm.cards
        if cards.isEmpty {
            Text("Nada coincide con el filtro o la búsqueda.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.mdcText3)
                .padding(28)
        }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
            ForEach(cards) { card in
                DeviceCard(
                    card: card,
                    onSelectAction: { vm.handle(.setAction(card.id, $0)) },
                    onInspect: { vm.handle(.inspect(card.id)) }
                )
                .equatable()
            }
        }
    }
}
