import Foundation
import Testing
@testable import MobileDevCleaner

private actor MockTrashService: TrashServicing {
    private(set) var trashed: [URL] = []
    private(set) var removed: [URL] = []
    var onCall: (@Sendable () -> Void)?
    var error: (any Error)?

    func setOnCall(_ handler: @escaping @Sendable () -> Void) { onCall = handler }
    func setError(_ error: any Error) { self.error = error }

    func moveToTrash(_ url: URL) async throws -> URL? {
        onCall?()
        if let error { throw error }
        trashed.append(url)
        return nil
    }

    func remove(_ url: URL) async throws {
        onCall?()
        if let error { throw error }
        removed.append(url)
    }
}

private actor MockSizes: SizeCalculating {
    private(set) var invalidated: [URL] = []
    private(set) var flushCount = 0

    func size(of url: URL) async throws -> Int64 { 0 }
    func sizes(of urls: [URL]) async -> [URL: Int64] { [:] }
    func invalidate(_ urls: [URL]) async { invalidated += urls }
    func clearCache() async {}
    func cacheFootprint() async -> Int64 { 0 }
    func flush() async { flushCount += 1 }
    func syncWithFileChanges() async {}
}

@Suite("CleanupRepositoryImpl")
struct CleanupRepositoryImplTests {
    private struct Fixture {
        let temp: TempDirectory
        let paths: PathProvider
        let trash: MockTrashService
        let runner: MockProcessRunner
        let sizes: MockSizes
        let repo: CleanupRepositoryImpl

        init(
            runner: MockProcessRunner = MockProcessRunner(), probe: MockProcessProbe = MockProcessProbe(),
            trash: MockTrashService = MockTrashService()
        ) throws {
            temp = try TempDirectory()
            paths = temp.paths
            self.trash = trash
            self.runner = runner
            sizes = MockSizes()
            repo = CleanupRepositoryImpl(
                guardrail: PathGuard(paths: paths), trash: trash, runner: runner, probe: probe, sizes: sizes)
        }
    }

    private func operation(
        _ id: String, url: URL, size: Int64 = 100, steps: [ExecutionStrategy]? = nil
    ) -> CleanupOperation {
        CleanupOperation(
            id: id, category: .builds, name: id, size: size, risk: .regenerates, note: nil,
            source: .candidate, steps: steps ?? [.remove(url)], url: url)
    }

    private func collect(_ stream: AsyncStream<CleanupEvent>) async -> [CleanupEvent] {
        var events: [CleanupEvent] = []
        for await event in stream { events.append(event) }
        return events
    }

    private func outcome(_ events: [CleanupEvent]) -> CleanupOutcome? {
        if case .completed(let outcome) = events.last { return outcome }
        return nil
    }

    @Test("emits events in order and completes last")
    func eventOrder() async throws {
        let f = try Fixture()
        let a = operation("a", url: f.paths.derivedData.appending(path: "A"))
        let b = operation("b", url: f.paths.derivedData.appending(path: "B"))
        let events = await collect(f.repo.execute([a, b], movesToTrash: true, token: CancellationToken()))
        #expect(events.count == 5)
        #expect(events[0] == .started(index: 0))
        #expect(events[1] == .finished(index: 0, failure: nil))
        #expect(events[2] == .started(index: 1))
        #expect(events[3] == .finished(index: 1, failure: nil))
        let result = try #require(outcome(events))
        #expect(result.done == [a, b])
        #expect(result.failures.isEmpty)
        #expect(!result.wasCancelled)
        #expect(result.movedToTrash)
        #expect(result.freedBytes == 200)
    }

    @Test("moves to trash when enabled, removes permanently otherwise")
    func trashVersusRemove() async throws {
        let f = try Fixture()
        let url = f.paths.caches.appending(path: "X")
        let op = operation("x", url: url)
        let trashed = outcome(await collect(f.repo.execute([op], movesToTrash: true, token: CancellationToken())))
        #expect(await f.trash.trashed == [url])
        #expect(await f.trash.removed.isEmpty)
        #expect(trashed?.movedToTrash == true)

        let removed = outcome(await collect(f.repo.execute([op], movesToTrash: false, token: CancellationToken())))
        #expect(await f.trash.removed == [url])
        #expect(removed?.movedToTrash == false)
    }

