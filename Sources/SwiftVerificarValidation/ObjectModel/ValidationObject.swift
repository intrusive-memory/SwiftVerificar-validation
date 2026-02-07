import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Box Type for Recursive Structures

/// A reference type wrapper for value types to enable recursive structures.
public final class Box<T>: @unchecked Sendable {
    public let value: T

    public init(_ value: T) {
        self.value = value
    }
}

extension Box: Equatable where T: Equatable {
    public static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}

/// Wrapper for PDF objects being validated.
///
/// This type wraps a PDF object with additional validation context,
/// providing a unified interface for rule evaluation. It tracks the
/// object's location in the document structure and maintains parent
/// relationships for contextual validation.
///
/// Corresponds to aspects of the Java `ModelObject` and validation
/// context from veraPDF-validation.
public struct WrappedPDFObject: PDFObject, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The wrapped object.
    private let wrappedObject: AnyPDFObject

    /// The parent object in the document hierarchy, if any.
    /// Boxed to avoid recursive value type issue.
    public let parent: Box<WrappedPDFObject>?

    /// Additional context information.
    public let context: ObjectContext

    /// The object type name for validation profiles.
    public var objectType: String {
        wrappedObject.objectType
    }

    /// The underlying COS object.
    public var cosObject: COSValue? {
        wrappedObject.cosObject
    }

    /// The object key for indirect objects.
    public var objectKey: COSObjectKey? {
        wrappedObject.objectKey
    }

    /// Property names supported by the wrapped object.
    public var propertyNames: [String] {
        wrappedObject.propertyNames
    }

    // MARK: - Initialization

    /// Creates a validation object wrapping another PDF object.
    ///
    /// - Parameters:
    ///   - object: The PDF object to wrap.
    ///   - parent: The parent object in the hierarchy, if any.
    ///   - context: Additional context information.
    public init<T: PDFObject>(
        wrapping object: T,
        parent: WrappedPDFObject? = nil,
        context: ObjectContext = ObjectContext()
    ) where T: Equatable {
        self.id = UUID()
        self.wrappedObject = AnyPDFObject(object)
        self.parent = parent.map { Box($0) }
        self.context = context
    }

    /// Creates a validation object from a type-erased object.
    ///
    /// - Parameters:
    ///   - object: The type-erased PDF object.
    ///   - parent: The parent object in the hierarchy, if any.
    ///   - context: Additional context information.
    public init(
        wrapping object: AnyPDFObject,
        parent: WrappedPDFObject? = nil,
        context: ObjectContext = ObjectContext()
    ) {
        self.id = UUID()
        self.wrappedObject = object
        self.parent = parent.map { Box($0) }
        self.context = context
    }

    // MARK: - Property Access

    /// Returns the value of a property by name.
    ///
    /// This delegates to the wrapped object's property accessor.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        wrappedObject.property(named: name)
    }

    // MARK: - Hierarchy

    /// Returns the path to this object from the document root.
    ///
    /// The path is a sequence of object types from root to this object,
    /// useful for error messages and debugging.
    public var objectPath: [String] {
        var path: [String] = []
        var current: WrappedPDFObject? = self
        while let obj = current {
            path.insert(obj.objectType, at: 0)
            current = obj.parent?.value
        }
        return path
    }

    /// Returns a string representation of the object path.
    public var pathString: String {
        objectPath.joined(separator: " > ")
    }

    // MARK: - Equatable

    public static func == (lhs: WrappedPDFObject, rhs: WrappedPDFObject) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - COS Object Wrapper

/// A validation object wrapping a raw COS value.
///
/// This is used when validating COS-level objects (dictionaries, arrays, etc.)
/// that don't have a corresponding PD-level type.
public struct CosValidationObject: PDFObject, Equatable {

    // MARK: - Properties

    /// Unique identifier.
    public let id: UUID

    /// The COS value being validated.
    public let cosValue: COSValue

    /// The object key, if this is an indirect object.
    public let objectKey: COSObjectKey?

    /// The object type name.
    public var objectType: String {
        switch cosValue {
        case .null: return "CosNull"
        case .boolean: return "CosBoolean"
        case .integer: return "CosInteger"
        case .real: return "CosReal"
        case .string: return "CosString"
        case .name: return "CosName"
        case .array: return "CosArray"
        case .dictionary: return "CosDict"
        case .reference: return "CosReference"
        }
    }

    /// The underlying COS object.
    public var cosObject: COSValue? {
        cosValue
    }

    // MARK: - Initialization

    /// Creates a COS validation object.
    ///
    /// - Parameters:
    ///   - cosValue: The COS value to wrap.
    ///   - objectKey: The object key for indirect objects.
    public init(cosValue: COSValue, objectKey: COSObjectKey? = nil) {
        self.id = UUID()
        self.cosValue = cosValue
        self.objectKey = objectKey
    }

    // MARK: - Property Access

    /// Returns the value of a property by name.
    ///
    /// For COS objects, this provides access to common COS properties:
    /// - "size" - number of entries (for dictionaries and arrays)
    /// - "type" - the Type entry (for dictionaries)
    /// - "subtype" - the Subtype entry (for dictionaries)
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "size":
            return cosValue.count.map { .integer(Int64($0)) }

        case "type":
            return cosValue.typeEntry.map { .name($0.stringValue) }

        case "subtype":
            return cosValue.subtypeEntry.map { .name($0.stringValue) }

        case "isNull":
            return .boolean(cosValue.isNull)

        case "isBoolean":
            return .boolean(cosValue.isBoolean)

        case "isInteger":
            return .boolean(cosValue.isInteger)

        case "isReal":
            return .boolean(cosValue.isReal)

        case "isNumeric":
            return .boolean(cosValue.isNumeric)

        case "isString":
            return .boolean(cosValue.isString)

        case "isName":
            return .boolean(cosValue.isName)

        case "isArray":
            return .boolean(cosValue.isArray)

        case "isDictionary":
            return .boolean(cosValue.isDictionary)

        case "isReference":
            return .boolean(cosValue.isReference)

        default:
            return nil
        }
    }

    /// Property names for COS objects.
    public var propertyNames: [String] {
        var names = ["size", "type", "subtype"]
        names += ["isNull", "isBoolean", "isInteger", "isReal", "isNumeric"]
        names += ["isString", "isName", "isArray", "isDictionary", "isReference"]
        return names
    }

    // MARK: - Equatable

    public static func == (lhs: CosValidationObject, rhs: CosValidationObject) -> Bool {
        lhs.id == rhs.id
    }
}
