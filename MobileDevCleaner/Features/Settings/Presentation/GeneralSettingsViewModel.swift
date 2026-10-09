import SwiftUI

enum GeneralSettingsIntent: Sendable {
    case appear
    case setNotifyOnFinish(Bool)
    case addExcludedFolder
    case removeExcludedFolder(String)
    case grantFullDiskAccess
}

@MainActor @Observable
final class GeneralSettingsViewModel {
    private(set) var hasFullDiskAccess = false
    /// Shown when the user turns notifications on but macOS denies them.
    private(set) var notificationsDenied = false

    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let fullDiskAccess: any FullDiskAccessChecking
    @ObservationIgnored private let notifications: any NotificationAuthorizing
    @ObservationIgnored private let router: AppRouter
    @ObservationIgnored private let chooseFolder: @MainActor () async -> URL?

    init(
        settings: SettingsStore, fullDiskAccess: any FullDiskAccessChecking,
        notifications: any NotificationAuthorizing, router: AppRouter,
        chooseFolder: @escaping @MainActor () async -> URL?
    ) {
        self.settings = settings
        self.fullDiskAccess = fullDiskAccess
        self.notifications = notifications
        self.router = router
        self.chooseFolder = chooseFolder
    }

    func handle(_ intent: GeneralSettingsIntent) {
        switch intent {
        case .appear:
            Task {
                hasFullDiskAccess = await fullDiskAccess.isGranted()
            }

        case .setNotifyOnFinish(let enable):
            if enable {
                Task {
                    let ok = await notifications.requestAuthorization()
                    settings.notifyOnFinish = ok
                    notificationsDenied = !ok
                }
            } else {
                settings.notifyOnFinish = false
                notificationsDenied = false
            }

        case .addExcludedFolder:
            Task {
                if let url = await chooseFolder() {
                    let path = url.path
                    if !settings.excludedPaths.contains(path) {
                        settings.excludedPaths.append(path)
                    }
                }
            }

        case .removeExcludedFolder(let path):
            settings.excludedPaths.removeAll { $0 == path }

        case .grantFullDiskAccess:
            router.isFullDiskAccessPresented = true
        }
    }
}
