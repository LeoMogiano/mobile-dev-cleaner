import SwiftUI

@main
struct MobileDevCleanerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1100, height: 720)
        .windowToolbarStyle(.unified)

        Settings {
            Text("Ajustes")
                .frame(width: 480, height: 320)
        }
    }
}
