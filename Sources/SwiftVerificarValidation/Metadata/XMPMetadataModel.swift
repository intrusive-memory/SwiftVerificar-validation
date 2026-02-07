import Foundation

// MARK: - XMP Metadata Model

/// Represents the complete XMP metadata for a PDF document.
///
/// This model aggregates all XMP schemas commonly used in PDF documents,
/// providing a unified interface for reading, writing, and validating
/// XMP metadata.
///
/// ## Structure
///
/// XMP metadata is organized into schemas:
/// - Dublin Core (dc:) - Core descriptive metadata
/// - XMP Basic (xmp:) - Basic XMP properties
/// - Adobe PDF (pdf:) - PDF-specific properties
/// - PDF/A Identification (pdfaid:) - PDF/A conformance identification
/// - XMP Media Management (xmpMM:) - Document history and versions
///
/// ## PDF/A Requirements
///
/// For PDF/A compliance:
/// 1. XMP metadata must be present in a metadata stream
/// 2. The PDF/A identification schema must declare conformance
/// 3. Properties must be synchronized with the Info dictionary
/// 4. Custom schemas require extension schema declarations
public struct XMPMetadataModel: Sendable, Equatable {

    // MARK: - Standard Schemas

    /// Dublin Core schema (dc:).
    ///
    /// Contains core descriptive metadata like title, creator, description.
    public var dublinCore: DublinCoreSchema

    /// XMP Basic schema (xmp:).
    ///
    /// Contains basic XMP properties like creation date, modification date.
    public var xmpBasic: XMPBasicSchema

    /// Adobe PDF schema (pdf:).
    ///
    /// Contains PDF-specific properties like producer, keywords, trapped.
    public var adobePDF: AdobePDFSchema

    /// PDF/A identification schema.
    ///
    /// Declares PDF/A conformance part and level.
    public var pdfaIdentification: PDFAIdentificationSchema

    /// XMP Media Management schema (xmpMM:).
    ///
    /// Contains document history and version information.
    public var mediaManagement: XMPMediaManagementSchema

    /// Custom schemas not included in the standard set.
    public var customSchemas: [String: [String: XMPValue]]

    // MARK: - Initialization

    public init(
        dublinCore: DublinCoreSchema = DublinCoreSchema(),
        xmpBasic: XMPBasicSchema = XMPBasicSchema(),
        adobePDF: AdobePDFSchema = AdobePDFSchema(),
        pdfaIdentification: PDFAIdentificationSchema = PDFAIdentificationSchema(),
        mediaManagement: XMPMediaManagementSchema = XMPMediaManagementSchema(),
        customSchemas: [String: [String: XMPValue]] = [:]
    ) {
        self.dublinCore = dublinCore
        self.xmpBasic = xmpBasic
        self.adobePDF = adobePDF
        self.pdfaIdentification = pdfaIdentification
        self.mediaManagement = mediaManagement
        self.customSchemas = customSchemas
    }

    // MARK: - Convenience Accessors

    /// The document title.
    public var title: String? {
        dublinCore.defaultTitle
    }

    /// The document creator/author.
    public var creator: String? {
        dublinCore.creatorsString
    }

    /// The document description/subject.
    public var description: String? {
        dublinCore.defaultDescription
    }

    /// The document keywords.
    public var keywords: String? {
        adobePDF.keywords
    }

    /// The creator tool (application that created the document).
    public var creatorTool: String? {
        xmpBasic.creatorTool
    }

    /// The producer (application that converted to PDF).
    public var producer: String? {
        adobePDF.producer
    }

    /// The creation date.
    public var createDate: Date? {
        xmpBasic.createDate
    }

    /// The modification date.
    public var modifyDate: Date? {
        xmpBasic.modifyDate
    }

    /// The PDF/A conformance part (1, 2, 3, or 4).
    public var pdfaPart: Int? {
        pdfaIdentification.part
    }

    /// The PDF/A conformance level (a, b, or u).
    public var pdfaConformance: String? {
        pdfaIdentification.conformance
    }

