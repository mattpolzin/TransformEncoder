
import OrderedDictionary

/// `Codable`-style `Encoder` that can be used to encode an `Encodable` type to a new `Encodable` type by applying
/// the specified transforms. Similar to `Foundation.JSONEncoder`.
public class TransformEncoder {

    internal var transforms: [TransformAttempt]

    /// Creates a `TransformEncoder`.
    public init() {
        self.transforms = []
    }

    /// Creates a `TransformEncoder`.
    internal init(transforms: [TransformAttempt]) {
        self.transforms = transforms
    }

    /// Add a transformation to be performed when encoding.
    public func transform<From: Encodable, To: Encodable>(
        if predicate: @escaping Transform<From, To>.Predicate = { _, _ in true },
        transform: @escaping Transform<From, To>.Transform
    ) {
        self.transform(Transform(if: predicate, transform: transform))
    }

    /// Add a transformation to be performed when encoding.
    ///
    /// - Important: This actually affects how many times
    ///     the transform runs per container hierarchy. It will
    ///     run once for each container regardless but
    ///     setting this to true will stop it from running twice
    ///     in one container and it will stop it from running in
    ///     child containers if it has already run in a parent.
    public func transformOnce<From: Encodable, To: Encodable>(
        if predicate: @escaping Transform<From, To>.Predicate = { _, _ in true },
        transform: @escaping Transform<From, To>.Transform
    ) {
        self.transform(Transform(if: predicate, onlyRunOnce: true, transform: transform))
    }

    /// Add a transformation to be performed when encoding.
    public func transform<From: Encodable, To: Encodable>(_ transform: Transform<From, To>) {
        self.transforms.append(TransformAttempt(transform))
    }

    /// Encode a value of type `T` to Data.
    ///
    /// - parameter value:    Value to encode.
    /// - parameter userInfo: Additional key/values which can be used when looking up keys to encode.
    ///
    /// - returns: Encoded Data after applying transforms.
    ///
    /// - throws: `EncodingError` if something went wrong while encoding.
    public func encode<T: Swift.Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> some Encodable {
        try encode(value, userInfo: userInfo)
    }

    internal func encode<T: Swift.Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Any] = [:]) throws -> TransformEncoderNode {
        do {
            let encoder = _Encoder(transforms: transforms, userInfo: userInfo)
            var container = encoder.singleValueContainer()
            try container.encode(value)
            return encoder.node
        } catch let error as EncodingError {
            throw error
        } catch {
            let description = "Unable to encode the given top-level value to YAML."
            let context = EncodingError.Context(codingPath: [],
                                                debugDescription: description,
                                                underlyingError: error)
            throw EncodingError.invalidValue(value, context)
        }
    }
}

/// Must be used with Encodable dict values and array elements only.
enum TransformEncoderNode: Encodable {
    case unused
    case single(Encodable)
    case unkeyed([TransformEncoderNode])
    case keyed(OrderedDictionary<String, TransformEncoderNode>)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .unused:
            fatalError()
        case .single(let value):
            try value.encode(to: encoder)
        case .unkeyed(let value):
            try value.encode(to: encoder)
        case .keyed(let value):
            try value.encode(to: encoder)
        }
    }

    static var null: TransformEncoderNode {
        return TransformEncoderNode.single(nil as Int?)
    }
}

class _Encoder: Encoder {

    init(
        transforms: [TransformAttempt],
        userInfo: [CodingUserInfoKey: Any] = [:],
        codingPath: [CodingKey] = []
    ) {
        self.transforms = transforms
        self.userInfo = userInfo
        self.codingPath = codingPath
    }

