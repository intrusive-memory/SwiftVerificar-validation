import Foundation

/// Document-level features extracted from a PDF document.
///
/// This struct contains metadata and structural information about
/// the PDF document as a whole, including info dictionary values,
/// PDF version, and document-level properties.
///
/// Corresponds to document-level feature extraction in veraPDF.
public struct DocumentFeatures: Sendable, Equatable {

    // MARK: - Info Dictionary Properties

    /// Document title from the info dictionary.
    public let title: String?

    /// Document author from the info dictionary.
    public let author: String?

    /// Document subject from the info dictionary.
    public let subject: String?

    /// Keywords from the info dictionary.
    public let keywords: String?

    /// Creator application from the info dictionary.
    public let creator: String?

    /// PDF producer from the info dictionary.
    public let producer: String?

    /// Creation date from the info dictionary.
    public let creationDate: Date?

    /// Modification date from the info dictionary.
    public let modificationDate: Date?

    /// Trapped status from the info dictionary.
    public let trapped: TrappedStatus?

    // MARK: - PDF Structure

    /// The PDF version (e.g., "1.4", "1.7", "2.0").
    public let pdfVersion: String

    /// Whether the document is linearized (web-optimized).
    public let isLinearized: Bool

    /// Whether the document is encrypted.
    public let isEncrypted: Bool

    /// The encryption method if encrypted.
    public let encryptionMethod: String?

    /// Total number of pages in the document.
    public let pageCount: Int

    /// Whether the document has a tagged structure.
    public let isTagged: Bool

    /// Whether the document contains XMP metadata.
    public let hasXMPMetadata: Bool

    /// Whether the document contains AcroForm fields.
    public let hasAcroForm: Bool

    /// Whether the document contains XFA form data.
    public let hasXFA: Bool

    /// The number of embedded files in the document.
    public let embeddedFileCount: Int

    /// Whether the document has bookmarks (outlines).
    public let hasOutlines: Bool

    /// The number of output intents.
    public let outputIntentCount: Int

    // MARK: - Conformance

    /// Claimed PDF/A conformance, if any.
    public let claimedPDFAConformance: String?

    /// Claimed PDF/UA conformance, if any.
    public let claimedPDFUAConformance: String?

    /// Claimed PDF/X conformance, if any.
    public let claimedPDFXConformance: String?

    // MARK: - Initialization

    /// Creates new document features.
    ///
    /// - Parameters:
    ///   - title: Document title.
    ///   - author: Document author.
    ///   - subject: Document subject.
    ///   - keywords: Document keywords.
    ///   - creator: Creator application.
    ///   - producer: PDF producer.
    ///   - creationDate: Creation date.
    ///   - modificationDate: Modification date.
    ///   - trapped: Trapped status.
    ///   - pdfVersion: PDF version string.
    ///   - isLinearized: Whether linearized.
    ///   - isEncrypted: Whether encrypted.
    ///   - encryptionMethod: Encryption method.
    ///   - pageCount: Number of pages.
    ///   - isTagged: Whether tagged.
    ///   - hasXMPMetadata: Whether has XMP.
    ///   - hasAcroForm: Whether has AcroForm.
    ///   - hasXFA: Whether has XFA.
    ///   - embeddedFileCount: Number of embedded files.
    ///   - hasOutlines: Whether has outlines.
    ///   - outputIntentCount: Number of output intents.
    ///   - claimedPDFAConformance: Claimed PDF/A conformance.
    ///   - claimedPDFUAConformance: Claimed PDF/UA conformance.
    ///   - claimedPDFXConformance: Claimed PDF/X conformance.
    public init(
        title: String? = nil,
        author: String? = nil,
        subject: String? = nil,
        keywords: String? = nil,
        creator: String? = nil,
        producer: String? = nil,
        creationDate: Date? = nil,
        modificationDate: Date? = nil,
        trapped: TrappedStatus? = nil,
        pdfVersion: String = "1.4",
        isLinearized: Bool = false,
        isEncrypted: Bool = false,
        encryptionMethod: String? = nil,
        pageCount: Int = 0,
        isTagged: Bool = false,
        hasXMPMetadata: Bool = false,
        hasAcroForm: Bool = false,
        hasXFA: Bool = false,
        embeddedFileCount: Int = 0,
        hasOutlines: Bool = false,
        outputIntentCount: Int = 0,
        claimedPDFAConformance: String? = nil,
        claimedPDFUAConformance: String? = nil,
        claimedPDFXConformance: String? = nil
    ) {
        self.title = title
        self.author = author
        self.subject = subject
        self.keywords = keywords
        self.creator = creator
        self.producer = producer
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.trapped = trapped
        self.pdfVersion = pdfVersion
        self.isLinearized = isLinearized
        self.isEncrypted = isEncrypted
        self.encryptionMethod = encryptionMethod
        self.pageCount = pageCount
        self.isTagged = isTagged
        self.hasXMPMetadata = hasXMPMetadata
        self.hasAcroForm = hasAcroForm
        self.hasXFA = hasXFA
        self.embeddedFileCount = embeddedFileCount
        self.hasOutlines = hasOutlines
        self.outputIntentCount = outputIntentCount
        self.claimedPDFAConformance = claimedPDFAConformance
        self.claimedPDFUAConformance = claimedPDFUAConformance
        self.claimedPDFXConformance = claimedPDFXConformance
    }

