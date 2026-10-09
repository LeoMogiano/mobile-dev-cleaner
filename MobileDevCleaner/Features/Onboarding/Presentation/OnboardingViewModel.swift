import SwiftUI

enum OnboardingIntent: Sendable {
    case appear
    case next
    case back
    /// Secondary button: "Ahora no" (step 2) / "No, gracias" (step 3).
    case skip
}

@MainActor @Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case welcome, howItWorks, fullDiskAccess, notifications, done
    }

    private(set) var step: Step = .welcome
    private(set) var notificationsAllowed = false
    let fullDiskAccess: FullDiskAccessViewModel

    @ObservationIgnored private let notifications: any NotificationAuthorizing
    @ObservationIgnored private let settings: SettingsStore
    @ObservationIgnored private let onFinish: @MainActor () -> Void

    init(
        fullDiskAccess: FullDiskAccessViewModel, notifications: any NotificationAuthorizing,
        settings: SettingsStore, onFinish: @escaping @MainActor () -> Void
    ) {
        self.fullDiskAccess = fullDiskAccess
        self.notifications = notifications
        self.settings = settings
        self.onFinish = onFinish
    }

    var showsBack: Bool { step != .welcome }

    /// nil hides the secondary button.
    var secondaryTitle: String? {
        switch step {
        case .fullDiskAccess: fullDiskAccess.isGranted ? nil : L10n.string("Ahora no")
        case .notifications: notificationsAllowed ? nil : L10n.string("No, gracias")
        default: nil
        }
    }

    var primaryTitle: String {
        switch step {
        case .welcome: L10n.string("Comenzar")
        case .howItWorks: L10n.string("Continuar")
        case .fullDiskAccess:
            switch fullDiskAccess.status {
            case .granted: L10n.string("Continuar")
            case .waiting: L10n.string("Esperando permiso…")
            case .idle: L10n.string("Abrir Ajustes del Sistema")
            }
        case .notifications: notificationsAllowed ? L10n.string("Continuar") : L10n.string("Permitir notificaciones")
        case .done: L10n.string("Escanear mi Mac")
        }
    }

    var isPrimaryEnabled: Bool { !(step == .fullDiskAccess && fullDiskAccess.status == .waiting) }

    func handle(_ intent: OnboardingIntent) {
        switch intent {
        case .appear:
            fullDiskAccess.handle(.refresh)
            Task { notificationsAllowed = await notifications.isAuthorized() }
        case .next: Task { await next() }
        case .skip:
            switch step {
            case .fullDiskAccess:
                fullDiskAccess.handle(.stopWaiting)
                advance()
            case .notifications:
                settings.notifyOnFinish = false
                advance()
            default: break
            }
        case .back:
            if step == .fullDiskAccess { fullDiskAccess.handle(.stopWaiting) }
            if let previous = Step(rawValue: step.rawValue - 1) { step = previous }
        }
    }

    private func next() async {
        switch step {
        case .fullDiskAccess where !fullDiskAccess.isGranted:
            fullDiskAccess.handle(.openSystemSettings)
        case .notifications where !notificationsAllowed:
            notificationsAllowed = await notifications.requestAuthorization()
            settings.notifyOnFinish = notificationsAllowed
            advance()
        case .done:
            settings.onboardingCompleted = true
            onFinish()
        default: advance()
        }
    }

    private func advance() {
        if let following = Step(rawValue: step.rawValue + 1) { step = following }
    }
}
