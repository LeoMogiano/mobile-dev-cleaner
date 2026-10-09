import SwiftUI

struct AppCommands: Commands {
    let store: ScanStore
    let router: AppRouter

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Escanear de nuevo") { store.handle(.start) }
                .keyboardShortcut("r")
            Divider()
            Button("Ir a Xcode") { router.show(.category(.builds)) }
                .keyboardShortcut("1")
            Button("Ir a Android") { router.show(.category(.gcache)) }
                .keyboardShortcut("2")
            Button("Ir a Flutter") { router.show(.category(.fprojects)) }
                .keyboardShortcut("3")
        }
    }
}
