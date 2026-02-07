import Foundation

// MARK: - SA Document

/// Top-level SA (Structured Accessibility) document representation.
///
/// `SADocument` wraps a `ValidatedDocument` and adds accessibility-specific
/// semantics for WCAG validation. It serves as the entry point for accessibility
/// analysis of a PDF document.
///
/// ## Key Properties
///
/// - **Document**: The underlying validated document
/// - **Pages**: SA page representations for accessibility analysis
/// - **Structure Root**: The SA structure tree root, if present
/// - **Language**: Document-level language for accessibility
/// - **Tagged Status**: Whether the document is properly tagged
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFSAPDFDocument` from veraPDF-validation's wcag-validation
/// module. In the Java codebase, this class wraps the GreenField PDF document
/// and provides accessibility-oriented access to document properties.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent WCAG validation
/// - References existing PD-layer types (ValidatedDocument, ValidatedPage)
/// - Computed properties for accessibility checks
public struct SADocument: SAObject {

    // MARK: - Properties

    /// Unique identifier for this SA document.
    public let id: UUID

    /// The underlying validated document.
    public let document: ValidatedDocument

    /// The SA pages within this document.
    public let pages: [SAPage]

    /// The SA structure tree root, if the document has a tagged structure.
    public let structureRoot: SAStructureRoot?

    // MARK: - Initialization

    /// Creates an SA document wrapping a validated document.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - document: The validated document to wrap.
    ///   - pages: The SA pages for accessibility analysis.
    ///   - structureRoot: The SA structure tree root, if present.
    public init(
        id: UUID = UUID(),
        document: ValidatedDocument,
        pages: [SAPage] = [],
        structureRoot: SAStructureRoot? = nil
    ) {
        self.id = id
        self.document = document
        self.pages = pages
        self.structureRoot = structureRoot
    }

    // MARK: - SAObject Conformance

    /// The SA object type name.
    public var saObjectType: String {
        SAObjectType.document.rawValue
    }

    /// The validation context for this SA document.
    public var validationContext: ObjectContext {
        .saDocument
    }

    /// Accessibility property names supported by this SA document.
    public var accessibilityPropertyNames: [String] {
        [
            "language", "isTagged", "isMarked", "hasStructTreeRoot",
            "pdfVersion", "pageCount", "hasMetadata", "hasOutlines",
            "hasSuspects", "isAccessible", "structureElementCount",
            "hasLanguage", "hasStructureRoot"
        ]
    }

    /// Returns the value of an accessibility property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func accessibilityProperty(named name: String) -> PropertyValue? {
        switch name {
        case "language":
            if let lang = document.language {
                return .string(lang)
            }
            return .null
        case "isTagged":
            return .boolean(document.isTagged)
        case "isMarked":
            return .boolean(document.isMarked)
        case "hasStructTreeRoot":
            return .boolean(document.hasStructTreeRoot)
        case "pdfVersion":
            return .string(document.pdfVersion)
        case "pageCount":
            return .integer(Int64(document.pageCount))
        case "hasMetadata":
            return .boolean(document.hasMetadata)
        case "hasOutlines":
            return .boolean(document.hasOutlines)
        case "hasSuspects":
            return .boolean(document.hasSuspects)
        case "isAccessible":
            return .boolean(document.isAccessible)
        case "structureElementCount":
            return .integer(Int64(document.structureElementCount))
        case "hasLanguage":
            return .boolean(document.language != nil)
        case "hasStructureRoot":
            return .boolean(structureRoot != nil)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: SADocument, rhs: SADocument) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Computed Properties

extension SADocument {

    /// Whether the document has a language tag set at the document level.
    public var hasLanguage: Bool {
        document.language != nil
    }

    /// The document language, if set.
    public var language: String? {
        document.language
    }

    /// Whether the document is tagged (marked with a structure tree).
    public var isTagged: Bool {
        document.isTagged
    }

    /// The PDF version string.
    public var pdfVersion: String {
        document.pdfVersion
    }

    /// The number of pages in the document.
    public var pageCount: Int {
        document.pageCount
    }

    /// Whether the document has a structure tree root for accessibility.
    public var hasStructureRoot: Bool {
        structureRoot != nil
    }

    /// Whether the document meets basic accessibility requirements.
    ///
    /// A document is considered basically accessible if it is tagged,
    /// has a language tag, and has a structure tree root.
    public var meetsBasicAccessibility: Bool {
        isTagged && hasLanguage && hasStructureRoot
    }

    /// The number of SA pages.
    public var saPageCount: Int {
        pages.count
    }

    /// Returns a summary string describing the SA document.
    public var summary: String {
        var parts: [String] = ["SADocument"]
        parts.append("PDF \(pdfVersion)")
        parts.append("\(pageCount) pages")
        if isTagged { parts.append("tagged") }
        if hasLanguage { parts.append("lang=\(language ?? "")") }
        if hasStructureRoot { parts.append("structured") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension SADocument {

    /// Creates a minimal SA document for testing.
    ///
    /// - Parameters:
    ///   - pdfVersion: PDF version string.
    ///   - pageCount: Number of pages.
    ///   - isTagged: Whether the document is tagged.
    ///   - language: Document language.
    /// - Returns: A minimal SA document.
    public static func minimal(
        pdfVersion: String = "1.7",
        pageCount: Int = 1,
        isTagged: Bool = false,
        language: String? = nil
    ) -> SADocument {
        let doc = ValidatedDocument.minimal(
            pdfVersion: pdfVersion,
            pageCount: pageCount,
            isTagged: isTagged,
            language: language
        )
        return SADocument(document: doc)
    }

    /// Creates a fully accessible SA document for testing.
    ///
    /// - Parameters:
    ///   - pdfVersion: PDF version string.
    ///   - pageCount: Number of pages.
    ///   - language: Document language.
    /// - Returns: A fully accessible SA document.
    public static func accessible(
        pdfVersion: String = "2.0",
        pageCount: Int = 1,
        language: String = "en"
    ) -> SADocument {
        let doc = ValidatedDocument.minimal(
            pdfVersion: pdfVersion,
            pageCount: pageCount,
            isTagged: true,
            language: language
        )
        let root = SAStructureRoot.minimal()
        return SADocument(
            document: doc,
            structureRoot: root
        )
    }
}
