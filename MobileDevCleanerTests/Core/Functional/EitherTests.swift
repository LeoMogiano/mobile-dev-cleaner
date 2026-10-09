import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Either")
struct EitherTests {
    @Test("fold with right value")
    func foldWithRight() {
        let either: Either<String, Int> = .right(42)
        let result = either.fold({ _ in 0 }, { $0 * 2 })
        #expect(result == 84)
    }

    @Test("fold with left value")
    func foldWithLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.fold({ $0.count }, { _ in 0 })
        #expect(result == 5)
    }

    @Test("map transforms right value")
    func mapTransformsRight() {
        let either: Either<String, Int> = .right(5)
        let result = either.map { $0 * 2 }
        #expect(result == .right(10))
    }

    @Test("map preserves left value")
    func mapPreservesLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.map { $0 * 2 }
        #expect(result == .left("error"))
    }

    @Test("mapLeft transforms left value")
    func mapLeftTransformsLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.mapLeft { $0.uppercased() }
        #expect(result == .left("ERROR"))
    }

    @Test("mapLeft preserves right value")
    func mapLeftPreservesRight() {
        let either: Either<String, Int> = .right(42)
        let result = either.mapLeft { $0.uppercased() }
        #expect(result == .right(42))
    }

    @Test("flatMap with right value")
    func flatMapWithRight() {
        let either: Either<String, Int> = .right(5)
        let result = either.flatMap { value in
            .right(value * 2)
        }
        #expect(result == .right(10))
    }

    @Test("flatMap with left value")
    func flatMapWithLeft() {
        let either: Either<String, Int> = .left("error")
        let result = either.flatMap { _ in
            .right(100)
        }
        #expect(result == .left("error"))
    }

    @Test("flatMap returns left from transform")
    func flatMapReturnsLeftFromTransform() {
        let either: Either<String, Int> = .right(5)
        let result = either.flatMap { _ in
            Either<String, Int>.left("transformed error")
        }
        #expect(result == .left("transformed error"))
    }

    @Test("rightValue returns value for right")
    func rightValueWithRight() {
        let either: Either<String, Int> = .right(42)
        #expect(either.rightValue == 42)
    }

    @Test("rightValue returns nil for left")
    func rightValueWithLeft() {
        let either: Either<String, Int> = .left("error")
        #expect(either.rightValue == nil)
    }

    @Test("leftValue returns value for left")
    func leftValueWithLeft() {
        let either: Either<String, Int> = .left("error")
        #expect(either.leftValue == "error")
    }

    @Test("leftValue returns nil for right")
    func leftValueWithRight() {
        let either: Either<String, Int> = .right(42)
        #expect(either.leftValue == nil)
    }

    @Test("isRight returns true for right")
    func isRightWithRight() {
        let either: Either<String, Int> = .right(42)
        #expect(either.isRight == true)
    }

    @Test("isRight returns false for left")
    func isRightWithLeft() {
        let either: Either<String, Int> = .left("error")
        #expect(either.isRight == false)
    }

    @Test("isLeft returns true for left")
    func isLeftWithLeft() {
        let either: Either<String, Int> = .left("error")
        #expect(either.isLeft == true)
    }

    @Test("isLeft returns false for right")
    func isLeftWithRight() {
        let either: Either<String, Int> = .right(42)
        #expect(either.isLeft == false)
    }

    @Test("Equatable works for equal rights")
    func equatableEqualRights() {
        let either1: Either<String, Int> = .right(42)
        let either2: Either<String, Int> = .right(42)
        #expect(either1 == either2)
    }

    @Test("Equatable works for different rights")
    func equatableDifferentRights() {
        let either1: Either<String, Int> = .right(42)
        let either2: Either<String, Int> = .right(43)
        #expect(either1 != either2)
    }

    @Test("Equatable works for equal lefts")
    func equatableEqualLefts() {
        let either1: Either<String, Int> = .left("error")
        let either2: Either<String, Int> = .left("error")
        #expect(either1 == either2)
    }

    @Test("Equatable works for different lefts")
    func equatableDifferentLefts() {
        let either1: Either<String, Int> = .left("error1")
        let either2: Either<String, Int> = .left("error2")
        #expect(either1 != either2)
    }

    @Test("Equatable works for left and right")
    func equatableLeftAndRight() {
        let either1: Either<String, Int> = .left("error")
        let either2: Either<String, Int> = .right(42)
        #expect(either1 != either2)
    }

    @Test("catching success case")
    func catchingSuccess() async {
        let result = await Either<Failure, String>.catching(domain: "test.domain") {
            "success"
        }
        #expect(result == .right("success"))
    }

    @Test("catching failure case")
    func catchingFailure() async {
        struct TestError: Error {}
        let result = await Either<Failure, String>.catching(domain: "test.domain") {
            throw TestError()
        }
        if case .left(let failure) = result {
            #expect(failure.type == .unknown)
            #expect(failure.domain == "test.domain")
        } else {
            Issue.record("Expected left value")
        }
    }

    @Test("catching with Failure passthrough")
    func catchingWithFailurePassthrough() async {
        let testFailure = Failure.permissionDenied(domain: "original")
        let result = await Either<Failure, String>.catching(domain: "new") {
            throw testFailure
        }
        if case .left(let failure) = result {
            #expect(failure.type == .permissionDenied)
            #expect(failure.domain == "original")
        } else {
            Issue.record("Expected left value")
        }
    }
}
