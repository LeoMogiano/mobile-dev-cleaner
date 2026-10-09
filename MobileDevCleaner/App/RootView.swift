import SwiftUI

struct RootView: View {
    @Environment(ScanStore.self) private var scanStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(AppRouter.self) private var router
    @Environment(SelectionStore.self) private var selection
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var router = router
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
                .overlay(alignment: .bottom) { selectionBar }
                .inspector(isPresented: $router.isInspectorPresented) {
                    InspectorView()
                        .inspectorColumnWidth(248)
                }
        }
        .searchable(text: $router.searchQuery, placement: .toolbar, prompt: "Buscar")
        .toolbar {
            ToolbarItem {
                Button { scanStore.handle(.start) } label: {
                    Label("Escanear de nuevo", systemImage: "arrow.clockwise")
                }
                .help("Escanear de nuevo (⌘R)")
                .accessibilityLabel("Escanear de nuevo")
            }
            ToolbarItem {
                Button { openSettings() } label: {
                    Label("Ajustes", systemImage: "gearshape")
                }
                .help("Ajustes (⌘,)")
                .accessibilityLabel("Ajustes")
            }
        }
        .mdcToast($router.toast)
        .sheet(isPresented: $router.isReviewPresented) { ReviewSheet() }
        .task {
            historyStore.handle(.load)
            if scanStore.status == .idle { scanStore.handle(.start) }
        }
        .onChange(of: scanStore.status) { _, status in
            if case .finished = status { selection.prune(to: scanStore.reports) }
        }
    }

    @ViewBuilder
    private var selectionBar: some View {
        if !selection.isEmpty, !router.isReviewPresented {
            MDCSelectionBar(
                count: selection.count,
                bytes: selection.selectedBytes(in: scanStore.reports),
                onDeselect: { selection.clear() },
                onReview: { router.isReviewPresented = true }
            )
            .padding(.bottom, 16)
        }
    }
}
