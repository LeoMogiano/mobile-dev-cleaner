import SwiftUI

struct RootView: View {
    @Environment(ScanStore.self) private var scanStore
    @Environment(AppRouter.self) private var router
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var router = router
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
                .inspector(isPresented: $router.isInspectorPresented) {
                    Text("Detalles")
                        .foregroundStyle(Color.mdcText3)
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
        .task {
            if scanStore.status == .idle { scanStore.handle(.start) }
        }
    }
}
