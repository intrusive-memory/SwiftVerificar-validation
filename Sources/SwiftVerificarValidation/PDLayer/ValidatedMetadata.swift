import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Validated Metadata

/// Validation wrapper for XMP and document metadata in PDF documents.
///
/// PDF documents contain metadata in two forms:
/// 1. The document information dictionary (traditional, pre-PDF 1.4)
/// 2. XMP metadata stream (XML-based, PDF 1.4+)
///
/// PDF/A and PDF/UA require these to be synchronized, and the XMP metadata
/// must conform to specific schema requirements.
///
/// ## Key Properties
///
/// - **Conformance**: Whether the metadata conforms to PDF/A or PDF/UA requirements
/// - **Schema Correctness**: Whether all XMP schemas are valid
/// - **Synchronization**: Whether XMP and Info dictionary values agree
/// - **PDF/A Identification**: The pdfaid schema values for PDF/A identification
///
/// ## Validation Rules
///
/// Metadata is checked for:
/// - XMP well-formedness (valid XML)
/// - Required XMP schemas present (dc, xmp, pdfaid for PDF/A)
/// - Property value synchronization between XMP and Info dictionary
/// - PDF/A identification schema correctness
/// - PDF/UA identification schema correctness
/// - Date format compliance
/// - Extension schema correctness
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFPDMetadata` from veraPDF-validation.
public struct ValidatedMetadata: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for the metadata stream.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    // MARK: - XMP Properties

    /// Whether the XMP metadata stream is well-formed XML.
    public let isWellFormed: Bool

    /// The size of the XMP metadata in bytes.
    public let dataSize: Int

    /// Whether the XMP metadata contains the required `x:xmpmeta` wrapper.
    public let hasXMPMetaWrapper: Bool

    /// The XMP toolkit version string from the `x:xmpmeta` element.
    public let xmpToolkitVersion: String?

    // MARK: - Schema Presence

    /// Whether the Dublin Core (dc:) schema is present.
    public let hasDublinCoreSchema: Bool

    /// Whether the XMP Basic (xmp:) schema is present.
    public let hasXMPBasicSchema: Bool

    /// Whether the Adobe PDF (pdf:) schema is present.
    public let hasAdobePDFSchema: Bool

    /// Whether the PDF/A identification (pdfaid:) schema is present.
    public let hasPDFAIdSchema: Bool

    /// Whether the PDF/UA identification (pdfuaid:) schema is present.
    public let hasPDFUAIdSchema: Bool

    /// Whether extension schemas are present.
    public let hasExtensionSchemas: Bool

    /// The total number of XMP schemas present.
    public let schemaCount: Int

    // MARK: - PDF/A Identification

    /// The PDF/A part number from pdfaid:part (e.g., 1, 2, 3, 4).
    public let pdfaPart: Int?

    /// The PDF/A conformance level from pdfaid:conformance (e.g., "A", "B", "U").
    public let pdfaConformance: String?

    /// The PDF/A amendment from pdfaid:amd.
    public let pdfaAmendment: String?

    // MARK: - PDF/UA Identification

    /// The PDF/UA part number from pdfuaid:part (e.g., 1, 2).
    public let pdfuaPart: Int?

    // MARK: - Synchronization Properties

    /// Whether the dc:title matches the Info dictionary Title.
    public let isTitleSynchronized: Bool

    /// Whether the dc:creator matches the Info dictionary Author.
    public let isAuthorSynchronized: Bool

    /// Whether the dc:description matches the Info dictionary Subject.
    public let isSubjectSynchronized: Bool

    /// Whether the pdf:Keywords matches the Info dictionary Keywords.
    public let isKeywordsSynchronized: Bool

    /// Whether the pdf:Producer matches the Info dictionary Producer.
    public let isProducerSynchronized: Bool

    /// Whether the xmp:CreatorTool matches the Info dictionary Creator.
    public let isCreatorToolSynchronized: Bool

    /// Whether the xmp:CreateDate matches the Info dictionary CreationDate.
    public let isCreateDateSynchronized: Bool

    /// Whether the xmp:ModifyDate matches the Info dictionary ModDate.
    public let isModDateSynchronized: Bool

    // MARK: - Validation Properties

    /// Whether all required schemas for PDF/A are present.
    public let hasAllRequiredPDFASchemas: Bool

    /// Whether the extension schemas are properly defined.
    public let hasValidExtensionSchemas: Bool

    /// The number of synchronization issues (mismatches between XMP and Info dictionary).
    public var synchronizationIssueCount: Int {
        var count = 0
        if !isTitleSynchronized { count += 1 }
        if !isAuthorSynchronized { count += 1 }
        if !isSubjectSynchronized { count += 1 }
        if !isKeywordsSynchronized { count += 1 }
        if !isProducerSynchronized { count += 1 }
        if !isCreatorToolSynchronized { count += 1 }
        if !isCreateDateSynchronized { count += 1 }
        if !isModDateSynchronized { count += 1 }
        return count
    }

    /// Whether all metadata properties are synchronized.
    public var isFullySynchronized: Bool {
        synchronizationIssueCount == 0
    }

    /// Whether the PDF/A identification is complete.
    ///
    /// Requires both pdfaid:part and pdfaid:conformance to be present.
    public var hasPDFAIdentification: Bool {
        pdfaPart != nil && pdfaConformance != nil
    }

    /// Whether the PDF/UA identification is complete.
    public var hasPDFUAIdentification: Bool {
        pdfuaPart != nil
    }

    /// Whether the metadata has non-zero size.
    public var hasData: Bool {
        dataSize > 0
    }

    /// Whether the metadata conforms to PDF/A requirements.
    ///
    /// Requires: well-formed XMP, required schemas present,
    /// PDF/A identification present, all properties synchronized.
    public var isPDFACompliant: Bool {
        isWellFormed &&
        hasAllRequiredPDFASchemas &&
        hasPDFAIdentification &&
        isFullySynchronized &&
        hasValidExtensionSchemas
    }

    // MARK: - Initialization

    /// Creates a validated metadata wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the metadata stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - isWellFormed: Whether the XMP is well-formed XML.
    ///   - dataSize: The metadata size in bytes.
    ///   - hasXMPMetaWrapper: Whether the xmpmeta wrapper is present.
    ///   - xmpToolkitVersion: The toolkit version string.
    ///   - hasDublinCoreSchema: Whether dc: schema is present.
    ///   - hasXMPBasicSchema: Whether xmp: schema is present.
    ///   - hasAdobePDFSchema: Whether pdf: schema is present.
    ///   - hasPDFAIdSchema: Whether pdfaid: schema is present.
    ///   - hasPDFUAIdSchema: Whether pdfuaid: schema is present.
    ///   - hasExtensionSchemas: Whether extension schemas are present.
    ///   - schemaCount: The total number of schemas.
    ///   - pdfaPart: The PDF/A part number.
    ///   - pdfaConformance: The PDF/A conformance level.
    ///   - pdfaAmendment: The PDF/A amendment.
    ///   - pdfuaPart: The PDF/UA part number.
    ///   - isTitleSynchronized: Whether title is synchronized.
    ///   - isAuthorSynchronized: Whether author is synchronized.
    ///   - isSubjectSynchronized: Whether subject is synchronized.
    ///   - isKeywordsSynchronized: Whether keywords are synchronized.
    ///   - isProducerSynchronized: Whether producer is synchronized.
    ///   - isCreatorToolSynchronized: Whether creator tool is synchronized.
    ///   - isCreateDateSynchronized: Whether creation date is synchronized.
    ///   - isModDateSynchronized: Whether modification date is synchronized.
    ///   - hasAllRequiredPDFASchemas: Whether all required PDF/A schemas are present.
    ///   - hasValidExtensionSchemas: Whether extension schemas are valid.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        isWellFormed: Bool = true,
        dataSize: Int = 0,
        hasXMPMetaWrapper: Bool = true,
        xmpToolkitVersion: String? = nil,
        hasDublinCoreSchema: Bool = false,
        hasXMPBasicSchema: Bool = false,
        hasAdobePDFSchema: Bool = false,
        hasPDFAIdSchema: Bool = false,
        hasPDFUAIdSchema: Bool = false,
        hasExtensionSchemas: Bool = false,
        schemaCount: Int = 0,
        pdfaPart: Int? = nil,
        pdfaConformance: String? = nil,
        pdfaAmendment: String? = nil,
        pdfuaPart: Int? = nil,
        isTitleSynchronized: Bool = true,
        isAuthorSynchronized: Bool = true,
        isSubjectSynchronized: Bool = true,
        isKeywordsSynchronized: Bool = true,
        isProducerSynchronized: Bool = true,
        isCreatorToolSynchronized: Bool = true,
        isCreateDateSynchronized: Bool = true,
        isModDateSynchronized: Bool = true,
        hasAllRequiredPDFASchemas: Bool = false,
        hasValidExtensionSchemas: Bool = true
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? .metadata
        self.isWellFormed = isWellFormed
        self.dataSize = dataSize
        self.hasXMPMetaWrapper = hasXMPMetaWrapper
        self.xmpToolkitVersion = xmpToolkitVersion
        self.hasDublinCoreSchema = hasDublinCoreSchema
        self.hasXMPBasicSchema = hasXMPBasicSchema
        self.hasAdobePDFSchema = hasAdobePDFSchema
        self.hasPDFAIdSchema = hasPDFAIdSchema
        self.hasPDFUAIdSchema = hasPDFUAIdSchema
        self.hasExtensionSchemas = hasExtensionSchemas
        self.schemaCount = schemaCount
        self.pdfaPart = pdfaPart
        self.pdfaConformance = pdfaConformance
        self.pdfaAmendment = pdfaAmendment
        self.pdfuaPart = pdfuaPart
        self.isTitleSynchronized = isTitleSynchronized
        self.isAuthorSynchronized = isAuthorSynchronized
        self.isSubjectSynchronized = isSubjectSynchronized
        self.isKeywordsSynchronized = isKeywordsSynchronized
        self.isProducerSynchronized = isProducerSynchronized
        self.isCreatorToolSynchronized = isCreatorToolSynchronized
        self.isCreateDateSynchronized = isCreateDateSynchronized
        self.isModDateSynchronized = isModDateSynchronized
        self.hasAllRequiredPDFASchemas = hasAllRequiredPDFASchemas
        self.hasValidExtensionSchemas = hasValidExtensionSchemas
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "PDMetadata"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "isWellFormed", "dataSize", "hasXMPMetaWrapper", "xmpToolkitVersion",
            "hasDublinCoreSchema", "hasXMPBasicSchema", "hasAdobePDFSchema",
            "hasPDFAIdSchema", "hasPDFUAIdSchema", "hasExtensionSchemas", "schemaCount",
            "pdfaPart", "pdfaConformance", "pdfaAmendment", "pdfuaPart",
            "isTitleSynchronized", "isAuthorSynchronized", "isSubjectSynchronized",
            "isKeywordsSynchronized", "isProducerSynchronized",
            "isCreatorToolSynchronized", "isCreateDateSynchronized", "isModDateSynchronized",
            "hasAllRequiredPDFASchemas", "hasValidExtensionSchemas",
            "synchronizationIssueCount", "isFullySynchronized",
            "hasPDFAIdentification", "hasPDFUAIdentification",
            "hasData", "isPDFACompliant"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "isWellFormed":
            return .boolean(isWellFormed)
        case "dataSize":
            return .integer(Int64(dataSize))
        case "hasXMPMetaWrapper":
            return .boolean(hasXMPMetaWrapper)
        case "xmpToolkitVersion":
            if let v = xmpToolkitVersion { return .string(v) }
            return .null
        case "hasDublinCoreSchema":
            return .boolean(hasDublinCoreSchema)
        case "hasXMPBasicSchema":
            return .boolean(hasXMPBasicSchema)
        case "hasAdobePDFSchema":
            return .boolean(hasAdobePDFSchema)
        case "hasPDFAIdSchema":
            return .boolean(hasPDFAIdSchema)
        case "hasPDFUAIdSchema":
            return .boolean(hasPDFUAIdSchema)
        case "hasExtensionSchemas":
            return .boolean(hasExtensionSchemas)
        case "schemaCount":
            return .integer(Int64(schemaCount))
        case "pdfaPart":
            if let p = pdfaPart { return .integer(Int64(p)) }
            return .null
        case "pdfaConformance":
            if let c = pdfaConformance { return .string(c) }
            return .null
        case "pdfaAmendment":
            if let a = pdfaAmendment { return .string(a) }
            return .null
        case "pdfuaPart":
            if let p = pdfuaPart { return .integer(Int64(p)) }
            return .null
        case "isTitleSynchronized":
            return .boolean(isTitleSynchronized)
        case "isAuthorSynchronized":
            return .boolean(isAuthorSynchronized)
        case "isSubjectSynchronized":
            return .boolean(isSubjectSynchronized)
        case "isKeywordsSynchronized":
            return .boolean(isKeywordsSynchronized)
        case "isProducerSynchronized":
            return .boolean(isProducerSynchronized)
        case "isCreatorToolSynchronized":
            return .boolean(isCreatorToolSynchronized)
        case "isCreateDateSynchronized":
            return .boolean(isCreateDateSynchronized)
        case "isModDateSynchronized":
            return .boolean(isModDateSynchronized)
        case "hasAllRequiredPDFASchemas":
            return .boolean(hasAllRequiredPDFASchemas)
        case "hasValidExtensionSchemas":
            return .boolean(hasValidExtensionSchemas)
        case "synchronizationIssueCount":
            return .integer(Int64(synchronizationIssueCount))
        case "isFullySynchronized":
            return .boolean(isFullySynchronized)
        case "hasPDFAIdentification":
            return .boolean(hasPDFAIdentification)
        case "hasPDFUAIdentification":
            return .boolean(hasPDFUAIdentification)
        case "hasData":
            return .boolean(hasData)
        case "isPDFACompliant":
            return .boolean(isPDFACompliant)
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: ValidatedMetadata, rhs: ValidatedMetadata) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Factory Methods

extension ValidatedMetadata {

    /// Creates a fully PDF/A-compliant metadata for testing.
    ///
    /// - Parameters:
    ///   - part: The PDF/A part number.
    ///   - conformance: The PDF/A conformance level.
    /// - Returns: A PDF/A-compliant metadata object.
    public static func pdfaCompliant(
        part: Int = 2,
        conformance: String = "B"
    ) -> ValidatedMetadata {
        ValidatedMetadata(
            isWellFormed: true,
            dataSize: 2048,
            hasXMPMetaWrapper: true,
            xmpToolkitVersion: "Adobe XMP Core 5.6-c015",
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            hasAdobePDFSchema: true,
            hasPDFAIdSchema: true,
            schemaCount: 4,
            pdfaPart: part,
            pdfaConformance: conformance,
            hasAllRequiredPDFASchemas: true,
            hasValidExtensionSchemas: true
        )
    }

    /// Creates a PDF/UA-compliant metadata for testing.
    ///
    /// - Parameter part: The PDF/UA part number.
    /// - Returns: A PDF/UA metadata object.
    public static func pdfuaCompliant(part: Int = 1) -> ValidatedMetadata {
        ValidatedMetadata(
            isWellFormed: true,
            dataSize: 1536,
            hasXMPMetaWrapper: true,
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            hasAdobePDFSchema: true,
            hasPDFUAIdSchema: true,
            schemaCount: 4,
            pdfuaPart: part,
            hasAllRequiredPDFASchemas: false,
            hasValidExtensionSchemas: true
        )
    }

    /// Creates metadata with synchronization issues for testing.
    ///
    /// - Returns: A metadata object with mismatched properties.
    public static func withSyncIssues() -> ValidatedMetadata {
        ValidatedMetadata(
            isWellFormed: true,
            dataSize: 1024,
            hasXMPMetaWrapper: true,
            hasDublinCoreSchema: true,
            hasXMPBasicSchema: true,
            schemaCount: 2,
            isTitleSynchronized: false,
            isAuthorSynchronized: false,
            isCreateDateSynchronized: false
        )
    }
}
