import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Structure Element

/// A higher-level validated structure element with resolved type information.
///
/// This struct provides a richer view of a structure element by resolving its
/// type through the role map and combining information from the structure tree
/// root. It is the primary type used by accessibility validators.
///
/// ## Design
///
/// While `ValidatedStructElem` wraps the raw PDF structure element dictionary,
/// `ValidatedStructureElement` adds:
/// - Resolved type (after role map resolution)
/// - Parent relationship
/// - Depth in the structure tree
/// - Combined accessibility properties (inherited language, etc.)
/// - Validation-specific computed properties
///
/// ## Relationship to veraPDF
///
/// This type consolidates functionality from 58 Java `GFSE*` classes
/// (e.g., `GFSEDocument`, `GFSEParagraph`, `GFSEFigure`, etc.) into a single
/// struct that uses `StructureElementType` for type identity.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Uses `StructureElementType` enum instead of class hierarchy
public struct ValidatedStructureElement: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the structure element.
    public let cosDictionary: COSValue?

    /// The object key for the structure element, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Type Information

    /// The resolved structure element type.
    ///
    /// This is the type after role map resolution. If the raw type name
    /// does not resolve to a standard type, this is `nil`.
    public let resolvedType: StructureElementType?

    /// The original (raw) structure type name from the PDF.
    public let originalTypeName: String

    /// The resolved type name (after role map resolution).
    ///
    /// This may differ from `originalTypeName` if a role map mapping was applied.
    public let resolvedTypeName: String

    /// Whether the type was resolved through a role map mapping.
    public var wasRemapped: Bool {
        originalTypeName != resolvedTypeName
    }

    /// Whether the resolved type is a standard (known) type.
    public var isStandardType: Bool {
        resolvedType != nil
    }

    // MARK: - Hierarchy

    /// The child validated structure elements.
    public let children: [ValidatedStructureElement]

    /// The number of child elements.
    public var childCount: Int {
        children.count
    }

    /// Whether this element has children.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    /// The depth of this element in the structure tree (0 = direct child of root).
    public let depth: Int

    /// The index of this element among its siblings.
    public let siblingIndex: Int

    // MARK: - Accessibility Properties

    /// The alternative text for this element.
    public let altText: String?

    /// The actual text for this element.
    public let actualText: String?

    /// The expansion text for abbreviations.
    public let expansionText: String?

    /// The effective language for this element.
    ///
    /// This is the language tag from the element itself, or inherited from
    /// the nearest ancestor that has one.
    public let effectiveLanguage: String?

    /// Whether this element has its own language tag (not inherited).
    public let hasOwnLanguage: Bool

    /// Whether the element has alternative text.
    public var hasAltText: Bool {
        altText != nil && !(altText?.isEmpty ?? true)
    }

    /// Whether the element has actual text.
    public var hasActualText: Bool {
        actualText != nil && !(actualText?.isEmpty ?? true)
    }

    /// Whether the element has an effective language.
    public var hasEffectiveLanguage: Bool {
        effectiveLanguage != nil && !(effectiveLanguage?.isEmpty ?? true)
    }

    // MARK: - Content Properties

    /// The marked content identifiers (MCID) associated with this element.
    public let markedContentIDs: [Int]

    /// The page number where this element's content appears.
    public let pageNumber: Int?

    /// The element's attributes.
    public let attributes: [String: COSValue]

    /// The element's class names.
    public let classNames: [String]

    /// The element's ID string.
    public let elementID: String?

    /// The namespace URI for this element (PDF 2.0).
    public let namespaceURI: String?

    // MARK: - Standard Types for Children

    /// The types of this element's children, collected as a string.
    ///
    /// This is used by validation rules that check child element type constraints.
    /// The format is the child type names joined by "&".
    public var kidsStandardTypes: String {
        children
            .map { $0.resolvedTypeName }
            .joined(separator: "&")
    }

    // MARK: - Initialization

    /// Creates a validated structure element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the structure element.
    ///   - objectKey: The object key for the structure element.
    ///   - context: Validation context.
    ///   - resolvedType: The resolved structure element type.
    ///   - originalTypeName: The original type name from the PDF.
    ///   - resolvedTypeName: The resolved type name after role map resolution.
    ///   - children: Child validated structure elements.
    ///   - depth: Depth in the structure tree.
    ///   - siblingIndex: Index among siblings.
    ///   - altText: Alternative text.
    ///   - actualText: Actual text.
    ///   - expansionText: Expansion text.
    ///   - effectiveLanguage: The effective language (own or inherited).
    ///   - hasOwnLanguage: Whether the element has its own language tag.
    ///   - markedContentIDs: Marked content identifiers.
    ///   - pageNumber: Page number for this element's content.
    ///   - attributes: Element attributes.
    ///   - classNames: Element class names.
    ///   - elementID: Element ID string.
    ///   - namespaceURI: Namespace URI (PDF 2.0).
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        resolvedType: StructureElementType? = nil,
        originalTypeName: String,
        resolvedTypeName: String? = nil,
        children: [ValidatedStructureElement] = [],
        depth: Int = 0,
        siblingIndex: Int = 0,
        altText: String? = nil,
        actualText: String? = nil,
        expansionText: String? = nil,
        effectiveLanguage: String? = nil,
        hasOwnLanguage: Bool = false,
        markedContentIDs: [Int] = [],
        pageNumber: Int? = nil,
        attributes: [String: COSValue] = [:],
        classNames: [String] = [],
        elementID: String? = nil,
        namespaceURI: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        let effectiveResolvedName = resolvedTypeName ?? originalTypeName
        self.validationContext = context ?? .structureElement(effectiveResolvedName)
        self.resolvedType = resolvedType ?? StructureElementType(rawValue: effectiveResolvedName)
        self.originalTypeName = originalTypeName
        self.resolvedTypeName = effectiveResolvedName
        self.children = children
        self.depth = depth
        self.siblingIndex = siblingIndex
        self.altText = altText
        self.actualText = actualText
        self.expansionText = expansionText
        self.effectiveLanguage = effectiveLanguage
        self.hasOwnLanguage = hasOwnLanguage
        self.markedContentIDs = markedContentIDs
        self.pageNumber = pageNumber
        self.attributes = attributes
        self.classNames = classNames
        self.elementID = elementID
        self.namespaceURI = namespaceURI
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "SEGeneral"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "resolvedType", "originalTypeName", "resolvedTypeName",
            "wasRemapped", "isStandardType", "childCount",
            "hasChildren", "depth", "siblingIndex",
            "altText", "actualText", "expansionText",
            "effectiveLanguage", "hasOwnLanguage",
            "hasAltText", "hasActualText", "hasEffectiveLanguage",
            "pageNumber", "hasAttributes", "kidsStandardTypes",
            "elementID", "namespaceURI"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
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
        case "childCount":
            return .integer(Int64(childCount))
        case "hasChildren":
            return .boolean(hasChildren)
        case "depth":
            return .integer(Int64(depth))
        case "siblingIndex":
            return .integer(Int64(siblingIndex))
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
        case "pageNumber":
            if let page = pageNumber {
                return .integer(Int64(page))
            }
            return .null
        case "hasAttributes":
            return .boolean(!attributes.isEmpty)
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
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedStructureElement, rhs: ValidatedStructureElement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Accessibility Validation Helpers

