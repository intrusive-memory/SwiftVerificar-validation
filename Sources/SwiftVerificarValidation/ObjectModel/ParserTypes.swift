import Foundation

// MARK: - Temporary Parser Type Stubs
//
// These are minimal stubs of types from SwiftVerificarParser to allow
// the validation package to build independently during development.
//
// TODO: Replace with actual imports from SwiftVerificarParser once that package is stable.

#if !canImport(SwiftVerificarParser)

/// Placeholder for ASAtom from the parser package.
public struct ASAtom: Sendable, Hashable, Comparable, CustomStringConvertible {
    public let stringValue: String

    public init(_ value: String) {
        self.stringValue = value
    }

    public static func < (lhs: ASAtom, rhs: ASAtom) -> Bool {
        lhs.stringValue < rhs.stringValue
    }

    public var description: String {
        "/\(stringValue)"
    }

    // Common PDF name atoms
    public static let type = ASAtom("Type")
    public static let subtype = ASAtom("Subtype")
    public static let parent = ASAtom("Parent")
    public static let page = ASAtom("Page")
    public static let pages = ASAtom("Pages")
    public static let catalog = ASAtom("Catalog")
    public static let font = ASAtom("Font")
    public static let type1 = ASAtom("Type1")
    public static let image = ASAtom("Image")
}

/// Placeholder for COSObjectKey from the parser package.
public struct COSObjectKey: Sendable, Hashable, Comparable, CustomStringConvertible {
    public let objectNumber: Int
    public let generation: Int

    public init(objectNumber: Int, generation: Int = 0) {
        self.objectNumber = objectNumber
        self.generation = generation
    }

    public static func < (lhs: COSObjectKey, rhs: COSObjectKey) -> Bool {
        if lhs.objectNumber != rhs.objectNumber {
            return lhs.objectNumber < rhs.objectNumber
        }
        return lhs.generation < rhs.generation
    }

    public var description: String {
        "\(objectNumber) \(generation) R"
    }
}

/// Placeholder for COSReference from the parser package.
public struct COSReference: Sendable, Hashable, CustomStringConvertible {
    public let objectNumber: Int
    public let generation: Int

    public init(objectNumber: Int, generation: Int = 0) {
        self.objectNumber = objectNumber
        self.generation = generation
    }

    public var key: COSObjectKey {
        COSObjectKey(objectNumber: objectNumber, generation: generation)
    }

    public var description: String {
        "\(objectNumber) \(generation) R"
    }
}

/// Placeholder for COSString from the parser package.
public struct COSString: Sendable, Hashable, CustomStringConvertible {
    public let bytes: Data

    public init(string: String) {
        self.bytes = Data(string.utf8)
    }

    public var stringValue: String? {
        String(data: bytes, encoding: .utf8)
    }

    public var description: String {
        if let str = stringValue {
            return "(\(str))"
        }
        return "<\(bytes.map { String(format: "%02x", $0) }.joined())>"
    }
}

/// Placeholder for COSValue from the parser package.
public enum COSValue: Sendable, Hashable, CustomStringConvertible {
    case null
    case boolean(Bool)
    case integer(Int64)
    case real(Double)
    case string(COSString)
    case name(ASAtom)
    case array([COSValue])
    case dictionary([ASAtom: COSValue])
    case reference(COSReference)

    // Type checking
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    public var isBoolean: Bool {
        if case .boolean = self { return true }
        return false
    }

    public var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    public var isReal: Bool {
        if case .real = self { return true }
        return false
    }

    public var isNumeric: Bool {
        isInteger || isReal
    }

    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    public var isName: Bool {
        if case .name = self { return true }
        return false
    }

    public var isArray: Bool {
        if case .array = self { return true }
        return false
    }

    public var isDictionary: Bool {
        if case .dictionary = self { return true }
        return false
    }

    public var isReference: Bool {
        if case .reference = self { return true }
        return false
    }

    // Value extraction
    public var boolValue: Bool? {
        if case .boolean(let v) = self { return v }
        return nil
    }

    public var integerValue: Int64? {
        if case .integer(let v) = self { return v }
        return nil
    }

    public var realValue: Double? {
        if case .real(let v) = self { return v }
        return nil
    }

    public var numericValue: Double? {
        switch self {
        case .integer(let v): return Double(v)
        case .real(let v): return v
        default: return nil
        }
    }

    public var stringValue: COSString? {
        if case .string(let v) = self { return v }
        return nil
    }

    public var textValue: String? {
        stringValue?.stringValue
    }

    public var nameValue: ASAtom? {
        if case .name(let v) = self { return v }
        return nil
    }

    public var arrayValue: [COSValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    public var dictionaryValue: [ASAtom: COSValue]? {
        if case .dictionary(let v) = self { return v }
        return nil
    }

    public var referenceValue: COSReference? {
        if case .reference(let v) = self { return v }
        return nil
    }

    // Dictionary access
    public subscript(key: ASAtom) -> COSValue? {
        if case .dictionary(let dict) = self {
            return dict[key]
        }
        return nil
    }

    public subscript(key: String) -> COSValue? {
        self[ASAtom(key)]
    }

    // Array access
    public subscript(index: Int) -> COSValue? {
        if case .array(let arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    // Helpers
    public var typeEntry: ASAtom? {
        self[.type]?.nameValue
    }

    public var subtypeEntry: ASAtom? {
        self[.subtype]?.nameValue
    }

    public var count: Int? {
        switch self {
        case .array(let arr): return arr.count
        case .dictionary(let dict): return dict.count
        default: return nil
        }
    }

    public var description: String {
        switch self {
        case .null: return "null"
        case .boolean(let v): return v ? "true" : "false"
        case .integer(let v): return String(v)
        case .real(let v): return String(v)
        case .string(let v): return v.description
        case .name(let v): return v.description
        case .array(let arr): return "[\(arr.map(\.description).joined(separator: " "))]"
        case .dictionary(let dict):
            let entries = dict.sorted { $0.key < $1.key }
                .map { "\($0.key) \($0.value)" }
                .joined(separator: " ")
            return "<<\(entries)>>"
        case .reference(let ref): return ref.description
        }
    }

    // Hashable for Double
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null: hasher.combine(0)
        case .boolean(let v): hasher.combine(1); hasher.combine(v)
        case .integer(let v): hasher.combine(2); hasher.combine(v)
        case .real(let v): hasher.combine(3); hasher.combine(v == 0.0 ? 0.0 : v)
        case .string(let v): hasher.combine(4); hasher.combine(v)
        case .name(let v): hasher.combine(5); hasher.combine(v)
        case .array(let arr): hasher.combine(6); hasher.combine(arr)
        case .dictionary(let dict):
            hasher.combine(7)
            hasher.combine(dict.count)
            for key in dict.keys.sorted() {
                hasher.combine(key)
                hasher.combine(dict[key])
            }
        case .reference(let ref): hasher.combine(8); hasher.combine(ref)
        }
    }
}

#endif
