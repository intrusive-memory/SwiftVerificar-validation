import Foundation
#if canImport(SwiftVerificarParser)
#endif

// MARK: - Embedded File Validation

/// Validation wrapper for files embedded within a PDF document.
///
/// PDF documents can contain embedded files via the `/EmbeddedFiles` name tree
/// in the document catalog. Each embedded file is stored as a stream with
/// associated metadata in a file specification dictionary.
///
/// ## Key Properties
///
/// - **MIME Type**: The media type of the embedded file
/// - **File Specification**: The file name and description
/// - **Compliance**: Whether the embedded file conforms to PDF/A requirements
/// - **Relationship**: The AFRelationship of the file (PDF 2.0)
///
/// ## Validation Rules
///
/// Embedded files are checked for:
/// - MIME type presence and validity
/// - File specification dictionary completeness
/// - PDF/A-1 prohibition (no embedded files allowed in PDF/A-1)
/// - PDF/A-2 restrictions (must be PDF/A compliant or have proper AFRelationship)
/// - PDF/A-3 requirements (AFRelationship must be specified)
/// - Associated file relationship validity (PDF 2.0+)
///
/// ## Relationship to veraPDF
///
/// Corresponds to `GFEmbeddedFile` from veraPDF-validation.
public struct EmbeddedFileValidation: PDValidationObject, Sendable, Equatable {

    // MARK: - Properties

    /// Unique identifier for this validation object.
    public let id: UUID

    /// The COS dictionary for the embedded file stream.
    public let cosDictionary: COSValue?

    /// The object key, if indirect.
    public let objectKey: COSObjectKey?

    /// The validation context.
    public let validationContext: ObjectContext

    // MARK: - File Properties

    /// The MIME type (subtype) of the embedded file.
    ///
    /// Specified in the `/Subtype` entry of the embedded file stream dictionary.
    /// Common values: "application/pdf", "text/xml", "image/jpeg", etc.
    public let mimeType: String?

    /// The file name from the file specification dictionary.
    ///
    /// Corresponds to the `/F` or `/UF` entry in the file specification.
    public let fileName: String?

    /// The Unicode file name from the file specification.
    ///
    /// Corresponds to the `/UF` entry, which takes precedence over `/F`.
    public let unicodeFileName: String?

    /// The file description from the file specification.
    ///
    /// Corresponds to the `/Desc` entry in the file specification dictionary.
    public let fileDescription: String?

    /// The size of the embedded file data in bytes.
    public let fileSize: Int

    /// The creation date of the embedded file.
    public let creationDate: String?

    /// The modification date of the embedded file.
    public let modificationDate: String?

    /// The checksum of the embedded file data.
    ///
    /// Corresponds to the `/CheckSum` entry in the embedded file params dictionary.
    public let checksum: String?

    // MARK: - Compliance Properties

    /// The AFRelationship value for this embedded file (PDF 2.0+).
    ///
    /// Defines the relationship between the embedded file and the containing
    /// document. Required for PDF/A-3.
    ///
    /// Common values: "Source", "Data", "Alternative", "Supplement", "Unspecified".
    public let afRelationship: EmbeddedFileRelationship?

    /// Whether the embedded file has a valid file specification dictionary.
    public let hasFileSpec: Bool

    /// Whether the MIME type is specified.
    public var hasMimeType: Bool {
        mimeType != nil && !(mimeType?.isEmpty ?? true)
    }

    /// Whether the embedded file has a file name.
    public var hasFileName: Bool {
        (fileName != nil && !(fileName?.isEmpty ?? true)) ||
        (unicodeFileName != nil && !(unicodeFileName?.isEmpty ?? true))
    }

    /// The effective file name (Unicode preferred, falling back to basic).
    public var effectiveFileName: String? {
        unicodeFileName ?? fileName
    }

    /// Whether the AFRelationship is specified.
    public var hasAFRelationship: Bool {
        afRelationship != nil
    }

    /// Whether the embedded file itself is claimed to be PDF/A compliant.
    ///
    /// Used for PDF/A-2 and later, where embedded files that are PDFs
    /// must themselves be PDF/A compliant.
    public let isClaimedPDFACompliant: Bool

    /// Whether the file specification has an associated files entry.
    public let hasAssociatedFile: Bool

    // MARK: - Computed Properties

