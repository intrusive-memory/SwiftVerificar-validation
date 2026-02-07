import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Validated Resource Protocol

/// Base protocol for PDF resource validation wrappers.
///
/// Resources are named objects that can be used by content streams, including
/// fonts, XObjects, color spaces, extended graphics states, patterns, and shadings.
///
/// ## Key Properties
///
/// - **Name**: The resource's name in the Resources dictionary
/// - **Type**: The resource type (Font, XObject, ColorSpace, etc.)
/// - **Referenced**: Whether the resource is actually used in content
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDResource` from veraPDF-validation, which serves as the
/// base class for all resource types.
public protocol ValidatedResource: PDValidationObject {

    /// The resource name (key in the Resources dictionary).
    var resourceName: ASAtom { get }

    /// The resource type.
    var resourceType: ResourceType { get }

    /// Whether this resource is referenced in a content stream.
    var isReferenced: Bool { get }

    /// The page numbers where this resource is used (if tracked).
    var usedOnPages: [Int] { get }
}

// MARK: - Resource Type

/// Enumeration of PDF resource types.
public enum ResourceType: String, Sendable, CaseIterable {
    /// Font resource.
    case font = "Font"

    /// XObject resource (image, form, or postscript).
    case xObject = "XObject"

    /// Color space resource.
    case colorSpace = "ColorSpace"

    /// Extended graphics state resource.
    case extGState = "ExtGState"

    /// Pattern resource.
    case pattern = "Pattern"

    /// Shading resource.
    case shading = "Shading"

    /// Properties (property list) resource.
    case properties = "Properties"

    /// ProcSet resource (obsolete, but still present in some PDFs).
    case procSet = "ProcSet"

    /// Unknown resource type.
    case unknown = "Unknown"

    /// Creates a resource type from a dictionary key.
    ///
    /// - Parameter key: The resource dictionary key.
    public init(fromKey key: String) {
        self = ResourceType(rawValue: key) ?? .unknown
    }
}

// MARK: - Default Resource Implementations

extension ValidatedResource {

    /// Default: The resource is not referenced.
    public var isReferenced: Bool {
        false
    }

    /// Default: No tracked usage pages.
    public var usedOnPages: [Int] {
        []
    }

    /// Default property names for resources.
    public var propertyNames: [String] {
        ["resourceName", "resourceType", "isReferenced", "usedOnPages"]
    }

    /// Default property access for resource protocol properties.
    public func resourceProperty(named name: String) -> PropertyValue? {
        switch name {
        case "resourceName":
            return .name(resourceName.stringValue)
        case "resourceType":
            return .string(resourceType.rawValue)
        case "isReferenced":
            return .boolean(isReferenced)
        case "usedOnPages":
            return .string(usedOnPages.map(String.init).joined(separator: ","))
        default:
            return nil
        }
    }
}

// MARK: - Generic Resource Wrapper

/// A generic resource wrapper for any PDF resource type.
///
/// This struct provides a concrete implementation of `ValidatedResource` that
/// can wrap any type of PDF resource (font, XObject, color space, etc.) for
/// validation purposes.
///
/// Use this for resources that do not need a specialized validation wrapper.
public struct GenericValidatedResource: ValidatedResource, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier.
    public let id: UUID

    /// The COS dictionary for this resource.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    /// The resource name.
    public let resourceName: ASAtom

    /// The resource type.
    public let resourceType: ResourceType

    /// Whether this resource is referenced in content.
    public let isReferenced: Bool

    /// Pages where this resource is used.
    public let usedOnPages: [Int]

    // MARK: - Additional Properties

    /// The subtype of the resource, if applicable.
    public let subtype: ASAtom?

    /// Additional metadata about this resource.
    public let metadata: [String: String]

    // MARK: - Initialization

    /// Creates a generic validated resource.
    ///
    /// - Parameters:
    ///   - id: Unique identifier.
    ///   - cosDictionary: The COS dictionary for the resource.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - resourceName: The resource name.
    ///   - resourceType: The resource type.
    ///   - isReferenced: Whether the resource is referenced.
    ///   - usedOnPages: Pages where the resource is used.
    ///   - subtype: The resource subtype.
    ///   - metadata: Additional metadata.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(),
        resourceName: ASAtom,
        resourceType: ResourceType,
        isReferenced: Bool = false,
        usedOnPages: [Int] = [],
        subtype: ASAtom? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.resourceName = resourceName
        self.resourceType = resourceType
        self.isReferenced = isReferenced
        self.usedOnPages = usedOnPages
        self.subtype = subtype
        self.metadata = metadata
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PD\(resourceType.rawValue)"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        var names = ["resourceName", "resourceType", "isReferenced", "usedOnPages", "subtype"]
        names.append(contentsOf: metadata.keys.sorted())
        return names
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "resourceName":
            return .name(resourceName.stringValue)
        case "resourceType":
            return .string(resourceType.rawValue)
        case "isReferenced":
            return .boolean(isReferenced)
        case "usedOnPages":
            return .string(usedOnPages.map(String.init).joined(separator: ","))
        case "subtype":
            if let st = subtype {
                return .name(st.stringValue)
            }
            return .null
        default:
            if let metaValue = metadata[name] {
                return .string(metaValue)
            }
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: GenericValidatedResource, rhs: GenericValidatedResource) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Resource Collection

/// A collection of validated resources grouped by type.
///
/// This struct provides convenient access to resources organized by their type,
/// useful during page-level and document-level validation.
public struct ResourceCollection: Sendable, Equatable {

    /// All resources in this collection.
    public let resources: [GenericValidatedResource]

    /// Creates a resource collection.
    ///
    /// - Parameter resources: The resources to include.
    public init(resources: [GenericValidatedResource] = []) {
        self.resources = resources
    }

    /// Resources filtered by type.
    ///
    /// - Parameter type: The resource type to filter by.
    /// - Returns: Resources of the specified type.
    public func resources(ofType type: ResourceType) -> [GenericValidatedResource] {
        resources.filter { $0.resourceType == type }
    }

    /// Font resources.
    public var fonts: [GenericValidatedResource] {
        resources(ofType: .font)
    }

    /// XObject resources.
    public var xObjects: [GenericValidatedResource] {
        resources(ofType: .xObject)
    }

    /// Color space resources.
    public var colorSpaces: [GenericValidatedResource] {
        resources(ofType: .colorSpace)
    }

    /// Extended graphics state resources.
    public var extGStates: [GenericValidatedResource] {
        resources(ofType: .extGState)
    }

    /// Pattern resources.
    public var patterns: [GenericValidatedResource] {
        resources(ofType: .pattern)
    }

    /// Shading resources.
    public var shadings: [GenericValidatedResource] {
        resources(ofType: .shading)
    }

    /// Properties resources.
    public var properties: [GenericValidatedResource] {
        resources(ofType: .properties)
    }

    /// The total number of resources.
    public var count: Int {
        resources.count
    }

    /// Whether the collection has no resources.
    public var isEmpty: Bool {
        resources.isEmpty
    }

    /// Looks up a resource by name and type.
    ///
    /// - Parameters:
    ///   - name: The resource name.
    ///   - type: The resource type.
    /// - Returns: The matching resource, or `nil` if not found.
    public func resource(named name: ASAtom, ofType type: ResourceType) -> GenericValidatedResource? {
        resources.first { $0.resourceName == name && $0.resourceType == type }
    }

    /// All unreferenced resources (potential issues for PDF/A).
    public var unreferencedResources: [GenericValidatedResource] {
        resources.filter { !$0.isReferenced }
    }
}