    @Test("blocked path is never touched and reported as failure")
    func blockedPath() async throws {
        let f = try Fixture()
        let url = f.paths.home.appending(path: "Documents/important")
        let events = await collect(f.repo.execute([operation("d", url: url)], movesToTrash: false, token: CancellationToken()))
        let result = try #require(outcome(events))
        #expect(result.done.isEmpty)
        #expect(result.failures.count == 1)
        #expect(result.failures.first?.reason == "Está fuera de las carpetas que limpiamos.")
        #expect(await f.trash.removed.isEmpty)
        #expect(await f.trash.trashed.isEmpty)
        if case .finished(_, let failure) = events[1] {
            #expect(failure?.code == "blocked_path")
            #expect(failure?.type == .permissionDenied)
        } else {
            Issue.record("expected finished event")
        }
    }

    @Test("allowed command runs through the runner")
    func allowedCommand() async throws {
        let f = try Fixture()
        let step = ExecutionStrategy.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "erase", "UDID"])
        let op = operation("sim", url: f.paths.coreSimulatorDevices.appending(path: "UDID"), steps: [step])
        let result = outcome(await collect(f.repo.execute([op], movesToTrash: true, token: CancellationToken())))
        #expect(result?.done == [op])
        #expect(result?.movedToTrash == false)
        let calls = await f.runner.calls
        #expect(calls.count == 1)
        #expect(calls.first?.executable == "/usr/bin/xcrun")
        #expect(calls.first?.arguments == ["simctl", "erase", "UDID"])
    }

    @Test("command not in the allowlist is never executed")
    func forbiddenCommand() async throws {
        let f = try Fixture()
        let step = ExecutionStrategy.command(executable: "/bin/rm", arguments: ["-rf", "/"])
        let op = operation("bad", url: f.paths.caches.appending(path: "X"), steps: [step])
        let result = outcome(await collect(f.repo.execute([op], movesToTrash: true, token: CancellationToken())))
        #expect(result?.failures.first?.reason == "Comando no permitido.")
        #expect(await f.runner.calls.isEmpty)
    }

    @Test("non-zero exit code fails the operation and stops its remaining steps")
    func nonZeroExit() async throws {
        let runner = MockProcessRunner { _, _ in ProcessResult(exitCode: 3, stdout: "", stderr: "boom") }
        let f = try Fixture(runner: runner)
        let url = f.paths.caches.appending(path: "after")
        let steps: [ExecutionStrategy] = [
            .command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", "UDID"]), .remove(url),
        ]
        let op = operation("sim", url: f.paths.caches.appending(path: "sim"), steps: steps)
        let events = await collect(f.repo.execute([op], movesToTrash: false, token: CancellationToken()))
        let result = try #require(outcome(events))
        #expect(result.done.isEmpty)
        #expect(result.failures.first?.reason == Failure.processFailed(exitCode: 3, stderr: "").message)
        #expect(await f.trash.removed.isEmpty)
        #expect(await f.sizes.invalidated.isEmpty)
    }

    @Test("trash errors are mapped to localized failures and later operations still run")
    func mappedErrors() async throws {
        let f = try Fixture()
        await f.trash.setError(CocoaError(.fileWriteNoPermission))
        let op = operation("x", url: f.paths.caches.appending(path: "X"))
        let result = outcome(await collect(f.repo.execute([op], movesToTrash: true, token: CancellationToken())))
        #expect(result?.failures.first?.reason == Failure.permissionDenied().message)
    }

    @Test("cancelling after the first operation stops the rest and completes last")
    func cancellation() async throws {
        let trash = MockTrashService()
        let f = try Fixture(trash: trash)
        let token = CancellationToken()
        await trash.setOnCall { token.cancel() }
        let ops = ["a", "b", "c"].map { operation($0, url: f.paths.caches.appending(path: $0)) }
        let events = await collect(f.repo.execute(ops, movesToTrash: true, token: token))
        let result = try #require(outcome(events))
        #expect(result.done == [ops[0]])
        #expect(result.wasCancelled)
        #expect(await trash.trashed.count == 1)
        let startedCount = events.filter { if case .started = $0 { true } else { false } }.count
        #expect(startedCount == 1)
    }

    @Test("pre-cancelled token runs nothing")
    func preCancelled() async throws {
        let f = try Fixture()
        let token = CancellationToken()
        token.cancel()
        let events = await collect(f.repo.execute([operation("a", url: f.paths.caches.appending(path: "a"))], movesToTrash: true, token: token))
        #expect(events.count == 1)
        #expect(outcome(events)?.wasCancelled == true)
    }

    @Test("invalidates sizes of successful operations and flushes")
    func sizeInvalidation() async throws {
        let f = try Fixture()
        let ok = operation("ok", url: f.paths.caches.appending(path: "ok"))
        let bad = operation("bad", url: f.paths.home.appending(path: "Documents/bad"))
        _ = await collect(f.repo.execute([ok, bad], movesToTrash: true, token: CancellationToken()))
        #expect(await f.sizes.invalidated == [ok.url])
        #expect(await f.sizes.flushCount == 1)
    }

    @Test("really deletes inside the temp home with the real TrashService")
    func realRemoval() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let file = try temp.file("Library/Developer/Xcode/DerivedData/App/Build/out.o", bytes: 64)
        let target = temp.paths.derivedData.appending(path: "App")
        let sibling = try temp.file("Library/Developer/Xcode/DerivedData/Other/keep.txt", bytes: 8)
        let repo = CleanupRepositoryImpl(
            guardrail: PathGuard(paths: temp.paths), trash: TrashService(), runner: MockProcessRunner(),
            probe: MockProcessProbe(), sizes: MockSizes())
        let result = outcome(await collect(repo.execute(
            [operation("app", url: target)], movesToTrash: false, token: CancellationToken())))
        #expect(result?.done.count == 1)
        #expect(!FileManager.default.fileExists(atPath: file.path))
        #expect(!FileManager.default.fileExists(atPath: target.path))
        #expect(FileManager.default.fileExists(atPath: sibling.path))
    }

    @Test("real removal of a missing path succeeds")
    func realMissing() async throws {
        let temp = try TempDirectory()
        defer { temp.remove() }
        let repo = CleanupRepositoryImpl(
            guardrail: PathGuard(paths: temp.paths), trash: TrashService(), runner: MockProcessRunner(),
            probe: MockProcessProbe(), sizes: MockSizes())
        let op = operation("gone", url: temp.paths.caches.appending(path: "gone"))
        let result = outcome(await collect(repo.execute([op], movesToTrash: false, token: CancellationToken())))
        #expect(result?.failures.isEmpty == true)
    }

    @Test("blocking apps follow the tools and DevApp order")
    func blockingApps() async throws {
        let running = RunningApps(apps: [.androidEmulator, .xcode, .simulator, .androidStudio], runningAVDs: ["b", "a"])
        let f = try Fixture(probe: MockProcessProbe(result: running))
        let xcode = await f.repo.blockingApps(for: [.xcode])
        #expect(xcode.map(\.app) == [.xcode, .simulator])
        let android = await f.repo.blockingApps(for: [.android])
        #expect(android.map(\.app) == [.androidStudio, .androidEmulator])
        #expect(android.last?.details == ["a", "b"])
        #expect(await f.repo.blockingApps(for: [.xcode, .android]).count == 4)
    }

    @Test("no blocking apps when nothing relevant runs")
    func noBlocking() async throws {
        let f = try Fixture(probe: MockProcessProbe(result: RunningApps(apps: [.androidStudio])))
        #expect(await f.repo.blockingApps(for: [.xcode]).isEmpty)
    }

    @Test("command timeout is reported as failure")
    func commandTimeout() async throws {
        let runner = MockProcessRunner { _, _ in
            throw ProcessRunnerError.timedOut(executable: "xcrun", after: .seconds(120))
        }
        let f = try Fixture(runner: runner)
        let step = ExecutionStrategy.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "delete", "UDID"])
        let op = operation("sim", url: f.paths.coreSimulatorDevices.appending(path: "UDID"), steps: [step])
        let events = await collect(f.repo.execute([op], movesToTrash: false, token: CancellationToken()))
        let result = try #require(outcome(events))
        #expect(result.done.isEmpty)
        #expect(result.failures.count == 1)
        #expect(result.failures.first?.reason.contains("tardó") == true || result.failures.first?.reason.contains("tiempo") == true)
    }

    @Test("process execution error is mapped to failure")
    func processFailed() async throws {
        let runner = MockProcessRunner { _, _ in
            throw ProcessRunnerError.executableNotFound("xcrun")
        }
        let f = try Fixture(runner: runner)
        let step = ExecutionStrategy.command(executable: "/usr/bin/xcrun", arguments: ["simctl", "erase", "UDID"])
        let op = operation("sim", url: f.paths.coreSimulatorDevices.appending(path: "UDID"), steps: [step])
        let events = await collect(f.repo.execute([op], movesToTrash: false, token: CancellationToken()))
        let result = try #require(outcome(events))
        #expect(result.done.isEmpty)
        #expect(result.failures.count == 1)
    }
}