    /// Whether the embedded file is compliant with PDF/A-1.
    ///
    /// PDF/A-1 does NOT allow embedded files, so this always returns `false`.
    public var isPDFA1Compliant: Bool {
        false
    }

    /// Whether the embedded file is compliant with PDF/A-2.
    ///
    /// PDF/A-2 allows embedded files that are themselves PDF/A compliant.
    public var isPDFA2Compliant: Bool {
        hasMimeType && hasFileSpec && isClaimedPDFACompliant
    }

    /// Whether the embedded file is compliant with PDF/A-3.
    ///
    /// PDF/A-3 allows any type of embedded file but requires:
    /// - MIME type specified
    /// - AFRelationship specified
    /// - Valid file specification
    public var isPDFA3Compliant: Bool {
        hasMimeType && hasAFRelationship && hasFileSpec
    }

    /// Whether the embedded file has non-zero size.
    public var hasData: Bool {
        fileSize > 0
    }

    /// The file extension derived from the file name.
    public var fileExtension: String? {
        guard let name = effectiveFileName else { return nil }
        let components = name.split(separator: ".")
        guard components.count > 1 else { return nil }
        return String(components.last ?? "")
    }

    // MARK: - Initialization

    /// Creates an embedded file validation wrapper.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - cosDictionary: The COS dictionary for the embedded file stream.
    ///   - objectKey: The object key, if indirect.
    ///   - context: The validation context.
    ///   - mimeType: The MIME type of the embedded file.
    ///   - fileName: The file name.
    ///   - unicodeFileName: The Unicode file name.
    ///   - fileDescription: The file description.
    ///   - fileSize: The file size in bytes.
    ///   - creationDate: The creation date string.
    ///   - modificationDate: The modification date string.
    ///   - checksum: The file checksum.
    ///   - afRelationship: The AFRelationship value.
    ///   - hasFileSpec: Whether a file specification dictionary exists.
    ///   - isClaimedPDFACompliant: Whether the file is claimed PDF/A compliant.
    ///   - hasAssociatedFile: Whether the file has an associated file entry.
    public init(
        id: UUID = UUID(),
        cosDictionary: COSValue? = nil,
        objectKey: COSObjectKey? = nil,
        context: ObjectContext? = nil,
        mimeType: String? = nil,
        fileName: String? = nil,
        unicodeFileName: String? = nil,
        fileDescription: String? = nil,
        fileSize: Int = 0,
        creationDate: String? = nil,
        modificationDate: String? = nil,
        checksum: String? = nil,
        afRelationship: EmbeddedFileRelationship? = nil,
        hasFileSpec: Bool = true,
        isClaimedPDFACompliant: Bool = false,
        hasAssociatedFile: Bool = false
    ) {
        self.id = id
        self.cosDictionary = cosDictionary
        self.objectKey = objectKey
        self.validationContext = context ?? ObjectContext(location: "EmbeddedFile", role: mimeType ?? "Unknown")
        self.mimeType = mimeType
        self.fileName = fileName
        self.unicodeFileName = unicodeFileName
        self.fileDescription = fileDescription
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.checksum = checksum
        self.afRelationship = afRelationship
        self.hasFileSpec = hasFileSpec
        self.isClaimedPDFACompliant = isClaimedPDFACompliant
        self.hasAssociatedFile = hasAssociatedFile
    }

    // MARK: - PDFObject Conformance

    /// The object type for validation profiles.
    public var objectType: String {
        "EmbeddedFile"
    }

    /// Property names supported by this object.
    public var propertyNames: [String] {
        [
            "mimeType", "fileName", "unicodeFileName",
            "fileDescription", "fileSize", "creationDate",
            "modificationDate", "checksum",
            "afRelationship", "hasFileSpec",
            "hasMimeType", "hasFileName", "effectiveFileName",
            "hasAFRelationship", "isClaimedPDFACompliant", "hasAssociatedFile",
            "isPDFA1Compliant", "isPDFA2Compliant", "isPDFA3Compliant",
            "hasData", "fileExtension"
        ]
    }

