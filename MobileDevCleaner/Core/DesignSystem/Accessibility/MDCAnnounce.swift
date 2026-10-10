import SwiftUI

enum MDCAnnounce {
    @MainActor
    static func post(_ text: String) {
        AccessibilityNotification.Announcement(text).post()
    }
}
