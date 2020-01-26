//
//  Transform.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

public struct Transform<From: Encodable, To: Encodable> {
    /// Applies a transformation on type `From` to type `To`.
    public typealias Transform = (From, [CodingKey]) throws -> To
    public typealias Predicate = (From, [CodingKey]) -> Bool

    /// Applies a transformation on type `From` to type `To`.
    public let transform: Transform

    /// Returns `true` if this transform should apply to
    /// the given value of type `From`.
    public let predicate: Predicate

    /// Defaults to `false`. Set this to `true` to not
    /// rely on the type and precondition to result in this
    /// transform only running once.
    ///
    /// - Important: This actually affects how many times
    ///     the transform runs per container hierarchy. It will
    ///     run once for each container regardless but
    ///     setting this to true will stop it from running twice
    ///     in one container and it will stop it from running in
    ///     child containers if it has already run in a parent.
    public let onlyRunOnce: Bool

    /// Create a Transform that by default appllies to all
    /// values of type `From`.
    ///
    /// - Parameters:
    ///     - transform: A function mapping values of type `From`
    ///         to type `To`.
    ///     - onlyRunOnce: Defaults to `true`. Set this to `false` to run
    ///         this transform repeatedly until the predicate fails.
    ///     - predicate: A function returning `true` if this transform
    ///         should apply to the given value.
    ///
    public init(
        if predicate: @escaping Predicate = { _, _ in true },
        onlyRunOnce: Bool = false,
        transform: @escaping Transform
    ) {
        self.transform = transform
        self.predicate = predicate
        self.onlyRunOnce = onlyRunOnce
    }
}

internal struct TransformAttempt {
    let transform: (Encodable, [CodingKey]) throws -> (changed: Bool, result: Encodable)
    let onlyRunOnce: Bool
    var runAgain: Bool

    // TODO: In Swift 5.2, this will allow uses to become function calls directly on values of this time.
//    mutating func callAsFunction(_ value: Encodable) throws -> (changed: Bool, result: Encodable) {
//        return try attempt(value)
//    }

    mutating func attempt(on value: Encodable, at codingPath: [CodingKey]) throws -> (changed: Bool, result: Encodable) {
        guard runAgain else {
            return (changed: false, result: value)
        }

        let result = try transform(value, codingPath)

        runAgain = !(result.changed && onlyRunOnce)

        return result
    }

    init<T: Encodable, U: Encodable>(_ t: Transform<T, U>) {
        self.runAgain = true
        self.onlyRunOnce = t.onlyRunOnce

        self.transform = { input, codingPath in
            guard let value = input as? T else {
                return (changed: false, result: input)
            }
            guard t.predicate(value, codingPath) else {
                return (changed: false, result: input)
            }
            return try (changed: true, result: t.transform(value, codingPath))
        }
    }
}
