import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Failure")
struct FailureTests {
    @Test("permissionDenied factory creates correct type and code")
    func permissionDeniedFactory() {
        let failure = Failure.permissionDenied(domain: "test.domain")
        #expect(failure.type == .permissionDenied)
        #expect(failure.code == "permission_denied")
        #expect(failure.domain == "test.domain")
        #expect(failure.message.contains("Permiso denegado"))
    }

    @Test("notFound factory creates correct type and code")
    func notFoundFactory() {
        let failure = Failure.notFound(domain: "test.domain")
        #expect(failure.type == .notFound)
        #expect(failure.code == "not_found")
        #expect(failure.domain == "test.domain")
        #expect(failure.message.contains("carpeta cambió"))
    }

    @Test("fileInUse factory without process name")
    func fileInUseFactoryWithoutProcess() {
        let failure = Failure.fileInUse(domain: "test.domain")
        #expect(failure.type == .fileInUse)
        #expect(failure.code == "file_in_use")
        #expect(failure.message.contains("otro proceso"))
        #expect(!failure.message.contains("("))
    }

    @Test("fileInUse factory with process name")
    func fileInUseFactoryWithProcess() {
        let failure = Failure.fileInUse(processName: "Xcode", domain: "test.domain")
        #expect(failure.type == .fileInUse)
        #expect(failure.code == "file_in_use")
        #expect(failure.message.contains("Xcode"))
    }

    @Test("toolMissing factory creates correct type and code")
    func toolMissingFactory() {
        let failure = Failure.toolMissing("git", domain: "test.domain")
        #expect(failure.type == .toolMissing)
        #expect(failure.code == "tool_missing")
        #expect(failure.message.contains("git"))
        #expect(failure.domain == "test.domain")
    }

    @Test("timeout factory creates correct type and code")
    func timeoutFactory() {
        let failure = Failure.timeout(domain: "test.domain")
        #expect(failure.type == .timeout)
        #expect(failure.code == "timeout")
        #expect(failure.message.contains("tardó demasiado"))
        #expect(failure.domain == "test.domain")
    }

    @Test("cancelled factory creates correct type and code")
    func cancelledFactory() {
        let failure = Failure.cancelled(domain: "test.domain")
        #expect(failure.type == .cancelled)
        #expect(failure.code == "cancelled")
        #expect(failure.message.contains("canceló"))
        #expect(failure.domain == "test.domain")
    }

    @Test("processFailed factory creates correct type and code")
    func processFailedFactory() {
        let failure = Failure.processFailed(exitCode: 127, stderr: "not found", domain: "test.domain")
        #expect(failure.type == .processFailed)
        #expect(failure.code == "process_failed")
        #expect(failure.message.contains("127"))
        #expect(failure.domain == "test.domain")
    }

    @Test("decoding factory creates correct type and code")
    func decodingFactory() {
        let failure = Failure.decoding(domain: "test.domain")
        #expect(failure.type == .decoding)
        #expect(failure.code == "decoding")
        #expect(failure.message.contains("leer los datos"))
        #expect(failure.domain == "test.domain")
    }

    @Test("io factory creates correct type and code")
    func ioFactory() {
        let failure = Failure.io(domain: "test.domain")
        #expect(failure.type == .io)
        #expect(failure.code == "io")
        #expect(failure.message.contains("leer o escribir"))
        #expect(failure.domain == "test.domain")
    }

    @Test("unknown factory creates correct type and code")
    func unknownFactory() {
        let failure = Failure.unknown(domain: "test.domain")
        #expect(failure.type == .unknown)
        #expect(failure.code == "unknown_error")
        #expect(failure.domain == "test.domain")
    }

    @Test("map passes through Failure unchanged")
    func mapPassthrough() {
        let original = Failure.permissionDenied(domain: "original.domain")
        let mapped = Failure.map(original, domain: "new.domain")
        #expect(mapped == original)
    }

