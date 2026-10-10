import SwiftUI

@main
struct MobileDevCleanerApp: App {
    @State fileprivate var scanStore: ScanStore
    @State fileprivate var historyStore: HistoryStore
    @State fileprivate var router: AppRouter
    @State fileprivate var selection = SelectionStore()
    @State fileprivate var settings: SettingsStore
    @AppStorage(MDCMaterial.storageKey) fileprivate var material: MDCMaterial = .liquidGlass
    @AppStorage(AppLanguage.storageKey) fileprivate var language: AppLanguage = .system

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
        let settings = SettingsStore()
        _settings = State(initialValue: settings)
        let router = AppRouter()
        router.isOnboardingPresented = !settings.onboardingCompleted
        _router = State(initialValue: router)
        _scanStore = State(initialValue: ScanStore(scan: sl(), tools: { settings.enabledTools }))
        _historyStore = State(initialValue: HistoryStore(load: sl(), record: sl()))
    }

    var body: some Scene {
        WindowGroup {
            // The benchmark measures the scan alone; drawing the UI would skew it.
            // As a test host the app must not scan the real disk either.
            if !HeadlessScan.isRequested && !Self.isTestHost {
                // L10n strings aren't observed by SwiftUI; rebuilding on a language change
                // re-resolves them. Stores live above this view, so scan state survives.
                MainWindowContent()
                    .id(language)
                    .appEnvironment(self)
            }
        }
        .defaultSize(width: 1100, height: 720)
        .windowToolbarStyle(.unified)
        .commands { AppCommands(store: scanStore, router: router) }

        Settings {
            SettingsView()
                .appEnvironment(self)
        }
    }

    private static let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    fileprivate var colorScheme: ColorScheme? {
        switch settings.theme {
        case .light: .light
        case .dark: .dark
        case .auto: nil
        }
    }
}

private extension View {
    func appEnvironment(_ app: MobileDevCleanerApp) -> some View {
        environment(app.scanStore)
            .environment(app.historyStore)
            .environment(app.router)
            .environment(app.selection)
            .environment(app.settings)
            .environment(\.mdcMaterial, app.material)
            .environment(\.locale, app.language.locale)
            .preferredColorScheme(app.colorScheme)
    }
}
