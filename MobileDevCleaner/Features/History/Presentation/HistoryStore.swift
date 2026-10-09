import Foundation

enum HistoryIntent: Sendable {
    case load
}

/// App-wide cleanup history shared by the history screen, dashboard footer and cleanup flow.
@MainActor @Observable
final class HistoryStore {
    private(set) var entries: [HistoryEntry] = []

    @ObservationIgnored private let loadHistory: LoadHistoryUseCase
    @ObservationIgnored private let recordCleanup: RecordCleanupUseCase

    init(load: LoadHistoryUseCase, record: RecordCleanupUseCase) {
        self.loadHistory = load
        self.recordCleanup = record
    }

    var totalFreed: Int64 { entries.reduce(0) { $0 + $1.freedBytes } }

    func handle(_ intent: HistoryIntent) {
        switch intent {
        case .load:
            Task {
                let result = await loadHistory()
                result.fold(
                    { _ in self.entries = [] },
                    { self.entries = $0 }
                )
            }
        }
    }

    func record(_ outcome: CleanupOutcome) async {
        guard let result = await recordCleanup(outcome) else { return }
        result.fold(
            { _ in },
            { self.entries = $0 }
        )
    }
}
