import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("SettingsStore")
@MainActor
struct SettingsStoreTests {
    @Test("defaults has moveToTrash true")
    func testMoveToTrashDefault() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        #expect(store.moveToTrash == true)
    }

    @Test("defaults has confirmCost true")
    func testConfirmCostDefault() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        #expect(store.confirmCost == true)
    }

    @Test("other defaults are false")
    func testOtherDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        #expect(store.showEmpty == false)
        #expect(store.showTechnicalNames == false)
        #expect(store.showCommands == false)
    }

    @Test("persistence across instances")
    func testPersistence() {
        let suiteName = UUID().uuidString
        do {
            let defaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: defaults)
            let m = store
            m.moveToTrash = false
            #expect(m.moveToTrash == false)
        }
        do {
            let defaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: defaults)
            #expect(store.moveToTrash == false)
        }
    }

    @Test("isExcluded exact match")
    func testIsExcludedExact() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        store.excludedPaths = ["/a/b"]
        #expect(store.isExcluded("/a/b"))
    }

    @Test("isExcluded prefix match with trailing slash")
    func testIsExcludedPrefixWithSlash() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        store.excludedPaths = ["/a/b"]
        #expect(store.isExcluded("/a/b/c"))
    }

    @Test("isExcluded does not match sibling prefix without slash")
    func testIsExcludedNoSibling() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        store.excludedPaths = ["/a/b"]
        #expect(!store.isExcluded("/a/bc"))
    }

    @Test("isExcluded handles multiple paths")
    func testIsExcludedMultiple() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        store.excludedPaths = ["/a/b", "/x/y"]
        #expect(store.isExcluded("/a/b/c"))
        #expect(store.isExcluded("/x/y/z"))
        #expect(!store.isExcluded("/a/c"))
    }

    @Test("isExcluded with trailing slash in path")
    func testIsExcludedTrailingSlashInPath() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = SettingsStore(defaults: defaults)
        store.excludedPaths = ["/a/b"]
        #expect(store.isExcluded("/a/b/"))
    }

    @Test("persistence of excluded paths")
    func testExcludedPersistence() {
        let suiteName = UUID().uuidString
        do {
            let defaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: defaults)
            store.excludedPaths = ["/path/1", "/path/2"]
        }
        do {
            let defaults = UserDefaults(suiteName: suiteName)!
            let store = SettingsStore(defaults: defaults)
            #expect(store.excludedPaths == ["/path/1", "/path/2"])
        }
    }

    @Test("enabledTools reflects scan flags")
    func testEnabledTools() {
        let store = SettingsStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)

        store.scanXcode = true
        store.scanAndroid = false
        store.scanFlutter = false
        #expect(store.enabledTools == [.xcode])

        store.scanAndroid = true
        #expect(store.enabledTools == [.xcode, .android])

        store.scanXcode = false
        store.scanFlutter = true
        #expect(store.enabledTools == [.android, .flutter])
    }

    @Test("reset reverts to defaults without touching onboarding")
    func testResetWithoutOnboarding() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!

        let store = SettingsStore(defaults: defaults)
        store.scanXcode = false
        store.scanFlutter = false
        store.notifyOnFinish = true
        store.excludedPaths = ["/test"]
        store.theme = .dark
        store.onboardingCompleted = true

        store.reset()

        #expect(store.scanXcode == true)
        #expect(store.scanAndroid == true)
        #expect(store.scanFlutter == true)
        #expect(store.notifyOnFinish == false)
        #expect(store.excludedPaths.isEmpty)
        #expect(store.theme == .auto)
        #expect(store.onboardingCompleted == true)
    }
}
