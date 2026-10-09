import SwiftUI

@MainActor @Observable
final class AppRouter {
    var selection: SidebarItem = .overview
    var searchQuery = ""
    var isInspectorPresented = false
    /// Candidate path or device id shown in the inspector.
    var inspectedID: String?
    var isReviewPresented = false
    var isFullDiskAccessPresented = false
    var isOnboardingPresented = false
    var toast: String?

    func show(_ item: SidebarItem) {
        selection = item
        searchQuery = ""
        inspect(nil)
    }

    func inspect(_ id: String?) {
        inspectedID = id
        isInspectorPresented = id != nil
    }
}
