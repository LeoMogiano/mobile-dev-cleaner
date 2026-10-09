import SwiftUI

@MainActor @Observable
final class AppRouter {
    var selection: SidebarItem = .overview
    var searchQuery = ""
    var isInspectorPresented = false
    var toast: String?

    func show(_ item: SidebarItem) {
        selection = item
        searchQuery = ""
        isInspectorPresented = false
    }
}
