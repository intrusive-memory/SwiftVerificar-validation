import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Validated Structure Tree Root

/// A validation wrapper for the PDF structure tree root.
///
/// The structure tree root is the top-level element of the document's tagged
/// structure hierarchy. It contains references to the structure elements that
/// define the logical reading order and semantic structure of the document.
///
/// ## Key Properties
///
/// - **Children**: Top-level structure elements
/// - **Role Map**: Mapping from custom structure types to standard types
/// - **Class Map**: Mapping from class names to attribute objects
/// - **Namespaces**: Structure namespaces (PDF 2.0)
/// - **ID Tree**: Name tree mapping element identifiers to structure elements
/// - **Parent Tree**: Number tree mapping marked content to structure elements
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDStructTreeRoot` from veraPDF-validation, which provides
/// access to the PDF structure tree root dictionary for validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Computed properties derived from the COS dictionary
public struct ValidatedStructTreeRoot: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the structure tree root.
    public let cosDictionary: COSValue?

    /// The object key for the structure tree root, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Structure Tree Properties

    /// The top-level structure elements (children of the root).
    public let children: [ValidatedStructElem]

    /// The number of top-level structure elements.
    public var childCount: Int {
        children.count
    }

    /// The role map dictionary (custom type -> standard type).
    ///
    /// Maps non-standard structure type names to their standard equivalents.
    /// For example, a custom "MyParagraph" type might map to "P".
    public let roleMap: [String: String]

    /// The class map dictionary (class name -> attribute objects).
    ///
    /// Maps attribute class names to their attribute objects for
    /// class-based attribute assignment.
    public let classMap: [String: COSValue]

    /// Whether the structure tree root has a role map.
    public var hasRoleMap: Bool {
        !roleMap.isEmpty
    }

    /// Whether the structure tree root has a class map.
    public var hasClassMap: Bool {
        !classMap.isEmpty
    }

    /// Whether the structure tree root has an ID tree.
    public let hasIDTree: Bool

    /// Whether the structure tree root has a parent tree.
    public let hasParentTree: Bool

    /// The parent tree next key (ParentTreeNextKey entry).
    ///
    /// This is the next available key for the parent tree number tree.
    public let parentTreeNextKey: Int?

    // MARK: - Namespace Support (PDF 2.0)

    /// The structure namespaces defined in this document (PDF 2.0).
    public let namespaces: [StructureNamespace]

    /// Whether the structure tree uses namespaces (PDF 2.0 feature).
    public var hasNamespaces: Bool {
        !namespaces.isEmpty
    }

    // MARK: - Computed Statistics

    /// The total number of structure elements in the tree (recursive count).
    public let totalElementCount: Int

    /// The maximum nesting depth of the structure tree.
    public let maxDepth: Int

    // MARK: - Initialization

    /// Creates a validated structure tree root.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the structure tree root.
    ///   - objectKey: The object key for the structure tree root.
    ///   - context: Validation context.
    ///   - children: Top-level structure elements.
    ///   - roleMap: Role map dictionary.
    ///   - classMap: Class map dictionary.
    ///   - hasIDTree: Whether an ID tree exists.
    ///   - hasParentTree: Whether a parent tree exists.
    ///   - parentTreeNextKey: The parent tree next key.
    ///   - namespaces: Structure namespaces (PDF 2.0).
    ///   - totalElementCount: Total number of structure elements.
    ///   - maxDepth: Maximum nesting depth.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = .structureTreeRoot,
        children: [ValidatedStructElem] = [],
        roleMap: [String: String] = [:],
        classMap: [String: COSValue] = [:],
        hasIDTree: Bool = false,
        hasParentTree: Bool = false,
        parentTreeNextKey: Int? = nil,
        namespaces: [StructureNamespace] = [],
        totalElementCount: Int = 0,
        maxDepth: Int = 0
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.children = children
        self.roleMap = roleMap
        self.classMap = classMap
        self.hasIDTree = hasIDTree
        self.hasParentTree = hasParentTree
        self.parentTreeNextKey = parentTreeNextKey
        self.namespaces = namespaces
        self.totalElementCount = totalElementCount
        self.maxDepth = maxDepth
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDStructTreeRoot"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "childCount", "hasRoleMap", "hasClassMap",
            "hasIDTree", "hasParentTree", "parentTreeNextKey",
            "hasNamespaces", "totalElementCount", "maxDepth"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "childCount":
            return .integer(Int64(childCount))
        case "hasRoleMap":
            return .boolean(hasRoleMap)
        case "hasClassMap":
            return .boolean(hasClassMap)
        case "hasIDTree":
            return .boolean(hasIDTree)
        case "hasParentTree":
            return .boolean(hasParentTree)
        case "parentTreeNextKey":
            if let key = parentTreeNextKey {
                return .integer(Int64(key))
            }
            return .null
        case "hasNamespaces":
            return .boolean(hasNamespaces)
        case "totalElementCount":
            return .integer(Int64(totalElementCount))
        case "maxDepth":
            return .integer(Int64(maxDepth))
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedStructTreeRoot, rhs: ValidatedStructTreeRoot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Role Map Resolution

extension ValidatedStructTreeRoot {

    /// Resolves a structure type name through the role map.
    ///
    /// If the given type name has a mapping in the role map, the mapped name is
    /// returned. The resolution follows the chain: if the mapped name itself has
    /// a mapping, it resolves further (up to a maximum depth to prevent cycles).
    ///
    /// - Parameter typeName: The structure type name to resolve.
    /// - Returns: The resolved standard type name.
    public func resolveRole(_ typeName: String) -> String {
        var resolved = typeName
        var visited: Set<String> = []
        let maxChainLength = 10

        while let mapped = roleMap[resolved], !visited.contains(resolved) {
            visited.insert(resolved)
            resolved = mapped
            if visited.count >= maxChainLength {
                break
            }
        }
        return resolved
    }

    /// Resolves a structure type name to a `StructureElementType`.
    ///
    /// First resolves through the role map, then attempts to create a
    /// `StructureElementType` from the resolved name.
    ///
    /// - Parameter typeName: The structure type name to resolve.
    /// - Returns: The resolved structure element type, or `nil` if the resolved
    ///   name does not match any standard type.
    public func resolveElementType(_ typeName: String) -> StructureElementType? {
        let resolved = resolveRole(typeName)
        return StructureElementType(rawValue: resolved)
    }
}

// MARK: - Tree Traversal

extension ValidatedStructTreeRoot {

    /// Returns all structure elements in depth-first order.
    ///
    /// This provides a flat list of all structure elements in the tree,
    /// which is useful for validation rules that need to inspect every element.
    public var allElements: [ValidatedStructElem] {
        var result: [ValidatedStructElem] = []
        for child in children {
            collectElements(child, into: &result)
        }
        return result
    }

    /// Collects all elements recursively in depth-first order.
    private func collectElements(_ element: ValidatedStructElem, into result: inout [ValidatedStructElem]) {
        result.append(element)
        for child in element.children {
            collectElements(child, into: &result)
        }
    }

    /// Returns all structure elements of a specific type.
    ///
    /// - Parameter type: The structure element type to filter by.
    /// - Returns: All elements matching the given type.
    public func elements(ofType type: StructureElementType) -> [ValidatedStructElem] {
        allElements.filter { $0.structureType == type }
    }

    /// Returns all heading elements in document order.
    public var headings: [ValidatedStructElem] {
        allElements.filter { $0.structureType?.isHeading == true }
    }

    /// Returns all table elements.
    public var tables: [ValidatedStructElem] {
        allElements.filter { $0.structureType == .table }
    }

    /// Returns all figure elements.
    public var figures: [ValidatedStructElem] {
        allElements.filter { $0.structureType == .figure }
    }

    /// Returns all list elements.
    public var lists: [ValidatedStructElem] {
        allElements.filter { $0.structureType == .list }
    }
}

// MARK: - Factory Methods

extension ValidatedStructTreeRoot {

    /// Creates a minimal validated structure tree root for testing.
    ///
    /// - Parameters:
    ///   - children: Top-level structure elements.
    ///   - roleMap: Role map dictionary.
    /// - Returns: A minimal validated structure tree root.
    public static func minimal(
        children: [ValidatedStructElem] = [],
        roleMap: [String: String] = [:]
    ) -> ValidatedStructTreeRoot {
        ValidatedStructTreeRoot(
            children: children,
            roleMap: roleMap,
            totalElementCount: children.count
        )
    }
}

// MARK: - Structure Namespace

/// Represents a PDF 2.0 structure namespace.
///
/// Structure namespaces allow PDFs to define custom structure types within
/// a namespace, avoiding conflicts with standard types and enabling
/// interoperability between different document producers.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `StructureNamespace` from the parser layer.
public struct StructureNamespace: Sendable, Hashable, Codable {

    /// The namespace URI.
    public let namespaceURI: String

    /// The optional schema file URL.
    public let schemaURL: String?

    /// Role mappings within this namespace.
    public let roleMapNS: [String: String]

    /// Creates a structure namespace.
    ///
    /// - Parameters:
    ///   - namespaceURI: The namespace URI.
    ///   - schemaURL: The optional schema file URL.
    ///   - roleMapNS: Role mappings within the namespace.
    public init(
        namespaceURI: String,
        schemaURL: String? = nil,
        roleMapNS: [String: String] = [:]
    ) {
        self.namespaceURI = namespaceURI
        self.schemaURL = schemaURL
        self.roleMapNS = roleMapNS
    }

    /// The standard PDF 1.x namespace URI.
    public static let pdf1Namespace = StructureNamespace(
        namespaceURI: "http://iso.org/pdf/ssn"
    )

    /// The standard PDF 2.0 namespace URI.
    public static let pdf2Namespace = StructureNamespace(
        namespaceURI: "http://iso.org/pdf2/ssn"
    )

    /// The MathML namespace URI.
    public static let mathMLNamespace = StructureNamespace(
        namespaceURI: "http://www.w3.org/1998/Math/MathML"
    )
}

// MARK: - ObjectContext Extension

extension ObjectContext {

    /// Context for the structure tree root.
    public static let structureTreeRoot = ObjectContext(location: "StructTreeRoot")
}
