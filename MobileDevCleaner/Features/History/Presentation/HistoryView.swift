import SwiftUI

struct HistoryView: View {
    @Environment(HistoryStore.self) private var store
    @State private var viewModel: HistoryViewModel?

    var body: some View {
        ZStack {
            if viewModel?.isEmpty ?? true {
                ScrollView {
                    MDCEmptyState(
                        symbol: "clock.arrow.circlepath",
                        tint: .mdcAccent,
                        title: "Aún no has limpiado",
                        message: "Aquí verás cuánto espacio liberas en cada limpieza."
                    )
                }
            } else if let vm = viewModel {
                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        HistorySummaryCard(
                            totalText: vm.totalText,
                            countText: vm.countText,
                            bars: vm.bars
                        )

                        VStack(spacing: 0) {
                            ForEach(vm.rows) { row in
                                HistoryRow(row: row) {
                                    vm.handle(.toggle(row.id))
                                }
                                if row.id != vm.rows.last?.id {
                                    Divider().foregroundColor(.mdcLine)
                                }
                            }
                        }
                        .mdcCard(radius: 12)
                    }
                    .frame(maxWidth: 720)
                    .padding(EdgeInsets(top: 22, leading: 24, bottom: 40, trailing: 24))
                }
            }
        }
        .task {
            viewModel = HistoryViewModel(store: store)
            store.handle(.load)
        }
    }
}
