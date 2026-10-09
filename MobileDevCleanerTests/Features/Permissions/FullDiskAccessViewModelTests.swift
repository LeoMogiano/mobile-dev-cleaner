import Foundation
import Testing
@testable import MobileDevCleaner

actor MockFullDiskAccessChecker: FullDiskAccessChecking {
    private var granted: Bool
    init(granted: Bool = false) { self.granted = granted }
    func set(_ value: Bool) { granted = value }
    func isGranted() async -> Bool { granted }
}

@MainActor
final class SettingsOpenCounter {
    private(set) var count = 0
    func hit() { count += 1 }
}

@Suite("FullDiskAccessViewModel")
@MainActor
struct FullDiskAccessViewModelTests {
    private func make(granted: Bool, counter: SettingsOpenCounter = SettingsOpenCounter())
        -> (FullDiskAccessViewModel, MockFullDiskAccessChecker, SettingsOpenCounter) {
        let checker = MockFullDiskAccessChecker(granted: granted)
        let vm = FullDiskAccessViewModel(
            checker: checker, pollInterval: .milliseconds(10), openSettings: { counter.hit() })
        return (vm, checker, counter)
    }

    @Test("refresh reports granted when already allowed")
    func refreshGranted() async {
        let (vm, _, _) = make(granted: true)
        vm.handle(.refresh)
        await waitUntil { vm.status == .granted }
    }

    @Test("refresh stays idle when not allowed")
    func refreshIdle() async throws {
        let (vm, _, _) = make(granted: false)
        vm.handle(.refresh)
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.status == .idle)
    }

    @Test("open settings waits then flips to granted via polling and fires onGranted")
    func pollGrants() async {
        let (vm, checker, counter) = make(granted: false)
        var grantedCalls = 0
        vm.onGranted = { grantedCalls += 1 }
        vm.handle(.openSystemSettings)
        #expect(vm.status == .waiting)
        #expect(counter.count == 1)
        await checker.set(true)
        await waitUntil { vm.status == .granted }
        #expect(grantedCalls == 1)
    }

    @Test("stop waiting cancels polling and returns to idle")
    func stopWaiting() async throws {
        let (vm, checker, _) = make(granted: false)
        var grantedCalls = 0
        vm.onGranted = { grantedCalls += 1 }
        vm.handle(.openSystemSettings)
        vm.handle(.stopWaiting)
        #expect(vm.status == .idle)
        await checker.set(true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(vm.status == .idle)
        #expect(grantedCalls == 0)
    }

    @Test("checker reads a readable file as granted and a missing path as denied")
    func checkerProbe() async throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try Data("x".utf8).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        #expect(await FullDiskAccessChecker(probeURL: file).isGranted())
        let missing = file.appending(path: "missing")
        #expect(await FullDiskAccessChecker(probeURL: missing).isGranted() == false)
    }
}
