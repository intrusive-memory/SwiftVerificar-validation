import Foundation
#if canImport(SwiftVerificarParser)
import SwiftVerificarParser
#endif

// MARK: - Validated Document

/// A validation wrapper for a PDF document.
///
/// This struct provides access to document-level properties and structures
/// for PDF/A, PDF/UA, and other conformance validation. It wraps the parsed
/// PDF document and exposes its components in a validation-friendly manner.
///
/// ## Key Properties
///
/// - **Catalog**: The document catalog dictionary
/// - **Pages**: Collection of validated pages
/// - **Metadata**: XMP metadata stream
/// - **Info Dictionary**: Document information dictionary
/// - **Structure Tree**: Tagged structure for accessibility
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDDocument` from veraPDF-validation, which serves as
/// the entry point for document validation.
///
/// ## Swift Adaptations
///
/// - Value type (struct) for thread safety
/// - Sendable for concurrent validation
/// - Computed properties derived from the COS dictionary
public struct ValidatedDocument: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The underlying COS dictionary (the trailer's Root/Catalog).
    public let cosDictionary: COSValue?

    /// The object key for the catalog, if indirect.
    public let objectKey: COSObjectKey?

    /// The object context for validation reporting.
    public let validationContext: ObjectContext

    // MARK: - Document Metadata

    /// The PDF version string (e.g., "1.4", "1.7", "2.0").
    public let pdfVersion: String

    /// Whether the document header version matches the catalog version.
    public let versionMismatch: Bool

    /// The number of pages in the document.
    public let pageCount: Int

    /// Whether the document is linearized (web-optimized).
    public let isLinearized: Bool

    /// Whether the document is encrypted.
    public let isEncrypted: Bool

    /// The encryption filter name, if encrypted.
    public let encryptionFilter: ASAtom?

    // MARK: - Document Structure

    /// Whether the document contains a MarkInfo dictionary.
    public let hasMarkInfo: Bool

    /// Whether the document is marked as tagged (MarkInfo/Marked = true).
    public let isMarked: Bool

    /// Whether the document contains a StructTreeRoot.
    public let hasStructTreeRoot: Bool

    /// Whether the document contains an Outlines dictionary.
    public let hasOutlines: Bool

    /// Whether the document contains an AcroForm dictionary.
    public let hasAcroForm: Bool

    /// Whether the document contains metadata stream.
    public let hasMetadata: Bool

    /// Whether the document contains OutputIntents.
    public let hasOutputIntents: Bool

    /// The number of output intents in the document.
    public let outputIntentCount: Int

    // MARK: - Language and Accessibility

    /// The document language (Lang entry from the catalog).
    public let language: String?

    /// Whether the document's MarkInfo has Suspects = true.
    public let hasSuspects: Bool

    /// The number of structure elements in the document.
    public let structureElementCount: Int

    // MARK: - Pages

    /// The validated pages within this document.
    public let pages: [ValidatedPage]

    // MARK: - Initialization

    /// Creates a validated document.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the catalog.
    ///   - objectKey: The object key for the catalog.
    ///   - context: Validation context.
    ///   - pdfVersion: PDF version string.
    ///   - versionMismatch: Whether header and catalog versions differ.
    ///   - pageCount: Number of pages.
    ///   - isLinearized: Whether the document is linearized.
    ///   - isEncrypted: Whether the document is encrypted.
    ///   - encryptionFilter: Encryption filter name.
    ///   - hasMarkInfo: Whether MarkInfo exists.
    ///   - isMarked: Whether marked as tagged.
    ///   - hasStructTreeRoot: Whether a StructTreeRoot exists.
    ///   - hasOutlines: Whether outlines exist.
    ///   - hasAcroForm: Whether an AcroForm exists.
    ///   - hasMetadata: Whether metadata stream exists.
    ///   - hasOutputIntents: Whether output intents exist.
    ///   - outputIntentCount: Number of output intents.
    ///   - language: Document language.
    ///   - hasSuspects: Whether suspects are flagged.
    ///   - structureElementCount: Number of structure elements.
    ///   - pages: Validated pages.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext = .document,
        pdfVersion: String = "1.7",
        versionMismatch: Bool = false,
        pageCount: Int = 0,
        isLinearized: Bool = false,
        isEncrypted: Bool = false,
        encryptionFilter: ASAtom? = nil,
        hasMarkInfo: Bool = false,
        isMarked: Bool = false,
        hasStructTreeRoot: Bool = false,
        hasOutlines: Bool = false,
        hasAcroForm: Bool = false,
        hasMetadata: Bool = false,
        hasOutputIntents: Bool = false,
        outputIntentCount: Int = 0,
        language: String? = nil,
        hasSuspects: Bool = false,
        structureElementCount: Int = 0,
        pages: [ValidatedPage] = []
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context
        self.pdfVersion = pdfVersion
        self.versionMismatch = versionMismatch
        self.pageCount = pageCount
        self.isLinearized = isLinearized
        self.isEncrypted = isEncrypted
        self.encryptionFilter = encryptionFilter
        self.hasMarkInfo = hasMarkInfo
        self.isMarked = isMarked
        self.hasStructTreeRoot = hasStructTreeRoot
        self.hasOutlines = hasOutlines
        self.hasAcroForm = hasAcroForm
        self.hasMetadata = hasMetadata
        self.hasOutputIntents = hasOutputIntents
        self.outputIntentCount = outputIntentCount
        self.language = language
        self.hasSuspects = hasSuspects
        self.structureElementCount = structureElementCount
        self.pages = pages
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDDocument"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "pdfVersion", "versionMismatch", "pageCount",
            "isLinearized", "isEncrypted", "encryptionFilter",
            "hasMarkInfo", "isMarked", "hasStructTreeRoot",
            "hasOutlines", "hasAcroForm", "hasMetadata",
            "hasOutputIntents", "outputIntentCount",
            "language", "hasSuspects", "structureElementCount"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "pdfVersion":
            return .string(pdfVersion)
        case "versionMismatch":
            return .boolean(versionMismatch)
        case "pageCount":
            return .integer(Int64(pageCount))
        case "isLinearized":
            return .boolean(isLinearized)
        case "isEncrypted":
            return .boolean(isEncrypted)
        case "encryptionFilter":
            if let filter = encryptionFilter {
                return .name(filter.stringValue)
            }
            return .null
        case "hasMarkInfo":
            return .boolean(hasMarkInfo)
        case "isMarked":
            return .boolean(isMarked)
        case "hasStructTreeRoot":
            return .boolean(hasStructTreeRoot)
        case "hasOutlines":
            return .boolean(hasOutlines)
        case "hasAcroForm":
            return .boolean(hasAcroForm)
        case "hasMetadata":
            return .boolean(hasMetadata)
        case "hasOutputIntents":
            return .boolean(hasOutputIntents)
        case "outputIntentCount":
            return .integer(Int64(outputIntentCount))
        case "language":
            if let lang = language {
                return .string(lang)
            }
            return .null
        case "hasSuspects":
            return .boolean(hasSuspects)
        case "structureElementCount":
            return .integer(Int64(structureElementCount))
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedDocument, rhs: ValidatedDocument) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Convenience Computed Properties

extension ValidatedDocument {

    /// Whether the document is tagged (has both MarkInfo and StructTreeRoot).
    public var isTagged: Bool {
        isMarked && hasStructTreeRoot
    }

    /// Whether the document is accessible (tagged with language set).
    public var isAccessible: Bool {
        isTagged && language != nil
    }

    /// The major PDF version number.
    public var majorVersion: Int {
        let components = pdfVersion.split(separator: ".")
        guard let first = components.first, let major = Int(first) else {
            return 1
        }
        return major
    }

    /// The minor PDF version number.
    public var minorVersion: Int {
        let components = pdfVersion.split(separator: ".")
        guard components.count > 1, let minor = Int(components[1]) else {
            return 0
        }
        return minor
    }

    /// Whether the document uses PDF 2.0 or later.
    public var isPDF2: Bool {
        majorVersion >= 2
    }

    /// Returns a summary string describing the document.
    public var summary: String {
        var parts: [String] = ["PDF \(pdfVersion)"]
        parts.append("\(pageCount) pages")
        if isTagged { parts.append("tagged") }
        if isEncrypted { parts.append("encrypted") }
        if isLinearized { parts.append("linearized") }
        if let lang = language { parts.append("lang=\(lang)") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Factory Methods

extension ValidatedDocument {

    /// Creates a minimal validated document for testing.
    ///
    /// - Parameters:
    ///   - pdfVersion: PDF version string.
    ///   - pageCount: Number of pages.
    ///   - isTagged: Whether the document is tagged.
    ///   - language: Document language.
    /// - Returns: A minimal validated document.
    public static func minimal(
        pdfVersion: String = "1.7",
        pageCount: Int = 1,
        isTagged: Bool = false,
        language: String? = nil
    ) -> ValidatedDocument {
        ValidatedDocument(
            pdfVersion: pdfVersion,
            pageCount: pageCount,
            hasMarkInfo: isTagged,
            isMarked: isTagged,
            hasStructTreeRoot: isTagged,
            language: language
        )
    }
}
