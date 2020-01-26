//
//  Helper.swift
//  
//
//  Created by Mathew Polzin on 1/26/20.
//

@testable import TransformEncoder
import OrderedDictionary

extension TransformEncoderNode: Equatable {
    public static func ==(lhs: TransformEncoderNode, rhs: TransformEncoderNode) -> Bool {
        switch (lhs, rhs) {
        case (.unused, .unused):
            return true
        case (.single(let value1), .single(let value2)):
            if type(of: value1) == type(of: value2) {
                return equal(value1, value2)
            }
            return false
        case (.unkeyed(let array1), .unkeyed(let array2)):
            return array1 == array2
        case (.keyed(let dict1), .keyed(let dict2)):
            return dict1 == dict2

        default:
            return false
        }
    }
}

fileprivate func equal<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool {
    return lhs == rhs
}

fileprivate protocol _Array {
    func equal(_ other: Any) -> Bool
}

extension Array: _Array where Element: Equatable {
    func equal(_ other: Any) -> Bool {
        if let otherSelf = other as? Self {
            return self == otherSelf
        }
        return false
    }
}

fileprivate protocol _OrderedDictionary {
    func equal(_ other: Any) -> Bool
}

extension OrderedDictionary: _OrderedDictionary where Value: Equatable {
    func equal(_ other: Any) -> Bool {
        if let otherSelf = other as? Self {
            return self == otherSelf
        }
        return false
    }
}

fileprivate func equal<T>(_ lhs: T, _ rhs: T) -> Bool {
    switch (lhs, rhs) {
    case (let l as String, let r as String):
        return l == r
    case (let l as Int, let r as Int):
        return l == r
    case (let l as Bool, let r as Bool):
        return l == r
    case (let l as Double, let r as Double):
        return l == r
    case (let l as _Array, let r as _Array):
        return l.equal(r)
    case (let l as _OrderedDictionary, let r as _OrderedDictionary):
        return l.equal(r)

    default:
        fatalError("Attempted to compare two values without support")
    }
}
