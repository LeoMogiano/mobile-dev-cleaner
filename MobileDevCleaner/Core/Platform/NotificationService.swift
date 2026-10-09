import Foundation
import UserNotifications

protocol NotificationAuthorizing: Sendable {
    func isAuthorized() async -> Bool
    /// Shows the system prompt the first time; returns whether notifications are allowed.
    func requestAuthorization() async -> Bool
}

protocol CleanupNotifying: Sendable {
    /// Posts "Limpieza completada" only if the user already allowed notifications.
    func notifyCleanupFinished(freedBytes: Int64, failureCount: Int) async
}

struct NotificationService: CleanupNotifying, NotificationAuthorizing {
    func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func notifyCleanupFinished(freedBytes: Int64, failureCount: Int) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = L10n.string("Limpieza completada")

        let freedString = ByteFormatter.string(freedBytes)
        content.body = switch failureCount {
        case 0: L10n.string("Liberaste \(freedString). Parte volverá a crecer al compilar.")
        case 1: L10n.string("Liberaste \(freedString). 1 no se pudo limpiar.")
        default: L10n.string("Liberaste \(freedString). \(failureCount) no se pudieron limpiar.")
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
