import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("GeneralSettingsViewModel")
@MainActor
struct GeneralSettingsViewModelTests {
    @Test("appear reflects full disk access status")
    func appearReflectsFullDiskAccess() async {
        let checker = TestMockFullDiskAccessChecker(granted: true)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        #expect(vm.hasFullDiskAccess == false)
        vm.handle(.appear)

        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(vm.hasFullDiskAccess == true)
    }

    @Test("setNotifyOnFinish with authorization allowed")
    func setNotifyOnFinishAllowed() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer(allowed: true)
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        #expect(settings.notifyOnFinish == false)
        #expect(vm.notificationsDenied == false)

        vm.handle(.setNotifyOnFinish(true))
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(settings.notifyOnFinish == true)
        #expect(vm.notificationsDenied == false)
    }

    @Test("setNotifyOnFinish with authorization denied")
    func setNotifyOnFinishDenied() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer(allowed: false)
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        vm.handle(.setNotifyOnFinish(true))
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(settings.notifyOnFinish == false)
        #expect(vm.notificationsDenied == true)
    }

    @Test("setNotifyOnFinish(false) clears denied flag")
    func setNotifyOnFinishFalse() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        vm.handle(.setNotifyOnFinish(false))

        #expect(settings.notifyOnFinish == false)
        #expect(vm.notificationsDenied == false)
    }

    @Test("addExcludedFolder adds path without duplicates")
    func addExcludedFolder() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let testURL = URL(filePath: "/tmp/test")
        var chooseCount = 0

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: {
                chooseCount += 1
                return chooseCount <= 2 ? testURL : nil
            }
        )

        #expect(settings.excludedPaths.isEmpty)

        vm.handle(.addExcludedFolder)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(settings.excludedPaths == ["/tmp/test"])

        vm.handle(.addExcludedFolder)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(settings.excludedPaths == ["/tmp/test"])

        vm.handle(.addExcludedFolder)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(settings.excludedPaths == ["/tmp/test"])
    }

    @Test("addExcludedFolder handles cancel (nil)")
    func addExcludedFolderCancel() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        vm.handle(.addExcludedFolder)
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(settings.excludedPaths.isEmpty)
    }

    @Test("removeExcludedFolder removes path")
    func removeExcludedFolder() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        settings.excludedPaths = ["/path/one", "/path/two", "/path/three"]
        vm.handle(.removeExcludedFolder("/path/two"))

        #expect(settings.excludedPaths == ["/path/one", "/path/three"])
    }

    @Test("grantFullDiskAccess opens sheet")
    func grantFullDiskAccess() async {
        let checker = TestMockFullDiskAccessChecker(granted: false)
        let notifications = TestMockNotificationAuthorizer()
        let router = AppRouter()
        let settings = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        let vm = GeneralSettingsViewModel(
            settings: settings,
            fullDiskAccess: checker,
            notifications: notifications,
            router: router,
            chooseFolder: { nil }
        )

        #expect(router.isFullDiskAccessPresented == false)
        vm.handle(.grantFullDiskAccess)
        #expect(router.isFullDiskAccessPresented == true)
    }
}

// MARK: - Mocks

private actor TestMockFullDiskAccessChecker: FullDiskAccessChecking {
    private let granted: Bool

    init(granted: Bool) {
        self.granted = granted
    }

    func isGranted() async -> Bool {
        granted
    }
}

private actor TestMockNotificationAuthorizer: NotificationAuthorizing {
    private let allowed: Bool

    init(allowed: Bool = false) {
        self.allowed = allowed
    }

    func isAuthorized() async -> Bool {
        allowed
    }

    func requestAuthorization() async -> Bool {
        allowed
    }
}