    // MARK: - Validation

    /// Validates this XMP metadata model.
    ///
    /// - Returns: Array of validation issues found
    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Validate each schema
        issues.append(contentsOf: dublinCore.validate())
        issues.append(contentsOf: xmpBasic.validate())
        issues.append(contentsOf: adobePDF.validate())
        issues.append(contentsOf: pdfaIdentification.validate())
        issues.append(contentsOf: mediaManagement.validate())

        // Check for custom schemas that may need extension declarations
        if !customSchemas.isEmpty {
            for (namespace, _) in customSchemas {
                if !isKnownNamespace(namespace) {
                    issues.append(XMPValidationIssue(
                        severity: .warning,
                        namespace: namespace,
                        message: "Custom namespace '\(namespace)' may require PDF/A extension schema declaration"
                    ))
                }
            }
        }

        return issues
    }

    /// Validates PDF/A identification requirements.
    ///
    /// - Parameter expectedPart: Expected PDF/A part (nil to skip check)
    /// - Parameter expectedLevel: Expected PDF/A conformance level (nil to skip check)
    /// - Returns: Array of validation issues
    public func validatePDFAIdentification(
        expectedPart: Int? = nil,
        expectedLevel: String? = nil
    ) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check if PDF/A identification is present
        guard let part = pdfaIdentification.part else {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: PDFAIdentificationSchema.namespaceURI,
                propertyName: "part",
                message: "PDF/A identification schema missing pdfaid:part",
                ruleId: "6.6.4-1"
            ))
            return issues
        }

        guard let conformance = pdfaIdentification.conformance else {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: PDFAIdentificationSchema.namespaceURI,
                propertyName: "conformance",
                message: "PDF/A identification schema missing pdfaid:conformance",
                ruleId: "6.6.4-1"
            ))
            return issues
        }

        // Check expected values
        if let expected = expectedPart, part != expected {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: PDFAIdentificationSchema.namespaceURI,
                propertyName: "part",
                message: "pdfaid:part is \(part) but expected \(expected)",
                ruleId: "6.6.4-2"
            ))
        }

        if let expected = expectedLevel {
            let normalizedExpected = expected.lowercased()
            let normalizedActual = conformance.lowercased()
            if normalizedActual != normalizedExpected {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: PDFAIdentificationSchema.namespaceURI,
                    propertyName: "conformance",
                    message: "pdfaid:conformance is '\(conformance)' but expected '\(expected)'",
                    ruleId: "6.6.4-2"
                ))
            }
        }

        return issues
    }

    private func isKnownNamespace(_ uri: String) -> Bool {
        let knownNamespaces: Set<String> = [
            DublinCoreSchema.namespaceURI,
            XMPBasicSchema.namespaceURI,
            AdobePDFSchema.namespaceURI,
            PDFAIdentificationSchema.namespaceURI,
            XMPMediaManagementSchema.namespaceURI,
            "http://ns.adobe.com/xap/1.0/rights/",
            "http://ns.adobe.com/photoshop/1.0/",
            "http://ns.adobe.com/tiff/1.0/",
            "http://ns.adobe.com/exif/1.0/"
        ]
        return knownNamespaces.contains(uri)
    }

    // MARK: - XML Serialization

    /// Generates the complete XMP packet as XML.
    ///
    /// - Parameter includeWrapper: Whether to include the xpacket wrapper
    /// - Returns: The XMP XML string
    public func toXML(includeWrapper: Bool = true) -> String {
        var xml = ""

        if includeWrapper {
            xml += "<?xpacket begin=\"\u{feff}\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>\n"
        }

        xml += """
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about=""
              xmlns:dc="\(DublinCoreSchema.namespaceURI)"
              xmlns:xmp="\(XMPBasicSchema.namespaceURI)"
              xmlns:pdf="\(AdobePDFSchema.namespaceURI)"
              xmlns:pdfaid="\(PDFAIdentificationSchema.namespaceURI)"
              xmlns:xmpMM="\(XMPMediaManagementSchema.namespaceURI)">

        """

        // Dublin Core
        let dcXML = dublinCore.toXML()
        if !dcXML.isEmpty {
            xml += indentXML(dcXML, spaces: 6) + "\n"
        }

        // XMP Basic
        let xmpXML = xmpBasic.toXML()
        if !xmpXML.isEmpty {
            xml += indentXML(xmpXML, spaces: 6) + "\n"
        }

        // Adobe PDF
        let pdfXML = adobePDF.toXML()
        if !pdfXML.isEmpty {
            xml += indentXML(pdfXML, spaces: 6) + "\n"
        }

        // PDF/A Identification
        let pdfaidXML = pdfaIdentification.toXML()
        if !pdfaidXML.isEmpty {
            xml += indentXML(pdfaidXML, spaces: 6) + "\n"
        }

        // Media Management
        let mmXML = mediaManagement.toXML()
        if !mmXML.isEmpty {
            xml += indentXML(mmXML, spaces: 6) + "\n"
        }

        xml += """
            </rdf:Description>
          </rdf:RDF>
        </x:xmpmeta>

        """

        if includeWrapper {
            // Add padding for in-place editing
            let padding = String(repeating: " ", count: 20) + "\n"
            xml += String(repeating: padding, count: 20)
            xml += "<?xpacket end=\"w\"?>"
        }

        return xml
    }

    private func indentXML(_ xml: String, spaces: Int) -> String {
        let indent = String(repeating: " ", count: spaces)
        return xml.split(separator: "\n", omittingEmptySubsequences: false)
            .map { indent + $0 }
            .joined(separator: "\n")
    }
}