    // MARK: - Computed Properties

    /// The major PDF version number.
    public var majorVersion: Int {
        let parts = pdfVersion.split(separator: ".")
        return Int(parts.first ?? "1") ?? 1
    }

    /// The minor PDF version number.
    public var minorVersion: Int {
        let parts = pdfVersion.split(separator: ".")
        return parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
    }

    /// Whether this is a PDF 2.0+ document.
    public var isPDF2: Bool {
        majorVersion >= 2
    }

    /// Whether the document has any claimed conformance.
    public var hasConformance: Bool {
        claimedPDFAConformance != nil ||
        claimedPDFUAConformance != nil ||
        claimedPDFXConformance != nil
    }

    /// Whether the document has an info dictionary.
    public var hasInfoDictionary: Bool {
        title != nil || author != nil || subject != nil ||
        keywords != nil || creator != nil || producer != nil ||
        creationDate != nil || modificationDate != nil
    }

    /// Whether the document has embedded files.
    public var hasEmbeddedFiles: Bool {
        embeddedFileCount > 0
    }

    /// Whether the document contains interactive forms.
    public var hasForms: Bool {
        hasAcroForm || hasXFA
    }

    // MARK: - Conversion to FeatureNode

    /// Converts the document features to a FeatureNode.
    ///
    /// - Returns: A feature node representing the document features.
    public func toFeatureNode() -> FeatureNode {
        var values: [String: FeatureValue] = [:]

        // Info dictionary values
        if let title = title { values["title"] = .string(title) }
        if let author = author { values["author"] = .string(author) }
        if let subject = subject { values["subject"] = .string(subject) }
        if let keywords = keywords { values["keywords"] = .string(keywords) }
        if let creator = creator { values["creator"] = .string(creator) }
        if let producer = producer { values["producer"] = .string(producer) }
        if let creationDate = creationDate { values["creationDate"] = .date(creationDate) }
        if let modificationDate = modificationDate { values["modificationDate"] = .date(modificationDate) }
        if let trapped = trapped { values["trapped"] = .string(trapped.rawValue) }

        // Structure values
        values["pdfVersion"] = .string(pdfVersion)
        values["isLinearized"] = .bool(isLinearized)
        values["isEncrypted"] = .bool(isEncrypted)
        if let encryptionMethod = encryptionMethod { values["encryptionMethod"] = .string(encryptionMethod) }
        values["pageCount"] = .int(pageCount)
        values["isTagged"] = .bool(isTagged)
        values["hasXMPMetadata"] = .bool(hasXMPMetadata)
        values["hasAcroForm"] = .bool(hasAcroForm)
        values["hasXFA"] = .bool(hasXFA)
        values["embeddedFileCount"] = .int(embeddedFileCount)
        values["hasOutlines"] = .bool(hasOutlines)
        values["outputIntentCount"] = .int(outputIntentCount)

        // Conformance values
        if let pdfa = claimedPDFAConformance { values["claimedPDFAConformance"] = .string(pdfa) }
        if let pdfua = claimedPDFUAConformance { values["claimedPDFUAConformance"] = .string(pdfua) }
        if let pdfx = claimedPDFXConformance { values["claimedPDFXConformance"] = .string(pdfx) }

        return FeatureNode(
            featureType: .document,
            name: "Document",
            values: values
        )
    }
}

// MARK: - Trapped Status

/// The trapped status of a PDF document.
///
/// The trapped status indicates whether the document has been
/// adjusted for printing imperfections (trapping).
public enum TrappedStatus: String, Sendable, Codable, CaseIterable {
    /// The document has been trapped.
    case trapped = "True"

    /// The document has not been trapped.
    case notTrapped = "False"

    /// The trapping status is unknown.
    case unknown = "Unknown"

    /// Creates a trapped status from a string value.
    ///
    /// - Parameter value: The string value (case-insensitive).
    /// - Returns: The trapped status, or nil if not recognized.
    public init?(string value: String) {
        switch value.lowercased() {
        case "true", "yes": self = .trapped
        case "false", "no": self = .notTrapped
        case "unknown": self = .unknown
        default: return nil
        }
    }
}

// MARK: - Document Features Builder

/// Builder for constructing DocumentFeatures incrementally.
///
/// Use this builder when extracting features from a PDF document
/// where not all properties are available at once.
public struct DocumentFeaturesBuilder: Sendable {

    // MARK: - Properties

    private var title: String?
    private var author: String?
    private var subject: String?
    private var keywords: String?
    private var creator: String?
    private var producer: String?
    private var creationDate: Date?
    private var modificationDate: Date?
    private var trapped: TrappedStatus?
    private var pdfVersion: String = "1.4"
    private var isLinearized: Bool = false
    private var isEncrypted: Bool = false
    private var encryptionMethod: String?
    private var pageCount: Int = 0
    private var isTagged: Bool = false
    private var hasXMPMetadata: Bool = false
    private var hasAcroForm: Bool = false
    private var hasXFA: Bool = false
    private var embeddedFileCount: Int = 0
    private var hasOutlines: Bool = false
    private var outputIntentCount: Int = 0
    private var claimedPDFAConformance: String?
    private var claimedPDFUAConformance: String?
    private var claimedPDFXConformance: String?

