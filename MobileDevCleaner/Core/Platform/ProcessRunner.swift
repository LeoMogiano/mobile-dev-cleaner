import Foundation

struct ProcessResult: Sendable, Equatable {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool { exitCode == 0 }
}

enum ProcessRunnerError: Error, Equatable, Sendable {
    case executableNotFound(String)
    case launchFailed(String)
    case timedOut(executable: String, after: Duration)
}

protocol ProcessRunning: Sendable {
    /// `executable` is an absolute path or a bare name resolved in standard bin folders.
    /// Cancelling the Task sends SIGTERM to the process.
    func run(_ executable: String, arguments: [String], timeout: Duration) async throws -> ProcessResult
}

extension ProcessRunning {
    func run(_ executable: String, arguments: [String] = []) async throws -> ProcessResult {
        try await run(executable, arguments: arguments, timeout: .seconds(30))
    }
}

struct ProcessRunner: ProcessRunning {
    private static let searchDirectories = ["/usr/bin", "/bin", "/usr/sbin", "/usr/local/bin", "/opt/homebrew/bin"]

    func run(_ executable: String, arguments: [String], timeout: Duration) async throws -> ProcessResult {
        let path = try Self.resolve(executable)
        let execution = Execution(path: path, arguments: arguments)
        let timer = Task {
            try await Task.sleep(for: timeout)
            execution.timeOut()
        }
        defer { timer.cancel() }
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    execution.start(continuation)
                }
            } onCancel: {
                execution.cancel()
            }
        } catch Execution.Failure.timedOut {
            throw ProcessRunnerError.timedOut(executable: executable, after: timeout)
        }
    }

    private static func resolve(_ executable: String) throws -> String {
        let fm = FileManager.default
        if executable.contains("/") {
            guard fm.isExecutableFile(atPath: executable) else {
                throw ProcessRunnerError.executableNotFound(executable)
            }
            return executable
        }
        for dir in searchDirectories {
            let candidate = dir + "/" + executable
            if fm.isExecutableFile(atPath: candidate) { return candidate }
        }
        throw ProcessRunnerError.executableNotFound(executable)
    }
}

// Process/Pipe are not Sendable and their callbacks arrive on arbitrary queues. All mutable
// state is guarded by one NSLock, which makes @unchecked Sendable safe. No waitUntilExit:
// termination is bridged to the continuation via terminationHandler.
private final class Execution: @unchecked Sendable {
    enum Failure: Error { case timedOut }

    private let process = Process()
    private let outPipe = Pipe()
    private let errPipe = Pipe()
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ProcessResult, Error>?
    private var outData = Data()
    private var errData = Data()
    private var terminated = false
    private var exitCode: Int32 = 0
    private var outEOF = false
    private var errEOF = false
    private var launched = false
    private var cancelled = false
    private var timedOut = false
    private var finished = false

    init(path: String, arguments: [String]) {
        process.executableURL = URL(filePath: path)
        process.arguments = arguments
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice
    }

    func start(_ continuation: CheckedContinuation<ProcessResult, Error>) {
        lock.lock()
        if cancelled {
            finished = true
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }
        self.continuation = continuation
        lock.unlock()

        outPipe.fileHandleForReading.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            consume(chunk, isOut: true)
        }
        errPipe.fileHandleForReading.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            consume(chunk, isOut: false)
        }
        process.terminationHandler = { [self] proc in
            lock.lock()
            terminated = true
            exitCode = proc.terminationStatus
            lock.unlock()
            completeIfReady()
        }
        do {
            try process.run()
            lock.lock()
            launched = true
            let shouldKill = cancelled || timedOut
            lock.unlock()
            if shouldKill { process.terminate() }
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            resume(with: .failure(ProcessRunnerError.launchFailed(error.localizedDescription)))
        }
    }

    func cancel() {
        lock.lock()
        cancelled = true
        let running = launched
        lock.unlock()
        if running { process.terminate() }
    }

    func timeOut() {
        lock.lock()
        timedOut = true
        let running = launched
        lock.unlock()
        if running { process.terminate() }
    }

    private func consume(_ chunk: Data, isOut: Bool) {
        lock.lock()
        if chunk.isEmpty {
            if isOut { outEOF = true } else { errEOF = true }
        } else if isOut {
            outData.append(chunk)
        } else {
            errData.append(chunk)
        }
        lock.unlock()
        if chunk.isEmpty {
            (isOut ? outPipe : errPipe).fileHandleForReading.readabilityHandler = nil
            completeIfReady()
        }
    }

    // On cancel/timeout EOF is not awaited: a grandchild may keep the pipe open.
    private func completeIfReady() {
        lock.lock()
        let ready = terminated && ((outEOF && errEOF) || cancelled || timedOut)
        guard ready, !finished else { lock.unlock(); return }
        let result: Result<ProcessResult, Error>
        if cancelled {
            result = .failure(CancellationError())
        } else if timedOut {
            result = .failure(Failure.timedOut)
        } else {
            result = .success(ProcessResult(
                exitCode: exitCode,
                stdout: String(decoding: outData, as: UTF8.self),
                stderr: String(decoding: errData, as: UTF8.self)))
        }
        lock.unlock()
        outPipe.fileHandleForReading.readabilityHandler = nil
        errPipe.fileHandleForReading.readabilityHandler = nil
        resume(with: result)
    }

    private func resume(with result: Result<ProcessResult, Error>) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}
