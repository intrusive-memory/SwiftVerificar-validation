import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - PD Validation Object Protocol

/// Base protocol for PD (Page Description) layer validation objects.
///
/// PD layer objects wrap higher-level PDF abstractions built on top of the COS
/// (Carousel Object System) layer. They provide semantically meaningful access
/// to PDF structures for validation rules.
///
/// ## Design Notes
///
/// This protocol extends `PDFObject` to add PD-specific functionality:
/// - Access to the underlying COS dictionary
/// - Parent-child relationships for hierarchical structures
/// - Lazy loading support for resource-intensive objects
///
/// ## Relationship to veraPDF
///
/// Corresponds to the Java `GFPDObject` base class from veraPDF-validation,
/// which provides the foundation for all PD layer model objects.
///
/// ## Swift Adaptations
///
/// - Uses protocol composition instead of class inheritance
/// - All types are value types (structs) for thread safety
/// - Sendable conformance for concurrent validation
public protocol PDValidationObject: PDFObject {

    /// The COS dictionary underlying this PD object.
    ///
    /// Most PD objects are backed by a dictionary that contains their
    /// properties. This provides direct access for validation rules
    /// that need to check low-level COS properties.
    var cosDictionary: COSValue? { get }

    /// The parent object in the document hierarchy, if any.
    ///
    /// For example, a page's parent is the pages tree node, and
    /// an annotation's parent is the page it appears on.
    var parentObject: (any PDValidationObject)? { get }

    /// The object context for validation reporting.
    ///
    /// Provides location information (page number, object type) for
    /// generating meaningful validation error messages.
    var validationContext: ObjectContext { get }

    /// Whether this object has been fully loaded.
    ///
    /// Some PD objects support lazy loading to improve performance.
    /// This property indicates whether the object's data has been
    /// fully loaded from the underlying COS structures.
    var isLoaded: Bool { get }
}

// MARK: - Default Implementations

extension PDValidationObject {

    /// Default: The COS object is the COS dictionary.
    public var cosObject: COSValue? {
        cosDictionary
    }

    /// Default: No parent object.
    public var parentObject: (any PDValidationObject)? {
        nil
    }

    /// Default: Empty context.
    public var validationContext: ObjectContext {
        ObjectContext()
    }

    /// Default: Objects are considered loaded.
    public var isLoaded: Bool {
        true
    }

    /// Returns a dictionary entry by key name.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The value for the key, or `nil` if not found.
    public func dictionaryEntry(_ key: String) -> COSValue? {
        cosDictionary?[ASAtom(key)]
    }

    /// Returns a dictionary entry by ASAtom key.
    ///
    /// - Parameter key: The dictionary key as an ASAtom.
    /// - Returns: The value for the key, or `nil` if not found.
    public func dictionaryEntry(_ key: ASAtom) -> COSValue? {
        cosDictionary?[key]
    }

    /// Returns a string value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The string value, or `nil` if not found or not a string.
    public func stringValue(forKey key: String) -> String? {
        dictionaryEntry(key)?.textValue
    }

    /// Returns an integer value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The integer value, or `nil` if not found or not numeric.
    public func intValue(forKey key: String) -> Int64? {
        dictionaryEntry(key)?.integerValue
    }

    /// Returns a double value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The double value, or `nil` if not found or not numeric.
    public func doubleValue(forKey key: String) -> Double? {
        dictionaryEntry(key)?.numericValue
    }

    /// Returns a boolean value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The boolean value, or `nil` if not found or not a boolean.
    public func boolValue(forKey key: String) -> Bool? {
        dictionaryEntry(key)?.boolValue
    }

    /// Returns a name value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The name as an ASAtom, or `nil` if not found or not a name.
    public func nameValue(forKey key: String) -> ASAtom? {
        dictionaryEntry(key)?.nameValue
    }

    /// Returns an array value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The array value, or `nil` if not found or not an array.
    public func arrayValue(forKey key: String) -> [COSValue]? {
        dictionaryEntry(key)?.arrayValue
    }

    /// Returns a dictionary value from the dictionary.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: The dictionary value, or `nil` if not found or not a dictionary.
    public func dictValue(forKey key: String) -> [ASAtom: COSValue]? {
        dictionaryEntry(key)?.dictionaryValue
    }

    /// Checks if a dictionary entry exists.
    ///
    /// - Parameter key: The dictionary key.
    /// - Returns: `true` if the key exists, `false` otherwise.
    public func hasEntry(_ key: String) -> Bool {
        dictionaryEntry(key) != nil
    }

    /// Returns the Type entry from the dictionary.
    public var typeEntry: ASAtom? {
        cosDictionary?.typeEntry
    }

    /// Returns the Subtype entry from the dictionary.
    public var subtypeEntry: ASAtom? {
        cosDictionary?.subtypeEntry
    }
}

// MARK: - PD Object Type

/// Enumeration of PD layer object types for validation purposes.
///
/// This enum provides type-safe access to the various PD layer object types
/// that can be validated, enabling pattern matching in validation rules.
public enum PDObjectType: String, Sendable, CaseIterable {
    /// Document catalog
    case catalog = "Catalog"