// MARK: - PDF/A Identification Schema

/// PDF/A identification schema (pdfaid: namespace).
///
/// This schema declares PDF/A conformance in the XMP metadata.
///
/// ## Namespace
/// - URI: `http://www.aiim.org/pdfa/ns/id/`
/// - Prefix: `pdfaid`
///
/// ## Required Properties for PDF/A
/// - `part` - The part of the PDF/A standard (1, 2, 3, or 4)
/// - `conformance` - The conformance level (A, B, or U)
public struct PDFAIdentificationSchema: Sendable, Equatable {

    public static let namespaceURI = "http://www.aiim.org/pdfa/ns/id/"
    public static let preferredPrefix = "pdfaid"

    /// The PDF/A part number (1, 2, 3, or 4).
    public var part: Int?

    /// The conformance level (A, B, U, E, or F).
    ///
    /// - A: Accessible (requires tagged structure)
    /// - B: Basic (visual appearance)
    /// - U: Unicode (text extraction)
    /// - E: Engineering (PDF/A-4e)
    /// - F: Full (PDF/A-4f with embedded files)
    public var conformance: String?

    /// Amendment number, if applicable.
    public var amd: String?

    /// Corrigenda reference, if applicable.
    public var corr: String?

    /// Revision year, if applicable.
    public var rev: Int?

    public init(
        part: Int? = nil,
        conformance: String? = nil,
        amd: String? = nil,
        corr: String? = nil,
        rev: Int? = nil
    ) {
        self.part = part
        self.conformance = conformance
        self.amd = amd
        self.corr = corr
        self.rev = rev
    }