    // MARK: - Initialization

    /// Creates a new document features builder.
    public init() {}

    // MARK: - Builder Methods

    /// Sets the document title.
    public mutating func title(_ value: String?) { title = value }

    /// Sets the document author.
    public mutating func author(_ value: String?) { author = value }

    /// Sets the document subject.
    public mutating func subject(_ value: String?) { subject = value }

    /// Sets the document keywords.
    public mutating func keywords(_ value: String?) { keywords = value }

    /// Sets the creator application.
    public mutating func creator(_ value: String?) { creator = value }

    /// Sets the PDF producer.
    public mutating func producer(_ value: String?) { producer = value }

    /// Sets the creation date.
    public mutating func creationDate(_ value: Date?) { creationDate = value }

    /// Sets the modification date.
    public mutating func modificationDate(_ value: Date?) { modificationDate = value }

    /// Sets the trapped status.
    public mutating func trapped(_ value: TrappedStatus?) { trapped = value }

    /// Sets the PDF version.
    public mutating func pdfVersion(_ value: String) { pdfVersion = value }

    /// Sets whether the document is linearized.
    public mutating func isLinearized(_ value: Bool) { isLinearized = value }

    /// Sets whether the document is encrypted.
    public mutating func isEncrypted(_ value: Bool) { isEncrypted = value }

    /// Sets the encryption method.
    public mutating func encryptionMethod(_ value: String?) { encryptionMethod = value }

    /// Sets the page count.
    public mutating func pageCount(_ value: Int) { pageCount = value }

    /// Sets whether the document is tagged.
    public mutating func isTagged(_ value: Bool) { isTagged = value }

    /// Sets whether the document has XMP metadata.
    public mutating func hasXMPMetadata(_ value: Bool) { hasXMPMetadata = value }

    /// Sets whether the document has AcroForm.
    public mutating func hasAcroForm(_ value: Bool) { hasAcroForm = value }

    /// Sets whether the document has XFA.
    public mutating func hasXFA(_ value: Bool) { hasXFA = value }

    /// Sets the embedded file count.
    public mutating func embeddedFileCount(_ value: Int) { embeddedFileCount = value }

    /// Sets whether the document has outlines.
    public mutating func hasOutlines(_ value: Bool) { hasOutlines = value }

    /// Sets the output intent count.
    public mutating func outputIntentCount(_ value: Int) { outputIntentCount = value }

    /// Sets the claimed PDF/A conformance.
    public mutating func claimedPDFAConformance(_ value: String?) { claimedPDFAConformance = value }

    /// Sets the claimed PDF/UA conformance.
    public mutating func claimedPDFUAConformance(_ value: String?) { claimedPDFUAConformance = value }

    /// Sets the claimed PDF/X conformance.
    public mutating func claimedPDFXConformance(_ value: String?) { claimedPDFXConformance = value }

    // MARK: - Build

    /// Builds the DocumentFeatures instance.
    ///
    /// - Returns: The constructed DocumentFeatures.
    public func build() -> DocumentFeatures {
        DocumentFeatures(
            title: title,
            author: author,
            subject: subject,
            keywords: keywords,
            creator: creator,
            producer: producer,
            creationDate: creationDate,
            modificationDate: modificationDate,
            trapped: trapped,
            pdfVersion: pdfVersion,
            isLinearized: isLinearized,
            isEncrypted: isEncrypted,
            encryptionMethod: encryptionMethod,
            pageCount: pageCount,
            isTagged: isTagged,
            hasXMPMetadata: hasXMPMetadata,
            hasAcroForm: hasAcroForm,
            hasXFA: hasXFA,
            embeddedFileCount: embeddedFileCount,
            hasOutlines: hasOutlines,
            outputIntentCount: outputIntentCount,
            claimedPDFAConformance: claimedPDFAConformance,
            claimedPDFUAConformance: claimedPDFUAConformance,
            claimedPDFXConformance: claimedPDFXConformance
        )
    }
}

// MARK: - CustomStringConvertible

extension DocumentFeatures: CustomStringConvertible {
    public var description: String {
        var parts: [String] = ["PDF \(pdfVersion)", "\(pageCount) pages"]

        if let title = title {
            parts.insert("'\(title)'", at: 0)
        }

        if isTagged { parts.append("tagged") }
        if isEncrypted { parts.append("encrypted") }
        if hasConformance {
            var conformances: [String] = []
            if let pdfa = claimedPDFAConformance { conformances.append("PDF/A-\(pdfa)") }
            if let pdfua = claimedPDFUAConformance { conformances.append("PDF/UA-\(pdfua)") }
            if let pdfx = claimedPDFXConformance { conformances.append("PDF/X-\(pdfx)") }
            parts.append(conformances.joined(separator: ", "))
        }

        return parts.joined(separator: ", ")
    }
}
