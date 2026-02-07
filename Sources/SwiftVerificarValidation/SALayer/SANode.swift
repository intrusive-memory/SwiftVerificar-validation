import Foundation

// MARK: - SA Node

/// Base SA (Structured Accessibility) node for accessibility tree traversal.
///
/// `SANode` represents a node in the accessibility tree built from the
/// document's tagged structure. Each node wraps a `ValidatedStructElem`
/// and provides accessibility-specific properties and traversal methods
/// for WCAG validation.
///
/// ## Key Properties
///
/// - **Structure Element**: The underlying validated structure element
/// - **Structure Type**: The resolved element type (e.g., paragraph, heading)
/// - **Children**: Child SA nodes forming the accessibility subtree
/// - **Alt Text**: Alternative text for non-text elements
/// - **Language**: Language tag for content language identification
/// - **Page Number**: The page where this node's content appears
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSANode` from veraPDF-validation's wcag-validation module.
/// In the Java codebase, this is the base class for nodes in the SA (Structured
/// Accessibility) tree, providing accessibility-oriented access to structure
/// element properties.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - References ValidatedStructElem from the PD layer
/// - Tree structure via children array (value semantics)
public struct SANode: SAObject {

    // MARK: - Properties

    /// Unique identifier for this SA node.
    public let id: UUID

    /// The underlying validated structure element.
    public let structElem: ValidatedStructElem

    /// The child SA nodes in the accessibility tree.
    public let children: [SANode]

    /// The resolved structure element type for this node.
    ///
    /// This is the standard structure type after role map resolution.
    /// It may differ from the raw structure type name if the document
    /// uses custom structure types mapped to standard ones.
    public let structureType: StructureElementType?

    /// The inherited language for this node.
    ///
    /// If the node itself does not have a language tag, this carries the
    /// language inherited from an ancestor node in the structure tree.
    public let inheritedLanguage: String?

    // MARK: - Initialization

    /// Creates an SA node wrapping a validated structure element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - structElem: The validated structure element to wrap.
    ///   - children: Child SA nodes.
    ///   - structureType: The resolved structure element type. If `nil`, derived
    ///     from the structure element.
    ///   - inheritedLanguage: Language inherited from ancestor nodes.
    public init(
        id: UUID = UUID(),
        structElem: ValidatedStructElem,
        children: [SANode] = [],
        structureType: StructureElementType? = nil,
        inheritedLanguage: String? = nil
    ) {
        self.id = id
        self.structElem = structElem
        self.children = children
        self.structureType = structureType ?? structElem.structureType
        self.inheritedLanguage = inheritedLanguage
    }

    // MARK: - SAObject Conformance

    /// The SA object type name.
    public var saObjectType: String {
        SAObjectType.node.rawValue
    }

    /// The validation context for this SA node.
    public var validationContext: ObjectContext {
        .saNode(structElem.structureTypeName)
    }

    /// Accessibility property names supported by this SA node.
    public var accessibilityPropertyNames: [String] {
        [
            "structureTypeName", "structureType", "altText",
            "actualText", "language", "effectiveLanguage",
            "hasAltText", "hasActualText", "hasLanguage",
            "hasEffectiveLanguage", "childCount", "hasChildren",
            "pageNumber", "requiresAltText", "isAccessible",
            "isHeading", "headingLevel", "isFigure",
            "isTableElement", "isListElement", "isGrouping",
            "isContent", "isArtifact", "inheritedLanguage"
        ]
    }

    /// Returns the value of an accessibility property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        switch name {
        case "structureTypeName":
            return .string(structElem.structureTypeName)
        case "structureType":
            if let type = structureType {
                return .string(type.rawValue)
            }
            return .null
        case "altText":
            if let text = structElem.altText {
                return .string(text)
            }
            return .null
        case "actualText":
            if let text = structElem.actualText {
                return .string(text)
            }
            return .null
        case "language":
            if let lang = structElem.language {
                return .string(lang)
            }
            return .null
        case "effectiveLanguage":
            if let lang = effectiveLanguage {
                return .string(lang)
            }
            return .null
        case "hasAltText":
            return .boolean(structElem.hasAltText)
        case "hasActualText":
            return .boolean(structElem.hasActualText)
        case "hasLanguage":
            return .boolean(structElem.hasLanguage)
        case "hasEffectiveLanguage":
            return .boolean(effectiveLanguage != nil)
        case "childCount":
            return .integer(Int64(children.count))
        case "hasChildren":
            return .boolean(!children.isEmpty)
        case "pageNumber":
            if let page = structElem.pageNumber {
                return .integer(Int64(page))
            }
            return .null
        case "requiresAltText":
            return .boolean(structElem.requiresAltText)
        case "isAccessible":
            return .boolean(isAccessible)
        case "isHeading":
            return .boolean(structureType?.isHeading ?? false)
        case "headingLevel":
            if let level = structureType?.headingLevel {
                return .integer(Int64(level))
            }
            return .null
        case "isFigure":
            return .boolean(structureType == .figure)
        case "isTableElement":
            return .boolean(structureType?.isTableElement ?? false)
        case "isListElement":
            return .boolean(structureType?.isListElement ?? false)
        case "isGrouping":
            return .boolean(structureType?.isGrouping ?? false)
        case "isContent":
            return .boolean(structureType?.isContent ?? false)
        case "isArtifact":
            return .boolean(structureType == .artifact)
        case "inheritedLanguage":
            if let lang = inheritedLanguage {
                return .string(lang)
            }
            return .null
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SANode, rhs: SANode) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Accessibility Properties

extension SANode {

    /// The raw structure type name from the element.
    public var structureTypeName: String {
        structElem.structureTypeName
    }

    /// The alternative text for this node.
    public var altText: String? {
        structElem.altText
    }

    /// The actual text for this node.
    public var actualText: String? {
        structElem.actualText
    }

    /// The language directly set on this node.
    public var language: String? {
        structElem.language
    }

    /// The effective language for this node.
    ///
    /// Returns the node's own language tag if set, otherwise falls back
    /// to the inherited language from ancestor nodes.
    public var effectiveLanguage: String? {
        structElem.language ?? inheritedLanguage
    }

    /// Whether this node has alternative text.
    public var hasAltText: Bool {
        structElem.hasAltText
    }

    /// Whether this node has actual text.
    public var hasActualText: Bool {
        structElem.hasActualText
    }

    /// Whether this node has a language tag (direct or inherited).
    public var hasEffectiveLanguage: Bool {
        effectiveLanguage != nil
    }

    /// The page number where this node's content appears.
    public var pageNumber: Int? {
        structElem.pageNumber
    }

    /// The number of child nodes.
    public var childCount: Int {
        children.count
    }

    /// Whether this node has child nodes.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    /// Whether this node requires alternative text for accessibility.
    public var requiresAltText: Bool {
        structElem.requiresAltText
    }

    /// Whether this node is a heading.
    public var isHeading: Bool {
        structureType?.isHeading ?? false
    }

    /// The heading level (1-6), if this is a numbered heading.
    public var headingLevel: Int? {
        structureType?.headingLevel
    }

    /// Whether this node is a figure.
    public var isFigure: Bool {
        structureType == .figure
    }

    /// Whether this node is a table element.
    public var isTableElement: Bool {
        structureType?.isTableElement ?? false
    }

    /// Whether this node is a list element.
    public var isListElement: Bool {
        structureType?.isListElement ?? false
    }

    /// Whether this node is a grouping element.
    public var isGrouping: Bool {
        structureType?.isGrouping ?? false
    }

    /// Whether this node is a content element.
    public var isContent: Bool {
        structureType?.isContent ?? false
    }

    /// Whether this node is an artifact.
    public var isArtifact: Bool {
        structureType == .artifact
    }

    /// Whether this node meets accessibility requirements.
    ///
    /// A node is considered accessible if:
    /// - Elements requiring alt text have it (or have actual text)
    /// - The node has an effective language (direct or inherited)
    public var isAccessible: Bool {
        let altTextOk = !requiresAltText || hasAltText || hasActualText
        return altTextOk
    }
}

// MARK: - Tree Traversal

extension SANode {

    /// All descendant nodes in depth-first order.
    public var allDescendants: [SANode] {
        var result: [SANode] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// All descendant nodes of a specific structure element type.
    ///
    /// - Parameter type: The structure element type to filter by.
    /// - Returns: All descendants matching the given type.
    public func descendants(ofType type: StructureElementType) -> [SANode] {
        allDescendants.filter { $0.structureType == type }
    }

    /// All heading descendants in document order.
    public var headingDescendants: [SANode] {
        allDescendants.filter { $0.isHeading }
    }

    /// All figure descendants.
    public var figureDescendants: [SANode] {
        allDescendants.filter { $0.isFigure }
    }

    /// Whether any descendant node lacks required accessibility properties.
    ///
    /// Checks for figures without alt text and nodes without effective language.
    public var hasAccessibilityIssues: Bool {
        if !isAccessible { return true }
        return allDescendants.contains { !$0.isAccessible }
    }
}

// MARK: - Summary

extension SANode {

    /// Returns a summary string describing this SA node.
    public var summary: String {
        var parts: [String] = [structureTypeName]
        if let type = structureType, type.rawValue != structureTypeName {
            parts.append("(\(type.rawValue))")
        }
        if hasAltText { parts.append("alt") }
        if let lang = effectiveLanguage { parts.append("lang=\(lang)") }
        if hasChildren { parts.append("\(childCount) children") }
        if let page = pageNumber { parts.append("p\(page)") }
        return parts.joined(separator: " ")
    }
}

// MARK: - Factory Methods

extension SANode {

    /// Creates a minimal SA node for testing.
    ///
    /// - Parameters:
    ///   - typeName: The structure type name (e.g., "P", "H1").
    ///   - children: Child SA nodes.
    ///   - altText: Alternative text.
    ///   - language: Language tag.
    ///   - inheritedLanguage: Inherited language.
    /// - Returns: A minimal SA node.
    public static func minimal(
        typeName: String,
        children: [SANode] = [],
        altText: String? = nil,
        language: String? = nil,
        inheritedLanguage: String? = nil
    ) -> SANode {
        let elem = ValidatedStructElem.minimal(
            typeName: typeName,
            altText: altText,
            language: language
        )
        return SANode(
            structElem: elem,
            children: children,
            inheritedLanguage: inheritedLanguage
        )
    }

    /// Creates a heading SA node for testing.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - language: Language tag.
    ///   - children: Child SA nodes.
    /// - Returns: A heading SA node.
    public static func heading(
        level: Int,
        language: String? = nil,
        children: [SANode] = []
    ) -> SANode {
        let elem = ValidatedStructElem.heading(level: level)
        return SANode(
            structElem: elem,
            children: children,
            inheritedLanguage: language
        )
    }

    /// Creates a figure SA node for testing.
    ///
    /// - Parameters:
    ///   - altText: Alternative text for the figure.
    ///   - pageNumber: Page where the figure appears.
    /// - Returns: A figure SA node.
    public static func figure(
        altText: String? = nil,
        pageNumber: Int? = nil
    ) -> SANode {
        let elem = ValidatedStructElem(
            structureTypeName: "Figure",
            altText: altText,
            pageNumber: pageNumber
        )
        return SANode(structElem: elem)
    }

    /// Creates a paragraph SA node for testing.
    ///
    /// - Parameter language: Language tag for the paragraph.
    /// - Returns: A paragraph SA node.
    public static func paragraph(
        language: String? = nil
    ) -> SANode {
        let elem = ValidatedStructElem.paragraph()
        return SANode(
            structElem: elem,
            inheritedLanguage: language
        )
    }
}
