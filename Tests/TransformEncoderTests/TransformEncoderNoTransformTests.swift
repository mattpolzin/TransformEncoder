//
//  TransformEncoderNoTransformTests.swift
//
//
//  Created by Mathew Polzin on 1/26/20.
//

import XCTest
@testable import TransformEncoder
import OrderedDictionary
import Yams

final class TransformEncoderNoTransformTests: XCTestCase {
    func test_stringStringDict() throws {
        let stringStringDict: OrderedDictionary = [
            "hello": "world",
            "ok": "then",
            "yeah": "cool"
        ]

        let encoded = try TransformEncoder().encode(stringStringDict) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.keyed([
                "hello": .single("world"),
                "ok": .single("then"),
                "yeah": .single("cool")
            ])
        )
    }

    func test_stringArray() throws {
        let stringStringDict = [
            "hello",
            "world",
            "ok"
        ]

        let encoded = try TransformEncoder().encode(stringStringDict) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.unkeyed([
                .single("hello"),
                .single("world"),
                .single("ok")
            ])
        )
    }

    func test_dictOfStringToStringArray() throws {
        let stringStringDict: OrderedDictionary = [
            "hello": ["to", "the", "world"],
            "ok": ["then"]
        ]

        let encoded = try TransformEncoder().encode(stringStringDict) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.keyed([
                "hello": .unkeyed([.single("to"), .single("the"), .single("world")]),
                "ok": .unkeyed([.single("then")])
            ])
        )
    }

    func test_arrayOfStringStringDict() throws {
        let stringStringDict = [
            ["hello": "world"],
            ["ok": "then"]
        ]

        let encoded = try TransformEncoder().encode(stringStringDict) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.unkeyed([
                .keyed(["hello": .single("world")]),
                .keyed(["ok": .single("then")]),
            ])
        )
    }

    func test_struct() throws {
        let encoded = try TransformEncoder().encode(TestStruct()) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.keyed([
                "int": .single(10),
                "double": .single(5.5),
                "string": .single("hello"),
                "bool": .single(true),
                "enum": .single("one"),
                "single": .single(false)
            ])
        )
    }

    func test_nestedStruct() throws {
        let encoded = try TransformEncoder().encode(TestNestedStruct()) as TransformEncoderNode

        XCTAssertEqual(
            encoded,
            TransformEncoderNode.keyed([
                "array": .unkeyed([.single("hello"), .single("world")]),
                "struct": .keyed([
                    "int": .single(10),
                    "double": .single(5.5),
                    "string": .single("hello"),
                    "bool": .single(true),
                    "enum": .single("one"),
                    "single": .single(false)
                ])
            ])
        )

        print(try YAMLEncoder().encode(encoded))
    }
}

fileprivate struct SingleValue: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(false)
    }
}

fileprivate enum TestEnum: String, Encodable {
    case one
    case two
}

fileprivate struct TestStruct: Encodable {
    let int = 10
    let double = 5.5
    let string = "hello"
    let bool = true
    let `enum` = TestEnum.one
    let single = SingleValue()
}

fileprivate struct TestNestedStruct: Encodable {
    let array = ["hello", "world"]
    let `struct` = TestStruct()
}
