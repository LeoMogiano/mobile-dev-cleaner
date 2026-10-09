import SwiftUI

@main
struct MobileDevCleanerApp: App {
    init() {
        Injection.setup()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 720)
        .windowToolbarStyle(.unified)

        Settings {
            Text("Ajustes")
                .frame(width: 620, height: 640)
        }
    }
}
