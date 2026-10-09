import Foundation
import Testing
@testable import MobileDevCleaner

private actor MockNotifications: NotificationAuthorizing {
    private var authorized: Bool
    private let grantsOnRequest: Bool
    private(set) var requests = 0
    init(authorized: Bool = false, grantsOnRequest: Bool = true) {
        self.authorized = authorized
        self.grantsOnRequest = grantsOnRequest
    }
    func isAuthorized() async -> Bool { authorized }
    func requestAuthorization() async -> Bool {
        requests += 1
        authorized = grantsOnRequest
        return grantsOnRequest
    }
}

@MainActor
private final class Flag { var value = false }

@MainActor
private struct Fixture {
    let vm: OnboardingViewModel
    let fda: FullDiskAccessViewModel
    let checker: MockFullDiskAccessChecker
    let settings: SettingsStore
    let finished = Flag()

    init(fdaGranted: Bool = false, notifications: MockNotifications = MockNotifications()) {
        checker = MockFullDiskAccessChecker(granted: fdaGranted)
        fda = FullDiskAccessViewModel(checker: checker, pollInterval: .milliseconds(10), openSettings: {})
        settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let flag = finished
        vm = OnboardingViewModel(
            fullDiskAccess: fda, notifications: notifications, settings: settings,
            onFinish: { flag.value = true })
    }

    func goToStep(_ n: Int) async {
        vm.handle(.appear)
        for _ in 0..<n {
            vm.handle(.next)
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {
    @Test("welcome and how-it-works titles and back visibility")
    func early() async {
        let f = Fixture()
        #expect(f.vm.primaryTitle == "Comenzar")
        #expect(f.vm.showsBack == false)
        #expect(f.vm.secondaryTitle == nil)
        await f.goToStep(1)
        #expect(f.vm.step == .howItWorks)
        #expect(f.vm.primaryTitle == "Continuar")
        #expect(f.vm.showsBack)
    }

    @Test("full disk access idle opens settings instead of advancing")
    func fdaIdleNext() async {
        let f = Fixture()
        await f.goToStep(2)
        #expect(f.vm.step == .fullDiskAccess)
        #expect(f.vm.primaryTitle == "Abrir Ajustes del Sistema")
        #expect(f.vm.secondaryTitle == "Ahora no")
        f.vm.handle(.next)
        try? await Task.sleep(for: .milliseconds(20))
        #expect(f.vm.step == .fullDiskAccess)
        #expect(f.fda.status == .waiting)
        #expect(f.vm.primaryTitle == "Esperando permiso…")
        #expect(f.vm.isPrimaryEnabled == false)
    }

    @Test("polling grant switches the primary to Continuar and hides skip")
    func fdaGranted() async {
        let f = Fixture()
        await f.goToStep(2)
        f.vm.handle(.next)
        await f.checker.set(true)
        await waitUntil { f.fda.status == .granted }
        #expect(f.vm.primaryTitle == "Continuar")
        #expect(f.vm.secondaryTitle == nil)
        #expect(f.vm.isPrimaryEnabled)
        f.vm.handle(.next)
        await waitUntil { f.vm.step == .notifications }
    }

    @Test("skipping full disk access advances and stops waiting")
    func fdaSkip() async {
        let f = Fixture()
        await f.goToStep(2)
        f.vm.handle(.next)
        f.vm.handle(.skip)
        #expect(f.vm.step == .notifications)
        #expect(f.fda.status == .idle)
    }

    @Test("back from full disk access stops waiting")
    func backStops() async {
        let f = Fixture()
        await f.goToStep(2)
        f.vm.handle(.next)
        f.vm.handle(.back)
        #expect(f.vm.step == .howItWorks)
        #expect(f.fda.status == .idle)
    }

    @Test("notifications denied: request, store false and advance")
    func notificationsDenied() async {
        let f = Fixture(fdaGranted: true, notifications: MockNotifications(grantsOnRequest: false))
        await f.goToStep(3)
        await waitUntil { f.vm.step == .notifications }
        #expect(f.vm.primaryTitle == "Permitir notificaciones")
        #expect(f.vm.secondaryTitle == "No, gracias")
        f.vm.handle(.next)
        await waitUntil { f.vm.step == .done }
        #expect(f.settings.notifyOnFinish == false)
    }

    @Test("notifications granted: request, store true and advance")
    func notificationsGranted() async {
        let f = Fixture(fdaGranted: true)
        await f.goToStep(3)
        f.vm.handle(.next)
        await waitUntil { f.vm.step == .done }
        #expect(f.settings.notifyOnFinish)
        #expect(f.vm.primaryTitle == "Escanear mi Mac")
    }

    @Test("already authorized notifications show Continuar and no skip")
    func notificationsAlreadyAllowed() async {
        let f = Fixture(fdaGranted: true, notifications: MockNotifications(authorized: true))
        await f.goToStep(3)
        await waitUntil { f.vm.notificationsAllowed }
        #expect(f.vm.primaryTitle == "Continuar")
        #expect(f.vm.secondaryTitle == nil)
    }

    @Test("skipping notifications turns the setting off and advances")
    func notificationsSkip() async {
        let f = Fixture(fdaGranted: true)
        await f.goToStep(3)
        f.settings.notifyOnFinish = true
        f.vm.handle(.skip)
        #expect(f.vm.step == .done)
        #expect(f.settings.notifyOnFinish == false)
    }

    @Test("done marks onboarding completed and calls onFinish")
    func done() async {
        let f = Fixture(fdaGranted: true)
        await f.goToStep(3)
        f.vm.handle(.skip)
        f.vm.handle(.next)
        await waitUntil { f.finished.value }
        #expect(f.settings.onboardingCompleted)
    }
}
