import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

/// Protocol representing any PDF object in the validation layer.
///
/// This is the base protocol for all validation object types. It provides a unified
/// interface for accessing PDF objects during validation, wrapping the parser's
/// COS (Carousel Object System) and PD (Page Description) layer types.
///
/// Corresponds to the Java `ModelObject` interface from veraPDF-validation.
///
/// ## Design Notes
/// - All validation objects are `Sendable` for thread-safe validation
/// - Objects provide both type information and property access
/// - The validation layer wraps parser types without modifying them
/// - Objects can be COS-level (low-level) or PD-level (high-level)
public protocol PDFObject: Sendable, Identifiable {

    /// A unique identifier for this object in the validation context.
    ///
    /// This identifier is used to track objects during validation and
    /// to correlate validation results with specific PDF objects.
    var id: UUID { get }

    /// The object type name used in validation profiles.
    ///
    /// This corresponds to the type names used in veraPDF validation profiles,
    /// such as "CosDict", "PDPage", "Font", etc.
    var objectType: String { get }

    /// The underlying COS object, if available.
    ///
    /// For COS-level validation objects, this is the direct COS value.
    /// For PD-level objects, this is the COS object that the PD object wraps.
    var cosObject: COSValue? { get }

    /// The object key for indirect objects, if applicable.
    ///
    /// Returns `nil` for direct objects.
    var objectKey: COSObjectKey? { get }

    /// Returns the value of a property by name.
    ///
    /// This is used by validation rules to access object properties.
    /// Property names correspond to the getters defined in the Java
    /// veraPDF model classes.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if the property doesn't exist.
    func property(named name: String) -> PropertyValue?

    /// Returns all property names supported by this object.
    ///
    /// This is used for introspection and debugging.
    var propertyNames: [String] { get }
}

// MARK: - Property Value

/// A value returned from a PDF object property.
///
/// Properties can be primitives, objects, or collections of objects.
public enum PropertyValue: Sendable, Equatable {

    /// A null/nil value.
    case null

    /// A boolean value.
    case boolean(Bool)

    /// An integer value.
    case integer(Int64)

    /// A real (floating-point) value.
    case real(Double)

    /// A string value.
    case string(String)

    /// A name value.
    case name(String)

    /// A single object.
    case object(AnyPDFObject)

    /// An array of objects.
    case objectArray([AnyPDFObject])

    // MARK: - Type Checking

    /// Whether this value is null.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    /// Whether this value is a boolean.
    public var isBoolean: Bool {
        if case .boolean = self { return true }
        return false
    }

    /// Whether this value is an integer.
    public var isInteger: Bool {
        if case .integer = self { return true }
        return false
    }

    /// Whether this value is a real number.
    public var isReal: Bool {
        if case .real = self { return true }
        return false
    }

    /// Whether this value is a string.
    public var isString: Bool {
        if case .string = self { return true }
        return false
    }

    /// Whether this value is a name.
    public var isName: Bool {
        if case .name = self { return true }
        return false
    }

    /// Whether this value is a single object.
    public var isObject: Bool {
        if case .object = self { return true }
        return false
    }

    /// Whether this value is an object array.
    public var isObjectArray: Bool {
        if case .objectArray = self { return true }
        return false
    }

    // MARK: - Value Extraction

    /// Extracts the boolean value.
    public var boolValue: Bool? {
        if case .boolean(let v) = self { return v }
        return nil
    }

    /// Extracts the integer value.
    public var integerValue: Int64? {
        if case .integer(let v) = self { return v }
        return nil
    }

    /// Extracts the real value.
    public var realValue: Double? {
        if case .real(let v) = self { return v }
        return nil
    }

    /// Extracts the string value.
    public var stringValue: String? {
        if case .string(let v) = self { return v }
        if case .name(let v) = self { return v }
        return nil
    }

    /// Extracts the object value.
    public var objectValue: AnyPDFObject? {
        if case .object(let v) = self { return v }
        return nil
    }

    /// Extracts the object array value.
    public var objectArrayValue: [AnyPDFObject]? {
        if case .objectArray(let v) = self { return v }
        return nil
    }

    /// Returns the value as a double, converting integers if needed.
    public var numericValue: Double? {
        switch self {
        case .integer(let v): return Double(v)
        case .real(let v): return v
        default: return nil
        }
    }
}

// MARK: - Type-Erased PDF Object

/// A type-erased wrapper for any PDF object.
///
/// This allows storing and passing around PDF objects of different concrete types
/// in collections and as property values.
public struct AnyPDFObject: PDFObject, Equatable {

    // Stored values instead of closures for Sendable conformance
    public let id: UUID
    public let objectType: String
    public let cosObject: COSValue?
    public let objectKey: COSObjectKey?
    private let propertiesDict: [String: PropertyValue]

    /// Creates a type-erased wrapper for a PDF object.
    public init<T: PDFObject>(_ object: T) where T: Equatable {
        self.id = object.id
        self.objectType = object.objectType
        self.cosObject = object.cosObject
        self.objectKey = object.objectKey

        // Eagerly evaluate properties to avoid storing closures
        var props: [String: PropertyValue] = [:]
        for name in object.propertyNames {
            if let value = object.property(named: name) {
                props[name] = value
            }
        }
        self.propertiesDict = props
    }

    public var propertyNames: [String] {
        Array(propertiesDict.keys).sorted()
    }

    public func property(named name: String) -> PropertyValue? {
        propertiesDict[name]
    }

    public static func == (lhs: AnyPDFObject, rhs: AnyPDFObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Default Implementations

extension PDFObject {

    /// Default implementation returns `nil` for object key.
    ///
    /// Concrete types should override if they represent indirect objects.
    public var objectKey: COSObjectKey? {
        nil
    }

    /// Default implementation returns an empty array.
    ///
    /// Concrete types should override to provide their supported properties.
    public var propertyNames: [String] {
        []
    }
}
