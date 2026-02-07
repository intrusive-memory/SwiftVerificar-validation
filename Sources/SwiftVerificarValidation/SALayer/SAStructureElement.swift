import Foundation

// MARK: - SA Structure Element

/// SA (Structured Accessibility) structure element for WCAG validation.
///
/// `SAStructureElement` wraps a `ValidatedStructureElement` from the PD layer
/// and extends `SANode` concepts with richer structure semantics for WCAG
/// accessibility validation. While `SANode` wraps `ValidatedStructElem` for
/// basic tree traversal, `SAStructureElement` wraps `ValidatedStructureElement`
/// which includes resolved type information, role map resolution, and
/// inherited language propagation.
///
/// ## Key Properties
///
/// - **Validated Structure Element**: The underlying PD-layer element with
///   resolved type information
/// - **Resolved Type**: The standard structure type after role map resolution
/// - **Accessibility Properties**: Alt text, actual text, language, etc.
/// - **Children**: Child SA structure elements forming the accessibility subtree
/// - **Depth**: Depth in the structure tree hierarchy
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSAStructElem` and the 55 `GFSA*` structure element
/// subclasses from veraPDF-validation's wcag-validation module (e.g.,
/// `GFSAParagraph`, `GFSAFigure`, `GFSATable`, etc.). In Swift, all 55
/// subclasses are consolidated into this single struct using
/// `StructureElementType` for type identity.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - Single struct replaces 55 Java subclasses
/// - Uses `StructureElementType` enum instead of class hierarchy
/// - References `ValidatedStructureElement` from the PD layer
public struct SAStructureElement: SAObject {

    // MARK: - Properties

    /// Unique identifier for this SA structure element.
    public let id: UUID

    /// The underlying validated structure element from the PD layer.
    ///
    /// This contains resolved type information, role map resolution results,
    /// inherited language, and other properties computed during PD-layer
    /// validation.
    public let validatedElement: ValidatedStructureElement

    /// The child SA structure elements.
    public let children: [SAStructureElement]

    /// The SA nodes associated with this structure element.
    ///
    /// These are the accessibility tree nodes that correspond to the
    /// content of this structure element.
    public let nodes: [SANode]

    // MARK: - Initialization

    /// Creates an SA structure element wrapping a validated structure element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - validatedElement: The validated structure element from the PD layer.
    ///   - children: Child SA structure elements.
    ///   - nodes: SA nodes associated with this element.
    public init(
        id: UUID = UUID(),
        validatedElement: ValidatedStructureElement,
        children: [SAStructureElement] = [],
        nodes: [SANode] = []
    ) {
        self.id = id
        self.validatedElement = validatedElement
        self.children = children
        self.nodes = nodes
    }

    // MARK: - SAObject Conformance

    /// The SA object type name.
    public var saObjectType: String {
        SAObjectType.structureElement.rawValue
    }

    /// The validation context for this SA structure element.
    public var validationContext: ObjectContext {
        .saStructureElement(resolvedTypeName)
    }

    /// Accessibility property names supported by this SA structure element.
    public var accessibilityPropertyNames: [String] {
        [
            "resolvedType", "originalTypeName", "resolvedTypeName",
            "wasRemapped", "isStandardType", "altText", "actualText",
            "expansionText", "effectiveLanguage", "hasOwnLanguage",
            "hasAltText", "hasActualText", "hasEffectiveLanguage",
            "childCount", "hasChildren", "depth", "siblingIndex",
            "pageNumber", "kidsStandardTypes", "elementID",
            "namespaceURI", "requiresAltText", "isAccessible",
            "isHeading", "headingLevel", "isFigure",
            "isTableElement", "isListElement", "isGrouping",
            "isContent", "isArtifact", "isLink", "nodeCount",
            "isAccessibilityRelevant", "meetsAccessibilityRequirements"
        ]
    }

    /// Returns the value of an accessibility property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        switch name {
        case "resolvedType":
            if let type = resolvedType {
                return .string(type.rawValue)
            }
            return .null
        case "originalTypeName":
            return .string(originalTypeName)
        case "resolvedTypeName":
            return .string(resolvedTypeName)
        case "wasRemapped":
            return .boolean(wasRemapped)
        case "isStandardType":
            return .boolean(isStandardType)
        case "altText":
            if let text = altText {
                return .string(text)
            }
            return .null
        case "actualText":
            if let text = actualText {
                return .string(text)
            }
            return .null
        case "expansionText":
            if let text = expansionText {
                return .string(text)
            }
            return .null
        case "effectiveLanguage":
            if let lang = effectiveLanguage {
                return .string(lang)
            }
            return .null
        case "hasOwnLanguage":
            return .boolean(hasOwnLanguage)
        case "hasAltText":
            return .boolean(hasAltText)
        case "hasActualText":
            return .boolean(hasActualText)
        case "hasEffectiveLanguage":
            return .boolean(hasEffectiveLanguage)
        case "childCount":
            return .integer(Int64(childCount))
        case "hasChildren":
            return .boolean(hasChildren)
        case "depth":
            return .integer(Int64(depth))
        case "siblingIndex":
            return .integer(Int64(siblingIndex))
        case "pageNumber":
            if let page = pageNumber {
                return .integer(Int64(page))
            }
            return .null
        case "kidsStandardTypes":
            return .string(kidsStandardTypes)
        case "elementID":
            if let eid = elementID {
                return .string(eid)
            }
            return .null
        case "namespaceURI":
            if let uri = namespaceURI {
                return .string(uri)
            }
            return .null
        case "requiresAltText":
            return .boolean(requiresAltText)
        case "isAccessible":
            return .boolean(isAccessible)
        case "isHeading":
            return .boolean(isHeading)
        case "headingLevel":
            if let level = headingLevel {
                return .integer(Int64(level))
            }
            return .null
        case "isFigure":
            return .boolean(isFigure)
        case "isTableElement":
            return .boolean(isTableElement)
        case "isListElement":
            return .boolean(isListElement)
        case "isGrouping":
            return .boolean(isGrouping)
        case "isContent":
            return .boolean(isContent)
        case "isArtifact":
            return .boolean(isArtifact)
        case "isLink":
            return .boolean(isLink)
        case "nodeCount":
            return .integer(Int64(nodes.count))
        case "isAccessibilityRelevant":
            return .boolean(isAccessibilityRelevant)
        case "meetsAccessibilityRequirements":
            return .boolean(meetsAccessibilityRequirements)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SAStructureElement, rhs: SAStructureElement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Delegated Properties from ValidatedStructureElement

extension SAStructureElement {

    /// The resolved structure element type.
    public var resolvedType: StructureElementType? {
        validatedElement.resolvedType
    }

    /// The original (raw) structure type name from the PDF.
    public var originalTypeName: String {
        validatedElement.originalTypeName
    }

    /// The resolved type name (after role map resolution).
    public var resolvedTypeName: String {
        validatedElement.resolvedTypeName
    }

    /// Whether the type was resolved through a role map mapping.
    public var wasRemapped: Bool {
        validatedElement.wasRemapped
    }

    /// Whether the resolved type is a standard (known) type.
    public var isStandardType: Bool {
        validatedElement.isStandardType
    }

    /// The alternative text for this element.
    public var altText: String? {
        validatedElement.altText
    }

    /// The actual text for this element.
    public var actualText: String? {
        validatedElement.actualText
    }

    /// The expansion text for abbreviations.
    public var expansionText: String? {
        validatedElement.expansionText
    }

    /// The effective language for this element (own or inherited).
    public var effectiveLanguage: String? {
        validatedElement.effectiveLanguage
    }

    /// Whether this element has its own language tag.
    public var hasOwnLanguage: Bool {
        validatedElement.hasOwnLanguage
    }

    /// Whether the element has alternative text.
    public var hasAltText: Bool {
        validatedElement.hasAltText
    }

    /// Whether the element has actual text.
    public var hasActualText: Bool {
        validatedElement.hasActualText
    }

    /// Whether the element has an effective language.
    public var hasEffectiveLanguage: Bool {
        validatedElement.hasEffectiveLanguage
    }

    /// The number of child elements.
    public var childCount: Int {
        children.count
    }

    /// Whether this element has children.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    /// The depth of this element in the structure tree.
    public var depth: Int {
        validatedElement.depth
    }

    /// The index of this element among its siblings.
    public var siblingIndex: Int {
        validatedElement.siblingIndex
    }

    /// The page number where this element's content appears.
    public var pageNumber: Int? {
        validatedElement.pageNumber
    }

    /// The children's standard types joined by "&".
    public var kidsStandardTypes: String {
        children
            .map { $0.resolvedTypeName }
            .joined(separator: "&")
    }

    /// The element's ID string.
    public var elementID: String? {
        validatedElement.elementID
    }

    /// The namespace URI for this element (PDF 2.0).
    public var namespaceURI: String? {
        validatedElement.namespaceURI
    }
}

// MARK: - Accessibility Properties

extension SAStructureElement {

    /// Whether this element requires alternative text.
    public var requiresAltText: Bool {
        resolvedType?.requiresAltText ?? false
    }

    /// Whether this element is accessible (has required alt text).
    public var isAccessible: Bool {
        validatedElement.meetsAccessibilityRequirements
    }

    /// Whether this element is a heading.
    public var isHeading: Bool {
        validatedElement.isHeading
    }

    /// The heading level (1-6), if this is a numbered heading.
    public var headingLevel: Int? {
        validatedElement.headingLevel
    }

    /// Whether this element is a figure.
    public var isFigure: Bool {
        validatedElement.isFigure
    }

    /// Whether this element is a table component.
    public var isTableElement: Bool {
        validatedElement.isTableElement
    }

    /// Whether this element is a list component.
    public var isListElement: Bool {
        validatedElement.isListElement
    }

    /// Whether this element is a grouping element.
    public var isGrouping: Bool {
        validatedElement.isGrouping
    }

    /// Whether this element is a content element.
    public var isContent: Bool {
        validatedElement.isContent
    }

    /// Whether this element is an artifact.
    public var isArtifact: Bool {
        validatedElement.isArtifact
    }

    /// Whether this element is a link.
    public var isLink: Bool {
        validatedElement.isLink
    }

    /// Whether this element is accessibility-relevant.
    public var isAccessibilityRelevant: Bool {
        validatedElement.isAccessibilityRelevant
    }

    /// Whether this element meets all accessibility requirements.
    public var meetsAccessibilityRequirements: Bool {
        validatedElement.meetsAccessibilityRequirements
    }
}

// MARK: - Tree Traversal

extension SAStructureElement {

    /// All descendant SA structure elements in depth-first order.
    public var allDescendants: [SAStructureElement] {
        var result: [SAStructureElement] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// All descendant elements of a specific structure element type.
    ///
    /// - Parameter type: The structure element type to filter by.
    /// - Returns: All descendants matching the given type.
    public func descendants(ofType type: StructureElementType) -> [SAStructureElement] {
        allDescendants.filter { $0.resolvedType == type }
    }

    /// All heading descendants in document order.
    public var headingDescendants: [SAStructureElement] {
        allDescendants.filter(\.isHeading)
    }

    /// All figure descendants.
    public var figureDescendants: [SAStructureElement] {
        allDescendants.filter(\.isFigure)
    }

    /// All descendant elements that fail accessibility requirements.
    public var accessibilityIssues: [SAStructureElement] {
        allDescendants.filter { !$0.meetsAccessibilityRequirements }
    }

    /// Whether any descendant has accessibility issues.
    public var hasAccessibilityIssues: Bool {
        if !isAccessible { return true }
        return allDescendants.contains { !$0.isAccessible }
    }
}

// MARK: - Summary

extension SAStructureElement {

    /// Returns a summary string describing this SA structure element.
    public var summary: String {
        var parts: [String] = [resolvedTypeName]
        if wasRemapped { parts.append("(from: \(originalTypeName))") }
        if hasAltText { parts.append("alt") }
        if let lang = effectiveLanguage { parts.append("lang=\(lang)") }
        if hasChildren { parts.append("\(childCount) children") }
        if let page = pageNumber { parts.append("p\(page)") }
        if !nodes.isEmpty { parts.append("\(nodes.count) nodes") }
        return parts.joined(separator: " ")
    }
}

// MARK: - ObjectContext Extension

extension ObjectContext {

    /// Context for an SA structure element.
    ///
    /// - Parameter typeName: The resolved structure type name.
    /// - Returns: An SA structure element context.
    public static func saStructureElement(_ typeName: String) -> ObjectContext {
        ObjectContext(location: "SAStructureElement", role: typeName)
    }
}

// MARK: - Factory Methods

extension SAStructureElement {

    /// Creates a minimal SA structure element for testing.
    ///
    /// - Parameters:
    ///   - typeName: The structure type name (e.g., "P", "H1").
    ///   - children: Child SA structure elements.
    ///   - altText: Alternative text.
    ///   - language: Effective language.
    /// - Returns: A minimal SA structure element.
    public static func minimal(
        typeName: String,
        children: [SAStructureElement] = [],
        altText: String? = nil,
        language: String? = nil
    ) -> SAStructureElement {
        let validated = ValidatedStructureElement.minimal(
            typeName: typeName,
            altText: altText,
            language: language
        )
        return SAStructureElement(
            validatedElement: validated,
            children: children
        )
    }

    /// Creates a heading SA structure element for testing.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - language: Effective language.
    /// - Returns: A heading SA structure element.
    public static func heading(
        level: Int,
        language: String? = nil
    ) -> SAStructureElement {
        let typeName = "H\(max(1, min(6, level)))"
        let validated = ValidatedStructureElement(
            originalTypeName: typeName,
            effectiveLanguage: language
        )
        return SAStructureElement(validatedElement: validated)
    }

    /// Creates a figure SA structure element for testing.
    ///
    /// - Parameters:
    ///   - altText: Alternative text for the figure.
    ///   - pageNumber: Page number.
    /// - Returns: A figure SA structure element.
    public static func figure(
        altText: String? = nil,
        pageNumber: Int? = nil
    ) -> SAStructureElement {
        let validated = ValidatedStructureElement(
            originalTypeName: "Figure",
            altText: altText,
            pageNumber: pageNumber
        )
        return SAStructureElement(validatedElement: validated)
    }

    /// Creates a paragraph SA structure element for testing.
    ///
    /// - Parameter language: Effective language.
    /// - Returns: A paragraph SA structure element.
    public static func paragraph(
        language: String? = nil
    ) -> SAStructureElement {
        let validated = ValidatedStructureElement(
            originalTypeName: "P",
            effectiveLanguage: language
        )
        return SAStructureElement(validatedElement: validated)
    }

    /// Creates an SA structure element from a `ValidatedStructureElement`
    /// and recursively creates child SA elements.
    ///
    /// - Parameter element: The validated structure element.
    /// - Returns: An SA structure element with recursively created children.
    public static func from(
        _ element: ValidatedStructureElement
    ) -> SAStructureElement {
        let saChildren = element.children.map { SAStructureElement.from($0) }
        return SAStructureElement(
            validatedElement: element,
            children: saChildren
        )
    }
}
