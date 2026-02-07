import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Structure Element

/// A validation wrapper for an individual PDF structure element.
///
/// Structure elements are the building blocks of the document's tagged
/// structure hierarchy. Each element has a type (e.g., paragraph, heading,
/// table) and can contain child elements, text content, or marked content
/// references.
///
/// ## Key Properties
///
/// - **Structure Type**: The element type name (e.g., "P", "H1", "Table")
/// - **Children**: Child structure elements
/// - **Attributes**: Element attributes dictionary
/// - **Alternative Text**: Alt text for accessibility
/// - **Actual Text**: Replacement text for the element
/// - **Language**: Language tag for the element content
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDStructElem` from veraPDF-validation, which wraps
/// an individual structure element dictionary for validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Uses `StructureElementType` enum for type-safe type identification
public struct ValidatedStructElem: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the structure element.
    public let cosDictionary: COSValue?

    /// The object key for the structure element, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Structure Element Properties

    /// The raw structure type name from the `/S` entry.
    ///
    /// This is the type name as it appears in the PDF, before role map resolution.
    /// It may be a standard type (e.g., "P", "H1") or a custom type that requires
    /// role map resolution to determine the standard equivalent.
    public let structureTypeName: String

    /// The resolved structure element type, if it maps to a standard type.
    ///
    /// This is `nil` if the structure type name (after role map resolution)
    /// does not match any standard `StructureElementType`.
    public let structureType: StructureElementType?

    /// The child structure elements.
    public let children: [ValidatedStructElem]

    /// The number of child structure elements.
    public var childCount: Int {
        children.count
    }

    /// Whether this element has child structure elements.
    public var hasChildren: Bool {
        !children.isEmpty
    }

    // MARK: - Accessibility Properties

    /// The alternative text (`/Alt` entry) for accessibility.
    ///
    /// Required for figures and other non-text elements in tagged PDFs.
    public let altText: String?

    /// The actual text (`/ActualText` entry) for the element.
    ///
    /// Replacement text that should be used instead of the element's
    /// marked content. Used for ligatures, special characters, etc.
    public let actualText: String?

    /// The expansion text (`/E` entry) for abbreviations and acronyms.
    public let expansionText: String?

    /// The language (`/Lang` entry) for the element content.
    ///
    /// An RFC 3066 language tag (e.g., "en-US", "fr", "de-DE").
    public let language: String?

    /// Whether the element has alternative text.
    public var hasAltText: Bool {
        altText != nil && !(altText?.isEmpty ?? true)
    }

    /// Whether the element has actual text.
    public var hasActualText: Bool {
        actualText != nil && !(actualText?.isEmpty ?? true)
    }

    /// Whether the element has a language tag.
    public var hasLanguage: Bool {
        language != nil && !(language?.isEmpty ?? true)
    }

    // MARK: - Marked Content

    /// The marked content identifiers (MCID) associated with this element.
    ///
    /// These link the structure element to specific marked content sequences
    /// in the page content streams.
    public let markedContentIDs: [Int]

    /// The page reference for this element's content.
    ///
    /// The page number (1-based) where this element's content appears.
    public let pageNumber: Int?

    // MARK: - Attributes

    /// The element's attribute dictionary entries.
    ///
    /// Attributes provide additional information about the element, such as
    /// table cell spans, list numbering, or layout attributes.
    public let attributes: [String: COSValue]

    /// Whether the element has attributes.
    public var hasAttributes: Bool {
        !attributes.isEmpty
    }

    /// The element's class names (from `/C` entry).
    ///
    /// Class names reference attribute objects defined in the structure
    /// tree root's class map.
    public let classNames: [String]

    /// Whether the element has class names.
    public var hasClassNames: Bool {
        !classNames.isEmpty
    }

    // MARK: - Structure Nesting

    /// The revision number of this element (for incremental updates).
    public let revision: Int

    /// The element's ID string (from `/ID` entry), if present.
    public let elementID: String?

    /// Whether the element has an ID.
    public var hasElementID: Bool {
        elementID != nil
    }

    // MARK: - Namespace (PDF 2.0)

    /// The namespace URI for this element (PDF 2.0).
    public let namespaceURI: String?

    /// Whether the element has a namespace.
    public var hasNamespace: Bool {
        namespaceURI != nil
    }

    // MARK: - Initialization

    /// Creates a validated structure element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the structure element.
    ///   - objectKey: The object key for the structure element.
    ///   - context: Validation context.
    ///   - structureTypeName: The raw structure type name from the /S entry.
    ///   - structureType: The resolved structure element type.
    ///   - children: Child structure elements.
    ///   - altText: Alternative text for accessibility.
    ///   - actualText: Actual text replacement.
    ///   - expansionText: Expansion text for abbreviations.
    ///   - language: Language tag.
    ///   - markedContentIDs: Marked content identifiers.
    ///   - pageNumber: Page number for this element's content.
    ///   - attributes: Element attributes.
    ///   - classNames: Element class names.
    ///   - revision: Element revision number.
    ///   - elementID: Element ID string.
    ///   - namespaceURI: Namespace URI (PDF 2.0).
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        structureTypeName: String,
        structureType: StructureElementType? = nil,
        children: [ValidatedStructElem] = [],
        altText: String? = nil,
        actualText: String? = nil,
        expansionText: String? = nil,
        language: String? = nil,
        markedContentIDs: [Int] = [],
        pageNumber: Int? = nil,
        attributes: [String: COSValue] = [:],
        classNames: [String] = [],
        revision: Int = 0,
        elementID: String? = nil,
        namespaceURI: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .structureElement(structureTypeName)
        self.structureTypeName = structureTypeName
        self.structureType = structureType ?? StructureElementType(rawValue: structureTypeName)
        self.children = children
        self.altText = altText
        self.actualText = actualText
        self.expansionText = expansionText
        self.language = language
        self.markedContentIDs = markedContentIDs
        self.pageNumber = pageNumber
        self.attributes = attributes
        self.classNames = classNames
        self.revision = revision
        self.elementID = elementID
        self.namespaceURI = namespaceURI
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDStructElem"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "structureTypeName", "structureType", "childCount",
            "hasChildren", "altText", "actualText", "expansionText",
            "language", "hasAltText", "hasActualText", "hasLanguage",
            "markedContentIDs", "pageNumber", "hasAttributes",
            "hasClassNames", "revision", "elementID", "hasElementID",
            "namespaceURI", "hasNamespace"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "structureTypeName":
            return .string(structureTypeName)
        case "structureType":
            if let type = structureType {
                return .string(type.rawValue)
            }
            return .null
        case "childCount":
            return .integer(Int64(childCount))
        case "hasChildren":
            return .boolean(hasChildren)
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
        case "language":
            if let lang = language {
                return .string(lang)
            }
            return .null
        case "hasAltText":
            return .boolean(hasAltText)
        case "hasActualText":
            return .boolean(hasActualText)
        case "hasLanguage":
            return .boolean(hasLanguage)
        case "markedContentIDs":
            return .string(markedContentIDs.map(String.init).joined(separator: ","))
        case "pageNumber":
            if let page = pageNumber {
                return .integer(Int64(page))
            }
            return .null
        case "hasAttributes":
            return .boolean(hasAttributes)
        case "hasClassNames":
            return .boolean(hasClassNames)
        case "revision":
            return .integer(Int64(revision))
        case "elementID":
            if let eid = elementID {
                return .string(eid)
            }
            return .null
        case "hasElementID":
            return .boolean(hasElementID)
        case "namespaceURI":
            if let uri = namespaceURI {
                return .string(uri)
            }
            return .null
        case "hasNamespace":
            return .boolean(hasNamespace)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedStructElem, rhs: ValidatedStructElem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Computed Properties

extension ValidatedStructElem {

    /// Whether this element is a heading.
    public var isHeading: Bool {
        structureType?.isHeading ?? false
    }

    /// The heading level, if this element is a numbered heading.
    public var headingLevel: Int? {
        structureType?.headingLevel
    }

    /// Whether this element is a table component.
    public var isTableElement: Bool {
        structureType?.isTableElement ?? false
    }

    /// Whether this element is a list component.
    public var isListElement: Bool {
        structureType?.isListElement ?? false
    }

    /// Whether this element is a figure.
    public var isFigure: Bool {
        structureType == .figure
    }

    /// Whether this element requires alternative text for accessibility.
    public var requiresAltText: Bool {
        structureType?.requiresAltText ?? false
    }

    /// Whether this element has all required accessibility properties.
    ///
    /// An element is considered accessible if it has alternative text when
    /// required, and has a language tag or inherits one from an ancestor.
    public var isAccessible: Bool {
        if requiresAltText && !hasAltText && !hasActualText {
            return false
        }
        return true
    }

    /// Whether this element is a grouping element.
    public var isGrouping: Bool {
        structureType?.isGrouping ?? false
    }

    /// Whether this element is a content element.
    public var isContent: Bool {
        structureType?.isContent ?? false
    }

    /// Whether this element is an artifact.
    public var isArtifact: Bool {
        structureType == .artifact
    }

    /// Returns all descendant elements in depth-first order.
    public var allDescendants: [ValidatedStructElem] {
        var result: [ValidatedStructElem] = []
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
    public func descendants(ofType type: StructureElementType) -> [ValidatedStructElem] {
        allDescendants.filter { $0.structureType == type }
    }

    /// Returns a summary string describing this element.
    public var summary: String {
        var parts: [String] = [structureTypeName]
        if let type = structureType, type.rawValue != structureTypeName {
            parts.append("(\(type.rawValue))")
        }
        if hasAltText { parts.append("alt") }
        if hasLanguage { parts.append("lang=\(language ?? "")") }
        if hasChildren { parts.append("\(childCount) children") }
        return parts.joined(separator: " ")
    }
}

// MARK: - Factory Methods

extension ValidatedStructElem {

    /// Creates a minimal validated structure element for testing.
    ///
    /// - Parameters:
    ///   - typeName: The structure type name (e.g., "P", "H1").
    ///   - children: Child structure elements.
    ///   - altText: Alternative text.
    ///   - language: Language tag.
    /// - Returns: A minimal validated structure element.
    public static func minimal(
        typeName: String,
        children: [ValidatedStructElem] = [],
        altText: String? = nil,
        language: String? = nil
    ) -> ValidatedStructElem {
        ValidatedStructElem(
            structureTypeName: typeName,
            children: children,
            altText: altText,
            language: language
        )
    }

    /// Creates a heading element for testing.
    ///
    /// - Parameters:
    ///   - level: The heading level (1-6).
    ///   - children: Child elements.
    /// - Returns: A heading structure element.
    public static func heading(level: Int, children: [ValidatedStructElem] = []) -> ValidatedStructElem {
        let typeName = "H\(max(1, min(6, level)))"
        return ValidatedStructElem(
            structureTypeName: typeName,
            children: children
        )
    }

    /// Creates a paragraph element for testing.
    ///
    /// - Parameter altText: Alternative text, if any.
    /// - Returns: A paragraph structure element.
    public static func paragraph(altText: String? = nil) -> ValidatedStructElem {
        ValidatedStructElem(
            structureTypeName: "P",
            altText: altText
        )
    }

    /// Creates a figure element for testing.
    ///
    /// - Parameter altText: Alternative text for the figure.
    /// - Returns: A figure structure element.
    public static func figure(altText: String? = nil) -> ValidatedStructElem {
        ValidatedStructElem(
            structureTypeName: "Figure",
            altText: altText
        )
    }

    /// Creates a table element for testing.
    ///
    /// - Parameter rows: Table row child elements.
    /// - Returns: A table structure element.
    public static func table(rows: [ValidatedStructElem] = []) -> ValidatedStructElem {
        ValidatedStructElem(
            structureTypeName: "Table",
            children: rows
        )
    }

    /// Creates a list element for testing.
    ///
    /// - Parameter items: List item child elements.
    /// - Returns: A list structure element.
    public static func list(items: [ValidatedStructElem] = []) -> ValidatedStructElem {
        ValidatedStructElem(
            structureTypeName: "L",
            children: items
        )
    }
}
