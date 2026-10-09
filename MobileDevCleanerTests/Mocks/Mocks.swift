import Foundation
import Testing
@testable import MobileDevCleaner

// MARK: - Test Helpers

@MainActor
func waitUntil(timeout: Duration = .seconds(2), _ condition: @MainActor () async -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if await condition() { return }
        try? await Task.sleep(for: .milliseconds(5))
    }
    Issue.record("waitUntil timed out", sourceLocation: sourceLocation)
}

// MARK: - MockProcessRunner

actor MockProcessRunner: ProcessRunning {
    private let handler: @Sendable (String, [String]) throws -> ProcessResult
    private(set) var calls: [(executable: String, arguments: [String])] = []

    init(handler: @escaping @Sendable (String, [String]) throws -> ProcessResult = { _, _ in
        ProcessResult(exitCode: 0, stdout: "", stderr: "")
    }) {
        self.handler = handler
    }

    func run(_ executable: String, arguments: [String], timeout: Duration) async throws -> ProcessResult {
        calls.append((executable, arguments))
        return try handler(executable, arguments)
    }
}
