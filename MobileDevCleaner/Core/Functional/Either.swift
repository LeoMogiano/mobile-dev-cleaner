import Foundation

/// Two-way result: `left` holds the error, `right` the success value.
/// Used instead of `throws` so domain errors are explicit in the signature.
enum Either<L, R> {
    case left(L)
    case right(R)

    var isRight: Bool {
        if case .right = self { return true }
        return false
    }

    var isLeft: Bool { !isRight }

    func fold<T>(_ onLeft: (L) -> T, _ onRight: (R) -> T) -> T {
        switch self {
        case .left(let value): return onLeft(value)
        case .right(let value): return onRight(value)
        }
    }

    func map<T>(_ transform: (R) -> T) -> Either<L, T> {
        switch self {
        case .left(let value): return .left(value)
        case .right(let value): return .right(transform(value))
        }
    }

    func mapLeft<T>(_ transform: (L) -> T) -> Either<T, R> {
        switch self {
        case .left(let value): return .left(transform(value))
        case .right(let value): return .right(value)
        }
    }

    func flatMap<T>(_ transform: (R) -> Either<L, T>) -> Either<L, T> {
        switch self {
        case .left(let value): return .left(value)
        case .right(let value): return transform(value)
        }
    }

    var rightValue: R? {
        if case .right(let value) = self { return value }
        return nil
    }

    var leftValue: L? {
        if case .left(let value) = self { return value }
        return nil
    }
}

extension Either: Equatable where L: Equatable, R: Equatable {}
extension Either: Sendable where L: Sendable, R: Sendable {}

extension Either where L == Failure {
    /// Runs a throwing block and converts its outcome into `Either<Failure, R>`.
    static func catching(domain: String? = nil, _ body: () async throws -> R) async -> Either<Failure, R> {
        do {
            return .right(try await body())
        } catch {
            return .left(Failure.map(error, domain: domain))
        }
    }
}
