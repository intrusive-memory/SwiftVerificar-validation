import Foundation

// MARK: - SA Structure Root

/// SA (Structured Accessibility) structure tree root.
///
/// `SAStructureRoot` wraps a `ValidatedStructTreeRoot` and provides
/// accessibility-oriented traversal and analysis of the document's
/// tagged structure hierarchy. It is the entry point for accessibility
/// tree analysis during WCAG validation.
///
/// ## Key Properties
///
/// - **Structure Tree Root**: The underlying validated structure tree root
/// - **Children**: Top-level SA nodes in the accessibility tree
/// - **Role Map**: Custom-to-standard structure type mappings
/// - **Statistics**: Structure tree depth, element counts, heading counts
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSAStructTreeRoot` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class wraps the structure tree root and
/// provides accessibility-specific traversal methods for WCAG checking.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - References ValidatedStructTreeRoot from the PD layer
/// - Computed properties for accessibility statistics
public struct SAStructureRoot: SAObject {

    // MARK: - Properties

    /// Unique identifier for this SA structure root.
    public let id: UUID

    /// The underlying validated structure tree root.
    public let structTreeRoot: ValidatedStructTreeRoot

    /// The top-level SA nodes in the accessibility tree.
    ///
    /// These nodes represent the top-level branches of the structure tree
    /// from an accessibility perspective.
    public let children: [SANode]

    // MARK: - Initialization

    /// Creates an SA structure root wrapping a validated structure tree root.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - structTreeRoot: The validated structure tree root to wrap.
    ///   - children: Top-level SA nodes.
    public init(
        id: UUID = UUID(),
        structTreeRoot: ValidatedStructTreeRoot,
        children: [SANode] = []
    ) {
        self.id = id
        self.structTreeRoot = structTreeRoot
        self.children = children
    }

    // MARK: - SAObject Conformance

    /// The SA object type name.
    public var saObjectType: String {
        SAObjectType.structureRoot.rawValue
    }

    /// The validation context for this SA structure root.
    public var validationContext: ObjectContext {
        .saStructureRoot
    }

    /// Accessibility property names supported by this SA structure root.
    public var accessibilityPropertyNames: [String] {
        [
            "childCount", "hasRoleMap", "hasParentTree",
            "hasIDTree", "hasNamespaces", "totalElementCount",
            "maxDepth", "headingCount", "tableCount",
            "figureCount", "listCount", "hasChildren"
        ]
    }

    /// Returns the value of an accessibility property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        switch name {
        case "childCount":
            return .integer(Int64(children.count))
        case "hasRoleMap":
            return .boolean(structTreeRoot.hasRoleMap)
        case "hasParentTree":
            return .boolean(structTreeRoot.hasParentTree)
        case "hasIDTree":
            return .boolean(structTreeRoot.hasIDTree)
        case "hasNamespaces":
            return .boolean(structTreeRoot.hasNamespaces)
        case "totalElementCount":
            return .integer(Int64(structTreeRoot.totalElementCount))
        case "maxDepth":
            return .integer(Int64(structTreeRoot.maxDepth))
        case "headingCount":
            return .integer(Int64(headingCount))
        case "tableCount":
            return .integer(Int64(tableCount))
        case "figureCount":
            return .integer(Int64(figureCount))
        case "listCount":
            return .integer(Int64(listCount))
        case "hasChildren":
            return .boolean(!children.isEmpty)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SAStructureRoot, rhs: SAStructureRoot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Accessibility Traversal

extension SAStructureRoot {

    /// The number of top-level children.
    public var childCount: Int {
        children.count
    }

    /// Whether the structure root has children.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    /// All SA nodes in depth-first order.
    ///
    /// Traverses the entire accessibility tree and returns all nodes
    /// in document reading order.
    public var allNodes: [SANode] {
        var result: [SANode] = []
        for child in children {
            collectNodes(child, into: &result)
        }
        return result
    }

    /// Collects all nodes recursively in depth-first order.
    private func collectNodes(_ node: SANode, into result: inout [SANode]) {
        result.append(node)
        for child in node.children {
            collectNodes(child, into: &result)
        }
    }

    /// All SA nodes of a specific structure element type.
    ///
    /// - Parameter type: The structure element type to filter by.
    /// - Returns: All nodes matching the given type.
    public func nodes(ofType type: StructureElementType) -> [SANode] {
        allNodes.filter { $0.structureType == type }
    }

    /// The number of heading nodes in the tree.
    public var headingCount: Int {
        allNodes.filter { $0.structureType?.isHeading == true }.count
    }

    /// The number of table nodes in the tree.
    public var tableCount: Int {
        allNodes.filter { $0.structureType == .table }.count
    }

    /// The number of figure nodes in the tree.
    public var figureCount: Int {
        allNodes.filter { $0.structureType == .figure }.count
    }

    /// The number of list nodes in the tree.
    public var listCount: Int {
        allNodes.filter { $0.structureType == .list }.count
    }

    /// All heading nodes in document order.
    public var headings: [SANode] {
        allNodes.filter { $0.structureType?.isHeading == true }
    }

    /// All figure nodes in the tree.
    public var figures: [SANode] {
        allNodes.filter { $0.structureType == .figure }
    }

    /// All table nodes in the tree.
    public var tables: [SANode] {
        allNodes.filter { $0.structureType == .table }
    }

    /// All list nodes in the tree.
    public var lists: [SANode] {
        allNodes.filter { $0.structureType == .list }
    }
}

// MARK: - Role Map Resolution

extension SAStructureRoot {

    /// Resolves a structure type through the role map.
    ///
    /// Delegates to the underlying `ValidatedStructTreeRoot.resolveRole(_:)`.
    ///
    /// - Parameter typeName: The structure type name to resolve.
    /// - Returns: The resolved standard type name.
    public func resolveRole(_ typeName: String) -> String {
        structTreeRoot.resolveRole(typeName)
    }

    /// Resolves a structure type to a `StructureElementType`.
    ///
    /// Delegates to the underlying `ValidatedStructTreeRoot.resolveElementType(_:)`.
    ///
    /// - Parameter typeName: The structure type name to resolve.
    /// - Returns: The resolved structure element type, or `nil`.
    public func resolveElementType(_ typeName: String) -> StructureElementType? {
        structTreeRoot.resolveElementType(typeName)
    }
}

// MARK: - Summary

extension SAStructureRoot {

    /// Returns a summary string describing this SA structure root.
    public var summary: String {
        var parts: [String] = ["SAStructureRoot"]
        parts.append("\(structTreeRoot.totalElementCount) elements")
        parts.append("depth=\(structTreeRoot.maxDepth)")
        if headingCount > 0 { parts.append("\(headingCount) headings") }
        if tableCount > 0 { parts.append("\(tableCount) tables") }
        if figureCount > 0 { parts.append("\(figureCount) figures") }
        if listCount > 0 { parts.append("\(listCount) lists") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension SAStructureRoot {

    /// Creates a minimal SA structure root for testing.
    ///
    /// - Parameters:
    ///   - children: Top-level SA nodes.
    ///   - roleMap: Role map dictionary.
    /// - Returns: A minimal SA structure root.
    public static func minimal(
        children: [SANode] = [],
        roleMap: [String: String] = [:]
    ) -> SAStructureRoot {
        let root = ValidatedStructTreeRoot.minimal(roleMap: roleMap)
        return SAStructureRoot(structTreeRoot: root, children: children)
    }
}
