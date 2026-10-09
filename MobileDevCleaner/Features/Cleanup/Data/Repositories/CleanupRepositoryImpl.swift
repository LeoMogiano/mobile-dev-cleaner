import Foundation

actor CleanupRepositoryImpl: CleanupRepository {
    private let guardrail: PathGuard
    private let trash: any TrashServicing
    private let runner: any ProcessRunning
    private let probe: any ProcessProbing
    private let sizes: any SizeCalculating

    init(
        guardrail: PathGuard, trash: any TrashServicing, runner: any ProcessRunning,
        probe: any ProcessProbing, sizes: any SizeCalculating
    ) {
        self.guardrail = guardrail
        self.trash = trash
        self.runner = runner
        self.probe = probe
        self.sizes = sizes
    }

    nonisolated func execute(
        _ operations: [CleanupOperation], movesToTrash: Bool, token: CancellationToken
    ) -> AsyncStream<CleanupEvent> {
        AsyncStream { continuation in
            Task.detached(priority: .userInitiated) {
                await self.run(operations, movesToTrash: movesToTrash, token: token, continuation: continuation)
            }
            // The running operation always finishes: only the token stops the loop.
            continuation.onTermination = { _ in
                token.cancel()
            }
        }
    }

    func blockingApps(for tools: Set<Tool>) async -> [BlockingApp] {
        let running = await probe.runningApps()
        let relevant: Set<DevApp> = tools.reduce(into: []) { result, tool in
            switch tool {
            case .xcode: result.formUnion([.xcode, .simulator])
            case .android: result.formUnion([.androidStudio, .androidEmulator])
            }
        }
        return DevApp.allCases.compactMap { app in
            guard relevant.contains(app), running.apps.contains(app) else { return nil }
            return BlockingApp(app: app, details: app == .androidEmulator ? running.runningAVDs.sorted() : [])
        }
    }

    // MARK: - Execution

    private func run(
        _ operations: [CleanupOperation], movesToTrash: Bool, token: CancellationToken,
        continuation: AsyncStream<CleanupEvent>.Continuation
    ) async {
        var done: [CleanupOperation] = []
        var failures: [CleanupFailureItem] = []
        var wasCancelled = false

        for (index, operation) in operations.enumerated() {
            if token.isCancelled {
                wasCancelled = true
                break
            }
            continuation.yield(.started(index: index))
            let signpost = Signposts.cleanup.makeSignpostID()
            let interval = Signposts.cleanup.beginInterval("operation", id: signpost)
            let failure = await perform(operation, movesToTrash: movesToTrash)
            Signposts.cleanup.endInterval("operation", interval)

            if let failure {
                failures.append(CleanupFailureItem(operation: operation, reason: failure.message))
            } else {
                done.append(operation)
                await sizes.invalidate([operation.url])
            }
            continuation.yield(.finished(index: index, failure: failure))
        }

        await sizes.flush()
        let touchedFiles = movesToTrash && done.contains { op in
            op.steps.contains { if case .remove = $0 { true } else { false } }
        }
        continuation.yield(.completed(CleanupOutcome(
            done: done, failures: failures, wasCancelled: wasCancelled, movedToTrash: touchedFiles)))
        continuation.finish()
    }

    private func perform(_ operation: CleanupOperation, movesToTrash: Bool) async -> Failure? {
        for step in operation.steps {
            if let failure = await perform(step, movesToTrash: movesToTrash) { return failure }
        }
        return nil
    }

    private func perform(_ step: ExecutionStrategy, movesToTrash: Bool) async -> Failure? {
        switch step {
        case .remove(let url):
            guard guardrail.isRemovable(url) else {
                return Self.blocked(L10n.string("Está fuera de las carpetas que limpiamos."))
            }
            do {
                if movesToTrash {
                    _ = try await trash.moveToTrash(url)
                } else {
                    try await trash.remove(url)
                }
                return nil
            } catch {
                return Failure.map(error)
            }
        case .command(let executable, let arguments):
            guard guardrail.isAllowedCommand(executable: executable, arguments: arguments) else {
                return Self.blocked(L10n.string("Comando no permitido."))
            }
            do {
                let result = try await runner.run(executable, arguments: arguments, timeout: .seconds(120))
                return result.succeeded ? nil : Failure.processFailed(exitCode: result.exitCode, stderr: result.stderr)
            } catch {
                return Failure.map(error)
            }
        }
    }

    private static func blocked(_ message: String) -> Failure {
        Failure(code: "blocked_path", message: message, type: .permissionDenied)
    }
}