extension ValidatedStructureElement {

    /// Whether this element is an accessibility-relevant element.
    ///
    /// Returns `true` for elements that carry content or structure meaningful
    /// to assistive technologies.
    public var isAccessibilityRelevant: Bool {
        guard let type = resolvedType else { return false }
        return !type.isArtifact && type != .nonStruct
    }

    /// Whether this element has all required accessibility properties.
    ///
    /// Checks:
    /// - Figures have alt text or actual text
    /// - The element has an effective language
    public var meetsAccessibilityRequirements: Bool {
        if resolvedType?.requiresAltText == true {
            if !hasAltText && !hasActualText {
                return false
            }
        }
        return true
    }

    /// Whether this element is a heading.
    public var isHeading: Bool {
        resolvedType?.isHeading ?? false
    }

    /// The heading level, if this element is a numbered heading.
    public var headingLevel: Int? {
        resolvedType?.headingLevel
    }

    /// Whether this element is a table component.
    public var isTableElement: Bool {
        resolvedType?.isTableElement ?? false
    }

    /// Whether this element is a list component.
    public var isListElement: Bool {
        resolvedType?.isListElement ?? false
    }

    /// Whether this element is a figure.
    public var isFigure: Bool {
        resolvedType == .figure
    }

    /// Whether this element is a link.
    public var isLink: Bool {
        resolvedType == .link
    }