    @Test("map converts CancellationError to cancelled")
    func mapCancellationError() {
        let error = CancellationError()
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .cancelled)
        #expect(failure.code == "cancelled")
    }

    @Test("map converts ProcessRunnerError executableNotFound to toolMissing")
    func mapProcessRunnerExecutableNotFound() {
        let error = ProcessRunnerError.executableNotFound("xcodebuild")
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .toolMissing)
        #expect(failure.code == "tool_missing")
        #expect(failure.message.contains("xcodebuild"))
    }

    @Test("map converts ProcessRunnerError launchFailed to io")
    func mapProcessRunnerLaunchFailed() {
        let error = ProcessRunnerError.launchFailed("Launch error")
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .io)
        #expect(failure.code == "io")
    }

    @Test("map converts ProcessRunnerError timedOut to timeout")
    func mapProcessRunnerTimedOut() {
        let error = ProcessRunnerError.timedOut(executable: "xcodebuild", after: .seconds(30))
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .timeout)
        #expect(failure.code == "timeout")
    }

    @Test("map converts POSIXError EACCES to permissionDenied")
    func mapPOSIXErrorEACCES() {
        let error = POSIXError(.EACCES)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .permissionDenied)
        #expect(failure.code == "permission_denied")
    }

    @Test("map converts POSIXError EPERM to permissionDenied")
    func mapPOSIXErrorEPERM() {
        let error = POSIXError(.EPERM)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .permissionDenied)
    }

    @Test("map converts POSIXError ENOENT to notFound")
    func mapPOSIXErrorENOENT() {
        let error = POSIXError(.ENOENT)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .notFound)
        #expect(failure.code == "not_found")
    }

    @Test("map converts POSIXError EBUSY to fileInUse")
    func mapPOSIXErrorEBUSY() {
        let error = POSIXError(.EBUSY)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .fileInUse)
        #expect(failure.code == "file_in_use")
    }

    @Test("map converts POSIXError ETXTBSY to fileInUse")
    func mapPOSIXErrorETXTBSY() {
        let error = POSIXError(.ETXTBSY)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .fileInUse)
    }

    @Test("map converts CocoaError fileReadNoPermission to permissionDenied")
    func mapCocoaErrorFileReadNoPermission() {
        let error = CocoaError(.fileReadNoPermission)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .permissionDenied)
        #expect(failure.code == "permission_denied")
    }

    @Test("map converts CocoaError fileWriteNoPermission to permissionDenied")
    func mapCocoaErrorFileWriteNoPermission() {
        let error = CocoaError(.fileWriteNoPermission)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .permissionDenied)
    }

    @Test("map converts CocoaError fileWriteVolumeReadOnly to permissionDenied")
    func mapCocoaErrorFileWriteVolumeReadOnly() {
        let error = CocoaError(.fileWriteVolumeReadOnly)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .permissionDenied)
    }

    @Test("map converts CocoaError fileNoSuchFile to notFound")
    func mapCocoaErrorFileNoSuchFile() {
        let error = CocoaError(.fileNoSuchFile)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .notFound)
        #expect(failure.code == "not_found")
    }

    @Test("map converts CocoaError fileReadNoSuchFile to notFound")
    func mapCocoaErrorFileReadNoSuchFile() {
        let error = CocoaError(.fileReadNoSuchFile)
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .notFound)
    }

    @Test("map converts DecodingError to decoding")
    func mapDecodingError() {
        struct TestCodable: Decodable {}
        let error: DecodingError = .dataCorrupted(DecodingError.Context(
            codingPath: [], debugDescription: "Test"
        ))
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .decoding)
        #expect(failure.code == "decoding")
    }

    @Test("map converts unknown error type to unknown")
    func mapUnknownError() {
        struct CustomError: Error {}
        let error = CustomError()
        let failure = Failure.map(error, domain: "test.domain")
        #expect(failure.type == .unknown)
        #expect(failure.code == "unknown_error")
        #expect(failure.domain == "test.domain")
    }

    @Test("map preserves domain parameter")
    func mapPreservesDomain() {
        let error = CancellationError()
        let failure = Failure.map(error, domain: "custom.domain")
        #expect(failure.domain == "custom.domain")
    }
}
