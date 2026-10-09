import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("ProcessRunner")
struct ProcessRunnerTests {
    let runner = ProcessRunner()

    @Test("captures stdout")
    func stdout() async throws {
        let result = try await runner.run("/bin/echo", arguments: ["hola"])
        #expect(result.stdout == "hola\n")
        #expect(result.succeeded)
    }

    @Test("resolves bare executable names")
    func bareName() async throws {
        let result = try await runner.run("echo", arguments: ["x"])
        #expect(result.stdout == "x\n")
    }

    @Test("captures stderr")
    func stderr() async throws {
        let result = try await runner.run("/bin/sh", arguments: ["-c", "echo err >&2"])
        #expect(result.stderr == "err\n")
        #expect(result.stdout.isEmpty)
    }

    @Test("returns the exit code")
    func exitCode() async throws {
        let result = try await runner.run("/bin/sh", arguments: ["-c", "exit 7"])
        #expect(result.exitCode == 7)
        #expect(!result.succeeded)
    }

    @Test("large output does not deadlock")
    func largeOutput() async throws {
        let result = try await runner.run(
            "/bin/sh", arguments: ["-c", "yes | head -n 200000; yes err | head -n 200000 >&2"],
            timeout: .seconds(20))
        #expect(result.stdout.count == 400_000)
        #expect(result.stderr.count == 200_000 * 4)
    }

    @Test("timeout terminates the process and throws timedOut")
    func timeout() async throws {
        let start = ContinuousClock.now
        await #expect(throws: ProcessRunnerError.self) {
            try await runner.run("/bin/sleep", arguments: ["5"], timeout: .milliseconds(200))
        }
        #expect(ContinuousClock.now - start < .seconds(3))
    }

    @Test("cancelling the Task terminates the process")
    func cancellation() async throws {
        let runner = self.runner
        let task = Task { try await runner.run("/bin/sleep", arguments: ["5"], timeout: .seconds(30)) }
        try await Task.sleep(for: .milliseconds(200))
        let start = ContinuousClock.now
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(ContinuousClock.now - start < .seconds(3))
    }

    @Test("missing executable")
    func notFound() async {
        await #expect(throws: ProcessRunnerError.executableNotFound("mdc-no-such-binary")) {
            try await runner.run("mdc-no-such-binary")
        }
    }
}