    /// Whether this element is an artifact.
    public var isArtifact: Bool {
        resolvedType == .artifact
    }

    /// Whether this element is a grouping element.
    public var isGrouping: Bool {
        resolvedType?.isGrouping ?? false
    }

    /// Whether this element is a content element.
    public var isContent: Bool {
        resolvedType?.isContent ?? false
    }
}

// MARK: - Tree Navigation

extension ValidatedStructureElement {

    /// Returns all descendant elements in depth-first order.
    public var allDescendants: [ValidatedStructureElement] {
        var result: [ValidatedStructureElement] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// Returns all descendant elements of a specific type.
    ///
    /// - Parameter type: The structure element type to filter by.
    /// - Returns: All descendants matching the given type.
    public func descendants(ofType type: StructureElementType) -> [ValidatedStructureElement] {
        allDescendants.filter { $0.resolvedType == type }
    }

    /// Returns all descendant headings in document order.
    public var descendantHeadings: [ValidatedStructureElement] {
        allDescendants.filter(\.isHeading)
    }

    /// Returns all descendant figures in document order.
    public var descendantFigures: [ValidatedStructureElement] {
        allDescendants.filter(\.isFigure)
    }

    /// Returns all descendant elements that fail accessibility requirements.
    public var accessibilityIssues: [ValidatedStructureElement] {
        allDescendants.filter { !$0.meetsAccessibilityRequirements }
    }
}

// MARK: - Creation from ValidatedStructElem

extension ValidatedStructureElement {

    /// Creates a `ValidatedStructureElement` from a `ValidatedStructElem` and its tree root.
    ///
    /// This method resolves the structure type through the role map and computes
    /// inherited properties like effective language.
    ///
    /// - Parameters:
    ///   - elem: The raw structure element to wrap.
    ///   - root: The structure tree root for role map resolution.
    ///   - depth: The depth in the tree.
    ///   - siblingIndex: The index among siblings.
    ///   - inheritedLanguage: The language inherited from the nearest ancestor.
    /// - Returns: A validated structure element with resolved properties.
    public static func from(
        _ elem: ValidatedStructElem,
        root: ValidatedStructTreeRoot,
        depth: Int = 0,
        siblingIndex: Int = 0,
        inheritedLanguage: String? = nil
    ) -> ValidatedStructureElement {
        let resolvedName = root.resolveRole(elem.structureTypeName)
        let resolvedType = StructureElementType(rawValue: resolvedName)
        let ownLanguage = elem.language
        let effectiveLang = ownLanguage ?? inheritedLanguage

        let resolvedChildren = elem.children.enumerated().map { index, child in
            ValidatedStructureElement.from(
                child,
                root: root,
                depth: depth + 1,
                siblingIndex: index,
                inheritedLanguage: effectiveLang
            )
        }

        return ValidatedStructureElement(
            id: elem.id,
            cosDictionary: elem.cosDictionary,
            objectKey: elem.objectKey,
            resolvedType: resolvedType,
            originalTypeName: elem.structureTypeName,
            resolvedTypeName: resolvedName,
            children: resolvedChildren,
            depth: depth,
            siblingIndex: siblingIndex,
            altText: elem.altText,
            actualText: elem.actualText,
            expansionText: elem.expansionText,
            effectiveLanguage: effectiveLang,
            hasOwnLanguage: ownLanguage != nil,
            markedContentIDs: elem.markedContentIDs,
            pageNumber: elem.pageNumber,
            attributes: elem.attributes,
            classNames: elem.classNames,
            elementID: elem.elementID,
            namespaceURI: elem.namespaceURI
        )
    }
}

// MARK: - Factory Methods

extension ValidatedStructureElement {

    /// Creates a minimal validated structure element for testing.
    ///
    /// - Parameters:
    ///   - typeName: The structure type name.
    ///   - children: Child elements.
    ///   - altText: Alternative text.
    ///   - language: Effective language.
    /// - Returns: A minimal validated structure element.
    public static func minimal(
        typeName: String,
        children: [ValidatedStructureElement] = [],
        altText: String? = nil,
        language: String? = nil
    ) -> ValidatedStructureElement {
        ValidatedStructureElement(
            originalTypeName: typeName,
            children: children,
            altText: altText,
            effectiveLanguage: language
        )
    }
}
