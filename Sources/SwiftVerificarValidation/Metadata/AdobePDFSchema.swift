import Foundation

// MARK: - Adobe PDF Schema

/// Adobe PDF schema (pdf: namespace) for XMP metadata.
///
/// The Adobe PDF schema defines PDF-specific metadata properties.
///
/// ## Namespace
/// - URI: `http://ns.adobe.com/pdf/1.3/`
/// - Prefix: `pdf`
///
/// ## Properties
/// - `Keywords` - Keywords associated with the document
/// - `PDFVersion` - The PDF version (e.g., "1.4", "2.0")
/// - `Producer` - The name of the application that produced the PDF
/// - `Trapped` - Whether the document has been trapped
///
/// ## PDF/A Synchronization
///
/// For PDF/A compliance, the following properties must be synchronized
/// with the Info dictionary:
/// - `pdf:Keywords` <-> Info dictionary `/Keywords`
/// - `pdf:Producer` <-> Info dictionary `/Producer`
public struct AdobePDFSchema: XMPSchema, Sendable, Equatable {

    // MARK: - Static Properties

    public static let namespaceURI = "http://ns.adobe.com/pdf/1.3/"
    public static let preferredPrefix = "pdf"

    // MARK: - Properties

    /// Keywords associated with the document.
    ///
    /// Corresponds to Info dictionary `/Keywords`.
    public var keywords: String?

    /// The PDF version number.
    ///
    /// Format: "1.4", "1.7", "2.0", etc.
    public var pdfVersion: String?

    /// The application that produced the PDF.
    ///
    /// Corresponds to Info dictionary `/Producer`.
    public var producer: String?

    /// Indicates whether the document has been trapped.
    ///
    /// Valid values: "True", "False", "Unknown"
    public var trapped: TrappedValue?

    /// Custom properties not defined in the standard schema.
    private var customProperties: [String: XMPValue] = [:]

    // MARK: - Initialization

    public init(
        keywords: String? = nil,
        pdfVersion: String? = nil,
        producer: String? = nil,
        trapped: TrappedValue? = nil
    ) {
        self.keywords = keywords
        self.pdfVersion = pdfVersion
        self.producer = producer
        self.trapped = trapped
    }

    // MARK: - XMPSchema Protocol

    public var propertyNames: [String] {
        var names = ["Keywords", "PDFVersion", "Producer", "Trapped"]
        names.append(contentsOf: customProperties.keys)
        return names
    }

    public func property(named name: String) -> XMPValue? {
        switch name {
        case "Keywords":
            return keywords.map { .text($0) }
        case "PDFVersion":
            return pdfVersion.map { .text($0) }
        case "Producer":
            return producer.map { .text($0) }
        case "Trapped":
            return trapped.map { .text($0.rawValue) }
        default:
            return customProperties[name]
        }
    }

    public mutating func setProperty(named name: String, to value: XMPValue?) {
        switch name {
        case "Keywords":
            keywords = value?.textValue
        case "PDFVersion":
            pdfVersion = value?.textValue
        case "Producer":
            producer = value?.textValue
        case "Trapped":
            if let text = value?.textValue {
                trapped = TrappedValue(rawValue: text)
            } else {
                trapped = nil
            }
        default:
            customProperties[name] = value
        }
    }

    public func validate() -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Validate PDFVersion format if present
        if let version = pdfVersion {
            if !isValidPDFVersion(version) {
                issues.append(XMPValidationIssue(
                    severity: .warning,
                    namespace: Self.namespaceURI,
                    propertyName: "PDFVersion",
                    message: "Invalid PDF version format: \(version). Expected format like '1.4' or '2.0'."
                ))
            }
        }

        // Validate Trapped value if present
        if let trapped = trapped {
            if trapped == .unknown {
                issues.append(XMPValidationIssue(
                    severity: .info,
                    namespace: Self.namespaceURI,
                    propertyName: "Trapped",
                    message: "Trapped value is 'Unknown'. Consider specifying trapping status."
                ))
            }
        }

