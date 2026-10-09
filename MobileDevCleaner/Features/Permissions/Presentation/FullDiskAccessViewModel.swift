import AppKit

enum FullDiskAccessIntent: Sendable {
    /// Reads the current state once (on appear).
    case refresh
    /// Opens System Settings › Privacy › Full Disk Access and polls until granted.
    case openSystemSettings
    case stopWaiting
}

/// Shared by the onboarding step, the "Dar acceso" sheet and Ajustes › Permisos.
@MainActor @Observable
final class FullDiskAccessViewModel {
    enum Status: Equatable {
        case idle
        case waiting
        case granted
    }

    private(set) var status: Status = .idle

    @ObservationIgnored private let checker: any FullDiskAccessChecking
    @ObservationIgnored private let pollInterval: Duration
    @ObservationIgnored private let openSettings: @MainActor () -> Void
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    /// Called once when access flips to granted while waiting.
    @ObservationIgnored var onGranted: (@MainActor () -> Void)?

    static let settingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!

    init(
        checker: any FullDiskAccessChecking, pollInterval: Duration = .seconds(1),
        openSettings: @escaping @MainActor () -> Void = { NSWorkspace.shared.open(FullDiskAccessViewModel.settingsURL) }
    ) {
        self.checker = checker
        self.pollInterval = pollInterval
        self.openSettings = openSettings
    }

    var isGranted: Bool { status == .granted }

    func handle(_ intent: FullDiskAccessIntent) {
        switch intent {
        case .refresh:
            Task { [weak self, checker] in
                let granted = await checker.isGranted()
                guard let self else { return }
                if granted {
                    status = .granted
                } else if status != .waiting {
                    status = .idle
                }
            }
        case .openSystemSettings:
            guard status != .granted else { return }
            openSettings()
            status = .waiting
            startPolling()
        case .stopWaiting:
            pollTask?.cancel()
            pollTask = nil
            if status != .granted { status = .idle }
        }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self, checker, pollInterval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: pollInterval)
                if Task.isCancelled { return }
                guard await checker.isGranted() else { continue }
                guard let self, !Task.isCancelled else { return }
                status = .granted
                pollTask = nil
                onGranted?()
                return
            }
        }
    }
}
