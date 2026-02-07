import Foundation

// MARK: - SA Page

/// SA (Structured Accessibility) page representation.
///
/// `SAPage` wraps a `ValidatedPage` and adds accessibility-relevant page
/// properties for WCAG validation. It provides access to page-level
/// accessibility information such as content structure, annotations,
/// and tagged content regions.
///
/// ## Key Properties
///
/// - **Page**: The underlying validated page
/// - **Page Number**: The 1-based page index
/// - **Annotations**: Count and presence of annotations
/// - **Content Streams**: Whether the page has content
/// - **Structure Nodes**: SA nodes associated with this page
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSAPage` from veraPDF-validation's wcag-validation module.
/// In the Java codebase, this class provides page-level accessibility context
/// for WCAG checking algorithms.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - References existing ValidatedPage from the PD layer
/// - Computed accessibility properties derived from the validated page
public struct SAPage: SAObject {

    // MARK: - Properties

    /// Unique identifier for this SA page.
    public let id: UUID

    /// The underlying validated page.
    public let page: ValidatedPage

    /// The SA nodes (content structure nodes) on this page.
    ///
    /// These represent the accessibility tree nodes that have content
    /// appearing on this page.
    public let nodes: [SANode]

    // MARK: - Initialization

    /// Creates an SA page wrapping a validated page.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - page: The validated page to wrap.
    ///   - nodes: The SA nodes on this page.
    public init(
        id: UUID = UUID(),
        page: ValidatedPage,
        nodes: [SANode] = []
    ) {
        self.id = id
        self.page = page
        self.nodes = nodes
    }

    // MARK: - SAObject Conformance

    /// The SA object type name.
    public var saObjectType: String {
        SAObjectType.page.rawValue
    }

    /// The validation context for this SA page.
    public var validationContext: ObjectContext {
        .saPage(page.pageNumber)
    }

    /// Accessibility property names supported by this SA page.
    public var accessibilityPropertyNames: [String] {
        [
            "pageNumber", "hasContentStreams", "hasAnnotations",
            "annotationCount", "hasResources", "rotation",
            "mediaBoxWidth", "mediaBoxHeight", "nodeCount",
            "hasNodes", "hasTransparencyGroup"
        ]
    }

    /// Returns the value of an accessibility property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        switch name {
        case "pageNumber":
            return .integer(Int64(page.pageNumber))
        case "hasContentStreams":
            return .boolean(page.hasContentStreams)
        case "hasAnnotations":
            return .boolean(page.hasAnnotations)
        case "annotationCount":
            return .integer(Int64(page.annotationCount))
        case "hasResources":
            return .boolean(page.hasResources)
        case "rotation":
            return .integer(Int64(page.rotation))
        case "mediaBoxWidth":
            return .real(page.mediaBox.width)
        case "mediaBoxHeight":
            return .real(page.mediaBox.height)
        case "nodeCount":
            return .integer(Int64(nodes.count))
        case "hasNodes":
            return .boolean(!nodes.isEmpty)
        case "hasTransparencyGroup":
            return .boolean(page.hasTransparencyGroup)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SAPage, rhs: SAPage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Computed Properties

extension SAPage {

    /// The 1-based page number.
    public var pageNumber: Int {
        page.pageNumber
    }

    /// Whether the page has any content streams.
    public var hasContent: Bool {
        page.hasContentStreams
    }

    /// Whether the page has annotations.
    public var hasAnnotations: Bool {
        page.hasAnnotations
    }

    /// The number of annotations on this page.
    public var annotationCount: Int {
        page.annotationCount
    }

    /// The number of SA nodes on this page.
    public var nodeCount: Int {
        nodes.count
    }

    /// Whether the page has SA nodes.
    public var hasNodes: Bool {
        !nodes.isEmpty
    }

    /// The effective page width in points.
    public var effectiveWidth: Double {
        page.effectiveWidth
    }

    /// The effective page height in points.
    public var effectiveHeight: Double {
        page.effectiveHeight
    }

    /// Returns a summary string describing this SA page.
    public var summary: String {
        var parts: [String] = ["SAPage \(pageNumber)"]
        parts.append("\(Int(page.mediaBox.width))x\(Int(page.mediaBox.height))")
        if hasAnnotations { parts.append("\(annotationCount) annots") }
        if hasNodes { parts.append("\(nodeCount) nodes") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension SAPage {

    /// Creates a minimal SA page for testing.
    ///
    /// - Parameters:
    ///   - pageNumber: The page number (1-based).
    ///   - nodes: SA nodes on this page.
    /// - Returns: A minimal SA page.
    public static func minimal(
        pageNumber: Int = 1,
        nodes: [SANode] = []
    ) -> SAPage {
        let validatedPage = ValidatedPage.minimal(pageNumber: pageNumber)
        return SAPage(page: validatedPage, nodes: nodes)
    }
}
