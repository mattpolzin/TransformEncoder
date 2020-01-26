//
//  TransformAttemptTests.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

@testable import TransformEncoder
import XCTest

final class TransformAttemptTests: XCTestCase {
    func test_intToString() throws {
        let string = "hello"
        let int = 10

        let transform = Transform<Int, String> { int, _ in
            "\(string) \(int)"
        }

        let res = try TransformAttempt(transform).transform(int, []).result

        XCTAssertEqual(res as? String, "hello 10")
    }

    func test_wrongType() throws {
        let string = "hello"

        let transform = Transform<Int, Int> { int, _ in int + 1 }

        let res = try TransformAttempt(transform).transform(string, []).result

        XCTAssertEqual(res as? String, "hello")
    }

    func test_throws() {
        let string = "hello"

        let transform = Transform<String, String> { _, _ in throw DummyError() }

        XCTAssertThrowsError(try TransformAttempt(transform).transform(string, []))
    }

    func test_failsPredicate() {
        let int = 10

        let transform = Transform<Int, Int>(if: { _, _ in false }) { int, _ in int + 1 }

        XCTAssertEqual(try TransformAttempt(transform).transform(int, []).result as? Int, int)
    }

    func test_failsPredicateDoesNotThrow() throws {
        let string = "hello"

        let transform = Transform<String, String>(if: { _, _ in false }) { _, _ in throw DummyError() }

        _ = try TransformAttempt(transform).transform(string, [])
    }

    func test_runMoreThanOnce() throws {
        let string = "a"

        let transform = Transform { (x: String, _) -> String in "\(x)_a" }
        var transformAttempt = TransformAttempt(transform)

        XCTAssertEqual(try transformAttempt.attempt(on: transformAttempt.attempt(on: string, at: []).result, at: []).result as? String, "a_a_a")
    }

    func test_runOnlyOnce() throws {
        let string = "a"

        let transform = Transform(onlyRunOnce: true) { (x: String, _) -> String in "\(x)_a" }
        var transformAttempt = TransformAttempt(transform)

        XCTAssertEqual(try transformAttempt.attempt(on: transformAttempt.attempt(on: string, at: []).result, at: []).result as? String, "a_a")
    }

    #warning("TODO: test coding key predicates")
}

struct DummyError: Swift.Error {}