    /// Validates this PDF/A identification schema.
    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check for required properties
        if part == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "part",
                message: "pdfaid:part is required for PDF/A identification",
                ruleId: "6.6.4-1"
            ))
        } else if let p = part {
            if p < 1 || p > 4 {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "part",
                    message: "pdfaid:part must be 1, 2, 3, or 4",
                    ruleId: "6.6.4-2"
                ))
            }
        }

        if conformance == nil && part != 4 {
            // PDF/A-4 may not require conformance level
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "conformance",
                message: "pdfaid:conformance is required for PDF/A identification",
                ruleId: "6.6.4-1"
            ))
        } else if let conf = conformance {
            let validLevels: Set<String>
            switch part {
            case 1:
                validLevels = ["A", "B", "a", "b"]
            case 2, 3:
                validLevels = ["A", "B", "U", "a", "b", "u"]
            case 4:
                validLevels = ["", "E", "F", "e", "f"]
            default:
                validLevels = ["A", "B", "U", "a", "b", "u"]
            }

            if !validLevels.contains(conf) {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "conformance",
                    message: "Invalid pdfaid:conformance '\(conf)' for PDF/A-\(part ?? 0)",
                    ruleId: "6.6.4-2"
                ))
            }
        }

        return issues
    }

    /// Generates XML for this schema.
    public func toXML() -> String {
        var elements: [String] = []

        if let p = part {
            elements.append("<pdfaid:part>\(p)</pdfaid:part>")
        }
        if let c = conformance {
            elements.append("<pdfaid:conformance>\(c)</pdfaid:conformance>")
        }
        if let a = amd {
            elements.append("<pdfaid:amd>\(a)</pdfaid:amd>")
        }
        if let c = corr {
            elements.append("<pdfaid:corr>\(c)</pdfaid:corr>")
        }
        if let r = rev {
            elements.append("<pdfaid:rev>\(r)</pdfaid:rev>")
        }

        return elements.joined(separator: "\n")
    }
}

// MARK: - XMP Media Management Schema

/// XMP Media Management schema (xmpMM: namespace).
///
/// This schema tracks document history and versions.
///
/// ## Namespace
/// - URI: `http://ns.adobe.com/xap/1.0/mm/`
/// - Prefix: `xmpMM`
public struct XMPMediaManagementSchema: Sendable, Equatable {

    public static let namespaceURI = "http://ns.adobe.com/xap/1.0/mm/"
    public static let preferredPrefix = "xmpMM"

    /// A unique identifier for this document.
    public var documentID: String?

    /// A unique identifier for this version of the document.
    public var instanceID: String?

    /// A reference to the original document this was derived from.
    public var originalDocumentID: String?

    /// Version identifier for this rendition.
    public var versionID: String?

    /// Array of resource events (document history).
    public var history: [ResourceEvent]?

    /// Reference to the source document this was derived from.
    public var derivedFrom: ResourceRef?

    public init(
        documentID: String? = nil,
        instanceID: String? = nil,
        originalDocumentID: String? = nil,
        versionID: String? = nil,
        history: [ResourceEvent]? = nil,
        derivedFrom: ResourceRef? = nil
    ) {
        self.documentID = documentID
        self.instanceID = instanceID
        self.originalDocumentID = originalDocumentID
        self.versionID = versionID
        self.history = history
        self.derivedFrom = derivedFrom
    }

    /// Validates this schema.
    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check for recommended properties
        if documentID == nil {
            issues.append(XMPValidationIssue(
                severity: .info,
                namespace: Self.namespaceURI,
                propertyName: "DocumentID",
                message: "xmpMM:DocumentID is recommended for document tracking"
            ))
        }

        if instanceID == nil {
            issues.append(XMPValidationIssue(
                severity: .info,
                namespace: Self.namespaceURI,
                propertyName: "InstanceID",
                message: "xmpMM:InstanceID is recommended for version tracking"
            ))
        }

        return issues
    }

    /// Generates XML for this schema.
    public func toXML() -> String {
        var elements: [String] = []

        if let docID = documentID {
            elements.append("<xmpMM:DocumentID>\(escapeXML(docID))</xmpMM:DocumentID>")
        }
        if let instID = instanceID {
            elements.append("<xmpMM:InstanceID>\(escapeXML(instID))</xmpMM:InstanceID>")
        }
        if let origID = originalDocumentID {
            elements.append("<xmpMM:OriginalDocumentID>\(escapeXML(origID))</xmpMM:OriginalDocumentID>")
        }
        if let verID = versionID {
            elements.append("<xmpMM:VersionID>\(escapeXML(verID))</xmpMM:VersionID>")
        }

        return elements.joined(separator: "\n")
    }

    private func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }
}

