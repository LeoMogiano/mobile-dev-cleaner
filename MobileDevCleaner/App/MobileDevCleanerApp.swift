import SwiftUI

@main
struct MobileDevCleanerApp: App {
    @State private var scanStore: ScanStore
    @State private var historyStore: HistoryStore
    @State private var router = AppRouter()
    @State private var selection = SelectionStore()
    @State private var settings = SettingsStore()
    @AppStorage(MDCMaterial.storageKey) private var material: MDCMaterial = .liquidGlass

    init() {
        FontRegistrar.registerBundledFonts()
        Injection.setup()
        #if DEBUG
        if let directory = GalleryRenderer.outputDirectory {
            Task { GalleryRenderer.run(to: directory) }
        }
        #endif
        if HeadlessScan.isRequested {
            Task { await HeadlessScan.run() }
        }
        _scanStore = State(initialValue: ScanStore(scan: sl()))
        _historyStore = State(initialValue: HistoryStore(load: sl(), record: sl()))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(scanStore)
                .environment(historyStore)
                .environment(router)
                .environment(selection)
                .environment(settings)
                .environment(\.mdcMaterial, material)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 720)
        .windowToolbarStyle(.unified)
        .commands { AppCommands(store: scanStore, router: router) }

        Settings {
            Text("Ajustes")
                .frame(width: 620, height: 640)
        }
    }
}