    /// Returns the value of a property by name.
    ///
    /// - Parameter name: The property name.
    /// - Returns: The property value, or `nil` if not found.
    public func property(named name: String) -> PropertyValue? {
        switch name {
        case "mimeType":
            if let mt = mimeType { return .string(mt) }
            return .null
        case "fileName":
            if let fn = fileName { return .string(fn) }
            return .null
        case "unicodeFileName":
            if let uf = unicodeFileName { return .string(uf) }
            return .null
        case "fileDescription":
            if let fd = fileDescription { return .string(fd) }
            return .null
        case "fileSize":
            return .integer(Int64(fileSize))
        case "creationDate":
            if let cd = creationDate { return .string(cd) }
            return .null
        case "modificationDate":
            if let md = modificationDate { return .string(md) }
            return .null
        case "checksum":
            if let cs = checksum { return .string(cs) }
            return .null
        case "afRelationship":
            if let af = afRelationship { return .string(af.rawValue) }
            return .null
        case "hasFileSpec":
            return .boolean(hasFileSpec)
        case "hasMimeType":
            return .boolean(hasMimeType)
        case "hasFileName":
            return .boolean(hasFileName)
        case "effectiveFileName":
            if let efn = effectiveFileName { return .string(efn) }
            return .null
        case "hasAFRelationship":
            return .boolean(hasAFRelationship)
        case "isClaimedPDFACompliant":
            return .boolean(isClaimedPDFACompliant)
        case "hasAssociatedFile":
            return .boolean(hasAssociatedFile)
        case "isPDFA1Compliant":
            return .boolean(isPDFA1Compliant)
        case "isPDFA2Compliant":
            return .boolean(isPDFA2Compliant)
        case "isPDFA3Compliant":
            return .boolean(isPDFA3Compliant)
        case "hasData":
            return .boolean(hasData)
        case "fileExtension":
            if let ext = fileExtension { return .string(ext) }
            return .null
        default:
            return nil
        }
    }

    // MARK: - Equatable

    public static func == (lhs: EmbeddedFileValidation, rhs: EmbeddedFileValidation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Embedded File Relationship

/// The AFRelationship value for an associated file (PDF 2.0+).
///
/// Defines how the embedded file relates to the PDF document or
/// the document component it is associated with.
public enum EmbeddedFileRelationship: String, Sendable, CaseIterable, Equatable {

    /// The embedded file is the source material for the PDF.
    case source = "Source"

    /// The embedded file contains data used to derive the PDF content.
    case data = "Data"

    /// The embedded file is an alternative representation.
    case alternative = "Alternative"

    /// The embedded file supplements the PDF content.
    case supplement = "Supplement"

    /// The embedded file encrypts a portion of the PDF.
    case encryptedPayload = "EncryptedPayload"

    /// The embedded file supplements a form XObject.
    case formData = "FormData"

    /// The embedded file contains a schema definition.
    case schema = "Schema"

    /// The relationship is unspecified.
    case unspecified = "Unspecified"

    /// Unknown relationship value.
    case unknown = "Unknown"

    /// Creates a relationship from a string value.
    ///
    /// - Parameter value: The relationship string.
    public init(fromString value: String?) {
        guard let v = value else {
            self = .unknown
            return
        }
        self = EmbeddedFileRelationship(rawValue: v) ?? .unknown
    }

    /// Whether this relationship is recognized by PDF/A-3.
    public var isPDFA3Valid: Bool {
        switch self {
        case .source, .data, .alternative, .supplement, .unspecified:
            return true
        case .encryptedPayload, .formData, .schema, .unknown:
            return false
        }
    }
}

// MARK: - Factory Methods

extension EmbeddedFileValidation {

    /// Creates a PDF/A-3 compliant embedded file for testing.
    ///
    /// - Parameters:
    ///   - mimeType: The MIME type.
    ///   - fileName: The file name.
    ///   - relationship: The AFRelationship.
    /// - Returns: A PDF/A-3 compliant embedded file.
    public static func pdfa3Compliant(
        mimeType: String = "application/xml",
        fileName: String = "invoice.xml",
        relationship: EmbeddedFileRelationship = .data
    ) -> EmbeddedFileValidation {
        EmbeddedFileValidation(
            mimeType: mimeType,
            fileName: fileName,
            unicodeFileName: fileName,
            fileSize: 1024,
            afRelationship: relationship,
            hasFileSpec: true
        )
    }

    /// Creates a non-compliant embedded file for testing.
    ///
    /// - Returns: A non-compliant embedded file.
    public static func nonCompliant() -> EmbeddedFileValidation {
        EmbeddedFileValidation(
            fileSize: 512,
            hasFileSpec: false
        )
    }
}