        return issues
    }

    public func toXML() -> String {
        var elements: [String] = []

        if let keywords = keywords {
            elements.append("<pdf:Keywords>\(escapeXML(keywords))</pdf:Keywords>")
        }
        if let version = pdfVersion {
            elements.append("<pdf:PDFVersion>\(escapeXML(version))</pdf:PDFVersion>")
        }
        if let producer = producer {
            elements.append("<pdf:Producer>\(escapeXML(producer))</pdf:Producer>")
        }
        if let trapped = trapped {
            elements.append("<pdf:Trapped>\(trapped.rawValue)</pdf:Trapped>")
        }

        for (name, value) in customProperties.sorted(by: { $0.key < $1.key }) {
            elements.append("<pdf:\(name)>\(escapeXML(value.description))</pdf:\(name)>")
        }

        return elements.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private func isValidPDFVersion(_ version: String) -> Bool {
        // Valid formats: "1.0" through "1.7", "2.0"
        let pattern = #"^[12]\.[0-9]$"#
        return version.range(of: pattern, options: .regularExpression) != nil
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

// MARK: - Trapped Value

/// The trapping status of a PDF document.
///
/// Trapping is a prepress technique to prevent gaps between colors due to
/// misregistration during printing.
public enum TrappedValue: String, Sendable, Codable, CaseIterable {
    /// The document has been trapped.
    case `true` = "True"

    /// The document has not been trapped.
    case `false` = "False"

    /// The trapping status is unknown.
    case unknown = "Unknown"

    /// Creates a TrappedValue from a PDF name string.
    public init?(pdfName: String) {
        switch pdfName.lowercased() {
        case "true": self = .true
        case "false": self = .false
        case "unknown": self = .unknown
        default: return nil
        }
    }

    /// The PDF name representation.
    public var pdfName: String {
        rawValue
    }
}

// MARK: - Property Descriptors

extension AdobePDFSchema {

    /// Returns descriptors for all properties in this schema.
    public static var propertyDescriptors: [XMPPropertyDescriptor] {
        [
            XMPPropertyDescriptor(
                name: "Keywords",
                type: .text,
                description: "Keywords associated with the document, separated by commas or semicolons.",
                isRequired: false,
                infoDictKey: "Keywords"
            ),
            XMPPropertyDescriptor(
                name: "PDFVersion",
                type: .text,
                description: "The PDF version designation, e.g., '1.4' or '2.0'.",
                isRequired: false,
                infoDictKey: nil
            ),
            XMPPropertyDescriptor(
                name: "Producer",
                type: .text,
                description: "The name of the application that converted the document to PDF.",
                isRequired: false,
                infoDictKey: "Producer"
            ),
            XMPPropertyDescriptor(
                name: "Trapped",
                type: .text,
                description: "Indicates whether the document has been trapped. One of: True, False, Unknown.",
                isRequired: false,
                infoDictKey: "Trapped"
            )
        ]
    }
}

// MARK: - Synchronization Support

extension AdobePDFSchema {

    /// Properties that should be synchronized with the Info dictionary.
    public static var synchronizedProperties: [(xmpProperty: String, infoDictKey: String)] {
        [
            ("Keywords", "Keywords"),
            ("Producer", "Producer")
            // Note: Trapped uses a Name value in Info dict, not a string
        ]
    }

    /// Creates an AdobePDFSchema from Info dictionary values.
    ///
    /// - Parameters:
    ///   - keywords: The Keywords from Info dictionary
    ///   - producer: The Producer from Info dictionary
    ///   - trapped: The Trapped status from Info dictionary
    /// - Returns: A new AdobePDFSchema instance
    public static func fromInfoDictionary(
        keywords: String? = nil,
        producer: String? = nil,
        trapped: TrappedValue? = nil
    ) -> AdobePDFSchema {
        AdobePDFSchema(
            keywords: keywords,
            producer: producer,
            trapped: trapped
        )
    }

    /// Checks if this schema is synchronized with given Info dictionary values.
    ///
    /// - Parameters:
    ///   - infoKeywords: Keywords from Info dictionary
    ///   - infoProducer: Producer from Info dictionary
    /// - Returns: List of synchronization issues
    public func checkSynchronization(
        infoKeywords: String?,
        infoProducer: String?
    ) -> [XMPValidationIssue] {
        var issues: [XMPValidationIssue] = []

        // Check Keywords synchronization
        if let xmpKeywords = keywords, let infoKw = infoKeywords {
            if xmpKeywords != infoKw {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "Keywords",
                    message: "pdf:Keywords '\(xmpKeywords)' does not match Info dictionary Keywords '\(infoKw)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if keywords != nil && infoKeywords == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "Keywords",
                message: "pdf:Keywords exists but Info dictionary Keywords is missing",
                ruleId: "6.7.3-1"
            ))
        } else if keywords == nil && infoKeywords != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "Keywords",
                message: "Info dictionary Keywords exists but pdf:Keywords is missing",
                ruleId: "6.7.3-1"
            ))
        }

        // Check Producer synchronization
        if let xmpProducer = producer, let infoProd = infoProducer {
            if xmpProducer != infoProd {
                issues.append(XMPValidationIssue(
                    severity: .error,
                    namespace: Self.namespaceURI,
                    propertyName: "Producer",
                    message: "pdf:Producer '\(xmpProducer)' does not match Info dictionary Producer '\(infoProd)'",
                    ruleId: "6.7.3-1"
                ))
            }
        } else if producer != nil && infoProducer == nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "Producer",
                message: "pdf:Producer exists but Info dictionary Producer is missing",
                ruleId: "6.7.3-1"
            ))
        } else if producer == nil && infoProducer != nil {
            issues.append(XMPValidationIssue(
                severity: .error,
                namespace: Self.namespaceURI,
                propertyName: "Producer",
                message: "Info dictionary Producer exists but pdf:Producer is missing",
                ruleId: "6.7.3-1"
            ))
        }

        return issues
    }
}
