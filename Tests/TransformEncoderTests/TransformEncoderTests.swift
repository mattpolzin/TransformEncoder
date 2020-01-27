//
//  TransformEncoderTests.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

import XCTest
@testable import TransformEncoder
import OrderedDictionary
import Yams

final class TransformEncoderTests: XCTestCase {
    func test_intToString() throws {
        let array = [10, 11, 12]

        let encoder = TransformEncoder()
        encoder.transform { (x: Int, _) -> String in "\(x)" }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single("10"), .single("11"), .single("12")])
        )
    }

    func test_intToStringPredicateNotMet() throws {
        let array = [10, 11, 12]

        let encoder = TransformEncoder()
        encoder.transform(if: { x, _ in x == 11 }) { (x: Int, _) -> String in "\(x)" }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single(10), .single("11"), .single(12)])
        )
    }

    func test_intPlusOneToString() throws {
        let array = [10, 11, 12]

        let encoder = TransformEncoder()
        encoder.transform { (x: Int, _) -> Int in x + 1 }
        encoder.transform { (x: Int, _) -> String in "\(x)" }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single("11"), .single("12"), .single("13")])
        )
    }

    func test_allAppliedDespiteTransformOrder() throws {
        let array = [10, 11, 12]

        let encoder = TransformEncoder()
        encoder.transformOnce { (x: String, _) -> String in "\(x)_2" }
        encoder.transform { (x: Int, _) -> String in "\(x)" }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single("10_2"), .single("11_2"), .single("12_2")])
        )
    }

    func test_appliedInTransformOrder() throws {
        let array = [10, 11, 12]

        let encoder = TransformEncoder()
        encoder.transformOnce { (x: String, _) -> String in "\(x)_2" } // cannot apply before next transform, so should apply last
        encoder.transform { (x: Int, _) -> String in "\(x)" } // should apply first
        encoder.transformOnce { (x: String, _) -> String in "\(x)_1" } // should apply second

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single("10_1_2"), .single("11_1_2"), .single("12_1_2")])
        )
    }

    func test_enumToInt() throws {
        let array: [TestEnum] = [.one, .two]

        let encoder = TransformEncoder()
        encoder.transform { (x: TestEnum, _) -> Int in
            switch x {
            case .one:
                return 1
            case .two:
                return 2
            }
        }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single(1), .single(2)])
        )
    }

    func test_transformValueInStruct() throws {
        let `struct` = TestStruct()

        let encoder = TransformEncoder()
        encoder.transform { (x: TestEnum, _) -> Int in
            switch x {
            case .one:
                return 1
            case .two:
                return 2
            }
        }

        let res = try encoder.encode(`struct`) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.keyed([
                "enum": .single(1),
                "int": .single(5)
            ])
        )
    }

    func test_transformStruct() throws {
        let array = [
            TestStruct()
        ]

        let encoder = TransformEncoder()
        encoder.transformOnce { (x: TestStruct, _) -> TestStruct in
            var ret = x
            ret.int = 10
            return ret
        }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([
                .keyed([
                    "enum": .single("one"),
                    "int": .single(10)
                ])
            ])
        )
    }

    func test_transformUntilPredicateFails() throws {
        let array = [1]

        let encoder = TransformEncoder()
        encoder.transform(if: { x, _ in x <= 8 }) { (x: Int, _) -> Int in x * 2 }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single(16)])
        )
    }

    func test_transformUntilPredicateFails2() throws {
        let array = [1, 7]

        let encoder = TransformEncoder()
        encoder.transform(if: { x, _ in x <= 8 }) { (x: Int, _) -> Int in x * 2 }

        let res = try encoder.encode(array) as TransformEncoderNode

        XCTAssertEqual(
            res,
            TransformEncoderNode.unkeyed([.single(16), .single(14)])
        )
    }

    func test_validationFails() throws {
        let array = [1, 2, 3]

        let encoder = TransformEncoder()
        encoder.validate { (x: Int, path) in
            if x > 2 {
                throw ValidationError(reason: "Found integer greater than 2!", at: path)
            }
        }

        XCTAssertThrowsError(try encoder.encode(array))
    }

    func test_validationPasses() throws {
        let array = [1, 2]

        let encoder = TransformEncoder()
        encoder.validate { (x: Int, path) in
            if x > 2 {
                throw ValidationError(reason: "Found integer greater than 2!", at: path)
            }
        }

        XCTAssertNoThrow(try encoder.encode(array))
    }

    #warning("TODO: write more tests")
}

fileprivate enum TestEnum: String, Encodable {
    case one
    case two
}

fileprivate struct TestStruct: Encodable {
    var `enum`: TestEnum = .one
    var int: Int = 5
}
