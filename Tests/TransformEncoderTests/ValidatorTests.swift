//
//  ValidatorTests.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

@testable import TransformEncoder
import XCTest

final class ValidatorTests: XCTestCase {
    func test_hitError() throws {
        let int = 3

        let validator = Validator { (x: Int, path) in
            if x > 2 {
                throw ValidationError(reason: "Found integer that was bigger than 2!", at: path)
            }
        }

        XCTAssertThrowsError(try TransformAttempt(validator).transform(int, []))
    }

    func test_dontHitError() throws {
        let int = 2

        let validator = Validator { (x: Int, path) in
            if x > 2 {
                throw ValidationError(reason: "Found integer that was bigger than 2!", at: path)
            }
        }

        XCTAssertNoThrow(try TransformAttempt(validator).transform(int, []))
    }

    func test_predicateNeverMet() throws {
        let int = 3

        let validator = Validator(if: { _, _ in false }) { (x: Int, path) in
            if x > 2 {
                throw ValidationError(reason: "Found integer that was bigger than 2!", at: path)
            }
        }

        XCTAssertNoThrow(try TransformAttempt(validator).transform(int, []))
    }
}