    let codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]
    private(set) var transforms: [TransformAttempt]

    var node: TransformEncoderNode = .unused

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return .init(_KeyedEncodingContainer(referencing: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _UnkeyedEncodingContainer(referencing: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }

    var keyed: OrderedDictionary<String, TransformEncoderNode> {
        get {
            guard case .keyed(let dict) = node else {
                return [:]
            }
            return dict
        }
        set {
            guard case .keyed = node else {
                fatalError()
            }
            node = .keyed(newValue)
        }
    }

    var unkeyed: [TransformEncoderNode] {
        get {
            guard case .unkeyed(let array) = node else {
                return []
            }
            return array
        }
        set {
            guard case .unkeyed = node else {
                fatalError()
            }
            node = .unkeyed(newValue)
        }
    }

    /// create a new `_ReferencingEncoder` instance as `key` inheriting `userInfo`
    func encoder(for key: CodingKey) -> _ReferencingEncoder {
        return .init(referencing: self, key: key)
    }

    /// create a new `_ReferencingEncoder` instance at `index` inheriting `userInfo`
    func encoder(at index: Int) -> _ReferencingEncoder {
        return .init(referencing: self, at: index)
    }

    private var canEncodeNewValue: Bool {
        guard case .unused = node else {
            return false
        }
        return true
    }
}

class _ReferencingEncoder: _Encoder {
    private enum Reference {
        case dictionary(String)
        case array(Int)
    }

    private let encoder: _Encoder
    private let reference: Reference

    init(referencing encoder: _Encoder, key: CodingKey) {
        self.encoder = encoder
        reference = .dictionary(key.stringValue)
        super.init(
            transforms: encoder.transforms,
            userInfo: encoder.userInfo,
            codingPath: encoder.codingPath + [key]
        )
    }

    init(referencing encoder: _Encoder, at index: Int) {
        self.encoder = encoder
        reference = .array(index)
        super.init(
            transforms: encoder.transforms,
            userInfo: encoder.userInfo,
            codingPath: encoder.codingPath + [_CodingKey(index: index)]
        )
    }

    deinit {
        switch reference {
        case .dictionary(let key):
            switch encoder.node {
            case .keyed(var dict):
                dict[key] = node
                encoder.node = .keyed(dict)
            case .unused:
                encoder.node = .keyed([key: node])

            default:
                fatalError()
            }
        case .array(let index):
            switch encoder.node {
            case .unkeyed(var array):
                if index == array.count {
                    array.append(node)
                } else {
                    array[index] = node
                }
                encoder.node = .unkeyed(array)
            case .unused:
                encoder.node = .unkeyed([node])

            default:
                fatalError()
            }
        }
    }
}

extension _Encoder: SingleValueEncodingContainer {
    func encodeNil() throws {
        assertCanEncodeNewValue()
        node = TransformEncoderNode.null
    }

    func encode(_ value: Bool) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: String) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Double) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Float) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Int) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Int8) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Int16) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Int32) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: Int64) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: UInt) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: UInt8) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: UInt16) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: UInt32) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode(_ value: UInt64) throws {
        node = .single(try applyTransforms(to: value))
    }

    func encode<T>(_ value: T) throws where T : Encodable {
        assertCanEncodeNewValue()
        try applyTransforms(to: value).encode(to: self)
    }

    /// Asserts that a single value can be encoded at the current coding path
    /// (i.e. that one has not already been encoded through this container).
    /// `preconditionFailure()`s if one cannot be encoded.
    private func assertCanEncodeNewValue() {
        precondition(
            canEncodeNewValue,
            "Attempt to encode value through single value container when previously value already encoded."
        )
    }

    private func applyTransforms(to value: Encodable) throws -> Encodable {
        var activelyTransforming = true
        var result: Encodable = value
        while activelyTransforming {
            activelyTransforming = false
            for idx in transforms.indices {
                let next = try transforms[idx].attempt(on: result, at: codingPath)

                activelyTransforming = activelyTransforming || next.changed
                result = next.result
            }
        }
        return result
    }
}

struct _UnkeyedEncodingContainer: UnkeyedEncodingContainer {
    let encoder: _Encoder

    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    var codingPath: [CodingKey] { encoder.codingPath }

    var count: Int { encoder.unkeyed.count }

    func encodeNil() throws {
        encoder.unkeyed.append(TransformEncoderNode.null)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        try currentEncoder.encode(value)
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        currentEncoder.container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        currentEncoder.unkeyedContainer()
    }

    func superEncoder() -> Encoder { currentEncoder }

    private var currentEncoder: _ReferencingEncoder {
        return encoder.encoder(at: count)
    }
}

struct _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {

    let encoder: _Encoder

    init(referencing encoder: _Encoder) {
        self.encoder = encoder
    }

    var codingPath: [CodingKey] { encoder.codingPath }

    func encodeNil(forKey key: Key) throws {
        encoder.keyed[key.stringValue] = TransformEncoderNode.null
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        try encoder(for: key).encode(value)
    }

//    mutating func encode(_ value: Bool, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: String, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Double, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Float, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Int, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Int8, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Int16, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Int32, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: Int64, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: UInt, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: UInt8, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: UInt16, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: UInt32, forKey key: Key) throws {
//        <#code#>
//    }
//
//    mutating func encode(_ value: UInt64, forKey key: Key) throws {
//        <#code#>
//    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        encoder(for: key).container(keyedBy: keyType)
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        encoder(for: key).unkeyedContainer()
    }

    func superEncoder() -> Encoder {
        encoder(for: _CodingKey.super)
    }

    func superEncoder(forKey key: Key) -> Encoder {
        encoder(for: key)
    }

    private func encoder(for key: CodingKey) -> _ReferencingEncoder { return encoder.encoder(for: key) }
}

struct _CodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    static let `super` = _CodingKey(stringValue: "super")
}