    /// Document information dictionary
    case documentInfo = "DocumentInfo"

    /// Page tree node
    case pages = "Pages"

    /// Page object
    case page = "Page"

    /// Content stream
    case contentStream = "ContentStream"

    /// Annotation
    case annotation = "Annot"

    /// Outlines (bookmarks)
    case outlines = "Outlines"

    /// Outline item
    case outlineItem = "OutlineItem"

    /// AcroForm
    case acroForm = "AcroForm"

    /// Form field
    case field = "Field"

    /// Font
    case font = "Font"

    /// XObject
    case xObject = "XObject"

    /// Image
    case image = "Image"

    /// Form XObject
    case form = "Form"

    /// Color space
    case colorSpace = "ColorSpace"

    /// ICC profile
    case iccProfile = "ICCProfile"

    /// Extended graphics state
    case extGState = "ExtGState"

    /// Pattern
    case pattern = "Pattern"

    /// Shading
    case shading = "Shading"

    /// Metadata stream
    case metadata = "Metadata"

    /// Output intent
    case outputIntent = "OutputIntent"

    /// Embedded file
    case embeddedFile = "EmbeddedFile"

    /// Structure tree root
    case structTreeRoot = "StructTreeRoot"

    /// Structure element
    case structElem = "StructElem"

    /// Action
    case action = "Action"

    /// Destination
    case destination = "Dest"

    /// File specification
    case fileSpec = "Filespec"

    /// Unknown or unrecognized type
    case unknown = "Unknown"

    /// Creates a PDObjectType from a Type dictionary entry.
    ///
    /// - Parameter typeName: The Type entry value.
    public init(fromType typeName: String?) {
        guard let name = typeName else {
            self = .unknown
            return
        }
        self = PDObjectType(rawValue: name) ?? .unknown
    }

    /// Creates a PDObjectType from an ASAtom.
    ///
    /// - Parameter atom: The ASAtom to convert.
    public init(fromAtom atom: ASAtom?) {
        self.init(fromType: atom?.stringValue)
    }
}

// MARK: - Lazy Loading Support

/// A property wrapper for lazy-loaded PD validation objects.
///
/// This wrapper defers the creation of a validation object until it's first
/// accessed, which can improve performance when validating large documents
/// with many resources.
///
/// ## Usage
///
/// ```swift
/// struct SomeValidationObject: PDValidationObject {
///     @LazyPDObject var children: [SomeChild]
/// }
/// ```
@propertyWrapper
public struct LazyPDObject<T: Sendable>: @unchecked Sendable {
    private var value: T?
    private let factory: @Sendable () -> T
    private let lock = NSLock()

    /// Creates a lazy PD object with a factory closure.
    ///
    /// - Parameter factory: The factory closure invoked on first access.
    public init(wrappedValue factory: @autoclosure @escaping @Sendable () -> T) {
        self.factory = factory
    }

    /// The lazily-loaded value.
    public var wrappedValue: T {
        mutating get {
            lock.lock()
            defer { lock.unlock() }

            if let value = value {
                return value
            }
            let created = factory()
            value = created
            return created
        }
    }

    /// Whether the value has been loaded.
    public var isLoaded: Bool {
        lock.lock()
        defer { lock.unlock() }
        return value != nil
    }
}

// MARK: - Resource Resolver Protocol

/// Protocol for resolving PDF resources by name.
///
/// This protocol is used by PD objects that need to look up resources
/// (fonts, color spaces, XObjects, etc.) from their resource dictionary.
public protocol ResourceResolver: Sendable {

    /// Resolves a font resource by name.
    ///
    /// - Parameter name: The font resource name.
    /// - Returns: The font COS value, or `nil` if not found.
    func resolveFont(named name: ASAtom) -> COSValue?

    /// Resolves an XObject resource by name.
    ///
    /// - Parameter name: The XObject resource name.
    /// - Returns: The XObject COS value, or `nil` if not found.
    func resolveXObject(named name: ASAtom) -> COSValue?

    /// Resolves a color space resource by name.
    ///
    /// - Parameter name: The color space resource name.
    /// - Returns: The color space COS value, or `nil` if not found.
    func resolveColorSpace(named name: ASAtom) -> COSValue?

    /// Resolves an extended graphics state resource by name.
    ///
    /// - Parameter name: The ExtGState resource name.
    /// - Returns: The ExtGState COS value, or `nil` if not found.
    func resolveExtGState(named name: ASAtom) -> COSValue?

    /// Resolves a pattern resource by name.
    ///
    /// - Parameter name: The pattern resource name.
    /// - Returns: The pattern COS value, or `nil` if not found.
    func resolvePattern(named name: ASAtom) -> COSValue?

    /// Resolves a shading resource by name.
    ///
    /// - Parameter name: The shading resource name.
    /// - Returns: The shading COS value, or `nil` if not found.
    func resolveShading(named name: ASAtom) -> COSValue?

    /// Resolves a property list resource by name.
    ///
    /// - Parameter name: The property list resource name.
    /// - Returns: The property list COS value, or `nil` if not found.
    func resolveProperties(named name: ASAtom) -> COSValue?
}
