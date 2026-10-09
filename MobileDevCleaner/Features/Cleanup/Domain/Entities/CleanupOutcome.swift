import Foundation

struct CleanupFailureItem: Identifiable, Sendable, Equatable {
    let operation: CleanupOperation
    /// Localized reason, e.g. "Permiso denegado: macOS protege este archivo."
    let reason: String

    var id: String { operation.id }
}

struct CleanupOutcome: Sendable, Equatable {
    let done: [CleanupOperation]
    let failures: [CleanupFailureItem]
    let wasCancelled: Bool
    let movedToTrash: Bool

    var freedBytes: Int64 { done.reduce(0) { $0 + $1.size } }
}

enum CleanupEvent: Sendable, Equatable {
    /// Emitted before running the operation at `index`.
    case started(index: Int)
    case finished(index: Int, failure: Failure?)
    case completed(CleanupOutcome)
}

/// A developer app that must be closed before cleaning.
struct BlockingApp: Identifiable, Sendable, Equatable {
    let app: DevApp
    /// Running AVD names for the emulator; empty otherwise.
    let details: [String]

    var id: DevApp { app }
}
