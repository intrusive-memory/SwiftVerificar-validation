import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Outline

/// A validation wrapper for a PDF outline (bookmark) entry.
///
/// Outlines provide a hierarchical, tree-structured table of contents
/// for the document. Each outline item can have a title, a destination
/// or action, and child items.
///
/// ## Key Properties
///
/// - **Title**: The display text for the outline entry
/// - **Destination**: Where clicking the entry navigates
/// - **Action**: An alternative to destination for more complex behaviors
/// - **Children**: Sub-entries in the hierarchy
/// - **Flags**: Bold, italic formatting
///
/// ## Validation Rules
///
/// - **PDF/A**: Outline items should have valid destinations or actions.
/// - **PDF/UA**: Outlines must accurately reflect the document structure.
///   The outline tree should correspond to the structure tree.
/// - **PDF/UA-1**: If a document has outlines, they must be accessible
///   and represent the document's logical structure.
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDOutline` and `GFPDOutlineItem` from
/// veraPDF-validation.
public struct ValidatedOutline: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary for the outline entry.
    public let cosDictionary: COSValue?

    /// The object key for the outline entry, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Outline Properties

    /// The title text of the outline entry (`/Title` entry).
    ///
    /// This is the text displayed in the bookmarks panel.
    public let title: String?

    /// Whether this entry has a destination (`/Dest` entry).
    public let hasDestination: Bool

    /// The destination name, if this is a named destination.
    public let destinationName: String?

    /// Whether this entry has an action (`/A` entry).
    public let hasAction: Bool

    /// The action type, if an action is present.
    public let actionType: String?

    /// Whether this entry has child entries.
    public let hasChildren: Bool

    /// The number of child entries at this level.
    public let childCount: Int

    /// The total number of visible descendant entries (`/Count` entry).
    ///
    /// A negative value means the entry is closed; the absolute value
    /// is the count of descendants.
    public let totalCount: Int?

    /// Whether this outline item is initially open (expanded).
    public let isOpen: Bool

    /// Whether this is the root outline node (the `/Outlines` dictionary).
    public let isRoot: Bool

    /// The nesting depth of this outline entry (0 for top-level items).
    public let depth: Int

    // MARK: - Text Properties

    /// Whether the outline item is bold (`/F` bit 0).
    public let isBold: Bool

    /// Whether the outline item is italic (`/F` bit 1).
    public let isItalic: Bool

    /// Whether the outline item has a color (`/C` entry).
    public let hasColor: Bool

    /// The number of color components in the text color.
    public let colorComponentCount: Int

    // MARK: - Structure Properties

    /// The structure element identifier this outline links to, if any.
    ///
    /// PDF/UA recommends that outlines correspond to structure elements.
    public let structureElementId: String?

    // MARK: - Initialization

    /// Creates a validated outline entry.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the outline entry.
    ///   - objectKey: The object key.
    ///   - context: Validation context.
    ///   - title: The outline title text.
    ///   - hasDestination: Whether a destination exists.
    ///   - destinationName: Named destination, if applicable.
    ///   - hasAction: Whether an action exists.
    ///   - actionType: The action type string.
    ///   - hasChildren: Whether child entries exist.
    ///   - childCount: Number of child entries.
    ///   - totalCount: Total visible descendant count.
    ///   - isOpen: Whether the entry is initially expanded.
    ///   - isRoot: Whether this is the root outline node.
    ///   - depth: The nesting depth.
    ///   - isBold: Whether the text is bold.
    ///   - isItalic: Whether the text is italic.
    ///   - hasColor: Whether a text color is set.
    ///   - colorComponentCount: Number of color components.
    ///   - structureElementId: Associated structure element ID.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = ObjectContext(location: "Outline"),
        title: String? = nil,
        hasDestination: Bool = false,
        destinationName: String? = nil,
        hasAction: Bool = false,
        actionType: String? = nil,
        hasChildren: Bool = false,
        childCount: Int = 0,
        totalCount: Int? = nil,
        isOpen: Bool = false,
        isRoot: Bool = false,
        depth: Int = 0,
        isBold: Bool = false,
        isItalic: Bool = false,
        hasColor: Bool = false,
        colorComponentCount: Int = 0,
        structureElementId: String? = nil
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.title = title
        self.hasDestination = hasDestination
        self.destinationName = destinationName
        self.hasAction = hasAction
        self.actionType = actionType
        self.hasChildren = hasChildren
        self.childCount = childCount
        self.totalCount = totalCount
        self.isOpen = isOpen
        self.isRoot = isRoot
        self.depth = depth
        self.isBold = isBold
        self.isItalic = isItalic
        self.hasColor = hasColor
        self.colorComponentCount = colorComponentCount
        self.structureElementId = structureElementId
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        isRoot ? "PDOutlines" : "PDOutlineItem"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "title", "hasDestination", "destinationName",
            "hasAction", "actionType",
            "hasChildren", "childCount", "totalCount",
            "isOpen", "isRoot", "depth",
            "isBold", "isItalic", "hasColor", "colorComponentCount",
            "structureElementId",
            "hasTitle", "hasNavigation",
            "hasStructureLink", "isLeaf"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "title":
            if let t = title { return .string(t) }
            return .null
        case "hasDestination":
            return .boolean(hasDestination)
        case "destinationName":
            if let dn = destinationName { return .string(dn) }
            return .null
        case "hasAction":
            return .boolean(hasAction)
        case "actionType":
            if let at = actionType { return .string(at) }
            return .null
        case "hasChildren":
            return .boolean(hasChildren)
        case "childCount":
            return .integer(Int64(childCount))
        case "totalCount":
            if let tc = totalCount { return .integer(Int64(tc)) }
            return .null
        case "isOpen":
            return .boolean(isOpen)
        case "isRoot":
            return .boolean(isRoot)
        case "depth":
            return .integer(Int64(depth))
        case "isBold":
            return .boolean(isBold)
        case "isItalic":
            return .boolean(isItalic)
        case "hasColor":
            return .boolean(hasColor)
        case "colorComponentCount":
            return .integer(Int64(colorComponentCount))
        case "structureElementId":
            if let se = structureElementId { return .string(se) }
            return .null
        case "hasTitle":
            return .boolean(hasTitle)
        case "hasNavigation":
            return .boolean(hasNavigation)
        case "hasStructureLink":
            return .boolean(hasStructureLink)
        case "isLeaf":
            return .boolean(isLeaf)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedOutline, rhs: ValidatedOutline) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Computed Properties

extension ValidatedOutline {

    /// Whether this outline entry has a title.
    public var hasTitle: Bool {
        guard let t = title else { return false }
        return !t.isEmpty
    }

    /// Whether this outline entry has navigation (destination or action).
    public var hasNavigation: Bool {
        hasDestination || hasAction
    }

    /// Whether this outline entry links to a structure element.
    public var hasStructureLink: Bool {
        structureElementId != nil
    }

    /// Whether this is a leaf node (no children).
    public var isLeaf: Bool {
        !hasChildren || childCount == 0
    }

    /// Whether this outline entry is valid for accessibility.
    ///
    /// For PDF/UA, outline items should have both a title and navigation.
    public var isAccessible: Bool {
        hasTitle && hasNavigation
    }

    /// The absolute count of visible descendants.
    public var visibleDescendantCount: Int {
        guard let tc = totalCount else { return 0 }
        return abs(tc)
    }

    /// Returns a summary string describing the outline entry.
    public var summary: String {
        var parts: [String] = []
        if isRoot {
            parts.append("Outlines root")
            parts.append("\(childCount) children")
        } else {
            if let t = title { parts.append("'\(t)'") }
            parts.append("depth=\(depth)")
            if hasDestination { parts.append("has dest") }
            if hasAction { parts.append("has action") }
            if hasChildren { parts.append("\(childCount) children") }
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedOutline {

    /// Creates a root outline node for testing.
    ///
    /// - Parameter childCount: Number of top-level outline items.
    /// - Returns: A root outline node.
    public static func root(childCount: Int = 3) -> ValidatedOutline {
        ValidatedOutline(
            hasChildren: childCount > 0,
            childCount: childCount,
            totalCount: childCount,
            isRoot: true
        )
    }

    /// Creates an outline item for testing.
    ///
    /// - Parameters:
    ///   - title: The bookmark title.
    ///   - depth: The nesting depth.
    ///   - hasDestination: Whether a destination exists.
    /// - Returns: An outline item.
    public static func item(
        title: String = "Chapter 1",
        depth: Int = 0,
        hasDestination: Bool = true
    ) -> ValidatedOutline {
        ValidatedOutline(
            title: title,
            hasDestination: hasDestination,
            depth: depth
        )
    }

    /// Creates an outline item with children for testing.
    ///
    /// - Parameters:
    ///   - title: The bookmark title.
    ///   - childCount: Number of children.
    ///   - isOpen: Whether initially expanded.
    /// - Returns: An outline item with children.
    public static func parent(
        title: String = "Part 1",
        childCount: Int = 3,
        isOpen: Bool = true
    ) -> ValidatedOutline {
        ValidatedOutline(
            title: title,
            hasDestination: true,
            hasChildren: true,
            childCount: childCount,
            totalCount: isOpen ? childCount : -childCount,
            isOpen: isOpen
        )
    }
}
