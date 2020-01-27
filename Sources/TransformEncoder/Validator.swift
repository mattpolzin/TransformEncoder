//
//  Validator.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

public struct Validator<T: Encodable> {
    /// Applies validation on type `T`. Throws if validation fails.
    public typealias Validator = (T, [CodingKey]) throws -> Void
    public typealias Predicate = (T, [CodingKey]) -> Bool

    /// Applies validation on type `T`. Throws if validation fails.
    public let validate: Validator

    /// Returns `true` if this validator should apply to
    /// the given value of type `T`.
    public let predicate: Predicate

    /// Create a Validator that by default appllies to all
    /// values of type `T`.
    ///
    /// - Parameters:
    ///     - validate: A function taking values of type `T` and validating
    ///         them. This function should throw if a validation error occurs.
    ///     - predicate: A function returning `true` if this validator
    ///         should run against the given value.
    ///
    public init(
        if predicate: @escaping Predicate = { _, _ in true },
        validate: @escaping Validator
    ) {
        self.validate = validate
        self.predicate = predicate
    }
}

public struct ValidationError: Swift.Error, CustomStringConvertible {
    public let reason: String
    public let codingPath: [CodingKey]

    public init(reason: String, at path: [CodingKey]) {
        self.reason = reason
        self.codingPath = path
    }

    public var description: String {
        "\(reason) at path: \(codingPath.map { $0.intValue.map { "[\($0)]" } ?? "/\($0.stringValue)" }.joined())"
    }
}
