import Foundation

enum SidebarItem: Hashable, Sendable {
    case overview
    case category(CategoryID)
    case history
}
