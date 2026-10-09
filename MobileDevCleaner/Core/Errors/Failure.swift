import Foundation

enum FailureType: String, Sendable, Equatable {
    case permissionDenied
    case notFound
    case fileInUse
    case toolMissing
    case timeout
    case cancelled
    case processFailed
    case decoding
    case io
    case unknown
}

/// Every Data/Domain error is converted to `Failure` before reaching Presentation;
/// `message` is already localized for the UI.
struct Failure: Error, Equatable, Sendable {
    let code: String
    let message: String
    let type: FailureType
    let domain: String?

    init(code: String, message: String, type: FailureType, domain: String? = nil) {
        self.code = code
        self.message = message
        self.type = type
        self.domain = domain
    }

    static func permissionDenied(path: String? = nil, domain: String? = nil) -> Failure {
        Failure(code: "permission_denied", message: L10n.string("Permiso denegado: macOS protege este archivo."), type: .permissionDenied, domain: domain)
    }

    static func notFound(domain: String? = nil) -> Failure {
        Failure(code: "not_found", message: L10n.string("La carpeta cambió durante la limpieza."), type: .notFound, domain: domain)
    }

    static func fileInUse(processName: String? = nil, domain: String? = nil) -> Failure {
        let message: String
        if let name = processName {
            message = L10n.string("Lo está usando otro proceso (\(name)).")
        } else {
            message = L10n.string("Lo está usando otro proceso.")
        }
        return Failure(code: "file_in_use", message: message, type: .fileInUse, domain: domain)
    }

    static func toolMissing(_ tool: String, domain: String? = nil) -> Failure {
        Failure(code: "tool_missing", message: L10n.string("No encontramos \(tool) en tu Mac."), type: .toolMissing, domain: domain)
    }

    static func timeout(domain: String? = nil) -> Failure {
        Failure(code: "timeout", message: L10n.string("La operación tardó demasiado."), type: .timeout, domain: domain)
    }

    static func cancelled(domain: String? = nil) -> Failure {
        Failure(code: "cancelled", message: L10n.string("Se canceló la operación."), type: .cancelled, domain: domain)
    }

    static func processFailed(exitCode: Int32, stderr: String, domain: String? = nil) -> Failure {
        Failure(code: "process_failed", message: L10n.string("El comando falló (código \(exitCode))."), type: .processFailed, domain: domain)
    }

    static func decoding(domain: String? = nil) -> Failure {
        Failure(code: "decoding", message: L10n.string("No pudimos leer los datos."), type: .decoding, domain: domain)
    }

    static func io(domain: String? = nil) -> Failure {
        Failure(code: "io", message: L10n.string("No pudimos leer o escribir en el disco."), type: .io, domain: domain)
    }

    static func unknown(_ message: String? = nil, domain: String? = nil) -> Failure {
        Failure(code: "unknown_error", message: message ?? L10n.string("Ocurrió un error inesperado."), type: .unknown, domain: domain)
    }

    static func map(_ error: any Error, domain: String? = nil) -> Failure {
        if let failure = error as? Failure {
            return failure
        }

        if error is CancellationError {
            return .cancelled(domain: domain)
        }

        if let processError = error as? ProcessRunnerError {
            switch processError {
            case .executableNotFound(let tool):
                return .toolMissing(tool, domain: domain)
            case .launchFailed:
                return .io(domain: domain)
            case .timedOut:
                return .timeout(domain: domain)
            }
        }

        if let posixError = error as? POSIXError {
            switch posixError.code {
            case .EACCES, .EPERM:
                return .permissionDenied(domain: domain)
            case .ENOENT:
                return .notFound(domain: domain)
            case .EBUSY, .ETXTBSY:
                return .fileInUse(domain: domain)
            default:
                return .io(domain: domain)
            }
        }

        if let cocoaError = error as? CocoaError {
            switch cocoaError.code {
            case .fileReadNoPermission, .fileWriteNoPermission, .fileWriteVolumeReadOnly:
                return .permissionDenied(domain: domain)
            case .fileNoSuchFile, .fileReadNoSuchFile:
                return .notFound(domain: domain)
            default:
                if let underlyingError = cocoaError.userInfo[NSUnderlyingErrorKey] as? NSError,
                   underlyingError.domain == NSPOSIXErrorDomain {
                    return .map(underlyingError, domain: domain)
                }
                return .io(domain: domain)
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSPOSIXErrorDomain {
            let code = POSIXError.Code(rawValue: Int32(nsError.code))
            if let code = code {
                switch code {
                case .EACCES, .EPERM:
                    return .permissionDenied(domain: domain)
                case .ENOENT:
                    return .notFound(domain: domain)
                case .EBUSY, .ETXTBSY:
                    return .fileInUse(domain: domain)
                default:
                    return .io(domain: domain)
                }
            }
            return .io(domain: domain)
        }

        if error is DecodingError {
            return .decoding(domain: domain)
        }

        return .unknown(domain: domain)
    }
}