// MARK: - Supporting Types

/// A resource event in the document history.
public struct ResourceEvent: Sendable, Equatable {
    /// The action that occurred.
    public var action: String?

    /// When the action occurred.
    public var when: Date?

    /// Identifier for the instance after the action.
    public var instanceID: String?

    /// Description of what was changed.
    public var changed: String?

    /// Software that performed the action.
    public var softwareAgent: String?

    /// Additional parameters.
    public var parameters: String?

    public init(
        action: String? = nil,
        when: Date? = nil,
        instanceID: String? = nil,
        changed: String? = nil,
        softwareAgent: String? = nil,
        parameters: String? = nil
    ) {
        self.action = action
        self.when = when
        self.instanceID = instanceID
        self.changed = changed
        self.softwareAgent = softwareAgent
        self.parameters = parameters
    }
}

/// A reference to another resource.
public struct ResourceRef: Sendable, Equatable {
    /// The document ID of the referenced resource.
    public var documentID: String?

    /// The instance ID of the referenced resource.
    public var instanceID: String?

    /// The rendition class of the referenced resource.
    public var renditionClass: String?

    public init(
        documentID: String? = nil,
        instanceID: String? = nil,
        renditionClass: String? = nil
    ) {
        self.documentID = documentID
        self.instanceID = instanceID
        self.renditionClass = renditionClass
    }
}

// MARK: - Factory Methods

extension XMPMetadataModel {

    /// Creates an XMP metadata model from an Info dictionary.
    ///
    /// - Parameter infoDictionary: The Info dictionary to convert
    /// - Returns: A new XMPMetadataModel with values from the Info dictionary
    public static func fromInfoDictionary(_ infoDictionary: InfoDictionary) -> XMPMetadataModel {
        XMPMetadataModel(
            dublinCore: DublinCoreSchema.fromInfoDictionary(
                title: infoDictionary.title,
                author: infoDictionary.author,
                subject: infoDictionary.subject
            ),
            xmpBasic: XMPBasicSchema.fromInfoDictionary(
                creationDate: infoDictionary.creationDate,
                modDate: infoDictionary.modDate,
                creator: infoDictionary.creator
            ),
            adobePDF: AdobePDFSchema.fromInfoDictionary(
                keywords: infoDictionary.keywords,
                producer: infoDictionary.producer,
                trapped: infoDictionary.trapped?.trappedValue
            )
        )
    }

    /// Creates an XMP metadata model with PDF/A identification.
    ///
    /// - Parameters:
    ///   - part: The PDF/A part (1, 2, 3, or 4)
    ///   - conformance: The conformance level (A, B, U, E, or F)
    /// - Returns: A new XMPMetadataModel with PDF/A identification
    public static func withPDFAIdentification(part: Int, conformance: String) -> XMPMetadataModel {
        XMPMetadataModel(
            pdfaIdentification: PDFAIdentificationSchema(
                part: part,
                conformance: conformance
            )
        )
    }

    /// Creates a minimal XMP metadata model for PDF/A compliance.
    ///
    /// - Parameters:
    ///   - title: Document title
    ///   - creator: Document creator/author
    ///   - pdfaPart: PDF/A part number
    ///   - pdfaConformance: PDF/A conformance level
    /// - Returns: A new XMPMetadataModel
    public static func minimalPDFA(
        title: String,
        creator: String,
        pdfaPart: Int,
        pdfaConformance: String
    ) -> XMPMetadataModel {
        let now = Date()
        return XMPMetadataModel(
            dublinCore: DublinCoreSchema(
                creator: [creator],
                title: ["x-default": title]
            ),
            xmpBasic: XMPBasicSchema(
                createDate: now,
                metadataDate: now,
                modifyDate: now
            ),
            pdfaIdentification: PDFAIdentificationSchema(
                part: pdfaPart,
                conformance: pdfaConformance
            )
        )
    }
}
